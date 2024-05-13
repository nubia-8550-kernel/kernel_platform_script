import lxml.etree as ET
import subprocess
import os
import re

# Define the list of XML files
xml_files = ['.repo/manifests/kernel.xml', '.repo/manifests/modules.xml']

# Get the absolute path of the root directory
root_dir = os.path.abspath('.')

for xml_file in xml_files:
    # Load the XML file
    parser = ET.XMLParser()
    tree = ET.parse(xml_file, parser)
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

    # Convert the XML tree to a string without the XML declaration
    xml_string = ET.tostring(root, pretty_print=True, encoding='UTF-8').decode('utf-8')

    # Use regex to replace ' />' with '/>'
    xml_string = re.sub(' />', '/>', xml_string)

    # Manually create the XML declaration with double quotes
    xml_declaration = '<?xml version="1.0" encoding="UTF-8"?>\n'

    # Combine the XML declaration and the XML string
    xml_string = xml_declaration + xml_string

    # Save the XML file with the same formatting
    with open(xml_file, 'w') as f:
        f.write(xml_string)