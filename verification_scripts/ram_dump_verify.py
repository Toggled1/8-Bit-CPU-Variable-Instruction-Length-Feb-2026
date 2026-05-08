#The expected_contents file should only include the RAM indexes and contents that are of interest
#Example:
"""
    15: 0F --addresses in decimal, memory content in hex
    16: 11
    17: A4
    88: 94
    89: 43

"""
#Ram dump in tb file



raw_lines_expected = {} #just lists
raw_lines_dumped = {}

expected_mapping = {} #dictionaries in form [index (base 10)] = value
dumped_mapping = {}

expected_file = open("verification_scripts/expected_contents.txt","r")
dumped_file = open("tb/ram_dump.txt","r")

raw_lines_expected = expected_file.read().splitlines()
raw_lines_dumped = dumped_file.read().splitlines()

######Parsing expected file into a dictionary

for line in raw_lines_expected:
    
    temp = line.split(':')
    expected_mapping[temp[0].strip()] = temp[1].strip()
    


#####Parsing dumped file into a dictionary
wrong_lines = 0
for line in raw_lines_dumped:
    
    temp = line.split(':')
    dumped_mapping[temp[0].strip()] = temp[1].strip()
    

####Comparing indexes of interest form expected dictionary to dumped dictionary

for test_index in expected_mapping:

    if expected_mapping[test_index] != dumped_mapping[test_index]:
        print(f"Location mem[{hex(int(test_index))}] contains incorrect value: {dumped_mapping[test_index]}.\nShould contain value {expected_mapping[test_index]}")
        wrong_lines = wrong_lines + 1

if wrong_lines == 0:
    print("all the memory locations returned correct values")

expected_file.close()
dumped_file.close()