import re, json

text = 'data: {"token": "Donald "}\ndata: {"token": "John "}data: {"token": "Trump "}'
matches = re.findall(r'\{[^{}]*\}', text)
tokens = [json.loads(m)['token'] for m in matches]
print("Parsed tokens successfully:", "".join(tokens))
