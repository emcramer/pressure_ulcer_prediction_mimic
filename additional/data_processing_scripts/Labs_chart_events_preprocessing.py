
import sys
import os
import gzip
import numpy as np

from datetime import datetime

REQUIRED_DATA = {'hadm_id', 'subject_id', 'intime', 'charteventsvalue', 'icd9_code', 'labeventsitemid', 'labeventsvalue'}
SECONDS_IN_DAY = 24 * 60 * 60

LAB_MAP = {	'50883': 'direct_bilirubin',
			'50884': 'indirect_bilirubin',
			'50885': 'total_bilirubin',
			'50912': 'creatinine',
			'50824': 'sodium',
			'50983': 'sodium',
			'50822': 'potassium',
			'50971': 'potassium',
			'50889': 'CRP',
			'51288': 'ESR',
			'51002': 'troponin',
			'51003': 'troponin',
			'50852': 'HbA1c',
			'50931': 'blood_glucose',
			'50809': 'blood_glucose',
			'51237': 'INR',
			'51006': 'BUN',
			'50963': 'BNP',
			'51301': 'WCC',
			'51265': 'platelets',
			'51256': 'neutrophils',
			'50886': 'blood_culture',
			#'50862': 'albumin',
			'51486': 'urine_leukocytes',
			'51069': 'urine_albumin',
			'51487': 'urine_nitrates',
			'51084': 'urine_glucose',
			'51478': 'urine_glucose'
		  }

BMI_MAP = {'1394': 'height-in', '226707': 'height-in', '763': 'weight-kg', '224639': 'weight-kg'}


#UBER_MATRIX_COLUMNS = ['icustay_id', 'subject_id', 'hadm_id', 'confusion', 'o2sat', 'ventilator', 'prd', 'gcs','albumin', 'blood_pressure', 'hemocrit', 'hemoglobin', 'direct_bilirubin', 'indirect_bilirubin', 'total_bilirubin', 'creatinine', 'sodium', 'potassium', 'CRP', 'ESR', 'troponin', 'HbA1c', 'blood_glucose', 'INR', 'BUN', 'BNP', 'WCC', 'platelets', 'neutrophils', 'BMI']
UBER_MATRIX_COLUMNS = ['icustay_id', 'bmi', 'weight', 'height']


OUTPUT_COLUMNS = ['age', 'gender', 'is_asian', 'is_white', 'is_black', 'is_hispanic', 'is_native_american', 'is_pacific_islander', 'is_other', 'is_multiracial', 'confusion', 'o2sat', 'ventilator', 'prd', 'spinal_cord_injury', 'peripheral_vascular_disease', 'amputation', 'diabetes', 'atherscloersis', 'leukemia', 'stroke', 'congestive_heart_failure', 'anemia', 'incontinence_urine', 'incontinence_feces', 'nueropathy', 'blood_culture', 'gcs','albumin', 'blood_pressure', 'hemocrit', 'hemoglobin', 'direct_bilirubin', 'indirect_bilirubin', 'total_bilirubin', 'creatinine', 'sodium', 'potassium', 'CRP', 'ESR', 'troponin', 'HbA1c', 'blood_glucose', 'INR', 'BUN', 'BNP', 'WCC', 'platelets', 'neutrophils', 'urine_albumin', 'urine_glucose', 'pressure_ulcers']
SIMPLE_NUMERICALS = ['gcs','albumin', 'blood_pressure', 'hemocrit', 'hemoglobin', 'direct_bilirubin', 'indirect_bilirubin', 'total_bilirubin', 'creatinine', 'sodium', 'potassium', 'CRP', 'ESR', 'troponin', 'HbA1c', 'blood_glucose', 'INR', 'BUN', 'BNP', 'WCC', 'platelets', 'neutrophils']

