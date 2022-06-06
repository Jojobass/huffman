	Title	struc_
	Assume	cs:c, ds:d
	
d	segment
MY_STRUCT_1 STRUC;В отличие от MASM - STRUC, а не STRUCT
member_1 dw ?;
member_2 dw ?;
MY_STRUCT_1 ENDS
my_struct MY_STRUCT_1 <?>
my_struct_2 MY_STRUCT_1 <'3', '3'>
my_struct_arr MY_STRUCT_1 <'1', '1'>, <'8', '2'>, <'3', '3'>
arr_of_structs MY_STRUCT_1 256 dup (<?>)
pointr dw ?
val db '2$'
d	ends
	
c	segment
start:	mov ax,d 
	mov ds,ax

	; lea bx, my_struct
	; mov [bx].member_1, '1'
	; mov dx, [bx].member_1
	; mov ah, 2
	; int 21H

	; mov pointr, offset val
	; mov bx, [pointr]
	; mov dx, bx
	; mov ah, 9
	; int 21H

	; lea bx, my_struct
	; mov [bx].member_2, offset my_struct_2
	; mov bx, [[bx].member_2]
	; mov dx, [bx].member_1
	; mov ah, 2
	; int 21H

	; mov bx, size MY_STRUCT_1
	; mov ax, 2
	; mul bx
	; mov bx, ax
	; lea bx, [my_struct_arr + bx]
	; mov dx, [bx].member_2
	; mov ah, 2
	; int 21H

	
	lea bx, [arr_of_structs]
	lea si, [my_struct_arr]
	mov dx, [si].member_1
	mov [bx].member_1, dx
	mov dx, [bx].member_1
	mov ah, 2
	int 21h
	mov dx, [si].member_2
	mov [bx].member_2, dx
	mov dx, [bx].member_2
	mov ah, 2
	int 21h

	add si, size MY_STRUCT_1
	add bx, size MY_STRUCT_1

	mov dx, [si].member_1
	mov [bx].member_1, dx
	mov dx, [bx].member_1
	mov ah, 2
	int 21h
	mov dx, [si].member_2
	mov [bx].member_2, dx
	mov dx, [bx].member_2
	mov ah, 2
	int 21h

	sub bx, size MY_STRUCT_1
	mov [si].member_1, offset bx
	add bx, size MY_STRUCT_1
	mov [si].member_2, offset bx

	mov bx, [[si].member_1]
	mov dx, [bx].member_1
	mov ah, 2
	int 21h
	mov dx, [bx].member_2
	mov ah, 2
	int 21h

	mov bx, [[si].member_2]
	mov dx, [bx].member_1
	mov ah, 2
	int 21h
	mov dx, [bx].member_2
	mov ah, 2
	int 21h
	
	mov ah,4ch
	int	21h
	
c	ends
	end start 