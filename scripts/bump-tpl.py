import re
import glob
import os
from git import Repo

def extract_version(file_path):
    # Define the regex pattern to find the template
    pattern = re.compile(r'define\s+"([^"]+)"')

    # Read the content of the file
    with open(file_path, 'r') as file:
        content = file.readlines()

    # Iterate through each line and check for a match
    for i, line in enumerate(content):
        match = pattern.search(line)
        if match:
            # Extract the text between the quotes
            extracted_text = match.group(1)

            # Remove the .tpl suffix if present
            cleaned_text = re.sub(r'\.tpl$', '', extracted_text)

            # Bump the version number by one
            bumped_text = re.sub(r'v(\d+)', lambda m: f"v{int(m.group(1)) + 1}", cleaned_text)

            # Replace the original line with the updated version
            content[i] = line.replace(cleaned_text, bumped_text)
            
            bump_version(cleaned_text, bumped_text)

def bump_version(search_text, replace_text):
    # Get a list of all files in the repository
    all_files = [os.path.join(dp, f) for dp, dn, filenames in os.walk('./library') for f in filenames]
    # Iterate through each file and perform the search and replace
    for file_path in all_files:
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as file:
                content = file.read()
        except UnicodeDecodeError as e:
            print(f"Error reading {file_path}: {e}")
            continue
        # Replace the search_text with replace_text
        updated_content = content.replace(search_text, replace_text)
        # Write the updated content back to the file if changes were made
        if content != updated_content:
            with open(file_path, 'w') as file:
                file.write(updated_content)
            os.environ["VERSION_BUMPED"] = "true"

def get_changed_files(repo_path):
    # Initialize the repository
    repo = Repo(repo_path)

    # Get the list of staged files
    staged_files = [item.a_path for item in repo.index.diff(None)]
    
    # Get the list of files changed in the last commit
    last_commit = repo.head.commit
    committed_files = [item.a_path for item in last_commit.diff('HEAD~1')]

    # Combine both lists and remove duplicates
    changed_files = list(set(staged_files + committed_files))
    
    return changed_files

if __name__ == "__main__":
    repo_path = "."
    changed_files = get_changed_files(repo_path)
    for file in changed_files:
        extract_version(file)

if os.environ.get("VERSION_BUMPED") == "true":
    print(f"version_updated")
