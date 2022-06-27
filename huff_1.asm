title copy
assume cs:c, ds:d, ss:s

s segment stack
	dw 128 dup ('ss')
s ends

d segment
	mes1 db 10, 13, 'Имя входного файла:$'
	mes2 db 10, 13, 'Имя выходного файла:$'
	fname db 255, 0, 255 dup (?)
	inhan dw ?
	outhan dw ?
	er1 db 10, 13, 'Файл не открылся$'
	er2 db 10, 13, 'Файл не создан$'
	buf db 16384 dup (?)
	outbuf db 16384 dup (?)
	er3 db 10, 13, 'Ошибка чтения файла$'
	er4 db 10, 13, 'Ошибка записи файла$'
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

	NODECODE STRUC
		code dw 9 dup (?)
		code_len dw ?
		node_ptr dw ?
	NODECODE ENDS

	CHARCODE STRUC
		code_ dw 9 dup (?)
		char_ dw ?
	CHARCODE ENDS

	arr_of_codes CHARCODE 256 dup (<?>)
	codes_size dw ?
	queue NODECODE 256 dup (<?>)
	q_size dw ?
	popped_item NODECODE <?>
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
	mul bx		; get offset of node_ptr
	mov bx, ax
	lea bx, [arr_of_nodes + bx]	; access the node_ptr
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

; USES SI, CX, BX, AX
; initialize
mov cx, 256
lea si, queue
lea di, arr_of_codes
init_codes:
	lea bx, [[di].code_]
	add bx, 8
	mov [bx], '$'

	lea bx, [[si].code]
	add bx, 8
	mov [bx], '$'
	
	add si, size NODECODE
	add di, size CHARCODE
loop init_codes
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
	mov cx, 16384
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

		; get si to point to needed node_ptr
		mov ax, size NODE
		mov dx, [bx]	; dl contains code of char
		xor dh, dh		; cleaning dh
		mul dx			; getting needed index in ax
		mov si, ax		; needed index in si
		lea si, [arr_of_nodes + si]	; accessing node_ptr

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

; building tree
build_tree:
.build_cycle:
	mov bx, arr_size
	cmp bx, 1
	jne no_jump
	jmp assign_codes
	no_jump:

	call find_smallest
	call join_nodes
	jmp .build_cycle
; OUTPUT: SI - root

; SI - OG node_ptr
; BX - new node_ptr
; USES: DX
; copy node_ptr from SI to BX
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

; DX - smallest node_ptr index
; DI - 2nd smallest node_ptr index
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

	; right is smallest
	sub bx, size NODE
	mov [si].right, offset bx
	mov dx, [bx].num
	mov [si].num, dx
		; mov ah, 2
		; add dx, '0'
		; int 21h
	; left is second smallest
	add bx, size NODE
	mov [si].left, offset bx
	mov dx, [bx].num
	add [si].num, dx
		; mov ah, 2
		; add dx, '0'
		; int 21h

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
; OUTPUT: BX - last node_ptr in 2nd arr, SI - new pointer node_ptr


;USES: AX, BX, CX, DX, SI
; find 2 smallest nodes
find_smallest: lea si, [arr_of_nodes]
	xor dx, dx ;DX - ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ, ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ ALMMIN ╤ПтФРтХЬ MINMIN
    ;mov si, 0 ;╤ПтФРтХЬ╤ПтФРтХЬ╨Б╨в╨з╨Ш╤ПтФРтХЬ ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ
    mov bx, 16384 ;╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ, ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ, ╤ПтФРтХЬ.╤ПтФРтХЬ. ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ
    mov cx, 16384 ;╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ ╤ПтФРтХЬ╤ПтФРтХЬ╤ПтФРтХЬ
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
;OUTPUT: ALMMIN almost min node, MINMIN - min node

