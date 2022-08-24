#!/usr/bin/env python3
# -*- coding:utf-8 -*-


import io
import re
import os
import bs4
import sys
import time
import json
import tarfile
import rarfile
import inspect
import platform
import datetime
import sshtunnel
import sqlalchemy
import collections
import numpy as np
import pandas as pd
from sqlalchemy import exc
import matplotlib.pyplot as plt

if sys.version_info >= (3, 6):
    import zipfile
else:
    import zipfile36 as zipfile


# current call stack
def current_filename():
    s = inspect.stack()
    return s[1][1]

def current_lineno():
    s = inspect.stack()
    return s[1][2]

def current_func():
    s = inspect.stack()
    return s[1][3]

# dataframe operations
def df_select(df, col_list):
    df_ret = df[col_list]
    return df_ret.infer_objects()

def df_set_cols(df, new_cols):
    old_cols = df.columns.values.tolist()
    df.rename(columns=dict(zip(old_cols, new_cols)), inplace=True)
    return df

def df_add_col(df, new_col, default_value=None):
    df[new_col] = default_value
    return df

def df_add_col_mapped(df, new_col, map_func):
    df = df.assign(new_col = map_func)
    return df

def df_isna(df, x, y):
    return pd.isna(df.at[x, y])

def df_map(df, map_func):
    return df.applymap(map_func)

def df_col_map(df, col, map_func):
    df[col] = df.apply(map_func, axis=1)
    return df

def df_col_parse(df, col, parse_func):
    result = []
    for i in range(len(df)):
        result.append(parse_func(df.at[i, col]))
    return result

def df_from_matrix(list_of_list, cols):
    df = pd.DataFrame(list_of_list, columns=cols)
    return df

def df_clean(df):
    df_ret = df.dropna(axis=0, how='all')
    df_ret = df_ret.dropna(axis=1, how='all')
    df_ret.drop_duplicates(inplace=True)
    return df_ret.reset_index(drop=True)

def df_range(df, by, low=None, high=None):
    if low and high:
        return df[(df[by] >= low) & (df[by] <= high)]
    elif low:
        return df[df[by] >= low]
    elif high:
        return df[df[by] <= high]
    else:
        return df

def df_filter(df, col, val_list, filter_out=False):
    if val_list:
        df_ret = df.loc[~df[col].isin(val_list)] if filter_out else df.loc[df[col].isin(val_list)]
    else:
        df_ret = df.loc[df[col].isnull()] if filter_out else df.loc[df[col].notnull()]
    return df_ret.reset_index(drop=True)

def df_merge(df1, df2, on=None, left_on=None, right_on=None, how='inner', sort='False',
             copy=False, suffixes=('_x', '_y')):
    return pd.merge(df1, df2, on=on, left_on=left_on, right_on=right_on, how=how,
                    sort=sort, copy=copy, suffixes=suffixes).reset_index(drop=True)

def df_concat(*args):
    df_list = list(args)
    return pd.concat(df_list, axis=0, sort=False, copy=False, ignore_index=True)

def df_col_concat(*args):
    df_list = list(args)
    return pd.concat(df_list, axis=1, sort=False, copy=False, ignore_index=False)

def df_sort(df, by, ascending=True, inplace=False):
    return df.sort_values(by=by, ascending=ascending, inplace=inplace).reset_index(drop=True)

def df_replace(to_replace=None, value=None, inplace=False, regex=False):
    return pd.DataFrame.replace(to_replace=to_replace, value=value, inplace=inplace, regex=regex)

def df_type_convert(df, target_cols, target_type='str'):
    if target_type == 'datetime':
        df[target_cols] = df[target_cols].apply(pd.to_datetime, errors='coerce')
    elif target_type == 'number':
        df[target_cols] = df[target_cols].apply(pd.to_numeric, errors='coerce')
    else:
        for col in target_cols:
            df[col] = df[col].astype(dtype=target_type, errors='ignore')
    return df

def df_to_set(df, col):
    return set(df[col])

def df_to_dict(df, col, orient='index'):
    return df.set_index(col).to_dict(orient=orient)

def df_from_dict(dict_of_dict, orient='index'):
    return pd.DataFrame.from_dict(dict_of_dict, orient=orient).reset_index(drop=False)

# other useful operations
# dataframe.groupby('COL1')['COL2'].transform('max|min|sum|mean|median|std|var|count')


# plot bar chart
"""
df = {'time': ['2000-01-01 00:00:00', '2000-01-02 00:00:00', '2000-01-03 00:00:00', '2000-01-04 00:00:00', '2000-01-05 00:00:00'],
      'price': [100, 110, 120, 130, 140, 125]}
plt.bar(df['time'], df[r'price'])
plt.title('Price Histogram')
plt.xlabel('Time')
plt.ylabel('Price')
plt.legend(('Price',), loc='upper right', frameon=True)
plt.show()
"""

# plot line chart
"""
df = {'time': ['2000-01-01 00:00:00', '2000-01-02 00:00:00', '2000-01-03 00:00:00', '2000-01-04 00:00:00', '2000-01-05 00:00:00'],
      'price': [100, 110, 120, 130, 140, 125],
      'cost': [50, 55, 60, 65, 70, 60],
      'profit': [50, 55, 60, 60, 80, 65]}
plt.figure(dpi=120, figsize=(16, 8))
plt.plot(df['time'], df['price'])
plt.plot(df['time'], df['cost'])
plt.plot(df['time'], df[r'profit'])
plt.title('Historic relation of cost and profit')
plt.xlabel('Time')
plt.ylabel('value')
plt.grid()
plt.legend(('Price','Cost', 'Profit'), loc='upper right', frameon=True)
plt.show()
"""