VENTILATOR_CATS = ['APRV', 'APRV/Biphasic+ApnVol', 'ApneaVentilation', 'AssistControl', 'CMV', 'CMV/ASSIST', 'CMV/ASSIST/AutoFlow', 'CMV/AutoFlow', 'CPAP', 'CPAP+PS', 'CPAP/PPS', 'CPAP/PSV', 'CPAP/PSV+ApnPres', 'CPAP/PSV+ApnVol', 'MMV', 'MMV/AutoFlow', 'MMV/PSV', 'MMV/PSV/AutoFlow', 'Other/Remarks', 'PCV+', 'PCV+/PSV', 'PCV+Assist', 'PRES/AC', 'PRVC/AC', 'PSV/SBT', 'PressureControl', 'PressureSupport', 'SIMV', 'SIMV+PS', 'SIMV/PRES', 'SIMV/PSV', 'SIMV/PSV/AutoFlow', 'Standby', 'TCPCV', 'VOL/AC']
PRD_CATS = ['FoamPad', 'Heel/ElbPads', 'MultipodusBoots', 'Other/Remarks', 'Sheepskin', 'Waffles']
PU_INDICATORS = {'DeepTissInjury', 'Red,Unbroken', 'ThroughDermis', 'ThroughFascia', 'ToBone'}

#OUT_FILE_NAME = 'uber_matrix.tsf'
OUT_FILE_NAME = 'bmi.tsf'
PLACEHOLDER = 'NA'
OUTPUT_DELIMITER = '\t'

OUTPUT_TRUE = 1
OUTPUT_FALSE = 0


def read_file(in_file_name, delimiter='|'):
	in_file = gzip.open(in_file_name, 'r')
	first_line = True
	columns = None
	data = list()
	for line in in_file:
		line = line.decode("utf-8").strip()
		split_line = [entry.strip() for entry in line.split(delimiter)]
		if len(split_line) >= 2:
			if first_line:
				columns = split_line
				first_line = False
			else:
				data.append(split_line)
	in_file.close()
	return columns, data

# def get_valid_subject_ids(the_input):
# 	columns, data = the_input
# 	subject_id_index = columns.index('subject_id')
# 	subject_ids = set([int(entry[subject_id_index]) for entry in data])
# 	return subject_ids

def get_valid_icustay_ids(the_input):
	columns, data = the_input
	id_index = columns.index('icustay_id')
	hadm_id_index = columns.index('hadm_id')
	ids = [(entry[id_index].strip(), entry[hadm_id_index].strip()) for entry in data if entry[id_index] and entry[hadm_id_index]]
	icustay_ids = [tup[0] for tup in ids]
	hadm_id_map = dict()
	for tup in ids:
		hadm_id_map[tup[1]] = tup[0]


	#print(sorted(list(icustay_ids)))
	return icustay_ids, hadm_id_map

def make_datetime(datetime_str):
	return datetime.strptime(datetime_str, '%Y-%m-%d %H:%M:%S')

def time_fits(datetime_event, datetime_admission, max_difference=SECONDS_IN_DAY):
	time_dif = datetime_event - datetime_admission
	return time_dif.total_seconds() <= max_difference and time_dif.total_seconds() >= 0

def add_to_map(the_map, to_add, time_map, replacements=None):
	replacements = replacements if replacements else dict()
	columns, data = to_add
	icustay_index = columns.index('icustay_id')
	timestamp_index = columns.index('charteventscharttime') if time_map else None
	relevent_columns = [index for index in range(len(columns)) if columns[index] in REQUIRED_DATA]
	for row in data:
		icustay_id = row[icustay_index]
		if icustay_id:
			for i in relevent_columns:
				if time_map is None or time_fits(make_datetime(row[timestamp_index]), time_map[icustay_id]):
					key = replacements.get(columns[i], columns[i])
					if key not in the_map[icustay_id]:
						the_map[icustay_id][key] = list()
					the_map[icustay_id][key].append(row[i])

