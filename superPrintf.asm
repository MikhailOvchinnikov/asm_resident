SECTION .text


%macro	_print_elem 1	

		push rcx	
		push rbx
		push rdi
		cmp al, 'd'
		jne %%not_int
		mov rax, %1
		xor rdx, rdx
		call PutToMemory
		mov rdx, symLen
		mov rcx, sym
		jmp %%interrupt_params
%%not_int:	
		cmp al, 'x'
		jne %%not_digit
		mov rax, %1
		mov rbx, str_x
		mov rdi, sym
		call XlatFunc
		mov rdx, symLen
		mov rcx, sym
		jmp %%interrupt_params

%%not_digit:	

		cmp al, 'c'
		jne %%long_str
		mov [sym], %1
		mov rdx, 1
		mov rcx, sym
		jmp %%interrupt_params

%%long_str:
		cmp al, 's'
		jne cmp_symbol
		mov rcx, %1
		mov rbx, %1
		call StrLen
		mov [lenSmth], rax
		mov rdx, [lenSmth]
%%interrupt_params:
		mov rax, 4
		mov rbx, 1

		int 80h	
		pop rdi
		pop rbx
		pop rcx
		jmp cmp_symbol		

%endmacro	


global _start

_start:		
		mov r8, format
		mov rsi, 859
		mov rdi, strParam
		push 450
		mov rax, strParam
		push rax
		push 60
		call SuperPrintf
		
		mov rax, 1
		mov rbx, 0
		
		int 80h



SuperPrintf:

		mov rbp, rsp
		xor rbx, rbx
		xor rcx, rcx
cmp_symbol:	
		mov al, [r8+rcx] 
		inc rcx


		cmp al, '$'
		je end_of_parse
		cmp al, '%'
		jne cmp_format
		mov [format_sym_ind], byte 1
		jmp cmp_symbol
cmp_format:
		cmp [format_sym_ind], byte  1
		je int_sym
		push rcx
		push rbx
		mov [sym+7], al
		mov rax, 4
		mov rbx, 1
		mov rcx, sym+7
		mov rdx, 1
		int 80h	
		pop rbx
		pop rcx
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
		mov rdx, [rbp + (rbx - 2)*8] 	
		_print_elem rdx

end_of_parse:
		pop rax
		shr rbx, 3
		sub rsp, rbx
		jmp rax


StrLen:
		push rcx
		push rdx
		xor rcx, rcx
cmp_sym:
		mov dl, [rbx+rcx]
		inc rcx
		cmp dl, '$'
		jne cmp_sym
		dec rcx
		mov rax, rcx

		pop rdx
		pop rcx
		ret

PutToMemory:	
		push rcx
		push rsi
		push rdi
		push rdx
		mov ecx, 7
		mov esi, 10
div_digit:
		div esi
		add dl, '0'
		mov edi, sym
		mov [edi+ecx], dl
		xor rdx, rdx
		cmp rax, 0
		je end_putmem
		loop div_digit
end_putmem:
		pop rdx
		pop rdi
		pop rsi
		pop rcx
		ret

XlatFunc:	
		push rcx
		push rsi
		mov esi, 10h
		mov rcx, 7
next_sym:
		xor rdx, rdx
		div esi
		push rax
		mov rax, rdx
		xlat
		mov [rdi+rcx], al
		pop rax
		cmp rax, 0
		je end_xlat
		loop next_sym
end_xlat:
		pop rsi
		pop rcx 	
		ret

SECTION .data

strParam:	db "something",'$'
lenSmth:	dq 0
format_sym_ind:	db 0
sym:		dq 0
symLen: 	equ $ - sym 
format:		db "%x%s Mikhail%c%s%d$",10
str_x:		db "0123456789ABCDEF$"
