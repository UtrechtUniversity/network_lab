import pandas as pd 

df = pd.read_csv('/Users/casper/Desktop/session_1/users.csv', encoding='utf-16', sep='\t')
df = df[['access_token', 'exit_token']]
df.to_csv('../priv/repo/session_1.csv', index=False)