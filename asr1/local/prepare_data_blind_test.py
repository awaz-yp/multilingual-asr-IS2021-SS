#import numpy as np
import sys
import os

root_dir = sys.argv[1]
#root_dir = '/mnt/data/Meet/Databases/multilingual_challenge/'
#language = sys.argv[1]

lang_dir = root_dir #os.path.join(root_dir, language)

#Test data prepare
subset = 'blind_testset_subtask1'
data_dir = 'data/{}'.format(subset)
try:
    os.makedirs(data_dir)
except:
    pass

with open(os.path.join(lang_dir,subset,'audio_list.txt'), encoding='utf-8') as transcript_file, \
    open(os.path.join(data_dir,'text'), 'w') as text_file, open(os.path.join(data_dir,'wav.scp'), 'w') as wav_scp, \
    open(os.path.join(data_dir,'utt2spk'), 'w') as utt2spk, open(os.path.join(data_dir,'spk2utt'), 'w') as spk2utt:
    for line in transcript_file:
        line_cont = line.strip().split()
        uid = line_cont[0]
        text = "<unk>"
        #text = ' '.join(line_cont[1:])
        wav_filename = os.path.join(lang_dir, subset, 'audio', '{}.wav'.format(uid))
        uid_print = uid
        print(uid_print, text, file=text_file)
        print(uid_print, wav_filename, file=wav_scp)
        print(uid_print, uid_print, file=utt2spk)
        print(uid_print, uid_print, file=spk2utt)


