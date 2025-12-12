// It only occurs when the stack clash protector uses a loop to touch all
// pages during (static) stack allocation.  For (dynamic) stack allocation, FP
// is used.
//
// gcc -O2 -fstack-clash-protection -c -S test_stack-clash-protection.c
#define PAGE_SIZE       4096
#define SIZE            (3 * PAGE_SIZE)

extern void bar(char *buffer);

void foo() {
        char buffer[SIZE];
        bar(buffer);
}