def add_to_map_lab(the_map, to_add, time_map, hadm_id_map, replacements=None, allow_unspecified=False):
	replacements = replacements if replacements else dict()
	columns, data = to_add
	hadm_id_index = columns.index('hadm_id')
	timestamp_index = columns.index('labeventscharttime')
	key_index = columns.index('labeventsitemid')
	result_index = columns.index('labeventsvalue')
	for row in data:
		hadm_id = row[hadm_id_index]
		if hadm_id:
			if hadm_id in hadm_id_map:
				icustay_id = hadm_id_map[hadm_id]
				# print('LABLAB')
				# print(make_datetime(row[timestamp_index]))
				# print(time_map[icustay_id])


				if time_fits(make_datetime(row[timestamp_index]), time_map[icustay_id]):
					#print('valid lab')
					if allow_unspecified:
						key = replacements.get(row[key_index], row[key_index])
					else:
						key = replacements.get(row[key_index], None)
						if not key:
							continue
					if key not in the_map[icustay_id]:
						the_map[icustay_id][key] = list()
					the_map[icustay_id][key].append(row[result_index])
				else:
					pass
					#print('invalid lab')
			else:
				print('Warning:', hadm_id, 'not in hadm_id_map')

def add_to_map_combo(the_map, to_add, time_map, replacements=None):
	replacements = replacements if replacements else dict()
	columns, data = to_add
	icustay_index = columns.index('icustay_id')
	timestamp_index = columns.index('charteventscharttime')
	key_index = columns.index('charteventsitemid')
	result_index = columns.index('charteventsvalue')
	for row in data:
		icustay_id = row[icustay_index]
		if not icustay_id:
			continue
		if time_fits(make_datetime(row[timestamp_index]), time_map[icustay_id]) or True:
			key = replacements.get(row[key_index], None)
			if not key:
				continue
			if key not in the_map[icustay_id]:
				the_map[icustay_id][key] = list()
				the_map[icustay_id][key].append(row[result_index])

#3545
#7353

def read_raw_data():
	grand_map = dict()
	time_map = dict()

	print('Reading transfers table...')
	transfer_data = read_file('transfers.gz')
	icustay_ids, hadm_id_map = get_valid_icustay_ids(transfer_data)
	for icustay_id in icustay_ids:
		grand_map[icustay_id] = dict()

	#print(hadm_id_map)

	add_to_map(grand_map, transfer_data, None)

	for icustay_id in icustay_ids:
		time_map[icustay_id] = make_datetime(grand_map[icustay_id]['intime'][0])
		

	# print('Reading admissions table...')
	# admin_data = read_file('admissions.gz')
	# subject_ids = get_valid_subject_ids(admin_data)
	# for subject_id in subject_ids:
	# 	grand_map[subject_id] = dict()
	# add_to_map(grand_map, admin_data)

	# gender_data = read_file('patientgenders.gz')
	# add_to_map(grand_map, gender_data)

	# print('Reading albumin table...')
	# albumin_data = read_file('albuminchartevents.gz')
	# add_to_map(grand_map, albumin_data, time_map, replacements={'charteventsvalue': 'albumin'})

	# print('Reading blood pressure table...')
	# bp_data = read_file('bpchartevents.gz')
	# add_to_map(grand_map, bp_data, time_map, replacements={'charteventsvalue': 'blood_pressure'})

	# print('Reading confusion score table...')
	# confusion_data = read_file('camchartevents.gz')
	# add_to_map(grand_map, confusion_data, time_map, replacements={'charteventsvalue': 'confusion'})

	# print('Reading GCS table...')
	# gcs_data = read_file('gcschartevents.gz')
	# add_to_map(grand_map, gcs_data, time_map, replacements={'charteventsvalue': 'gcs'})

	# print('Reading hemocrit table...')
	# hemocrit_data = read_file('hematocritchartevents.gz')
	# add_to_map(grand_map, hemocrit_data, time_map, replacements={'charteventsvalue': 'hemocrit'})

	# print('Reading hemoglobin data...')
	# hemoglobin_data = read_file('hemoglobinchartevents.gz')
	# add_to_map(grand_map, hemoglobin_data, time_map, replacements={'charteventsvalue': 'hemoglobin'})

	# print('Reading oxygen saturation data...')
	# oxy_data = read_file('o2satchartevents.gz')
	# add_to_map(grand_map, oxy_data, time_map, replacements={'charteventsvalue': 'o2sat'})

	# print('Reading ventilator data...')
	# vent_data = read_file('ventilatorchartevents.gz')
	# add_to_map(grand_map, vent_data, time_map, replacements={'charteventsvalue': 'ventilator'})

	# print('Reading PRD data...')
	# prd_data = read_file('prdchartevents.gz')
	# add_to_map(grand_map, prd_data, time_map, replacements={'charteventsvalue': 'prd'})

	# print('Reading ICD data...')
	# icd_data = read_file('icd9-features.gz')
	# add_to_map(grand_map, icd_data)

	print('Reading height/weight data...')
	hw_data = read_file('hwchartevents.gz')

	add_to_map_combo(grand_map, hw_data, time_map, replacements=BMI_MAP)

	# print('Reading lab data...')
	# lab_data = read_file('labevents.gz')
	# add_to_map_lab(grand_map, lab_data, time_map, hadm_id_map, replacements=LAB_MAP)

	# print('Reading PU data...')
	# pu_data = read_file('puchartevents.gz')
	# add_to_map(grand_map, pu_data, time_map, replacements={'charteventsvalue': 'pressure_ulcers'})

	#print(time_map)
	#print(grand_map[22])
	return grand_map

