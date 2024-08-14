import re
import glob
import os

def find_and_extract_pattern(file_path, pattern):
    # Read the content of the file
    with open(file_path, 'r') as file:
        content = file.read()

    # Find all matches of the pattern in the content
    matches = pattern.findall(content)

    # Write the matches to a temporary text file
    with open('/tmp/master-tpl-versions.txt', 'a') as temp_file:
        for match in matches:
            temp_file.write(match + '\n')
    
    # Read the content of the temporary text file
    with open('/tmp/master-tpl-versions.txt', 'r') as temp_file:
        content = temp_file.readlines()

    # Remove the .tpl suffix and duplicates from the content
    cleaned_content = list(set([line.strip().replace('.tpl', '') for line in content]))

    # Write the cleaned content back to the temporary text file
    with open('/tmp/master-tpl-versions.txt', 'w') as temp_file:
        for line in cleaned_content:
            temp_file.write(line + '\n')

# Define the regex pattern to find the template
pattern = re.compile(r'define\s+"([^"]+)"')

# Get a list of all files in the repository
all_files = [os.path.join(dp, f) for dp, dn, filenames in os.walk('./library/templates') for f in filenames]

# Iterate through each file and find and extract the pattern
for file_path in all_files:
<<<<<<< HEAD
    find_and_extract_pattern(file_path, pattern)
=======
    find_and_extract_pattern(file_path, pattern)
>>>>>>> master
