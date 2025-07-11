<div align="center">    
 
# NeuroSTORM: Towards a general-purpose foundation model for fMRI analysis

</div>

<div align="center">
  <a href='LICENSE'><img src='https://img.shields.io/badge/license-MIT-yellow'></a>
  <a href='https://www.researchsquare.com/article/rs-6728658/v1'><img src='https://img.shields.io/badge/Preprint-NeuroSTORM-red'></a>  &nbsp;
  <a href='https://cuhk-aim-group.github.io/NeuroSTORM/'><img src='https://img.shields.io/badge/Project-NeuroSTORM-green'></a> &nbsp;
  <a href='https://github.com/CUHK-AIM-Group/NeuroSTORM'><img src="https://img.shields.io/badge/GitHub-NeuroSTORM-9E95B7?logo=github"></a> &nbsp; 
  <a href=''><img src='https://img.shields.io/badge/%F0%9F%A4%97%20Model-NeuroSTORM-blue'></a> &nbsp; 
  <br>
</div>


## Introduction

This repo provides a platform that covers all aspects involved in using deep learning for fMRI analysis. It is moderately encapsulated, highly customizable, and supports most common tasks and methods out of the box. 

This platform is proposed in our paper *Towards a General-Purpose Foundation Model for fMRI Analysis*. NeuroSTORM is a pretrained fMRI foundation model developed by the AIM group for fMRI analysis. You can run the pre-training and fine-tuning of NeuroSTORM in this repo. Specifically, our code provides the following:

- Preprocessing tools for fMRI volumes. You can use the tools to process fMRI volumes in MNI152 space into a unified 4D Volume (for models like NeuroSTORM), 2D time series d   ata (for models like BNT), and 2D Functional Correlation Matrix (for models like BrainGNN).
- Trainer for pre-training, including the MAE-based mechanism proposed in NeuroSTORM and the contrastive learning approach in SwiFT.
- Trainer for fine-tuning, including both fully learnable parameters and Task-specific Prompt Learning as proposed in NeuroSTORM.
- A comprehensive fMRI benchmark, including five tasks: Age and Gender Prediction, Phenotype Prediction, Disease Diagnosis, fMRI Retrieval, and Task fMRI State Classification.
- Implementations of NeuroSTORM and other commonly used fMRI analysis models.
- Customization options for all stages. You can quickly add custom preprocessing procedures, pre-training methods, fine-tuning strategies, new downstream tasks, and implement other models on the platform.


