OPTION EXPLICIT

' Configurazione I/O

' Tastiera righe
SETPIN GP9,  DOUT
SETPIN GP10, DOUT
SETPIN GP11, DOUT
SETPIN GP12, DOUT
SETPIN GP13, DOUT

' Tastiera colonne
SETPIN GP14, DIN, PULLUP
SETPIN GP15, DIN, PULLUP
SETPIN GP16, DIN, PULLUP
SETPIN GP17, DIN, PULLUP

' Encoder
SETPIN GP18, DIN, PULLUP
SETPIN GP19, DIN, PULLUP

' Range selector
SETPIN GP20, DOUT   ' ADC range
SETPIN GP21, DOUT   ' DAC range

' 1-Wire (plreimposta)
SETPIN GP22, DIN

' Ventola PWM
SETPIN GP23, PWM
PWM GP23, 25000, 0

' ADC
SETPIN GP26, AIN

' UART RS232
OPEN "COM1:115200,8,N,1" AS #1

'Variabili 

DIM keyState(4,3)
DIM lastKeyState(4,3)

DIM lastADCtime = 0
DIM interval = 500

DIM encLastA = PIN(GP18)
DIM cmd$
DIM fanValue = 0

' Porta righe HIGH
PIN(GP9)=1 : PIN(GP10)=1 : PIN(GP11)=1
PIN(GP12)=1: PIN(GP13)=1

'Main loop

DO

    ' ----- SCANSIONE TASTIERA -----
    FOR r = 0 TO 4

        PIN(GP9)=1 : PIN(GP10)=1 : PIN(GP11)=1
        PIN(GP12)=1: PIN(GP13)=1

        PIN(GP9 + r) = 0

        FOR c = 0 TO 3

            keyState(r,c) = NOT PIN(GP14 + c)

            IF keyState(r,c) <> lastKeyState(r,c) THEN
                keyNum = r*4 + c + 1

                IF keyState(r,c) = 1 THEN
                    PRINT "K" + STR$(keyNum) + " ON"
                    PRINT #1, "K" + STR$(keyNum) + " ON"
                ELSE
                    PRINT "K" + STR$(keyNum) + " OFF"
                    PRINT #1, "K" + STR$(keyNum) + " OFF"
                ENDIF

                lastKeyState(r,c) = keyState(r,c)
            ENDIF

        NEXT c
    NEXT r

    ' ----- ENCODER -----
    encA = PIN(GP18)
    IF encA <> encLastA THEN
        IF PIN(GP19) <> encA THEN
            PRINT "R"
            PRINT #1, "R"
        ELSE
            PRINT "L"
            PRINT #1, "L"
        ENDIF
        encLastA = encA
    ENDIF

    ' ----- SERIAL USB -----
    IF LOC(0) > 0 THEN
        LINE INPUT cmd$
        cmd$ = UCASE$(cmd$)
        GOSUB HandleCommand
    ENDIF

    ' ----- SERIAL RS232 -----
    IF LOC(#1) > 0 THEN
        LINE INPUT #1, cmd$
        cmd$ = UCASE$(cmd$)
        GOSUB HandleCommand
    ENDIF

    ' ----- ADC + TEMP out  ogni 500ms 
    IF TIMER - lastADCtime >= interval THEN
        lastADCtime = TIMER

        adcVal = PIN(GP26)
        PRINT "I," + STR$(adcVal)
        PRINT #1, "I," + STR$(adcVal)

        tempVal = 0   ' qui andrà la lettura reale DS18B20
        PRINT "T," + STR$(tempVal)
        PRINT #1, "T," + STR$(tempVal)
    ENDIF

LOOP

' Comandi polling in ingresso

HandleCommand:

IF cmd$ = "ADC0" THEN PIN(GP20)=0
IF cmd$ = "ADC1" THEN PIN(GP20)=1

IF cmd$ = "DAC0" THEN PIN(GP21)=0
IF cmd$ = "DAC1" THEN PIN(GP21)=1

IF LEFT$(cmd$,4) = "FAN," THEN
    fanValue = VAL(MID$(cmd$,5))
    IF fanValue < 0 THEN fanValue = 0
    IF fanValue > 255 THEN fanValue = 255
    PWM GP23, 25000, fanValue/255*100
ENDIF

RETURN