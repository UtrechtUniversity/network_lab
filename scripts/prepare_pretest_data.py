import pandas as pd
import random
from itertools import combinations, zip_longest
from constraint import *


def grouper(iterable, n, fillvalue=None):
    "Collect data into fixed-length chunks or blocks"
    # grouper('ABCDEFG', 3, 'x') --> ABC DEF Gxx
    args = [iter(iterable)] * n
    return list(zip_longest(fillvalue=fillvalue, *args))


def is_true_lib(row):
    return ((row['post_intended_as_liberal'] == 1 and row['post_is_false'] == 0) or
        (row['post_intended_as_liberal'] == 0 and row['post_is_false'] == 1))


df = pd.read_excel('posts_for_pretest_new.xlsx')
df = df.iloc[0:72, :]
# create true_lib column
df['post_true_liberal'] = df.apply(is_true_lib, axis='columns')

df = df[['post_id', 'post_true_liberal']].iloc[0:72]

data = []
for record in df.to_records(index=False):
    if record[1] == True:
        data.append((int(record[0]), 'liberal', True))
        data.append((int(record[0]), 'conservative', False))
    else:
        data.append((int(record[0]), 'conservative', True))
        data.append((int(record[0]), 'liberal', False))



#random.shuffle(l)
subjects = {}
for key in range(1, 901):
    subjects[key] = {}
    subjects[key]['workload'] = []
    if key <= 450:
        subjects[key]['color'] = 'liberal'
    else:
        subjects[key]['color'] = 'conservative'

        
lib_true = [i for i in data if i[1]=='liberal' and i[2]==True]
lib_false = [i for i in data if i[1]=='liberal' and i[2]==False]
cons_true = [i for i in data if i[1]=='conservative' and i[2]==True]
cons_false = [i for i in data if i[1]=='conservative' and i[2]==False]


teller = 0
for color in ['liberal', 'conservative']:
    for message_ideology in ['liberal', 'conservative']:

        true_messages = [i for i in data if i[1] == message_ideology and i[2]==True]
        print(len(true_messages))
        # false_messages = [i for i in data if i[1] == message_ideology and i[2]==False]
        # print(len(false_messages))

        population = [key for key, value in subjects.items() if value['color'] == color]
        random.shuffle(population)

        groups = grouper(population, 6)

        for group in groups:
            selected_messages = random.sample([(i, m) for i, m in enumerate(true_messages)], 36)


            for i, true_message in selected_messages:
                subject_index = i % 6
                neighbour_index = (subject_index + 1) % 6

                # the true message
                subject_id = group[subject_index]
                subjects[subject_id]['workload'].append(true_message)

                # the false message
                false_message = (true_message[0], true_message[1], False)
                # check
                assert(true_message[0] == false_message[0])
                # assign false message to neighbour
                neighbour_id = group[neighbour_index]
                subjects[neighbour_id]['workload'].append(false_message)

            for subject_id in group:
                workload = list(subjects[subject_id]['workload'])
                random.shuffle(workload)
                subjects[subject_id]['workload'] = workload


# tests
# -- no duplicates 
for key in subjects.keys():
    workload = subjects[key]['workload']
    workload = [w[0] for w in workload]
    assert(len(set(workload)) == len(workload))


# -- every question 150 times
total = []
count = {}
for key in subjects.keys():
    total += subjects[key]['workload']
for w in total:
    if w not in count.keys():
        count[w] = 0
    count[w] += 1
assert(set(count.values()) == {150})



# -- every subject has 6 lib true, 6 lib false, 6 cons true and 6 cons false
count = {}
for key in subjects.keys():
    workload = subjects[key]['workload']
    lib_true = len([i for i in workload if i[1]== 'liberal' and i[2]==True]) == 6
    lib_false = len([i for i in workload if i[1]== 'liberal' and i[2]==False]) == 6
    cons_true = len([i for i in workload if i[1]== 'conservative' and i[2]==True]) == 6
    cons_false = len([i for i in workload if i[1]== 'conservative' and i[2]==False]) == 6
    count[key] = all([lib_true, lib_false, cons_true, cons_false])
assert(set(count.values()) == {True})


# elixir syntax
print('@workloads %{')
for key in list(subjects.keys()):
    string = '\t{} => [ "{}", {} ],'.format(
        key, 
        subjects[key]['color'].replace("'", "\""), 
        str(subjects[key]['workload']).replace('(', '{').replace(')', '}').replace("'",'"').replace('True', 'true').replace('False', 'false')
    )
    print(string)
print('}')



