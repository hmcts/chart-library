import re
import glob
import os
import subprocess

changed_files = os.environ.get('CHANGED_FILES')
changed_files_list = changed_files.split()

# Wipe the output file clean at the start
with open('/tmp/bumped-tpl-versions.txt', 'w') as output_file:
    output_file.write('')

# Search for all the define statements in the changed files
for changed_file in changed_files_list:
    with open(changed_file, 'r') as file:
        content = file.read()
        pattern = re.compile(r'define\s+"([^"]+)"')
        matches = re.findall(pattern, content)
        for match in matches:
            
            # Remove the .tpl suffix if present
            match = re.sub(r'\.tpl$', '', match)

            # Write an updated version of the templates to a new file
            with open('/tmp/master-tpl-versions.txt', 'r') as master_file:
                for line in master_file:
                    line = line.strip()
                    if line == match:
                        new_version = match
                        with open('/tmp/bumped-tpl-versions.txt', 'a') as file:
                            file.write(new_version + '\n')

# Search for each line in /tmp/bumped-tpl-versions.txt in the library/templates/v2 directory
with open('/tmp/bumped-tpl-versions.txt', 'r') as bumped_file:
    for line in bumped_file:
        line = line.strip()
        if line:
            # Use grep to search for the line in the directory
            result = subprocess.run(['grep', '-rl', line, './library/templates/v2'], capture_output=True, text=True)
            if result.stdout:
                for file_path in result.stdout.splitlines():
                    # Increment the version number
                    new_version = re.sub(r'v(\d+)', lambda m: f"v{int(m.group(1)) + 1}", line)
                    with open(file_path, 'r') as file:
                        content = file.read()
                        updated_content = content.replace(line, new_version)
                        # Write the updated version number to the files that contain the template
                        with open(file_path, 'w') as file:
                            file.write(updated_content)
                            os.environ["version_bumped"] = "true"

if os.environ.get("version_bumped") == "true":
    print(f"version_updated")