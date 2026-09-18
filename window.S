; clang window.S -framework Cocoa

; Stack slot offsets, relative to `sp`. Brackets are written at the use site so
; the values stay plain numbers usable in arithmetic and in the guard below.
#define STACK_SIZE 256
#define STACK_FUNCTION_SAVE 16
#define STACK_SCRATCH 0
#define STACK_NS_APPLICATION_CLASS 8
#define STACK_SHARED_APPLICATION_NAME 16
#define STACK_ACTIVATION_POLICY_NAME 24
#define STACK_NS_APPLICATION_ID 32
#define STACK_RUN_NAME 40
#define STACK_NS_WINDOW_NAME 48
#define STACK_ALLOC_NAME 56
#define STACK_NS_WINDOW_CLASS 64
#define STACK_NS_WINDOW_ID 72
#define STACK_INIT_WITH_CONTENT_RECT_NAME 80
#define STACK_MAKE_KEY_AND_ORDER_FRONT_NAME 88
#define STACK_ACTIVATE_NAME 96
#define STACK_NS_BUTTON_CLASS 104
#define STACK_INIT_NAME 112
#define STACK_NS_BUTTON_ID 120
#define STACK_STRING_WITH_UTF8_STRING_NAME 128
#define STACK_NS_STRING_CLASS 136
#define STACK_SET_TITLE_NAME 144

; Highest slot in use; must stay below the saved x29/x30 pair.
#define STACK_LAST_SLOT STACK_SET_TITLE_NAME
#if STACK_LAST_SLOT + 8 > STACK_SIZE - STACK_FUNCTION_SAVE
#error "locals overflow into the saved frame pointer"
#endif
#if STACK_SIZE % 16 != 0
#error "stack size must be 16-byte aligned"
#endif

.data
.p2align 3
RECT: .double 100.0, 100.0, 400.0, 300.0    ; x, y, width, height

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

