#!/usr/bin/python3

import sys
import codecs,string
import numpy as np

langs = ["odia", "gujarati", "tamil", "telugu", "hi_ma"]

lang_dict = {
	
	"OR" : "odia",
	"GU": "gujarati",
	"TA" : "tamil",
	"TE" : "telugu",
	"HI" : "hi_ma",
	"MR" : "hi_ma"
}

def detect_language(character):
	maxchar = max(character)
	if u'\u0b01' <= maxchar <= u'\u0b4d':
		return 'odia'
	elif u'\u0a81' <= maxchar <= u'\u0ad0':
		return 'gujarati'
	elif u'\u0b02' <= maxchar <= u'\u0bcd':
		return 'tamil'
	elif u'\u0c01' <= maxchar <= u'\u0c4d':
		return 'telugu'
	elif u'\u0900' <= maxchar <= u'\u0954':
		return 'hi_ma'

def detect_language_word(word):
	od_char = 0
	gu_char = 0
	ta_char = 0
	te_char = 0
	hi_ma_char = 0
	for i in word:
		# total+=1
		lang = detect_language(i)
		if lang == "odia":
			od_char += 1
		elif lang == "tamil":
			ta_char += 1
		elif lang == "telugu":
			te_char += 1
		elif lang == "gujarati":
			gu_char += 1
		elif lang == "hi_ma":
			hi_ma_char += 1
	return [od_char, gu_char, ta_char, te_char, hi_ma_char]

def detect_language_sentence(words):
	langs = ["odia", "gujarati", "tamil", "telugu", "hi_ma"]

	od_word = 0
	gu_word = 0
	ta_word = 0
	te_word = 0
	hi_ma_word = 0
	word_langs = []
	for word in words:
		curr_wlang = detect_language_word(word)
		word_lang = langs[np.argmax(curr_wlang)]
		word_langs.append(word_lang)

	for wlang in word_langs:
		if wlang == "odia":
			od_word += 1
		elif wlang == 'gujarati':
			gu_word += 1
		elif wlang == 'tamil':
			ta_word += 1
		elif wlang == 'telugu':
			te_word += 1
		elif wlang == 'hi_ma':
			hi_ma_word += 1

	B = [od_word, gu_word, ta_word, te_word, hi_ma_word]
	# if uid == "blindtest_650845":
	# 	print(B)
	winner = np.argwhere(B == np.amax(B))
	winner = winner.flatten().tolist()
	if len(winner) == 1:
		sent_lang = langs[winner[0]]
	else:
		sent_lang = langs[winner[1]]

	return sent_lang





def read_submission_file_assign_language(filename):
	sub_dict = {}
	with open(filename) as file:
		for line in file:
			line_cont = line.strip().split()
			uid = line_cont[0]
			text = line_cont[1:]

			sent_lang = detect_language_sentence(text)

			sub_dict[uid] = {
					'text' : " ".join(text),
					'lang' : sent_lang	
			}
		return sub_dict

sub_dict_E2E = read_submission_file_assign_language(sys.argv[1])
sub_dict_kaldi = read_submission_file_assign_language(sys.argv[2])


total_sent = 0
disagree_sent = 0
hi_ma_disagree = 0
with open('kaldi/lang_disagree_E2E_kaldi.txt', 'w') as disagree_file:
	for key in sub_dict_E2E:
		total_sent += 1
		if sub_dict_E2E[key]['lang'] != sub_dict_kaldi[key]['lang']:
			disagree_sent += 1
			if sub_dict_kaldi[key]['lang'] == 'hi_ma':
				hi_ma_disagree += 1

			print(key, sub_dict_E2E[key]['text'], '|' ,sub_dict_kaldi[key]['text'],  '|' ,sub_dict_kaldi[key]['lang'], file=disagree_file)


print(disagree_sent, hi_ma_disagree, total_sent)