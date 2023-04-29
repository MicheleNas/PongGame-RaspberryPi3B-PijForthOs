HEX

\ ------------------------------------------- RENDERING RECT ---------------------------------------------- \

00FFFFFF CONSTANT WHITE
00000000 CONSTANT BLACK

\ Base Address del Framebuffer
0E8FA000 CONSTANT FRAMEBUFFER

\ Dati in input le coordinate dello schermo (x y) restituisce l'indirizzo del framebuffer corrispondente
\ ( coordinateSchermo -- indirizzoFB )
: XY_FB 400 * + 4 * FRAMEBUFFER + ;

\ Definizioni di variabili che conterranno gli indirizzi necessari per disegnare su schermo
\ DRAW_START_ADDR: contiene l'indirizzo di partenza, ovvero quello corrispondente alle coordinate x y
\ DRAW_FINAL_HORIZONTAL_ADDR: contiene l'indirizzo che indica la fine lungo l'asse orizzontale
\ DRAW_FINAL_VERTICAL_ADDR: contiene l'indirizzo che indica la fine lungo l'asse verticale
VARIABLE DRAW_START_ADDR
VARIABLE MODHOR
VARIABLE INTHOR
VARIABLE INTVER
VARIABLE COLOR
: XY_COORDINATES! XY_FB DRAW_START_ADDR ! ;   \ ( x y -- ) date le coordinate calcola l'indirizzo del FB e lo memorizza in DRAW_START_ADDR
: HORIZONTAL_LENGTH! DUP 8 / SWAP 8 MOD MODHOR ! INTHOR ! ;  \ ( distanzaOriz -- ) data la distanza orizzontale calcola la parte intera e il resto.
                                                             \ La parte intera viene calcolata in relazione al numero di valori che possono essere caricati in memoria contemporaneamente
: VERTICAL_LENGTH! INTVER ! ; \ ( distanzaVert -- ) memorizza la distanza verticale
: COLOR! COLOR ! ;

\ Opcode Assembly per Arm32; Permette di disegnare a schermo un rettangolo
\ E' necessario che i valori delle 5 variabili sopra definite siano correttamente aggiornati ogni qualvolta si vuole disegnare un rettangolo
\ Il codice assembly opera nel seguente modo: 
\           1. Prende dallo stack, tramite lo stack pointer, i valori che serviranno a individuare il punto di inzio per disegnare (DRAW_START_ADDR),
\               la parte intera della divisione per 8, che corrisponde al numero di iterazioni che dovrà fare l'istruzione Store Multiple (INTHOR), il resto 
\               della divisione che corrisponde al numero di iterazioni che dovrà effettuare l'istruzione singola di Store (MODHOR) e il numero di volte
\               che le iterazioni citate prima dovranno essere effettuate (INTVER)
\           2. Successivamente il coloro che viene riportato dalla variabile (COLOR) viene copiato in 8 registri per fare in modo che venga effettuato lo Store Multiple
\           3. A seguire si entrerà nel flusso di iterazioni che realizzeranno il rettangolo; la logica è quella di realizzare passo dopo passo le singole righe di pixel che 
\               daranno origine al rettangolo
\ ( DRAW_START_ADDR VARIABLE MODHOR INTHOR INTVER COLOR -- )
create SUB_RECT
    e49d0004 ,
    e49d1004 ,
    e49d2004 ,
    e49d3004 ,
    e49d4004 ,
    e92d1fe0 ,
    e1a05000 ,
    e1a06000 ,
    e1a07000 ,
    e1a08000 ,
    e1a09000 ,
    e1a0a000 ,
    e1a0b000 ,
    e1a0c000 ,
    e1a00001 ,
    e92d4018 ,
    eb000007 ,
    e8bd4018 ,
    e2811a01 ,
    e1a00001 ,
    e2422001 ,
    e3520000 ,
    1afffff7 ,
    e8bd1fe0 ,
    e12fff1e ,
    e3530000 ,
    0a000005 ,
    e8a01fe0 ,
    e2433001 ,
    e3530000 ,
    1afffff9 ,
    e3540000 ,
    0a000003 ,
    e4805004 ,
    e2444001 ,
    e3540000 ,
    1afffffb ,
    e12fff1e ,
does> jsr ;

\ DRAWRECT carica ordinatamente nello stack gli indirizzi necessari per l'esecuzione di SUB_RECT
\ il drop finale serve ad eliminare dalla cima dello stack il valore di ritorno della subroutine (registro r0)
: DRAWRECT  MODHOR @
            INTHOR @
            INTVER @
            DRAW_START_ADDR @
            COLOR @
            SUB_RECT
            DROP
;

\ ------------------------------------------- END RENDERING RECT ---------------------------------------------- \

\ ----------------------------------------------- PLAYING ARENA ----------------------------------------------- \

\ Dichiaro la lunghezza, larghezza e spossore linee del campo
320 CONSTANT ARENAWIDTH
258 CONSTANT ARENALENGTH
5 CONSTANT LINETHICKNESS

