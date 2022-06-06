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
buf db 32768 dup (?)
er3 db 10, 13, 'Ошибка чтения файла$'
er4 db 10, 13, 'Ошибка записи файла$'
nulchar db 00h
read_cnt dw 0

NODE STRUC
is_char db ?
char dw ?
num dw ?
left dw ?
right dw ?
NODE ENDS

arr_of_nodes NODE 256 dup (<?>)
buf1 db "hello"
d ends

c segment
start: mov ax, d
mov ds, ax

mov si, 0
mov cx, 256

iteration: mov bx, size NODE
    mov ax, si
    mul bx
    mov bx, ax
    lea bx, [arr_of_nodes + bx]
	mov [bx].is_char, 1
	mov [bx].char, si 
	mov [bx].num, 0 
    
    mov dx, [bx].char
	mov	ah, 2
	int 21h
    
    ;mov ax, si
    ;mov dx, ax
    ;add dl, '0'
    ;mov ah, 2
    ;int 21h
	inc si
	;dec cx
loop iteration

lea bx, buf1
mov dx, [bx]
xor bx, bx
mov bl, dl
mov dl, bl
mov	ah, 2
int 21h

mov ax, size NODE
mul bx
mov si, ax
lea si, [arr_of_nodes + si]

mov dx, [si].char
; add dx, '0'
mov	ah, 2
int 21h

add [si].num, 1
mov dx, [si].num
add dx, '0'
mov	ah, 2
int 21h



; mov si, 0
; mov cx, 256
; output: mov bx, size NODE
;     mov ax, si
;     mul bx
;     mov bx, ax
;     lea bx, [arr_of_nodes + bx]
;     mov dx, [bx].char
; 	mov	ah, 2
; 	int 21h
;     ;mov ax, arr_of_nodes[si].num
; 	;mov dl, al
; 	;mov	ah, 2
; 	;int 21h
; 	inc si
; loop output 

exit:
mov ah, 4ch
int 21H

c ends
end start