def process_generic_categorical(icustay_info, key):
	if key not in icustay_info:
		return list()
	data_list = icustay_info[key]
	return data_list

def process_generic_numerical(icustay_info, key, preprocessing=None):
	true_data = list()
	if key not in icustay_info:
		return true_data
	raw_list = icustay_info[key]
	for entry in raw_list:
		try:
			true_entry = preprocessing(entry) if preprocessing else entry
			true_entry = float(true_entry)
			true_data.append(true_entry)
		except Exception:
			print('Error: Invalid value for key ', key, ': ', entry, ' Skipping...')
	return true_data

# def process_age(age_strs):
# 	for age_str in age_strs:
# 		try:
# 			day_age = int(age_str.split('days')[0])
# 			return int(day_age / 365)
# 		except Exception:
# 			# print('Error: Invalid age string ', age_str)
# 			pass
# 	return PLACEHOLDER

# def process_gender(gender_strings):
# 	if len(gender_strings):
# 		if gender_strings[0].upper() == 'F':
# 			return 0
# 		return 1
# 	return PLACEHOLDER

# def process_ethnicity(ethnicity_strings):
# 	is_asian, is_white, is_black, is_hispanic, is_native_american, is_pacific_islander, is_other, is_multiracial = 0, 0, 0, 0, 0, 0, 0, 0
# 	for ethno_string in ethnicity_strings:
# 		ethno_string = ethno_string.upper()
# 		if ethno_string[:5] == 'ASIAN':
# 			is_asian = 1
# 		if ethno_string[:5] == 'WHITE' or ethno_string == 'MIDDLEEASTERN': #Foldling middle eastern into white per Federal government
# 			is_white = 1
# 		if ethno_string[:5] == 'BLACK':
# 			is_black = 1
# 		if 'HISPANIC' in ethno_string or 'LATINO' in ethno_string:
# 			is_hispanic = 1
# 		if ethno_string == 'AMERICANINDIAN/ALASKANATIVE':
# 			is_native_american = 1
# 		if ethno_string == 'NATIVEHAWAIIANOROTHERPACIFICISLANDER':
# 			is_pacific_islander = 1
# 		if ethno_string == 'OTHER':
# 			is_other = 1
# 		if ethno_string == 'MULTIRACEETHNICITY':
# 			is_multiracial = 1
# 	return [is_asian, is_white, is_black, is_hispanic, is_native_american, is_pacific_islander, is_other, is_multiracial]

def process_o2(o2_strings):
	to_return = 0
	for o2_string in o2_strings:
		if 'O2sat<90' in o2_string: #<90 O2 sat even with suplemental
			return 2
		if 'NeedsO2inhalation' in o2_string:
			to_return = 1

	return to_return