\ Dichiaro il punto iniziale del campo, in base ad questo e i valori definiti prima si potrà realizzare il campo da gioco
CREATE XY_START_ARENA 70 , 54 , DOES> DUP @ SWAP 1 CELLS + @ ;
: X_START_ARENA@ XY_START_ARENA DROP ;
: Y_START_ARENA@ XY_START_ARENA SWAP DROP ;

\ Definisco le delimitazioni del campo; serviranno successivamente per far rimbalzare la palla e non limitare lo spostamento delle barre
Y_START_ARENA@ LINETHICKNESS + CONSTANT LIMIT_SUP_ARENA
Y_START_ARENA@ ARENALENGTH + LINETHICKNESS - CONSTANT LIMIT_INF_ARENA
X_START_ARENA@ LINETHICKNESS + CONSTANT LIMIT_SX_ARENA
X_START_ARENA@ ARENAWIDTH + LINETHICKNESS - CONSTANT LIMIT_DX_ARENA

\ Definisco altri due punti di partenza per poter disegnare 2 dei 4 rettangoli appartenenti al campo
: XY_ARENA2 X_START_ARENA@ LIMIT_INF_ARENA ;
: XY_ARENA3 LIMIT_DX_ARENA Y_START_ARENA@ ;

\ Le linee del campo saranno realizzate mediante 4 rettangoli 
: PLAYING_ARENA 
    XY_START_ARENA XY_COORDINATES! ARENAWIDTH HORIZONTAL_LENGTH! LINETHICKNESS VERTICAL_LENGTH! WHITE COLOR! DRAWRECT
    XY_START_ARENA XY_COORDINATES! LINETHICKNESS HORIZONTAL_LENGTH! ARENALENGTH VERTICAL_LENGTH! WHITE COLOR! DRAWRECT
    XY_ARENA2 XY_COORDINATES! ARENAWIDTH HORIZONTAL_LENGTH! LINETHICKNESS VERTICAL_LENGTH! WHITE COLOR! DRAWRECT
    XY_ARENA3 XY_COORDINATES! LINETHICKNESS HORIZONTAL_LENGTH! ARENALENGTH VERTICAL_LENGTH! WHITE COLOR! DRAWRECT
;

: CLEAR_LOGOPJ 0 0 XY_COORDINATES! C8 HORIZONTAL_LENGTH! 32 VERTICAL_LENGTH! BLACK COLOR! DRAWRECT ;

\ --------------------------------------------- END PLAYING ARENA --------------------------------------------- \

\ ---------------------------------------------- DEFINIZIONI GPIO ---------------------------------------------- \

\ Indirizzo base dei registri gpio
3F000000 CONSTANT BASE

BASE 200008 + CONSTANT GPFSEL2
BASE 20001C + CONSTANT GPSET0
BASE 200040 + CONSTANT GPEDS0
BASE 200070 + CONSTANT GPLEN0

\ Imposto il gpio23 e gpio24 in input
0 GPFSEL2 !

\ Abilito il pin per la gpio 23 24 25 26
7800000 GPSET0 !

\ GPLEN ci permette di abilitare la modalità LOW ovvero quando si arriva a 0 ; in questo modo possiamo lasciare il dito 
\ sul pulsante e far muovere la barra fin quando non lo rilasciamo
7800000 GPLEN0 !


\ --------------------------------------------------- BAR --------------------------------------------------- \

1 CONSTANT DELTABAR
5A CONSTANT BARLENGTH
F CONSTANT BARWIDTH

CREATE PLAYER_1 8B , 153 , 0 ,    \ definisco il player 1 e memorizzo la posizione iniziale della barra (XY = 8B 153) e il punteggio inziale
CREATE PLAYER_2 366 , 153 , 0 ,    \ definisco il player 1 e memorizzo la posizione iniziale della barra (XY = 366 153) e il punteggio inziale

\ Definisco una serie di istruzioni che mi permetto di risalire alle informazioni degi giocatori dando come argomento l'indirizzo associato al player
: POSITION_BAR@ DUP @ SWAP 1 CELLS + @  ;   \ ( PLAYER -- XY_ADDR ); in questo modo riesco a risalire all'indirizzo della startposition di ogni player
: SCORE@ 2 CELLS + @  ;                     \ ( PLAYER -- SCORE )
: RESETSCORE 2 CELLS + 0 SWAP ! ;
: SCORE+ 1 SWAP 2 CELLS + +!  ;             \ ( PLAYER -- ) 
: Y_POSITION_BAR! SWAP 1 CELLS + ! ;        \ ( PLAYER Y -- ) LA X RIMANE COSTANTE quindi non c'è bisogno di modificarla
: Y_POSITION_BAR@ 1 CELLS + @ ;             \ ( PLAYER -- Y )

