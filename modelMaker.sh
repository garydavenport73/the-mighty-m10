#!/bin/bash

# 1. Capture the very first argument as the core model name
myModel="$1"

if [ -z "$myModel" ]; then
    echo "========================================================================"
    echo "                   OLLAMA CURRENTLY LOADED MODELS                       "
    echo "========================================================================"
    ollama list
    echo "------------------------------------------------------------------------"
    read -p "No model provided. Enter base model name exactly: " myModel
fi

# Double-check that we finally have a model name to work with
if [ -z "$myModel" ]; then
    echo "ERROR: Model name cannot be empty. Aborting."
    exit 1
fi

# 2. Automated Size Lookup (Counts backwards from the end of the line safely)
#model_size_gb=$(ollama list | grep -w "$myModel" | awk '{print $(NF-2)}' | cut -d. -f1)
#model_size_gb=${model_size_gb:-"0"}

# FIXED METHOD: Searches specifically for the column that ends with "GB" and pulls just the number
model_size_gb=$(ollama list | grep -w "$myModel" | sed 's/\x1B\[[0-9;]*[JKmsu]//g' | grep -oE '[0-9]+(\.[0-9]+)?\s*GB' | head -n 1 | cut -d. -f1 | tr -d -c '0-9')
model_size_gb=${model_size_gb:-"0"}


# Initialize baseline hardware defaults
total_vram_gb="96"

# Calculate remaining VRAM headroom to suggest standard bracket recommendations
vram_headroom=$(( total_vram_gb - model_size_gb ))
if [ "$vram_headroom" -le 5 ]; then
    sug_ctx="2048"
elif [ "$vram_headroom" -le 15 ]; then
    sug_ctx="4096"
elif [ "$vram_headroom" -le 30 ]; then
    sug_ctx="8192"
elif [ "$vram_headroom" -le 45 ]; then
    sug_ctx="16384"
else
    sug_ctx="32768"
fi

if [ "$vram_headroom" -le 10 ]; then
    sug_batch="216"
else
    sug_batch="512"
fi

sug_temp="0.8"

# Initialize variables
input_temp=""
auto_pilot=""

# ======================================================================================
# AUTOPILOT LOOP: Scan arguments for "autopilot=yes" or custom temperature overrides
# ======================================================================================
for arg in "$@"; do
    if [[ "$arg" == "autopilot=yes" ]]; then
        auto_pilot="autopilot=yes"
    elif [[ "$arg" == temperature=* ]]; then
        input_temp="${arg#*=}"
    fi
done

# ======================================================================================
# INTERACTIVE AUTOMATION PROMPT (Only triggers if run manually without flags)
# ======================================================================================
if [ "$auto_pilot" != "autopilot=yes" ]; then
    echo "------------------------------------------------------------------------"
    read -p "Automate and apply all system defaults for this model? (y/n): " choice
    if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
        auto_pilot="autopilot=yes"
    fi
fi

# ======================================================================================
# CLUSTERING TARGET ASSIGNMENTS
# ======================================================================================
if [ "$auto_pilot" = "autopilot=yes" ]; then
    # Keep math parameters fully optimized, override temperature if specified
    num_ctx="$sug_ctx"
    batch_setting="$sug_batch"
    temp_setting=${input_temp:-$sug_temp}

    echo "------------------------------------------------------------------------"
    echo ">> CONFIGURATION LOG: Applying Target Profile Parameters <<"
    echo " -> Model Lookup Size:  $model_size_gb GB"
    echo " -> Calculated Context: $num_ctx tokens"
    echo " -> Calculated Batch:   $batch_setting elements"
    echo " -> Assigned Temp:      $temp_setting"
