#!/bin/bash

GPUS=8
INSTANCES_PER_GPU=5
PORT_START=11435

for current_gpu_number in $(seq 0 $((GPUS - 1))); do
    for process_number in $(seq 1 $((INSTANCES_PER_GPU))); do
        current_port=$((PORT_START + process_number))
        CUDA_VISIBLE_DEVICES=$current_gpu_number OLLAMA_HOST=127.0.0.1:$current_port ./ollama serve &
        echo "started process $process_number on gpu $current_gpu_number on port $current_port"
    done
done