\ Istruzioni per disegnare e cancellare la barra; mi permetteranno di realizzare l'animazione del movimento della barra
: XY_DRAWBAR XY_COORDINATES! BARWIDTH HORIZONTAL_LENGTH! BARLENGTH VERTICAL_LENGTH! WHITE COLOR! DRAWRECT ; \ ( XYBAR -- )
: DELETE_BAR POSITION_BAR@ XY_COORDINATES! BARWIDTH HORIZONTAL_LENGTH! BARLENGTH VERTICAL_LENGTH! BLACK COLOR! DRAWRECT ; \ ( PLAYER -- )

\ Muove la barra in alto di DELTABAR pixel
\ ( PLAYER --  )
: MOVE_UP   DUP DELETE_BAR
            DUP DUP Y_POSITION_BAR@ DELTABAR - Y_POSITION_BAR!
            POSITION_BAR@ XY_DRAWBAR
;

\ Muove la barra in basso di DELTABAR pixel
\ ( PLAYER --  )
: MOVE_DOWN DUP DELETE_BAR
            DUP DUP Y_POSITION_BAR@ DELTABAR + Y_POSITION_BAR!
            POSITION_BAR@ XY_DRAWBAR
;

\ Definizioni di istruzioni che permetto di interagire con la barra tramite l'interfaccia GPIO

\ Le seguenti costanti corrispondono a dei specifici bit appartenenti al valore del registro GPEDS0.
\ Se il bit indicato nella posizione della costante è 1 allora vuol dire che il tasto relativo ad esso è stato premuto,
\ se è 0 non è stato premuto.
1000000 CONSTANT BUTTON1
800000  CONSTANT BUTTON2
4000000 CONSTANT BUTTON3
2000000 CONSTANT BUTTON4

\ Effettuo un bitmasking per verificare se sono stati premuti i tasti relativi al player1 o al player2
: ?BUTTONS_PLAYER1 GPEDS0 @ 1800000 AND ; 
: ?BUTTONS_PLAYER2 GPEDS0 @ 6000000 AND ;

\ Dopo che i tasti vengono premuti, anche se rilasciati, è necessario settare i corrispondenti bit a 0.
\ Le seguenti istruzioni effettuano questo compito
: RESETBUTTON1 BUTTON1 GPEDS0 ! ;
: RESETBUTTON2 BUTTON2 GPEDS0 ! ;
: RESETBUTTON3 BUTTON3 GPEDS0 ! ;
: RESETBUTTON4 BUTTON4 GPEDS0 ! ;

\ Le seguenti istruzioni verificano se con la prossima mossa la barra supera i limiti del campo da gioco
: ?MOVE_UP DUP Y_POSITION_BAR@ DELTABAR - LIMIT_SUP_ARENA > ;
: ?MOVE_DOWN DUP Y_POSITION_BAR@ BARLENGTH + DELTABAR + LIMIT_INF_ARENA < ;

\ Tramite lo switch verifico se i tasti sono stati premuti singolarmente o contemporaneamente:
\           1. Se è stato premuto il tasto up o down allora controllo se viene sforato il limite superiore del campo, 
\               se è così la barra non si muove
\           2. Se sono premuti contemporaneamente allora la barra non si muove
: MOVE_BAR1 ?BUTTONS_PLAYER1 CASE   BUTTON1 OF ?MOVE_UP IF MOVE_UP RESETBUTTON1 ELSE DROP THEN ENDOF
                                    BUTTON2 OF ?MOVE_DOWN IF MOVE_DOWN RESETBUTTON2 ELSE DROP THEN ENDOF
                                    [ BUTTON1 BUTTON2 OR ] LITERAL OF RESETBUTTON1 RESETBUTTON2 ENDOF
                            ENDCASE
;
: MOVE_BAR2 ?BUTTONS_PLAYER2 CASE   BUTTON3 OF ?MOVE_UP IF MOVE_UP RESETBUTTON3 ELSE DROP THEN ENDOF
                                    BUTTON4 OF ?MOVE_DOWN IF MOVE_DOWN RESETBUTTON4 ELSE DROP THEN ENDOF
                                    [ BUTTON3 BUTTON4 OR ] LITERAL OF RESETBUTTON3 RESETBUTTON4 ENDOF
                            ENDCASE
;

\ ------------------------------------------------- END BAR ------------------------------------------------- \

\ -------------------------------------------------- SCORE -------------------------------------------------- \
\ Per ralizzare i numeri che mi permetteranno di visualizzare il punteggio su schermo, svolgo i seguenti passaggi:
\       1. Tramite una bitmap genero un immagine completa di colore bianco che viene memorizzata in memoria.
\           L'immagine sarà composta da 7x8 quadrati di dimenzioni, un quadrato è di dimensioni 8x8 pixel.
\       2. Per stamparla a schermo utilizzero una subroutine in assembly la quale funziona in maniera analoga a quella precedente
\           ma con l'unica differenza che dovrà prelevare i valori da una zona di memoria e spostarli nella zona dedicata al FRAMEBUFFER

