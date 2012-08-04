.686p
.mmx
.model FLAT, C
	
GlobalAlloc PROTO STDCALL :DWORD,:DWORD
GlobalFree	PROTO STDCALL :DWORD

GETMEM MACRO PARAM1, PARAM2 
	push eax
	push ecx
	push edx
	INVOKE GlobalAlloc, 0, PARAM2
	mov PARAM1, eax
	pop edx
	pop ecx
	pop eax
ENDM

FREEMEM MACRO PARAM
	push eax
	push ecx
	push edx
	INVOKE GlobalFree, PARAM
	pop edx
	pop ecx
	pop eax
ENDM

.data
; origin
kernel1 DD 0, 0, 0, 0, 1, 0, 0, 0, 0
; blur
kernel2 DD 1, 1, 1, 1, 1, 1, 1, 1, 1
; sharpen
kernel3 DD 0, -1, 0, -1, 5, -1, 0, -1, 0
; emboss
kernel4 DD -2, -1, 0, -1, 1, 1, 0, 1, 2
; light-blur
kernel5 DD 1, 1, 0, 1, 1, 0, 0, 0, 0
; light-sharpen
kernel6 DD -1, 0, 0, 0, 2, 0, 0, 0, 0
; light-emboss
kernel7 DD 1, 0, 0, 0, 1, 0, 0, 0, -1

kernelSize DD 3
kernelVal DQ 0
pixelPosX DD 0
pixelPosY DD 0
conv_len DD 0
x DD 0
y DD 0
i DD 0
j DD 0
r DB 0
g DB 0
b DB 0
rSum DQ 0.0
gSum DQ 0.0
bSum DQ 0.0
kSum DQ 0.0
tmp4bytes DD 0
tmp2bytes DW 0
tmp1bytes DB 0
c255 DQ 255.0

pixels DD 0
tmp DD 0
tmp2 DD 0
c0114 DD 0.114
c0587 DD 0.587
c0299 DD 0.299

.code
DLLMain PROC stdcall hInst: DWORD, flag: DWORD, noUse: DWORD
	mov eax, 1
	ret
DLLMain ENDP

CONVOLUTION PROC C USES eax ebx ecx edx esi edi RGB:DWORD, W:DWORD, H:DWORD, KERNEL:DWORD
	finit
	mov x, 0
	jmp label1 
iteration_x:
	mov eax, x 
	add eax, 1 
	mov x, eax 
label1:
	mov ebx, W
	cmp x, ebx
	jge out_x
	mov y, 0 
	jmp label2 
iteration_y:
	mov eax, y 
	add eax, 1
	mov y, eax 
label2:
	mov ebx, H
	cmp y, ebx
	jge out_y 
	fldz             
	fstp rSum
	fldz             
	fstp gSum
	fldz             
	fstp bSum
	fldz             
	fstp kSum
	mov i, 0 
	jmp label3
iteration_i:
	mov eax, i 
	add eax, 1 
	mov i, eax 
label3:
	mov eax, i
	mov ebx, kernelSize
	cmp eax, ebx 
	jge out_i
	mov j, 0 
	jmp label4
iteration_j: 
	mov eax, j 
	add eax,1 
	mov j, eax 
label4:
	mov eax, j
	mov ebx, kernelSize
	cmp eax, ebx
	jge out_j
	mov eax, kernelSize
	cdq              
	sub eax,edx 
	sar eax, 1 
	mov ecx, i 
	sub ecx, eax 
	add ecx, x 
	mov pixelPosX, ecx 
	mov eax, kernelSize
	cdq
	sub eax, edx 
	sar eax, 1 
	mov ecx, j 
	sub ecx, eax 
	add ecx, y
	mov pixelPosY, ecx 
	cmp pixelPosX, 0 
	jl continue
	mov ebx, W
	cmp pixelPosX, ebx
	jge continue
	cmp pixelPosY, 0 
	jl continue
	mov ebx, H
	cmp pixelPosY, ebx
	jl letsgo
continue:
	jmp iteration_j
letsgo:
	xor edx, edx
	mov eax, pixelPosX
	mov ebx, H
	imul eax, ebx
	shl eax, 2
	mov ecx, pixelPosY
	mov edx, RGB
	add edx, eax
	mov dl, byte ptr [edx+ecx*4][0]
	mov r, dl
	xor edx, edx
	mov eax, pixelPosX
	mov ebx, H
	imul eax, ebx
	shl eax, 2
	mov ecx, pixelPosY
	mov edx, RGB
	add edx, eax
	mov dl, byte ptr [edx+ecx*4][1]
	mov g, dl
	xor edx, edx
	mov eax, pixelPosX
	mov ebx, H
	imul eax, ebx
	shl eax, 2
	mov ecx, pixelPosY
	mov edx, RGB
	add edx, eax
	mov dl, byte ptr [edx+ecx*4][2]
	mov b, dl
	mov eax, i 
	imul eax, kernelSize
	mov ebx, KERNEL
	lea ecx, [ebx+eax*4]
	mov edx, j
	fild dword ptr [ecx+edx*4] 
	fstp kernelVal 
	movzx eax, r
	mov tmp4bytes, eax
	fild tmp4bytes
	fmul kernelVal
	fadd rSum 
	fstp rSum
	movzx eax, g 
	mov tmp4bytes, eax 
	fild tmp4bytes
	fmul kernelVal 
	fadd gSum 
	fstp gSum 
	movzx eax, b 
	mov tmp4bytes, eax 
	fild tmp4bytes
	fmul kernelVal 
	fadd bSum 
	fstp bSum 
