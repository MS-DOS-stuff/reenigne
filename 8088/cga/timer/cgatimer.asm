org 0
cpu 8086

  mov al,0x34
  out 0x43,al
  xor al,al
  out 0x40,al
  out 0x40,al

  cli

  mov ax,0
  mov ds,ax
  mov ax,cs
  mov word[0x20],interrupt8
  mov [0x22],ax

  mov ds,ax
  mov es,ax
  mov ss,ax
  mov sp,0

  mov byte[repeat],0

  mov cx,9
loop3:
  push cx
  mov bx,9
  sub bx,cx
  mov al,[byteChoices + bx]
  mov [byte3],al

  mov cx,9
loop2:
  push cx
  mov bx,9
  sub bx,cx
  mov al,[byteChoices + bx]
  mov [byte2],al

  mov cx,9
loop1:
  push cx
  mov bx,9
  sub bx,cx
  mov al,[byteChoices + bx]
  mov [byte1],al

  push ax
  mov cl,4
  shr al,cl
  call printNybble
  pop ax
  and al,0x0f
  call printNybble
  mov al,' '
  int 0x62

  mov al,[byte2]
  push ax
  mov cl,4
  shr al,cl
  call printNybble
  pop ax
  and al,0x0f
  call printNybble
  mov al,' '
  int 0x62

  mov al,[byte3]
  push ax
  mov cl,4
  shr al,cl
  call printNybble
  pop ax
  and al,0x0f
  call printNybble
  mov al,' '
  int 0x62

  mov word[loadSeg],0x9000
  mov word[baseline],0
  call doExperiment
  mov word[baseline],ax

  mov word[loadSeg],0xb800
  mov cx,10
repeatLoop:
  push cx
  call doExperiment
  pop cx

  loop repeatLoop

  ; Print a newline
  mov al,10
  int 0x62

  pop cx
  loop loop1

  pop cx
  loop loop2a

  pop cx
  loop loop3a

  int 0x67

loop3a: jmp loop3
loop2a: jmp loop2

baseline: dw 0


printNybble:
  cmp al,9
  jle .numeric
  add al,'A'-10
  int 0x62
  ret
.numeric:
  add al,'0'
  int 0x62
  ret


doExperiment:
  ; Turn off refresh
  mov al,0x60  ; Timer 1, write LSB, mode 0, binary
  out 0x43,al
  mov al,0x01  ; Count = 0x0001 so we'll stop almost immediately
  out 0x41,al

  ; Enable IRQ0
  mov al,0xfe  ; Enable IRQ 0 (timer), disable others
  out 0x21,al

  ; Use IRQ0 to go into lockstep with timer 0
  mov al,0x24  ; Timer 0, write LSB, mode 2, binary
  out 0x43,al
  mov al,0x04  ; Count = 0x0004 which should be after the hlt instruction has
  out 0x40,al  ; taken effect.
  sti
  hlt

  ; The actual measurement happens in the the IRQ0 handler which runs here and
  ; returns the timer value in BX.

  ; Pop the flags pushed when the interrupt occurred
  pop ax

  mov ax,bx
  neg ax         ; Negate to get the positive number of cycles.
  sub ax,[baseline]
  push ax

 ; sub ax,8880  ; Correct for the 74 cycle multiply: 8880 = 480*74/4

  xor dx,dx
  mov cx,80    ; 960/80 = 12, and there are 12 hdots per tcycle.
  div cx       ; Divide by 80 to get number of hdots (quotient) and number of extra tcycles (remainder)

  push dx      ; Store remainder

  ; Output quotient
  xor dx,dx
  mov cx,10
  div cx
  add dl,'0'
  mov [output+3],dl
  xor dx,dx
  div cx
  add dl,'0'
  mov [output+2],dl
  xor dx,dx
  div cx
  add dl,'0'
  mov [output+1],dl
  xor dx,dx
  div cx
  add dl,'0'
  mov [output+0],dl

  ; Output remainder
  pop ax
  xor dx,dx
  div cx
  add dl,'0'
  mov [output+7],dl
  xor dx,dx
  div cx
  add dl,'0'
  mov [output+6],dl

  ; Emit the final result text
  mov si,output
  mov cx,10
  int 0x61

  pop ax
  inc byte[repeat]
  ret


output:
  db "0000 +00  "