\ Le segunti variabili servono a definire i punti dello schermo sui quali dovranno essere disegnati i numeri corrispondenti al punteggio
CREATE XY_CANVAS1 129 , 4 , DOES> DUP @ SWAP 1 CELLS + @ ;
CREATE XY_CANVAS2 2B4 , 4 , DOES> DUP @ SWAP 1 CELLS + @ ;

\ Istruzioni che permetto di generare un immagine partendo da una bitmap 7x5
: ?WHITE/BLACK 2DUP RSHIFT 1 AND ; \ (  )

\ Genera una riga di un quadrato; quindi assegna il colore bianco o nero a 8 pixel
: WHITEX8 8 BEGIN WHITE , 1 - DUP 0 = UNTIL DROP ; \ (  )
: BLACKX8 8 BEGIN BLACK , 1 - DUP 0 = UNTIL DROP ;

\ Genera una riga dell'immagine; quindi assegna il colore bianco o nero a 5x8 pixel.
\ Per farlo chiama 5 volte, alternandole in relazione ai valori della bitmap, le istruzioni WHITEX8 e BLACKX8.
\ Ad esempio, se la prima riga della bit map è la seguente: 01110 ai pixel verranno assegnati in ordine i valori ==> Bx8 Wx8 Wx8 Wx8 Bx8
: GENERATE_ROW 4 BEGIN ?WHITE/BLACK IF WHITEX8 ELSE BLACKX8 THEN 1 - DUP -1 = UNTIL DROP ; \ (5BIT -- 5BIT )

\ Per fare in modo che la prima riga sia completa la si dovrà ripetere per otto volte in verticale:
\   riprendendo l'esempio di prima (01110) si avrà ==>  Bx8 Wx8 Wx8 Wx8 Bx8
\                                                       Bx8 Wx8 Wx8 Wx8 Bx8
\                                                               .               <-- totale 8 righe di 5x8 pixel
\                                                               .
\                                                       Bx8 Wx8 Wx8 Wx8 Bx8
: GENROWX8 8 BEGIN SWAP GENERATE_ROW SWAP 1 - DUP 0 = UNTIL DROP DROP ; \( 5BIT -- )

\ Questa istruzione usa le precedenti per realizzare l'immagine completa.
\ Prenderà in input la bitmap che sarà composta da un totale di 35 bit suddivisi in due word da 32:
\                       Word 1: la prima word conterrà i 30 bit più significativi
\                       Word 2: la seconda word conterrà i 5 bit meno significativi
: GENERATE_CHAR 19 BEGIN 2DUP RSHIFT GENROWX8 5 - DUP -5 = UNTIL DROP DROP GENROWX8 ; \ (bitmapSection1 bitmapSection2 -- )

\ Prima di generare generare l'immagine tramite la bitmap è necessario aver definito tramite CREATE una word che indica il punto
\ di partenza dell'immagine. Infatti l'immagine la si può vedere come un Array di dimensione 7x8x5x8 elementi.

\ Subroutine assembly che preleva l'immagine dalla locazione di memoria in cui è memorizzata e la copia in un determinato punto del framebuffer
CREATE SUB_CHAR  \ ( indirizzoFB indirizzoChar -- returR0 )
    e49d0004 ,
    e49d1004 ,
    e92d1fe0 ,
    e1a02001 ,
    e3a04038 ,
    e3a03005 ,
    e52de004 ,
    eb000007 ,
    e49de004 ,
    e2811a01 ,
    e1a02001 ,
    e2444001 ,
    e3540000 ,
    1afffff6 ,
    e8bd1fe0 ,
    e12fff1e ,
    e8b01fe0 ,
    e8a21fe0 ,
    e2433001 ,
    e3530000 ,
    1afffffa ,
    e12fff1e ,
DOES> JSR ;

\ Questa istruzione non fa altro che chiamare la subRoutine per stampare il carattere ed eliminare dallo stack il suo return
: DRAW_CHAR SUB_CHAR DROP ; \ ( indirizzoFB indirizzoChar --  )

\ Genero le immagini delle singole cifre: 0, 1, 2, ... , 9
CREATE 0_BITMAP 1D19D731 , E , DOES> DUP 1 CELLS + @ SWAP @ ; \ ( -- ELEM2 ELEM1 )
CREATE 0_CHAR 0_BITMAP GENERATE_CHAR

CREATE 1_BITMAP 8C21084 , E , DOES> DUP 1 CELLS + @ SWAP @ ;
CREATE 1_CHAR 1_BITMAP GENERATE_CHAR

CREATE 2_BITMAP 1D108888 , 1F , DOES> DUP 1 CELLS + @ SWAP @ ;
CREATE 2_CHAR 2_BITMAP GENERATE_CHAR

CREATE 3_BITMAP 1D109831 , E , DOES> DUP 1 CELLS + @ SWAP @ ;
CREATE 3_CHAR 3_BITMAP GENERATE_CHAR

CREATE 4_BITMAP 4654BE2 , 2 , DOES> DUP 1 CELLS + @ SWAP @ ;
CREATE 4_CHAR 4_BITMAP GENERATE_CHAR

