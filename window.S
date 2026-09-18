; clang window.s -framework Cocoa

#define STACK_SIZE 64
#define STACK_FUNCTION_SAVE 16
#define STACK_SCRATCH [sp, 0]
#define STACK_NS_APPLICATION_CLASS [sp, 8]
#define STACK_SHARED_APPLICATION_ID [sp, 16]
#define STACK_ACTIVATION_POLICY_ID [sp, 24]
#define STACK_NS_APPLICATION_ID [sp, 32]

.macro LEA reg, sym
      adrp \reg, \sym@PAGE
      add  \reg, \reg, \sym@PAGEOFF
.endm


; Calls `printf("%#llx\n", num)`.
; Consumes: `x0`.
; Uses: `[sp]` as scratch stack slot.
.macro LOG_PTR_LN num
	str \num, STACK_SCRATCH
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
	sub sp, sp, #STACK_SIZE ; 16B saved pair!
	stp x29, x30, [sp, #STACK_SIZE-16]  ; save frame pointer + return address
	add x29, sp, #STACK_SIZE-STACK_FUNCTION_SAVE         ; establish new frame pointer

	; Locate `NSApplication` class and store it.
	LEA x0, NSApplication.str
	bl _objc_getClass
	cmp x0, 0
	b.eq .die
	str x0, STACK_NS_APPLICATION_CLASS
	LOG_PTR_LN x0

	; Register the `sharedApplication` name and store it.
	LEA x0, sharedApplication.str
	bl _sel_registerName
	; `sel_registerName` cannot fail so do not check the return value.
	str x0, STACK_SHARED_APPLICATION_ID
	LOG_PTR_LN x0

	; Register the `setActivationPolicy` name and store it.
	LEA x0, setActivationPolicy.str
	bl _sel_registerName
	; `sel_registerName` cannot fail so do not check the return value.
	str x0, STACK_ACTIVATION_POLICY_ID
	LOG_PTR_LN x0

	; Send the message to create an `NSApplication` instance and store its id.
	ldr x0, STACK_NS_APPLICATION_CLASS
	ldr x1, STACK_SHARED_APPLICATION_ID
	bl _objc_msgSend
	cmp x0, 0
	b.eq .die
	str x0, STACK_NS_APPLICATION_ID
	LOG_PTR_LN x0

	; Set the activation policy for our application to be allowed to have a window.
	ldr x0, STACK_NS_APPLICATION_ID
	ldr x1, STACK_ACTIVATION_POLICY_ID
	mov x2, #NSApplicationActivationPolicyRegular
	bl _objc_msgSend
	cmp x0, 0
	b.eq .die
	; do not store the result.




	LEA x0, OK.str
	bl _puts

	mov w0, #0 ; exit code
	ldp x29, x30, [sp, #STACK_SIZE-STACK_FUNCTION_SAVE] ; restore frame pointer and return address.
	add sp, sp, #STACK_SIZE ; reset frame pointer.
	ret


.die:
	LEA x0, UNKNOWN_ERROR.str
	bl _puts
	mov w0, #1 ; exit code
	ldp x29, x30, [sp, #STACK_SIZE-STACK_FUNCTION_SAVE] ; restore frame pointer and return address.
	add sp, sp, #STACK_SIZE ; reset frame pointer.
	ret
