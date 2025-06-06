#!/bin/bash

# start multiple ollama serve instances for use with other scripts

echo "usage: CUDA_VISIBLE_DEVICES=0,1 ./ollamaparallel.sh"

#start at
PORT=11435

# get the number of GPUs
if [ -z "$CUDA_VISIBLE_DEVICES" ]; then
    echo "CUDA_VISIBLE_DEVICES is not set. Using all GPUs."
    GPU_COUNT=$(nvidia-smi --list-gpus | wc -l)
    GPUS=($(seq 0 $((GPU_COUNT - 1))))
else
    GPUS=($(echo $CUDA_VISIBLE_DEVICES | tr ',' ' '))
fi

# check if ollama serve instances are already running
alreadyrunning=$(ss -ntlp | grep -w "ollama" | awk '{print $4}' | awk -F: '{print $2}')
if [ -n "$alreadyrunning" ]; then
    echo "ollama already running on ports:"
    echo "$alreadyrunning"
    echo "stop ollama? [y/N]:"
    read -n 1 -s -r -p "" key
    if [ "$key" = "y" ]; then
        pkill "ollama" -x 2>/dev/null
        echo -e "\nollama stopped\n"
    else
        echo "quitting"
        exit 1
    fi
fi
echo >ollamaports.txt

# display current situation
echo "using GPUs: ${GPUS[*]}"
for current_gpu_number in "${GPUS[@]}"; do
    echo "GPU $current_gpu_number: $(nvidia-smi --query-gpu=name,memory.free --format=csv -i $current_gpu_number)"
done

# set number of processes per GPU
INSTANCES_PER_GPU=""
while [[ ! $INSTANCES_PER_GPU =~ ^[0-9]+$ ]]; do
    echo "enter the number of instances per GPU [1]:"
    read -r INSTANCES_PER_GPU
    if [ -z "$INSTANCES_PER_GPU" ]; then
        echo "instances per GPU not set. Using 1."
        INSTANCES_PER_GPU=1
    fi
done

if [ "$INSTANCES_PER_GPU" -eq 0 ]; then
    echo "Exiting."
    exit 1
fi

# start the processes
for current_gpu_number in "${GPUS[@]}"; do
    for process_number in $(seq 1 $((INSTANCES_PER_GPU))); do
        ((PORT += 1))
        while nc -z 127.0.0.1 $PORT; do
            ((PORT += 1))
        done
        echo $PORT >>ollamaports.txt
        nohup /bin/bash -c "CUDA_VISIBLE_DEVICES=\"$current_gpu_number\" OLLAMA_HOST=127.0.0.1:$PORT ollama serve" >/dev/null 2>&1 &
        echo -e "\033[0;34mGPU $current_gpu_number: ollama started on port $PORT\033[0m"
    done
done

echo -e " \n"
echo "ports are written to ollamaports.txt"
echo "to kill all ollama instances, run: "
echo -e "\033[0;31mpkill ollama\033[0m"
echo "to see the running instances, run: "
echo -e "\033[0;31mss -ntlp | grep -w \"ollama\"\033[0m"
