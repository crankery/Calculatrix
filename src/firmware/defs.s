
	.equ ZP_PTR, 0x00
	.equ RAM_PTR, 0x0200

.macro zp_alloc name,size
	.equ \name, ZP_PTR
	.equ ZP_PTR, ZP_PTR + \size
.endm

.macro alloc name,size
	.equ \name, RAM_PTR
	.equ RAM_PTR, RAM_PTR + \size
.endm

;
; calc variables
;

	zp_alloc DIGITS, 8
	zp_alloc LEDS, 1
	zp_alloc KEY_STATE, 8
	zp_alloc INPUT_LEN, 1   					; 0-8 digits entered
	zp_alloc DECIMAL_POS, 1   					; 0xFF = none, otherwise position
	zp_alloc DISPLAY_REFRESH, 1					; index of the display that will be refreshed next cycle
	
	zp_alloc TMPB, 1							; temporary byte

;
; wozfp variables
;

	zp_alloc SIGN, 1
	zp_alloc X2, 1								; exponent 2, 1 byte
	zp_alloc M2, 3								; mantissa 2, 3 bytes
	zp_alloc X1, 1								; exponent 1, 1 byte
	zp_alloc M1, 3								; mantissa 1, 3 bytes
	zp_alloc E, 4
	zp_alloc Z, 4
	zp_alloc T, 4
	zp_alloc SEXP, 4
	zp_alloc INT, 1


;
; constants
;

	; dislay constants
	.equ BLANK, 0x0f						; 74LS247 will display blank for F, use this for software blanking

	.equ BSY_LED, 0x01						; busy is Q0, red side of bicolor led
	.equ RDY_LED, 0x02						; ready is Q1, green side of bicolor led
	.equ ERR_LED, 0x04						; error is Q2
	.equ NEG_LED, 0x80						; negative is Q7
	.equ NOT_BSY_LED, BSY_LED ^ 0xff		; busy is Q0, red side of bicolor led
	.equ NOT_RDY_LED, RDY_LED ^ 0xff		; ready is Q1, green side of bicolor led
	.equ NOT_ERR_LED, ERR_LED ^ 0xff		; error is Q2
	.equ NOT_NEG_LED, NEG_LED ^ 0xff		; negative is Q7

	; hardware
	.equ DISPLAY_LATCH, 0x0800
	.equ LED_LATCH, 0x0801
	.equ KEY_LATCH, 0x0802
	.equ KEY_BUFFER, 0x0803

;
; fail assembly if we overflow the zp
;

.if ZP_PTR > 0xff
.fail "zero page overflow"
.endif

.if RAM_PTR > 0x0800
.fail "memory overlow"
.endif
