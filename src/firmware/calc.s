;
; start of firmware
;
	.org 0x1000

	.include "defs.s"

;
; start / entry point
;

start:
	; do some post reset/power on stuff

	jsr clear

;
; main loop
;

loop:
	jsr ready_status
	jsr refresh_display
	jsr scan_keypad
	jsr handle_keypress

	; jsr clear
	jmp loop

; end of loop

	.include "key_handlers.s"

; insert the digit in A into DIGITS at the ones positio
insert_digit:
	ldx INPUT_LEN
	cpx #8
	bcc .insert_ok
	rts

.insert_ok:				; move current digits one pos up
	pha					; push digit to insert on stack
	dex

.insert_loop:
	lda DIGITS, x		; grab the source value
	sta DIGITS+1, x		; set the value at the target
	dex
	bpl .insert_loop

	pla
	sta DIGITS			; set the new ones value
	inc INPUT_LEN		; increment the count of characters so far
	rts

; status LEDs
; set the led to red (busy) or green (ready)

ready_status:
	lda LEDS
	and #NOT_BSY_LED
	ora #RDY_LED
	sta LEDS
	sta LED_LATCH
	rts

busy_status:
	lda LEDS
	and #NOT_RDY_LED
	ora #BSY_LED
	sta LEDS
	sta LED_LATCH
	rts

error_status:
	lda LEDS
	ora #ERR_LED
	sta LEDS
	sta LED_LATCH
	rts

noerror_status:
	lda LEDS
	and #NOT_ERR_LED
	sta LEDS
	sta LED_LATCH
	rts

neg_status:
	lda LEDS
	ora NEG_LED
	sta LEDS
	sta LED_LATCH
	rts

pos_status:
	lda LEDS
	and NOT_NEG_LED
	sta LEDS
	sta LED_LATCH
	rts

;
; clear
; (clear key, power-on or reset)
;

clear:
	lda #0
	sta INPUT_LEN			; no input yet
	sta DISPLAY_REFRESH		; start refreshing on display 0
	sta LEDS				; turn off all LED states
	sta LED_LATCH

	; clear the digits
	lda #BLANK
	ldx #7

.cleardigit:
	sta DIGITS, x
	dex
	bpl .cleardigit
	rts

;
; refresh a display
; display number in DISPLAY_REFRESH
; advances DISPLAY_REFRESH
;

refresh_display:
	; grab the display number to refresh (0-7)
	lda DISPLAY_REFRESH

	; we'll use this for an index too
	tax

	; move the digit index into the top 3 bits
	asl
	asl
	asl
	asl
	asl

	; put adjusted index aside
	sta TMPB

	; grab the digit value, keep lower nibble (BCD)
	lda DIGITS, x
	and #0x0f

	; put the shifted display index back on there
	ora TMPB

	; todo: decimal place is the first bit of upper nibble

	; show it on the display
	sta DISPLAY_LATCH

	inc DISPLAY_REFRESH
	lda DISPLAY_REFRESH
	and #0b00000111
	sta DISPLAY_REFRESH

	rts

;
; scan the keypad
;

scan_keypad:
	; scan all the columns, store them in memory, debounce
	rts

;
; figure out which key is newly pressed
;

handle_keypress:
	rts

;
; irq handler
;

handle_irq:
    pla             ; pull saved status
    pha             ; put it back for RTI later
    and #0x10       ; B flag set?
    bne handle_brk

    rti             ; real IRQ, currently ignored

;
; brk handler
;

handle_brk:
    pla             ; discard saved status
    pla             ; discard return low
    pla             ; discard return high

    ; show error / reset calculator state
    jmp error_handler

;
; error handler (brk)
;

error_handler:
; stub
; reset calculator state, set error flag
	jmp error_handler;

;
; reset handler
;

handle_rst:
	; enable interrupts
    sei

	; turn off decimal mode
    cld

	; the 6502's reset puts the sp at 0xfd. move it up to the top
	pla
	pla

	jmp	start

;
; nmi handler
;

handle_nmi:
	rti

;
; floating point routines
;

	.include "wozfp.s"

; die - development routine to create non-moving stop location for emulator

	.org 0x1ff7

die:
	jmp die

;
; vectors
;

	.org	0x1ffa

vec_nmi:	.word	handle_nmi
vec_rst:	.word	handle_rst
vec_irq:	.word	handle_irq

