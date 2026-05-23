#!/bin/bash
# ======================================================================================
# SIMPLIFIED CONSOLE-ONLY OLLAMA BENCHMARKER (V20.0 - CLEAN OVERNIGHT AUTOMATION)
# ======================================================================================

export OLLAMA_HOST="127.0.0.1:11434"

echo "========================================================================"
echo "                   OLLAMA LIVE CONSOLE BENCHMARKER                      "
echo "========================================================================"

# Fetch available models into a clean array
mapfile -t model_list < <(ollama list | tail -n +2 | awk '{print $1}')

if [ ${#model_list[@]} -eq 0 ]; then
    echo "Error: No models found running in your Ollama library."
    exit 1
fi

# STEP 1: Choose Models
echo "Available Models for Benchmarking:"
for i in "${!model_list[@]}"; do
    echo "  [$i] ${model_list[i]}"
done
echo "------------------------------------------------------------------------"
read -p "Select models (comma-separated list, e.g., 3,13,1,0): " user_selection

# Parse selections
TARGETS=()
IFS=',' read -ra ADDR <<< "$user_selection"
for idx in "${ADDR[@]}"; do
    idx=$(echo "$idx" | tr -d ' ')
    if [[ "$idx" =~ ^[0-9]+$ ]] && [ "$idx" -lt "${#model_list[@]}" ]; then
        TARGETS+=("$idx")
    fi
done

if [ ${#TARGETS[@]} -eq 0 ]; then
    echo "Error: No valid model indices selected. Exiting."
    exit 1
fi

# STEP 2: Choose Prompt Workload
echo -e "\n------------------------------------------------------------------------"
echo "Choose your evaluation prompt workload:"
echo "  [1] Standard Speed Test (Ultra-Fast 2+2 Math Instant Metric)"
echo "  [2] Narrative Logic Test (The Parable of the Unjust Steward Analysis)"
echo "  [3] Coding Discriminator Test (SHORT PURE VANILLA JavaScript Trait)"
echo "  [4] Custom Input Test (Type your own prompt)"
read -p " Select choice (1-4, default is 1): " prompt_choice
prompt_choice=${prompt_choice:-1}

if [ "$prompt_choice" -eq 2 ]; then
    PROMPT="Analyze the Parable of the Unjust Steward (Luke 16:1-13). Explain the core paradox: Why does the master commend the dishonest manager, and how does the concept of 'shrewdness' bridge the gap between material actions and spiritual prudence? Provide a tight 2-paragraph theological and logical resolution. Limit your entire response to under 150 words."
elif [ "$prompt_choice" -eq 3 ]; then
    PROMPT="Write a JavaScript function to merge two objects. If a key exists in both, sum their values. Constraint: You cannot use any loops (for, for...in, forEach), built-in array iteration methods (map, reduce), or external libraries. Provide only the clean function. No explanation."
elif [ "$prompt_choice" -eq 4 ]; then
    read -p " Enter your custom prompt: " PROMPT
else
    # FIXED: Hardcoded math problem ensures instant completion without long thought loops
    PROMPT="What is 2+2? Answer with just the single digit number and nothing else."
fi

# ======================================================================================
# THE WORKLOAD RUNNER LOOP (No logs, no filters, direct to screen)
# ======================================================================================
for current_idx in "${TARGETS[@]}"; do
    TEST_MODEL="${model_list[$current_idx]}"
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    
    echo -e "\n\n=========================================================="
    echo "STARTING TEST FOR: $TEST_MODEL"
    echo "TIMESTAMP:         $TIMESTAMP"
    echo "=========================================================="
    
    # Pure direct console stream with Flash Attention active
    OLLAMA_FLASH_ATTENTION=1 ollama run "$TEST_MODEL" "$PROMPT" --verbose
    
    echo -e "\n=========================================================="
    echo "FINISHED TEST FOR: $TEST_MODEL"
    echo "=========================================================="
    
    # Critical cluster unmapping and VRAM eviction
    echo "Evicting $TEST_MODEL from cluster VRAM pools..."
    ollama stop "$TEST_MODEL" > /dev/null 2>&1
    
    # 10-Second Cooldown for multi-GPU memory lane stabilization
    for i in {10..1}; do 
        echo -ne " Cooling GPU Cluster Lanes... Cooldown: $i.. \r"
        sleep 1
    done
    echo -e "Ready for next model sequence.                          "
done

echo -e "\n\n>>> ALL RECOGNIZED MODEL TEST SEQUENCES COMPLETE. <<<"