; USES: AX, BX, DX, CX, SI, DI
; assigning codes and putting CHARCODEs in arr_of_codes
assign_codes:
	mov codes_size, 0
	mov q_size, size NODECODE
	lea bx, queue
	mov [bx].node_ptr, offset si
	; mov [bx].code, '1'
		; mov dx, [bx].code_len
		; add dx, '0'
		; mov ah, 2
		; int 21h
	mov [bx].code_len, 1
		; mov dx, [bx].code_len
		; add dx, '0'
		; mov ah, 2
		; int 21h
	lea bx, [[bx].code]
	mov [bx], '1'
	add bx, 8
	mov [bx], '$'

		; mov si, [[bx].node_ptr]
		; xor dx, dx
		; mov dl, [si].is_char
		; add dx, '0'
		; mov ah, 2
		; int 21h
		
		; lea bx, [[bx].code]
		; mov dx, bx
		; mov ah, 09h
		; int 21h

	jmp .pop_q

	.if_char:

			; mov ax, q_size
			; mov dx, size NODECODE
			; div dx
			; mov dx, ax
			; ; add dx, '0'
			; mov ah, 02h
			; int 21H

			; mov dx, 'i'
			; mov ah, 02h
			; int 21H

		mov si, q_size
		cmp si, 00h
		jne .not_empty
		jmp close_handles
		.not_empty:
		jmp .pop_q ; popped_item

		.after_pop:
			; mov dx, 'c'
			; mov ah, 2
			; int 21h
		lea bx, popped_item

			; xor dx, dx
			; mov dx, [bx].code_len
			; add dx, '0'
			; mov ah, 02h
			; int 21h

		mov si, [[bx].node_ptr]
		cmp [si].is_char, 0
		je .push_q
		jmp .assign

	; bx - popped item from queue
	; uses di, si, dx
	.push_q:
			; mov dx, 'b'
			; mov ah, 2
			; int 21h
		mov di, q_size
		lea di, [di + queue] ; di - new item in queue

		mov si, [[bx].node_ptr]
		mov si, [[si].left] ; si - at left child of popped

		mov [di].node_ptr, offset si ; node_ptr of new item points to left child of popped

		lea si, [[bx].code]
			; mov dx, si
			; mov ah, 9
			; int 21h
			; mov dx, '>'
			; mov ah, 2
			; int 21h
		lea di, [[di].code]
		call .copy_code

		mov di, q_size
		lea di, [di + queue] ; di - new item in queue

		mov dx, [bx].code_len ; dx - code len of popped
			; add dx, '0'
			; mov ah, 02h
			; int 21H
			; sub dx, '0'
		lea di, [[di].code]
		add di, dx
		mov [di], '0' ; added '0' to the end of code
			; mov dx, 'l'
			; mov ah, 2
			; int 21h
			; mov di, q_size
			; lea di, [di + queue] ; di - new item in queue
			; lea di, [[di].code]
			; mov dx, di
			; mov ah, 9
			; int 21h
		mov dx, [bx].code_len
		add dx, 1
		mov di, q_size
		lea di, [di + queue]
		mov [di].code_len, dx ; new code len is previous +1


		add q_size, size NODECODE


		mov di, q_size
		lea di, [di + queue] ; di - new item in queue

		mov si, [[bx].node_ptr]
		mov si, [[si].right] ; si - at right child of popped

		mov [di].node_ptr, offset si ; node_ptr of new item points to left child of popped

		lea si, [[bx].code]
			; mov dx, si
			; mov ah, 9
			; int 21h
			; mov dx, '>'
			; mov ah, 2
			; int 21h
		lea di, [[di].code]
		call .copy_code

		mov di, q_size
		lea di, [di + queue] ; di - new item in queue

		mov dx, [bx].code_len
			; add dx, '0'
			; mov ah, 02h
			; int 21H
			; sub dx, '0'
		lea di, [[di].code]
		add di, dx
		mov [di], '1' ; added '1' to the end of code
			; mov dx, 'r'
			; mov ah, 2
			; int 21h
			; mov di, q_size
			; lea di, [di + queue] ; di - new item in queue
			; lea di, [[di].code]
			; mov dx, di
			; mov ah, 9
			; int 21h
		mov dx, [bx].code_len
		add dx, 1
		mov di, q_size
		lea di, [di + queue]
		mov [di].code_len, dx ; new code len is previous +1

			; mov dx, [di].code_len
			; add dx, '0'
			; mov ah, 2
			; int 21H

		add q_size, size NODECODE

	jmp .if_char

	; uses si, di, ax, dx
	; bx - popped item from queue
	.assign:
			; mov dx, 'a'
			; mov ah, 2
			; int 21h
		mov di, codes_size
		mov ax, size CHARCODE
		mul di
		mov di, ax
		lea di, [di + arr_of_codes] ; di - new element in arr_of_codes

		mov si, [[bx].node_ptr]
		mov si, [si].char
		mov [di].char_, si ; char_ of new element is char of node
			mov dx, [di].char_
			mov ah, 2
			int 21h

			; xor ax, ax
			; mov al, [[bx].code]
			; mov dx, ax
			; mov ah, 2
			; int 21h

		lea di, [[di].code_]
		lea si, [[bx].code]
		call .copy_code ; copy the codes

			; mov dx, 's'
			; mov ah, 02h
			; int 21H

			mov di, codes_size
			mov ax, size CHARCODE
			mul di
			mov di, ax
			lea di, [di + arr_of_codes] ; si - new element in arr_of_codes
			lea ax, [[di].code_]
			mov dx, ax
			mov ah, 9
			int 21h

			; sub di, 8
			; mov cx, 9
			; output_loop:
			; 	mov dx, [di]
			; 	mov ah, 2
			; 	int 21H

		add codes_size, 1

	jmp .if_char

	; si - from, di - to, dx - buffer, ax - cnt
	.copy_code:
		mov ax, 8 ; because 1 char <= 8 bits
		copy_code_cycle:
			cmp ax, 0
			je .end_loop_code_cycle
			dec ax
			mov dx, [si]
			mov [di], dx
			add di, 1
			add si, 1
			jmp copy_code_cycle
		.end_loop_code_cycle:
		mov [di], '$'
		sub di, 8
		sub si, 8
	ret

	; si - from, di - to, dx - buffer
	.copy_node:
			; mov dx, 'd'
			; mov ah, 2
			; int 21h
		xor dx, dx
		mov dx, [si].code_len
			; add dx, '0'
			; mov ah, 2
			; int 21h
			; sub dx, '0'
		mov [di].code_len, dx
		mov dx, [si].node_ptr
		mov [di].node_ptr, dx
		lea si, [[si].code]
		lea di, [[di].code]
		call .copy_code
	ret

	; uses ax, dx, bx
	.pop_q:
		xor ax, ax
		xor dx, dx

		; lea bx, queue
		lea si, queue
			; mov dx, [si].code_len
			; add dx, '0'
			; mov ah, 2
			; int 21h
		lea di, popped_item
		call .copy_node

			; lea bx, [[bx].code]
			; add bx, 8
			; mov [bx], '$'
			; sub bx, 8
			; mov dx, bx
			; mov ah, 09h
			; int 21h

		lea bx, queue

			; mov dx, 'e'
			; mov ah, 2
			; int 21h

		mov cx, 256
		pop_cycle:
			add bx, size NODECODE
			mov si, bx

			sub bx, size NODECODE
			; mov dx, [si]
			mov di, bx
			call .copy_node

			add bx, size NODECODE
		loop pop_cycle
		xor bx, bx
		sub q_size, size NODECODE

			; mov dx, 'e'
			; mov ah, 2
			; int 21h

	jmp .after_pop
