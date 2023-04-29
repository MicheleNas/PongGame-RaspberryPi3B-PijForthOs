// Il codice assembly permette di disegnare un rettangolo di dimensioni variabili sullo schermo.
// La funzione accetta come argomenti il colore del rettangolo, l'indirizzo di partenza 
// per il disegno, il numero di righe da disegnare, il numero di cicli per istruzioni stmia e il numero 
// di cicli per istruzioni str.

// La funzione inizia copiando i valori degli argomenti nei registri r5-r12 e salva questi registri nello stack. 
// Successivamente, la funzione inizia a disegnare il rettangolo utilizzando un ciclo while. In ogni iterazione 
// del ciclo, viene chiamata la funzione "drawrow" che disegna una singola riga del rettangolo. 
// Dopo ogni chiamata a drawrow, l'indirizzo di partenza per il disegno viene incrementato di 0x1000 (cioè 1024 pixel), 
// corrispondente al salto di una riga, e il contatore delle righe viene decrementato di 1.

// La funzione "drawrow" inizia controllando il numero di cicli rimasti per istruzioni stmia. 
// Se la lunghezza orizzontale della riga è maggiore o uguale a 8, la funzione utilizza l'istruzione 
// stmia per disegnare gli otto pixel in una sola istruzione. Se la lunghezza orizzontale è inferiore a 8, 
// la funzione disegna ogni singolo pixel utilizzando l'istruzione str.

// Dopo il disegno della riga, la funzione "drawrow" controlla il numero di cicli rimasti per l'istruzione 
// str e disegna i pixel rimanenti, uno per uno, utilizzando l'istruzione str.

// Infine, la funzione ripristina i valori dei registri r5-r12 dallo stack e ritorna al chiamante.

.global _start
_start:
	
	
	pop {r0}    // colore rettangolo
	pop {r1}    // indirizzo di partenza per disegnare SAREBBE R1
	pop {r2}    // n cicli righe
	pop {r3}	// n cicli per istruzioni stmia; in modo da disegnare più punti per linea
	pop {r4}    // n cicli per istruzione str; disegna i punti rimanenti, quindi un numero mod di 8
	
	push {r5-r12}
	
	mov r5, r0
	mov r6, r0
	mov r7, r0
	mov r8, r0
	mov r9, r0
	mov r10, r0
	mov r11, r0
	mov r12, r0
	
	mov r0, r1
	
	drawrect:
	
	push {r3, r4, lr}
	bl drawrow
	pop {r3, r4, lr}
	
	add r1, r1, #0x1000
	mov r0, r1
	sub r2, r2, #1 
	cmp r2, #0	
	bne drawrect
	
	pop {r5-r12}
	bx lr
	
	drawrow:
		cmp r3, #0
		beq jump1					// verifico che la lunghezza orizzontale non sia minore di 8

		stmia r0!, {r5-r12} 
		sub r3, r3, #1
		cmp r3, #0
		bne	drawrow
		cmp r4, #0
		beq jump2				// verifico che ci siano punti rimanenti da disegnare

		jump1:
		drawsinglepoint:
			str r5, [r0], #4
			sub r4, r4, #1
			cmp r4, #0
			bne	drawsinglepoint
            
		jump2:
		bx lr
