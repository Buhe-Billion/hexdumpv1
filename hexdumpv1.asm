;Description			:	When you redirect input from a file of any kind, it will read that file
;				:	16 Bytes at a time and display those Bytes in a line, as 16 hex vals
;				:	separated by spaces.
;				:
;Architecture			:	x86-64
;CPU				:	Intel® Core™2 Duo CPU T6570 @ 2.10GHz × 2
;make				:	hexdumpv1: hexdumpv1.o
;				:		ld -o hexdumpv1 hexdumpv1.o
;				:	hexdumpv1.o: hexdumpv1.asm
;				:		nasm -f elf64 -g -F dwarf hexdumpv1.asm
;				:
;NASM				:	2.14.02
;				:

SECTION .bss			;	Section containing uninitialised data

	BUFFLEN EQU 16		;	Read the file 16 bytes at a time
	BUFF: RESB BUFFLEN	;	Text buffer of 16 bytes

SECTION .data			;	Section containing initialised data

	HEXSTR: DB " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00",10
	HEXLEN EQU $-HEXSTR		;I'm guessing that this could'nt have been in .bss coz of asm time
												;calculations like this one? I mean it is uninitialised data in a sense
												;(I don't respect 0's and spaces as proper initialised data but that's just a me thing)
												; As far as I know, .bss is not allocated storage at assembly and linkage,
												;rather the loader allocates storage for .bss as and when the executable is
												;loaded into excecution.So doing assembly time logic there and then,
												; would lead to some error.Find out bitte future me reading this.
												;[In defence of this scheme, it offers a very elegant solution for including spaces
												; - think of the array as 16 sets of 3!]

	DIGITS: DB "0123456789ABCDEF"

SECTION .text			;	Section containing code

	global _start		;	Linker entry point.<Beginning of the world>

	_start:

		MOV RBP,RSP	;	4 debugging

;Read a buffer full of text from stdin:

		READ:
			MOV RAX,0	;Specify sys_read call
			MOV RDI,0	;Specify stin fd:0
			MOV RSI,BUFF	;Pass BUFF offset
			MOV RDX,BUFFLEN ;Pass # of bytes to read
			SYSCALL		;Call sys_read <ring0>
			MOV R15,RAX	;Save # of bytes read from file for later
			CMP RAX,0	;Did we reach EOF? <sys_read returns to rax the number of bytes read>
			JE DONE		;Los geht's

;Set up registers for the process Buffer step:parm

			MOV RSI,BUFF	;Place addy of file buffer into rsi
			MOV RDI,HEXSTR	;Place addy of line string into rdi
			XOR RCX,RCX	;Clear line string pointer to 0

;Go through the buffer and convert binary values to hex digits:

		SCAN:
			XOR RAX,RAX	;Clear rax to 0 <I love XOR!, like wow>

;Here we calculate the offset into the line string, which is rcx * 3

			MOV RDX,RCX	;Copy the pointer into line string into rdx
			;SHL RDX,1	;Multiply pointer by 2
			;ADD RDX,RCX	;Complete the multiplication rdx * 3
			LEA RDX,[RDX*2+RDX];Is equivalent to the previous two commented out lines

;Get a character from the buffer and put it in both rax and rbx

			MOV AL,BYTE [RSI+RCX];Put a byte from the input buffer into al
			MOV RBX,RAX	;Duplicate byte in bl for second nybble

;Look up low nybble character and insert it into string:

			AND AL,0FH	;Mask out all but the low nybble
			MOV AL,BYTE [DIGITS+RAX];Look up the char equivalent of nybble
			MOV BYTE [HEXSTR+RDX+2],AL;Write char equivalent to the line string

;Look up high nybble character and insert it into the string:

			SHR BL,4	;Shift high 4 bits of char into low 4 bits
			MOV BL, BYTE [DIGITS+RBX];Look up char equivalent of nybble
			MOV BYTE [HEXSTR+RDX+1],BL;Write the char equivalent to the line string

;Bump the buffer pointer to the next character and see if we're done:

			INC RCX		;Increment line string pointer
			CMP RCX,R15	;Compare to the number of characters in the buffer
			JNA SCAN	;Loop back if rcx is <= number of chars in buffer

;Write the line of hexadecimal values to stdout:

			MOV RAX,1	;Specify syscall 1:sys_write
			MOV RDI,1	;Specify fd:1 stdout
			MOV RSI,HEXSTR	;Pass address of line string in rsi
			MOV RDX,HEXLEN	;Pass size of the line string in rdx
			SYSCALL		;Make kernel call to display line string
			JMP READ	;Loop back and load file buffer again

;Auf Wiedersehen

		DONE:
			MOV RAX,60	;EXIT THE PROGRAM
			MOV RDI,0	;RETURN VALUE
			SYSCALL		;SERVUS UND BIS DANN


;I just realised that int 80h in x86-32 Linux used eax @ 1 for exits.
;Todo: Compare <int 80h>  and <syscall>
