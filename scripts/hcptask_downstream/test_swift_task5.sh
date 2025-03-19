#!/bin/bash
# bash scripts/hcptask_downstream/ts_swift_task5.sh batch_size

batch_size="12"

# Override with the arguments if provided
if [ ! -z "$1" ]; then
  task_name=$1
fi
if [ ! -z "$2" ]; then
  batch_size=$2
fi

# export CUDA_VISIBLE_DEVICES=0,1
export NCCL_P2P_DISABLE=1

# Construct project_name using score_name
project_name="hcp_ts_swift_task5_train1.0"

python main.py \
  --accelerator gpu \
  --max_epochs 30 \
  --num_nodes 1 \
  --strategy ddp \
  --loggername tensorboard \
  --clf_head_version v2 \
  --dataset_name HCPTASK \
  --image_path ./data/HCPTASK_preprocessed \
  --batch_size "$batch_size" \
  --num_workers "$batch_size" \
  --project_name "$project_name" \
  --limit_training_samples 1.0 \
  --c_multiplier 2 \
  --last_layer_full_MSA True \
  --downstream_task_id 5 \
  --downstream_task_type classification \
  --num_classes 7 \
  --task_name "state_classification" \
  --dataset_split_num 1 \
  --seed 1 \
  --learning_rate 5e-5 \
  --model swift \
  --depth 2 2 6 2 \
  --embed_dim 36 \
  --sequence_length 40 \
  --first_window_size 4 4 4 4 \
  --window_size 4 4 4 4 \
  --img_size 96 96 96 40 \
  --test_only \
  --test_ckpt_path ./output/volume-based/hcp_ts_swift_task5_train1.0/checkpt-epoch=26-valid_acc=0.24.ckpt