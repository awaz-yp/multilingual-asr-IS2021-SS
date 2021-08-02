#!/bin/bash

# Copyright 2017 Johns Hopkins University (Shinji Watanabe)
#  Apache 2.0  (http://www.apache.org/licenses/LICENSE-2.0)

. ./path.sh || exit 1;
. ./cmd.sh || exit 1;

# general configuration
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

preprocess_config=conf/specaug_generalized.yaml
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

train_set=train_all
train_set_actual=train_all
train_sp=train_all_sp
train_dev=dev
train_test=dev
#recog_set="Gujarati_test Hindi_test Odia_test Tamil_test Telugu_test Marathi_test"
recog_set="Tamil_test Telugu_test Marathi_test"


if [ ${stage} -le -1 ] && [ ${stop_stage} -ge -1 ]; then
    echo "stage -1: Data Download"
    for part in dev-clean test-clean dev-other test-other train-clean-100 train-clean-360 train-other-500; do
        local/download_and_untar.sh ${datadir} ${data_url} ${part}
    done
fi

if [ ${stage} -le 0 ] && [ ${stop_stage} -ge 0 ]; then
    ### Task dependent. You have to make data the following preparation part by yourself.
    ### But you can utilize Kaldi recipes in most cases
    echo "stage 0: Data preparation"
    for part in dev-clean test-clean dev-other test-other train-clean-100 train-clean-360 train-other-500; do
        # use underscore-separated names in data directories.
        local/data_prep.sh ${datadir}/LibriSpeech/${part} data/${part//-/_}
    done
fi

feat_tr_dir=${dumpdir}/${train_set}/delta${do_delta}; mkdir -p ${feat_tr_dir}
feat_sp_dir=${dumpdir}/${train_sp}/delta${do_delta}; mkdir -p ${feat_sp_dir}
feat_dt_dir=${dumpdir}/${train_dev}/delta${do_delta}; mkdir -p ${feat_dt_dir}
if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
    ### Task dependent. You have to design training and dev sets by yourself.
    ### But you can utilize Kaldi recipes in most cases
    echo "stage 1: Feature Generation"
    fbankdir=fbank
    # Generate the fbank features; by default 80-dimensional fbanks with pitch on each frame
    
    #for x in Hindi_train Hindi_test Gujarati_train Gujarati_test Marathi_train Marathi_test Tamil_train Tamil_test Telugu_train Telugu_test Odia_train Odia_test; do

    #for x in Telugu_train Telugu_test; do
    #    steps/make_fbank.sh --cmd "$train_cmd" --nj ${nj} --write_utt2num_frames true \
    #        data/${x} exp/make_fbank/${x} ${fbankdir}
    #    utils/fix_data_dir.sh data/${x}
    #done

    #utils/combine_data.sh --extra_files utt2num_frames --extra_files feats.scp data/${train_set}_orig data/Hindi_train data/Gujarati_train data/Marathi_train data/Telugu_train data/Tamil_train data/Odia_train
    #utils/combine_data.sh --extra_files utt2num_frames --extra_files feats.scp  data/${train_dev}_orig data/Hindi_test data/Gujarati_test data/Marathi_test data/Telugu_test data/Tamil_test data/Odia_test

    # remove utt having more than 3000 frames
    # remove utt having more than 400 characters
    #remove_longshortdata.sh --maxframes 3000 --maxchars 400 data/${train_set}_orig data/${train_set}
    #remove_longshortdata.sh --maxframes 3000 --maxchars 400 data/${train_dev}_orig data/${train_dev}
    
    #utils/combine_data.sh --extra_files utt2num_frames data/${train_dev}_org data/dev_clean data/dev_other
    
    #utils/perturb_data_dir_speed.sh 0.9  data/train_all  data/temp1
    #utils/perturb_data_dir_speed.sh 1.0  data/train_all  data/temp2
    #utils/perturb_data_dir_speed.sh 1.1  data/train_all  data/temp3

    #utils/perturb_data_dir_speed.sh 0.9  data/dev  data/temp1
    #utils/perturb_data_dir_speed.sh 1.0  data/dev  data/temp2
    #utils/perturb_data_dir_speed.sh 1.1  data/dev  data/temp3

    #utils/combine_data.sh --extra-files utt2uniq data/train_dev_all_sp data/train_all_sp data/temp1 data/temp2 data/temp3
    
    #utils/data/perturb_data_dir_volume.sh ${train_sp}

    #steps/make_fbank.sh --cmd "$train_cmd" --nj $nj  --write_utt2num_frames true \
    #    data/train_dev_all_sp  exp/make_fbank/train_dev_all_sp  ${fbankdir}
    
    #utils/fix_data_dir.sh data/${train_sp}
    # compute global CMVN
    
   # compute-cmvn-stats scp:data/${train_sp}/feats.scp data/${train_sp}/cmvn.ark

    # dump features for training
    dump.sh --cmd "$train_cmd" --nj ${nj} --do_delta ${do_delta} \
        data/train_dev_all_sp/feats.scp data/train_all/cmvn.ark exp/dump_feats/train ${feat_sp_dir}
    #dump.sh --cmd "$train_cmd" --nj ${nj} --do_delta ${do_delta} \
    #    data/${train_dev}/feats.scp data/${train_sp}/cmvn.ark exp/dump_feats/dev ${feat_dt_dir}
    
    #for rtask in ${recog_set}; do
    #    feat_recog_dir=${dumpdir}/${rtask}/delta${do_delta}; mkdir -p ${feat_recog_dir}
    #    dump.sh --cmd "$train_cmd" --nj ${nj} --do_delta ${do_delta} \
    #        data/${rtask}/feats.scp data/${train_sp}/cmvn.ark exp/dump_feats/recog/${rtask} \
    #        ${feat_recog_dir}
    #done
fi

dict=data/lang_char/${train_set}_${bpemode}${nbpe}_units.txt
bpemodel=data/lang_char/${train_set}_${bpemode}${nbpe}
echo "dictionary: ${dict}"
if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
    ### Task dependent. You have to check non-linguistic symbols used in the corpus.
    echo "stage 2: Dictionary and Json Data Preparation"
    mkdir -p data/lang_char/
    
    #echo "<unk> 1" > ${dict} # <unk> must be 1, 0 will be used for "blank" in CTC
    #cut -f 2- -d" " data/${train_set}/text > data/lang_char/input.txt
    #spm_train --input=data/lang_char/input.txt --vocab_size=${nbpe} --model_type=${bpemode} --model_prefix=${bpemodel} --input_sentence_size=100000000
    #spm_encode --model=${bpemodel}.model --output_format=piece < data/lang_char/input.txt | tr ' ' '\n' | sort | uniq | awk '{print $0 " " NR+1}' >> ${dict}
    #wc -l ${dict}

    # make json labels
    data2json.sh --nj ${nj} --feat ${feat_sp_dir}/feats.scp --bpecode ${bpemodel}.model \
        data/${train_sp} ${dict} > ${feat_sp_dir}/data_${bpemode}${nbpe}.json
    #data2json.sh --nj ${nj} --feat ${feat_dt_dir}/feats.scp --bpecode ${bpemodel}.model \
    #    data/${train_dev} ${dict} > ${feat_dt_dir}/data_${bpemode}${nbpe}.json

   # for rtask in ${recog_set}; do
   #     feat_recog_dir=${dumpdir}/${rtask}/delta${do_delta}
   #     data2json.sh --nj ${nj} --feat ${feat_recog_dir}/feats.scp --bpecode ${bpemodel}.model \
   #         data/${rtask} ${dict} > ${feat_recog_dir}/data_${bpemode}${nbpe}.json
   # done
fi

# You can skip this and remove --rnnlm option in the recognition (stage 5)
#if [ -z ${lmtag} ]; then
#    lmtag=$(basename ${lm_config%.*})
#fi


if [ -z ${lmtag} ]; then
      lmtag=$(basename ${lm_config%.*})
      if [ ${use_wordlm} = true ]; then
          lmtag=${lmtag}_word${lm_vocabsize}
      fi
fi

lmexpname=train_rnnlm_${backend}_${lmtag}
lmexpdir=exp/${lmexpname}



if [ ${stage} -le 3 ] && [ ${stop_stage} -ge 3 ] && ! ${skip_lm_training}; then
    echo "stage 3: LM Preparation"

    #if [ -z ${lmtag} ]; then
    #    lmtag=$(basename ${lm_config%.*})
    #    if [ ${use_wordlm} = true ]; then
    #        lmtag=${lmtag}_word${lm_vocabsize}
    #    fi
    #fi
    #lmexpname=train_rnnlm_${backend}_${lmtag}
    #lmexpdir=exp/${lmexpname}
    mkdir -p ${lmexpdir}

    if [ ${use_wordlm} = true ]; then
        lmdatadir=data/local/wordlm_train
        lmdict=${lmdatadir}/wordlist_${lm_vocabsize}.txt
        mkdir -p ${lmdatadir}
        cut -f 2- -d" " data/${train_set}/text > ${lmdatadir}/train_trans.txt
        #zcat ${wsj1}/13-32.1/wsj1/doc/lng_modl/lm_train/np_data/{87,88,89}/*.z \
        #        | grep -v "<" | tr "[:lower:]" "[:upper:]" > ${lmdatadir}/train_others.txt
        cut -f 2- -d" " data/${train_dev}/text > ${lmdatadir}/valid.txt
        cut -f 2- -d" " data/${train_test}/text > ${lmdatadir}/test.txt
        cat ${lmdatadir}/train_trans.txt ${lmdatadir}/train_others.txt > ${lmdatadir}/train.txt
        text2vocabulary.py -o ${lmdict} ${lmdatadir}/train.txt
    else
        lmdatadir=data/local/lm_train
        lmdict=${dict}
        mkdir -p ${lmdatadir}
        #text2token.py -s 1 -n 1 -l ${nlsyms} data/${train_set}/text \
        #    | cut -f 2- -d" " > ${lmdatadir}/train_trans.txt
        
	#zcat ${wsj1}/13-32.1/wsj1/doc/lng_modl/lm_train/np_data/{87,88,89}/*.z \
        #    | grep -v "<" | tr "[:lower:]" "[:upper:]" \
        #    | text2token.py -n 1 | cut -f 2- -d" " > ${lmdatadir}/train_others.txt
        
	#text2token.py -s 1 -n 1 -l ${nlsyms} data/${train_dev}/text \
        #    | cut -f 2- -d" " > ${lmdatadir}/valid.txt
        #text2token.py -s 1 -n 1 -l ${nlsyms} data/${train_test}/text \
        #        | cut -f 2- -d" " > ${lmdatadir}/test.txt
        #cat ${lmdatadir}/train_trans.txt > ${lmdatadir}/train.txt
    fi

    ${cuda_cmd} --gpu ${ngpu} ${lmexpdir}/train.log \
        lm_train.py \
        --config ${lm_config} \
        --ngpu ${ngpu} \
        --backend ${backend} \
        --verbose 1 \
        --outdir ${lmexpdir} \
        --tensorboard-dir tensorboard/${lmexpname} \
        --train-label ${lmdatadir}/train.txt \
        --valid-label ${lmdatadir}/valid.txt \
        --test-label ${lmdatadir}/test.txt \
        --resume ${lm_resume} \
        --dict ${lmdict}
fi


if [ -z ${tag} ]; then
    expname=${train_set_actual}_${backend}_$(basename ${train_config%.*})
    if ${do_delta}; then
        expname=${expname}_delta
    fi
    if [ -n "${preprocess_config}" ]; then
        expname=${expname}_$(basename ${preprocess_config%.*})
    fi
else
    expname=${train_set_actual}_${backend}_${tag}
fi
expdir=exp/${expname}
mkdir -p ${expdir}

if [ ${stage} -le 4 ] && [ ${stop_stage} -ge 4 ]; then
    echo "stage 4: Network Training"
   
    ./run.pl --gpu ${ngpu} ${expdir}/train.log \
        asr_train.py \
        --config ${train_config} \
        --preprocess-conf ${preprocess_config} \
        --ngpu ${ngpu} \
        --backend ${backend} \
        --outdir ${expdir}/results \
        --tensorboard-dir tensorboard/${expname} \
        --debugmode ${debugmode} \
        --dict ${dict} \
        --debugdir ${expdir} \
        --minibatches ${N} \
        --verbose ${verbose} \
        --resume ${resume} \
        --train-json ${feat_sp_dir}/data_${bpemode}${nbpe}.json \
        --valid-json ${feat_dt_dir}/data_${bpemode}${nbpe}.json
fi

if [ ${stage} -le 5 ] && [ ${stop_stage} -ge 5 ]; then
    echo "stage 5: Decoding"
    if [[ $(get_yaml.py ${train_config} model-module) = *transformer* ]] || \
           [[ $(get_yaml.py ${train_config} model-module) = *conformer* ]] || \
           [[ $(get_yaml.py ${train_config} etype) = transformer ]] || \
           [[ $(get_yaml.py ${train_config} dtype) = transformer ]]; then
        # Average ASR models
        if ${use_valbest_average}; then
            recog_model=model.val${n_average}.avg.best
            opt="--log ${expdir}/results/log"
        else
            recog_model=model.last${n_average}.avg.best
            opt="--log"
        fi
        average_checkpoints.py \
            ${opt} \
            --backend ${backend} \
            --snapshots ${expdir}/results/snapshot.ep.* \
            --out ${expdir}/results/${recog_model} \
            --num ${n_average}

        # Average LM models
        if [ ${lm_n_average} -eq 0 ]; then
            lang_model=rnnlm.model.best
        else
            if ${use_lm_valbest_average}; then
                lang_model=rnnlm.val${lm_n_average}.avg.best
                opt="--log ${lmexpdir}/log"
            else
                lang_model=rnnlm.last${lm_n_average}.avg.best
                opt="--log"
            fi
            average_checkpoints.py \
                ${opt} \
                --backend ${backend} \
                --snapshots ${lmexpdir}/snapshot.ep.* \
                --out ${lmexpdir}/${lang_model} \
                --num ${lm_n_average}
        fi
    fi

    pids=() # initialize pids
    for rtask in ${recog_set}; do
    (
        decode_dir=decode_${rtask}_${recog_model}_$(basename ${decode_config%.*})_${lmtag}
        feat_recog_dir=${dumpdir}/${rtask}/delta${do_delta}

        # split data
        splitjson.py --parts ${nj} ${feat_recog_dir}/data_${bpemode}${nbpe}.json

        #### use CPU for decoding
        ngpu=0

        # set batchsize 0 to disable batch decoding
        ./run.pl --max-jobs-run 12 JOB=1:${nj} ${expdir}/${decode_dir}/log/decode.JOB.log \
            asr_recog.py \
            --config ${decode_config} \
            --ngpu ${ngpu} \
            --backend ${backend} \
            --batchsize 0 \
            --recog-json ${feat_recog_dir}/split${nj}utt/data_${bpemode}${nbpe}.JOB.json \
            --result-label ${expdir}/${decode_dir}/data.JOB.json \
            --model ${expdir}/results/${recog_model}  \
	    --rnnlm ${lmexpdir}/${lang_model} \
            --api v2

        score_sclite.sh --bpe ${nbpe} --bpemodel ${bpemodel}.model --wer true ${expdir}/${decode_dir} ${dict}

    ) 
    pids+=($!) # store background pids
    done
    i=0; for pid in "${pids[@]}"; do wait ${pid} || ((++i)); done
    [ ${i} -gt 0 ] && echo "$0: ${i} background jobs are failed." && false
    echo "Finished"
fi
