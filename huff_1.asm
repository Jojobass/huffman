title copy
assume cs:c, ds:d, ss:s

s segment stack
	dw 128 dup ('ss')
s ends

d segment
mes1 db 10, 13, 'ˆ¬ï ¢å®¤­®£® ä ©« :$'
mes2 db 10, 13, 'ˆ¬ï ¢ëå®¤­®£® ä ©« :$'
fname db 255, 0, 255 dup (?)
inhan dw ?
outhan dw ?
er1 db 10, 13, '” ©« ­¥ ®âªàë«áï$'
er2 db 10, 13, '” ©« ­¥ á®§¤ ­$'
buf db 32768 dup (?)
outbuf db 32768 dup (?)=
er3 db 10, 13, 'è¨¡ª  çâ¥­¨ï ä ©« $'
er4 db 10, 13, 'è¨¡ª  § ¯¨á¨ ä ©« $'
nulchar db 00h
read_cnt dw 0
almmin dw 0
minmin dw 0
cur_bit db 7

NODE STRUC
is_char db ?
char dw ?
num dw ?
left dw ?
right dw ?
NODE ENDS

arr_of_nodes NODE 256 dup (<?>)
arr_size dw 0
second_arr NODE 256 dup (<?>)
second_arr_size dw 0
d ends

c segment
start: mov ax, d
mov ds, ax

; USES SI, CX, BX, AX
; initialize
	mov si, 0
	mov cx, 256
	initializing: 
		mov bx, size NODE
		mov ax, si
		mul bx		; get offset of node
		mov bx, ax
		lea bx, [arr_of_nodes + bx]	; access the node
		; default values
		mov [bx].is_char, 1
		mov [bx].char, si 
		mov [bx].num, 0 
		
		; mov dx, [bx].char
		; mov	ah, 2
		; int 21h
		
		inc si
	loop initializing
; NO OUTPUT REGS

; USES AX, DX, DI, CX
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
; NO OUTPUT REGS

; USES: BX, AX, DX, SI
; iterate through chars in buf
	count_read: lea bx, buf
	.cycle:
		; if EOF
		cmp [bx], 00h
		jne .no_jump
		jmp build_tree
	.no_jump:

		; get si to point to needed node
		mov ax, size NODE
		mov dx, [bx]	; dl contains code of char
		xor dh, dh		; cleaning dh
		mul dx			; getting needed index in ax
		mov si, ax		; needed index in si
		lea si, [arr_of_nodes + si]	; accessing node

		cmp [si].num, 0
		jne .already_node
		; if num == 0, increment arr_size
		inc arr_size
		; else
		.already_node:
		; increment number of entries
		add [si].num, 1

		; mov dx, [si].num
		; add dx, '0'
		; mov ah, 2
		; int 21H

		; next char
		add bx, 1
	jmp .cycle
; NO OUTPUT REGS

build_tree:
.build_cycle:
	mov bx, arr_size
	cmp bx, 1
	jne no_jump
	jmp close_handles
	no_jump:

	call find_smallest
	call join_nodes
jmp .build_cycle


; SI - OG node
; BX - new node
; USES: DX
; copy node from SI to BX
	move_node:
		mov dl, [si].is_char
		mov [bx].is_char, dl
		xor dx, dx
		mov dx, [si].char
		mov [bx].char, dx
		mov dx, [si].num
		mov [bx].num, dx
		mov dx, [si].left
		mov [bx].left, dx
		mov dx, [si].right
		mov [bx].right, dx
		mov [si].is_char, 0
		mov [si].num, 0

		; mov dx, [bx].char
		; mov ah, 2
		; int 21h
		ret
; OUTPUT: SI, BX

; DX - smallest node index
; DI - 2nd smallest node index
; USES: AX, BX, SI, DX
; join 2 smallest nodes, 2nd smallest now is pointer
	join_nodes:
		; access smallest node
		mov bx, size NODE
		mov ax, minmin
		mul bx		; get offset of node
		mov si, ax
		lea si, [arr_of_nodes + si]	; access the node

		; access empty node from second arr
		mov bx, second_arr_size
		mov ax, size NODE
		mul bx
		mov bx, ax
		lea bx, [second_arr + bx]

		; moving node
		call move_node
		inc second_arr_size

		; access second smallest node
		mov bx, size NODE
		mov ax, almmin
		mul bx		; get offset of node
		mov si, ax
		lea si, [arr_of_nodes + si]	; access the node

		; access empty node from second arr
		mov bx, second_arr_size
		mov ax, size NODE
		mul bx
		mov bx, ax
		lea bx, [second_arr + bx]

		; moving node
		call move_node
		inc second_arr_size

		; left is smallest
		sub bx, size NODE
		mov [si].left, offset bx
		mov dx, [bx].num
		mov [si].num, dx
		; right is second smallest
		add bx, size NODE
		mov [si].right, offset bx
		mov dx, [bx].num
		add [si].num, dx

		; mov bx, [[si].left]
		; mov dx, [bx].char
		; mov ah, 2
		; int 21h
		; mov bx, [[si].right]
		; mov dx, [bx].char
		; mov ah, 2
		; int 21h
		; mov dx, [si].num
		; add dx, '0'
		; mov ah, 2
		; int 21h


		dec arr_size
		ret
