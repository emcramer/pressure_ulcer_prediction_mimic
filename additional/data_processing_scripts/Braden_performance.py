
MASTER_FILE = 'masterfile_ml.csv'
DELIMITER = ','
OUTCOME_INDEX = 3
BRADEN_INDEX = 9
THRESHOLD_RANGE = range(6, 23)

import matplotlib.pyplot as plt
from numpy import mean, std

def read_file():
	first_line = True
	data = list()
	with open(MASTER_FILE, 'r') as in_file:
		for line in in_file:
			line = line.strip().replace('\"', '')
			if first_line:
				first_line = False
			else:
				split_line = line.split(DELIMITER)
				braden = split_line[BRADEN_INDEX]
				if braden != 'NA':
					data.append((int(braden), split_line[OUTCOME_INDEX] == 'ulcer'))
	return data

def process_data(data):
	precisions = list()
	recalls = list()
	braden_ulcer = list()
	braden_no_ulcer = list()

	for threshold in THRESHOLD_RANGE:
		tp, fp, tn, fn = 0, 0, 0, 0
		for tup in data:
			braden_score = tup[0]
			threshold_flag = braden_score <= threshold
			ulcer_flag = tup[1]
			if threshold_flag and ulcer_flag:
				tp += 1
				braden_ulcer.append(braden_score)
			elif threshold_flag:
				braden_no_ulcer.append(braden_score)
				fp += 1
			elif ulcer_flag:
				braden_ulcer.append(braden_score)
				fn += 1
			else:
				tn += 1
				braden_no_ulcer.append(braden_score)
		precisions.append(tp / float(tp + fp))
		recalls.append(tp / float(tp + fn))
	print('Ulcer ', mean(braden_ulcer), std(braden_ulcer), len(braden_ulcer))
	print('No Ulcer ', mean(braden_no_ulcer), std(braden_no_ulcer), len(braden_no_ulcer))
	return precisions, recalls

def plot_data(precisions, recalls):
	x_axis = THRESHOLD_RANGE
	plt.plot(THRESHOLD_RANGE, precisions, 'ro', label='precision')
	plt.plot(THRESHOLD_RANGE, recalls, 'bo', label='recall')
	plt.xlabel('Braden Threshold')
	plt.title('Braden Score Prediction')
	plt.legend()
	plt.show()

def process_braden():
	raw_data = read_file()
	precisions, recalls = process_data(raw_data)
	plot_data(precisions, recalls)
	print(THRESHOLD_RANGE)
	print(precisions)
	print(recalls)


process_braden()