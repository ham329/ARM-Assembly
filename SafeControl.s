@ aaron habana
@ comp 122
@ 5/5/2017
@ safe.s


.equ SWI_SETSEG8, 0x200 
.equ SWI_SETLED, 0x201 
.equ SWI_CheckBlackButton, 0x202 
.equ SWI_CheckBlueButton, 0x203 
.equ SWI_DISPLAY_STRING, 0x204  @display a string on LCD
.equ SWI_DISPLAY_INT, 0x205  @display an int on LCD
.equ SWI_CLEAR_DISPLAY,0x206 @reset lcd
.equ SWI_DISPLAY_CHAR, 0x207 @display a char on LCD
.equ SWI_CLEAR_LINE, 0x208 @ clear line
.equ SWI_Exit, 0x11 @ exit

.equ LEFT_LED, 0x02 @bit patterns for LED lights
.equ RIGHT_LED, 0x01
.equ BLACK_BUTTON,0x02 @bit patterns for black buttons
.equ BLUE_BUTTON,0x01 @and for blue buttons

.equ SEG_A,0x80
.equ SEG_B,0x40
.equ SEG_C,0x20
.equ SEG_D,0x08
.equ SEG_E,0x04
.equ SEG_F,0x02
.equ SEG_G,0x01
.equ SEG_P,0x10


.equ is_Locked,0x00002040     @ 0x00 unlocked, 0x01 locked
.equ PINCOUNT,0x00002044        @ counts length of pin

@ for pin
.equ PIN,0x00002048           

@ write to LCD
mov r0,#0 @ column
mov r1,#0 @ row
ldr r2,=SetPinMsg1 @ pointer to string
swi SWI_DISPLAY_STRING @ display to the LCD screen
mov r0,#0
mov r1,#1
ldr r2,=SetPinMsg2
swi SWI_DISPLAY_STRING
mov r0,#0
mov r1,#2
ldr r2,=SetPinMsg3
swi SWI_DISPLAY_STRING
mov r0,#2
mov r1,#3
ldr r2,=SetPinMsg4
swi SWI_DISPLAY_STRING

@ initial state: unlocked
mov r0,#0x00
bl set_unlocked

@ initialize pin counter
mov r0,#0x00
ldr r1,=PINCOUNT
str r0,[r1]

@ initialize pin code to start
mov r0,#0x00
ldr r1,=PIN
str r0,[r1]


loop:

loop_blackbuttons:
   @ Black buttons
   swi SWI_CheckBlackButton 
   
loop_blackbuttons_left:
   @ Left Black Button check  
   cmp r0,#BLACK_BUTTON
   bne loop_blackbuttons_left_end
      bl lockstate
      cmp r1,#0x00
      bne unlocksafe
      bl pinhit_reset      @ Reset PINCOUNTER
      beq locksafe
loop_blackbuttons_left_end:

loop_blackbuttons_right:
   @ Right Black Button check
   cmp r0,#BLUE_BUTTON
   bne loop_blackbuttons_end
      bl pinhit_reset      @ Reset PIN HIT counter
      @ If no PIN stored, test, otherwise, Forget 
      bl get_pin_length
      cmp r1,#0x00
      beq test
      bne forget
loop_blackbuttons_end:

loop_bluebuttons:
   bl lockstate
   cmp r1,#0x01
   beq match

loop_end:   
   @ Infinite loop loop
   b loop
   
match:
   @ Check blue buttons
   swi SWI_CheckBlueButton
   mov r9,#0x00
   
match_skipswi:
   cmp r0,#0x00
   beq match_end
   add r9,r9,#0x01   
   mov r8,r0   @ Store the input code for later use
   
   @ Checking the PIN code on the fly
   @ Get hit counter to r2
   ldr r1,=PINCOUNT
   ldr r2,[r1]
   @ Get PIN length to r3
   ldr r1,=PIN
   ldr r3,[r1]
   
   @ Check overflow
   cmp r2,r3
   bge match_fail
   
   @ Get PIN code from the array to r4
   mov r4, r2,LSL #2 
   add r4,r4,#0x04      
   add r1,r1,r4      
   ldr r4,[r1]       
   
   @ Comparison
   cmp r8,r4
   bne match_fail
   
   @ If matches, increment hit counter
   add r2,r2,#0x01
   ldr r1,=PINCOUNT
   str r2,[r1]
   
   @ if pinmatch is true, blackbutton will unlock the safe 
   b match_end
   
match_fail:
   @ Reset hit counter
   bl pinhit_reset
   
   @ Do one more iteration with the same input
   cmp r9,#0x02
   bge match_end
   mov r0, r8
   b match_skipswi   
   