; CHARCODEs in arr_of_codes in ascending codelength order

close_handles: mov ah, 3eh
mov bx, inhan
int 21H

mov ah, 3eh
mov bx, outhan
int 21H


; output_buf_fill:
; xor cx, cx
; .start:
; 	xor ax, ax 
; 	lea bx, a  ;a - ? ????, ??? ????? ???
; 	 ;??? ????? ???-??, ??? ???????? ? ?????????? ?????, ?? ????????????? ?? ?? ????? ??? ???? ?????, ???????????? .NEW_CHAR ??? ???-?? ?????
; 	cmp [bx + cx], 1
; 	je .fuckwithnumbers

; .continue:
; 	dec cur_bit
; 	cmp cur_bit, -1
; 	je .reset

; jmp .is_end

; .fuckwithnumbers:
; 	mov ah, 1
; 	shl ah, cur_bit
; 	OR dh, ah
; jmp .continue

; .reset:
; 	xor dx, dx
; 	mov cur_bit, 7
; 	jmp .add_to_buf

; .add_to_buf:
; 	mov[outbuf + size outbuf], dh
; 	jmp .is_end

; .is_end:
; 	; ??? ???-?? ? ??????? ???? ??????
; jmp .exit1
; jmp .next_char 

; .next_char:
; 	cmp [dx + 1], '$'
; 	je .next_el
; 	inc cx
; jmp .start

; .next_el:
; 	xor cx, cx
; 	;? ?????????? ?????? ????????? ?? ?????? ?? ???
; jmp .start

; .exit1:
; 	ret

exit:
mov ah, 4ch
int 21H

c ends
end start