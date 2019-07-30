
from numpy import mean, std

def get_ulcer_no_ulcer():
	first_line = True
	ulcers_icu_ids = set()
	no_ulcers_icu_ids = set()
	count_healed = 0
	with open('cases_controls_master_stage_2.csv', 'r') as master_file:
		for line in master_file:
			line = line.strip().replace('\"', '')
			split_line = line.split(',')
			if first_line:
				first_line = False
			else:
				icu_id = int(split_line[4])
				ulcer_flag = split_line[20] == "1"
				if ulcer_flag:
					ulcers_icu_ids.add(icu_id)
					if int(split_line[18]) < 0:
						count_healed += 1
				else:
					no_ulcers_icu_ids.add(icu_id)
	print('Heal ', float(count_healed) / len(ulcers_icu_ids))
	return ulcers_icu_ids, no_ulcers_icu_ids



def get_mean_weight(ulcers_icu_ids):
	weights_ulcer = []
	weights_no_ulcer = []
	first_line = True
	with open('bmi.tsf', 'r') as bmi_file:
		for line in bmi_file:
			if first_line:
				first_line = False
				continue
			split_line = line.split()
			icu_id = int(split_line[0])
			weight_str = split_line[2]
			if weight_str == 'NA':
				continue
			weight = float(weight_str)
			if icu_id in ulcers_icu_ids:
				weights_ulcer.append(weight)
			else:
				weights_no_ulcer.append(weight)
	print ('Ulcer: ', mean(weights_ulcer), std(weights_ulcer), len(weights_ulcer))
	print ('No ulcer: ', mean(weights_no_ulcer), std(weights_no_ulcer), len(weights_no_ulcer))

			

ulcers_icu_ids, no_ulcers_icu_ids = get_ulcer_no_ulcer()
get_mean_weight(ulcers_icu_ids)