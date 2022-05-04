SECTION .text



%macro _val_to_mem 2

		mov rax, %1
		mov rbx, str_x
		mov rdi, sym
		mov esi, %2
		call Xlat
		mov rdx, SYM_LEN
		sub rdx, rcx
		inc rdx
		mov rsi, rcx
		add rsi, sym
		dec rsi
%endmacro


%macro	_print_elem 1	

		push rcx	
		push rbx
		push rdi
		cmp al, 'd'
		jne %%x_format
		_val_to_mem %1, 10	
		jmp %%interrupt_params

%%x_format:	
		cmp al, 'x'
		jne %%o_format
		_val_to_mem %1, 10h	
		jmp %%interrupt_params

%%o_format:	
		cmp al, 'o'
		jne %%b_format
		_val_to_mem %1, 8h		
		jmp %%interrupt_params

%%b_format:	
		cmp al, 'b'
		jne %%not_digit
		_val_to_mem %1, 2h		
		jmp %%interrupt_params

%%not_digit:	

		cmp al, 'c'
		jne %%long_str
		mov [sym], %1
		mov rdx, 1
		mov rsi, sym
		jmp %%interrupt_params

%%long_str:
		cmp al, 's'
		jne cmp_symbol
		mov rsi, %1
		mov rbx, %1
		call StrLen
		mov [lenSmth], rax
		mov rdx, [lenSmth]

%%interrupt_params:
		mov rax, 1
		mov rdi, 1
		push r11
		syscall
		pop r11
		pop rdi
		pop rbx
		pop rcx
		jmp cmp_symbol		

%endmacro	


global _start

_start:		
		mov r8, format
		mov r9, 685
		mov r10, strParam
		mov r12, 685
		mov r13, strParam
		mov r14, 685
		mov r15, strParam
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
		push rbp
		xor rbx, rbx
		xor rcx, rcx
		xor r11, r11
cmp_symbol:	
		mov al, [r8+rcx] 
		inc rcx
		

		cmp al, '$'
		je end_of_parse
		cmp al, '%'
		jne cmp_format
		cmp [format_sym_ind], byte 1
		je simple_sym
		mov [format_sym_ind], byte 1
		jmp cmp_symbol
cmp_format:
		cmp [format_sym_ind], byte  1
		je format_sym
simple_sym:
		mov [format_sym_ind], byte 0
		
		mov [temp_buffer + r11], al
		inc r11
		cmp r11, 49
		jne cmp_symbol
	
		call Write_buffer
		jmp cmp_symbol		

format_sym:
		mov [format_sym_ind], byte 0
		call Write_buffer
		cmp rbx, 6
		jae other_params
		mov rdx, REG_NUM
		shl rbx, 3
		add rdx, rbx
		shr rbx, 3
		inc rbx
		jmp [rdx]

first_param:
		_print_elem r9
second_param:
		_print_elem r10
third_param:
		_print_elem r12
fourth_param:
		_print_elem r13
fifth_param:
		_print_elem r14
sixth_param:
		_print_elem r15
other_params:
		inc rbx
		mov rdx, [rbp + (rbx - 6)*8] 	
		_print_elem rdx

end_of_parse:
		call Write_buffer
		pop rbp
		pop rax
		shr rbx, 3
		sub rsp, rbx
		jmp rax


Write_buffer:	
		push rcx
		push rbx
		push rax
		mov rax, 1
		mov rdi, 1
		mov rsi, temp_buffer
		mov rdx, r11
		syscall
		xor r11, r11
		pop rax
		pop rbx
		pop rcx

		ret


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
		push rsi
		push rdi
		push rdx
		mov ecx, OFFSET_SYM
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
		ret

Xlat:	
		mov rcx, 8
next_sym:
		xor rdx, rdx
		div esi
		push rax
		mov rax, rdx
		xlat
		mov [rdi+rcx-1], al
		pop rax
		cmp rax, 0
		je end_xlat
		loop next_sym
end_xlat:
		ret
			

SECTION .data

strParam:	db "something",'$'
lenSmth:	dq 0
format_sym_ind:	db 0
sym:		dq 0
SYM_LEN	 	equ $ - sym 
OFFSET_SYM	equ 7
format:		db "%%%b%s%o%s%x%s Mi%%%%khail%c%s%dEnd of the string$"
str_x:		db "0123456789ABCDEF$"
temp_buffer:	times 50 db 0
REG_NUM:	dq first_param
		dq second_param
		dq third_param
		dq fourth_param
		dq fifth_param
		dq sixth_param
