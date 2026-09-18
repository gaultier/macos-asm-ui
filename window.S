; clang window.S -framework Cocoa

; Stack slot offsets, relative to `sp`. Brackets are written at the use site so
; the values stay plain numbers usable in arithmetic and in the guard below.
#define STACK_SIZE 128
#define STACK_FUNCTION_SAVE 16
#define STACK_SCRATCH 0
#define STACK_NS_APPLICATION_CLASS 8
#define STACK_SHARED_APPLICATION_NAME 16
#define STACK_ACTIVATION_POLICY_NAME 24
#define STACK_NS_APPLICATION_ID 32
#define STACK_RUN_NAME 40

; Highest slot in use; must stay below the saved x29/x30 pair.
#define STACK_LAST_SLOT STACK_RUN_NAME
#if STACK_LAST_SLOT + 8 > STACK_SIZE - STACK_FUNCTION_SAVE
#error "locals overflow into the saved frame pointer"
#endif
#if STACK_SIZE % 16 != 0
#error "stack size must be 16-byte aligned"
#endif

.macro LEA reg, sym
      adrp \reg, \sym@PAGE
      add  \reg, \reg, \sym@PAGEOFF
.endm

; Sends a message with no arguments. Takes stack slot *offsets*, not addresses.
.macro OBJC_MSG_SEND_2 arg0, arg1
	ldr x0, [sp, #\arg0]
	ldr x1, [sp, #\arg1]
	bl _objc_msgSend
	cmp x0, 0
	b.eq .die
.endm


; Calls `printf("%#llx\n", num)`.
; Consumes: `x0`.
; Uses: `[sp]` as scratch stack slot.
.macro LOG_PTR_LN num
	str \num, [sp, #STACK_SCRATCH]
  LEA x0, FMT_PTR.str
	bl _printf
.endm


.cstring

; AppKit constants.
NSApplication.str: .asciz "NSApplication"
sharedApplication.str: .asciz "sharedApplication"
setActivationPolicy.str: .asciz "setActivationPolicy:"
run.str: .asciz "run"
.set NSApplicationActivationPolicyRegular, 0

; App constants.
UNKNOWN_ERROR.str: .asciz "unknown error"
UNREACHABLE.str: .asciz "unreachable"
FMT_NUM.str: .asciz "%lld\n"
FMT_PTR.str: .asciz "%#llx\n"


.data


.text

.global _main
_main:
	sub sp, sp, #STACK_SIZE
	stp x29, x30, [sp, #STACK_SIZE-STACK_FUNCTION_SAVE]  ; save frame pointer + return address
	add x29, sp, #STACK_SIZE-STACK_FUNCTION_SAVE         ; establish new frame pointer

	; Locate `NSApplication` class and store it.
	LEA x0, NSApplication.str
	bl _objc_getClass
	cmp x0, 0
	b.eq .die
	str x0, [sp, #STACK_NS_APPLICATION_CLASS]
	LOG_PTR_LN x0

	; Register the `sharedApplication` name and store it.
	LEA x0, sharedApplication.str
	bl _sel_registerName
	; `sel_registerName` cannot fail so do not check the return value.
	str x0, [sp, #STACK_SHARED_APPLICATION_NAME]
	LOG_PTR_LN x0

	; Register the `setActivationPolicy` name and store it.
	LEA x0, setActivationPolicy.str
	bl _sel_registerName
	; `sel_registerName` cannot fail so do not check the return value.
	str x0, [sp, #STACK_ACTIVATION_POLICY_NAME]
	LOG_PTR_LN x0


	; Register the `run` name and store it.
	LEA x0, run.str
	bl _sel_registerName
	; `sel_registerName` cannot fail so do not check the return value.
	str x0, [sp, #STACK_RUN_NAME]
	LOG_PTR_LN x0

	; Send the message to create an `NSApplication` instance and store its id.
	ldr x0, [sp, #STACK_NS_APPLICATION_CLASS]
	ldr x1, [sp, #STACK_SHARED_APPLICATION_NAME]
	bl _objc_msgSend
	cmp x0, 0
	b.eq .die
	str x0, [sp, #STACK_NS_APPLICATION_ID]
	LOG_PTR_LN x0

	; Set the activation policy for our application to be allowed to have a window.
	ldr x0, [sp, #STACK_NS_APPLICATION_ID]
	ldr x1, [sp, #STACK_ACTIVATION_POLICY_NAME]
	mov x2, #NSApplicationActivationPolicyRegular
	bl _objc_msgSend
	cmp x0, 0
	b.eq .die
	; do not store the result.


	; Send the message to run. This does not return: terminating calls exit().
	OBJC_MSG_SEND_2 STACK_NS_APPLICATION_ID, STACK_RUN_NAME



	; the end
	LEA x0, UNREACHABLE.str
	bl _puts

	mov w0, #1 ; exit code
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
