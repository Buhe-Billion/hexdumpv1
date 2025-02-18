hexdumpv1: hexdumpv1.o
	ld -o hexdumpv1 hexdumpv1.o
hexdumpv1.o: hexdumpv1.asm
	nasm -f elf64 -g -F dwarf hexdumpv1.asm
