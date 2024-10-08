#!/bin/bash

GPUS=8
INSTANCES_PER_GPU=5
PORT=11435
echo >ollamaports.txt

for current_gpu_number in $(seq 0 $((GPUS - 1))); do
    for process_number in $(seq 1 $((INSTANCES_PER_GPU))); do
        ((PORT += 1))
        while nc -z 127.0.0.1 $PORT; do
            ((PORT += 1))
        done
        echo $PORT >>ollamaports.txt
        CUDA_VISIBLE_DEVICES=$current_gpu_number OLLAMA_HOST=127.0.0.1:$PORT ./ollama serve &
        echo "started process $process_number on gpu $current_gpu_number on port $PORT"
    done
done
