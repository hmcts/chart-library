import re
import glob
import os

def extract_version(content):
    # Define the regex pattern to find the version string
    pattern = re.compile(r'v(\d+\.\d+\.\d+)\b')
    match = pattern.search(content)
    if match:
        return match.group(1)
    return None

def bump_version(file_path, new_version):
    # Read the content of the file
    with open(file_path, 'r') as file:
        content = file.read()

    # Extract the current version
    current_version = extract_version(content)

    # Compare the current version with the new version
    if current_version == str(new_version):
        print(f"Version in {file_path} is already .v{new_version}")
    else:
        os.environ["VERSION_BUMPED"] = "true"
        # Define the regex pattern to find the version strings
        pattern = re.compile(rf'\.v{current_version}\b')

        # Replace the old version with the new version
        updated_content = pattern.sub(f'.v{new_version}', content)

        # Write the updated content back to the file
        with open(file_path, 'w') as file:
            file.write(updated_content)

if __name__ == "__main__":
    # Define the file path pattern and new version
    tpl_file_path_pattern = 'library/templates/v2/*.tpl'
    yaml_file_path_pattern = 'library/templates/v2/*.yaml'
    new_version = os.environ["NEW_VERSION"]

    # Find all files matching the pattern
    tpl_files = glob.glob(tpl_file_path_pattern)
    yaml_files = glob.glob(yaml_file_path_pattern)

    # Update the version in each tpl file
    for file_path in tpl_files:
        bump_version(file_path, new_version)

    # Update the version in each yaml file
    for file_path in yaml_files:
        bump_version(file_path, new_version)

if os.environ.get("VERSION_BUMPED") == "true":
    print(f"version_updated")