.186
.model tiny
.code
org 100h


SCR_WDTH equ 80d		;width of the screen
COLOR = 4eh			;background of rectangle
INTERVAL equ 2*SCR_WDTH	;constant interval between string of rectangle
INDENT equ 9*SCR_WDTH-30d		;beginning interval to first string
VIDEO_PAGE_0 equ 0b800h			;address of zero video page
VIDEO_PAGE_1 equ 0b900h			;address of first video page
VIDEO_PAGE_2 equ 0bA00h			;address of second video page

.INT_W_H MACRO

	mov ax, 32				;put width of the rectangle at AX
	mov bx, 8				;put height of the rectangle at BX
	push bx
	mov dx, INTERVAL
	mov bx, ax
	shl bx, 1
	sub dx, bx
	pop bx

	ENDM

.VIDE_PAGES MACRO V1, V2

	mov si, V2
	mov es, si
	mov si, V1
	mov ds, si
	mov si, INDENT
	sub si, ax				
	add si, 2
	mov di, si

	ENDM

start:	jmp init

New08	proc

	push di es ax bx si cx dx ds

	.INT_W_H

	cld

	push cs
	pop ds

	cmp button, 1			;compare for activation of the rectangle
	je rec_act
	jmp ex1

rec_act:	

	push ds

	.VIDE_PAGES VIDEO_PAGE_0, VIDEO_PAGE_2

	mov cx, bx
	mov si, di

store_cmp:	push cx

	mov cx, ax

s_cmp:	

	repe cmpsw

	je cm1

cm2:	push es
	inc cx
	sub di, 2
	sub si, 2
	mov si, VIDEO_PAGE_1
	mov es, si
	mov si, di

	movsw

	pop es
	loop s_cmp

cm1:	
	add si, dx
	add di, dx
	pop cx
	loop store_cmp
	
	pop ds
	

	mov di,VIDEO_PAGE_0		 
	mov es,di				
	mov di, INDENT			
	sub di, ax				
	add di, 2				
	
	call PrintRec

	mov di, INDENT + 2*INTERVAL
	shr ax, 1
	sub di, ax

	mov si, offset RegAX
	mov cx, StrLen
	call SetPosTxt
	add di, ax
	call DrawReg
	sub di, ax
	add di, INTERVAL

IRP R,<BX, CX, DX>

	mov si, offset Reg&R
	call SetPosTxt
	add di, ax
	push ax
	mov ax, R
	call DrawReg
	pop ax
	sub di, ax
	add di, INTERVAL

ENDM

	push cs
	pop ds

	mov ax, 32
	.VIDE_PAGES VIDEO_PAGE_0, VIDEO_PAGE_2

	call Put_scr

ex1:	pop ds dx cx si bx ax es di

	pushf

	call dword ptr cs:old08adr
	iret
	endp

New09	proc

	push ds di es ax bx si cx dx

	cld

	in al,60h
	mov cl, al

	.INT_W_H

	push cs
	pop ds

	cmp button, 1
	je noact

	cmp cl, 2
	jne noact
	

	.VIDE_PAGES VIDEO_PAGE_0, VIDEO_PAGE_1

	call Put_scr

	push cs
	pop ds

	mov button, 1
	jmp ex

noact:	
	cmp cl, 3
	jne ex
	mov button, 0

	.VIDE_PAGES VIDEO_PAGE_1, VIDEO_PAGE_0

	call Put_scr
	
ex:	pop dx cx si bx ax es di ds

	pushf

	call dword ptr cs:old09adr
	
	iret

New09	endp


Set_inter	proc

	
	ret
	endp


Put_scr	proc

	push dx ax bx cx es ds si di

	mov cx, bx

	mov si, di

store:	push cx

	mov cx, ax
	rep movsw
	add si, dx
	mov di, si
	pop cx
	loop store

	pop di si ds es cx bx ax dx

	ret
	endp


;-----------------------------------------------------------------------------------
PrintRec	proc
	
	pusha			

	sub ax, 2
	sub bx, 2

	mov si, offset CharsArrayUp	
	mov cx, ax
	call DrawLine
								
	mov cx, bx
	mov si, offset CharsArrayBot		

	push bx
	mov bx, ax
	call DrawBodyRec
	pop bx

		
	mov si, offset CharsArrayUp
	add di, dx
	mov cx, ax
	call DrawLine
	popa
	ret
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

		ret
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

		ret
		endp
;------------------------------------------------------------------------------------------------
SetPosTxt	proc
		
	push di
	push cx
	shr cx, 2
	shl cx, 1
	sub di, cx
	pop cx
	call DrawText

	pop di

	ret
	endp	
;-------------------------------------------------------------------------------------------------
DrawText	proc
		cld
		
		push si di ax cx

		mov ah, color

txtrep:		lodsb
		stosw
		loop txtrep		
	
		pop cx ax di si

		ret
		endp

;------------------------------------------------------------------------------------------------
DrawReg	proc
	std

	pusha

	mov bx, offset str_sym
	mov si, 10h
	mov cx, 4

my_rep:	
	xor dx, dx
	div si
	push ax
	mov al, dl
	xlat
	mov ah, color
	stosw
	pop ax
	loop my_rep

	popa

	cld

	ret
	endp

CharsArrayUp 	db '+-+' 		;top and down string
CharsArrayBot 	db '| |'		;bottom string
str_sym db '0123456789ABCDEF'

RegVal dw ?
RegAX db 'AX$'
RegBX db 'BX$'
RegCX db 'CX$'
s_str: RegDX db 'DX$'
StrLen dw $-s_str-1

old09adr dd ?
old08adr dd ?
button db 0, '$'
rec_shape db 0,'$'

init:
	mov ah,35h
	mov al,09h
	int 21h

	mov word ptr old09adr,bx
	mov word ptr old09adr+2,es
	
	mov ah,35h
	mov al,08h
	int 21h

	mov word ptr old08adr,bx
	mov word ptr old08adr+2,es
	mov ax, 2509h
	mov dx,offset New09
	int 21h

	mov ax, 2508h
	mov dx,offset New08
	int 21h

	mov dx,offset init
	int 27h


end     start