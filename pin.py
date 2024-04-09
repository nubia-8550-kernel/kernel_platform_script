import xml.etree.ElementTree as ET
import subprocess
import os

# Define the list of XML files
xml_files = ['.repo/manifests/kernel.xml', '.repo/manifests/modules.xml']

# Get the absolute path of the root directory
root_dir = os.path.abspath('.')

for xml_file in xml_files:
    # Load the XML file
    tree = ET.parse(xml_file)
    root = tree.getroot()

    # Find all project elements
    for project in root.findall('.//project'):
        # Extract the repository path
        repo_path = project.get('path')
        
        # Get the absolute path of the repository
        abs_repo_path = os.path.join(root_dir, repo_path)
        
        # Change to the repository directory
        os.chdir(abs_repo_path)
        
        # Get the current commit hash
        commit_hash = subprocess.check_output(['git', 'rev-parse', 'HEAD']).strip().decode('utf-8')
        
        # Set the commit hash as the revision attribute
        project.set('revision', commit_hash)
        
    # Change back to the root directory before saving the XML file
    os.chdir(root_dir)

    # Save the XML file with the same formatting
    with open(xml_file, 'wb') as f:
        tree.write(f, xml_declaration=True, encoding='utf-8')