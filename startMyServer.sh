#!/bin/bash
# ======================================================================================
# TERMINAL A: PRODUCTION MULTI-GPU SERVER SCHEDULER (V4)
# ======================================================================================

# 1. Hardware thermal and power boundaries configuration
echo "Configuring cluster power clamps (30W ceilings)..."
for i in {0..11}; do sudo nvidia-smi -i $i -pl 30; done

# 2. Flush legacy background runtime daemons
echo "Flushing background daemons..."
sudo systemctl stop ollama
sudo pkill -f ollama || true

# 3. Armed System Environment Global Optimizations
export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7,8,9,10,11
export OLLAMA_FLASH_ATTENTION=1      # Unlocks fast SRAM cache tile matrices globally
export OLLAMA_MAX_LOAD_MODELS=1       # Overload memory crash safeguard
export OLLAMA_KEEP_ALIVE=-1           # Locks models into VRAM indefinitely
export OLLAMA_DEBUG=1                 # Streams diagnostic kernel strings
export OLLAMA_SCHED_SPREAD=1          # Spreads model layers evenly across 12 nodes

echo "------------------------------------------------------------------------"
echo "LAUNCHING UNIFIED SERVER NODE ENGINE..."
echo " -> Power Clamps: 30W Absolute Ceiling"
echo " -> Mode Status:  Spread Layout Active | Flash Attention Enabled"
echo "------------------------------------------------------------------------"

ollama serve
