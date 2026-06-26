import json

with open('assets/data/free_exercises.json', encoding='utf-8') as f:
    lst = json.load(f)

print(f'Total: {len(lst)}')
for e in lst[:3]:
    eid = e.get('id', '')
    name = e.get('name', '')
    print(f'  id={eid}  name={name}')
