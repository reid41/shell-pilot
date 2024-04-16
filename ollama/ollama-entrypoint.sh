#!/bin/bash
set -e

# Start ollama serve in the background
export OLLAMA_HOST=0.0.0.0 

ollama serve &

# Sleep for 50 seconds (adjust as needed)
sleep 30

# Check if the specified model is present
MODEL="${MODEL:-llama2}"  # Default to "llama2" if MODEL is not set
MODEL_PRESENT=$(ollama list | grep "$MODEL" | wc -l)
if [ $MODEL_PRESENT -lt 1 ]; then 
    #Ensure the model is pulled by default when the container starts up
    echo "Model not available already. Pulling $MODEL now!"
    ollama pull "$MODEL" 
else    
    echo "Model $MODEL already available"
fi 

# Sleep indefinitely
echo "$MODEL ready to be served"
sleep infinity
