; external functions from X11 library
extern XOpenDisplay
extern XDisplayName
extern XCloseDisplay
extern XCreateSimpleWindow
extern XMapWindow
extern XRootWindow
extern XSelectInput
extern XFlush
extern XCreateGC
extern XSetForeground
extern XDrawLine
extern XDrawPoint
extern XNextEvent

; external functions from stdio library (ld-linux-x86-64.so.2)    
extern printf
extern scanf
extern exit

%define	StructureNotifyMask	131072
%define KeyPressMask		1
%define ButtonPressMask		4
%define MapNotify		19
%define KeyPress		2
%define ButtonPress		4
%define Expose			12
%define ConfigureNotify		22
%define CreateNotify 16
%define QWORD	8
%define DWORD	4
%define WORD	2
%define BYTE	1

global main

section .bss
display_name:	resq	1
screen:			resd	1
depth:         	resd	1
connection:    	resd	1
width:         	resd	1
height:        	resd	1
window:		resq	1
gc:		resq	1

section .data

event:		times	24 dq 0

affich:db  "Ratio de la fenêtre : %d, %d",10,0
printpixel:db  "PIXEL = %d",10,0
printnuance:db  "Nuance de I = %d",10,0
change:db  "Changement",10,0
askx1:db  "Veuillez insérer x1",10,0
askx2:db  "Veuillez insérer x2",10,0
asky1:db  "Veuillez insérer y1",10,0
asky2:db  "Veuillez insérer y2",10,0
ask:db  "Voulez vous changez les coordonnées ? 0 = Non 1 = Oui",10,0
fmt_scan:       db "%d",0
fmt_scan_f:       db "%f",0
printi:db  "i = %d",10,0
printx:db  "x = %d",10,0
printy:db  "y = %d",10,0
verifcr:db  "c_r = %f",10,0
verifci:db  "ci = %f",10,0
verifzr:db  "z_r = %f",10,0
verifzi:db  "z_i = %f",10,0
verifstock:db  "stockage = %f",10,0
verify:db  "Y = %d",10,0
x1:    dd  -2.1
x2:    dd 0.6
y1:    dd  -1.2
y2:    dd 1.2
zoom:    dd  100
iteration_max:    dd  50
image_x:    dd  0
image_y:    dd  0
tmpx:    dd  0
x:    dd  0
y:    dd  0
c_r:    dd  0.0
c_i:    dd  0.0
z_r:    dd  0.0
z_i:    dd  0.0
i:    dd  0
tmp:    dd  0.0
const0: dd 0.0
const2: dd 2.0
const4: dd 4.0
stockage: dd 0.0
nuance: dd 0
value:dd 0

section .text
	
;##################################################
;########### PROGRAMME PRINCIPAL ##################
;##################################################

main:
xor     rdi,rdi
call    XOpenDisplay	; Création de display
mov     qword[display_name],rax	; rax=nom du display

; display_name structure
; screen = DefaultScreen(display_name);
mov     rax,qword[display_name]
mov     eax,dword[rax+0xe0]
mov     dword[screen],eax

mov rdi,qword[display_name]
mov esi,dword[screen]
call XRootWindow
mov rbx,rax

mov rdi,qword[display_name]
mov rsi,rbx
mov rdx,10
mov rcx,10
mov r8,400	; largeur
mov r9,400	; hauteur
push 0xFFFFFF	; background  0xRRGGBB
push 0x00FF00
push 1
call XCreateSimpleWindow
mov qword[window],rax

mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,131077 ;131072
call XSelectInput

mov rdi,qword[display_name]
mov rsi,qword[window]
call XMapWindow

mov rsi,qword[window]
mov rdx,0
mov rcx,0
call XCreateGC
mov qword[gc],rax

mov rdi,qword[display_name]
mov rsi,qword[gc]
mov rdx,0x000000	; Couleur du crayon
call XSetForeground

boucle: ; boucle de gestion des évènements
mov rdi,qword[display_name]
mov rsi,event
call XNextEvent

cmp dword[event],ConfigureNotify	; à l'apparition de la fenêtre
je dessin							; on saute au label 'dessin'

cmp dword[event],KeyPress			; Si on appuie sur une touche
je closeDisplay						; on saute au label 'closeDisplay' qui ferme la fenêtre
jmp boucle

;#########################################
;#		DEBUT DE LA ZONE DE DESSIN		 #
;#########################################
dessin:

mov rdi,ask ;On demande à l'utilisateur si il veut 
mov rax,0   ;modifier ou non les coordonnées
call printf

mov rdi, fmt_scan
mov rsi,value
mov rax,0
call scanf

mov bl, [value]
cmp bl, 0
je no_modif


mov rdi,askx1
mov rax,0
call printf

mov rdi, fmt_scan_f
mov rsi,x1
mov rax,0
call scanf

mov rdi,askx2
mov rax,0
call printf

mov rdi, fmt_scan_f
mov rsi,x2
mov rax,0
call scanf

mov rdi,asky1
mov rax,0
call printf

mov rdi, fmt_scan_f
mov rsi,y1
mov rax,0
call scanf

mov rdi,asky2
mov rax,0
call printf

mov rdi, fmt_scan_f
mov rsi,y2
mov rax,0
call scanf

mov dword[zoom], 200
mov dword[iteration_max], 100



no_modif:



movss xmm0, dword[x1]
movss xmm1,dword[x2]
cvtsi2ss xmm2, dword[zoom]

subss xmm1, xmm0 ;soustraction x2-x1
mulss xmm2, xmm1 ;mul (x2-x1) * zoom

cvtss2si edx,xmm2 ;conversion float32 bit --> int 32bit

mov dword[image_x], edx ;on range le tout dans image_x


