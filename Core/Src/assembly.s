/*
 * assembly.s
 *
 */
 
 @ DO NOT EDIT
	.syntax unified
    .text
    .global ASM_Main
    .thumb_func

@ DO NOT EDIT
vectors:
	.word 0x20002000
	.word ASM_Main + 1

@ DO NOT EDIT label ASM_Main
ASM_Main:

	@ Some code is given below for you to start with
	LDR R0, RCC_BASE  		@ Enable clock for GPIOA and B by setting bit 17 and 18 in RCC_AHBENR
	LDR R1, [R0, #0x14]
	LDR R2, AHBENR_GPIOAB	@ AHBENR_GPIOAB is defined under LITERALS at the end of the code
	ORRS R1, R1, R2
	STR R1, [R0, #0x14]

	LDR R0, GPIOA_BASE		@ Enable pull-up resistors for pushbuttons
	MOVS R1, #0b01010101
	STR R1, [R0, #0x0C]
	LDR R1, GPIOB_BASE  	@ Set pins connected to LEDs to outputs
	LDR R2, MODER_OUTPUT
	STR R2, [R1, #0]
	MOVS R2, #0         	@ NOTE: R2 will be dedicated to holding the value on the LEDs

	MOVS R3, #1				@default increment = 1

@ TODO: Add code, labels and logic for button checks and LED patterns

main_loop:
	@Read switch states
	LDR R4, GPIOA_BASE
	LDR R5, [R4, #0x10]		@r5 = idr value (input pins)

	@copy input state (PA0,..PA3)
	MOV R6, R5

	@reset and increment to default -> 1
	MOVS R3, #1

	@if SW0 is pressed -> increment by 2 while pressed
	MOVS R0, #1			@mask 0b0001
	ANDS R0, R6, R0		@R0 = (inputs & 0x01)
	CMP R0, #0
	BNE check_sw1		@if not pressed -> skip
	MOVS R3, #2			@increment by 2

check_sw1:
	@ while sw1 is pressed -> time should change every 0.3s
	LDR R7, LONG_DELAY_CNT	@default long delay (0.7s)
	MOVS R0, #2				@mask 0b0010
	ANDS R0, R6, R0
	CMP R0, #0
	BNE check_sw2			@if not pressed -> keep long delay
	LDR R7, SHORT_DELAY_CNT	@if sw1 pressed -> short delay (0.3s)

check_sw2:
	@ while sw2 is pressed -> force 0xAA (170)
	MOVS R0, #4				@mask 0b0100
	ANDS R0, R6, R0
	CMP R0, #0
	BNE check_sw3			@if not pressed -> continue
	MOVS R2, #0xAA			@if pressed -> force pattern 0xAA (170)
	B write_leds

check_sw3:
	@while sw3 is pressed -> freeze
	MOVS R0, #8				@mask 0b1000
	ANDS R0, R6, R0
	CMP R0, #0
	BNE do_increment		@if not pressed -> do increment
	B delay_loop			@if pressed -> freeze

do_increment:
	ADDS R2, R2, R3		@R2 += increment
	UXTB R2, R2 		@keep to 8 bits

write_leds:
	STR R2, [R1, #0x14]	@write to GPIO_ODR (offset 0x14)

@simple software delay using r7 and r0 as loop counter
delay_loop:
	MOV R0, R7
delay_dec:
	SUBS R0, R0, #1
	BNE delay_dec

	B main_loop

@ LITERALS; DO NOT EDIT
	.align
RCC_BASE: 			.word 0x40021000
AHBENR_GPIOAB: 		.word 0b1100000000000000000
GPIOA_BASE:  		.word 0x48000000
GPIOB_BASE:  		.word 0x48000400
MODER_OUTPUT: 		.word 0x5555

@ TODO: Add your own values for these delays
LONG_DELAY_CNT: 	.word 1400000	@ 0.7s
SHORT_DELAY_CNT: 	.word 600000	@ 0.3s