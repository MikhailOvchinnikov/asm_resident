.186
.model tiny
.code
org 100h

start:	cli
	xor di,di
	mov es, di
	mov di,09h*4
	mov word ptr es:[di],offset New09
	mov ax,cs
	mov es:[di+2],ax
	sti

dowait:	in al,60h
	cmp al,1
	jne dowait
	mov ax,3100h
	mov dx,offset eop
	shr dx,4
	inc dx
	int 21h
	

New09	proc
	
	push ax
	push di
	push es
	
	mov di,0b800h
	mov es,di
	mov di,(5*90+80/2)*2
	mov ah, 4eh
	cld

next:	in al,60h
	mov es:[di],ax	
	
	mov al, 20h
	out 20h, al

	pop es
	pop di
	pop ax	
	iret
	endp

eop:
end     start
