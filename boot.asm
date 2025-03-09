[BITS 16]
[ORG 0x7C00]

VIDEO_MEM        equ 0xB800
SCREEN_WIDTH     equ 80
SCREEN_HEIGHT    equ 25
MAX_CHARS        equ SCREEN_WIDTH * SCREEN_HEIGHT

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov ax, 0x03        ; Текстовый режим 80x25
    int 0x10

    call set_blue_background  ; Устанавливаем синий фон
    call display_logo         ; Отображение логотипа

    mov si, welcome_msg
    call print_text

main_loop:
    call get_key
    cmp al, 0x1B        ; ESC - выход
    je halt_system
    cmp al, 0x08        ; Backspace
    je handle_backspace
    cmp al, 0x0D        ; Enter
    je handle_enter
    call add_char_to_buffer
    call print_char
    jmp main_loop

handle_backspace:
    call remove_last_char
    jmp main_loop

handle_enter:
    call check_clear_cmd
    call new_line
    jmp main_loop

halt_system:
    cli
    hlt

set_blue_background:
    push es
    mov ax, VIDEO_MEM
    mov es, ax
    xor di, di
    mov cx, SCREEN_WIDTH * SCREEN_HEIGHT
    mov ax, 0x1F20    ; Пробел (0x20) с белым текстом (0x1F) на синем фоне
    rep stosw
    pop es
    ret

display_logo:
    push es
    mov ax, VIDEO_MEM
    mov es, ax

    ; Смещаем вниз на 10 строк
    mov di, (SCREEN_WIDTH * 10 * 2) + 35 * 2

    mov byte [es:di], '#'   ; ASCII 35
    mov byte [es:di + 1], 0x1F
    add di, 2

    mov byte [es:di], 'C'
    mov byte [es:di + 1], 0x1F
    add di, 2

    mov byte [es:di], 'H'
    mov byte [es:di + 1], 0x1F
    add di, 2

    mov byte [es:di], 'I'
    mov byte [es:di + 1], 0x1F
    add di, 2

    mov byte [es:di], 'L'
    mov byte [es:di + 1], 0x1F
    add di, 2

    mov byte [es:di], 'O'
    mov byte [es:di + 1], 0x1F
    add di, 2

    mov byte [es:di], 'S'
    mov byte [es:di + 1], 0x1F
    add di, 2

    mov byte [es:di], '#'    
    mov byte [es:di + 1], 0x1F  

    pop es
    ret


print_text:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_text
.done:
    ret

print_char:
    mov ah, 0x0E
    int 0x10
    ret

get_key:
    xor ah, ah
    int 0x16
    ret

add_char_to_buffer:
    cmp cx, 64
    jae .done
    mov si, buffer
    add si, cx
    mov [si], al
    inc cx
.done:
    ret

remove_last_char:
    test cx, cx
    jz .done
    dec cx
    mov al, 0x08
    call print_char
    mov al, ' '
    call print_char
    mov al, 0x08
    call print_char
.done:
    ret

check_clear_cmd:
    mov si, buffer
    mov di, clear_cmd
    mov cx, 5
    repe cmpsb
    jne .done
    call clear_screen
.done:
    ret

clear_screen:
    call set_blue_background
    xor cx, cx
    ret

new_line:
    mov al, 0x0D
    call print_char
    mov al, 0x0A
    call print_char
    xor cx, cx
    ret

welcome_msg db 'Type "clear" to clean.', 0
clear_cmd   db 'clear', 0
buffer      times 64 db 0

times 510 - ($ - $$) db 0
dw 0xAA55
