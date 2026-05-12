import os
import re

def modernize_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Replace .withOpacity(x) with .withValues(alpha: x)
    content = re.sub(r'\.withOpacity\((.*?)\)', r'.withValues(alpha: \1)', content)

    # Replace activeColor: with activeThumbColor: for Switch (simplified check)
    if 'Switch' in content or 'Switch.adaptive' in content:
        content = content.replace('activeColor:', 'activeThumbColor:')

    with open(filepath, 'w') as f:
        f.write(content)

def main():
    lib_path = 'notehub/lib'
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                modernize_file(os.path.join(root, file))

if __name__ == "__main__":
    main()
