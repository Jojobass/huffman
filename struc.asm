	Title	struc_
	Assume	cs:c, ds:d
	
d	segment
MY_STRUCT_1 STRUC;В отличие от MASM - STRUC, а не STRUCT
member_1 db ?;
member_2 dw ?;
MY_STRUCT_1 ENDS
my_struct MY_STRUCT_1 <?>
my_struct_2 MY_STRUCT_1 <'3', '3'>
my_struct_arr MY_STRUCT_1 <'1', '1'>, <'2', '2'>, <'3', '3'>
arr_of_structs MY_STRUCT_1 256 dup (<?>)
pointr dw ?
val db '2$'
d	ends
	
c	segment
start:	mov ax,d 
	mov ds,ax

	lea bx, my_struct
	mov [bx].member_1, '1'
	mov dl, [bx].member_1
	mov ah, 2
	int 21H

	mov pointr, offset val
	mov bx, [pointr]
	mov dx, bx
	mov ah, 9
	int 21H

	lea bx, my_struct
	mov [bx].member_2, offset my_struct_2
	mov bx, [[bx].member_2]
	mov dl, [bx].member_1
	mov ah, 2
	int 21H

	
	mov ah,4ch
	int	21h
	
c	ends
	end start 