def process_icd(icd_strings):
	icd_data = list()
	# Spinal Cord Injury
	icd_data.append(single_determinant_bool(icd_strings, lambda x: x in {'95200', '95205', '95210', '95215', '9522', '9528', '9539', '9523'}))
	# Peripheral vascular disease
	icd_data.append(single_determinant_bool(icd_strings, lambda x: x[:3] == '443'))
	# Amputation
	icd_data.append(single_determinant_bool(icd_strings, lambda x: x[:2] == '88'))
	# Diabetes
	icd_data.append(single_determinant_bool(icd_strings, lambda x: x[:3] == '250'))	
	# Atherscloersis
	icd_data.append(single_determinant_bool(icd_strings, lambda x: x[:3] == '440'))
	# Leukemia
	icd_data.append(single_determinant_bool(icd_strings, lambda x: x[:3] in {'204', '205', '206', '207', '208'}))
	# Stroke
	icd_data.append(single_determinant_bool(icd_strings, lambda x: x == '43491'))
	# Congestive heart failure
	icd_data.append(single_determinant_bool(icd_strings, lambda x: x[:3] == '428'))
	# Anemia
	icd_data.append(single_determinant_bool(icd_strings, lambda x: x[:3] == '281' or x == '2800' or x == '2859'))
	# Urinary incontinence
	icd_data.append(single_determinant_bool(icd_strings, lambda x: x == '7883'))
	# Incontinence of feces
	icd_data.append(single_determinant_bool(icd_strings, lambda x: x == '7876'))
	# Nueropathy
	icd_data.append(single_determinant_bool(icd_strings, lambda x: x[:3] == '356' or x[:3] == '357'))
	return icd_data

def process_ventilator(ventilator_strings):
	ventilator_value = 0
	for value in ventilator_strings:
		if 'CPAP' in value:
			ventilator_value = 1
		elif value:
			ventilator_value = 2
			break
	return ventilator_value

def convert_to_bool_flags(entries, categories):
	num_categories = len(categories)
	result_vector = [0 for i in range(num_categories)]
	for i in range(num_categories):
		if categories[i] in entries:
			result_vector[i] = 1
	return result_vector

def single_determinant_bool(entries, determinant, null_value=OUTPUT_FALSE):
	if entries == PLACEHOLDER:
		return null_value
	for entry in entries:
		try:
			if determinant(entry):
				return OUTPUT_TRUE
		except Exception:
			print('Error: Determinant failure for key: ', key, ' value: ', entry, ' Skipping...')
	return OUTPUT_FALSE

def is_yes(entry):
	return entry[:3].upper() == 'YES'

def get_mean(values, remove_negative_values=True, remove_zero=False):
	if remove_negative_values:
		values = [value for value in values if value >= 0]
	if remove_zero:
		values = [value for value in values if value != 0]
	if len(values):
		return np.mean(values)
	return PLACEHOLDER

def find_bmi(weight_values, height_values):
	weight_avg_kg = get_mean(weight_values, remove_zero=True)
	height_avg_m = get_mean(height_values, remove_zero=True) 
	if weight_avg_kg == PLACEHOLDER or height_avg_m == PLACEHOLDER:
		return PLACEHOLDER, weight_avg_kg, height_avg_m
	return weight_avg_kg / ((height_avg_m * 0.0254)** 2), weight_avg_kg, height_avg_m * 0.0254

def remove_signs(text):
	return text.replace('>', '').replace('<', '')

def handle_simple_numerical(row, icustay_info, keys):
	for key in keys:
		values = process_generic_numerical(icustay_info, key, preprocessing=remove_signs)
		row.append(get_mean(values))

