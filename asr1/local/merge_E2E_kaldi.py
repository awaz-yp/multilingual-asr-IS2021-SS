#!/usr/bin/python3

import sys

def read_submission_file(filename):
	sub_dict = {}
	with open(filename) as file:
		for line in file:
			line_cont = line.strip().split()
			uid = line_cont[0]
			text = line_cont[1:]

			sub_dict[uid] = {
					'text' : " ".join(text),
			}
		return sub_dict
		
E2E_file = read_submission_file(sys.argv[1])
kaldi_file = read_submission_file(sys.argv[2])
hi_ma_file = read_submission_file(sys.argv[3])

with open('results/E2E_kaldi_merged_marathi.txt', 'w') as out_file:
	for key in E2E_file:
		if key not in hi_ma_file:
			print(key, E2E_file[key]['text'], file=out_file)
		else:
			print(key, kaldi_file[key]['text'], file=out_file)
			
