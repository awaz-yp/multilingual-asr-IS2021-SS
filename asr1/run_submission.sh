#!/bin/bash

# Copyright 2017 Johns Hopkins University (Shinji Watanabe)
#  Apache 2.0  (http://www.apache.org/licenses/LICENSE-2.0)

. ./path.sh || exit 1;
. ./cmd.sh || exit 1;

# general configuration
blind_data_location=
backend=pytorch
stage=3       # start from -1 if you need to start from data download
stop_stage=3
ngpu=1         # number of gpus ("0" uses cpu, otherwise use gpu)
nj=32
debugmode=1
dumpdir=dump   # directory to dump full features
N=0            # number of minibatches to be used (mainly for debugging). "0" uses all minibatches.
verbose=0      # verbose option
resume=        # Resume the training from snapshot

# feature configuration
do_delta=false

preprocess_config=conf/specaug.yaml
train_config=conf/train_960h.yaml # current default recipe requires 4 gpus.
                             # if you do not have 4 gpus, please reconfigure the `batch-bins` and `accum-grad` parameters in config.
lm_config=conf/tuning/lm_transformer.yaml
decode_config=conf/decode_100h.yaml

# rnnlm related
lm_resume= # specify a snapshot file to resume LM training
lmtag=     # tag for managing LMs

# decoding parameter
recog_model=model.acc.best  # set a model to be used for decoding: 'model.acc.best' or 'model.loss.best'
lang_model=rnnlm.model.best # set a language model to be used for decoding

# model average realted (only for transformer)
n_average=5                  # the number of ASR models to be averaged
use_valbest_average=true     # if true, the validation `n_average`-best ASR models will be averaged.
                             # if false, the last `n_average` ASR models will be averaged.
lm_n_average=0               # the number of languge models to be averaged
use_lm_valbest_average=false # if true, the validation `lm_n_average`-best language models will be averaged.
                             # if false, the last `lm_n_average` language models will be averaged.

# Set this to somewhere where you want to put your data, or where
# someone else has already put it.  You'll want to change this
# if you're not on the CLSP grid.
datadir=/home/meet/

# base url for downloads.
data_url=www.openslr.org/resources/12

# bpemode (unigram or bpe)
nbpe=300
bpemode=unigram

use_wordlm=false
skip_lm_training=false
# exp tag
tag="" # tag for managing experiments.

. utils/parse_options.sh || exit 1;

# Set bash to 'debug' mode, it will exit on :
# -e 'error', -u 'undefined variable', -o ... 'error in pipeline',n -x 'print commands',
#set -e
#set -u
#set -o pipefail

recog_set="blind_testset_subtask1"
train_sp=train_all_sp
train_set=train_all

python local/prepare_data_blind_test.py $blind_data_location || exit 1;

for rtask in ${recog_set}; do
  feat_recog_dir=${dumpdir}/${rtask}/delta${do_delta}; mkdir -p ${feat_recog_dir}
    dump.sh --cmd "$train_cmd" --nj ${nj} --do_delta ${do_delta} \
        data/${rtask}/feats.scp data/${train_sp}/cmvn.ark exp/dump_feats/recog/${rtask} \
        ${feat_recog_dir}
done

dict=data/lang_char/${train_set}_${bpemode}${nbpe}_units.txt
bpemodel=data/lang_char/${train_set}_${bpemode}${nbpe}

for rtask in ${recog_set}; do
        feat_recog_dir=${dumpdir}/${rtask}/delta${do_delta}
        data2json.sh --nj ${nj} --feat ${feat_recog_dir}/feats.scp --bpecode ${bpemodel}.model \
            data/${rtask} ${dict} > ${feat_recog_dir}/data_${bpemode}${nbpe}.json
done



do_delta=false
dumpdir=dump
bpemode=unigram
nbpe=300
expdir=exp/train_all_pytorch_70_epoch_Conformer_GenSpecAugment_sp_vp_dev_data_lr5.0_mixedSA
ngpu=0
backend=pytorch
decode_config=conf/decode_100h.yaml
recog_model=model.val5.avg.best
lmexpdir=exp/transformer_lm_10_layer_large
lang_model=rnnlm.model.10
dict=data/lang_char/train_all_${bpemode}${nbpe}_units.txt
bpemodel=data/lang_char/train_all_${bpemode}${nbpe}


for rtask in ${recog_set}; do
    
        decode_dir=decode_${rtask}_large_LM_10_layers_Conformer_GenSpecAug_sp_train_dev_mixSA
        feat_recog_dir=${dumpdir}/${rtask}/delta${do_delta}

        # split data
        splitjson.py --parts ${nj} ${feat_recog_dir}/data_${bpemode}${nbpe}.json

        #### use CPU for decoding
        ngpu=0

        # set batchsize 0 to disable batch decoding
        ./run.pl --max-jobs-run 12 JOB=1:${nj} exp/${decode_dir}/log/decode.JOB.log \
            asr_recog.py \
            --config ${decode_config} \
            --ngpu ${ngpu} \
            --backend ${backend} \
            --batchsize 0 \
			--recog-json ${feat_recog_dir}/split${nj}utt/data_${bpemode}${nbpe}.JOB.json \
			--result-label exp/${decode_dir}/data.JOB.json \
		    --model ${expdir}/results/${recog_model}  \
			--rnnlm ${lmexpdir}/${lang_model} \
		        --api v2
		        
        score_sclite.sh --bpe ${nbpe} --bpemodel ${bpemodel}.model --wer true exp/${decode_dir} ${dict}
        
        python local/submission_prepare.py exp/${decode_dir}/hyp.wrd.trn
	    
    done

#Done
