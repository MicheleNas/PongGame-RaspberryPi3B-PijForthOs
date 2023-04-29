// Questo codice assembly disegna un carattere su uno schermo rappresentato tramite una matrice di pixel. 
// Prende come input l'indirizzo del carattere da disegnare e l'indirizzo del framebuffer dove disegnare il carattere.

// Viene utilizzata una subroutine "drawrow" per disegnare ogni riga del carattere. 
// Viene inizializzato un contatore r4 con valore 56, in quanto ogni carattere ha 7 righe 
// da disegnare e la matrice è 8x8, quindi vengono necessarie 56 iterazioni per disegnare completamente il carattere.

// La subroutine "drawrow" prende come argomento l'indirizzo di una riga del carattere e l'indirizzo 
// di una riga del framebuffer. La subroutine disegna ogni pixel della riga, caricando i pixel in 8 registri
// e memorizzandoli nel framebuffer

// Il codice utilizza anche l'istruzione push per salvare temporaneamente i registri r5-r12 sullo stack e pop per ripristinarli alla fine.

.global _start
_start:
	
	pop {r0}	// indirizzo char
	pop {r1}	// indirizzo framebuffer
	push {r5-r12}
	mov r2, r1
	mov r4, #56
	
	drawchar:
	mov r3, #5
	
	push {lr}
	bl drawrow
	pop {lr}
	
	add r1, r1, #0x1000
	mov r2, r1
	sub r4, r4, #1
	cmp r4, #0
	bne drawchar
	
	pop {r5-r12}
	bx lr
	
	drawrow:
		ldmia r0!, {r5-r12}
		stmia r2!, {r5-r12}
		sub r3, r3, #1
		cmp r3, #0
		bne	drawrow
		bx lr