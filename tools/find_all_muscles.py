"""List ALL meshes in Muscular system collections (main + bonus)."""
import json

with open('tools/blender_scan.json', encoding='utf-8') as f:
    data = json.load(f)

# Recursively collect all mesh names from a collection node
def collect_meshes(node):
    result = list(node.get('meshes', []))
    for child in node.get('children', []):
        result.extend(collect_meshes(child))
    return result

main_muscles = []
bonus_muscles = []

for c in data['collections']:
    name = c.get('name', '')
    if name == '3:Muscular system':
        main_muscles = collect_meshes(c)
    elif name == 'Bonus collection':
        for child in c.get('children', []):
            if child.get('name', '') == "Muscular system'":
                bonus_muscles = collect_meshes(child)

# Combine, deduplicate
all_muscle_names = list(dict.fromkeys(main_muscles + bonus_muscles))

print(f'Main muscular system: {len(main_muscles)}')
print(f'Bonus muscular system: {len(bonus_muscles)}')
print(f'Combined unique: {len(all_muscle_names)}')

# Save to file for use in Blender script
with open('tools/all_muscle_names.json', 'w', encoding='utf-8') as f:
    json.dump(all_muscle_names, f, indent=2, ensure_ascii=False)

print('Saved to tools/all_muscle_names.json')
print()
print('Sample (first 30):')
for n in all_muscle_names[:30]:
    print(' ', n)