randomTable:
  db 0xff, 0x7f, 0xff, 0x7f, 0x7f, 0x03, 0xff, 0x03
  db 0x1f, 0x03, 0x00, 0x00, 0xff, 0xff, 0x03, 0x0f
  db 0x0f, 0x01, 0x03, 0xff, 0x1f, 0x1f, 0x03, 0x7f
  db 0x0f, 0xff, 0xff, 0x3f, 0x1f, 0x1f, 0xff, 0x3f
  db 0x00, 0x3f, 0x00, 0x01, 0x1f, 0x0f, 0x01, 0xff
  db 0x07, 0x00, 0xff, 0x0f, 0x01, 0x07, 0x01, 0x03
  db 0x03, 0x01, 0x3f, 0x01, 0x00, 0x00, 0x0f, 0x1f
  db 0x0f, 0x7f, 0x0f, 0x00, 0x1f, 0x03, 0x01, 0x0f
  db 0x07, 0x0f, 0x1f, 0x3f, 0x07, 0xff, 0x7f, 0x7f
  db 0x7f, 0x3f, 0x03, 0x0f, 0x01, 0x00, 0x00, 0x3f
  db 0xff, 0x0f, 0x03, 0x3f, 0xff, 0x01, 0x7f, 0x00
  db 0xff, 0xff, 0x1f, 0x1f, 0x0f, 0x01, 0x03, 0x00
  db 0x7f, 0x7f, 0x01, 0x0f, 0x00, 0x0f, 0x00, 0x3f
  db 0x0f, 0x07, 0x1f, 0x7f, 0x0f, 0xff, 0x03, 0xff
  db 0x07, 0x03, 0x00, 0x03, 0x03, 0xff, 0x7f, 0x01
  db 0x3f, 0x3f, 0x7f, 0x1f, 0x7f, 0x3f, 0x7f, 0xff
  db 0x00, 0x07, 0xff, 0x00, 0x07, 0x7f, 0x0f, 0x0f
  db 0x1f, 0x07, 0x00, 0x7f, 0x3f, 0x01, 0x0f, 0x01
  db 0x3f, 0x0f, 0x0f, 0x7f, 0xff, 0x3f, 0xff, 0x01
  db 0x3f, 0x01, 0x01, 0x01, 0x07, 0x03, 0x00, 0x3f
  db 0x01, 0xff, 0xff, 0x01, 0x1f, 0xff, 0x7f, 0x03
  db 0x03, 0xff, 0x00, 0xff, 0x01, 0x3f, 0x03, 0x7f
  db 0xff, 0x1f, 0x07, 0x7f, 0x00, 0x03, 0x3f, 0x7f
  db 0x00, 0xff, 0x00, 0x00, 0x03, 0x07, 0x03, 0x03
  db 0x00, 0x00, 0x0f, 0x7f, 0x3f, 0x0f, 0x3f, 0x0f
  db 0x00, 0x1f, 0x7f, 0x3f, 0x7f, 0x7f, 0x1f, 0x3f
  db 0xff, 0x3f, 0x01, 0xff, 0x00, 0x00, 0x03, 0x7f
  db 0x1f, 0x01, 0x1f, 0x7f, 0x7f, 0x01, 0xff, 0x3f
  db 0x01, 0x1f, 0x0f, 0x01, 0x03, 0x1f, 0x3f, 0x00
  db 0x03, 0x0f, 0x07, 0x01, 0x7f, 0x1f, 0xff, 0xff
  db 0xff, 0x01, 0x07, 0x03, 0x00, 0xff, 0x00, 0x01
  db 0x01, 0x0f, 0x7f, 0x7f, 0x01, 0x07, 0x0f, 0x1f


savedSS: dw 0
savedSP: dw 0

loadSeg: dw 0x9000
byte1: db 0
byte2: db 0
byte3: db 0
repeat: dw 0

byteChoices: db 0x00, 0x01, 0x03, 0x07, 0x0f, 0x1f, 0x3f, 0x7f, 0xff



interrupt8:
  mov ax,[loadSeg]
  mov es,ax
  mov cx,960
  mov di,0
.loopTop
  mov al,[byte1]
  stosb
  mov al,[byte2]
  stosb
  mov al,[byte3]
  stosb
  loop .loopTop
  mov si,0

  ; Wait a random number of cycles to eliminate aliasing effects
  mov bl,[repeat]
  mov bh,0
  mov al,[bx+randomTable]
  mov bl,al
  mov cl,1
  mul cl

  mov ax,[loadSeg]
  mov ds,ax

  mov al,0x34  ; Timer 0, write LSB+MSB, mode 2, binary
  out 0x43,al
  mov al,0x00
  out 0x40,al
  out 0x40,al

  mov al,bl

%rep 960
  mul cl
  lodsb
  mul cl
  lodsb
  mul cl
  lodsb
%endrep

  in al,0x40
  mov bl,al
  in al,0x40
  mov bh,al

  mov al,0x54  ; Timer 1, write LSB, mode 2, binary
  out 0x43,al
  mov al,18
  out 0x41,al  ; Timer 1 rate

  mov al,0x20
  out 0x20,al

  mov ax,cs
  mov ds,ax
  mov es,ax

  ; Don't use IRET here - it'll turn interrupts back on and IRQ0 will be
  ; triggered a second time.
  retf

