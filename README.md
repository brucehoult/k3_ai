# Run command on K3's AI cores

Utility to run a command with arguments on the A100 "AI" cores on SpacemiT K3.

## Quick start

```bash
$ git clone https://github.com/brucehoult/k3_ai
$ cd ai
$ make
$ ai bash
```

## Usage

```bash
ai cmd arg1 arg2 ...

aix path arg1 arg2 ...
```

Normally prefer to use `ai`.  This is a shell script that converts a bare program name to the absolute path
of the executable and then chains to `aix`. It's about 1ms slower than calling `aix` directly.

`aix` is a tiny assembly language program that needs the absolute or relative path of the program to run.
It is written to be pure asm using only syscalls, no libraries, no dynamic linker, so as to be
really sure that nothing has used any RVV instructions in this process, and therefore no
decisions have been made based on the X100 core's shorter VLEN.

## Examples

```bash
# just run a single program on the A100 cores
ai as hello.s -o hello.o

# same thing but maybe 1ms faster
aix /usr/bin/as hello.s -o hello.o

# run a whole build. All processes started by `make` will run on the A100 cores.
ai make -j8 test

# start a shell on the A100 cores. All programs run from it will be run only on the A100 cores
ai bash
```

## Why you need it

The K3 has eight high performance Out-of-Order X100 cores with RISC-V vector length of 256 bits.
These cores are what all normal Linux programs run on.

There are also eight lower performance in-order A100 "AI" cores similar to the X60 cores in the
SpacemiT K1/M1 chips, but with long 1024 bit vector registers and ALU.

The "AI" cores can actually run all normal Linux programs. On standard scalar code they have
approximately 40% the performance of the main X100 cores, but on certain kinds of vectorised
code (for example Llama) they have considerably higher performance.

Even ignoring vectorised code, the A100 cores by themselves have more computing power than
any previous RISC-V computer under $1000, including those using the Allwinner D1, StarFive JH7110,
THead TH1520, SpacemiT K1/M1, or even Eswin EIC7700x.

As such, it is well worth using the A100 cores to run normal programs and adding 40% to the
overall power of a K3 computer.

Because of the different vector length, it is dangerous to move a program between X100 and A100
cores -- in either direction -- once it has been started.

SpacemiT provides a mechanism to move an existing running program from the X100 cores to the
A100 cores by writing the `PID` of the process to `/proc/set_ai_thread` but that is dangerous
depending on what that process has already done.

This utility creates a new process and then moves it to the A100 cores before it has done
anything dangerous, and then does `EXEC()` on the program you really wanted to run.
