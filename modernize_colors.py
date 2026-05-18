import os
import re

def modernize_colors(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".dart"):
                filepath = os.path.join(root, file)
                with open(filepath, "r") as f:
                    content = f.read()

                # Replace .withOpacity(...) with .withValues(alpha: ...)
                new_content = re.sub(r'\.withOpacity\((.*?)\)', r'.withValues(alpha: \1)', content)

                if new_content != content:
                    with open(filepath, "w") as f:
                        f.write(new_content)
                    print(f"Updated {filepath}")

if __name__ == "__main__":
    modernize_colors("notehub/lib")
