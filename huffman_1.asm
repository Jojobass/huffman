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

MY_STRUCT_1 STRUC;В отличие от MASM - STRUC, а не STRUCT
char db ?;
member_2 db ?;
MY_STRUCT_1 ENDS

arr_of_structs MY_STRUCT_1 256 dup (<?>)
d ends

c segment
start: mov ax, d
mov ds, ax

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

; get_out_fname_n_create: lea dx, mes2
; mov ah, 9
; int 21H

; mov ah, 0ah
; lea dx, fname
; int 21H

; lea di, fname+2
; mov al, -1[di]
; xor ah, ah
; add di, ax
; mov [di], ah

; mov ah, 3ch
; lea dx, fname+2
; xor cx, cx
; int 21H
; jnc save_outhandle

; lea dx, er2
; mov ah, 9
; int 21H
; jmp get_out_fname_n_create

; save_outhandle: mov outhan, ax

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
je write_out
add read_cnt, 1
add bx, 1
jmp cycle

; write_out: cmp ax, 0
; jz close_handles

; mov ah, 40h
; mov bx, outhan
; lea dx, buf
; mov cx, read_cnt
; int 21H
; jnc read_in

; lea dx, er4
; mov ah, 9
; int 21H
; jmp close_handles

close_handles: mov ah, 3eh
mov bx, inhan
int 21H

mov ah, 3eh
mov bx, outhan
int 21H

mov ah, 4ch
int 21H

c ends
end start