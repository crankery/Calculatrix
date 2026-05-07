

test_add:
    ; X2/M2 = float(1)
    lda #0x00
    sta M1
    lda #0x01
    sta M1+1
    jsr FLOAT

    lda X1
    sta X2
    lda M1
    sta M2
    lda M1+1
    sta M2+1
    lda M1+2
    sta M2+2

    ; X1/M1 = float(1)
    lda #0x00
    sta M1
    lda #0x02
    sta M1+1
    jsr FLOAT

    ; X1 = X1 + X2
    jsr FADD  