else
    # Run the interactive prompts normally if user explicitly chose 'n'
    read -p "Enter total system GPU VRAM capacity in GB (Hit Enter for default: 96): " input_vram
    total_vram_gb=${input_vram:-"96"}

    vram_headroom=$(( total_vram_gb - model_size_gb ))

    if [ "$model_size_gb" -gt "$total_vram_gb" ]; then
        echo "ERROR: Model size ($model_size_gb GB) is larger than VRAM ($total_vram_gb GB)."
        echo "Aborting configuration: You requested a GPU-only deployment."
        exit 1
    fi

    echo "------------------------------------------------------------------------"
    echo "CHOICE 1: Context Window Size (num_ctx)"
    echo " -> Standard choices: 2048, 4096, 8192, 16384, 32768"
    echo " -> RECOMMENDED SIZE FOR YOUR VRAM HEADROOM ($vram_headroom GB): $sug_ctx"
    read -p "Enter chosen context size (Hit Enter for recommendation): " num_ctx
    num_ctx=${num_ctx:-$sug_ctx}

    echo "------------------------------------------------------------------------"
    echo "CHOICE 2: Intake Batch Size (num_batch)"
    echo " -> Standard choices: 216, 512, 1024"
    echo " -> RECOMMENDED BATCH SIZE FOR YOUR CLUSTER CONFIGURATION: $sug_batch"
    read -p "Enter chosen intake batch size (Hit Enter for recommendation): " batch_setting
    batch_setting=${batch_setting:-$sug_batch}

    echo "------------------------------------------------------------------------"
    echo "CHOICE 3: Logic Consistency / Temperature (temperature)"
    echo " -> RECOMMENDED CHOSEN TEMP (Hit Enter for Ollama default: 0.8): "
    read -p "Enter temperature value: " temp_setting
    temp_setting=${temp_setting:-"0.8"}
fi

# ======================================================================================
# ZERO-PADDED VISUAL SORTING NAMING ENGINE
# ======================================================================================
size_string=$(printf "siz%03dg" "$model_size_gb")

#ctx_k=$(( num_ctx / 1024 ))
#if [ "$ctx_k" -eq 0 ]; then
#    ctx_string=$(printf "ctx%04d" "$num_ctx")
#else
#    ctx_string=$(printf "ctx%03dk" "$ctx_k")
#fi

ctx_string=$(printf "ctx%05d" "$num_ctx")


batch_string=$(printf "bat%04d" "$batch_setting")
temp_string=$(printf "tmp%.2f" "$temp_setting")

cleanModelName=$(echo "$myModel" | sed 's/:/-/g')
finalName="${size_string}-${ctx_string}-${batch_string}-${temp_string}-${cleanModelName}"
output_filename="${finalName}.modelfile"

# ======================================================================================
# STANDALONE FILE GENERATION
# ======================================================================================
cat <<EOF > "$output_filename"
# Custom Modelfile Generated for Rig Benchmark Testing
FROM ${myModel}
PARAMETER num_ctx ${num_ctx}
PARAMETER num_batch ${batch_setting}
PARAMETER temperature ${temp_setting}

# --- HISTORICAL LEGACY RUNTIME RECORDS ---
# PARAMETER num_gpu 999  # Deprecated: Overridden by system engine and server startup configs
# PARAMETER use_mmap 0   # Deprecated: No longer parsed natively in recent modelfile compilers
# PARAMETER use_lock 1   # Deprecated: Memory-locking flags handled automatically at host startup
EOF

# ======================================================================================
# AUTOMATED OLLAMA REGISTER COMPILER
# ======================================================================================
echo "------------------------------------------------------------------------"
echo "Compiling and registering model with Ollama..."
ollama create "${finalName}" -f "./${output_filename}"


# AUTO-PURGE ARTIFACT: Deletes the clutter text file immediately after build registration
rm "./${output_filename}"

echo "------------------------------------------------------------------------"
echo "SUCCESS: ${finalName} is now registered in your system library."
echo " -> File Backup:     ${output_filename}"
echo " -> Launch command:  OLLAMA_FLASH_ATTENTION=1 ollama run ${finalName}"
echo "------------------------------------------------------------------------"
