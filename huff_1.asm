title copy
assume cs:c, ds:d, ss:s

s segment stack
	dw 128 dup ('ss')
s ends

d segment
mes1 db 10, 13, 'ฌ๏ ขๅฎคญฎฃฎ ไ ฉซ :$'
mes2 db 10, 13, 'ฌ๏ ข๋ๅฎคญฎฃฎ ไ ฉซ :$'
fname db 255, 0, 255 dup (?)
inhan dw ?
outhan dw ?
er1 db 10, 13, ' ฉซ ญฅ ฎโชเ๋ซแ๏$'
er2 db 10, 13, ' ฉซ ญฅ แฎงค ญ$'
buf db 32768 dup (?)
er3 db 10, 13, '่จกช  ็โฅญจ๏ ไ ฉซ $'
er4 db 10, 13, '่จกช  ง ฏจแจ ไ ฉซ $'
nulchar db 00h
read_cnt dw 0
almmin dw 0
minmin dw 0

NODE STRUC
is_char db ?
char dw ?
num dw ?
left dw ?
right dw ?
NODE ENDS

arr_of_nodes NODE 256 dup (<?>)
d ends

c segment
start: mov ax, d
mov ds, ax

; initialize
; USES: AX, BX, CX, SI
mov si, 0
mov cx, 256
initializing: mov bx, size NODE
    mov ax, si
    mul bx
    mov bx, ax
    lea bx, [arr_of_nodes + bx]
	mov [bx].is_char, 1
	mov [bx].char, si 
	mov [bx].num, 0 
    
    ; mov dx, [bx].char
	; mov	ah, 2
	; int 21h
    
	inc si
loop initializing

; open file by name
get_in_fname_n_open: lea dx, mes1
	mov ah, 9
	int 21H

	mov ah, 0ah
	lea dx, fname
	int 21H

	lea di, fname+2
	mov al, -1[di]
	xor ah, ah
	add di, ax
	mov [di], ah

	mov ah, 3dh
	lea dx, fname+2
	xor al, al
	int 21H
	jnc save_inhandle

	lea dx, er1
	mov ah, 9
	int 21H
jmp get_in_fname_n_open

save_inhandle: mov inhan, ax


; read file
read_in: mov bx, inhan
mov ah, 3fh
lea dx, buf
mov cx, 32768
int 21H
jnc count_read

lea dx, er3
mov bx, inhan
int 21H
jmp close_handles

; iterate through chars to read
count_read: lea bx, buf
cycle: cmp [bx], 00h
	je close_handles

	mov ax, size NODE
	mov dx, [bx]
	xor dh, dh
	mul dx
	mov si, ax
	lea si, [arr_of_nodes + si]
	add [si].num, 1
	mov dx, [si].num
	add dx, '0'
	mov ah, 2
	int 21H

	add bx, 1
jmp cycle



close_handles: mov ah, 3eh
mov bx, inhan
int 21H

mov ah, 3eh
mov bx, outhan
int 21H

;USES: AX, BX, CX, DX, SI
xor dx, dx ;DX -  ,     ALMMIN  MINMIN
;mov si, 0 ;๐  
mov bx, 32768 ; ,  , ..   
mov cx, 32767 ;  


	
num_node: lea si, [arr_of_nodes]
.num_st:
	mov dx, [si].char
	mov ah, 2
	int 21H

	cmp [si].char, 255
	je .exit_num 

	cmp [si].num, 0
	je .num_fn

	cmp [si].num, bx
	jg .comp1
	cmp [si].num, bx
	je .comp_e

	cmp [si].num, cx
	jg .comp2

.comp1:
	mov dx, minmin
	mov almmin, dx
	mov dx, [si].char
	mov minmin, dx
	mov ah, 2
	int 21H
	mov bx, [si].num
	jmp .num_fn

.comp_e:
	mov dx, minmin
	mov almmin, dx
	mov dx, [si].char
	mov minmin, dx
	mov cx, [si].num
jmp .num_fn

.comp2:
	mov dx, [si].char
	mov almmin, dx
	mov cx, [si].num
jmp .num_fn

.num_fn:
	add si, size NODE
	jmp .num_st

.exit_num:
	;ret
	; 
;OUTPUT:  ALMMIN    ,  MINMIN - 

exit:
mov ah, 4ch
int 21H

c ends
end start