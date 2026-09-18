; clang window.s -framework Cocoa

.macro LEA reg, sym
      adrp \reg, \sym@PAGE
      add  \reg, \reg, \sym@PAGEOFF
.endm


; Calls `printf("%#llx\n", num)`.
; Consumes: `x0`.
; Uses: `[sp]` as scratch stack slot.
.macro LOG_PTR_LN num
	str \num, [sp]
  LEA x0, FMT_PTR.str
	bl _printf
.endm


.cstring

; AppKit constants.
NSApplication.str: .asciz "NSApplication"
sharedApplication.str: .asciz "sharedApplication"
setActivationPolicy.str: .asciz "setActivationPolicy:"
.set NSApplicationActivationPolicyRegular, 0

; App constants.
UNKNOWN_ERROR.str: .asciz "unknown error"
OK.str: .asciz "ok"
FMT_NUM.str: .asciz "%lld\n"
FMT_PTR.str: .asciz "%#llx\n"


.data


.text

.global _main
_main:
	sub sp, sp, #64 ; 16B saved pair!
	stp x29, x30, [sp, #48]  ; save frame pointer + return address
	add x29, sp, #48         ; establish new frame pointer

	; Locate `NSApplication` class and store it in `[sp+8]`.
	LEA x0, NSApplication.str
	bl _objc_getClass
	cmp x0, 0
	b.eq .die
	str x0, [sp, 8]
	LOG_PTR_LN x0

	; Register the `sharedApplication` name and store it in `[sp + 16]`.
	LEA x0, sharedApplication.str
	bl _sel_registerName
	; `sel_registerName` cannot fail so do not check the return value.
	str x0, [sp, 16]
	LOG_PTR_LN x0

	; Register the `setActivationPolicy` name and store it in `[sp + 24]`.
	LEA x0, setActivationPolicy.str
	bl _sel_registerName
	; `sel_registerName` cannot fail so do not check the return value.
	str x0, [sp, 24]
	LOG_PTR_LN x0

	; Send the message to create an `NSApplication` instance and store its id in `[sp + 32].
	ldr x0, [sp, 8] ;`NSApplication` id
	ldr x1, [sp, 16] ; `sharedApplication` id
	bl _objc_msgSend
	cmp x0, 0
	b.eq .die
	str x0, [sp, 32]
	LOG_PTR_LN x0

	; Set the activation policy for our application to be allowed to have a window.
	ldr x0, [sp, 32] ; app id
	ldr x1, [sp, 24] ; `setActivationPolicy` id
	mov x2, #NSApplicationActivationPolicyRegular
	bl _objc_msgSend
	cmp x0, 0
	b.eq .die
	; do not store the result.




	LEA x0, OK.str
	bl _puts

	mov w0, #0
	ldp x29, x30, [sp, #48] ; restore frame pointer and return address.
	add sp, sp, #64 ; reset frame pointer.
	ret


.die:
	LEA x0, UNKNOWN_ERROR.str
	bl _puts
	mov w0, #1
	ldp x29, x30, [sp, #48] ; restore frame pointer and return address.
	add sp, sp, #64 ; reset frame pointer.
	ret
