SECTION .text


%macro	_print_elem 1	

		push rcx	
		push rbx
		cmp al, 'd'
		jne %%not_digit
		mov [sym], %1
		mov rcx, sym
		mov rdx, symLen
		jmp %%interrupt_params
%%not_digit:	
		cmp al, 's'
		jne cmp_symbol
		mov rcx, %1
		mov edx, strLen
%%interrupt_params:
		mov rax, 4
		mov rbx, 1

		int 80h	
		pop rbx
		pop rcx
		jmp cmp_symbol		

%endmacro	


global _start

_start:		

		mov rsi, 56
		mov rdi, str_param
		;push str_param2 
		;push 51
		call SuperPrintf

		mov rax, 1
		mov rbx, 0
		
		int 80h



SuperPrintf:

		mov rbp, rsp
		xor rbx, rbx
		xor rcx, rcx
cmp_symbol:	
		mov al, [format+rcx] 
		inc rcx


		cmp al, '0'
		je end_of_parse
		cmp al, '%'
		jne cmp_format
		mov [format_sym_ind], byte 1
		jmp cmp_symbol
cmp_format:
		cmp [format_sym_ind], byte  1
		je int_sym
		jmp cmp_symbol

int_sym:
		mov [format_sym_ind], byte 0
		inc rbx
		cmp rbx, 1
		je first_param
		cmp rbx, 2
		je second_param
		jmp other_params

first_param:
		_print_elem rsi
second_param:
		_print_elem rdi


other_params:
		push rcx
		push rbx
		mov rax, [rbp + (rbx - 2)*8] 	
		mov [sym], rax
		mov eax, 4
		mov ebx, 1
		mov ecx, sym
		mov edx, 8

		int 80h	
		pop rbx
		pop rcx
		jmp cmp_symbol		


end_of_parse:

		ret


SECTION .data

str_param:	db "something",'\0'
strLen:		equ $ - str_param
format_sym_ind:	db 0
sym:		dq 0
symLen: 	equ $ - sym
format:		db "%d%s%0",10
formatLen:	equ $ - format

