; clang window.s -framework Cocoa

.macro LEA reg, sym
      adrp \reg, \sym@PAGE
      add  \reg, \reg, \sym@PAGEOFF
.endm


.cstring

// STR_NSString: .asciz "NSString"

NSApplication.str: .asciz "NSApplication"
sharedApplication.str: .asciz "sharedApplication"
UNKNOWN_ERROR.str: .asciz "unknown error"
OK.str: .asciz "ok"


.data


.text

.global _main
_main:
	sub sp, sp, #0x30 ; 3 locals (24B, rounded to 32) + 16B saved pair
	stp x29, x30, [sp, #0x20]  ; save frame pointer + return address
	add x29, sp, #0x20         ; establish new frame pointer

	; Locate `NSApplication` class and store it in `[sp]`.
	LEA x0, NSApplication.str
	bl _objc_getClass
	cmp x0, 0
	b.eq .die
	str x0, [sp]

	; Register `sharedApplication` and store it in `[sp + 8]`.
	LEA x0, sharedApplication.str
	bl _sel_registerName
	cmp x0, 0
	b.eq .die
	str x0, [sp, 8]

	; Send the message.
	ldr x0, [sp]
	ldr x1, [sp, 8]
	bl _objc_msgSend
	cmp x0, 0
	b.eq .die
	str x0, [sp, 16]


	LEA x0, OK.str
	bl _puts

	mov w0, #0
	ldp x29, x30, [sp, #0x20] ; restore frame pointer and return address.
	add sp, sp, #0x30 ; reset frame pointer.
	ret


.die:
	LEA x0, UNKNOWN_ERROR.str
	bl _puts
	mov w0, #1
	ldp x29, x30, [sp, #0x20] ; restore frame pointer and return address.
	add sp, sp, #0x30 ; reset frame pointer.
	ret
