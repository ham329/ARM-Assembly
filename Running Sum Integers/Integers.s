

@@@ OPEN INPUT FILE, READ INTEGER FROM FILE, PRINT RUNNING SUM, CLOSE INPUT FILE
    .equ SWI_Open, 0x66         @ open a file
    .equ SWI_Close, 0x68        @ close a file
    .equ SWI_PrChr, 0x00        @ write an ascii char to Stdout
    .equ SWI_PrStr, 0x69        @ write a null-ending string
    .equ SWI_PrInt, 0x6b        @ write an integer
    .equ SWI_RdInt, 0x6c        @ read an integer from a file
    .equ Stdout, 1              @ set output target to be stdout
    .equ SWI_Exit, 0x11         @ stop execution
    .global _start
    .text
_start:
@ print initial message
    mov R0, #Stdout             @ print an initial message
    ldr R1, =Message1           @ load address of Message1 label
    swi SWI_PrStr               @ display message to Stdout

@ Open an input file for reading
    ldr r0, =InFileName         @ name of input file
    mov r1, #0                  @ mode is input
    mov r4, #0                  @ -----for adding integers
    swi SWI_Open                @ open file for input
    bcs InFileError             @ Check Carry-Bit (C): if= 1 then ERROR

@ Save file handle in memory
    ldr r1, =InputFileHandle
    str r0, [r1]                @ save the file handle

@ ========== Read Integers until end of file ========
RLoop:
    ldr r0, =InputFileHandle    @ load input file handle
    ldr r0, [r0]                @ ---
    add r4, r4, r0              @ ---
    swi SWI_RdInt               @ read the integer into R0
    bcs EOR                     @ check carry-bit
@ print the integer to Stdout
    mov r1,r0                  @ R1 = integer to print
    mov r0, #Stdout             @ target is Stdout
    swi SWI_PrInt               
    mov r0, #Stdout             @ print new line
    ldr r1, =NL                
    swi SWI_PrStr
    bal RLoop                  @ keep reading till end of file

    
@ ========== End of File ============
EOR:
    mov r0, #Stdout             @ print last message
    ldr r1, =EndOfFileMsg
    swi SWI_PrStr
    
    mov r0, #Stdout
    ldr r1, =TOTAL
    swi SWI_PrStr

    mov r0, #Stdout
    mov r4, r0
    swi SWI_PrInt

@ ========== CLOSE FILE ============
    ldr R0, =InputFileHandle    @ get address of file handle
    ldr r0, [R0]                @ get value at address
    swi SWI_Close
Exit:
    swi SWI_Exit                @ stop executing
InFileError:
    mov r0, #Stdout
    ldr R1, =FileErrMsg         
    swi SWI_PrStr   
    bal Exit                    @ exit
    .data
    .align

InputFileHandle:    .skip       4
Message1:           .asciz      "Hello World\n"
InFileName:         .asciz      "numbers.txt"
EndOfFileMsg:       .asciz      "End Of File Reached\n"
FileErrMsg:         .asciz      "Failed to open input file \n"
ColonSpace:         .asciz      ": "
NL:                 .asciz      " \n"
TOTAL:              .asciz      "The sum is: "
    .end