; Sends a message with 1 argument.
.macro OBJC_MSG_SEND_3 arg0, arg1, arg2
	ldr x0, [sp, #\arg0]
	ldr x1, [sp, #\arg1]
	mov x2, #\arg2
	bl _objc_msgSend
	cmp x0, 0
	b.eq .die
.endm

.macro SEL_REGISTER_NAME arg0
	LEA x0, \arg0
	bl _sel_registerName
.endm

.macro OBJC_GET_CLASS arg0
	LEA x0, \arg0
	bl _objc_getClass
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
NSWindow.str: .asciz "NSWindow"
NSButton.str: .asciz "NSButton"
NSString.str: .asciz "NSString"
stringWithUTF8String.str: .asciz "stringWithUTF8String:"
alloc.str: .asciz "alloc"
init.str: .asciz "init"
setTitle.str: .asciz "setTitle:"
Hello.str: .asciz "Hello"
initWithContentRect.str: .asciz "initWithContentRect:styleMask:backing:defer:"
sharedApplication.str: .asciz "sharedApplication"
setActivationPolicy.str: .asciz "setActivationPolicy:"
run.str: .asciz "run"
makeKeyAndOrderFront.str: .asciz "makeKeyAndOrderFront:"
activateIgnoringOtherApps.str: .asciz "activateIgnoringOtherApps:"
#define NSApplicationActivationPolicyRegular 0
#define NSBackingStoreBuffered 2

; App constants.
UNKNOWN_ERROR.str: .asciz "unknown error"
UNREACHABLE.str: .asciz "unreachable"
FMT_NUM.str: .asciz "%lld\n"
FMT_PTR.str: .asciz "%#llx\n"


.text

.global _main
_main:
	; Prologue.
	sub sp, sp, #STACK_SIZE
	stp x29, x30, [sp, #STACK_SIZE-STACK_FUNCTION_SAVE]  ; save frame pointer + return address
	add x29, sp, #STACK_SIZE-STACK_FUNCTION_SAVE         ; establish new frame pointer

	; Locate `NSApplication` class and store it.
	OBJC_GET_CLASS NSApplication.str
	str x0, [sp, #STACK_NS_APPLICATION_CLASS]
	LOG_PTR_LN x0

  ; Register name.
	SEL_REGISTER_NAME sharedApplication.str
	str x0, [sp, #STACK_SHARED_APPLICATION_NAME]
	LOG_PTR_LN x0

  ; Register name.
	SEL_REGISTER_NAME setActivationPolicy.str
	str x0, [sp, #STACK_ACTIVATION_POLICY_NAME]
	LOG_PTR_LN x0

  ; Register name.
	SEL_REGISTER_NAME run.str
	str x0, [sp, #STACK_RUN_NAME]
	LOG_PTR_LN x0

	; Create a `NSApplication` instance.
	OBJC_MSG_SEND_2 STACK_NS_APPLICATION_CLASS, STACK_SHARED_APPLICATION_NAME
	cmp x0, 0
	b.eq .die
	str x0, [sp, #STACK_NS_APPLICATION_ID]
	LOG_PTR_LN x0

	; Set the activation policy for our application to be allowed to have a window.
	OBJC_MSG_SEND_3 STACK_NS_APPLICATION_ID, STACK_ACTIVATION_POLICY_NAME, NSApplicationActivationPolicyRegular
	cmp x0, 0
	b.eq .die

  ; Register name.
	SEL_REGISTER_NAME alloc.str
	str x0, [sp, #STACK_ALLOC_NAME]
	LOG_PTR_LN x0
	
	; Locate `NSWindow` class and store it.
	OBJC_GET_CLASS NSWindow.str
	str x0, [sp, #STACK_NS_WINDOW_CLASS]
	LOG_PTR_LN x0


	; Create a `NSWindow` instance.
	OBJC_MSG_SEND_2 STACK_NS_WINDOW_CLASS, STACK_ALLOC_NAME
	str x0, [sp, #STACK_NS_WINDOW_ID]
	LOG_PTR_LN x0

  ; Register name.
	SEL_REGISTER_NAME initWithContentRect.str
	str x0, [sp, #STACK_INIT_WITH_CONTENT_RECT_NAME]
	LOG_PTR_LN x0

	; Initiate the window with a content rectangle.
	ldr x0, [sp, #STACK_NS_WINDOW_ID]
	ldr x1, [sp, #STACK_INIT_WITH_CONTENT_RECT_NAME]
	LEA x8, RECT
	ldp d0, d1, [x8]
	ldp d2, d3, [x8, #16]
	mov x2, #11 ; Flags
	mov x3, #NSBackingStoreBuffered
	mov w4, #0 ; false
	bl _objc_msgSend
	cmp x0, 0
	b.eq .die
	; -init may return a different object than -alloc: keep the result.
	str x0, [sp, #STACK_NS_WINDOW_ID]
	LOG_PTR_LN x0


	; Locate `NSButton` class and store it.
	OBJC_GET_CLASS NSButton.str
	str x0, [sp, #STACK_NS_BUTTON_CLASS]
	LOG_PTR_LN x0

  ; Register name.
	SEL_REGISTER_NAME init.str
	str x0, [sp, #STACK_INIT_NAME]
	LOG_PTR_LN x0


	; Allocate a button.
	OBJC_MSG_SEND_2 STACK_NS_BUTTON_CLASS, STACK_ALLOC_NAME
	str x0, [sp, #STACK_NS_BUTTON_ID]

	; Init the button.
	OBJC_MSG_SEND_2 STACK_NS_BUTTON_ID, STACK_INIT_NAME
	str x0, [sp, #STACK_NS_BUTTON_ID]
	

  ; Register name.
	SEL_REGISTER_NAME setTitle.str
	str x0, [sp, #STACK_SET_TITLE_NAME]
	LOG_PTR_LN x0

  ; Register name.
	SEL_REGISTER_NAME stringWithUTF8String.str
	str x0, [sp, #STACK_STRING_WITH_UTF8_STRING_NAME]
	LOG_PTR_LN x0


	; Locate `NSString` class and store it.
	OBJC_GET_CLASS NSString.str
	str x0, [sp, #STACK_NS_STRING_CLASS]
	LOG_PTR_LN x0

	; Show the window. -makeKeyAndOrderFront: returns void, so do NOT nil-check x0.
	SEL_REGISTER_NAME makeKeyAndOrderFront.str
	str x0, [sp, #STACK_MAKE_KEY_AND_ORDER_FRONT_NAME]
	ldr x0, [sp, #STACK_NS_WINDOW_ID]
	ldr x1, [sp, #STACK_MAKE_KEY_AND_ORDER_FRONT_NAME]
	mov x2, #0 ; nil sender
	bl _objc_msgSend

	; Bring the whole app forward. Also returns void.
	SEL_REGISTER_NAME activateIgnoringOtherApps.str
	str x0, [sp, #STACK_ACTIVATE_NAME]
	ldr x0, [sp, #STACK_NS_APPLICATION_ID]
	ldr x1, [sp, #STACK_ACTIVATE_NAME]
	mov x2, #1 ; YES
	bl _objc_msgSend


	; Tell the application to run. This does not return: terminating calls exit().
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
