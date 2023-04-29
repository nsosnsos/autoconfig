#!/usr/bin/env python3
# -*- coding:utf-8 -*-


import openai

openai.api_key='OPENAI_API_KEY'


def chat_gpt(text):
    completion = openai.ChatCompletion.create(
        model = 'gpt-3.5-turbo',
        messages = [
            {
                'role': 'user',
                'content': text,
            }
        ],
        temperature = 0,
    )
    print('>>> ' + completion['choices'][0]['message']['content'])


if __name__ == '__main__':
    while True:
        text = input('\n<<< ')
        if text == 'exit':
            break
        chat_gpt(text)

