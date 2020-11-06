# Azeria Labs ARM training notes
## Stack0
The stack of the main function has a size of 80 bytes. However, all calculations for variables are done from the frame pointer which is pointing at the saved link register(return address) on the stack. The buffer is loaded into r3 for the call to the 'gets' like function. r3 gets the address from the frame pointer - 72. 
![stack0 vulnerable buffer](res/stack0_vuln_buf.png) 
Before the overflow you can see different values on the stack such as the addresses of do_lookup, frame_dummy and others. The important value we are trying to overwrite is 0xb6e8c294 at the bottom of the stack pointed to by r11 the frame pointer. This is the address of where we want to return in __libc_start_main.
![stack0 correct stack](res/stack0_correct_stack.png) 
With an overflow of 76 bytes we can overwrite the saved frame pointer at frame pointer - 4 and the saved link register(return address) at frame pointer. Below you can see the stack is now populated by nop values, followed by shellcode, followed by the value with which we overwrite the saved link register. The __libc_start_main value has been replaced with a stack address which will cause execution to start somewhere in our nop values.
![stack0 running shellcode](res/stack0_exploited_stack.png) 
Here you can see the shell code running
![stack0 running shellcode](res/stack0_running_shellcode.png) 
However, when the same exploit blob is run without GDB all we get is a segfault...
Unsure why we are not getting a shell.
![stack0 segfault](res/stack0_segfault.png) 