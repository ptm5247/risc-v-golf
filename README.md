# RISC-V Simulator Code Golf

This project was inspired by an assignment given to me during the Fall 2022 semester in a Computer Architecture class. The assignment was as follows (original instructions available [here](https://github.com/schoeberl/cae-lab/tree/master/finasgmt)):

Write a program in any language that simulates a RISC-V processor. The program should accept a file path as a command line argument which references a compiled RISC-V binary. The simulator should provide 1MB of memory for the program and support all RV32I instructions except `ebreak`, the `fence` instructions, and the `csr` instructions. The only `ecall` that needs to be supported is `ecall 10` which exits the program. When the program terminates, the contents of the 32 registers should be printed to `stdout`.

I completed and submitted this project in C, but I had a lot of spare time and decided that, as an extra challenge, I would try to minimize the size of the source code for the simulator. After a bit of condensing, I had a working solution using less than 100 lines of C source code. This solution can be found [here](./src/main.c).

This was satisfying, but I was unhappy with the comparatively giant executable that `gcc` produced for the simulator. To take my golf challenge to the next level, I decided I would try to minimize the size of the final executable instead. To do this, I decided to abandon C (and compilers) altogether and build an executable from scratch. I set an initial goal for 1KB, which was less than 1/20th the size of the executable produced by `gcc` (using default options).

I started by simply writing a working solution that mimicked my C code in x86 Assembly. I had some experience with ARM, but this was my first foray into x86, so this was enough of a project on its own. Once I got this working, I started really focusing on where I could cut down the size of the executable. After reading [this article](https://www.muppetlabs.com/~breadbox/software/tiny/teensy.html) and taking a closer look at the output of `nasm`, I realized I was still getting a bunch of unnecessary things packed in with my executable. So, I decided I would need to write the program/section headers by hand too. Doing this would also allow me to insert instructions and program data into unused portions of these sections.

Finally, I arrived at a solution that I was satisfied with. Running `make small` will build an executable taking up only 396 bytes that passes all of the tests distributed for the project (on my machine). While I may be able to squeeze a few more bytes out of this file, after already smashing my original goal of 1KB and breaking what I believe to be the last significant milestone (400 bytes), I was ready to call it done. The simulator is built entirely from the contents of [main.s](./src/main.s).