CREATE 5_BITMAP 3F0F0431 , E , DOES> DUP 1 CELLS + @ SWAP @ ;
CREATE 5_CHAR 5_BITMAP GENERATE_CHAR

CREATE 6_BITMAP 1D187A31 , E , DOES> DUP 1 CELLS + @ SWAP @ ;
CREATE 6_CHAR 6_BITMAP GENERATE_CHAR

CREATE 7_BITMAP 3E111084 , 4 , DOES> DUP 1 CELLS + @ SWAP @ ;
CREATE 7_CHAR 7_BITMAP GENERATE_CHAR

CREATE 8_BITMAP 1D18BA31 , E , DOES> DUP 1 CELLS + @ SWAP @ ;
CREATE 8_CHAR 8_BITMAP GENERATE_CHAR

CREATE 9_BITMAP 1D18BC31 , E , DOES> DUP 1 CELLS + @ SWAP @ ;
CREATE 9_CHAR 9_BITMAP GENERATE_CHAR


: DRAW_SCORE_START XY_CANVAS1 XY_FB 0_CHAR DRAW_CHAR XY_CANVAS2 XY_FB 0_CHAR DRAW_CHAR ;

: PLAYER_1? PLAYER_1 = ;

\ Seleziono il carattere corretto da stampare in relazione ai punteggio del Player
: UPDATE_SCORE  DUP PLAYER_1? IF SCORE@ XY_CANVAS1 ROT ELSE SCORE@ XY_CANVAS2 ROT THEN \ (PLAYER -- )
                CASE    0 OF XY_FB 0_CHAR DRAW_CHAR ENDOF
                        1 OF XY_FB 1_CHAR DRAW_CHAR ENDOF
                        2 OF XY_FB 2_CHAR DRAW_CHAR ENDOF
                        3 OF XY_FB 3_CHAR DRAW_CHAR ENDOF
                        4 OF XY_FB 4_CHAR DRAW_CHAR ENDOF
                        5 OF XY_FB 5_CHAR DRAW_CHAR ENDOF
                        6 OF XY_FB 6_CHAR DRAW_CHAR ENDOF
                        7 OF XY_FB 7_CHAR DRAW_CHAR ENDOF
                        8 OF XY_FB 8_CHAR DRAW_CHAR ENDOF
                        9 OF XY_FB 9_CHAR DRAW_CHAR ENDOF
                ENDCASE
;

\ ------------------------------------------------ END SCORE ------------------------------------------------ \

\ -------------------------------------------------- BALL -------------------------------------------------- \
CREATE BALL 1F9 , 179 ,     \ Posizione palla nel campo
CREATE DX 1 ,               \ Spostamento palla lungo X
CREATE DY 0 ,               \ Spostamento palla lungo Y
CREATE ANGLE 0 ,            \ Tengo traccia dell'angolo con cui si muove la pallina rispetto all'impatto con la barra
CREATE BALL_DIRECTION 1 ,   \ Tengo traccia del verso lungo l'asse x

AF0 CONSTANT TIME_BALL
CREATE SEC_BALL TIME_BALL ,    \ VARIABILE Timer palla; inizializzo sec_ball
F CONSTANT DIMBALL          \ Dimensione della palla 15x15 pixel

\ Sono delle linee che si trovano in corrispondenza al lato più interno, rispetto al campo, delle barre.
\ Quando la palla incide uno di questi limiti allora si verifica se in quel punto si trova la barra:
\           se è presente => la palla rimbalza
\           se non è presente => la palla continua a muoversi lungo la sua direzione
9A CONSTANT X_ALERTSX
366 CONSTANT X_ALERTDX

\ Inverte il verso della palla lungo x o y
: -DX! 0 DX @ - DX ! ;
: -DY! 0 DY @ - DY ! ;

\ Inverte il verso, lungo x, della palla.
\ -BALL_DIRECTION! è fondamentale quando l'angolo di impatto con la barra è di 65 o -65 gradi
\ poichè la palla si muoverà nella seguente maniera ==> stemp1: Dx=1 Dy=1 stemp2: Dx=0 Dy=1 ; al terzo step se non ci fosse
\ la variabile BALL_DIRECTION non si saprebbe se considerare Dx=1 o Dx=-1. Ecco il motivo per il quale è fondamentale tenere 
\ traccia del verso attuale della palla lungo x.
: -BALL_DIRECTION! 0 BALL_DIRECTION @ - BALL_DIRECTION ! ;

: XY_BALL@ BALL @ BALL 1 CELLS + @ ;
: XY_BALL! BALL 1 CELLS + ! BALL ! ;
: X_BALL@ BALL @ ;
: Y_BALL@ BALL 1 CELLS + @ ;
: CENTER_BALL 1F9 179 XY_BALL! ;

