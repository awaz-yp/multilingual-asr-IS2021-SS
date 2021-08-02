#!/usr/bin/python3
import sys

input_file = open(sys.argv[1])

with open('ESPNet_blind_subtask1.txt', 'w') as out_file:
	for line in input_file:
		line_cont = line.strip().split('(')
		text = line_cont[0]
		utt_id = line_cont[1].split('-')[0]
		print(utt_id,text,file=out_file)


input_file.close()
