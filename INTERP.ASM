.186
.model tiny
.code
org 100h

SCR_WDTH equ 80d		;width of the screen
COLOR = 4eh			;background of rectangle
INTERVAL equ 2*SCR_WDTH-4	;constant interval between string of rectangle
INDENT equ 9*SCR_WDTH-40d		;beginning interval to first string
VIDEO_PAGE_0 equ 0b800h			;address of zero video page

start:	jmp init

New09	proc
	pushf

	call dword ptr cs:old09adr

	push di es ax bx si
			
	mov ah, 4eh
	cld

	mov di,VIDEO_PAGE_0
	mov es,di
	mov di, INDENT

	in al,60h

comp_sym:
	cmp button, 2
	jne res_off
	push ax
	mov ax, es:[di]
	cmp cur_sym, ax
	pop ax
	je res_on
	call MovNextPg
	

res_on:	
	cmp al, 3
	je ret_scr
	jmp print_sym


res_off:
	cmp al,2
	je save_sym
	jmp ex

save_sym:
	mov button, al
	call MovNextPg
	jmp print_sym

ret_scr:
	mov button, 0
	call MovPrevPg
	jmp ex

print_sym:
	mov es:[di],ax
	mov cur_sym, ax

ex:	pop si bx ax es di

	
	iret

MovPrevPg	proc

	push ds cx di

	mov si, 0B900h
	mov ds, si
	mov si, di
	mov cx, 1
	rep movsw

	pop di cx ds

	ret
	endp

MovNextPg	proc

	push cx es ds di

	mov si,es
	mov ds,si
	mov si, 0B900h
	mov es, si
	mov si, di
	mov cx, 1
	rep movsw

	pop di ds es cx

	ret
	endp

;-----------------------------------------------------------------------------------
PrintRec	proc
	
	pusha			

	push bx
	mov dx, INTERVAL
	mov bx, ax
	shl bx, 1
	sub dx, bx
	pop bx

	mov si, offset CharsArrayUp	
;		mov di, INDENT
	sub di, ax	
	mov cx, ax
	call far ptr DrawLine
								
	mov cx, bx
	mov si, offset CharsArrayBot		

	push bx
	mov bx, ax
	call far ptr DrawBodyRec
	pop bx

		
	mov si, offset CharsArrayUp
	add di, dx
	mov cx, ax
	call far ptr DrawLine
	popa
	retf
	endp
;-----------------------------------------------------------
DrawLine	proc
		cld
		
		push ax si

		mov ah, color
		lodsb
		stosw

		lodsb
		rep stosw

		lodsb
		stosw	
		
		pop si ax	

		retf
		endp
;--------------------------------------------------------
DrawBodyRec	proc
		cld

		push ax bx

		mov ah, color

rep_draw_l:	push cx
		mov cx, bx
		add di, dx

		mov al, [si]
		stosw

		mov al, [si+1]
		rep stosw

		mov al, [si+2]
		stosw

		pop cx
		loop rep_draw_l

		pop bx ax

		retf
		endp
;------------------------------------------------------------------------------------------------
SetPosTxt	proc
		
	shr cx, 1
	sub di, cx
	shl cx, 1
	call far ptr DrawText

	retf
	endp	
;-------------------------------------------------------------------------------------------------
DrawText	proc
		cld
		
		push si	

		mov ah, color

txtrep:		lodsb
		stosw
		loop txtrep		
	
		pop si

		retf
		endp

CharsArrayUp 	db '+-+' 		;top and down string
CharsArrayBot 	db '| |'		;bottom string

old09adr dd ?
button db 0
cur_sym dw 0,0

New09	endp

init:	
	mov ah,35h
	mov al,09h
	int 21h

	mov word ptr old09adr,bx
	mov word ptr old09adr+2,es

	mov ax, 2509h
	mov dx,offset New09
	int 21h

	mov dx,offset init
	int 27h


end     start