\ Disegno e cancello la palla in modo da simulare il suo movimento
: DRAWBALL XY_BALL@ XY_COORDINATES! DIMBALL HORIZONTAL_LENGTH! DIMBALL VERTICAL_LENGTH! WHITE COLOR! DRAWRECT ;
: DELETE_BALL XY_BALL@ XY_COORDINATES! DIMBALL HORIZONTAL_LENGTH! DIMBALL VERTICAL_LENGTH! BLACK COLOR! DRAWRECT ;

\ Verifico se il player ha segnato; restituirà -1 o 0
: ?GOAL_PLAYER1 X_BALL@ LIMIT_DX_ARENA DIMBALL - >= ;
: ?GOAL_PLAYER2 X_BALL@ LIMIT_SX_ARENA <= ;

\ Verifico se mi trovo nell'allertZone sopra descritta; restituirà -1 o 0
: ?ALERT_ZONESX X_BALL@ X_ALERTSX <= ;
: ?ALERT_ZONEDX X_BALL@ DIMBALL + X_ALERTDX >= ;

\ Verifico se la palla sta impattando con la parete superiore o inferiore del campo; restituirà -1 o 0
: ?Y_IMPACT Y_BALL@ LIMIT_SUP_ARENA <= Y_BALL@ LIMIT_INF_ARENA DIMBALL - >= OR ;

\ Verifico che Y_ball è contenuto nei seguenti range; restituirà -1 o 0
: Y_BAR1_UP<Y_BALL<Y_BAR1_DOWN Y_BALL@ PLAYER_1 Y_POSITION_BAR@ DIMBALL - > Y_BALL@ PLAYER_1 Y_POSITION_BAR@ BARLENGTH + < AND ;
: Y_BAR2_UP<Y_BALL<Y_BAR2_DOWN Y_BALL@ PLAYER_2 Y_POSITION_BAR@ DIMBALL - > Y_BALL@ PLAYER_2 Y_POSITION_BAR@ BARLENGTH + < AND ;

\ Verifico che Y_Bal sta impattando con la parte superiore o inferiore della barra; restituirà -1 o 0
: Y_BALL==Y_BAR1_UP Y_BALL@ PLAYER_1 Y_POSITION_BAR@ DIMBALL - = ;
: Y_BALL==Y_BAR1_DOWN Y_BALL@ PLAYER_1 Y_POSITION_BAR@ BARLENGTH + = ;

: Y_BALL==Y_BAR2_UP Y_BALL@ PLAYER_2 Y_POSITION_BAR@ DIMBALL - = ;
: Y_BALL==Y_BAR2_DOWN Y_BALL@ PLAYER_2 Y_POSITION_BAR@ BARLENGTH + = ;

\ Verifico se la palla sta impattando con la barra
: ?BAR1_IMPACT Y_BAR1_UP<Y_BALL<Y_BAR1_DOWN X_BALL@ X_ALERTSX = AND ;
: ?BAR1_IMPACT_UP Y_BALL==Y_BAR1_UP ;
: ?BAR1_IMPACT_DOWN Y_BALL==Y_BAR1_DOWN ;

: ?BAR2_IMPACT Y_BAR2_UP<Y_BALL<Y_BAR2_DOWN X_BALL@ X_ALERTDX DIMBALL - = AND ;
: ?BAR2_IMPACT_UP Y_BALL==Y_BAR2_UP ;
: ?BAR2_IMPACT_DOWN Y_BALL==Y_BAR2_DOWN ;

\ ISTRUZIONI PER INDIVIDUARE L'ANGOLO DI RIFLESSIONE DELLA BARRA

\ Per poter implementare diverse angolature di rimbalzo della palla suddivido la barra in 5 range:          
\                y0.... __ ...
\                y1....|  |...
\                y2....|  |...
\                y3....|  |...
\                y4....|  |...
\                y5....|__|...
\
\ Se la palla è contenuta tra y0-y1 => 65° ; y1-y2 => 45° ; y2-y3 => 0° ; y3-y4 => -45° ; y4-y5 => -65°

\ Tengo traccia del centro della pallina. Mi servirà per individuare la porzione di impatto 
: Y_BALL_CENTER Y_BALL@ 7 + ;

\ Le seguenti istruzioni restituiscono il valore delle seguenti y
\ (PLAYER -- valYn ) 
: Y0 Y_POSITION_BAR@ 7 - ;
: Y1 Y_POSITION_BAR@ 14 + ;
: Y2 Y1 14 + ;
: Y3 Y2 A + ;
: Y4 Y3 14 + ;
: Y5 Y4 14 + ;

\ Verifico che il punto centrale della palla si trova tra uno dei range prima citati
\ (PLAYER -- BOOLEAN)
: Y0<Y_BALL_CENTER<=Y1 DUP Y0 SWAP Y1 Y_BALL_CENTER >= SWAP Y_BALL_CENTER < AND ;
: Y1<Y_BALL_CENTER<=Y2 DUP Y1 SWAP Y2 Y_BALL_CENTER >= SWAP Y_BALL_CENTER < AND ;
: Y2<Y_BALL_CENTER<=Y3 DUP Y2 SWAP Y3 Y_BALL_CENTER >= SWAP Y_BALL_CENTER < AND ;
: Y3<Y_BALL_CENTER<=Y4 DUP Y3 SWAP Y4 Y_BALL_CENTER >= SWAP Y_BALL_CENTER < AND ;
: Y4<Y_BALL_CENTER<=Y5 DUP Y4 SWAP Y5 Y_BALL_CENTER >= SWAP Y_BALL_CENTER < AND ;

