import os
import json

#
#
#

#This assembler uses the standard .text, .data, and .bss fields
#Hashtags (#) are the only accepted character for comments
#For now, it is case sensitive ;(
#Recently added support for labels

#NOTE: writes in order: .text -> .data -> .bss

#
#
#







#setting up the dictionaries
ops = {

    "CLEAR": 0b0000,
    "LOAD": 0b0001,
    "STORE": 0b0010,
    "MOVE": 0b0011,
    "BZ": 0b0100,
    "BN": 0b0101,
    "BRANCH": 0b0110,
    "OR": 0b0111,
    "XOR": 0b1000,
    "AND": 0b1001,
    "NOT": 0b1010,
    "ADD": 0b1011,
    "SUB": 0b1100,
    "INC": 0b1101,
    "DEC": 0b1110,
    "NOP": 0b1111
}



regs = {

    "R0": 0b000,
    "R1": 0b001,
    "R2": 0b010,
    "R3": 0b011,
    "R4": 0b100,
    "R5": 0b101,
    "R6": 0b110,
    "R7": 0b111

}



#DEFINING CURRENT SECTION
cur_section = ".text"

data_lines = []
bss_lines = []
text_lines = []





#defining which are short instructions
short_ins = ["CLEAR", "NOT", "INC", "DEC", "NOP"]

#defining which are always imm = 1/0 (if neithier, then could be reg or src)
imm_always_1 = ["LOAD","STORE","BZ","BN","BRANCH"]
imm_always_0 = ["MOVE"]

#current values from parsing
cur_op = None
cur_imm = None
cur_reg = None
cur_src = None

byte0 = None
byte1 = None

input_file = open("Assembler/input.txt","r")

#cleaning up the file and putting into a list
code_list = input_file.readlines()

for line in code_list:
    #splitting at # and throwing away the stuff after the #
    clean_line = line.split('#')[0].strip()
    if not clean_line:
        continue
    

    ##Split into individual parameters
    ins_parts = clean_line.replace(',', ' ').split() #ins_parts is just a list
    if not ins_parts:
        continue
        

    ### Test if a new section was declared
    if ins_parts[0] in [".data", ".bss", ".text"]:
        cur_section = ins_parts[0]
        continue # Don't add the directive itself to the compilation lists
        

    ####update the current section value and build list for each section
    if cur_section == ".data":
        data_lines.append(ins_parts)

    elif cur_section == ".bss":
        bss_lines.append(ins_parts)

    elif cur_section == ".text":
        text_lines.append(ins_parts)


input_file.close()
output_file = open("Assembler/output.txt","w")


#
#
cur_address = 0x00 #tracks the address
symbol_table = {} #creating the symbol table for all the mapping
#
#




############LABEL MAPPING
for cur_ins in text_lines:
    if len(cur_ins) == 0:
        continue
    
    
    temp_op = cur_ins[0]

    if temp_op.endswith(':'):
        #remove colon
        lbl_name = temp_op[:-1] 

        #put this new labael onto the symbol table
        symbol_table[lbl_name] = cur_address 
        
        #see if there is more stuff on the label line
        if len(cur_ins) > 1:
            temp_op = cur_ins[1]


        else:
            continue #just a standalone label line with nothin
            
    #increment the address so the symbol table has the correct address moving forward
    if temp_op in short_ins:
        cur_address += 1

    else:
        cur_address += 2
    


#############PARSING (NO WRITING) of .data (INITIALIZED)




for cur_ins in data_lines:
    var_name = cur_ins[0]

    symbol_table[var_name] = cur_address
    cur_address += 1




#############PARSING (NO WRITING) of .bss (Block Started by Symbol) (UNINITIALIZED)

for cur_ins in bss_lines:
    var_name = cur_ins[0]
    space_reserve = int(cur_ins[1], 0)

    symbol_table[var_name] = cur_address #continous from data's address locations

    ##change: now it doesn't write until later, after .text is written
    cur_address += space_reserve


#############PARSING & WRITING of .text


for cur_ins in text_lines:

    if len(cur_ins) == 0:
        continue

    #Strip the label when it find a colon
    if cur_ins[0].endswith(':'):
        cur_ins = cur_ins[1:] #Shift the entire list so now it doesn't include the label


        if len(cur_ins) == 0:
            continue #Skip if standalone label



    cur_op = cur_ins[0]
    
    if cur_op not in ops:
        raise ValueError ("invalid operation")

    #
    #
    #DEAL WITH SHORT INSTRUCTION PARSING
    if cur_op in short_ins:

        cur_imm = 0 #set to 0 for all single length instructions


        #for NOP
        try:
            cur_reg = cur_ins[1]
        except IndexError:
            cur_reg = "R0"
        #

        if cur_reg not in regs:
            raise ValueError ("Invalid register")
        #build the byte0 and then write
        byte0 = (ops[cur_op] << 4) | (cur_imm << 3) | regs[cur_reg]

        output_file.write(f"{byte0:02X}\n")
    #
    #
    #

    #
    #
    #DEAL WITH LONG INSTRUCITON PARSING
    else:

        jump_ins = ["BZ", "BN", "BRANCH"]
        #a quick length check... the branch type instructions dont need a register value
        if cur_op in jump_ins:
            if len(cur_ins) < 2:
                raise ValueError(f"Missing operand for branching type instruction: {cur_op}")
        else:
            if len(cur_ins) < 3:
                raise ValueError(f"Missing operand for math/memory instruction: {cur_op}")

        #decide imm flag
        if cur_op in imm_always_0:
            cur_imm = 0

        elif cur_op in imm_always_1:
            cur_imm = 1

        else:
            if cur_ins[2] in regs:
                cur_imm = 0
            else:
                cur_imm = 1
        
        if cur_op in jump_ins:
            cur_reg = "R0"
            cur_src = cur_ins[1] # For jumps, the target address/label is at index 1!
        else:
            cur_reg = cur_ins[1]
            if cur_reg not in regs:
                raise ValueError (f"Invalid register: {cur_reg} in instruction {cur_ins}")
            cur_src = cur_ins[2] # For math/memory, the source is at index 2.

            
        #build the byte0 and then write
        byte0 = (ops[cur_op] << 4) | (cur_imm << 3) | regs[cur_reg]
        output_file.write(f"{byte0:02X}\n")


        #build the byte1 and then write

        if cur_src in symbol_table:
        # if it happens to be a variable name from .data or .bss, substitute the associated address
            byte1 = symbol_table[cur_src]

        elif cur_src in regs:
            byte1 = (regs[cur_src] << 5) ## follows format: BBB-----

        else:
            byte1 = int(cur_src, 0) #if a variable wasn't used go to explicitly given address


        output_file.write(f"{byte1:02X}\n")
    




########WRITING of .data

for cur_ins in data_lines:
    var_value = int(cur_ins[1], 0)

    output_file.write(f"{var_value:02X}\n")


########WRITING of .bss

for cur_ins in bss_lines:
    space_reserve = int(cur_ins[1], 0)

    for i in range(space_reserve):
        output_file.write("00\n")

output_file.close()
















