; clang window.s -framework Cocoa

.macro LEA reg, sym
      adrp \reg, \sym@PAGE
      add  \reg, \reg, \sym@PAGEOFF
.endm


.cstring

// STR_NSString: .asciz "NSString"

NSApplication.str: .asciz "NSApplication"
UNKNOWN_ERROR.str: .asciz "unknown error"
OK.str: .asciz "ok"


.data


.text

.global _main
_main:
	sub sp, sp, #0x20 ; FIXME: real stack size.
	stp x29, x30, [sp, #0x10]  ; save frame pointer + return address
	add x29, sp, #0x10         ; establish new frame pointer

	; Locate `NSApplication` class and store it in `[sp]`.
	LEA x0, NSApplication.str
	bl _objc_getClass
	str x0, [sp]
	cmp x0, 0
	b.eq .die


	LEA x0, OK.str
	b _puts

	mov w0, #0
	ldp x29, x30, [sp, #0x10] ; restore frame pointer and return address.
	add sp, sp, #0x20 ; reset frame pointer.
	ret


.die:
	LEA x0, UNKNOWN_ERROR.str
	b _puts
	mov w0, #1
	ldp x29, x30, [sp, #0x10] ; restore frame pointer and return address.
	add sp, sp, #0x20 ; reset frame pointer.
	ret
