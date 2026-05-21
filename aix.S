    .globl _start
    .section .text
_start:
    # === Get PID ===
    li      a7, 172             # __NR_getpid
    ecall

    # === Convert to decimal string ===
    la      s0, bufend          # s0 = end of buffer (will become start)
    mv      s1, s0              # s1 will be length later
    li      a3, 10
1:
    remu    a4, a0, a3
    divu    a0, a0, a3
    addi    a4, a4, '0'
    addi    s0, s0, -1
    sb      a4, 0(s0)
    bnez    a0, 1b
    sub     s1, s1, s0          # length

    # === openat(AT_FDCWD, "/proc/set_ai_thread", O_WRONLY, 0600) ===
    li      a0, -100            # AT_FDCWD
    la      a1, ai_path
    li      a2, 1               # O_WRONLY
    li      a3, 0600            # mode (ignored for procfs)
    li      a7, 56              # __NR_openat
    ecall
    bltz    a0, fail

    # === write(fd, buf, len) ===
    mv      s2, a0              # save fd
    mv      a1, s0              # buffer start
    mv      a2, s1              # length
    li      a7, 64              # __NR_write
    ecall
    bltz    a0, fail

    # === close(fd) ===
    mv      a0, s2
    li      a7, 57              # __NR_close
    ecall

    # === Prepare and execve(argv[1], &argv[1], envp) ===
    ld      a0, 16(sp)          # argv[1] (filename)
    addi    a1, sp, 16          # pointer to argv[1..]
    ld      a3, (sp)            # argc
    addi    a2, sp, 24	
    sh3add  a2, a3, a2          # envp
    li      a7, 221             # __NR_execve
    ecall                       # shouldn't return

fail:
    li      a7, 93              # __NR_exit with existing error code
    ecall

.section .rodata
ai_path: .asciz "/proc/set_ai_thread"

.section .data
buf:    .space 32
bufend:
