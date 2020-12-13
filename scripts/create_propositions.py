import pandas as pd

df = pd.read_excel('posts_for_pretest_new.xlsx')

def convert(row):
    print('%Proposition{')
    print('\tid: {},'.format(int(row['post_id'])))
    print('\ttitle: \"{}\",'.format(row['title'].replace('"', '\\"').strip()))
    print('\ttrue: \"{}\",'.format(row['true'].replace('"', '\\"').strip()))
    print('\tfalse: \"{}\",'.format(row['false'].replace('"', '\\"').strip()))
    boolean = 'true' if row['post_is_false'] == 1 else 'false'
    print('\tpost_is_false: {},'.format(boolean))
    boolean = 'true' if row['post_intended_as_liberal'] == 1 else 'false'
    print('\tpost_intended_as_liberal: {},'.format(boolean))
    print('},')

df.iloc[0:72, :].apply(convert, axis='columns')

# PIPE OUTPUT TO file propos.ex (within this folder), and ADD TO NetworklLib/propositions.ex