; kSum += kernelVal;
	fld kSum 
	fadd kernelVal 
	fstp kSum 
	jmp iteration_j
out_j:
	jmp iteration_i
out_i:
	fldz             
	fcomp kSum 
	fnstsw ax   
	test ah,1 
	jne wtf1
	fld1             
	fstp kSum 
wtf1:
	fld rSum 
	fdiv kSum 
	fstp rSum 
	fldz             
	fcomp rSum 
	fnstsw ax   
	test ah,41h 
	jne wtf2
	fldz             
	fstp rSum 
wtf2:
	fld qword ptr c255
	fcomp rSum 
	fnstsw ax   
	test ah, 5 
	jp wtf3
	fld qword ptr c255
	fstp rSum
wtf3:
	fld gSum 
	fdiv kSum 
	fstp gSum 
	fldz
	fcomp gSum 
	fnstsw ax   
	test ah,41h 
	jne wtf4
	fldz
	fstp gSum 
wtf4:
	fld qword ptr c255
	fcomp gSum
	fnstsw ax   
	test ah,5 
	jp wtf5
	fld qword ptr c255
	fstp gSum 
wtf5:
	fld bSum 
	fdiv kSum
	fstp bSum 
	fldz             
	fcomp bSum 
	fnstsw ax   
	test ah,41h 
	jne wtf6
	fldz             
	fstp bSum
wtf6:
	fld qword ptr c255
	fcomp bSum 
	fnstsw ax   
	test ah, 5 
	jp wtf7
	fld qword ptr c255
	fstp bSum 
wtf7:
	fld rSum 
	fistp tmp4bytes
	xor edx, edx
	mov ebx, H
	mov eax, x 
	imul eax, ebx
	shl eax, 2
	mov edx, y
	mov ebx, pixels
	add ebx, eax
	mov ecx, tmp4bytes
	mov byte ptr [ebx+edx*4][0],cl 
	fld gSum 
	fistp tmp4bytes
	xor edx, edx
	mov ebx, H
	mov eax, x 
	imul eax, ebx
	shl eax, 2
	mov edx, y
	mov ebx, pixels
	add ebx, eax
	mov ecx, tmp4bytes
	mov byte ptr [ebx+edx*4][1],cl 
	fld bSum 
	fistp tmp4bytes
	xor edx, edx
	mov ebx, H
	mov eax, x 
	imul eax, ebx
	shl eax, 2
	mov edx, y
	mov ebx, pixels
	add ebx, eax
	mov ecx, tmp4bytes
	mov byte ptr [ebx+edx*4][2],cl 
	jmp iteration_y
out_y:
	jmp iteration_x
out_x:
	ret
CONVOLUTION ENDP

GRAYSCALE PROC C USES eax ebx ecx edx esi edi RGB: DWORD, W: DWORD, H: DWORD, PR: DWORD, PG: DWORD, PB: DWORD
	mov esi, RGB
	mov edi, pixels
	mov ebx, W
	mov ecx, H
	imul ebx, ecx
	xor ecx, ecx
	.WHILE ecx < ebx
		lodsd
		mov tmp, eax

; blue
		xor edx, edx
		mov dl, byte ptr tmp[0]
		mov tmp2, edx
		fld tmp2
		fmul PB
		fmul c0114
		fstp tmp2
		mov eax, tmp2
; green
		mov dl, byte ptr tmp[1]
		mov tmp2, edx
		fld tmp2
		fmul PG
		fmul c0587
		fstp tmp2
		add eax, tmp2
; red
		mov dl, byte ptr tmp[2]
		mov tmp2, edx
		fld tmp2
		fmul PR
		fmul c0299
		fstp tmp2
		add eax, tmp2

		mov [edi+ecx*4][0], al
		mov [edi+ecx*4][1], al
		mov [edi+ecx*4][2], al
		inc ecx
	.ENDW
	ret
GRAYSCALE ENDP

mmxProc PROC C USES ebx ecx edx rgb:DWORD, w:DWORD, h:DWORD, PR: DWORD, PG: DWORD, PB: DWORD
	xor edx, edx
	mov eax, w
	mov ebx, h
	mul ebx
	mov conv_len, eax
	shl eax, 2
  	INVOKE GRAYSCALE, rgb, w, h, pr, pg, pb
	mov esi, pixels
	mov edi, rgb
	mov ecx, conv_len
	rep movsd
	mov eax, 0
    ret
mmxProc ENDP

end DLLMain
