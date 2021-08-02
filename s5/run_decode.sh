#!/bin/bash#!/bin/bash#!/bin/bash

. ./cmd.sh
. ./path.sh

#nnet3-latgen-faster-parallel --num-threads=4 --online-ivectors=scp:exp/nnet3/ivectors_test_hires/ivector_online.scp --online-ivector-period=10 --frame-subsampling-factor=3 --frames-per-chunk=140 --extra-left-context=22 --extra-right-context=16 --extra-left-context-initial=0 --extra-right-context-final=0 --minimize=false --max-active=7000 --min-active=200 --beam=15.0 --lattice-beam=8.0 --acoustic-scale=1.0 --allow-partial=true --word-symbol-table=exp/chain2/tree_sp/graph_tgsmall/words.txt exp/chain2/tdnn1a_sp/final.mdl exp/chain2/tree_sp/graph_tgsmall/HCLG.fst 'ark,s,cs:apply-cmvn --norm-means=false --norm-vars=false --utt2spk=ark:data/test_hires/split21185/1/utt2spk scp:data/test_hires/split21185/1/cmvn.scp scp:data/test_hires/split21185/1/feats.scp ark:- |' 'ark:|lattice-scale --acoustic-scale=10.0 ark:- ark:- | gzip -c >exp/chain2/tdnn1a_sp/decode_test/lat.1.gz
stage=1
curr_lang=gujarati
tree_dir=exp/chain2_hi_ma/tree_sp
dir=exp/chain2_hi_ma/tdnn1a_sp


#for curr_lang in gujarati tamil telugu odia hi_ma; do
for curr_lang in hi_ma; do


if [ $stage -le 1 ]; then
  # Note: it's not important to give mkgraph.sh the lang directory with the
  # matched topology (since it gets the topology file from the model).
  utils/mkgraph.sh \
    --self-loop-scale 1.0 data/lang_$curr_lang \
    $tree_dir $tree_dir/graph_tgsmall_${curr_lang} || exit 1;
fi



if [ $stage -le 2 ]; then

frames_per_chunk=$(echo $chunk_width | cut -d, -f1)
  # Do the speaker-dependent decoding pass
  test_sets=test_$curr_lang

  for data in $test_sets; do
    (
      nspk=$(wc -l <data/${data}_hires/spk2utt)
      steps/nnet3/decode.sh \
          --acwt 1.0 --post-decode-acwt 10.0 \
          --extra-left-context 22 \
          --extra-right-context 16 \
          --extra-left-context-initial 0 \
          --extra-right-context-final 0 \
          --frames-per-chunk 140 \
          --nj $nspk --cmd "$decode_cmd"  --num-threads 4 \
          --online-ivector-dir exp/nnet3${nnet3_affix}/ivectors_test_hires \
          $tree_dir/graph_tgsmall_$curr_lang data/${data}_hires ${dir}/decode_${data} || exit 1

    ) || touch $dir/.error &
  done
  wait

fi

done
