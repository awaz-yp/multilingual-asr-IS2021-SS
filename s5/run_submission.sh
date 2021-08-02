#!/bin/bash#!/bin/bash#!/bin/bash

. ./cmd.sh
. ./path.sh

#nnet3-latgen-faster-parallel --num-threads=4 --online-ivectors=scp:exp/nnet3/ivectors_test_hires/ivector_online.scp --online-ivector-period=10 --frame-subsampling-factor=3 --frames-per-chunk=140 --extra-left-context=22 --extra-right-context=16 --extra-left-context-initial=0 --extra-right-context-final=0 --minimize=false --max-active=7000 --min-active=200 --beam=15.0 --lattice-beam=8.0 --acoustic-scale=1.0 --allow-partial=true --word-symbol-table=exp/chain2/tree_sp/graph_tgsmall/words.txt exp/chain2/tdnn1a_sp/final.mdl exp/chain2/tree_sp/graph_tgsmall/HCLG.fst 'ark,s,cs:apply-cmvn --norm-means=false --norm-vars=false --utt2spk=ark:data/test_hires/split21185/1/utt2spk scp:data/test_hires/split21185/1/cmvn.scp scp:data/test_hires/split21185/1/feats.scp ark:- |' 'ark:|lattice-scale --acoustic-scale=10.0 ark:- ark:- | gzip -c >exp/chain2/tdnn1a_sp/decode_test/lat.1.gz
stage=0

data_dir=
tree_dir=exp/chain2/tree_sp
dir=exp/chain2/tdnn1a_sp
nj=32

mfccdir=mfcc
nnet3_affix=

if [ $stage -le 0 ]; then
	python local/prepare_data.py $data_dir
fi

if [ $stage -le 1 ]; then
	part=blind_testset_subtask1
        steps/make_mfcc.sh --cmd "$train_cmd" --nj $nj --mfcc-config conf/mfcc_hires.conf data/$part exp/make_mfcc/$part $mfccdir
          utils/fix_data_dir.sh  data/blind_testset_subtask1
	  utils/validate_data_dir.sh data/blind_testset_subtask1
fi

data=blind_testset_subtask1

if [ $stage -le 2 ]; then
    for data in blind_testset_subtask1; do
    steps/online/nnet2/extract_ivectors_online.sh --cmd "$train_cmd" --nj $nj \
      data/${data} exp/nnet3${nnet3_affix}/extractor \
      exp/nnet3${nnet3_affix}/ivectors_${data}
  done


fi


if [ $stage -le 3 ]; then

frames_per_chunk=$(echo $chunk_width | cut -d, -f1)
  # Do the speaker-dependent decoding pass
  test_sets=blind_testset_subtask1

  for data in $test_sets; do
    (
      nspk=$(wc -l <data/${data}/spk2utt)
      steps/nnet3/decode.sh \
          --acwt 1.0 --post-decode-acwt 10.0 \
          --extra-left-context 22 \
          --extra-right-context 16 \
          --extra-left-context-initial 0 \
          --extra-right-context-final 0 \
          --frames-per-chunk 140 \
          --nj $nspk --cmd "$decode_cmd"  --num-threads 4 \
          --online-ivector-dir exp/nnet3${nnet3_affix}/ivectors_$data \
          $tree_dir/graph_tgsmall data/${data} ${dir}/decode_${data} || exit 1
          
          ./utils/int2sym.pl -f 2- $tree_dir/graph_tgsmall/words.txt ${dir}/decode_${data}/scoring/10.1.0.tra | sort -u > kaldi_blind_subtask1.txt

    ) || touch $dir/.error &
  done
  wait

fi


