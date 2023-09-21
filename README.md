# Evader

I want to work on two types of *basic* Antivirus/EDR evasion tools for general malware. It may evolve into something more sophisticated, but for now, I'm going to narrow the scope to "If it bypasses current Windows Defender, we're good."

With that being said, there are two approaches, one specific to traditional AV on PCs, which typically do not perform full sandboxed executions, but instead just check for good signatures, no immediate socket constructions, etc.

The other approach is for bypassing heavier-duty EDR. The trick (so I hear) is to manage the syscalls so that we don't trigger some flag when interacting with WinAPI functions
like VirtualAlloc. There are obvious requirements for certain shellcodes. For example, a computer without rwx (DEP) on a polymorphic shellcode won't work without combining it with other tricks.
Umm, but these are pretty basic shellcodes, and I don't have the funds to actually test them on EDR, so yeah... Down the line, it may be cool to try and obfuscate at a shellcode-level.

x64 linux/mac shellcode is also on the horizon, but they generally do not have the same AV as Windows (not that the Windows shellcode will bypass EDR).
