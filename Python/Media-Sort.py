"""

Sorts through all pictures and videos in the directory & put them in a pics or vids folder respectively.
Also makes sure there's no duplicates. If there is it puts them in the respective duplicate folders.

"""


# Imports
import os 
import json


# Constants
PATH = input("Path: ") + "\\"
PICS_DESTINATION = PATH + "pics\\"
VIDS_DESTINATION = PATH + "vids\\"
PICS_DUPE_DESTINATION = PATH + "\\picsdupes\\"
VIDS_DUPE_DESTINATION = PATH + "\\vidsdupes\\"
INDEX_FILE = PATH + "\\index.json"
PATH_C, DIR_C, FILE_C = next(os.walk(PATH))


# Predefined values
index_values = {}
f = None
file_count = 0
file_total = len(FILE_C)


# Creating the needed directories if they aren't already there
if not os.path.isdir(PICS_DESTINATION):         os.mkdir(PICS_DESTINATION)
if not os.path.isdir(VIDS_DESTINATION):         os.mkdir(VIDS_DESTINATION)
if not os.path.isdir(PICS_DUPE_DESTINATION):    os.mkdir(PICS_DUPE_DESTINATION)
if not os.path.isdir(VIDS_DUPE_DESTINATION):    os.mkdir(VIDS_DUPE_DESTINATION)


#Try to create the index.json file but if the file already exists then read it and write it to the dictionary
try:
    with open(INDEX_FILE, 'x') as f:
        index_values = {
            "pic": 0,
            "vid": 0,
            "pic_dupe": 0,
            "vid_dupe": 0
        }
        f.write(json.dumps(index_values))
except FileExistsError:
    with open(INDEX_FILE, 'r') as f:
        index_values = json.load(f)


# Loops through the files of the given directory to sort them between pics and vids and sort out the duplicate ones
for file in os.listdir(PATH):
    # Writes the dictionary to the file at the beginning of the loop
    f = open(INDEX_FILE, 'w')
    f.write(json.dumps(index_values))
    
    
    # Splits the file into the name and the extension
    file_sep = file.split(".")
    file_ext = file_sep[-1]
    
    
    # If the file is a directory or is an excluded file(Will be making a better excluded list including extension exclusion) then skip this file and loop next one
    if file == "dupes.py" or os.path.isdir(os.path.join(PATH, file)) or file == "index.json": continue
    
    
    # Print the file name then adds to the count
    print(f"\t\t****FILE: {file_count}/{file_total}****\n\t\t{file}")
    file_count += 1


    # Predefining dupe & dupe name variables to include them in this scope
    dupe = False
    dupe_name = None


    # If the file is a MP4/MOV file then it's processed as a vid & determined if it's a duplicate
    if file_ext == "mp4" or file_ext == "mov":
        # Sorting through the already sorted videos to determine if it's a duplicate based on the bytes of the entire file
        for file_check in os.listdir(VIDS_DESTINATION):
            if open(PATH + file,"rb").read() == open(VIDS_DESTINATION + file_check,"rb").read(): 
                print(f"DUPE FOUND: {file} is a dupe to {file_check}")
                dupe = True
                dupe_name = file_check.split(".")[0]
                break
        

        if not dupe:
            os.rename(PATH + file, VIDS_DESTINATION + f"vid{index_values['vid']}.{file_ext}")
            index_values["vid"] += 1
        else:
            os.rename(PATH + file, VIDS_DUPE_DESTINATION + f"{index_values['vid_dupe']}-dupeOf-{dupe_name}.{file_ext}")
            index_values['vid_dupe'] += 1


    else:
        for file_check in os.listdir(PICS_DESTINATION):
            if open(PATH + file,"rb").read() == open(PICS_DESTINATION + file_check,"rb").read(): 
                print(f"DUPE FOUND: {file} is a dupe to {file_check}")
                dupe = True
                dupe_name = file_check.split(".")[0]
                break


        if not dupe:
            os.rename(PATH + file, PICS_DESTINATION + f"pic{index_values['pic']}.{file_ext}")
            index_values["pic"] += 1


        elif dupe:
            os.rename(PATH + file, PICS_DUPE_DESTINATION + f"{index_values['pic_dupe']}-dupeOf-{dupe_name}.{file_ext}")
            index_values["pic_dupe"] += 1




# The end of the Program gives confirmation of the sorting process finished to the terminal
print("\n\n\t\t****FILE SORTING COMPLETE!****")
