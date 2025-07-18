.global _start
_start:
    addi x10, x0, 5
    addi x11, x0, 8
    addi x12, x0, 10
    bge x11, x10, _first_branch
    sw x11, 0(x12)
    lw x10, 0(x12)
    lw x15, 0(x12)
_first_branch:
    sw x10, 0(x12)
    lw x11, 0(x12)
    mul x7, x5, x6