movss xmm0, dword[y1]
movss xmm1,dword[y2]
cvtsi2ss xmm2, dword[zoom]

subss xmm1, xmm0 ;soustraction y2-y1
mulss xmm2, xmm1 ;mul (y2-y1) * zoom

cvtss2si edx,xmm2 ;conversion float32 bit --> int 32bit

mov dword[image_y], edx ;on range le tout dans image_y


mov dword[x], 0


;mov dword[image_x], 50
;mov dword[image_y], 50


for1:

mov dword[y], 0
for2:

;mov rdi, printx
;movsx rsi, dword[x]
;mov rax,0
;call printf

;mov rdi, printy
;movsx rsi, dword[y]
;mov rax,0
;call printf

cvtsi2ss xmm0, dword[x]
cvtsi2ss xmm1,dword[zoom]
movss xmm2, dword[x1]

divss xmm0, xmm1 ; x/zoom
addss xmm0, xmm2 ; x/zoom + x1 --> c_r

movss dword[c_r], xmm0

cvtsi2ss xmm0, dword[y]
cvtsi2ss xmm1,dword[zoom]
movss xmm2, dword[y1]

divss xmm0, xmm1 ;y/zoom
addss xmm0, xmm2 ; y/zoom + y1 --> c_i

movss dword[c_i], xmm0

;mov rdi, verifcr
;cvtss2sd xmm0, dword[c_r]
;mov rax, 1
;call printf

;mov rdi, verifci
;cvtss2sd xmm0, dword[c_i]
;mov rax, 1
;call printf

movss xmm0, dword[const0]
movss dword[z_r], xmm0 ;z_r = 0
movss dword[z_i], xmm0 ;z_i = 0

mov dword[i], 0 ;i=0

dowhile:

movss xmm0, dword[z_r]
movss dword[tmp], xmm0 ;tmp = z_r

movss xmm0, dword[z_r]
movss xmm1, dword[z_i]
movss xmm2, dword[c_r]

mulss xmm0, xmm0 ; z_r * z_r
mulss xmm1,xmm1 ; zi * zi 
subss xmm0, xmm1 ; zr*zr - zi*zi
addss xmm0, xmm2 ; (zr*zr - zi*zi) + c_r

movss dword[z_r], xmm0

;mov rdi,verifzr
;cvtss2sd xmm0, dword[z_r]
;mov rax,1
;call printf


movss xmm0, dword[const2]
movss xmm1, dword[z_i]
movss xmm2, dword[tmp]
movss xmm3, dword[c_i] 

mulss xmm0, xmm1 ; 2* z_i
mulss xmm0, xmm2 ; 2* z_i * tmp
addss xmm0, xmm3 ;2* z_i * tmp + c_i

movss dword[z_i], xmm0

;mov rdi,verifzi
;cvtss2sd xmm0, dword[z_i]
;mov rax,1
;call printf


inc dword[i]

movss xmm0, dword[z_r]
movss xmm1, dword[z_i]

mulss xmm0, xmm0 ; z_r = zr*zr
mulss xmm1, xmm1 ; z_i = zi*zi
addss xmm0, xmm1 ; z_r*z_r + z_i*z_i

movss dword[stockage], xmm0

;mov rdi,verifstock
;cvtss2sd xmm0, dword[z_i]
;mov rax,1
;call printf

mov rdi,printi
movsx rsi, dword[i]
mov rax,0
call printf

movss xmm0, dword[stockage]
movss xmm1, dword[const4]

ucomiss xmm0, xmm1
ja enddo

mov edx, dword[iteration_max]
cmp dword[i], edx
jae enddo
jmp dowhile

enddo:

mov edx, dword[iteration_max]
cmp dword[i], edx
jne white

mov rdi,qword[display_name]
mov rsi,qword[gc]
mov edx,0x000000	; Couleur du crayon ; noir
call XSetForeground

mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov ecx,dword[x]	; coordonnée source en x
mov r8d,dword[y]	; coordonnée source en y
mov r9d,dword[x]	; coordonnée destination en x
push qword[y]		; coordonnée destination en y
call XDrawLine

jmp enddraw

white:

mov eax, dword[i]
mov ecx, 0xFF00
mul ecx ; --> eax = eax * ecx
mov dword[nuance], eax ;i*255

mov eax, dword[nuance]
mov ebx, dword[iteration_max]
div ebx ;eax = eax/ebx
        ; i*255 / iter_max

mov dword[nuance], eax

mov rdi,qword[display_name]
mov rsi,qword[gc]
mov edx,dword[nuance]	; Couleur du crayon ; nuance de bleu
call XSetForeground

mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,qword[gc]
mov ecx,dword[x]	; coordonnée source en x
mov r8d,dword[y]	; coordonnée source en y
mov r9d,dword[x]	; coordonnée destination en x
push qword[y]		; coordonnée destination en y
call XDrawLine

enddraw:

mov edx, dword[image_y]
cmp dword[y], edx ;on compare y à image_y
jae endfor2  ;si y>= image_y on sort de la boucle
inc dword[y] ;sinon y++ et retour a la boucle for2
jmp for2

endfor2:

mov ecx, dword[image_x]
cmp dword[x], ecx ;on compare x à image_x
jae endfor1 ;si x>= image_x on sort de la boucle
inc dword[x] ;sinon x++ et retour a la boucle for1
jmp for1

endfor1:




; ############################
; # FIN DE LA ZONE DE DESSIN #
; ############################
jmp flush

flush:
mov rdi,qword[display_name]
call XFlush
jmp boucle
mov rax,34
syscall

closeDisplay:
    mov     rax,qword[display_name]
    mov     rdi,rax
    call    XCloseDisplay
    xor	    rdi,rdi
    call    exit
	