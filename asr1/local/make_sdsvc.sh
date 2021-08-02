#!/bin/bash
# Copyright   2020   Tata Consulstancy Services (Author: Meet Soni)


. ./cmd.sh
. ./path.sh
set -e


input_dir=/home/meet/Databases/SDSVC/task2
out_dir=data/sdsvc_train
wav_scp=$out_dir/wav.scp



mkdir -p $out_dir
rm -rf $wav_scp


find -L $input_dir/wav/train -iname "*.wav" | sort | xargs -I% basename % .wav | \
awk -v "dir=$input_dir/wav/train" '{printf "%s sox  %s/%s.wav -b 16 -r 16000 -t wav - | \n", $0, dir, $0}' >>$wav_scp|| exit 1

#tail -n +2 $input_dir/docs/train_labels.txt > $out_dir/utt2spk
#./utils/utt2spk_to_spk2utt.pl $out_dir/utt2spk > $out_dir/spk2utt


