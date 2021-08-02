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

total_sent = 0
incorrect_sent = 0

with codecs.open(sys.argv[1], encoding='utf-8') as f, \
	 open('results/gujarati_utterances_blind_test.txt', 'w') as gu_write, \
	 open('results/tamil_utterances_blind_test.txt', 'w') as ta_write, \
	 open('results/telugu_utterances_blind_test.txt', 'w') as te_write, \
	 open('results/odia_utterances_blind_test.txt', 'w') as od_write, \
	 open('results/hi_ma_utterances_blind_test.txt', 'w') as hi_ma_write:
	for input1 in f:
		total_sent += 1
		input2=input1.strip()

		line_cont = input2.split()
		uid = line_cont[0]
		words = line_cont[1:]
		gt_lang = uid[:2] # ground truth lang
		
		word_langs = []

		od_word = 0
		gu_word = 0
		ta_word = 0
		te_word = 0
		hi_ma_word = 0
		for word in words:
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
			

			A = np.array([od_char, gu_char, ta_char, te_char, hi_ma_char])
			word_lang = langs[np.argmax(A)]
			
			word_langs.append(word_lang)
			# if uid == "blindtest_650845":
			# 	print(word_langs)
			# print(word_langs)

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

		# if lang_dict[gt_lang] != sent_lang:
		# 	incorrect_sent += 1

		if sent_lang == 'odia':
			print(input2, file=od_write)
		elif sent_lang == 'gujarati':
			print(input2, file=gu_write)
		elif sent_lang == 'tamil':
			print(input2, file=ta_write)
		elif sent_lang == 'telugu':
			print(input2, file=te_write)
		elif sent_lang == 'hi_ma':
			print(input2, file=hi_ma_write)
		# if uid == "blindtest_586921":
		# 	print(uid,winner, B, A)

		# print(lang_dict[gt_lang], sent_lang)

print(1-(incorrect_sent / total_sent), incorrect_sent, total_sent)