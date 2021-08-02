#!/bin/bash
# Copyright   2020   Tata Consulstancy Services (Author: Meet Soni)


. ./cmd.sh
. ./path.sh
set -e
mfccdir=`pwd`/mfcc
vaddir=`pwd`/mfcc
fbankdir=`pwd`/fbank_lID

voxceleb2_root=/home/meet/Databases/voxceleb/voxceleb2
musan_root=/home/meet/Databases/musan
nnet_dir=exp/lang_ID
nnet_dir_main=exp/xvector_nnet_1a
nj=32

stage=5

if [ $stage -le 5 ]; then


steps/make_fbank.sh --fbank-config conf/fbank_langID.conf --cmd "$train_cmd" --nj ${nj} --write_utt2num_frames true \
          data/blind_testset_subtask1_langID exp/make_fbank/${x} ${fbankdir}

fi

<<Done

#Stages 6 through 8 are handled in run_xvector.sh
local/nnet3/xvector/run_xvector_LID.sh \
  --data data/train_all_langID --nnet-dir $nnet_dir --stage $stage \
  --egs-dir $nnet_dir/egs



if [ $stage -le 9 ]; then
  # Extract x-vectors for centering, LDA, and PLDA training.

#sid/nnet3/xvector/extract_xvectors.sh --cmd "$train_cmd --mem 4G" --nj 12 \
#    $nnet_dir data/sdsv_challenge_task2.enroll \
#    $nnet_dir/LID_sdsv_challenge_task2.enroll

sid/nnet3/xvector/extract_xvectors.sh --cmd "$train_cmd --mem 4G" --nj 12 \
    $nnet_dir data/sdsv_challenge_task2.test \
    $nnet_dir/LID_sdsv_challenge_task2.test
fi

if [ $stage -le 10 ]; then
python python_codes/apply_lang_ID.py

./utils/filter_scp.pl exp/lang_ID/LID_sdsv_challenge_task2.test/utt_english $nnet_dir_main/xvectors_sdsv_challenge_task2.test/xvector.scp > exp/lang_ID/LID_sdsv_challenge_task2.test/xvector_english.scp

./utils/filter_scp.pl exp/lang_ID/LID_sdsv_challenge_task2.test/utt_persian $nnet_dir_main/xvectors_sdsv_challenge_task2.test/xvector.scp > exp/lang_ID/LID_sdsv_challenge_task2.test/xvector_persian.scp

fi

if [ $stage -le 11 ]; then

#${train_cmd} ${nnet_dir}/LID_sdsv_challenge_task2.test/log/compute_mean_english.log \
#    ivector-mean scp:${nnet_dir}/LID_sdsv_challenge_task2.test/xvector_english.scp \
#    ${nnet_dir}/LID_sdsv_challenge_task2.test/mean_english.vec || exit 1;

#${train_cmd} ${nnet_dir}/LID_sdsv_challenge_task2.test/log/compute_mean_persian.log \
#    ivector-mean scp:${nnet_dir}/LID_sdsv_challenge_task2.test/xvector_persian.scp \
#    ${nnet_dir}/LID_sdsv_challenge_task2.test/mean_persian.vec || exit 1;


ivector-subtract-global-mean exp/xvector_nnet_1a/xvectors_train_voxceleb_mean_sub/mean.vec scp:${nnet_dir}/LID_sdsv_challenge_task2.test/xvector_english.scp ark,scp:${nnet_dir}/LID_sdsv_challenge_task2.test/xvector_english_mean_sub.ark,${nnet_dir}/LID_sdsv_challenge_task2.test/xvector_english_mean_sub.scp

ivector-subtract-global-mean exp/xvector_nnet_1a/xvectors_train_voxceleb_mean_sub/mean.vec scp:${nnet_dir}/LID_sdsv_challenge_task2.test/xvector_persian.scp ark,scp:${nnet_dir}/LID_sdsv_challenge_task2.test/xvector_persian_mean_sub.ark,${nnet_dir}/LID_sdsv_challenge_task2.test/xvector_persian_mean_sub.scp

cat ${nnet_dir}/LID_sdsv_challenge_task2.test/xvector_english_mean_sub.scp ${nnet_dir}/LID_sdsv_challenge_task2.test/xvector_persian_mean_sub.scp | sort -u > ${nnet_dir}/LID_sdsv_challenge_task2.test/xvectors_lang_mean_sub.scp

fi


if [[ ${stage} -le 12 ]]; then

echo "Do the scoring..."

  for name in sdsv_challenge_task2; do
    ${train_cmd} ${nnet_dir_main}/scores/log/${name}_scoring.log \
      ivector-plda-scoring --normalize-length=true \
      --num-utts=ark:${nnet_dir_main}/xvectors_${name}.enroll/num_utts.ark \
      "ivector-copy-plda --smoothing=0.0 ${nnet_dir_main}/xvectors_train/plda_train_lang_mean - |" \
      "ark:ivector-mean ark:data/${name}.enroll/spk2utt scp:${nnet_dir_main}/xvectors_${name}.enroll/xvector.scp ark:- | ivector-subtract-global-mean ${nnet_dir_main}/xvectors_train/mean.vec ark:- ark:- | transform-vec ${nnet_dir_main}/xvectors_train/transform_lang_mean.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
      "ark:transform-vec ${nnet_dir_main}/xvectors_train/transform_lang_mean.mat scp:${nnet_dir}/LID_${name}.test/xvectors_lang_mean_sub.scp ark:- | ivector-normalize-length ark:- ark:- |" \
      "cat 'data/${name}.test/trials' | cut -d\  --fields=1,2 |" ${nnet_dir_main}/scores/${name}_scores_train_lang_mean_after_LID || exit 1;
  done

fi

Done