match_end:
   b loop

@ LOCK
locksafe:
   @ check PIN length
   bl get_pin_length
   cmp r1,#0x00
   beq locksafefailed   @ no PIN code stored, safe cannot be locked
   
   @ lock safe if there is a stored PIN
   bl set_locked
   b loop
   
locksafefailed:
   bl seg8_STATE
   b loop
   
@ UNLOCKSAFE
unlocksafe:
   @ Get PIN length to r3
   bl get_pin_length
   mov r3,r1
   @ Get hit count to r2
   ldr r1,=PINCOUNT
   ldr r2,[r1]
   
   @ Unlock the safe if PIN matches
   cmp r2,r3
   bne unlocksafe_end
   
   @ Unlock the safe
   bl set_unlocked

unlocksafe_end:
   @ Reset hit counter
   ldr r1,=PINCOUNT
   mov r2,#0x00
   str r2,[r1]
   b loop

@ PINHIT_RESET 
pinhit_reset:
   @ Reset hit counter
   ldr r1,=PINCOUNT
   mov r2,#0x00
   str r2,[r1]
   mov pc,lr

lockstate:
   ldr r2,=is_Locked
   ldr r1,[r2] 
   mov pc,lr      @ return

get_pin_length:
   ldr r2,=PIN
   ldr r1,[r2] 
   mov pc,lr      @ return


@ SET_UNLOCKED
set_unlocked:
   @ set state 
   mov r0,#0x00
   ldr r1,=is_Locked
   str r0,[r1]
   @ display
   ldr r0,=SEG_G|SEG_E|SEG_D|SEG_C|SEG_B
   swi SWI_SETSEG8
   mov r0,#RIGHT_LED
   swi SWI_SETLED
   mov pc,lr      @ return

   
@ SET_LOCKED
set_locked:
   
   @ set state 
   mov r0,#0x01
   ldr r1,=is_Locked
   str r0,[r1]
   
   @ display
   ldr r0,=SEG_G|SEG_E|SEG_D
   swi SWI_SETSEG8
   mov r0,#LEFT_LED
   swi SWI_SETLED
   mov pc,lr      @ return


   @ init
   mov r2,#0x00      @ memory address offset
   mov r3,#0x00      @ counter
   
readpinloop:
   swi SWI_CheckBlackButton

   cmp r0,#BLUE_BUTTON
   beq readpinend
   
   cmp r0,#BLACK_BUTTON
   beq locksafe
   
   @ read one number
   swi SWI_CheckBlueButton
   cmp r0,#0x00
   beq readpinloop
   
   @ store number
   add r2, r2, #4      
   str r0,[r1,r2]    
   add r3, r3, #1       
   b readpinloop

readpinend: 
   str r3,[r1]    @ store r3 in the memory 
   mov pc,lr      @ return
   

checkpin:
   @ initialization  
   mov r3,#0x00      
   mov r4,#0x00      
   mov r5,#0x00      
   mov r2,#0x01      
   ldr r6,[r1]       
   add r1,r1,#0x04      
   
checkpinloop:
   @ black buttons
   swi SWI_CheckBlackButton
   @ BLUE Button
   cmp r0,#BLUE_BUTTON
   beq checkpinstop
   @ Left BUtton
   cmp r7, #0x00
   beq checkpinloop_leftbuttonend
   cmp r0,#BLACK_BUTTON
   beq locksafe
   checkpinloop_leftbuttonend:

   @ read one number
   swi SWI_CheckBlueButton
   cmp r0,#0x00
   beq checkpinloop
   add r4, r4, #1       @ PIN counter
   
   cmp r4,r6
   bge checkpinloop
   
   @ skip comparison after fail
   cmp r2,#0x00
   beq checkpinloop
   
   @ read PIN part from memory
   ldr r5,[r1,r3]    
   add r3, r3, #4      
      
   @ compare PIN numbers
   cmp r0,r5
   beq checkpinloop  @ if match, jump back
   mov r2,#0x00      
   
   b checkpinloop
   
checkpinstop:
   @ Check if the user entered the min length of code
   cmp r6,r4
   beq checkpinend      @ true
   mov r2,#0x00      @ false
   
checkpinend:
   mov pc,lr      @ return
   

@ EXIT
exit:
   swi SWI_Exit
   
SetPinMsg1: .asciz "Press Right Black Button to Set up PIN"
SetPinMsg2: .asciz "Press Left Button to Lock"
SetPinMsg3: .asciz "Can't lock until PIN is setup"
SetPinMsg4: .asciz "MINIMUM LENGTH OF PIN: 4"