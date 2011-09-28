; simple TLS PE
; displays twice under XP, once under W7

; Ange Albertini, BSD LICENCE 2009-2011

%include '..\consts.inc'
%define iround(n, r) (((n + (r - 1)) / r) * r)

IMAGEBASE equ 400000h
org IMAGEBASE
bits 32

SECTIONALIGN equ 1000h
FILEALIGN equ 200h

istruc IMAGE_DOS_HEADER
    at IMAGE_DOS_HEADER.e_magic, db 'MZ'
    at IMAGE_DOS_HEADER.e_lfanew, dd NT_Signature - IMAGEBASE
iend

NT_Signature:
istruc IMAGE_NT_HEADERS
    at IMAGE_NT_HEADERS.Signature, db 'PE', 0, 0
iend
istruc IMAGE_FILE_HEADER
    at IMAGE_FILE_HEADER.Machine,               dw IMAGE_FILE_MACHINE_I386
    at IMAGE_FILE_HEADER.NumberOfSections,      dw NUMBEROFSECTIONS
    at IMAGE_FILE_HEADER.SizeOfOptionalHeader,  dw SIZEOFOPTIONALHEADER
    at IMAGE_FILE_HEADER.Characteristics,       dw IMAGE_FILE_EXECUTABLE_IMAGE | IMAGE_FILE_32BIT_MACHINE
iend

OptionalHeader:
istruc IMAGE_OPTIONAL_HEADER32
    at IMAGE_OPTIONAL_HEADER32.Magic,                     dw IMAGE_NT_OPTIONAL_HDR32_MAGIC
    at IMAGE_OPTIONAL_HEADER32.AddressOfEntryPoint,       dd VDELTA + EntryPoint - IMAGEBASE
    at IMAGE_OPTIONAL_HEADER32.ImageBase,                 dd IMAGEBASE
    at IMAGE_OPTIONAL_HEADER32.SectionAlignment,          dd SECTIONALIGN
    at IMAGE_OPTIONAL_HEADER32.FileAlignment,             dd FILEALIGN
    at IMAGE_OPTIONAL_HEADER32.MajorSubsystemVersion,     dw 4
    at IMAGE_OPTIONAL_HEADER32.SizeOfImage,               dd VDELTA + SIZEOFIMAGE
    at IMAGE_OPTIONAL_HEADER32.SizeOfHeaders,             dd SIZEOFHEADERS
    at IMAGE_OPTIONAL_HEADER32.Subsystem,                 dw IMAGE_SUBSYSTEM_WINDOWS_CUI
    at IMAGE_OPTIONAL_HEADER32.NumberOfRvaAndSizes,       dd 16
iend

DataDirectory:
istruc IMAGE_DATA_DIRECTORY_16
    at IMAGE_DATA_DIRECTORY_16.ImportsVA,   dd VDELTA + Import_Descriptor - IMAGEBASE
    at IMAGE_DATA_DIRECTORY_16.TLSVA,       dd VDELTA + Image_Tls_Directory32 - IMAGEBASE
iend

SIZEOFOPTIONALHEADER equ $ - OptionalHeader
SectionHeader:
istruc IMAGE_SECTION_HEADER
    at IMAGE_SECTION_HEADER.VirtualSize,      dd Section0Size
    at IMAGE_SECTION_HEADER.VirtualAddress,   dd VDELTA + Section0Start - IMAGEBASE
    at IMAGE_SECTION_HEADER.SizeOfRawData,    dd iround(Section0Size, FILEALIGN)
    at IMAGE_SECTION_HEADER.PointerToRawData, dd Section0Start - IMAGEBASE
    at IMAGE_SECTION_HEADER.Characteristics,  dd IMAGE_SCN_MEM_EXECUTE + IMAGE_SCN_MEM_WRITE
iend
NUMBEROFSECTIONS equ ($ - SectionHeader) / IMAGE_SECTION_HEADER_size

ALIGN FILEALIGN, db 0

SIZEOFHEADERS equ $ - IMAGEBASE

Section0Start:
VDELTA equ SECTIONALIGN - ($ - IMAGEBASE) ; VIRTUAL DELTA between this sections offset and virtual addresses

EntryPoint:
    mov dword [VDELTA + TLSMsg], VDELTA + TLSEnd
    push VDELTA + Exitproc
    call printf
    add esp, 1 * 4
    push 0
    call [VDELTA + __imp__ExitProcess]
_c

tls:
    push dword [VDELTA + TLSMsg]
    call printf
    add esp, 1 * 4
    retn
_c

printf:
    jmp [VDELTA + __imp__printf]
_c

TLSMsg dd VDELTA + TLSstart
TLSstart db " * PE with simple TLS: 1st TLS call", 0
TLSEnd db " - 2nd TLS call", 0ah, 0
Exitproc db " - EntryPoint executed - ExitProcess called",  0

_d

Import_Descriptor:
kernel32.dll_DESCRIPTOR:
    dd VDELTA + kernel32.dll_hintnames - IMAGEBASE
    dd 0, 0
    dd VDELTA + kernel32.dll - IMAGEBASE
    dd VDELTA + kernel32.dll_iat - IMAGEBASE
msvcrt.dll_DESCRIPTOR:
    dd VDELTA + msvcrt.dll_hintnames - IMAGEBASE
    dd 0, 0
    dd VDELTA + msvcrt.dll - IMAGEBASE
    dd VDELTA + msvcrt.dll_iat - IMAGEBASE
;terminator
    dd 0, 0, 0, 0, 0
_d

kernel32.dll_hintnames:
    DD VDELTA + hnExitProcess - IMAGEBASE
    DD 0
msvcrt.dll_hintnames:
    dd VDELTA + hnprintf - IMAGEBASE
    dd 0
_d

hnExitProcess:
    dw 0
    db 'ExitProcess', 0
hnprintf:
    dw 0
    db 'printf', 0
_d

kernel32.dll_iat:
__imp__ExitProcess:
    DD VDELTA + hnExitProcess - IMAGEBASE
    DD 0

msvcrt.dll_iat:
__imp__printf:
    DD VDELTA + hnprintf - IMAGEBASE
    DD 0
_d

kernel32.dll  DB 'kernel32.dll', 0
msvcrt.dll  DB 'msvcrt.dll', 0
_d

Image_Tls_Directory32:
    StartAddressOfRawData dd VDELTA + some_values
    EndAddressOfRawData   dd VDELTA + some_values + 4
    AddressOfIndex        dd VDELTA + some_values + 8
    AddressOfCallBacks    dd VDELTA + CallBacks
    SizeOfZeroFill        dd VDELTA + some_values + 0ch
    Characteristics       dd 0
_d

some_values dd 0, 0, 0, 0
CallBacks:
    dd VDELTA + tls
    dd 0
_d

align FILEALIGN, db 0

Section0Size EQU $ - Section0Start

SIZEOFIMAGE EQU $ - IMAGEBASE