\ Setto l'angolo di rimbalzo individuato
\ (PLAYER -- ) 
: SET_ANGLE DUP Y0<Y_BALL_CENTER<=Y1 IF 65 ANGLE ! THEN   \ ANGOLO DI 65
            DUP Y1<Y_BALL_CENTER<=Y2 IF 45 ANGLE ! THEN   \ ANGOLO 45
            DUP Y2<Y_BALL_CENTER<=Y3 IF 0 ANGLE ! THEN   \ ANGOLO 0
            DUP Y3<Y_BALL_CENTER<=Y4 IF -45 ANGLE ! THEN   \ ANGOLO -45
                Y4<Y_BALL_CENTER<=Y5 IF -65 ANGLE ! THEN   \ ANGOLO -65
;

\ Setto gli spostamenti opportuni che deve svolgere la palla in relazione all'angolo di spostamento
: SET65DEGREES -BALL_DIRECTION! -1 DY ! 0 DX ! ;
: SET45DEGREES -BALL_DIRECTION! -1 DY ! BALL_DIRECTION @ DX ! ;
: SET0DEGREES -BALL_DIRECTION! 0 DY ! BALL_DIRECTION @ DX ! ;
: SET-45DEGREES -BALL_DIRECTION! 1 DY ! BALL_DIRECTION @ DX ! ;
: SET-65DEGREES -BALL_DIRECTION! 1 DY ! 0 DX ! ;


\ Questa istruzione viene chiamata dopo che l'angolo di impatto è stato settato.
\ Ciò che fa è andate e settare lo spostamento della pallina opportuno
: UPDATE_DXDY ANGLE @    CASE    65 OF SET65DEGREES ENDOF
                                 45 OF SET45DEGREES ENDOF
                                  0 OF SET0DEGREES ENDOF
                                -45 OF SET-45DEGREES ENDOF
                                -65 OF SET-65DEGREES ENDOF
                        ENDCASE
;

: SETBALLSPEED ANGLE @   CASE    65 OF TIME_BALL 401 - SEC_BALL ! ENDOF
                                45 OF TIME_BALL SEC_BALL ! ENDOF
                                0 OF  TIME_BALL 401 - SEC_BALL ! ENDOF
                                -45 OF TIME_BALL SEC_BALL ! ENDOF
                                -65 OF TIME_BALL 401 - SEC_BALL ! ENDOF
                        ENDCASE ;

\ Verifico che la balla si trovi o nella zona di alert o se sta impattando con una parete del campo.
\ Se si trova nella zona di alert viene verificato se sta impattando con la barra o se si sta per segnare
: CHECK_BALL
            ?ALERT_ZONESX  IF
                ?BAR1_IMPACT_UP IF -DY! THEN
                ?BAR1_IMPACT_DOWN IF -DY! THEN
                ?BAR1_IMPACT IF PLAYER_1 SET_ANGLE UPDATE_DXDY THEN
                ?GOAL_PLAYER2 IF CENTER_BALL PLAYER_2 SCORE+ PLAYER_2 UPDATE_SCORE THEN
            THEN
            ?ALERT_ZONEDX IF
                ?BAR2_IMPACT_UP IF -DY! THEN
                ?BAR2_IMPACT_DOWN IF -DY! THEN
                ?BAR2_IMPACT IF PLAYER_2 SET_ANGLE UPDATE_DXDY THEN
                ?GOAL_PLAYER1 IF CENTER_BALL PLAYER_1 SCORE+ PLAYER_1 UPDATE_SCORE THEN
            THEN
            ?Y_IMPACT IF -DY! THEN
;

: ?DX=0 DX @ 0 = ;
: ?ANGLE65OR-65 ANGLE @ DUP 65 = SWAP -65 = OR ;

: UPDATE_X_BALL X_BALL@ DX @ + ; \ ( -- X_BALL + DX )
: UPDATE_Y_BALL Y_BALL@ DY @ + ; \ ( -- Y_BALL + DY )

\ Istruzione che esegue l'aggiornamento di DX e DY della palla
: UPDATE_XY_BALL 
    ?ANGLE65OR-65 IF ?DX=0 IF BALL_DIRECTION @ DX ! ELSE 0 DX ! THEN THEN
    UPDATE_X_BALL UPDATE_Y_BALL XY_BALL! 
;

