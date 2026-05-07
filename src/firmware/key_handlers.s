;
; digit key handlers
;

handle_0:
    lda #0x00
    jmp insert_digit

handle_1:
    lda #0x01
    jmp insert_digit

handle_2:
    lda #0x02
    jmp insert_digit

handle_3:
    lda #0x03
    jmp insert_digit

handle_4:
    lda #0x04
    jmp insert_digit

handle_5:
    lda #0x05
    jmp insert_digit

handle_6:
    lda #0x06
    jmp insert_digit

handle_7:
    lda #0x07
    jmp insert_digit

handle_8:
    lda #0x08
    jmp insert_digit

handle_9:
    lda #0x09
    jmp insert_digit