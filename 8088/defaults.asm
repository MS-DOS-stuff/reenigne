cpu 8086
org 0

%macro initCGA 1
  %if (%1 & 0x10) != 0
    initCGA %1, 0x0f
  %else
    initCGA %1, 0
  %endif
%endmacro

%macro initCGA 2
  ; Mode
  ;      1 +HRES
  ;      2 +GRPH
  ;      4 +BW
  ;      8 +VIDEO ENABLE
  ;   0x10 +1BPP
  ;   0x20 +ENABLE BLINK
  mov dx,0x3d8
  mov al,%1
  out dx,al

  ; Palette
  ;      1 +OVERSCAN B
  ;      2 +OVERSCAN G
  ;      4 +OVERSCAN R
  ;      8 +OVERSCAN I
  ;   0x10 +BACKGROUND I
  ;   0x20 +COLOR SEL
  mov dx,0x3d9
  mov al,%2
  out dx,al

  mov dx,0x3d4

  ;   0xff Horizontal Total                             38 71
  %if (%1 & 1) != 0
    mov ax,0x7100
  %else
    mov ax,0x3800
  %endif
  out dx,ax

  ;   0xff Horizontal Displayed                         28 50
  %if (%1 & 1) != 0
    mov ax,0x5001
  %else
    mov ax,0x2801
  %endif
  out dx,ax

  ;   0xff Horizontal Sync Position                     2d 5a
  %if (%1 & 1) != 0
    mov ax,0x5a02
  %else
    mov ax,0x2d02
  %endif
  out dx,ax

  ;   0x0f Horizontal Sync Width                              0a
  mov ax,0x0a03
  out dx,ax

  ;   0x7f Vertical Total                                        1f 7f
  %if (%1 & 2) != 0
    mov ax,0x7f04
  %else
    mov ax,0x1f04
  %endif
  out dx,ax

  ;   0x1f Vertical Total Adjust                              06
  mov ax,0x0605
  out dx,ax

  ;   0x7f Vertical Displayed                                    19 64
  %if (%1 & 2) != 0
    mov ax,0x6406
  %else
    mov ax,0x1906
  %endif
  out dx,ax

  ;   0x7f Vertical Sync Position                                1c 70
  %if (%1 & 2) != 0
    mov ax,0x7007
  %else
    mov ax,0x1c07
  %endif
  out dx,ax

  ;   0x03 Interlace Mode                                     02
  mov ax,0x0208
  out dx,ax

  ;   0x1f Max Scan Line Address                                 07 01
  %if (%1 & 2) != 0
    mov ax,0x0109
  %else
    mov ax,0x0709
  %endif
  out dx,ax

  ; Cursor Start                                              06
  ;   0x1f Cursor Start                                        6
  ;   0x60 Cursor Mode                                         0
  mov ax,0x060a
  out dx,ax

  ;   0x1f Cursor End                                         07
  mov ax,0x070b
  out dx,ax

  ;   0x3f Start Address (H)                                  00
  mov ax,0x000c
  out dx,ax

  ;   0xff Start Address (L)                                  00
  mov ax,0x000d
  out dx,ax

  ;   0x3f Cursor (H)                                         03  0x3c0 == 40*24 == start of last line
  mov ax,0x030e
  out dx,ax

  ;   0xff Cursor (L)                                         c0
  mov ax,0xc00f
  out dx,ax
%endmacro


; Assumes DS == 0
%macro setInterrupt 2
  mov word [%1*4], %2
  mov [%1*4 + 2], cs
%endmacro


%macro initSerial 0
  mov dx,0x3f8  ; COM1 (0x3f8 == COM1, 0x2f8 == COM2, 0x3e8 == COM3, 0x2e8 == COM4)

  ; dx + 0 == Transmit/Receive Buffer   (bit 7 of LCR == 0)  Baud Rate Divisor LSB (bit 7 of LCR == 1)
  ; dx + 1 == Interrupt Enable Register (bit 7 of LCR == 0)  Baud Rate Divisor MSB (bit 7 of LCR == 1)
  ; dx + 2 == Interrupt Identification Register IIR (read)   16550 FIFO Control Register (write)
  ; dx + 3 == Line Control Register LCR
  ; dx + 4 == Modem Control Register MCR
  ; dx + 5 == Line Status Register LSR
  ; dx + 6 == Modem Status Register MSR
  ; dx + 7 == Scratch Pad Register

  add dx,3    ; 3
  mov al,0x80
  out dx,al   ; Set LCR bit 7 to 1 to allow us to set baud rate

  dec dx      ; 2
  dec dx      ; 1
  mov al,0x00
  out dx,al   ; Set baud rate divisor high = 0x00

  dec dx      ; 0
  mov al,2 ;0x01
  out dx,al   ; Set baud rate divisor low  = 0x01 = 115200 baud

  add dx,3    ; 3
  ; Line Control Register LCR                                03
  ;      1 Word length -5 low bit                             1
  ;      2 Word length -5 high bit                            2
  ;      4 1.5/2 stop bits                                    0
  ;      8 parity                                             0
  ;   0x10 even parity                                        0
  ;   0x20 parity enabled                                     0
  ;   0x40 force spacing break state                          0
  ;   0x80 allow changing baud rate                           0
  mov al,0x03
  out dx,al

  dec dx      ; 2
  dec dx      ; 1
  ; Interrupt Enable Register                                00
  ;      1 Enable data available interrupt and 16550 timeout  0
  ;      2 Enable THRE interrupt                              0
  ;      4 Enable lines status interrupt                      0
  ;      8 Enable modem status change interrupt               0
  mov al,0x00
  out dx,al

  add dx,3    ; 4
  ; Modem Control Register                                   00
  ;      1 Activate DTR                                       0
  ;      2 Activate RTS                                       0
  ;      4 OUT1                                               0
  ;      8 OUT2                                               0
  ;   0x10 Loop back test                                     0
  out dx,al
%endmacro


; Receive a byte over serial and put it in AL. DX == port base address + 5
%macro receiveByte 0
    ; Wait until a byte is available
  %%waitForData:
    in al,dx
    test al,1
    jz %%waitForData
    ; Read the data byte
    sub dx,5
    in al,dx
    add dx,5
%endmacro


; Send byte in AL over serial. DX == port base address + 5
%macro sendByte 0
    mov ah,al
  %%waitForSpace:
    in al,dx
    test al,0x20
    jz %%waitForSpace
    inc dx
  %%waitForDSR:
    in al,dx
    test al,0x20
    jz %%waitForDSR
    ; Write the data byte
    sub dx,6
    mov al,ah
    out dx,al
    add dx,5
%endmacro

%define writeHex       int 0x60
%define writeString    int 0x61
%define writeCharacter int 0x62

%macro writeNewLine 0
  mov al,10
  int 0x62
%endmacro
