import os
import re

def modernize_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Replace .withOpacity(x) with .withValues(alpha: x)
    new_content = re.sub(r'\.withOpacity\((.*?)\)', r'.withValues(alpha: \1)', content)

    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        return True
    return False

def main():
    lib_dir = 'notehub/lib'
    modified_count = 0
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                if modernize_file(os.path.join(root, file)):
                    modified_count += 1
    print(f'Modified {modified_count} files.')

if __name__ == '__main__':
    main()