def process_data(grand_map):
	uber_matrix = list()
	#uber_matrix.append(OUTPUT_COLUMNS)

	uber_matrix_keys = set()
	ethnicity_cats = set()
	o2_cats = set()
	ventilator_cats = set()
	prd_cats = set()
	icd_cats = set()
	culture_cats = set()
	urine_leukocytes_cats = set()
	urine_nitrates_cats = set()
	pu_cats = set()
	#temp_cats = set()

	num_bmis = 0
	num_weights = 0
	num_heights = 0

	for icustay_id in grand_map:

		icustay_info = grand_map[icustay_id]
		key_values = grand_map[icustay_id].keys()
		row = list()

		row.append(icustay_id)
		# row.append(process_generic_categorical(icustay_info, 'subject_id')[0])
		# row.append(process_generic_categorical(icustay_info, 'hadm_id')[0])
		# # age_values = process_generic_categorical(icustay_info, 'age')
		# # row.append(process_age(age_values))

		# # gender_values = process_generic_categorical(icustay_info, 'gender')
		# # row.append(process_gender(gender_values))

		# # ethnicity_values = process_generic_categorical(icustay_info, 'ethnicity')
		# # row.extend(process_ethnicity(ethnicity_values))

		# confusion_values = process_generic_categorical(icustay_info, 'confusion')
		# row.append(single_determinant_bool(confusion_values, is_yes))

		# # Note: Overlap with ventilator?
		# # gcs_values = process_generic_categorical(icustay_info, 'gcs')

		# o2_sat_values = process_generic_categorical(icustay_info, 'o2sat')
		# row.append(process_o2(o2_sat_values))

		# ventilator_values = process_generic_categorical(icustay_info, 'ventilator')
		# row.append(process_ventilator(ventilator_values))

		# prd_values = process_generic_categorical(icustay_info, 'prd')
		# row.append(single_determinant_bool(prd_values, lambda x: x in {'Foam Pad', 'Heel/Elb Pads', 'Multipodus Boots', 'Other/Remarks', 'Sheepskin', 'Waffles'}))

		# # icd_values = process_generic_categorical(icustay_info, 'icd9_code')
		# # row.extend(process_icd(icd_values))

		# handle_simple_numerical(row, icustay_info, SIMPLE_NUMERICALS)

		height_values = process_generic_numerical(icustay_info, 'height-in')
		weight_values = process_generic_numerical(icustay_info, 'weight-kg')

		to_add = find_bmi(weight_values, height_values)
		if to_add[0] != PLACEHOLDER:
			num_bmis += 1
		if to_add[1] != PLACEHOLDER:
			num_weights += 1
		if to_add[2] != PLACEHOLDER:
			num_heights += 1
		row.extend(to_add)

		# 'platelets', 'neutrophils', 'urine_albumin', 'urine glucose'

		# pu_values = process_generic_categorical(icustay_info, 'pressure_ulcers')
		# row.append(single_determinant_bool(pu_values, lambda x: x in PU_INDICATORS))

		#assert len(OUTPUT_COLUMNS) == len(row)

		uber_matrix.append(row)

		# for val in key_values:
		# 	uber_matrix_keys.add(val)

		# for val in o2_sat_values:
		# 	o2_cats.add(val)

		# for val in ventilator_values:
		# 	ventilator_cats.add(val)

		# for val in prd_values:
		# 	prd_cats.add(val)

		# for val in icd_values:
		# 	icd_cats.add(val)

		# for val in pu_values:
		# 	pu_cats.add(val)
		#for val in temp_values:
			#temp_cats.add(val)

	print(len(OUTPUT_COLUMNS), len(row), ' columns')
	print('BMIs: ', num_bmis, 'Weights', num_weights, 'Heights', num_heights)
	# print('Values extracted ', sorted(list(uber_matrix_keys)))
	# print('Recorded O2 sats', o2_cats)
	# print('Recorded Ventilator cats', sorted(list(ventilator_cats)))
	# print('Recorded PRD cats', sorted(list(prd_cats)))
	#print('Recorded ICD codes', sorted(list(icd_cats)))
	# print('Recorded PU values', sorted(list(pu_cats)))
	#print('Recorded temp values', sorted(list(temp_cats)))
	return uber_matrix

def print_results(uber_matrix):
	outfile = open(OUT_FILE_NAME, 'w')
	outfile.write(OUTPUT_DELIMITER.join(UBER_MATRIX_COLUMNS))
	outfile.write('\n')
	for row in uber_matrix:
		to_print = [str(entry) for entry in row]
		outfile.write(OUTPUT_DELIMITER.join(to_print))
		outfile.write('\n')
	outfile.close()

if __name__ == "__main__":
	grand_map = read_raw_data()
	uber_matrix = process_data(grand_map)
	print_results(uber_matrix)

