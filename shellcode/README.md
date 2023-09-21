## Complation Instructions

### Windows
``` bash
# compilation
> nasm -f win32 <file>.asm
> ld -m elf_i386 -o <output> <file>.o

# checking for bad characters for exploit dev
> objdump -M intel -d <output>

# print shellcode in C format
> objdump -M intel -d <output> | grep '[0-9a-f]:' | grep -v 'file' | cut -f1-6 -d ' ' | tr -s ' ' | tr '\t' ' ' | sed 's/ $//g' | sed 's/ /\\x/g' | paste -d '' -s | sed 's/^/"/' | sed 's/$/"/g'
```

### MacOS
``` bash
# compilation
> nasm -f macho64 <file>.asm
> ld -L <MacOS linker> -lSystem <file>.o -o <output>

# check for charaters
objdump -M intel -d <file>
```

### Linux
``` bash
```
