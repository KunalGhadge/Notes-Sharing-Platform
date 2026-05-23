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
        print(f"Modernized {filepath}")

def main():
    lib_dir = "notehub/lib"
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith(".dart"):
                modernize_file(os.path.join(root, file))

if __name__ == "__main__":
    main()