; OUTPUT: BX - last node in 2nd arr, SI - new pointer node


;USES: AX, BX, CX, DX, SI
; find 2 smallest nodes
	find_smallest: lea si, [arr_of_nodes]
	xor dx, dx ;DX - ‚‘Œƒ€’…‹œ›‰ …ƒˆ‘’, —……‡ Š’›‰ ‡€ˆ‘›‚€’‘Ÿ ……Œ…›… ALMMIN ˆ MINMIN
	;mov si, 0 ;‘—ğ’—ˆŠ ‹…Œ…’€ Œ€‘‘ˆ‚€
	mov bx, 32767 ;€ˆŒ…œ˜ˆ‰ “Œ, ˆ‡€—€‹œ €ˆ‹œ˜ˆ‰, ’.…. ‚…‘œ €‡Œ… ”€‰‹€
	mov cx, 32767 ;—’ˆ €ˆŒ…œ˜ˆ‰ “Œ
	.num_st:
		; mov dx, [si].char
		; mov ah, 2
		; int 21H

		cmp [si].char, 255
		je .exit_num 

		cmp [si].num, 0
		je .num_fn

		cmp bx, [si].num
		jg .comp1
		cmp [si].num, bx
		je .comp_e

		cmp cx, [si].num
		jg .comp2

	.num_fn:
		add si, size NODE
		jmp .num_st

	.comp1:
		mov dx, minmin
		mov almmin, dx
		mov dx, [si].char
		mov minmin, dx
		; mov ah, 2
		; int 21H
		; mov dx, '1'
		; mov ah, 2
		; int 21H
		mov bx, [si].num
		jmp .num_fn

	.comp_e:
		mov dx, minmin
		mov almmin, dx
		mov dx, [si].char
		mov minmin, dx
		; mov ah, 2
		; int 21H
		; mov dx, '3'
		; mov ah, 2
		; int 21H
		mov cx, bx
	jmp .num_fn

	.comp2:
		mov dx, [si].char
		mov almmin, dx
		; mov ah, 2
		; int 21H
		; mov dx, '2'
		; mov ah, 2
		; int 21H
		mov cx, [si].num
	jmp .num_fn

	.exit_num:
		ret
		;Š€ ˆŠ€Š
;OUTPUT: ‚ ALMMIN •€ˆ’‘Ÿ —’ˆ €ˆŒ…œ˜…… ‡€—…ˆ…, ‚ MINMIN - €ˆŒ…œ˜……

close_handles: mov ah, 3eh
mov bx, inhan
int 21H

mov ah, 3eh
mov bx, outhan
int 21H

output_buf_fill:
xor cx, cx
.start
	xor ax, ax 
	lea bx, a ;a - â® ¬¥áâ®, £¤¥ «¥¦¨â ª®¤
	;’“’ “† —’-’, —’ €’€…’ ‘ ‹“—…›Œ Š„Œ, ’… ……„‚ˆƒ€…’‘Ÿ € ‘‹ –ˆ”“ ˆ‹ˆ …ğ’ ‚›‰, ’…–ˆ€‹œ .NEW_CHAR ˆ‹ˆ —’-’ ’€Š…
	cmp [bx + cx], 1
	je .fuckwithnumbers

.continue
	dec cur_bit
	cmp cur_bit, -1
	je .reset

jmp is_end

.fuckwithnumbers
	mov ah, 1
	shl ah, cur_bit
	OR dh, ah
jmp .continue

.reset
	xor dx, dx
	mov cur_bit, 7
	jmp .add_to_buf

.add_to_buf
	mov[outbuf + size outbuf], dh
	jmp is_end

.is_end
	;’“’ —’-’ ‘ „……‚Œ, ‚€Ÿ „…‹€‰
jmp .exit
jmp .next_char 

.next_char
	cmp [dx + 1], /0
	je .next_el
	inc cx
jmp .start

.next_el
	xor cx, cx
	;A ‘’€‚ˆ’‘Ÿ „“ƒˆŒ ‹…Œ…’Œ ˆ‡ „……‚€, •‡ Š€Š
jmp .start

.exit
	ret

exit:
mov ah, 4ch
int 21H

c ends
end start