## 🚀 Updates
* __[2025.06.10]__: Release the [project website](https://cuhk-aim-group.github.io/NeuroSTORM/). Welcome to visit!
* __[2025.02.13]__: Release the code of NeuroSTORM model, (volume&ROI) data pre-processing, and benchmark (task1&2&3&5)


## 1. How to install
We highly recommend you to use our conda environment.
```bash
# create virtual environment
cd NeuroSTORM
conda create -n neurostorm python=3.10
conda activate neurostorm

# upgrade gcc compiler (optional)
conda install gcc_impl_linux-64=11.2.0
ln -s /path/to/anaconda3/envs/neurostorm/libexec/gcc/x86_64-conda-linux-gnu/11.2.0/gcc /path/to/anaconda3/envs/neurostorm/bin/gcc
conda install gxx_linux-64=11.2.0
conda install ninja

# set environment variables for gcc 11.2 and cuda 11.8 (optional)
source ./set_env.sh

# install dependencies
pip install torch==2.1.0 torchvision==0.16.0 torchaudio==2.1.0 --index-url https://download.pytorch.org/whl/cu118
pip install tensorboard tensorboardX tqdm ipdb nvitop monai==1.3.0 
pip install pytorch-lightning==1.9.4 neptune nibabel nilearn numpy==1.22.4

# install mamba_ssm, it may takes a few minutes to download the .whl files
pip install https://github.com/Dao-AILab/causal-conv1d/releases/download/v1.5.0.post8/causal_conv1d-1.5.0.post8+cu11torch2.1cxx11abiTRUE-cp310-cp310-linux_x86_64.whl
pip install https://github.com/state-spaces/mamba/releases/download/v2.2.2/mamba_ssm-2.2.2+cu118torch2.1cxx11abiFALSE-cp310-cp310-linux_x86_64.whl
 ```

If you encounter issues when installing PyTorch and mamba_ssm, please try upgrading the GCC compiler and setting environment variables to ensure the correct versions of the GCC compiler and CUDA are being used.


## 2. Project Structure
Our directory structure looks like this:

```
├── datasets                           <- tools and dataset class
│   ├── atlas                          <- examples of brain atlas
│   ├── preprocessing_volume.py        <- remove background, z-normalization, save as pt files
│   └── generate_roi_data_from_nii.py  <- 2D rois data and functional correlation matrix
│
├── models                 
│   ├── heads                          <- task heads
│   │   ├── cls_head.py                <- for classification tasks
│   │   ├── reg_head.py                <- for regression tasks
│   │   └── swift.py                   <- for contrastive learning
│   ├── load_model.py                  <- load any backbone or head network
│   ├── neurostorm.py                  <- NeuroSTORM
│   ├── lightning_model.py             <- the basic lightning model class
│   └── swift.py                       <- SwiFT
│
├── pretrained_models                  <- pre-trained model checkpoints 
├── scripts                 
│   ├── abcd_pretrain                  <- scripts for pre-training in ABCD
│   ├── adhd200_downstream             <- scripts for fine-tuning in ADHD200
│   ├── ... 
│   └── custom                         <- customize the run script, specify the dataset, model name, model parameters, task type, and head net
│ 
├── utils                              <- utils codes
│
├── .gitignore                         <- list of files/folders ignored by git
├── main.py                            <- the program entry for the fMRI analysis platform
├── set_envs.py                        <- set the environment variables
└── README.md
```

<br>

## 3. Prepare Datasets

### 3.1 Pre-processing

First, please ensure that you have applied a primary processing pipeline, such as [FSL](https://fsl.fmrib.ox.ac.uk/fsl/docs/#/), [fMRIPrep](https://fmriprep.org/en/stable/), or [HCP pipeline](https://github.com/Washington-University/HCPpipelines), and that your data has been aligned into MNI152 space. You can also use our provided shell script for brain extraction. It is based on FSL BET, so you need install [FSL tool](https://fsl.fmrib.ox.ac.uk/fsl/docs/#/). After running the script, brain mask files in the nii.gz format will be generated in the output directory.


```bash
cd NeuroSTORM/datasets
bash brain_extraction.sh /path/to/your/dataset /path/to/output/dataset
```


After that, we provide a tool to prepare your data for model input. With this tool, you can preprocess all supported datasets in bulk, which includes background removal, resampling to fixed spatial and temporal resolution (via interpolation algorithms or by discarding certain slices), Z-normalization, and saving each frame as a .pt file. If your CPU computational power is limited, we recommend preprocessing all datasets in advance. However, if your training bottleneck lies in disk read speed, you may choose to skip this step and process the data online during training.


Here is an example of pre-processing HCP-YA dataset:

```bash
cd NeuroSTORM/datasets
python preprocessing_volume.py --dataset_name hcp --load_root ./data/hcp --save_root ./processed_data/hcp --num_processes 8
```

We recommend setting the number of processes to match the number of idle CPU cores to speed up processing. If you need to delete the original files to free up disk space, you can use `--delete_after_preprocess`, and the tool will delete the original data after processing each sequence. If you didn't delete them during runtime, you can run the tool again and use `--delete_nii`. The tool will check if preprocessed files exist in the output folder and then delete the original files.


### 3.2 Convert 4D Volume to 2D ROIs data

If you need 2D ROIs data, we provide several available brain atlases and data conversion tools. You can process one or multiple datasets simultaneously and use one or multiple brain atlases at the same time. Here is an example:

```bash
cd NeuroSTORM/datasets
python generate_roi_data_from_nii.py --atlas_names aal3 cc200 --dataset_names hcp ucla --output_dir ./processed_data --num_processes 32
 ```

We recommend setting the number of processes to match the number of idle CPU cores to speed up processing. We also provide code for computing the Functional Correlation Matrix. For details, refer to [BrainGNN](https://github.com/LifangHe/BrainGNN_Pytorch/tree/main). You can use it by:


 ```bash
cd NeuroSTORM/datasets
# To be relased
 ```


## 4. Train model

### 4.0 Quick start

You can use our prepared running scripts to quickly reproduce the experiments from the paper.

```bash
cd NeuroSTORM
bash scripts/hcp_downstream/ts_neurostorm_task2.sh
 ```


### 4.1 Customize pre-training scripts
Here is the arguments list of main.py

```
usage: main.py [-h] [--seed SEED] [--dataset_name {HCP1200,ABCD,UKB,Cobre,ADHD200,HCPA,HCPD,UCLA,HCPEP,HCPTASK,GOD,NSD,BOLD5000}] [--downstream_task_id DOWNSTREAM_TASK_ID]
               [--downstream_task_type DOWNSTREAM_TASK_TYPE] [--task_name TASK_NAME] [--loggername LOGGERNAME] [--project_name PROJECT_NAME] [--resume_ckpt_path RESUME_CKPT_PATH]
               [--load_model_path LOAD_MODEL_PATH] [--test_only] [--test_ckpt_path TEST_CKPT_PATH] [--freeze_feature_extractor] [--print_flops] [--grad_clip] [--optimizer OPTIMIZER]
               [--use_scheduler] [--weight_decay WEIGHT_DECAY] [--learning_rate LEARNING_RATE] [--momentum MOMENTUM] [--gamma GAMMA] [--cycle CYCLE] [--milestones MILESTONES [MILESTONES ...]]
               [--use_contrastive] [--contrastive_type CONTRASTIVE_TYPE] [--use_mae] [--spatial_mask SPATIAL_MASK] [--time_mask TIME_MASK] [--mask_ratio MASK_RATIO]
               [--pretraining] [--augment_during_training] [--augment_only_affine] [--augment_only_intensity] [--temperature TEMPERATURE] [--model MODEL] [--in_chans IN_CHANS]
               [--num_classes NUM_CLASSES] [--embed_dim EMBED_DIM] [--window_size WINDOW_SIZE [WINDOW_SIZE ...]] [--first_window_size FIRST_WINDOW_SIZE [FIRST_WINDOW_SIZE ...]]
               [--patch_size PATCH_SIZE [PATCH_SIZE ...]] [--depths DEPTHS [DEPTHS ...]] [--num_heads NUM_HEADS [NUM_HEADS ...]] [--c_multiplier C_MULTIPLIER]
               [--last_layer_full_MSA LAST_LAYER_FULL_MSA] [--clf_head_version CLF_HEAD_VERSION] [--attn_drop_rate ATTN_DROP_RATE] [--scalability_check] [--process_code PROCESS_CODE]
               [--dataset_split_num DATASET_SPLIT_NUM] [--label_scaling_method {minmax,standardization}] [--image_path IMAGE_PATH] [--bad_subj_path BAD_SUBJ_PATH] [--train_split TRAIN_SPLIT]
               [--val_split VAL_SPLIT] [--batch_size BATCH_SIZE] [--eval_batch_size EVAL_BATCH_SIZE] [--img_size IMG_SIZE [IMG_SIZE ...]] [--sequence_length SEQUENCE_LENGTH]
               [--stride_between_seq STRIDE_BETWEEN_SEQ] [--stride_within_seq STRIDE_WITHIN_SEQ] [--num_workers NUM_WORKERS] [--with_voxel_norm WITH_VOXEL_NORM] [--shuffle_time_sequence]
               [--limit_training_samples LIMIT_TRAINING_SAMPLES]

options:
  -h, --help            show this help message and exit
  --seed SEED           random seeds. recommend aligning this argument with data split number to control randomness (default: 1234)
  --dataset_name {HCP1200,ABCD,UKB,Cobre,ADHD200,HCPA,HCPD,UCLA,HCPEP,HCPTASK,GOD,NSD,BOLD5000}
  --downstream_task_id DOWNSTREAM_TASK_ID
                        downstream task id (default: 1)
  --downstream_task_type DOWNSTREAM_TASK_TYPE
                        select either classification or regression according to your downstream task (default: classification)
  --task_name TASK_NAME
                        specify the task name (default: sex)
  --loggername LOGGERNAME
                        A name of logger (default: default)
  --project_name PROJECT_NAME
                        A name of project (default: default)
  --resume_ckpt_path RESUME_CKPT_PATH
                        A path to previous checkpoint. Use when you want to continue the training from the previous checkpoints (default: None)
  --load_model_path LOAD_MODEL_PATH
                        A path to the pre-trained model weight file (.pth) (default: None)
  --test_only           specify when you want to test the checkpoints (model weights) (default: False)
  --test_ckpt_path TEST_CKPT_PATH
                        A path to the previous checkpoint that intends to evaluate (--test_only should be True) (default: None)
  --freeze_feature_extractor
                        Whether to freeze the feature extractor (for evaluating the pre-trained weight) (default: False)
  --print_flops         Whether to print the number of FLOPs (default: False)

Default classifier:
  --grad_clip           whether to use gradient clipping (default: False)
  --optimizer OPTIMIZER
                        which optimizer to use [AdamW, SGD] (default: AdamW)
  --use_scheduler       whether to use scheduler (default: False)
  --weight_decay WEIGHT_DECAY
                        weight decay for optimizer (default: 0.01)
  --learning_rate LEARNING_RATE
                        learning rate for optimizer (default: 0.001)
  --momentum MOMENTUM   momentum for SGD (default: 0)
  --gamma GAMMA         decay for exponential LR scheduler (default: 1.0)
  --cycle CYCLE         cycle size for CosineAnnealingWarmUpRestarts (default: 0.3)
  --milestones MILESTONES [MILESTONES ...]
                        lr scheduler (default: [100, 150])
  --use_contrastive     whether to use contrastive learning (specify --contrastive_type argument as well) (default: False)
  --contrastive_type CONTRASTIVE_TYPE
                        combination of contrastive losses to use [1: Use the Instance contrastive loss function, 2: Use the local-local temporal contrastive loss function, 3: Use the sum of
                        both loss functions] (default: 0)
  --use_mae             whether to use mae (default: False)
  --spatial_mask SPATIAL_MASK
                        spatial mae strategy (default: random)
  --time_mask TIME_MASK
                        time mae strategy (default: random)
  --mask_ratio MASK_RATIO
                        mae masking ratio (default: 0.1)
  --pretraining         whether to use pretraining (default: False)
  --augment_during_training
                        whether to augment input images during training (default: False)
  --augment_only_affine
                        whether to only apply affine augmentation (default: False)
  --augment_only_intensity
                        whether to only apply intensity augmentation (default: False)
  --temperature TEMPERATURE
                        temperature for NTXentLoss (default: 0.1)
  --model MODEL         which model to be used (default: none)
  --in_chans IN_CHANS   Channel size of input image (default: 1)
  --num_classes NUM_CLASSES
  --embed_dim EMBED_DIM
                        embedding size (recommend to use 24, 36, 48) (default: 24)
  --window_size WINDOW_SIZE [WINDOW_SIZE ...]
                        window size from the second layers (default: [4, 4, 4, 4])
  --first_window_size FIRST_WINDOW_SIZE [FIRST_WINDOW_SIZE ...]
                        first window size (default: [2, 2, 2, 2])
  --patch_size PATCH_SIZE [PATCH_SIZE ...]
                        patch size (default: [6, 6, 6, 1])
  --depths DEPTHS [DEPTHS ...]
                        depth of layers in each stage (default: [2, 2, 6, 2])
  --num_heads NUM_HEADS [NUM_HEADS ...]
                        The number of heads for each attention layer (default: [3, 6, 12, 24])
  --c_multiplier C_MULTIPLIER
                        channel multiplier for Swin Transformer architecture (default: 2)
  --last_layer_full_MSA LAST_LAYER_FULL_MSA
                        whether to use full-scale multi-head self-attention at the last layers (default: False)
  --clf_head_version CLF_HEAD_VERSION
                        clf head version, v2 has a hidden layer (default: v1)
  --attn_drop_rate ATTN_DROP_RATE
                        dropout rate of attention layers (default: 0)
  --scalability_check   whether to check scalability (default: False)
  --process_code PROCESS_CODE
                        Slurm code/PBS code. Use this argument if you want to save process codes to your log (default: None)

DataModule arguments:
  --dataset_split_num DATASET_SPLIT_NUM
  --label_scaling_method {minmax,standardization}
                        label normalization strategy for a regression task (mean and std are automatically calculated using train set) (default: standardization)
  --image_path IMAGE_PATH
                        path to image datasets preprocessed for SwiFT (default: None)
  --bad_subj_path BAD_SUBJ_PATH
                        path to txt file that contains subjects with bad fMRI quality (default: None)
  --train_split TRAIN_SPLIT
  --val_split VAL_SPLIT
  --batch_size BATCH_SIZE
  --eval_batch_size EVAL_BATCH_SIZE
  --img_size IMG_SIZE [IMG_SIZE ...]
                        image size (adjust the fourth dimension according to your --sequence_length argument) (default: [96, 96, 96, 20])
  --sequence_length SEQUENCE_LENGTH
  --stride_between_seq STRIDE_BETWEEN_SEQ
                        skip some fMRI volumes between fMRI sub-sequences (default: 1)
  --stride_within_seq STRIDE_WITHIN_SEQ
                        skip some fMRI volumes within fMRI sub-sequences (default: 1)
  --num_workers NUM_WORKERS
  --with_voxel_norm WITH_VOXEL_NORM
  --shuffle_time_sequence
  --limit_training_samples LIMIT_TRAINING_SAMPLES
                        use if you want to limit training samples (default: None)
```


### 4.3 Customize fine-tuning scripts

Unlike the pre-training scripts, different downstream tasks will have different input parameters. For example, in the Phenotype Prediction task, predictions are often made on different scores. To avoid creating too many scripts, you can use the score name as an input parameter for the script. Here is an example:

```bash
#!/bin/bash
# bash scripts/hcp_downstream/ft_neurostorm_task1.sh task_name batch_size

# Set default task_name
task_name="sex"
batch_size="12"

# Override with the arguments if provided
if [ ! -z "$1" ]; then
  task_name=$1
fi

if [ "$task_name" = "sex" ]; then
    downstream_task_type="classification"
else
    downstream_task_type="regression"
fi

if [ ! -z "$2" ]; then
  batch_size=$2
fi

# We will use all aviailable GPUs, and automatically set the same batch size for each GPU
export CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7
export NCCL_P2P_DISABLE=1

# Construct project_name using task_name
project_name="hcp_ts_neurostorm_task1_${task_name}_train1.0"

python main.py \
  --accelerator gpu \
  --max_epochs 30 \
  --num_nodes 1 \
  --strategy ddp \
  --loggername tensorboard \
  --clf_head_version v1 \
  --dataset_name HCP1200 \
  --image_path ./data/HCP1200_MNI_to_TRs_minmax \
  --batch_size "$batch_size" \
  --num_workers "$batch_size" \
  --project_name "$project_name" \
  --limit_training_samples 1.0 \
  --c_multiplier 2 \
  --last_layer_full_MSA True \
  --downstream_task_id 1 \
  --downstream_task_type "$downstream_task_type" \
  --task_name "$task_name" \
  --dataset_split_num 1 \
  --seed 1 \
  --learning_rate 5e-5 \
  --model neurostorm \
  --depth 2 2 6 2 \
  --embed_dim 36 \
  --sequence_length 20 \
  --img_size 96 96 96 20 \
  --first_window_size 4 4 4 4 \
  --window_size 4 4 4 4 \
  --load_model_path ./output/neurostorm/pt_neurostorm_mae_ratio0.5.ckpt
 ```


## 5. How to ues your own dataset

First, please refer to the following links to pre-process fMRI sequences and align the fMRI data to MNI152 space or directly download processed fMRI data (please contact to the authors).
- https://fmriprep.org/en/stable/
- https://github.com/Washington-University/HCPpipelines
- https://biobank.ctsu.ox.ac.uk/crystal/crystal/docs/brain_mri.pdf

Next, you can add your dataset in `preprocessing_volume.py`. There are two places need to modify: one is the naming convention for Volume data, located in the `determine_subject_name` function. The second is to confirm the resize method. If your data has similar resolution to HCP-YA, you can use the `select_middle_96` method; otherwise, use the `resize_to_96` method.


```python
def determine_subject_name(dataset_name, filename):
    if dataset_name in ['abcd', 'cobre']:
        return filename.split('-')[1][:-4]
    elif dataset_name == 'adhd200':
        return filename.split('_')[2]
    ...
    elif dataset_name == 'your_dataset':
        return filename # your naming rule
```

```python
def read_data(dataset_name, delete_after_preprocess, filename, load_root, save_root, subj_name, count, queue=None, scaling_method=None, fill_zeroback=False):
    print("processing: " + filename, flush=True)
    path = os.path.join(load_root, filename)
    try:
        data = LoadImage()(path)
    except:
        print('{} open failed'.format(path))
        return None
    
    save_dir = os.path.join(save_root, subj_name)
    isExist = os.path.exists(save_dir)
    if not isExist:
        os.makedirs(save_dir)
    
    # if high-resolution
    if dataset_name in ['ukb', 'abcd', 'hcp', 'hcpd', 'hcpep', 'hcptask']:
        data = select_middle_96(data)
    # if low-resolution
    elif dataset_name in ['adhd200', 'cobre', 'ucla', 'god']:
        data = resize_to_96(data)
    ...
```

## 5. How to use your own network

You can easily create a new Python file in the models folder to define your model, just ensure the format of the forward function is correct. If additional inputs or outputs are needed, you'll need to modify `lightning_model.py`.


```python
class NewModel(nn.Module):
    def __init__(
        self,
        img_size: Tuple,
        in_chans: int,
        embed_dim: int,
        ...,
        **kwargs,
    ) -> None:
        super().__init__()
        # define the network
    
    # if you need specific loss function for this network
    def forward_loss(self, x, pred, mask):
        loss = 0

        return loss

    def forward(self, x):
        pred = self.model(x)
        loss = self.forward_loss(x, pred)

        return pred, loss
```


## 6. How to add a new down-stream task

Defining a new task involves setting labels in the dataset and choosing the head net. First, define the corresponding dataset label format in the function `make_subject_dict` from `data_module.py`.

```python
def make_subject_dict(self):
    img_root = os.path.join(self.hparams.image_path, 'img')
    final_dict = dict()

    if self.hparams.dataset_name == "your dataset":
        subject_list = os.listdir(img_root)
        meta_data = pd.read_csv(os.path.join(self.hparams.image_path, "metadata", "meta_data.csv"))
        if self.hparams.task_name == 'xxx': task_name = 'xxx'
        else: raise NotImplementedError()

        print('task_name = {}'.format(task_name))

        if task_name == 'xxx':
            meta_task = meta_data[['Subject',task_name]].dropna()
        elif task_name == 'age':
            meta_task = meta_data_residual[['subject', task_name, 'sex']].dropna()
            meta_task = meta_task.rename(columns={'subject': 'Subject'})
        
        for subject in subject_list:
            if int(subject) in meta_task['Subject'].values:
                if task_name == 'sex':
                    target = meta_task[meta_task["Subject"]==int(subject)][task_name].values[0]
                    target = 1 if target == "M" else 0
                    sex = target
                elif task_name == 'age':
                    target = meta_task[meta_task["Subject"]==int(subject)][task_name].values[0]
                    sex = meta_task[meta_task["Subject"]==int(subject)]["sex"].values[0]
                    sex = 1 if sex == "M" else 0
                elif task_name == 'xxx':
                    target = meta_task[meta_task["Subject"]==int(subject)][task_name].values[0]
                    sex = meta_task[meta_task["Subject"]==int(subject)]["Gender"].values[0]
                    sex = 1 if sex == "M" else 0
                final_dict[subject] = [sex, target]
        
        print('Load dataset your dataset, {} subjects'.format(len(final_dict)))
```


Then, specify the task type in the script by setting `--downstream_task`.


Finally, choose either a classification or regression head. If you need a custom head, you can add a head net definition in the `models/heads` folder.


```python
class cls_head(nn.Module):
    def __init__(self, version=1, num_classes=2, num_tokens=96):
        super(cls_head, self).__init__()
        if version == 1:
            self.head = cls_head_v1(num_classes, num_tokens)
        elif version == 2:
            self.head = cls_head_v2(num_classes, num_tokens)
        elif version == 3:
            self.head = cls_head_v3(num_classes, num_tokens)
        elif version == 4:
            # add your head net here

    def forward(self, x):
        return self.head(x)
```


## 7. Pretrained model checkpoints
We have provided the checkpoint files on HuggingFace, so you can download these files to your working directory. Also, the code will try to download checkpoint files by HuggingFace API if it cannot find the checkpoint files locally.


## ✏️ Todo List
- [ ] Release code for computing the Functional Correlation Matrix
- [ ] Release code for task 4
- [ ] Support for custmized mamba scanning startegies
- [ ] Support for more pre-training startegies


## Acknowledgements
Greatly appreciate the tremendous effort for the following projects!

- https://github.com/Transconnectome/SwiFT
- https://github.com/LifangHe/BrainGNN_Pytorch
- https://github.com/MedARC-AI/MindEyeV2
- https://fsl.fmrib.ox.ac.uk/fsl/docs
- https://github.com/Washington-University/HCPpipelines
- https://github.com/nipreps/fmriprep