\ Istruzione che esegue il vero è proprio spostamento della palla.
\ Notiamo che prima viene cancellata dallo schermo la palla, successivamente si verifica un controllo sulla posizione attuale della palla
\ e in relazione a ciò si decide quale deve essere il prossimo spostamento di questa, come ultimo passaggio non resta che disegnare su
\ schermo la palla mossa di Dx e Dy precedentemente impostate.
: MOVE_BALL DELETE_BALL CHECK_BALL UPDATE_XY_BALL SETBALLSPEED DRAWBALL ;

\ ------------------------------------------------ END BALL ------------------------------------------------ \

\-------------------------------------------------- TIMER -------------------------------------------------- \

\ Definiso le costanti che mi serviranno per individuare i registri per effettuare il controllo sul timing
BASE 3000 + CONSTANT CS
CS 4 + CONSTANT CLO
CS 10 + CONSTANT C1
CS 18 + CONSTANT C3

8FC   CONSTANT SEC_BAR  \ Timer barre

\ Viene poi definita una serie di funzioni per il controllo del tempo di movimento della barra e della palla. 
\ La funzione SET_COMPARE_BAR utilizza la costante SEC_BAR per impostare il valore di confronto del timer per il 
\ movimento della barra, mentre la funzione SET_COMPARE_BALL utilizza la costante DAC per impostare il valore di 
\ confronto del timer per il movimento della palla.
\ Le funzioni ?TIME_BAR e ?TIME_BALL verificano se il bit appropriato del registro CS è stato impostato a 1, indicando 
\ che il tempo di movimento della barra o della palla è scaduto. In caso affermativo, vengono eseguite le azioni appropriate, 
\ come il movimento della barra del giocatore 1 o 2, il movimento della palla e la reimpostazione del timer corrispondente.
: SET_COMPARE_BAR CLO @ SEC_BAR + C1 ! ;
: ?TIME_BAR CS @ 2 AND 2 = ;
: SET_TIMER_BAR 2 CS ! SET_COMPARE_BAR ;

: SET_COMPARE_BALL CLO @ SEC_BALL @ + C3 ! ;
: ?TIME_BALL CS @ 8 AND 8 = ;
: SET_TIMER_BALL 8 CS ! SET_COMPARE_BALL ;

\ La porzione di codice che hai condiviso sembra essere parte di un gioco. Nella subroutine "?END", 
\ vengono presi i punteggi dei giocatori (PLAYER_1 SCORE@ e PLAYER_2 SCORE@) e si confrontano per verificare 
\ se uno dei due ha vinto la partita.
: ?END PLAYER_1 SCORE@ PLAYER_2 SCORE@ 2DUP > IF DROP ELSE SWAP DROP THEN 9 = ;

: PRINTGAME
    CLEAR_LOGOPJ
    PLAYING_ARENA
    DRAW_SCORE_START
    8B 153 XY_DRAWBAR
    366 153 XY_DRAWBAR
    DRAWBALL
;

\ La subroutine "RESETGAME" viene utilizzata per riportare il gioco allo stato iniziale.
: RESETGAME DELETE_BALL
            CENTER_BALL

            1 DX !
            0 DY ! 
            0 ANGLE ! 

            PLAYER_1 DELETE_BAR
            PLAYER_2 DELETE_BAR

            153 DUP 
            PLAYER_1 SWAP Y_POSITION_BAR!
            PLAYER_2 SWAP Y_POSITION_BAR! 
        
            PLAYER_1 RESETSCORE
            PLAYER_2 RESETSCORE
;

\ La subroutine "START" viene utilizzata per avviare il gioco. Viene chiamata la subroutine "RESETGAME" 
\ per portare il gioco allo stato iniziale e viene stampata la schermata di gioco con la subroutine "PRINTGAME". 
\ Viene impostato il timer per il movimento delle barre e della palla (SET_COMPARE_BAR, SET_COMPARE_BALL) e viene 
\ avviato il ciclo di gioco con il costrutto BEGIN-UNTIL. All'interno del ciclo, vengono controllati i timer per 
\ il movimento delle barre e della palla (?TIME_BAR e ?TIME_BALL). Se uno dei timer è scaduto, viene effettuato il 
\ movimento corrispondente (PLAYER_1 MOVE_BAR1, PLAYER_2 MOVE_BAR2, MOVE_BALL) e viene impostato nuovamente il timer 
\ corrispondente (SET_TIMER_BAR, SET_TIMER_BALL). Il ciclo continua finché non si verifica la condizione di fine gioco (?END),
\ ovvero quando uno dei due giocatori arriva a 9.

: START
    RESETGAME
    PRINTGAME
    SET_COMPARE_BAR
    SET_COMPARE_BALL
    BEGIN
        ?TIME_BAR   IF  PLAYER_1 MOVE_BAR1
                        PLAYER_2 MOVE_BAR2
                        SET_TIMER_BAR
                    THEN
        ?TIME_BALL  IF  MOVE_BALL
                        SET_TIMER_BALL
                    THEN
        ?END
    UNTIL
;

\ ------------ DISEGNO CAMPO E BARRE -------------------------------------
PRINTGAME
