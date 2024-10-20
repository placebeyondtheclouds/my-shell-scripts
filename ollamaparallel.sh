#!/bin/bash

# run with: CUDA_VISIBLE_DEVICES=0,1 ollamaparallel

#start at
PORT=11435

# get the number of GPUs from CUDA_VISIBLE_DEVICES
if [ -z "$CUDA_VISIBLE_DEVICES" ]; then
    echo "CUDA_VISIBLE_DEVICES is not set. Using all GPUs."
    GPU_COUNT=$(nvidia-smi --list-gpus | wc -l)
    GPUS=($(seq 0 $((GPU_COUNT - 1))))
else
    GPUS=($(echo $CUDA_VISIBLE_DEVICES | tr ',' ' '))
fi

alreadyrunning=$(ss -ntlp | grep -w "ollama" | awk '{print $4}' | awk -F: '{print $2}')
if [ -n "$alreadyrunning" ]; then
    echo "ollama already running on ports:"
    echo "$alreadyrunning"
    echo "stop ollama? [y/N]:"
    read -n 1 -s -r -p "" key
    if [ "$key" = "y" ]; then
        pkill ollama
    else
        echo "quitting"
        exit 1
    fi
fi

echo "using GPUs: ${GPUS[*]}"
echo "enter the number of instances per GPU [1]:"
read -r INSTANCES_PER_GPU

if [ -z "$INSTANCES_PER_GPU" ]; then
    echo "instances per GPU not set. Using 1."
    INSTANCES_PER_GPU=1
fi

echo >ollamaports.txt

for current_gpu_number in "${GPUS[@]}"; do
    for process_number in $(seq 1 $((INSTANCES_PER_GPU))); do
        ((PORT += 1))
        while nc -z 127.0.0.1 $PORT; do
            ((PORT += 1))
        done
        echo $PORT >>ollamaports.txt
        nohup /bin/bash -c "CUDA_VISIBLE_DEVICES=\"$current_gpu_number\" OLLAMA_HOST=127.0.0.1:$PORT ollama serve" >/dev/null 2>&1 &
        echo "started process $process_number on gpu $current_gpu_number on port $PORT"
    done
done

echo "ports are written to ollamaports.txt"
echo "to kill all ollama instances, run: "
echo "pkill ollama"
echo "to see the running instances, run: "
echo "ss -ntlp | grep -w \"ollama\""
