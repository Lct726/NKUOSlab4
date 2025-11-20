
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00009297          	auipc	t0,0x9
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0209000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00009297          	auipc	t0,0x9
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0209008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02082b7          	lui	t0,0xc0208
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0208137          	lui	sp,0xc0208

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	00009517          	auipc	a0,0x9
ffffffffc020004e:	fe650513          	addi	a0,a0,-26 # ffffffffc0209030 <buf>
ffffffffc0200052:	0000d617          	auipc	a2,0xd
ffffffffc0200056:	49a60613          	addi	a2,a2,1178 # ffffffffc020d4ec <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	5d5030ef          	jal	ra,ffffffffc0203e36 <memset>
    dtb_init();
ffffffffc0200066:	514000ef          	jal	ra,ffffffffc020057a <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	49e000ef          	jal	ra,ffffffffc0200508 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00004597          	auipc	a1,0x4
ffffffffc0200072:	e1a58593          	addi	a1,a1,-486 # ffffffffc0203e88 <etext+0x4>
ffffffffc0200076:	00004517          	auipc	a0,0x4
ffffffffc020007a:	e3250513          	addi	a0,a0,-462 # ffffffffc0203ea8 <etext+0x24>
ffffffffc020007e:	116000ef          	jal	ra,ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	15a000ef          	jal	ra,ffffffffc02001dc <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	084020ef          	jal	ra,ffffffffc020210a <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	0ad000ef          	jal	ra,ffffffffc0200936 <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	0ab000ef          	jal	ra,ffffffffc0200938 <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	5ed020ef          	jal	ra,ffffffffc0202e7e <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	560030ef          	jal	ra,ffffffffc02035f6 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	41c000ef          	jal	ra,ffffffffc02004b6 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	08d000ef          	jal	ra,ffffffffc020092a <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	7a2030ef          	jal	ra,ffffffffc0203844 <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	715d                	addi	sp,sp,-80
ffffffffc02000a8:	e486                	sd	ra,72(sp)
ffffffffc02000aa:	e0a6                	sd	s1,64(sp)
ffffffffc02000ac:	fc4a                	sd	s2,56(sp)
ffffffffc02000ae:	f84e                	sd	s3,48(sp)
ffffffffc02000b0:	f452                	sd	s4,40(sp)
ffffffffc02000b2:	f056                	sd	s5,32(sp)
ffffffffc02000b4:	ec5a                	sd	s6,24(sp)
ffffffffc02000b6:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02000b8:	c901                	beqz	a0,ffffffffc02000c8 <readline+0x22>
ffffffffc02000ba:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02000bc:	00004517          	auipc	a0,0x4
ffffffffc02000c0:	df450513          	addi	a0,a0,-524 # ffffffffc0203eb0 <etext+0x2c>
ffffffffc02000c4:	0d0000ef          	jal	ra,ffffffffc0200194 <cprintf>
readline(const char *prompt) {
ffffffffc02000c8:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000ca:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000cc:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000ce:	4aa9                	li	s5,10
ffffffffc02000d0:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000d2:	00009b97          	auipc	s7,0x9
ffffffffc02000d6:	f5eb8b93          	addi	s7,s7,-162 # ffffffffc0209030 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000de:	0ee000ef          	jal	ra,ffffffffc02001cc <getchar>
        if (c < 0) {
ffffffffc02000e2:	00054a63          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e6:	00a95a63          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc02000ea:	029a5263          	bge	s4,s1,ffffffffc020010e <readline+0x68>
        c = getchar();
ffffffffc02000ee:	0de000ef          	jal	ra,ffffffffc02001cc <getchar>
        if (c < 0) {
ffffffffc02000f2:	fe055ae3          	bgez	a0,ffffffffc02000e6 <readline+0x40>
            return NULL;
ffffffffc02000f6:	4501                	li	a0,0
ffffffffc02000f8:	a091                	j	ffffffffc020013c <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02000fa:	03351463          	bne	a0,s3,ffffffffc0200122 <readline+0x7c>
ffffffffc02000fe:	e8a9                	bnez	s1,ffffffffc0200150 <readline+0xaa>
        c = getchar();
ffffffffc0200100:	0cc000ef          	jal	ra,ffffffffc02001cc <getchar>
        if (c < 0) {
ffffffffc0200104:	fe0549e3          	bltz	a0,ffffffffc02000f6 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200108:	fea959e3          	bge	s2,a0,ffffffffc02000fa <readline+0x54>
ffffffffc020010c:	4481                	li	s1,0
            cputchar(c);
ffffffffc020010e:	e42a                	sd	a0,8(sp)
ffffffffc0200110:	0ba000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i ++] = c;
ffffffffc0200114:	6522                	ld	a0,8(sp)
ffffffffc0200116:	009b87b3          	add	a5,s7,s1
ffffffffc020011a:	2485                	addiw	s1,s1,1
ffffffffc020011c:	00a78023          	sb	a0,0(a5)
ffffffffc0200120:	bf7d                	j	ffffffffc02000de <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200122:	01550463          	beq	a0,s5,ffffffffc020012a <readline+0x84>
ffffffffc0200126:	fb651ce3          	bne	a0,s6,ffffffffc02000de <readline+0x38>
            cputchar(c);
ffffffffc020012a:	0a0000ef          	jal	ra,ffffffffc02001ca <cputchar>
            buf[i] = '\0';
ffffffffc020012e:	00009517          	auipc	a0,0x9
ffffffffc0200132:	f0250513          	addi	a0,a0,-254 # ffffffffc0209030 <buf>
ffffffffc0200136:	94aa                	add	s1,s1,a0
ffffffffc0200138:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020013c:	60a6                	ld	ra,72(sp)
ffffffffc020013e:	6486                	ld	s1,64(sp)
ffffffffc0200140:	7962                	ld	s2,56(sp)
ffffffffc0200142:	79c2                	ld	s3,48(sp)
ffffffffc0200144:	7a22                	ld	s4,40(sp)
ffffffffc0200146:	7a82                	ld	s5,32(sp)
ffffffffc0200148:	6b62                	ld	s6,24(sp)
ffffffffc020014a:	6bc2                	ld	s7,16(sp)
ffffffffc020014c:	6161                	addi	sp,sp,80
ffffffffc020014e:	8082                	ret
            cputchar(c);
ffffffffc0200150:	4521                	li	a0,8
ffffffffc0200152:	078000ef          	jal	ra,ffffffffc02001ca <cputchar>
            i --;
ffffffffc0200156:	34fd                	addiw	s1,s1,-1
ffffffffc0200158:	b759                	j	ffffffffc02000de <readline+0x38>

ffffffffc020015a <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015a:	1141                	addi	sp,sp,-16
ffffffffc020015c:	e022                	sd	s0,0(sp)
ffffffffc020015e:	e406                	sd	ra,8(sp)
ffffffffc0200160:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200162:	3a8000ef          	jal	ra,ffffffffc020050a <cons_putc>
    (*cnt)++;
ffffffffc0200166:	401c                	lw	a5,0(s0)
}
ffffffffc0200168:	60a2                	ld	ra,8(sp)
    (*cnt)++;
ffffffffc020016a:	2785                	addiw	a5,a5,1
ffffffffc020016c:	c01c                	sw	a5,0(s0)
}
ffffffffc020016e:	6402                	ld	s0,0(sp)
ffffffffc0200170:	0141                	addi	sp,sp,16
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe050513          	addi	a0,a0,-32 # ffffffffc020015a <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	08b030ef          	jal	ra,ffffffffc0203a12 <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40 # ffffffffc0208028 <boot_page_table_sv39+0x28>
{
ffffffffc020019a:	8e2a                	mv	t3,a0
ffffffffc020019c:	f42e                	sd	a1,40(sp)
ffffffffc020019e:	f832                	sd	a2,48(sp)
ffffffffc02001a0:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a2:	00000517          	auipc	a0,0x0
ffffffffc02001a6:	fb850513          	addi	a0,a0,-72 # ffffffffc020015a <cputch>
ffffffffc02001aa:	004c                	addi	a1,sp,4
ffffffffc02001ac:	869a                	mv	a3,t1
ffffffffc02001ae:	8672                	mv	a2,t3
{
ffffffffc02001b0:	ec06                	sd	ra,24(sp)
ffffffffc02001b2:	e0ba                	sd	a4,64(sp)
ffffffffc02001b4:	e4be                	sd	a5,72(sp)
ffffffffc02001b6:	e8c2                	sd	a6,80(sp)
ffffffffc02001b8:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001bc:	c202                	sw	zero,4(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001be:	055030ef          	jal	ra,ffffffffc0203a12 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c2:	60e2                	ld	ra,24(sp)
ffffffffc02001c4:	4512                	lw	a0,4(sp)
ffffffffc02001c6:	6125                	addi	sp,sp,96
ffffffffc02001c8:	8082                	ret

ffffffffc02001ca <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001ca:	a681                	j	ffffffffc020050a <cons_putc>

ffffffffc02001cc <getchar>:
}

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc02001cc:	1141                	addi	sp,sp,-16
ffffffffc02001ce:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02001d0:	36e000ef          	jal	ra,ffffffffc020053e <cons_getc>
ffffffffc02001d4:	dd75                	beqz	a0,ffffffffc02001d0 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc02001d6:	60a2                	ld	ra,8(sp)
ffffffffc02001d8:	0141                	addi	sp,sp,16
ffffffffc02001da:	8082                	ret

ffffffffc02001dc <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc02001dc:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001de:	00004517          	auipc	a0,0x4
ffffffffc02001e2:	cda50513          	addi	a0,a0,-806 # ffffffffc0203eb8 <etext+0x34>
{
ffffffffc02001e6:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001e8:	fadff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc02001ec:	00000597          	auipc	a1,0x0
ffffffffc02001f0:	e5e58593          	addi	a1,a1,-418 # ffffffffc020004a <kern_init>
ffffffffc02001f4:	00004517          	auipc	a0,0x4
ffffffffc02001f8:	ce450513          	addi	a0,a0,-796 # ffffffffc0203ed8 <etext+0x54>
ffffffffc02001fc:	f99ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200200:	00004597          	auipc	a1,0x4
ffffffffc0200204:	c8458593          	addi	a1,a1,-892 # ffffffffc0203e84 <etext>
ffffffffc0200208:	00004517          	auipc	a0,0x4
ffffffffc020020c:	cf050513          	addi	a0,a0,-784 # ffffffffc0203ef8 <etext+0x74>
ffffffffc0200210:	f85ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200214:	00009597          	auipc	a1,0x9
ffffffffc0200218:	e1c58593          	addi	a1,a1,-484 # ffffffffc0209030 <buf>
ffffffffc020021c:	00004517          	auipc	a0,0x4
ffffffffc0200220:	cfc50513          	addi	a0,a0,-772 # ffffffffc0203f18 <etext+0x94>
ffffffffc0200224:	f71ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200228:	0000d597          	auipc	a1,0xd
ffffffffc020022c:	2c458593          	addi	a1,a1,708 # ffffffffc020d4ec <end>
ffffffffc0200230:	00004517          	auipc	a0,0x4
ffffffffc0200234:	d0850513          	addi	a0,a0,-760 # ffffffffc0203f38 <etext+0xb4>
ffffffffc0200238:	f5dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020023c:	0000d597          	auipc	a1,0xd
ffffffffc0200240:	6af58593          	addi	a1,a1,1711 # ffffffffc020d8eb <end+0x3ff>
ffffffffc0200244:	00000797          	auipc	a5,0x0
ffffffffc0200248:	e0678793          	addi	a5,a5,-506 # ffffffffc020004a <kern_init>
ffffffffc020024c:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200250:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200254:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200256:	3ff5f593          	andi	a1,a1,1023
ffffffffc020025a:	95be                	add	a1,a1,a5
ffffffffc020025c:	85a9                	srai	a1,a1,0xa
ffffffffc020025e:	00004517          	auipc	a0,0x4
ffffffffc0200262:	cfa50513          	addi	a0,a0,-774 # ffffffffc0203f58 <etext+0xd4>
}
ffffffffc0200266:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200268:	b735                	j	ffffffffc0200194 <cprintf>

ffffffffc020026a <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc020026a:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc020026c:	00004617          	auipc	a2,0x4
ffffffffc0200270:	d1c60613          	addi	a2,a2,-740 # ffffffffc0203f88 <etext+0x104>
ffffffffc0200274:	04900593          	li	a1,73
ffffffffc0200278:	00004517          	auipc	a0,0x4
ffffffffc020027c:	d2850513          	addi	a0,a0,-728 # ffffffffc0203fa0 <etext+0x11c>
{
ffffffffc0200280:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200282:	1d8000ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0200286 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200286:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200288:	00004617          	auipc	a2,0x4
ffffffffc020028c:	d3060613          	addi	a2,a2,-720 # ffffffffc0203fb8 <etext+0x134>
ffffffffc0200290:	00004597          	auipc	a1,0x4
ffffffffc0200294:	d4858593          	addi	a1,a1,-696 # ffffffffc0203fd8 <etext+0x154>
ffffffffc0200298:	00004517          	auipc	a0,0x4
ffffffffc020029c:	d4850513          	addi	a0,a0,-696 # ffffffffc0203fe0 <etext+0x15c>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002a0:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002a2:	ef3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002a6:	00004617          	auipc	a2,0x4
ffffffffc02002aa:	d4a60613          	addi	a2,a2,-694 # ffffffffc0203ff0 <etext+0x16c>
ffffffffc02002ae:	00004597          	auipc	a1,0x4
ffffffffc02002b2:	d6a58593          	addi	a1,a1,-662 # ffffffffc0204018 <etext+0x194>
ffffffffc02002b6:	00004517          	auipc	a0,0x4
ffffffffc02002ba:	d2a50513          	addi	a0,a0,-726 # ffffffffc0203fe0 <etext+0x15c>
ffffffffc02002be:	ed7ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02002c2:	00004617          	auipc	a2,0x4
ffffffffc02002c6:	d6660613          	addi	a2,a2,-666 # ffffffffc0204028 <etext+0x1a4>
ffffffffc02002ca:	00004597          	auipc	a1,0x4
ffffffffc02002ce:	d7e58593          	addi	a1,a1,-642 # ffffffffc0204048 <etext+0x1c4>
ffffffffc02002d2:	00004517          	auipc	a0,0x4
ffffffffc02002d6:	d0e50513          	addi	a0,a0,-754 # ffffffffc0203fe0 <etext+0x15c>
ffffffffc02002da:	ebbff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    return 0;
}
ffffffffc02002de:	60a2                	ld	ra,8(sp)
ffffffffc02002e0:	4501                	li	a0,0
ffffffffc02002e2:	0141                	addi	sp,sp,16
ffffffffc02002e4:	8082                	ret

ffffffffc02002e6 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e6:	1141                	addi	sp,sp,-16
ffffffffc02002e8:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002ea:	ef3ff0ef          	jal	ra,ffffffffc02001dc <print_kerninfo>
    return 0;
}
ffffffffc02002ee:	60a2                	ld	ra,8(sp)
ffffffffc02002f0:	4501                	li	a0,0
ffffffffc02002f2:	0141                	addi	sp,sp,16
ffffffffc02002f4:	8082                	ret

ffffffffc02002f6 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002f6:	1141                	addi	sp,sp,-16
ffffffffc02002f8:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002fa:	f71ff0ef          	jal	ra,ffffffffc020026a <print_stackframe>
    return 0;
}
ffffffffc02002fe:	60a2                	ld	ra,8(sp)
ffffffffc0200300:	4501                	li	a0,0
ffffffffc0200302:	0141                	addi	sp,sp,16
ffffffffc0200304:	8082                	ret

ffffffffc0200306 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200306:	7115                	addi	sp,sp,-224
ffffffffc0200308:	ed5e                	sd	s7,152(sp)
ffffffffc020030a:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020030c:	00004517          	auipc	a0,0x4
ffffffffc0200310:	d4c50513          	addi	a0,a0,-692 # ffffffffc0204058 <etext+0x1d4>
kmonitor(struct trapframe *tf) {
ffffffffc0200314:	ed86                	sd	ra,216(sp)
ffffffffc0200316:	e9a2                	sd	s0,208(sp)
ffffffffc0200318:	e5a6                	sd	s1,200(sp)
ffffffffc020031a:	e1ca                	sd	s2,192(sp)
ffffffffc020031c:	fd4e                	sd	s3,184(sp)
ffffffffc020031e:	f952                	sd	s4,176(sp)
ffffffffc0200320:	f556                	sd	s5,168(sp)
ffffffffc0200322:	f15a                	sd	s6,160(sp)
ffffffffc0200324:	e962                	sd	s8,144(sp)
ffffffffc0200326:	e566                	sd	s9,136(sp)
ffffffffc0200328:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020032a:	e6bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020032e:	00004517          	auipc	a0,0x4
ffffffffc0200332:	d5250513          	addi	a0,a0,-686 # ffffffffc0204080 <etext+0x1fc>
ffffffffc0200336:	e5fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    if (tf != NULL) {
ffffffffc020033a:	000b8563          	beqz	s7,ffffffffc0200344 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020033e:	855e                	mv	a0,s7
ffffffffc0200340:	7d8000ef          	jal	ra,ffffffffc0200b18 <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200344:	4501                	li	a0,0
ffffffffc0200346:	4581                	li	a1,0
ffffffffc0200348:	4601                	li	a2,0
ffffffffc020034a:	48a1                	li	a7,8
ffffffffc020034c:	00000073          	ecall
ffffffffc0200350:	00004c17          	auipc	s8,0x4
ffffffffc0200354:	da0c0c13          	addi	s8,s8,-608 # ffffffffc02040f0 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200358:	00004917          	auipc	s2,0x4
ffffffffc020035c:	d5090913          	addi	s2,s2,-688 # ffffffffc02040a8 <etext+0x224>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200360:	00004497          	auipc	s1,0x4
ffffffffc0200364:	d5048493          	addi	s1,s1,-688 # ffffffffc02040b0 <etext+0x22c>
        if (argc == MAXARGS - 1) {
ffffffffc0200368:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020036a:	00004b17          	auipc	s6,0x4
ffffffffc020036e:	d4eb0b13          	addi	s6,s6,-690 # ffffffffc02040b8 <etext+0x234>
        argv[argc ++] = buf;
ffffffffc0200372:	00004a17          	auipc	s4,0x4
ffffffffc0200376:	c66a0a13          	addi	s4,s4,-922 # ffffffffc0203fd8 <etext+0x154>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020037a:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020037c:	854a                	mv	a0,s2
ffffffffc020037e:	d29ff0ef          	jal	ra,ffffffffc02000a6 <readline>
ffffffffc0200382:	842a                	mv	s0,a0
ffffffffc0200384:	dd65                	beqz	a0,ffffffffc020037c <kmonitor+0x76>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200386:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020038a:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020038c:	e1bd                	bnez	a1,ffffffffc02003f2 <kmonitor+0xec>
    if (argc == 0) {
ffffffffc020038e:	fe0c87e3          	beqz	s9,ffffffffc020037c <kmonitor+0x76>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200392:	6582                	ld	a1,0(sp)
ffffffffc0200394:	00004d17          	auipc	s10,0x4
ffffffffc0200398:	d5cd0d13          	addi	s10,s10,-676 # ffffffffc02040f0 <commands>
        argv[argc ++] = buf;
ffffffffc020039c:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020039e:	4401                	li	s0,0
ffffffffc02003a0:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003a2:	23b030ef          	jal	ra,ffffffffc0203ddc <strcmp>
ffffffffc02003a6:	c919                	beqz	a0,ffffffffc02003bc <kmonitor+0xb6>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003a8:	2405                	addiw	s0,s0,1
ffffffffc02003aa:	0b540063          	beq	s0,s5,ffffffffc020044a <kmonitor+0x144>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ae:	000d3503          	ld	a0,0(s10)
ffffffffc02003b2:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003b4:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003b6:	227030ef          	jal	ra,ffffffffc0203ddc <strcmp>
ffffffffc02003ba:	f57d                	bnez	a0,ffffffffc02003a8 <kmonitor+0xa2>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003bc:	00141793          	slli	a5,s0,0x1
ffffffffc02003c0:	97a2                	add	a5,a5,s0
ffffffffc02003c2:	078e                	slli	a5,a5,0x3
ffffffffc02003c4:	97e2                	add	a5,a5,s8
ffffffffc02003c6:	6b9c                	ld	a5,16(a5)
ffffffffc02003c8:	865e                	mv	a2,s7
ffffffffc02003ca:	002c                	addi	a1,sp,8
ffffffffc02003cc:	fffc851b          	addiw	a0,s9,-1
ffffffffc02003d0:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003d2:	fa0555e3          	bgez	a0,ffffffffc020037c <kmonitor+0x76>
}
ffffffffc02003d6:	60ee                	ld	ra,216(sp)
ffffffffc02003d8:	644e                	ld	s0,208(sp)
ffffffffc02003da:	64ae                	ld	s1,200(sp)
ffffffffc02003dc:	690e                	ld	s2,192(sp)
ffffffffc02003de:	79ea                	ld	s3,184(sp)
ffffffffc02003e0:	7a4a                	ld	s4,176(sp)
ffffffffc02003e2:	7aaa                	ld	s5,168(sp)
ffffffffc02003e4:	7b0a                	ld	s6,160(sp)
ffffffffc02003e6:	6bea                	ld	s7,152(sp)
ffffffffc02003e8:	6c4a                	ld	s8,144(sp)
ffffffffc02003ea:	6caa                	ld	s9,136(sp)
ffffffffc02003ec:	6d0a                	ld	s10,128(sp)
ffffffffc02003ee:	612d                	addi	sp,sp,224
ffffffffc02003f0:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003f2:	8526                	mv	a0,s1
ffffffffc02003f4:	22d030ef          	jal	ra,ffffffffc0203e20 <strchr>
ffffffffc02003f8:	c901                	beqz	a0,ffffffffc0200408 <kmonitor+0x102>
ffffffffc02003fa:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003fe:	00040023          	sb	zero,0(s0)
ffffffffc0200402:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200404:	d5c9                	beqz	a1,ffffffffc020038e <kmonitor+0x88>
ffffffffc0200406:	b7f5                	j	ffffffffc02003f2 <kmonitor+0xec>
        if (*buf == '\0') {
ffffffffc0200408:	00044783          	lbu	a5,0(s0)
ffffffffc020040c:	d3c9                	beqz	a5,ffffffffc020038e <kmonitor+0x88>
        if (argc == MAXARGS - 1) {
ffffffffc020040e:	033c8963          	beq	s9,s3,ffffffffc0200440 <kmonitor+0x13a>
        argv[argc ++] = buf;
ffffffffc0200412:	003c9793          	slli	a5,s9,0x3
ffffffffc0200416:	0118                	addi	a4,sp,128
ffffffffc0200418:	97ba                	add	a5,a5,a4
ffffffffc020041a:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020041e:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200422:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200424:	e591                	bnez	a1,ffffffffc0200430 <kmonitor+0x12a>
ffffffffc0200426:	b7b5                	j	ffffffffc0200392 <kmonitor+0x8c>
ffffffffc0200428:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc020042c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020042e:	d1a5                	beqz	a1,ffffffffc020038e <kmonitor+0x88>
ffffffffc0200430:	8526                	mv	a0,s1
ffffffffc0200432:	1ef030ef          	jal	ra,ffffffffc0203e20 <strchr>
ffffffffc0200436:	d96d                	beqz	a0,ffffffffc0200428 <kmonitor+0x122>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200438:	00044583          	lbu	a1,0(s0)
ffffffffc020043c:	d9a9                	beqz	a1,ffffffffc020038e <kmonitor+0x88>
ffffffffc020043e:	bf55                	j	ffffffffc02003f2 <kmonitor+0xec>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200440:	45c1                	li	a1,16
ffffffffc0200442:	855a                	mv	a0,s6
ffffffffc0200444:	d51ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc0200448:	b7e9                	j	ffffffffc0200412 <kmonitor+0x10c>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc020044a:	6582                	ld	a1,0(sp)
ffffffffc020044c:	00004517          	auipc	a0,0x4
ffffffffc0200450:	c8c50513          	addi	a0,a0,-884 # ffffffffc02040d8 <etext+0x254>
ffffffffc0200454:	d41ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
ffffffffc0200458:	b715                	j	ffffffffc020037c <kmonitor+0x76>

ffffffffc020045a <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc020045a:	0000d317          	auipc	t1,0xd
ffffffffc020045e:	00e30313          	addi	t1,t1,14 # ffffffffc020d468 <is_panic>
ffffffffc0200462:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200466:	715d                	addi	sp,sp,-80
ffffffffc0200468:	ec06                	sd	ra,24(sp)
ffffffffc020046a:	e822                	sd	s0,16(sp)
ffffffffc020046c:	f436                	sd	a3,40(sp)
ffffffffc020046e:	f83a                	sd	a4,48(sp)
ffffffffc0200470:	fc3e                	sd	a5,56(sp)
ffffffffc0200472:	e0c2                	sd	a6,64(sp)
ffffffffc0200474:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200476:	020e1a63          	bnez	t3,ffffffffc02004aa <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc020047a:	4785                	li	a5,1
ffffffffc020047c:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200480:	8432                	mv	s0,a2
ffffffffc0200482:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200484:	862e                	mv	a2,a1
ffffffffc0200486:	85aa                	mv	a1,a0
ffffffffc0200488:	00004517          	auipc	a0,0x4
ffffffffc020048c:	cb050513          	addi	a0,a0,-848 # ffffffffc0204138 <commands+0x48>
    va_start(ap, fmt);
ffffffffc0200490:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200492:	d03ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200496:	65a2                	ld	a1,8(sp)
ffffffffc0200498:	8522                	mv	a0,s0
ffffffffc020049a:	cdbff0ef          	jal	ra,ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc020049e:	00005517          	auipc	a0,0x5
ffffffffc02004a2:	c3a50513          	addi	a0,a0,-966 # ffffffffc02050d8 <default_pmm_manager+0x530>
ffffffffc02004a6:	cefff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02004aa:	486000ef          	jal	ra,ffffffffc0200930 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004ae:	4501                	li	a0,0
ffffffffc02004b0:	e57ff0ef          	jal	ra,ffffffffc0200306 <kmonitor>
    while (1) {
ffffffffc02004b4:	bfed                	j	ffffffffc02004ae <__panic+0x54>

ffffffffc02004b6 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02004b6:	67e1                	lui	a5,0x18
ffffffffc02004b8:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02004bc:	0000d717          	auipc	a4,0xd
ffffffffc02004c0:	faf73e23          	sd	a5,-68(a4) # ffffffffc020d478 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02004c4:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc02004c8:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004ca:	953e                	add	a0,a0,a5
ffffffffc02004cc:	4601                	li	a2,0
ffffffffc02004ce:	4881                	li	a7,0
ffffffffc02004d0:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc02004d4:	02000793          	li	a5,32
ffffffffc02004d8:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc02004dc:	00004517          	auipc	a0,0x4
ffffffffc02004e0:	c7c50513          	addi	a0,a0,-900 # ffffffffc0204158 <commands+0x68>
    ticks = 0;
ffffffffc02004e4:	0000d797          	auipc	a5,0xd
ffffffffc02004e8:	f807b623          	sd	zero,-116(a5) # ffffffffc020d470 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc02004ec:	b165                	j	ffffffffc0200194 <cprintf>

ffffffffc02004ee <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02004ee:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004f2:	0000d797          	auipc	a5,0xd
ffffffffc02004f6:	f867b783          	ld	a5,-122(a5) # ffffffffc020d478 <timebase>
ffffffffc02004fa:	953e                	add	a0,a0,a5
ffffffffc02004fc:	4581                	li	a1,0
ffffffffc02004fe:	4601                	li	a2,0
ffffffffc0200500:	4881                	li	a7,0
ffffffffc0200502:	00000073          	ecall
ffffffffc0200506:	8082                	ret

ffffffffc0200508 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200508:	8082                	ret

ffffffffc020050a <cons_putc>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020050a:	100027f3          	csrr	a5,sstatus
ffffffffc020050e:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200510:	0ff57513          	zext.b	a0,a0
ffffffffc0200514:	e799                	bnez	a5,ffffffffc0200522 <cons_putc+0x18>
ffffffffc0200516:	4581                	li	a1,0
ffffffffc0200518:	4601                	li	a2,0
ffffffffc020051a:	4885                	li	a7,1
ffffffffc020051c:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc0200520:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200522:	1101                	addi	sp,sp,-32
ffffffffc0200524:	ec06                	sd	ra,24(sp)
ffffffffc0200526:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200528:	408000ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc020052c:	6522                	ld	a0,8(sp)
ffffffffc020052e:	4581                	li	a1,0
ffffffffc0200530:	4601                	li	a2,0
ffffffffc0200532:	4885                	li	a7,1
ffffffffc0200534:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200538:	60e2                	ld	ra,24(sp)
ffffffffc020053a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020053c:	a6fd                	j	ffffffffc020092a <intr_enable>

ffffffffc020053e <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020053e:	100027f3          	csrr	a5,sstatus
ffffffffc0200542:	8b89                	andi	a5,a5,2
ffffffffc0200544:	eb89                	bnez	a5,ffffffffc0200556 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200546:	4501                	li	a0,0
ffffffffc0200548:	4581                	li	a1,0
ffffffffc020054a:	4601                	li	a2,0
ffffffffc020054c:	4889                	li	a7,2
ffffffffc020054e:	00000073          	ecall
ffffffffc0200552:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200554:	8082                	ret
int cons_getc(void) {
ffffffffc0200556:	1101                	addi	sp,sp,-32
ffffffffc0200558:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc020055a:	3d6000ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc020055e:	4501                	li	a0,0
ffffffffc0200560:	4581                	li	a1,0
ffffffffc0200562:	4601                	li	a2,0
ffffffffc0200564:	4889                	li	a7,2
ffffffffc0200566:	00000073          	ecall
ffffffffc020056a:	2501                	sext.w	a0,a0
ffffffffc020056c:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020056e:	3bc000ef          	jal	ra,ffffffffc020092a <intr_enable>
}
ffffffffc0200572:	60e2                	ld	ra,24(sp)
ffffffffc0200574:	6522                	ld	a0,8(sp)
ffffffffc0200576:	6105                	addi	sp,sp,32
ffffffffc0200578:	8082                	ret

ffffffffc020057a <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020057a:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc020057c:	00004517          	auipc	a0,0x4
ffffffffc0200580:	bfc50513          	addi	a0,a0,-1028 # ffffffffc0204178 <commands+0x88>
void dtb_init(void) {
ffffffffc0200584:	fc86                	sd	ra,120(sp)
ffffffffc0200586:	f8a2                	sd	s0,112(sp)
ffffffffc0200588:	e8d2                	sd	s4,80(sp)
ffffffffc020058a:	f4a6                	sd	s1,104(sp)
ffffffffc020058c:	f0ca                	sd	s2,96(sp)
ffffffffc020058e:	ecce                	sd	s3,88(sp)
ffffffffc0200590:	e4d6                	sd	s5,72(sp)
ffffffffc0200592:	e0da                	sd	s6,64(sp)
ffffffffc0200594:	fc5e                	sd	s7,56(sp)
ffffffffc0200596:	f862                	sd	s8,48(sp)
ffffffffc0200598:	f466                	sd	s9,40(sp)
ffffffffc020059a:	f06a                	sd	s10,32(sp)
ffffffffc020059c:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc020059e:	bf7ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005a2:	00009597          	auipc	a1,0x9
ffffffffc02005a6:	a5e5b583          	ld	a1,-1442(a1) # ffffffffc0209000 <boot_hartid>
ffffffffc02005aa:	00004517          	auipc	a0,0x4
ffffffffc02005ae:	bde50513          	addi	a0,a0,-1058 # ffffffffc0204188 <commands+0x98>
ffffffffc02005b2:	be3ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005b6:	00009417          	auipc	s0,0x9
ffffffffc02005ba:	a5240413          	addi	s0,s0,-1454 # ffffffffc0209008 <boot_dtb>
ffffffffc02005be:	600c                	ld	a1,0(s0)
ffffffffc02005c0:	00004517          	auipc	a0,0x4
ffffffffc02005c4:	bd850513          	addi	a0,a0,-1064 # ffffffffc0204198 <commands+0xa8>
ffffffffc02005c8:	bcdff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02005cc:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02005d0:	00004517          	auipc	a0,0x4
ffffffffc02005d4:	be050513          	addi	a0,a0,-1056 # ffffffffc02041b0 <commands+0xc0>
    if (boot_dtb == 0) {
ffffffffc02005d8:	120a0463          	beqz	s4,ffffffffc0200700 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02005dc:	57f5                	li	a5,-3
ffffffffc02005de:	07fa                	slli	a5,a5,0x1e
ffffffffc02005e0:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02005e4:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005e6:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ea:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ec:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02005f0:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005f4:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005f8:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005fc:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200600:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200602:	8ec9                	or	a3,a3,a0
ffffffffc0200604:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200608:	1b7d                	addi	s6,s6,-1
ffffffffc020060a:	0167f7b3          	and	a5,a5,s6
ffffffffc020060e:	8dd5                	or	a1,a1,a3
ffffffffc0200610:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200612:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200616:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200618:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed2a01>
ffffffffc020061c:	10f59163          	bne	a1,a5,ffffffffc020071e <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc0200620:	471c                	lw	a5,8(a4)
ffffffffc0200622:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200624:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200626:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020062a:	0086d51b          	srliw	a0,a3,0x8
ffffffffc020062e:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200632:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200636:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020063a:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020063e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200642:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200646:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020064a:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020064e:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200650:	01146433          	or	s0,s0,a7
ffffffffc0200654:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200658:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020065c:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020065e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200662:	8c49                	or	s0,s0,a0
ffffffffc0200664:	0166f6b3          	and	a3,a3,s6
ffffffffc0200668:	00ca6a33          	or	s4,s4,a2
ffffffffc020066c:	0167f7b3          	and	a5,a5,s6
ffffffffc0200670:	8c55                	or	s0,s0,a3
ffffffffc0200672:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200676:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200678:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020067a:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020067c:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200680:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200682:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200684:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200688:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020068a:	00004917          	auipc	s2,0x4
ffffffffc020068e:	b7690913          	addi	s2,s2,-1162 # ffffffffc0204200 <commands+0x110>
ffffffffc0200692:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200694:	4d91                	li	s11,4
ffffffffc0200696:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200698:	00004497          	auipc	s1,0x4
ffffffffc020069c:	b6048493          	addi	s1,s1,-1184 # ffffffffc02041f8 <commands+0x108>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006a0:	000a2703          	lw	a4,0(s4)
ffffffffc02006a4:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a8:	0087569b          	srliw	a3,a4,0x8
ffffffffc02006ac:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b0:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b4:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b8:	0107571b          	srliw	a4,a4,0x10
ffffffffc02006bc:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006be:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c2:	0087171b          	slliw	a4,a4,0x8
ffffffffc02006c6:	8fd5                	or	a5,a5,a3
ffffffffc02006c8:	00eb7733          	and	a4,s6,a4
ffffffffc02006cc:	8fd9                	or	a5,a5,a4
ffffffffc02006ce:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02006d0:	09778c63          	beq	a5,s7,ffffffffc0200768 <dtb_init+0x1ee>
ffffffffc02006d4:	00fbea63          	bltu	s7,a5,ffffffffc02006e8 <dtb_init+0x16e>
ffffffffc02006d8:	07a78663          	beq	a5,s10,ffffffffc0200744 <dtb_init+0x1ca>
ffffffffc02006dc:	4709                	li	a4,2
ffffffffc02006de:	00e79763          	bne	a5,a4,ffffffffc02006ec <dtb_init+0x172>
ffffffffc02006e2:	4c81                	li	s9,0
ffffffffc02006e4:	8a56                	mv	s4,s5
ffffffffc02006e6:	bf6d                	j	ffffffffc02006a0 <dtb_init+0x126>
ffffffffc02006e8:	ffb78ee3          	beq	a5,s11,ffffffffc02006e4 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02006ec:	00004517          	auipc	a0,0x4
ffffffffc02006f0:	b8c50513          	addi	a0,a0,-1140 # ffffffffc0204278 <commands+0x188>
ffffffffc02006f4:	aa1ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02006f8:	00004517          	auipc	a0,0x4
ffffffffc02006fc:	bb850513          	addi	a0,a0,-1096 # ffffffffc02042b0 <commands+0x1c0>
}
ffffffffc0200700:	7446                	ld	s0,112(sp)
ffffffffc0200702:	70e6                	ld	ra,120(sp)
ffffffffc0200704:	74a6                	ld	s1,104(sp)
ffffffffc0200706:	7906                	ld	s2,96(sp)
ffffffffc0200708:	69e6                	ld	s3,88(sp)
ffffffffc020070a:	6a46                	ld	s4,80(sp)
ffffffffc020070c:	6aa6                	ld	s5,72(sp)
ffffffffc020070e:	6b06                	ld	s6,64(sp)
ffffffffc0200710:	7be2                	ld	s7,56(sp)
ffffffffc0200712:	7c42                	ld	s8,48(sp)
ffffffffc0200714:	7ca2                	ld	s9,40(sp)
ffffffffc0200716:	7d02                	ld	s10,32(sp)
ffffffffc0200718:	6de2                	ld	s11,24(sp)
ffffffffc020071a:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc020071c:	bca5                	j	ffffffffc0200194 <cprintf>
}
ffffffffc020071e:	7446                	ld	s0,112(sp)
ffffffffc0200720:	70e6                	ld	ra,120(sp)
ffffffffc0200722:	74a6                	ld	s1,104(sp)
ffffffffc0200724:	7906                	ld	s2,96(sp)
ffffffffc0200726:	69e6                	ld	s3,88(sp)
ffffffffc0200728:	6a46                	ld	s4,80(sp)
ffffffffc020072a:	6aa6                	ld	s5,72(sp)
ffffffffc020072c:	6b06                	ld	s6,64(sp)
ffffffffc020072e:	7be2                	ld	s7,56(sp)
ffffffffc0200730:	7c42                	ld	s8,48(sp)
ffffffffc0200732:	7ca2                	ld	s9,40(sp)
ffffffffc0200734:	7d02                	ld	s10,32(sp)
ffffffffc0200736:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200738:	00004517          	auipc	a0,0x4
ffffffffc020073c:	a9850513          	addi	a0,a0,-1384 # ffffffffc02041d0 <commands+0xe0>
}
ffffffffc0200740:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200742:	bc89                	j	ffffffffc0200194 <cprintf>
                int name_len = strlen(name);
ffffffffc0200744:	8556                	mv	a0,s5
ffffffffc0200746:	64e030ef          	jal	ra,ffffffffc0203d94 <strlen>
ffffffffc020074a:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020074c:	4619                	li	a2,6
ffffffffc020074e:	85a6                	mv	a1,s1
ffffffffc0200750:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200752:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200754:	6a6030ef          	jal	ra,ffffffffc0203dfa <strncmp>
ffffffffc0200758:	e111                	bnez	a0,ffffffffc020075c <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc020075a:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020075c:	0a91                	addi	s5,s5,4
ffffffffc020075e:	9ad2                	add	s5,s5,s4
ffffffffc0200760:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200764:	8a56                	mv	s4,s5
ffffffffc0200766:	bf2d                	j	ffffffffc02006a0 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200768:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc020076c:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200770:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200774:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200778:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020077c:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200780:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200784:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200788:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020078c:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200790:	00eaeab3          	or	s5,s5,a4
ffffffffc0200794:	00fb77b3          	and	a5,s6,a5
ffffffffc0200798:	00faeab3          	or	s5,s5,a5
ffffffffc020079c:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020079e:	000c9c63          	bnez	s9,ffffffffc02007b6 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02007a2:	1a82                	slli	s5,s5,0x20
ffffffffc02007a4:	00368793          	addi	a5,a3,3
ffffffffc02007a8:	020ada93          	srli	s5,s5,0x20
ffffffffc02007ac:	9abe                	add	s5,s5,a5
ffffffffc02007ae:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02007b2:	8a56                	mv	s4,s5
ffffffffc02007b4:	b5f5                	j	ffffffffc02006a0 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02007b6:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007ba:	85ca                	mv	a1,s2
ffffffffc02007bc:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007be:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007c2:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007c6:	0187971b          	slliw	a4,a5,0x18
ffffffffc02007ca:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007ce:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02007d2:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007d4:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007d8:	0087979b          	slliw	a5,a5,0x8
ffffffffc02007dc:	8d59                	or	a0,a0,a4
ffffffffc02007de:	00fb77b3          	and	a5,s6,a5
ffffffffc02007e2:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02007e4:	1502                	slli	a0,a0,0x20
ffffffffc02007e6:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007e8:	9522                	add	a0,a0,s0
ffffffffc02007ea:	5f2030ef          	jal	ra,ffffffffc0203ddc <strcmp>
ffffffffc02007ee:	66a2                	ld	a3,8(sp)
ffffffffc02007f0:	f94d                	bnez	a0,ffffffffc02007a2 <dtb_init+0x228>
ffffffffc02007f2:	fb59f8e3          	bgeu	s3,s5,ffffffffc02007a2 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02007f6:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02007fa:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007fe:	00004517          	auipc	a0,0x4
ffffffffc0200802:	a0a50513          	addi	a0,a0,-1526 # ffffffffc0204208 <commands+0x118>
           fdt32_to_cpu(x >> 32);
ffffffffc0200806:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080a:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc020080e:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200812:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200816:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020081a:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020081e:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200822:	0187d693          	srli	a3,a5,0x18
ffffffffc0200826:	01861f1b          	slliw	t5,a2,0x18
ffffffffc020082a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020082e:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200832:	0106561b          	srliw	a2,a2,0x10
ffffffffc0200836:	010f6f33          	or	t5,t5,a6
ffffffffc020083a:	0187529b          	srliw	t0,a4,0x18
ffffffffc020083e:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200842:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200846:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020084a:	0186f6b3          	and	a3,a3,s8
ffffffffc020084e:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200852:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200856:	0107581b          	srliw	a6,a4,0x10
ffffffffc020085a:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020085e:	8361                	srli	a4,a4,0x18
ffffffffc0200860:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200864:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200868:	01e6e6b3          	or	a3,a3,t5
ffffffffc020086c:	00cb7633          	and	a2,s6,a2
ffffffffc0200870:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200874:	0085959b          	slliw	a1,a1,0x8
ffffffffc0200878:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020087c:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200880:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200884:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200888:	0088989b          	slliw	a7,a7,0x8
ffffffffc020088c:	011b78b3          	and	a7,s6,a7
ffffffffc0200890:	005eeeb3          	or	t4,t4,t0
ffffffffc0200894:	00c6e733          	or	a4,a3,a2
ffffffffc0200898:	006c6c33          	or	s8,s8,t1
ffffffffc020089c:	010b76b3          	and	a3,s6,a6
ffffffffc02008a0:	00bb7b33          	and	s6,s6,a1
ffffffffc02008a4:	01d7e7b3          	or	a5,a5,t4
ffffffffc02008a8:	016c6b33          	or	s6,s8,s6
ffffffffc02008ac:	01146433          	or	s0,s0,a7
ffffffffc02008b0:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02008b2:	1702                	slli	a4,a4,0x20
ffffffffc02008b4:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02008b6:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02008b8:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02008ba:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02008bc:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02008c0:	0167eb33          	or	s6,a5,s6
ffffffffc02008c4:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc02008c6:	8cfff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02008ca:	85a2                	mv	a1,s0
ffffffffc02008cc:	00004517          	auipc	a0,0x4
ffffffffc02008d0:	95c50513          	addi	a0,a0,-1700 # ffffffffc0204228 <commands+0x138>
ffffffffc02008d4:	8c1ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02008d8:	014b5613          	srli	a2,s6,0x14
ffffffffc02008dc:	85da                	mv	a1,s6
ffffffffc02008de:	00004517          	auipc	a0,0x4
ffffffffc02008e2:	96250513          	addi	a0,a0,-1694 # ffffffffc0204240 <commands+0x150>
ffffffffc02008e6:	8afff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02008ea:	008b05b3          	add	a1,s6,s0
ffffffffc02008ee:	15fd                	addi	a1,a1,-1
ffffffffc02008f0:	00004517          	auipc	a0,0x4
ffffffffc02008f4:	97050513          	addi	a0,a0,-1680 # ffffffffc0204260 <commands+0x170>
ffffffffc02008f8:	89dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02008fc:	00004517          	auipc	a0,0x4
ffffffffc0200900:	9b450513          	addi	a0,a0,-1612 # ffffffffc02042b0 <commands+0x1c0>
        memory_base = mem_base;
ffffffffc0200904:	0000d797          	auipc	a5,0xd
ffffffffc0200908:	b687be23          	sd	s0,-1156(a5) # ffffffffc020d480 <memory_base>
        memory_size = mem_size;
ffffffffc020090c:	0000d797          	auipc	a5,0xd
ffffffffc0200910:	b767be23          	sd	s6,-1156(a5) # ffffffffc020d488 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200914:	b3f5                	j	ffffffffc0200700 <dtb_init+0x186>

ffffffffc0200916 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200916:	0000d517          	auipc	a0,0xd
ffffffffc020091a:	b6a53503          	ld	a0,-1174(a0) # ffffffffc020d480 <memory_base>
ffffffffc020091e:	8082                	ret

ffffffffc0200920 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200920:	0000d517          	auipc	a0,0xd
ffffffffc0200924:	b6853503          	ld	a0,-1176(a0) # ffffffffc020d488 <memory_size>
ffffffffc0200928:	8082                	ret

ffffffffc020092a <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020092a:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020092e:	8082                	ret

ffffffffc0200930 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200930:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200934:	8082                	ret

ffffffffc0200936 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc0200936:	8082                	ret

ffffffffc0200938 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200938:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020093c:	00000797          	auipc	a5,0x0
ffffffffc0200940:	39478793          	addi	a5,a5,916 # ffffffffc0200cd0 <__alltraps>
ffffffffc0200944:	10579073          	csrw	stvec,a5
}
ffffffffc0200948:	8082                	ret

ffffffffc020094a <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020094a:	610c                	ld	a1,0(a0)
{
ffffffffc020094c:	1141                	addi	sp,sp,-16
ffffffffc020094e:	e022                	sd	s0,0(sp)
ffffffffc0200950:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200952:	00004517          	auipc	a0,0x4
ffffffffc0200956:	97650513          	addi	a0,a0,-1674 # ffffffffc02042c8 <commands+0x1d8>
{
ffffffffc020095a:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020095c:	839ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200960:	640c                	ld	a1,8(s0)
ffffffffc0200962:	00004517          	auipc	a0,0x4
ffffffffc0200966:	97e50513          	addi	a0,a0,-1666 # ffffffffc02042e0 <commands+0x1f0>
ffffffffc020096a:	82bff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020096e:	680c                	ld	a1,16(s0)
ffffffffc0200970:	00004517          	auipc	a0,0x4
ffffffffc0200974:	98850513          	addi	a0,a0,-1656 # ffffffffc02042f8 <commands+0x208>
ffffffffc0200978:	81dff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc020097c:	6c0c                	ld	a1,24(s0)
ffffffffc020097e:	00004517          	auipc	a0,0x4
ffffffffc0200982:	99250513          	addi	a0,a0,-1646 # ffffffffc0204310 <commands+0x220>
ffffffffc0200986:	80fff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc020098a:	700c                	ld	a1,32(s0)
ffffffffc020098c:	00004517          	auipc	a0,0x4
ffffffffc0200990:	99c50513          	addi	a0,a0,-1636 # ffffffffc0204328 <commands+0x238>
ffffffffc0200994:	801ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200998:	740c                	ld	a1,40(s0)
ffffffffc020099a:	00004517          	auipc	a0,0x4
ffffffffc020099e:	9a650513          	addi	a0,a0,-1626 # ffffffffc0204340 <commands+0x250>
ffffffffc02009a2:	ff2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02009a6:	780c                	ld	a1,48(s0)
ffffffffc02009a8:	00004517          	auipc	a0,0x4
ffffffffc02009ac:	9b050513          	addi	a0,a0,-1616 # ffffffffc0204358 <commands+0x268>
ffffffffc02009b0:	fe4ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02009b4:	7c0c                	ld	a1,56(s0)
ffffffffc02009b6:	00004517          	auipc	a0,0x4
ffffffffc02009ba:	9ba50513          	addi	a0,a0,-1606 # ffffffffc0204370 <commands+0x280>
ffffffffc02009be:	fd6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02009c2:	602c                	ld	a1,64(s0)
ffffffffc02009c4:	00004517          	auipc	a0,0x4
ffffffffc02009c8:	9c450513          	addi	a0,a0,-1596 # ffffffffc0204388 <commands+0x298>
ffffffffc02009cc:	fc8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009d0:	642c                	ld	a1,72(s0)
ffffffffc02009d2:	00004517          	auipc	a0,0x4
ffffffffc02009d6:	9ce50513          	addi	a0,a0,-1586 # ffffffffc02043a0 <commands+0x2b0>
ffffffffc02009da:	fbaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009de:	682c                	ld	a1,80(s0)
ffffffffc02009e0:	00004517          	auipc	a0,0x4
ffffffffc02009e4:	9d850513          	addi	a0,a0,-1576 # ffffffffc02043b8 <commands+0x2c8>
ffffffffc02009e8:	facff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009ec:	6c2c                	ld	a1,88(s0)
ffffffffc02009ee:	00004517          	auipc	a0,0x4
ffffffffc02009f2:	9e250513          	addi	a0,a0,-1566 # ffffffffc02043d0 <commands+0x2e0>
ffffffffc02009f6:	f9eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02009fa:	702c                	ld	a1,96(s0)
ffffffffc02009fc:	00004517          	auipc	a0,0x4
ffffffffc0200a00:	9ec50513          	addi	a0,a0,-1556 # ffffffffc02043e8 <commands+0x2f8>
ffffffffc0200a04:	f90ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a08:	742c                	ld	a1,104(s0)
ffffffffc0200a0a:	00004517          	auipc	a0,0x4
ffffffffc0200a0e:	9f650513          	addi	a0,a0,-1546 # ffffffffc0204400 <commands+0x310>
ffffffffc0200a12:	f82ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200a16:	782c                	ld	a1,112(s0)
ffffffffc0200a18:	00004517          	auipc	a0,0x4
ffffffffc0200a1c:	a0050513          	addi	a0,a0,-1536 # ffffffffc0204418 <commands+0x328>
ffffffffc0200a20:	f74ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200a24:	7c2c                	ld	a1,120(s0)
ffffffffc0200a26:	00004517          	auipc	a0,0x4
ffffffffc0200a2a:	a0a50513          	addi	a0,a0,-1526 # ffffffffc0204430 <commands+0x340>
ffffffffc0200a2e:	f66ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a32:	604c                	ld	a1,128(s0)
ffffffffc0200a34:	00004517          	auipc	a0,0x4
ffffffffc0200a38:	a1450513          	addi	a0,a0,-1516 # ffffffffc0204448 <commands+0x358>
ffffffffc0200a3c:	f58ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a40:	644c                	ld	a1,136(s0)
ffffffffc0200a42:	00004517          	auipc	a0,0x4
ffffffffc0200a46:	a1e50513          	addi	a0,a0,-1506 # ffffffffc0204460 <commands+0x370>
ffffffffc0200a4a:	f4aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a4e:	684c                	ld	a1,144(s0)
ffffffffc0200a50:	00004517          	auipc	a0,0x4
ffffffffc0200a54:	a2850513          	addi	a0,a0,-1496 # ffffffffc0204478 <commands+0x388>
ffffffffc0200a58:	f3cff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a5c:	6c4c                	ld	a1,152(s0)
ffffffffc0200a5e:	00004517          	auipc	a0,0x4
ffffffffc0200a62:	a3250513          	addi	a0,a0,-1486 # ffffffffc0204490 <commands+0x3a0>
ffffffffc0200a66:	f2eff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a6a:	704c                	ld	a1,160(s0)
ffffffffc0200a6c:	00004517          	auipc	a0,0x4
ffffffffc0200a70:	a3c50513          	addi	a0,a0,-1476 # ffffffffc02044a8 <commands+0x3b8>
ffffffffc0200a74:	f20ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a78:	744c                	ld	a1,168(s0)
ffffffffc0200a7a:	00004517          	auipc	a0,0x4
ffffffffc0200a7e:	a4650513          	addi	a0,a0,-1466 # ffffffffc02044c0 <commands+0x3d0>
ffffffffc0200a82:	f12ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a86:	784c                	ld	a1,176(s0)
ffffffffc0200a88:	00004517          	auipc	a0,0x4
ffffffffc0200a8c:	a5050513          	addi	a0,a0,-1456 # ffffffffc02044d8 <commands+0x3e8>
ffffffffc0200a90:	f04ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200a94:	7c4c                	ld	a1,184(s0)
ffffffffc0200a96:	00004517          	auipc	a0,0x4
ffffffffc0200a9a:	a5a50513          	addi	a0,a0,-1446 # ffffffffc02044f0 <commands+0x400>
ffffffffc0200a9e:	ef6ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200aa2:	606c                	ld	a1,192(s0)
ffffffffc0200aa4:	00004517          	auipc	a0,0x4
ffffffffc0200aa8:	a6450513          	addi	a0,a0,-1436 # ffffffffc0204508 <commands+0x418>
ffffffffc0200aac:	ee8ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200ab0:	646c                	ld	a1,200(s0)
ffffffffc0200ab2:	00004517          	auipc	a0,0x4
ffffffffc0200ab6:	a6e50513          	addi	a0,a0,-1426 # ffffffffc0204520 <commands+0x430>
ffffffffc0200aba:	edaff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200abe:	686c                	ld	a1,208(s0)
ffffffffc0200ac0:	00004517          	auipc	a0,0x4
ffffffffc0200ac4:	a7850513          	addi	a0,a0,-1416 # ffffffffc0204538 <commands+0x448>
ffffffffc0200ac8:	eccff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200acc:	6c6c                	ld	a1,216(s0)
ffffffffc0200ace:	00004517          	auipc	a0,0x4
ffffffffc0200ad2:	a8250513          	addi	a0,a0,-1406 # ffffffffc0204550 <commands+0x460>
ffffffffc0200ad6:	ebeff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200ada:	706c                	ld	a1,224(s0)
ffffffffc0200adc:	00004517          	auipc	a0,0x4
ffffffffc0200ae0:	a8c50513          	addi	a0,a0,-1396 # ffffffffc0204568 <commands+0x478>
ffffffffc0200ae4:	eb0ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200ae8:	746c                	ld	a1,232(s0)
ffffffffc0200aea:	00004517          	auipc	a0,0x4
ffffffffc0200aee:	a9650513          	addi	a0,a0,-1386 # ffffffffc0204580 <commands+0x490>
ffffffffc0200af2:	ea2ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200af6:	786c                	ld	a1,240(s0)
ffffffffc0200af8:	00004517          	auipc	a0,0x4
ffffffffc0200afc:	aa050513          	addi	a0,a0,-1376 # ffffffffc0204598 <commands+0x4a8>
ffffffffc0200b00:	e94ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b04:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b06:	6402                	ld	s0,0(sp)
ffffffffc0200b08:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b0a:	00004517          	auipc	a0,0x4
ffffffffc0200b0e:	aa650513          	addi	a0,a0,-1370 # ffffffffc02045b0 <commands+0x4c0>
}
ffffffffc0200b12:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b14:	e80ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200b18 <print_trapframe>:
{
ffffffffc0200b18:	1141                	addi	sp,sp,-16
ffffffffc0200b1a:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b1c:	85aa                	mv	a1,a0
{
ffffffffc0200b1e:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b20:	00004517          	auipc	a0,0x4
ffffffffc0200b24:	aa850513          	addi	a0,a0,-1368 # ffffffffc02045c8 <commands+0x4d8>
{
ffffffffc0200b28:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b2a:	e6aff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200b2e:	8522                	mv	a0,s0
ffffffffc0200b30:	e1bff0ef          	jal	ra,ffffffffc020094a <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200b34:	10043583          	ld	a1,256(s0)
ffffffffc0200b38:	00004517          	auipc	a0,0x4
ffffffffc0200b3c:	aa850513          	addi	a0,a0,-1368 # ffffffffc02045e0 <commands+0x4f0>
ffffffffc0200b40:	e54ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b44:	10843583          	ld	a1,264(s0)
ffffffffc0200b48:	00004517          	auipc	a0,0x4
ffffffffc0200b4c:	ab050513          	addi	a0,a0,-1360 # ffffffffc02045f8 <commands+0x508>
ffffffffc0200b50:	e44ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200b54:	11043583          	ld	a1,272(s0)
ffffffffc0200b58:	00004517          	auipc	a0,0x4
ffffffffc0200b5c:	ab850513          	addi	a0,a0,-1352 # ffffffffc0204610 <commands+0x520>
ffffffffc0200b60:	e34ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b64:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b68:	6402                	ld	s0,0(sp)
ffffffffc0200b6a:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b6c:	00004517          	auipc	a0,0x4
ffffffffc0200b70:	abc50513          	addi	a0,a0,-1348 # ffffffffc0204628 <commands+0x538>
}
ffffffffc0200b74:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b76:	e1eff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200b7a <interrupt_handler>:

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200b7a:	11853783          	ld	a5,280(a0)
ffffffffc0200b7e:	472d                	li	a4,11
ffffffffc0200b80:	0786                	slli	a5,a5,0x1
ffffffffc0200b82:	8385                	srli	a5,a5,0x1
ffffffffc0200b84:	08f76363          	bltu	a4,a5,ffffffffc0200c0a <interrupt_handler+0x90>
ffffffffc0200b88:	00004717          	auipc	a4,0x4
ffffffffc0200b8c:	b8070713          	addi	a4,a4,-1152 # ffffffffc0204708 <commands+0x618>
ffffffffc0200b90:	078a                	slli	a5,a5,0x2
ffffffffc0200b92:	97ba                	add	a5,a5,a4
ffffffffc0200b94:	439c                	lw	a5,0(a5)
ffffffffc0200b96:	97ba                	add	a5,a5,a4
ffffffffc0200b98:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200b9a:	00004517          	auipc	a0,0x4
ffffffffc0200b9e:	b0650513          	addi	a0,a0,-1274 # ffffffffc02046a0 <commands+0x5b0>
ffffffffc0200ba2:	df2ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200ba6:	00004517          	auipc	a0,0x4
ffffffffc0200baa:	ada50513          	addi	a0,a0,-1318 # ffffffffc0204680 <commands+0x590>
ffffffffc0200bae:	de6ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200bb2:	00004517          	auipc	a0,0x4
ffffffffc0200bb6:	a8e50513          	addi	a0,a0,-1394 # ffffffffc0204640 <commands+0x550>
ffffffffc0200bba:	ddaff06f          	j	ffffffffc0200194 <cprintf>
        break;
    case IRQ_U_TIMER:
        cprintf("User Timer interrupt\n");
ffffffffc0200bbe:	00004517          	auipc	a0,0x4
ffffffffc0200bc2:	b0250513          	addi	a0,a0,-1278 # ffffffffc02046c0 <commands+0x5d0>
ffffffffc0200bc6:	dceff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200bca:	1141                	addi	sp,sp,-16
ffffffffc0200bcc:	e406                	sd	ra,8(sp)
        /*(1)设置下次时钟中断- clock_set_next_event()
         *(2)计数器（ticks）加一
         *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
         * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
         */
        clock_set_next_event();
ffffffffc0200bce:	921ff0ef          	jal	ra,ffffffffc02004ee <clock_set_next_event>
        ticks++;
ffffffffc0200bd2:	0000d797          	auipc	a5,0xd
ffffffffc0200bd6:	89e78793          	addi	a5,a5,-1890 # ffffffffc020d470 <ticks>
ffffffffc0200bda:	6398                	ld	a4,0(a5)
ffffffffc0200bdc:	0705                	addi	a4,a4,1
ffffffffc0200bde:	e398                	sd	a4,0(a5)
        static int num = 0;
        if (ticks % 100 == 0)
ffffffffc0200be0:	639c                	ld	a5,0(a5)
ffffffffc0200be2:	06400713          	li	a4,100
ffffffffc0200be6:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200bea:	c38d                	beqz	a5,ffffffffc0200c0c <interrupt_handler+0x92>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200bec:	60a2                	ld	ra,8(sp)
ffffffffc0200bee:	0141                	addi	sp,sp,16
ffffffffc0200bf0:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200bf2:	00004517          	auipc	a0,0x4
ffffffffc0200bf6:	af650513          	addi	a0,a0,-1290 # ffffffffc02046e8 <commands+0x5f8>
ffffffffc0200bfa:	d9aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200bfe:	00004517          	auipc	a0,0x4
ffffffffc0200c02:	a6250513          	addi	a0,a0,-1438 # ffffffffc0204660 <commands+0x570>
ffffffffc0200c06:	d8eff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200c0a:	b739                	j	ffffffffc0200b18 <print_trapframe>
            cprintf("100 ticks\n");
ffffffffc0200c0c:	00004517          	auipc	a0,0x4
ffffffffc0200c10:	acc50513          	addi	a0,a0,-1332 # ffffffffc02046d8 <commands+0x5e8>
ffffffffc0200c14:	d80ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
            num++;
ffffffffc0200c18:	0000d717          	auipc	a4,0xd
ffffffffc0200c1c:	87870713          	addi	a4,a4,-1928 # ffffffffc020d490 <num.0>
ffffffffc0200c20:	431c                	lw	a5,0(a4)
            if (num == 10)
ffffffffc0200c22:	46a9                	li	a3,10
            num++;
ffffffffc0200c24:	0017861b          	addiw	a2,a5,1
ffffffffc0200c28:	c310                	sw	a2,0(a4)
            if (num == 10)
ffffffffc0200c2a:	fcd611e3          	bne	a2,a3,ffffffffc0200bec <interrupt_handler+0x72>
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200c2e:	4501                	li	a0,0
ffffffffc0200c30:	4581                	li	a1,0
ffffffffc0200c32:	4601                	li	a2,0
ffffffffc0200c34:	48a1                	li	a7,8
ffffffffc0200c36:	00000073          	ecall
}
ffffffffc0200c3a:	bf4d                	j	ffffffffc0200bec <interrupt_handler+0x72>

ffffffffc0200c3c <exception_handler>:

void exception_handler(struct trapframe *tf)
{
    switch (tf->cause)
ffffffffc0200c3c:	11853783          	ld	a5,280(a0)
{
ffffffffc0200c40:	1141                	addi	sp,sp,-16
ffffffffc0200c42:	e022                	sd	s0,0(sp)
ffffffffc0200c44:	e406                	sd	ra,8(sp)
    switch (tf->cause)
ffffffffc0200c46:	470d                	li	a4,3
{
ffffffffc0200c48:	842a                	mv	s0,a0
    switch (tf->cause)
ffffffffc0200c4a:	04e78b63          	beq	a5,a4,ffffffffc0200ca0 <exception_handler+0x64>
ffffffffc0200c4e:	04f76163          	bltu	a4,a5,ffffffffc0200c90 <exception_handler+0x54>
ffffffffc0200c52:	4709                	li	a4,2
ffffffffc0200c54:	04e79263          	bne	a5,a4,ffffffffc0200c98 <exception_handler+0x5c>
        /* LAB3 CHALLENGE3   YOUR CODE :  */
        /*(1)输出指令异常类型（ Illegal instruction）
         *(2)输出异常指令地址
         *(3)更新 tf->epc寄存器
         */
        cprintf("Exception type: Illegal instruction\n");
ffffffffc0200c58:	00004517          	auipc	a0,0x4
ffffffffc0200c5c:	ae050513          	addi	a0,a0,-1312 # ffffffffc0204738 <commands+0x648>
ffffffffc0200c60:	d34ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
ffffffffc0200c64:	10843583          	ld	a1,264(s0)
ffffffffc0200c68:	00004517          	auipc	a0,0x4
ffffffffc0200c6c:	af850513          	addi	a0,a0,-1288 # ffffffffc0204760 <commands+0x670>
        /*(1)输出指令异常类型（ breakpoint）
         *(2)输出异常指令地址
         *(3)更新 tf->epc寄存器
         */
        cprintf("Exception type: breakpoint\n");
        cprintf("ebreak caught at 0x%08x\n", tf->epc);
ffffffffc0200c70:	d24ff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        tf->epc += 4; // 跳过当前指令继续执行
ffffffffc0200c74:	10843783          	ld	a5,264(s0)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c78:	60a2                	ld	ra,8(sp)
        cprintf("Exception tests completed.\n");
ffffffffc0200c7a:	00004517          	auipc	a0,0x4
ffffffffc0200c7e:	b0e50513          	addi	a0,a0,-1266 # ffffffffc0204788 <commands+0x698>
        tf->epc += 4; // 跳过当前指令继续执行
ffffffffc0200c82:	0791                	addi	a5,a5,4
ffffffffc0200c84:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200c88:	6402                	ld	s0,0(sp)
ffffffffc0200c8a:	0141                	addi	sp,sp,16
        cprintf("Exception tests completed.\n");
ffffffffc0200c8c:	d08ff06f          	j	ffffffffc0200194 <cprintf>
    switch (tf->cause)
ffffffffc0200c90:	17f1                	addi	a5,a5,-4
ffffffffc0200c92:	471d                	li	a4,7
ffffffffc0200c94:	02f76363          	bltu	a4,a5,ffffffffc0200cba <exception_handler+0x7e>
}
ffffffffc0200c98:	60a2                	ld	ra,8(sp)
ffffffffc0200c9a:	6402                	ld	s0,0(sp)
ffffffffc0200c9c:	0141                	addi	sp,sp,16
ffffffffc0200c9e:	8082                	ret
        cprintf("Exception type: breakpoint\n");
ffffffffc0200ca0:	00004517          	auipc	a0,0x4
ffffffffc0200ca4:	b0850513          	addi	a0,a0,-1272 # ffffffffc02047a8 <commands+0x6b8>
ffffffffc0200ca8:	cecff0ef          	jal	ra,ffffffffc0200194 <cprintf>
        cprintf("ebreak caught at 0x%08x\n", tf->epc);
ffffffffc0200cac:	10843583          	ld	a1,264(s0)
ffffffffc0200cb0:	00004517          	auipc	a0,0x4
ffffffffc0200cb4:	b1850513          	addi	a0,a0,-1256 # ffffffffc02047c8 <commands+0x6d8>
ffffffffc0200cb8:	bf65                	j	ffffffffc0200c70 <exception_handler+0x34>
}
ffffffffc0200cba:	6402                	ld	s0,0(sp)
ffffffffc0200cbc:	60a2                	ld	ra,8(sp)
ffffffffc0200cbe:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200cc0:	bda1                	j	ffffffffc0200b18 <print_trapframe>

ffffffffc0200cc2 <trap>:

static inline void trap_dispatch(struct trapframe *tf)
{
    if ((intptr_t)tf->cause < 0)
ffffffffc0200cc2:	11853783          	ld	a5,280(a0)
ffffffffc0200cc6:	0007c363          	bltz	a5,ffffffffc0200ccc <trap+0xa>
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
ffffffffc0200cca:	bf8d                	j	ffffffffc0200c3c <exception_handler>
        interrupt_handler(tf);
ffffffffc0200ccc:	b57d                	j	ffffffffc0200b7a <interrupt_handler>
	...

ffffffffc0200cd0 <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200cd0:	14011073          	csrw	sscratch,sp
ffffffffc0200cd4:	712d                	addi	sp,sp,-288
ffffffffc0200cd6:	e406                	sd	ra,8(sp)
ffffffffc0200cd8:	ec0e                	sd	gp,24(sp)
ffffffffc0200cda:	f012                	sd	tp,32(sp)
ffffffffc0200cdc:	f416                	sd	t0,40(sp)
ffffffffc0200cde:	f81a                	sd	t1,48(sp)
ffffffffc0200ce0:	fc1e                	sd	t2,56(sp)
ffffffffc0200ce2:	e0a2                	sd	s0,64(sp)
ffffffffc0200ce4:	e4a6                	sd	s1,72(sp)
ffffffffc0200ce6:	e8aa                	sd	a0,80(sp)
ffffffffc0200ce8:	ecae                	sd	a1,88(sp)
ffffffffc0200cea:	f0b2                	sd	a2,96(sp)
ffffffffc0200cec:	f4b6                	sd	a3,104(sp)
ffffffffc0200cee:	f8ba                	sd	a4,112(sp)
ffffffffc0200cf0:	fcbe                	sd	a5,120(sp)
ffffffffc0200cf2:	e142                	sd	a6,128(sp)
ffffffffc0200cf4:	e546                	sd	a7,136(sp)
ffffffffc0200cf6:	e94a                	sd	s2,144(sp)
ffffffffc0200cf8:	ed4e                	sd	s3,152(sp)
ffffffffc0200cfa:	f152                	sd	s4,160(sp)
ffffffffc0200cfc:	f556                	sd	s5,168(sp)
ffffffffc0200cfe:	f95a                	sd	s6,176(sp)
ffffffffc0200d00:	fd5e                	sd	s7,184(sp)
ffffffffc0200d02:	e1e2                	sd	s8,192(sp)
ffffffffc0200d04:	e5e6                	sd	s9,200(sp)
ffffffffc0200d06:	e9ea                	sd	s10,208(sp)
ffffffffc0200d08:	edee                	sd	s11,216(sp)
ffffffffc0200d0a:	f1f2                	sd	t3,224(sp)
ffffffffc0200d0c:	f5f6                	sd	t4,232(sp)
ffffffffc0200d0e:	f9fa                	sd	t5,240(sp)
ffffffffc0200d10:	fdfe                	sd	t6,248(sp)
ffffffffc0200d12:	14002473          	csrr	s0,sscratch
ffffffffc0200d16:	100024f3          	csrr	s1,sstatus
ffffffffc0200d1a:	14102973          	csrr	s2,sepc
ffffffffc0200d1e:	143029f3          	csrr	s3,stval
ffffffffc0200d22:	14202a73          	csrr	s4,scause
ffffffffc0200d26:	e822                	sd	s0,16(sp)
ffffffffc0200d28:	e226                	sd	s1,256(sp)
ffffffffc0200d2a:	e64a                	sd	s2,264(sp)
ffffffffc0200d2c:	ea4e                	sd	s3,272(sp)
ffffffffc0200d2e:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200d30:	850a                	mv	a0,sp
    jal trap
ffffffffc0200d32:	f91ff0ef          	jal	ra,ffffffffc0200cc2 <trap>

ffffffffc0200d36 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200d36:	6492                	ld	s1,256(sp)
ffffffffc0200d38:	6932                	ld	s2,264(sp)
ffffffffc0200d3a:	10049073          	csrw	sstatus,s1
ffffffffc0200d3e:	14191073          	csrw	sepc,s2
ffffffffc0200d42:	60a2                	ld	ra,8(sp)
ffffffffc0200d44:	61e2                	ld	gp,24(sp)
ffffffffc0200d46:	7202                	ld	tp,32(sp)
ffffffffc0200d48:	72a2                	ld	t0,40(sp)
ffffffffc0200d4a:	7342                	ld	t1,48(sp)
ffffffffc0200d4c:	73e2                	ld	t2,56(sp)
ffffffffc0200d4e:	6406                	ld	s0,64(sp)
ffffffffc0200d50:	64a6                	ld	s1,72(sp)
ffffffffc0200d52:	6546                	ld	a0,80(sp)
ffffffffc0200d54:	65e6                	ld	a1,88(sp)
ffffffffc0200d56:	7606                	ld	a2,96(sp)
ffffffffc0200d58:	76a6                	ld	a3,104(sp)
ffffffffc0200d5a:	7746                	ld	a4,112(sp)
ffffffffc0200d5c:	77e6                	ld	a5,120(sp)
ffffffffc0200d5e:	680a                	ld	a6,128(sp)
ffffffffc0200d60:	68aa                	ld	a7,136(sp)
ffffffffc0200d62:	694a                	ld	s2,144(sp)
ffffffffc0200d64:	69ea                	ld	s3,152(sp)
ffffffffc0200d66:	7a0a                	ld	s4,160(sp)
ffffffffc0200d68:	7aaa                	ld	s5,168(sp)
ffffffffc0200d6a:	7b4a                	ld	s6,176(sp)
ffffffffc0200d6c:	7bea                	ld	s7,184(sp)
ffffffffc0200d6e:	6c0e                	ld	s8,192(sp)
ffffffffc0200d70:	6cae                	ld	s9,200(sp)
ffffffffc0200d72:	6d4e                	ld	s10,208(sp)
ffffffffc0200d74:	6dee                	ld	s11,216(sp)
ffffffffc0200d76:	7e0e                	ld	t3,224(sp)
ffffffffc0200d78:	7eae                	ld	t4,232(sp)
ffffffffc0200d7a:	7f4e                	ld	t5,240(sp)
ffffffffc0200d7c:	7fee                	ld	t6,248(sp)
ffffffffc0200d7e:	6142                	ld	sp,16(sp)
    # go back from supervisor call
    sret
ffffffffc0200d80:	10200073          	sret

ffffffffc0200d84 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200d84:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200d86:	bf45                	j	ffffffffc0200d36 <__trapret>
	...

ffffffffc0200d8a <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200d8a:	00008797          	auipc	a5,0x8
ffffffffc0200d8e:	6a678793          	addi	a5,a5,1702 # ffffffffc0209430 <free_area>
ffffffffc0200d92:	e79c                	sd	a5,8(a5)
ffffffffc0200d94:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200d96:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200d9a:	8082                	ret

ffffffffc0200d9c <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200d9c:	00008517          	auipc	a0,0x8
ffffffffc0200da0:	6a456503          	lwu	a0,1700(a0) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200da4:	8082                	ret

ffffffffc0200da6 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200da6:	715d                	addi	sp,sp,-80
ffffffffc0200da8:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200daa:	00008417          	auipc	s0,0x8
ffffffffc0200dae:	68640413          	addi	s0,s0,1670 # ffffffffc0209430 <free_area>
ffffffffc0200db2:	641c                	ld	a5,8(s0)
ffffffffc0200db4:	e486                	sd	ra,72(sp)
ffffffffc0200db6:	fc26                	sd	s1,56(sp)
ffffffffc0200db8:	f84a                	sd	s2,48(sp)
ffffffffc0200dba:	f44e                	sd	s3,40(sp)
ffffffffc0200dbc:	f052                	sd	s4,32(sp)
ffffffffc0200dbe:	ec56                	sd	s5,24(sp)
ffffffffc0200dc0:	e85a                	sd	s6,16(sp)
ffffffffc0200dc2:	e45e                	sd	s7,8(sp)
ffffffffc0200dc4:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200dc6:	2a878d63          	beq	a5,s0,ffffffffc0201080 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc0200dca:	4481                	li	s1,0
ffffffffc0200dcc:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200dce:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200dd2:	8b09                	andi	a4,a4,2
ffffffffc0200dd4:	2a070a63          	beqz	a4,ffffffffc0201088 <default_check+0x2e2>
        count++, total += p->property;
ffffffffc0200dd8:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200ddc:	679c                	ld	a5,8(a5)
ffffffffc0200dde:	2905                	addiw	s2,s2,1
ffffffffc0200de0:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200de2:	fe8796e3          	bne	a5,s0,ffffffffc0200dce <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200de6:	89a6                	mv	s3,s1
ffffffffc0200de8:	6db000ef          	jal	ra,ffffffffc0201cc2 <nr_free_pages>
ffffffffc0200dec:	6f351e63          	bne	a0,s3,ffffffffc02014e8 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200df0:	4505                	li	a0,1
ffffffffc0200df2:	653000ef          	jal	ra,ffffffffc0201c44 <alloc_pages>
ffffffffc0200df6:	8aaa                	mv	s5,a0
ffffffffc0200df8:	42050863          	beqz	a0,ffffffffc0201228 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200dfc:	4505                	li	a0,1
ffffffffc0200dfe:	647000ef          	jal	ra,ffffffffc0201c44 <alloc_pages>
ffffffffc0200e02:	89aa                	mv	s3,a0
ffffffffc0200e04:	70050263          	beqz	a0,ffffffffc0201508 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200e08:	4505                	li	a0,1
ffffffffc0200e0a:	63b000ef          	jal	ra,ffffffffc0201c44 <alloc_pages>
ffffffffc0200e0e:	8a2a                	mv	s4,a0
ffffffffc0200e10:	48050c63          	beqz	a0,ffffffffc02012a8 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200e14:	293a8a63          	beq	s5,s3,ffffffffc02010a8 <default_check+0x302>
ffffffffc0200e18:	28aa8863          	beq	s5,a0,ffffffffc02010a8 <default_check+0x302>
ffffffffc0200e1c:	28a98663          	beq	s3,a0,ffffffffc02010a8 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200e20:	000aa783          	lw	a5,0(s5)
ffffffffc0200e24:	2a079263          	bnez	a5,ffffffffc02010c8 <default_check+0x322>
ffffffffc0200e28:	0009a783          	lw	a5,0(s3)
ffffffffc0200e2c:	28079e63          	bnez	a5,ffffffffc02010c8 <default_check+0x322>
ffffffffc0200e30:	411c                	lw	a5,0(a0)
ffffffffc0200e32:	28079b63          	bnez	a5,ffffffffc02010c8 <default_check+0x322>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200e36:	0000c797          	auipc	a5,0xc
ffffffffc0200e3a:	6827b783          	ld	a5,1666(a5) # ffffffffc020d4b8 <pages>
ffffffffc0200e3e:	40fa8733          	sub	a4,s5,a5
ffffffffc0200e42:	00005617          	auipc	a2,0x5
ffffffffc0200e46:	a7e63603          	ld	a2,-1410(a2) # ffffffffc02058c0 <nbase>
ffffffffc0200e4a:	8719                	srai	a4,a4,0x6
ffffffffc0200e4c:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200e4e:	0000c697          	auipc	a3,0xc
ffffffffc0200e52:	6626b683          	ld	a3,1634(a3) # ffffffffc020d4b0 <npage>
ffffffffc0200e56:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e58:	0732                	slli	a4,a4,0xc
ffffffffc0200e5a:	28d77763          	bgeu	a4,a3,ffffffffc02010e8 <default_check+0x342>
    return page - pages + nbase;
ffffffffc0200e5e:	40f98733          	sub	a4,s3,a5
ffffffffc0200e62:	8719                	srai	a4,a4,0x6
ffffffffc0200e64:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e66:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200e68:	4cd77063          	bgeu	a4,a3,ffffffffc0201328 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0200e6c:	40f507b3          	sub	a5,a0,a5
ffffffffc0200e70:	8799                	srai	a5,a5,0x6
ffffffffc0200e72:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e74:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200e76:	30d7f963          	bgeu	a5,a3,ffffffffc0201188 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0200e7a:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200e7c:	00043c03          	ld	s8,0(s0)
ffffffffc0200e80:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200e84:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200e88:	e400                	sd	s0,8(s0)
ffffffffc0200e8a:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200e8c:	00008797          	auipc	a5,0x8
ffffffffc0200e90:	5a07aa23          	sw	zero,1460(a5) # ffffffffc0209440 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200e94:	5b1000ef          	jal	ra,ffffffffc0201c44 <alloc_pages>
ffffffffc0200e98:	2c051863          	bnez	a0,ffffffffc0201168 <default_check+0x3c2>
    free_page(p0);
ffffffffc0200e9c:	4585                	li	a1,1
ffffffffc0200e9e:	8556                	mv	a0,s5
ffffffffc0200ea0:	5e3000ef          	jal	ra,ffffffffc0201c82 <free_pages>
    free_page(p1);
ffffffffc0200ea4:	4585                	li	a1,1
ffffffffc0200ea6:	854e                	mv	a0,s3
ffffffffc0200ea8:	5db000ef          	jal	ra,ffffffffc0201c82 <free_pages>
    free_page(p2);
ffffffffc0200eac:	4585                	li	a1,1
ffffffffc0200eae:	8552                	mv	a0,s4
ffffffffc0200eb0:	5d3000ef          	jal	ra,ffffffffc0201c82 <free_pages>
    assert(nr_free == 3);
ffffffffc0200eb4:	4818                	lw	a4,16(s0)
ffffffffc0200eb6:	478d                	li	a5,3
ffffffffc0200eb8:	28f71863          	bne	a4,a5,ffffffffc0201148 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ebc:	4505                	li	a0,1
ffffffffc0200ebe:	587000ef          	jal	ra,ffffffffc0201c44 <alloc_pages>
ffffffffc0200ec2:	89aa                	mv	s3,a0
ffffffffc0200ec4:	26050263          	beqz	a0,ffffffffc0201128 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ec8:	4505                	li	a0,1
ffffffffc0200eca:	57b000ef          	jal	ra,ffffffffc0201c44 <alloc_pages>
ffffffffc0200ece:	8aaa                	mv	s5,a0
ffffffffc0200ed0:	3a050c63          	beqz	a0,ffffffffc0201288 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ed4:	4505                	li	a0,1
ffffffffc0200ed6:	56f000ef          	jal	ra,ffffffffc0201c44 <alloc_pages>
ffffffffc0200eda:	8a2a                	mv	s4,a0
ffffffffc0200edc:	38050663          	beqz	a0,ffffffffc0201268 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0200ee0:	4505                	li	a0,1
ffffffffc0200ee2:	563000ef          	jal	ra,ffffffffc0201c44 <alloc_pages>
ffffffffc0200ee6:	36051163          	bnez	a0,ffffffffc0201248 <default_check+0x4a2>
    free_page(p0);
ffffffffc0200eea:	4585                	li	a1,1
ffffffffc0200eec:	854e                	mv	a0,s3
ffffffffc0200eee:	595000ef          	jal	ra,ffffffffc0201c82 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200ef2:	641c                	ld	a5,8(s0)
ffffffffc0200ef4:	20878a63          	beq	a5,s0,ffffffffc0201108 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0200ef8:	4505                	li	a0,1
ffffffffc0200efa:	54b000ef          	jal	ra,ffffffffc0201c44 <alloc_pages>
ffffffffc0200efe:	30a99563          	bne	s3,a0,ffffffffc0201208 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0200f02:	4505                	li	a0,1
ffffffffc0200f04:	541000ef          	jal	ra,ffffffffc0201c44 <alloc_pages>
ffffffffc0200f08:	2e051063          	bnez	a0,ffffffffc02011e8 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0200f0c:	481c                	lw	a5,16(s0)
ffffffffc0200f0e:	2a079d63          	bnez	a5,ffffffffc02011c8 <default_check+0x422>
    free_page(p);
ffffffffc0200f12:	854e                	mv	a0,s3
ffffffffc0200f14:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200f16:	01843023          	sd	s8,0(s0)
ffffffffc0200f1a:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200f1e:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200f22:	561000ef          	jal	ra,ffffffffc0201c82 <free_pages>
    free_page(p1);
ffffffffc0200f26:	4585                	li	a1,1
ffffffffc0200f28:	8556                	mv	a0,s5
ffffffffc0200f2a:	559000ef          	jal	ra,ffffffffc0201c82 <free_pages>
    free_page(p2);
ffffffffc0200f2e:	4585                	li	a1,1
ffffffffc0200f30:	8552                	mv	a0,s4
ffffffffc0200f32:	551000ef          	jal	ra,ffffffffc0201c82 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200f36:	4515                	li	a0,5
ffffffffc0200f38:	50d000ef          	jal	ra,ffffffffc0201c44 <alloc_pages>
ffffffffc0200f3c:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200f3e:	26050563          	beqz	a0,ffffffffc02011a8 <default_check+0x402>
ffffffffc0200f42:	651c                	ld	a5,8(a0)
ffffffffc0200f44:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200f46:	8b85                	andi	a5,a5,1
ffffffffc0200f48:	54079063          	bnez	a5,ffffffffc0201488 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200f4c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f4e:	00043b03          	ld	s6,0(s0)
ffffffffc0200f52:	00843a83          	ld	s5,8(s0)
ffffffffc0200f56:	e000                	sd	s0,0(s0)
ffffffffc0200f58:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200f5a:	4eb000ef          	jal	ra,ffffffffc0201c44 <alloc_pages>
ffffffffc0200f5e:	50051563          	bnez	a0,ffffffffc0201468 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200f62:	08098a13          	addi	s4,s3,128
ffffffffc0200f66:	8552                	mv	a0,s4
ffffffffc0200f68:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200f6a:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200f6e:	00008797          	auipc	a5,0x8
ffffffffc0200f72:	4c07a923          	sw	zero,1234(a5) # ffffffffc0209440 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200f76:	50d000ef          	jal	ra,ffffffffc0201c82 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200f7a:	4511                	li	a0,4
ffffffffc0200f7c:	4c9000ef          	jal	ra,ffffffffc0201c44 <alloc_pages>
ffffffffc0200f80:	4c051463          	bnez	a0,ffffffffc0201448 <default_check+0x6a2>
ffffffffc0200f84:	0889b783          	ld	a5,136(s3)
ffffffffc0200f88:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200f8a:	8b85                	andi	a5,a5,1
ffffffffc0200f8c:	48078e63          	beqz	a5,ffffffffc0201428 <default_check+0x682>
ffffffffc0200f90:	0909a703          	lw	a4,144(s3)
ffffffffc0200f94:	478d                	li	a5,3
ffffffffc0200f96:	48f71963          	bne	a4,a5,ffffffffc0201428 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200f9a:	450d                	li	a0,3
ffffffffc0200f9c:	4a9000ef          	jal	ra,ffffffffc0201c44 <alloc_pages>
ffffffffc0200fa0:	8c2a                	mv	s8,a0
ffffffffc0200fa2:	46050363          	beqz	a0,ffffffffc0201408 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc0200fa6:	4505                	li	a0,1
ffffffffc0200fa8:	49d000ef          	jal	ra,ffffffffc0201c44 <alloc_pages>
ffffffffc0200fac:	42051e63          	bnez	a0,ffffffffc02013e8 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0200fb0:	418a1c63          	bne	s4,s8,ffffffffc02013c8 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200fb4:	4585                	li	a1,1
ffffffffc0200fb6:	854e                	mv	a0,s3
ffffffffc0200fb8:	4cb000ef          	jal	ra,ffffffffc0201c82 <free_pages>
    free_pages(p1, 3);
ffffffffc0200fbc:	458d                	li	a1,3
ffffffffc0200fbe:	8552                	mv	a0,s4
ffffffffc0200fc0:	4c3000ef          	jal	ra,ffffffffc0201c82 <free_pages>
ffffffffc0200fc4:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200fc8:	04098c13          	addi	s8,s3,64
ffffffffc0200fcc:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200fce:	8b85                	andi	a5,a5,1
ffffffffc0200fd0:	3c078c63          	beqz	a5,ffffffffc02013a8 <default_check+0x602>
ffffffffc0200fd4:	0109a703          	lw	a4,16(s3)
ffffffffc0200fd8:	4785                	li	a5,1
ffffffffc0200fda:	3cf71763          	bne	a4,a5,ffffffffc02013a8 <default_check+0x602>
ffffffffc0200fde:	008a3783          	ld	a5,8(s4)
ffffffffc0200fe2:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200fe4:	8b85                	andi	a5,a5,1
ffffffffc0200fe6:	3a078163          	beqz	a5,ffffffffc0201388 <default_check+0x5e2>
ffffffffc0200fea:	010a2703          	lw	a4,16(s4)
ffffffffc0200fee:	478d                	li	a5,3
ffffffffc0200ff0:	38f71c63          	bne	a4,a5,ffffffffc0201388 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200ff4:	4505                	li	a0,1
ffffffffc0200ff6:	44f000ef          	jal	ra,ffffffffc0201c44 <alloc_pages>
ffffffffc0200ffa:	36a99763          	bne	s3,a0,ffffffffc0201368 <default_check+0x5c2>
    free_page(p0);
ffffffffc0200ffe:	4585                	li	a1,1
ffffffffc0201000:	483000ef          	jal	ra,ffffffffc0201c82 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201004:	4509                	li	a0,2
ffffffffc0201006:	43f000ef          	jal	ra,ffffffffc0201c44 <alloc_pages>
ffffffffc020100a:	32aa1f63          	bne	s4,a0,ffffffffc0201348 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc020100e:	4589                	li	a1,2
ffffffffc0201010:	473000ef          	jal	ra,ffffffffc0201c82 <free_pages>
    free_page(p2);
ffffffffc0201014:	4585                	li	a1,1
ffffffffc0201016:	8562                	mv	a0,s8
ffffffffc0201018:	46b000ef          	jal	ra,ffffffffc0201c82 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020101c:	4515                	li	a0,5
ffffffffc020101e:	427000ef          	jal	ra,ffffffffc0201c44 <alloc_pages>
ffffffffc0201022:	89aa                	mv	s3,a0
ffffffffc0201024:	48050263          	beqz	a0,ffffffffc02014a8 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0201028:	4505                	li	a0,1
ffffffffc020102a:	41b000ef          	jal	ra,ffffffffc0201c44 <alloc_pages>
ffffffffc020102e:	2c051d63          	bnez	a0,ffffffffc0201308 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0201032:	481c                	lw	a5,16(s0)
ffffffffc0201034:	2a079a63          	bnez	a5,ffffffffc02012e8 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201038:	4595                	li	a1,5
ffffffffc020103a:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc020103c:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201040:	01643023          	sd	s6,0(s0)
ffffffffc0201044:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0201048:	43b000ef          	jal	ra,ffffffffc0201c82 <free_pages>
    return listelm->next;
ffffffffc020104c:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc020104e:	00878963          	beq	a5,s0,ffffffffc0201060 <default_check+0x2ba>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0201052:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201056:	679c                	ld	a5,8(a5)
ffffffffc0201058:	397d                	addiw	s2,s2,-1
ffffffffc020105a:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc020105c:	fe879be3          	bne	a5,s0,ffffffffc0201052 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0201060:	26091463          	bnez	s2,ffffffffc02012c8 <default_check+0x522>
    assert(total == 0);
ffffffffc0201064:	46049263          	bnez	s1,ffffffffc02014c8 <default_check+0x722>
}
ffffffffc0201068:	60a6                	ld	ra,72(sp)
ffffffffc020106a:	6406                	ld	s0,64(sp)
ffffffffc020106c:	74e2                	ld	s1,56(sp)
ffffffffc020106e:	7942                	ld	s2,48(sp)
ffffffffc0201070:	79a2                	ld	s3,40(sp)
ffffffffc0201072:	7a02                	ld	s4,32(sp)
ffffffffc0201074:	6ae2                	ld	s5,24(sp)
ffffffffc0201076:	6b42                	ld	s6,16(sp)
ffffffffc0201078:	6ba2                	ld	s7,8(sp)
ffffffffc020107a:	6c02                	ld	s8,0(sp)
ffffffffc020107c:	6161                	addi	sp,sp,80
ffffffffc020107e:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0201080:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201082:	4481                	li	s1,0
ffffffffc0201084:	4901                	li	s2,0
ffffffffc0201086:	b38d                	j	ffffffffc0200de8 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0201088:	00003697          	auipc	a3,0x3
ffffffffc020108c:	76068693          	addi	a3,a3,1888 # ffffffffc02047e8 <commands+0x6f8>
ffffffffc0201090:	00003617          	auipc	a2,0x3
ffffffffc0201094:	76860613          	addi	a2,a2,1896 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201098:	11100593          	li	a1,273
ffffffffc020109c:	00003517          	auipc	a0,0x3
ffffffffc02010a0:	77450513          	addi	a0,a0,1908 # ffffffffc0204810 <commands+0x720>
ffffffffc02010a4:	bb6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02010a8:	00004697          	auipc	a3,0x4
ffffffffc02010ac:	80068693          	addi	a3,a3,-2048 # ffffffffc02048a8 <commands+0x7b8>
ffffffffc02010b0:	00003617          	auipc	a2,0x3
ffffffffc02010b4:	74860613          	addi	a2,a2,1864 # ffffffffc02047f8 <commands+0x708>
ffffffffc02010b8:	0dc00593          	li	a1,220
ffffffffc02010bc:	00003517          	auipc	a0,0x3
ffffffffc02010c0:	75450513          	addi	a0,a0,1876 # ffffffffc0204810 <commands+0x720>
ffffffffc02010c4:	b96ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02010c8:	00004697          	auipc	a3,0x4
ffffffffc02010cc:	80868693          	addi	a3,a3,-2040 # ffffffffc02048d0 <commands+0x7e0>
ffffffffc02010d0:	00003617          	auipc	a2,0x3
ffffffffc02010d4:	72860613          	addi	a2,a2,1832 # ffffffffc02047f8 <commands+0x708>
ffffffffc02010d8:	0dd00593          	li	a1,221
ffffffffc02010dc:	00003517          	auipc	a0,0x3
ffffffffc02010e0:	73450513          	addi	a0,a0,1844 # ffffffffc0204810 <commands+0x720>
ffffffffc02010e4:	b76ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02010e8:	00004697          	auipc	a3,0x4
ffffffffc02010ec:	82868693          	addi	a3,a3,-2008 # ffffffffc0204910 <commands+0x820>
ffffffffc02010f0:	00003617          	auipc	a2,0x3
ffffffffc02010f4:	70860613          	addi	a2,a2,1800 # ffffffffc02047f8 <commands+0x708>
ffffffffc02010f8:	0df00593          	li	a1,223
ffffffffc02010fc:	00003517          	auipc	a0,0x3
ffffffffc0201100:	71450513          	addi	a0,a0,1812 # ffffffffc0204810 <commands+0x720>
ffffffffc0201104:	b56ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201108:	00004697          	auipc	a3,0x4
ffffffffc020110c:	89068693          	addi	a3,a3,-1904 # ffffffffc0204998 <commands+0x8a8>
ffffffffc0201110:	00003617          	auipc	a2,0x3
ffffffffc0201114:	6e860613          	addi	a2,a2,1768 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201118:	0f800593          	li	a1,248
ffffffffc020111c:	00003517          	auipc	a0,0x3
ffffffffc0201120:	6f450513          	addi	a0,a0,1780 # ffffffffc0204810 <commands+0x720>
ffffffffc0201124:	b36ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201128:	00003697          	auipc	a3,0x3
ffffffffc020112c:	72068693          	addi	a3,a3,1824 # ffffffffc0204848 <commands+0x758>
ffffffffc0201130:	00003617          	auipc	a2,0x3
ffffffffc0201134:	6c860613          	addi	a2,a2,1736 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201138:	0f100593          	li	a1,241
ffffffffc020113c:	00003517          	auipc	a0,0x3
ffffffffc0201140:	6d450513          	addi	a0,a0,1748 # ffffffffc0204810 <commands+0x720>
ffffffffc0201144:	b16ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free == 3);
ffffffffc0201148:	00004697          	auipc	a3,0x4
ffffffffc020114c:	84068693          	addi	a3,a3,-1984 # ffffffffc0204988 <commands+0x898>
ffffffffc0201150:	00003617          	auipc	a2,0x3
ffffffffc0201154:	6a860613          	addi	a2,a2,1704 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201158:	0ef00593          	li	a1,239
ffffffffc020115c:	00003517          	auipc	a0,0x3
ffffffffc0201160:	6b450513          	addi	a0,a0,1716 # ffffffffc0204810 <commands+0x720>
ffffffffc0201164:	af6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201168:	00004697          	auipc	a3,0x4
ffffffffc020116c:	80868693          	addi	a3,a3,-2040 # ffffffffc0204970 <commands+0x880>
ffffffffc0201170:	00003617          	auipc	a2,0x3
ffffffffc0201174:	68860613          	addi	a2,a2,1672 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201178:	0ea00593          	li	a1,234
ffffffffc020117c:	00003517          	auipc	a0,0x3
ffffffffc0201180:	69450513          	addi	a0,a0,1684 # ffffffffc0204810 <commands+0x720>
ffffffffc0201184:	ad6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201188:	00003697          	auipc	a3,0x3
ffffffffc020118c:	7c868693          	addi	a3,a3,1992 # ffffffffc0204950 <commands+0x860>
ffffffffc0201190:	00003617          	auipc	a2,0x3
ffffffffc0201194:	66860613          	addi	a2,a2,1640 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201198:	0e100593          	li	a1,225
ffffffffc020119c:	00003517          	auipc	a0,0x3
ffffffffc02011a0:	67450513          	addi	a0,a0,1652 # ffffffffc0204810 <commands+0x720>
ffffffffc02011a4:	ab6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(p0 != NULL);
ffffffffc02011a8:	00004697          	auipc	a3,0x4
ffffffffc02011ac:	83868693          	addi	a3,a3,-1992 # ffffffffc02049e0 <commands+0x8f0>
ffffffffc02011b0:	00003617          	auipc	a2,0x3
ffffffffc02011b4:	64860613          	addi	a2,a2,1608 # ffffffffc02047f8 <commands+0x708>
ffffffffc02011b8:	11900593          	li	a1,281
ffffffffc02011bc:	00003517          	auipc	a0,0x3
ffffffffc02011c0:	65450513          	addi	a0,a0,1620 # ffffffffc0204810 <commands+0x720>
ffffffffc02011c4:	a96ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free == 0);
ffffffffc02011c8:	00004697          	auipc	a3,0x4
ffffffffc02011cc:	80868693          	addi	a3,a3,-2040 # ffffffffc02049d0 <commands+0x8e0>
ffffffffc02011d0:	00003617          	auipc	a2,0x3
ffffffffc02011d4:	62860613          	addi	a2,a2,1576 # ffffffffc02047f8 <commands+0x708>
ffffffffc02011d8:	0fe00593          	li	a1,254
ffffffffc02011dc:	00003517          	auipc	a0,0x3
ffffffffc02011e0:	63450513          	addi	a0,a0,1588 # ffffffffc0204810 <commands+0x720>
ffffffffc02011e4:	a76ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011e8:	00003697          	auipc	a3,0x3
ffffffffc02011ec:	78868693          	addi	a3,a3,1928 # ffffffffc0204970 <commands+0x880>
ffffffffc02011f0:	00003617          	auipc	a2,0x3
ffffffffc02011f4:	60860613          	addi	a2,a2,1544 # ffffffffc02047f8 <commands+0x708>
ffffffffc02011f8:	0fc00593          	li	a1,252
ffffffffc02011fc:	00003517          	auipc	a0,0x3
ffffffffc0201200:	61450513          	addi	a0,a0,1556 # ffffffffc0204810 <commands+0x720>
ffffffffc0201204:	a56ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201208:	00003697          	auipc	a3,0x3
ffffffffc020120c:	7a868693          	addi	a3,a3,1960 # ffffffffc02049b0 <commands+0x8c0>
ffffffffc0201210:	00003617          	auipc	a2,0x3
ffffffffc0201214:	5e860613          	addi	a2,a2,1512 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201218:	0fb00593          	li	a1,251
ffffffffc020121c:	00003517          	auipc	a0,0x3
ffffffffc0201220:	5f450513          	addi	a0,a0,1524 # ffffffffc0204810 <commands+0x720>
ffffffffc0201224:	a36ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201228:	00003697          	auipc	a3,0x3
ffffffffc020122c:	62068693          	addi	a3,a3,1568 # ffffffffc0204848 <commands+0x758>
ffffffffc0201230:	00003617          	auipc	a2,0x3
ffffffffc0201234:	5c860613          	addi	a2,a2,1480 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201238:	0d800593          	li	a1,216
ffffffffc020123c:	00003517          	auipc	a0,0x3
ffffffffc0201240:	5d450513          	addi	a0,a0,1492 # ffffffffc0204810 <commands+0x720>
ffffffffc0201244:	a16ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201248:	00003697          	auipc	a3,0x3
ffffffffc020124c:	72868693          	addi	a3,a3,1832 # ffffffffc0204970 <commands+0x880>
ffffffffc0201250:	00003617          	auipc	a2,0x3
ffffffffc0201254:	5a860613          	addi	a2,a2,1448 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201258:	0f500593          	li	a1,245
ffffffffc020125c:	00003517          	auipc	a0,0x3
ffffffffc0201260:	5b450513          	addi	a0,a0,1460 # ffffffffc0204810 <commands+0x720>
ffffffffc0201264:	9f6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201268:	00003697          	auipc	a3,0x3
ffffffffc020126c:	62068693          	addi	a3,a3,1568 # ffffffffc0204888 <commands+0x798>
ffffffffc0201270:	00003617          	auipc	a2,0x3
ffffffffc0201274:	58860613          	addi	a2,a2,1416 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201278:	0f300593          	li	a1,243
ffffffffc020127c:	00003517          	auipc	a0,0x3
ffffffffc0201280:	59450513          	addi	a0,a0,1428 # ffffffffc0204810 <commands+0x720>
ffffffffc0201284:	9d6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201288:	00003697          	auipc	a3,0x3
ffffffffc020128c:	5e068693          	addi	a3,a3,1504 # ffffffffc0204868 <commands+0x778>
ffffffffc0201290:	00003617          	auipc	a2,0x3
ffffffffc0201294:	56860613          	addi	a2,a2,1384 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201298:	0f200593          	li	a1,242
ffffffffc020129c:	00003517          	auipc	a0,0x3
ffffffffc02012a0:	57450513          	addi	a0,a0,1396 # ffffffffc0204810 <commands+0x720>
ffffffffc02012a4:	9b6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02012a8:	00003697          	auipc	a3,0x3
ffffffffc02012ac:	5e068693          	addi	a3,a3,1504 # ffffffffc0204888 <commands+0x798>
ffffffffc02012b0:	00003617          	auipc	a2,0x3
ffffffffc02012b4:	54860613          	addi	a2,a2,1352 # ffffffffc02047f8 <commands+0x708>
ffffffffc02012b8:	0da00593          	li	a1,218
ffffffffc02012bc:	00003517          	auipc	a0,0x3
ffffffffc02012c0:	55450513          	addi	a0,a0,1364 # ffffffffc0204810 <commands+0x720>
ffffffffc02012c4:	996ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(count == 0);
ffffffffc02012c8:	00004697          	auipc	a3,0x4
ffffffffc02012cc:	86868693          	addi	a3,a3,-1944 # ffffffffc0204b30 <commands+0xa40>
ffffffffc02012d0:	00003617          	auipc	a2,0x3
ffffffffc02012d4:	52860613          	addi	a2,a2,1320 # ffffffffc02047f8 <commands+0x708>
ffffffffc02012d8:	14700593          	li	a1,327
ffffffffc02012dc:	00003517          	auipc	a0,0x3
ffffffffc02012e0:	53450513          	addi	a0,a0,1332 # ffffffffc0204810 <commands+0x720>
ffffffffc02012e4:	976ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free == 0);
ffffffffc02012e8:	00003697          	auipc	a3,0x3
ffffffffc02012ec:	6e868693          	addi	a3,a3,1768 # ffffffffc02049d0 <commands+0x8e0>
ffffffffc02012f0:	00003617          	auipc	a2,0x3
ffffffffc02012f4:	50860613          	addi	a2,a2,1288 # ffffffffc02047f8 <commands+0x708>
ffffffffc02012f8:	13b00593          	li	a1,315
ffffffffc02012fc:	00003517          	auipc	a0,0x3
ffffffffc0201300:	51450513          	addi	a0,a0,1300 # ffffffffc0204810 <commands+0x720>
ffffffffc0201304:	956ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201308:	00003697          	auipc	a3,0x3
ffffffffc020130c:	66868693          	addi	a3,a3,1640 # ffffffffc0204970 <commands+0x880>
ffffffffc0201310:	00003617          	auipc	a2,0x3
ffffffffc0201314:	4e860613          	addi	a2,a2,1256 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201318:	13900593          	li	a1,313
ffffffffc020131c:	00003517          	auipc	a0,0x3
ffffffffc0201320:	4f450513          	addi	a0,a0,1268 # ffffffffc0204810 <commands+0x720>
ffffffffc0201324:	936ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201328:	00003697          	auipc	a3,0x3
ffffffffc020132c:	60868693          	addi	a3,a3,1544 # ffffffffc0204930 <commands+0x840>
ffffffffc0201330:	00003617          	auipc	a2,0x3
ffffffffc0201334:	4c860613          	addi	a2,a2,1224 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201338:	0e000593          	li	a1,224
ffffffffc020133c:	00003517          	auipc	a0,0x3
ffffffffc0201340:	4d450513          	addi	a0,a0,1236 # ffffffffc0204810 <commands+0x720>
ffffffffc0201344:	916ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201348:	00003697          	auipc	a3,0x3
ffffffffc020134c:	7a868693          	addi	a3,a3,1960 # ffffffffc0204af0 <commands+0xa00>
ffffffffc0201350:	00003617          	auipc	a2,0x3
ffffffffc0201354:	4a860613          	addi	a2,a2,1192 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201358:	13300593          	li	a1,307
ffffffffc020135c:	00003517          	auipc	a0,0x3
ffffffffc0201360:	4b450513          	addi	a0,a0,1204 # ffffffffc0204810 <commands+0x720>
ffffffffc0201364:	8f6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201368:	00003697          	auipc	a3,0x3
ffffffffc020136c:	76868693          	addi	a3,a3,1896 # ffffffffc0204ad0 <commands+0x9e0>
ffffffffc0201370:	00003617          	auipc	a2,0x3
ffffffffc0201374:	48860613          	addi	a2,a2,1160 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201378:	13100593          	li	a1,305
ffffffffc020137c:	00003517          	auipc	a0,0x3
ffffffffc0201380:	49450513          	addi	a0,a0,1172 # ffffffffc0204810 <commands+0x720>
ffffffffc0201384:	8d6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201388:	00003697          	auipc	a3,0x3
ffffffffc020138c:	72068693          	addi	a3,a3,1824 # ffffffffc0204aa8 <commands+0x9b8>
ffffffffc0201390:	00003617          	auipc	a2,0x3
ffffffffc0201394:	46860613          	addi	a2,a2,1128 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201398:	12f00593          	li	a1,303
ffffffffc020139c:	00003517          	auipc	a0,0x3
ffffffffc02013a0:	47450513          	addi	a0,a0,1140 # ffffffffc0204810 <commands+0x720>
ffffffffc02013a4:	8b6ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02013a8:	00003697          	auipc	a3,0x3
ffffffffc02013ac:	6d868693          	addi	a3,a3,1752 # ffffffffc0204a80 <commands+0x990>
ffffffffc02013b0:	00003617          	auipc	a2,0x3
ffffffffc02013b4:	44860613          	addi	a2,a2,1096 # ffffffffc02047f8 <commands+0x708>
ffffffffc02013b8:	12e00593          	li	a1,302
ffffffffc02013bc:	00003517          	auipc	a0,0x3
ffffffffc02013c0:	45450513          	addi	a0,a0,1108 # ffffffffc0204810 <commands+0x720>
ffffffffc02013c4:	896ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(p0 + 2 == p1);
ffffffffc02013c8:	00003697          	auipc	a3,0x3
ffffffffc02013cc:	6a868693          	addi	a3,a3,1704 # ffffffffc0204a70 <commands+0x980>
ffffffffc02013d0:	00003617          	auipc	a2,0x3
ffffffffc02013d4:	42860613          	addi	a2,a2,1064 # ffffffffc02047f8 <commands+0x708>
ffffffffc02013d8:	12900593          	li	a1,297
ffffffffc02013dc:	00003517          	auipc	a0,0x3
ffffffffc02013e0:	43450513          	addi	a0,a0,1076 # ffffffffc0204810 <commands+0x720>
ffffffffc02013e4:	876ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013e8:	00003697          	auipc	a3,0x3
ffffffffc02013ec:	58868693          	addi	a3,a3,1416 # ffffffffc0204970 <commands+0x880>
ffffffffc02013f0:	00003617          	auipc	a2,0x3
ffffffffc02013f4:	40860613          	addi	a2,a2,1032 # ffffffffc02047f8 <commands+0x708>
ffffffffc02013f8:	12800593          	li	a1,296
ffffffffc02013fc:	00003517          	auipc	a0,0x3
ffffffffc0201400:	41450513          	addi	a0,a0,1044 # ffffffffc0204810 <commands+0x720>
ffffffffc0201404:	856ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201408:	00003697          	auipc	a3,0x3
ffffffffc020140c:	64868693          	addi	a3,a3,1608 # ffffffffc0204a50 <commands+0x960>
ffffffffc0201410:	00003617          	auipc	a2,0x3
ffffffffc0201414:	3e860613          	addi	a2,a2,1000 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201418:	12700593          	li	a1,295
ffffffffc020141c:	00003517          	auipc	a0,0x3
ffffffffc0201420:	3f450513          	addi	a0,a0,1012 # ffffffffc0204810 <commands+0x720>
ffffffffc0201424:	836ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201428:	00003697          	auipc	a3,0x3
ffffffffc020142c:	5f868693          	addi	a3,a3,1528 # ffffffffc0204a20 <commands+0x930>
ffffffffc0201430:	00003617          	auipc	a2,0x3
ffffffffc0201434:	3c860613          	addi	a2,a2,968 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201438:	12600593          	li	a1,294
ffffffffc020143c:	00003517          	auipc	a0,0x3
ffffffffc0201440:	3d450513          	addi	a0,a0,980 # ffffffffc0204810 <commands+0x720>
ffffffffc0201444:	816ff0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201448:	00003697          	auipc	a3,0x3
ffffffffc020144c:	5c068693          	addi	a3,a3,1472 # ffffffffc0204a08 <commands+0x918>
ffffffffc0201450:	00003617          	auipc	a2,0x3
ffffffffc0201454:	3a860613          	addi	a2,a2,936 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201458:	12500593          	li	a1,293
ffffffffc020145c:	00003517          	auipc	a0,0x3
ffffffffc0201460:	3b450513          	addi	a0,a0,948 # ffffffffc0204810 <commands+0x720>
ffffffffc0201464:	ff7fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201468:	00003697          	auipc	a3,0x3
ffffffffc020146c:	50868693          	addi	a3,a3,1288 # ffffffffc0204970 <commands+0x880>
ffffffffc0201470:	00003617          	auipc	a2,0x3
ffffffffc0201474:	38860613          	addi	a2,a2,904 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201478:	11f00593          	li	a1,287
ffffffffc020147c:	00003517          	auipc	a0,0x3
ffffffffc0201480:	39450513          	addi	a0,a0,916 # ffffffffc0204810 <commands+0x720>
ffffffffc0201484:	fd7fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(!PageProperty(p0));
ffffffffc0201488:	00003697          	auipc	a3,0x3
ffffffffc020148c:	56868693          	addi	a3,a3,1384 # ffffffffc02049f0 <commands+0x900>
ffffffffc0201490:	00003617          	auipc	a2,0x3
ffffffffc0201494:	36860613          	addi	a2,a2,872 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201498:	11a00593          	li	a1,282
ffffffffc020149c:	00003517          	auipc	a0,0x3
ffffffffc02014a0:	37450513          	addi	a0,a0,884 # ffffffffc0204810 <commands+0x720>
ffffffffc02014a4:	fb7fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02014a8:	00003697          	auipc	a3,0x3
ffffffffc02014ac:	66868693          	addi	a3,a3,1640 # ffffffffc0204b10 <commands+0xa20>
ffffffffc02014b0:	00003617          	auipc	a2,0x3
ffffffffc02014b4:	34860613          	addi	a2,a2,840 # ffffffffc02047f8 <commands+0x708>
ffffffffc02014b8:	13800593          	li	a1,312
ffffffffc02014bc:	00003517          	auipc	a0,0x3
ffffffffc02014c0:	35450513          	addi	a0,a0,852 # ffffffffc0204810 <commands+0x720>
ffffffffc02014c4:	f97fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(total == 0);
ffffffffc02014c8:	00003697          	auipc	a3,0x3
ffffffffc02014cc:	67868693          	addi	a3,a3,1656 # ffffffffc0204b40 <commands+0xa50>
ffffffffc02014d0:	00003617          	auipc	a2,0x3
ffffffffc02014d4:	32860613          	addi	a2,a2,808 # ffffffffc02047f8 <commands+0x708>
ffffffffc02014d8:	14800593          	li	a1,328
ffffffffc02014dc:	00003517          	auipc	a0,0x3
ffffffffc02014e0:	33450513          	addi	a0,a0,820 # ffffffffc0204810 <commands+0x720>
ffffffffc02014e4:	f77fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(total == nr_free_pages());
ffffffffc02014e8:	00003697          	auipc	a3,0x3
ffffffffc02014ec:	34068693          	addi	a3,a3,832 # ffffffffc0204828 <commands+0x738>
ffffffffc02014f0:	00003617          	auipc	a2,0x3
ffffffffc02014f4:	30860613          	addi	a2,a2,776 # ffffffffc02047f8 <commands+0x708>
ffffffffc02014f8:	11400593          	li	a1,276
ffffffffc02014fc:	00003517          	auipc	a0,0x3
ffffffffc0201500:	31450513          	addi	a0,a0,788 # ffffffffc0204810 <commands+0x720>
ffffffffc0201504:	f57fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201508:	00003697          	auipc	a3,0x3
ffffffffc020150c:	36068693          	addi	a3,a3,864 # ffffffffc0204868 <commands+0x778>
ffffffffc0201510:	00003617          	auipc	a2,0x3
ffffffffc0201514:	2e860613          	addi	a2,a2,744 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201518:	0d900593          	li	a1,217
ffffffffc020151c:	00003517          	auipc	a0,0x3
ffffffffc0201520:	2f450513          	addi	a0,a0,756 # ffffffffc0204810 <commands+0x720>
ffffffffc0201524:	f37fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201528 <default_free_pages>:
{
ffffffffc0201528:	1141                	addi	sp,sp,-16
ffffffffc020152a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020152c:	14058463          	beqz	a1,ffffffffc0201674 <default_free_pages+0x14c>
    for (; p != base + n; p++)
ffffffffc0201530:	00659693          	slli	a3,a1,0x6
ffffffffc0201534:	96aa                	add	a3,a3,a0
ffffffffc0201536:	87aa                	mv	a5,a0
ffffffffc0201538:	02d50263          	beq	a0,a3,ffffffffc020155c <default_free_pages+0x34>
ffffffffc020153c:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020153e:	8b05                	andi	a4,a4,1
ffffffffc0201540:	10071a63          	bnez	a4,ffffffffc0201654 <default_free_pages+0x12c>
ffffffffc0201544:	6798                	ld	a4,8(a5)
ffffffffc0201546:	8b09                	andi	a4,a4,2
ffffffffc0201548:	10071663          	bnez	a4,ffffffffc0201654 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc020154c:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201550:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201554:	04078793          	addi	a5,a5,64
ffffffffc0201558:	fed792e3          	bne	a5,a3,ffffffffc020153c <default_free_pages+0x14>
    base->property = n;
ffffffffc020155c:	2581                	sext.w	a1,a1
ffffffffc020155e:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201560:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201564:	4789                	li	a5,2
ffffffffc0201566:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020156a:	00008697          	auipc	a3,0x8
ffffffffc020156e:	ec668693          	addi	a3,a3,-314 # ffffffffc0209430 <free_area>
ffffffffc0201572:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201574:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201576:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020157a:	9db9                	addw	a1,a1,a4
ffffffffc020157c:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc020157e:	0ad78463          	beq	a5,a3,ffffffffc0201626 <default_free_pages+0xfe>
            struct Page *page = le2page(le, page_link);
ffffffffc0201582:	fe878713          	addi	a4,a5,-24
ffffffffc0201586:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc020158a:	4581                	li	a1,0
            if (base < page)
ffffffffc020158c:	00e56a63          	bltu	a0,a4,ffffffffc02015a0 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201590:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201592:	04d70c63          	beq	a4,a3,ffffffffc02015ea <default_free_pages+0xc2>
    for (; p != base + n; p++)
ffffffffc0201596:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201598:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc020159c:	fee57ae3          	bgeu	a0,a4,ffffffffc0201590 <default_free_pages+0x68>
ffffffffc02015a0:	c199                	beqz	a1,ffffffffc02015a6 <default_free_pages+0x7e>
ffffffffc02015a2:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02015a6:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02015a8:	e390                	sd	a2,0(a5)
ffffffffc02015aa:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02015ac:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02015ae:	ed18                	sd	a4,24(a0)
    if (le != &free_list)
ffffffffc02015b0:	00d70d63          	beq	a4,a3,ffffffffc02015ca <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc02015b4:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02015b8:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc02015bc:	02059813          	slli	a6,a1,0x20
ffffffffc02015c0:	01a85793          	srli	a5,a6,0x1a
ffffffffc02015c4:	97b2                	add	a5,a5,a2
ffffffffc02015c6:	02f50c63          	beq	a0,a5,ffffffffc02015fe <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02015ca:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc02015cc:	00d78c63          	beq	a5,a3,ffffffffc02015e4 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc02015d0:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02015d2:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc02015d6:	02061593          	slli	a1,a2,0x20
ffffffffc02015da:	01a5d713          	srli	a4,a1,0x1a
ffffffffc02015de:	972a                	add	a4,a4,a0
ffffffffc02015e0:	04e68a63          	beq	a3,a4,ffffffffc0201634 <default_free_pages+0x10c>
}
ffffffffc02015e4:	60a2                	ld	ra,8(sp)
ffffffffc02015e6:	0141                	addi	sp,sp,16
ffffffffc02015e8:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02015ea:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02015ec:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02015ee:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02015f0:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc02015f2:	02d70763          	beq	a4,a3,ffffffffc0201620 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc02015f6:	8832                	mv	a6,a2
ffffffffc02015f8:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc02015fa:	87ba                	mv	a5,a4
ffffffffc02015fc:	bf71                	j	ffffffffc0201598 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc02015fe:	491c                	lw	a5,16(a0)
ffffffffc0201600:	9dbd                	addw	a1,a1,a5
ffffffffc0201602:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201606:	57f5                	li	a5,-3
ffffffffc0201608:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc020160c:	01853803          	ld	a6,24(a0)
ffffffffc0201610:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201612:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201614:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0201618:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc020161a:	0105b023          	sd	a6,0(a1)
ffffffffc020161e:	b77d                	j	ffffffffc02015cc <default_free_pages+0xa4>
ffffffffc0201620:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list)
ffffffffc0201622:	873e                	mv	a4,a5
ffffffffc0201624:	bf41                	j	ffffffffc02015b4 <default_free_pages+0x8c>
}
ffffffffc0201626:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201628:	e390                	sd	a2,0(a5)
ffffffffc020162a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020162c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020162e:	ed1c                	sd	a5,24(a0)
ffffffffc0201630:	0141                	addi	sp,sp,16
ffffffffc0201632:	8082                	ret
            base->property += p->property;
ffffffffc0201634:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201638:	ff078693          	addi	a3,a5,-16
ffffffffc020163c:	9e39                	addw	a2,a2,a4
ffffffffc020163e:	c910                	sw	a2,16(a0)
ffffffffc0201640:	5775                	li	a4,-3
ffffffffc0201642:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201646:	6398                	ld	a4,0(a5)
ffffffffc0201648:	679c                	ld	a5,8(a5)
}
ffffffffc020164a:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020164c:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020164e:	e398                	sd	a4,0(a5)
ffffffffc0201650:	0141                	addi	sp,sp,16
ffffffffc0201652:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201654:	00003697          	auipc	a3,0x3
ffffffffc0201658:	50468693          	addi	a3,a3,1284 # ffffffffc0204b58 <commands+0xa68>
ffffffffc020165c:	00003617          	auipc	a2,0x3
ffffffffc0201660:	19c60613          	addi	a2,a2,412 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201664:	09500593          	li	a1,149
ffffffffc0201668:	00003517          	auipc	a0,0x3
ffffffffc020166c:	1a850513          	addi	a0,a0,424 # ffffffffc0204810 <commands+0x720>
ffffffffc0201670:	debfe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(n > 0);
ffffffffc0201674:	00003697          	auipc	a3,0x3
ffffffffc0201678:	4dc68693          	addi	a3,a3,1244 # ffffffffc0204b50 <commands+0xa60>
ffffffffc020167c:	00003617          	auipc	a2,0x3
ffffffffc0201680:	17c60613          	addi	a2,a2,380 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201684:	09100593          	li	a1,145
ffffffffc0201688:	00003517          	auipc	a0,0x3
ffffffffc020168c:	18850513          	addi	a0,a0,392 # ffffffffc0204810 <commands+0x720>
ffffffffc0201690:	dcbfe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201694 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201694:	c941                	beqz	a0,ffffffffc0201724 <default_alloc_pages+0x90>
    if (n > nr_free)
ffffffffc0201696:	00008597          	auipc	a1,0x8
ffffffffc020169a:	d9a58593          	addi	a1,a1,-614 # ffffffffc0209430 <free_area>
ffffffffc020169e:	0105a803          	lw	a6,16(a1)
ffffffffc02016a2:	872a                	mv	a4,a0
ffffffffc02016a4:	02081793          	slli	a5,a6,0x20
ffffffffc02016a8:	9381                	srli	a5,a5,0x20
ffffffffc02016aa:	00a7ee63          	bltu	a5,a0,ffffffffc02016c6 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02016ae:	87ae                	mv	a5,a1
ffffffffc02016b0:	a801                	j	ffffffffc02016c0 <default_alloc_pages+0x2c>
        if (p->property >= n)
ffffffffc02016b2:	ff87a683          	lw	a3,-8(a5)
ffffffffc02016b6:	02069613          	slli	a2,a3,0x20
ffffffffc02016ba:	9201                	srli	a2,a2,0x20
ffffffffc02016bc:	00e67763          	bgeu	a2,a4,ffffffffc02016ca <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc02016c0:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc02016c2:	feb798e3          	bne	a5,a1,ffffffffc02016b2 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02016c6:	4501                	li	a0,0
}
ffffffffc02016c8:	8082                	ret
    return listelm->prev;
ffffffffc02016ca:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02016ce:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02016d2:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc02016d6:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc02016da:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc02016de:	01133023          	sd	a7,0(t1)
        if (page->property > n)
ffffffffc02016e2:	02c77863          	bgeu	a4,a2,ffffffffc0201712 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc02016e6:	071a                	slli	a4,a4,0x6
ffffffffc02016e8:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02016ea:	41c686bb          	subw	a3,a3,t3
ffffffffc02016ee:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02016f0:	00870613          	addi	a2,a4,8
ffffffffc02016f4:	4689                	li	a3,2
ffffffffc02016f6:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02016fa:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02016fe:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0201702:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0201706:	e290                	sd	a2,0(a3)
ffffffffc0201708:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc020170c:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc020170e:	01173c23          	sd	a7,24(a4)
ffffffffc0201712:	41c8083b          	subw	a6,a6,t3
ffffffffc0201716:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020171a:	5775                	li	a4,-3
ffffffffc020171c:	17c1                	addi	a5,a5,-16
ffffffffc020171e:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201722:	8082                	ret
{
ffffffffc0201724:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201726:	00003697          	auipc	a3,0x3
ffffffffc020172a:	42a68693          	addi	a3,a3,1066 # ffffffffc0204b50 <commands+0xa60>
ffffffffc020172e:	00003617          	auipc	a2,0x3
ffffffffc0201732:	0ca60613          	addi	a2,a2,202 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201736:	06d00593          	li	a1,109
ffffffffc020173a:	00003517          	auipc	a0,0x3
ffffffffc020173e:	0d650513          	addi	a0,a0,214 # ffffffffc0204810 <commands+0x720>
{
ffffffffc0201742:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201744:	d17fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201748 <default_init_memmap>:
{
ffffffffc0201748:	1141                	addi	sp,sp,-16
ffffffffc020174a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020174c:	c5f1                	beqz	a1,ffffffffc0201818 <default_init_memmap+0xd0>
    for (; p != base + n; p++)
ffffffffc020174e:	00659693          	slli	a3,a1,0x6
ffffffffc0201752:	96aa                	add	a3,a3,a0
ffffffffc0201754:	87aa                	mv	a5,a0
ffffffffc0201756:	00d50f63          	beq	a0,a3,ffffffffc0201774 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020175a:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc020175c:	8b05                	andi	a4,a4,1
ffffffffc020175e:	cf49                	beqz	a4,ffffffffc02017f8 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0201760:	0007a823          	sw	zero,16(a5)
ffffffffc0201764:	0007b423          	sd	zero,8(a5)
ffffffffc0201768:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc020176c:	04078793          	addi	a5,a5,64
ffffffffc0201770:	fed795e3          	bne	a5,a3,ffffffffc020175a <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201774:	2581                	sext.w	a1,a1
ffffffffc0201776:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201778:	4789                	li	a5,2
ffffffffc020177a:	00850713          	addi	a4,a0,8
ffffffffc020177e:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201782:	00008697          	auipc	a3,0x8
ffffffffc0201786:	cae68693          	addi	a3,a3,-850 # ffffffffc0209430 <free_area>
ffffffffc020178a:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020178c:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020178e:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201792:	9db9                	addw	a1,a1,a4
ffffffffc0201794:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list))
ffffffffc0201796:	04d78a63          	beq	a5,a3,ffffffffc02017ea <default_init_memmap+0xa2>
            struct Page *page = le2page(le, page_link);
ffffffffc020179a:	fe878713          	addi	a4,a5,-24
ffffffffc020179e:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list))
ffffffffc02017a2:	4581                	li	a1,0
            if (base < page)
ffffffffc02017a4:	00e56a63          	bltu	a0,a4,ffffffffc02017b8 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02017a8:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02017aa:	02d70263          	beq	a4,a3,ffffffffc02017ce <default_init_memmap+0x86>
    for (; p != base + n; p++)
ffffffffc02017ae:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02017b0:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02017b4:	fee57ae3          	bgeu	a0,a4,ffffffffc02017a8 <default_init_memmap+0x60>
ffffffffc02017b8:	c199                	beqz	a1,ffffffffc02017be <default_init_memmap+0x76>
ffffffffc02017ba:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02017be:	6398                	ld	a4,0(a5)
}
ffffffffc02017c0:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02017c2:	e390                	sd	a2,0(a5)
ffffffffc02017c4:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02017c6:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02017c8:	ed18                	sd	a4,24(a0)
ffffffffc02017ca:	0141                	addi	sp,sp,16
ffffffffc02017cc:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02017ce:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02017d0:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02017d2:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02017d4:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list)
ffffffffc02017d6:	00d70663          	beq	a4,a3,ffffffffc02017e2 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc02017da:	8832                	mv	a6,a2
ffffffffc02017dc:	4585                	li	a1,1
    for (; p != base + n; p++)
ffffffffc02017de:	87ba                	mv	a5,a4
ffffffffc02017e0:	bfc1                	j	ffffffffc02017b0 <default_init_memmap+0x68>
}
ffffffffc02017e2:	60a2                	ld	ra,8(sp)
ffffffffc02017e4:	e290                	sd	a2,0(a3)
ffffffffc02017e6:	0141                	addi	sp,sp,16
ffffffffc02017e8:	8082                	ret
ffffffffc02017ea:	60a2                	ld	ra,8(sp)
ffffffffc02017ec:	e390                	sd	a2,0(a5)
ffffffffc02017ee:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02017f0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02017f2:	ed1c                	sd	a5,24(a0)
ffffffffc02017f4:	0141                	addi	sp,sp,16
ffffffffc02017f6:	8082                	ret
        assert(PageReserved(p));
ffffffffc02017f8:	00003697          	auipc	a3,0x3
ffffffffc02017fc:	38868693          	addi	a3,a3,904 # ffffffffc0204b80 <commands+0xa90>
ffffffffc0201800:	00003617          	auipc	a2,0x3
ffffffffc0201804:	ff860613          	addi	a2,a2,-8 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201808:	04c00593          	li	a1,76
ffffffffc020180c:	00003517          	auipc	a0,0x3
ffffffffc0201810:	00450513          	addi	a0,a0,4 # ffffffffc0204810 <commands+0x720>
ffffffffc0201814:	c47fe0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(n > 0);
ffffffffc0201818:	00003697          	auipc	a3,0x3
ffffffffc020181c:	33868693          	addi	a3,a3,824 # ffffffffc0204b50 <commands+0xa60>
ffffffffc0201820:	00003617          	auipc	a2,0x3
ffffffffc0201824:	fd860613          	addi	a2,a2,-40 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201828:	04800593          	li	a1,72
ffffffffc020182c:	00003517          	auipc	a0,0x3
ffffffffc0201830:	fe450513          	addi	a0,a0,-28 # ffffffffc0204810 <commands+0x720>
ffffffffc0201834:	c27fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201838 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201838:	c94d                	beqz	a0,ffffffffc02018ea <slob_free+0xb2>
{
ffffffffc020183a:	1141                	addi	sp,sp,-16
ffffffffc020183c:	e022                	sd	s0,0(sp)
ffffffffc020183e:	e406                	sd	ra,8(sp)
ffffffffc0201840:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201842:	e9c1                	bnez	a1,ffffffffc02018d2 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201844:	100027f3          	csrr	a5,sstatus
ffffffffc0201848:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020184a:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020184c:	ebd9                	bnez	a5,ffffffffc02018e2 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020184e:	00007617          	auipc	a2,0x7
ffffffffc0201852:	7d260613          	addi	a2,a2,2002 # ffffffffc0209020 <slobfree>
ffffffffc0201856:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201858:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc020185a:	679c                	ld	a5,8(a5)
ffffffffc020185c:	02877a63          	bgeu	a4,s0,ffffffffc0201890 <slob_free+0x58>
ffffffffc0201860:	00f46463          	bltu	s0,a5,ffffffffc0201868 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201864:	fef76ae3          	bltu	a4,a5,ffffffffc0201858 <slob_free+0x20>
			break;

	if (b + b->units == cur->next)
ffffffffc0201868:	400c                	lw	a1,0(s0)
ffffffffc020186a:	00459693          	slli	a3,a1,0x4
ffffffffc020186e:	96a2                	add	a3,a3,s0
ffffffffc0201870:	02d78a63          	beq	a5,a3,ffffffffc02018a4 <slob_free+0x6c>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201874:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201876:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc0201878:	00469793          	slli	a5,a3,0x4
ffffffffc020187c:	97ba                	add	a5,a5,a4
ffffffffc020187e:	02f40e63          	beq	s0,a5,ffffffffc02018ba <slob_free+0x82>
	{
		cur->units += b->units;
		cur->next = b->next;
	}
	else
		cur->next = b;
ffffffffc0201882:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201884:	e218                	sd	a4,0(a2)
    if (flag) {
ffffffffc0201886:	e129                	bnez	a0,ffffffffc02018c8 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201888:	60a2                	ld	ra,8(sp)
ffffffffc020188a:	6402                	ld	s0,0(sp)
ffffffffc020188c:	0141                	addi	sp,sp,16
ffffffffc020188e:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201890:	fcf764e3          	bltu	a4,a5,ffffffffc0201858 <slob_free+0x20>
ffffffffc0201894:	fcf472e3          	bgeu	s0,a5,ffffffffc0201858 <slob_free+0x20>
	if (b + b->units == cur->next)
ffffffffc0201898:	400c                	lw	a1,0(s0)
ffffffffc020189a:	00459693          	slli	a3,a1,0x4
ffffffffc020189e:	96a2                	add	a3,a3,s0
ffffffffc02018a0:	fcd79ae3          	bne	a5,a3,ffffffffc0201874 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc02018a4:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc02018a6:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc02018a8:	9db5                	addw	a1,a1,a3
ffffffffc02018aa:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b)
ffffffffc02018ac:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc02018ae:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b)
ffffffffc02018b0:	00469793          	slli	a5,a3,0x4
ffffffffc02018b4:	97ba                	add	a5,a5,a4
ffffffffc02018b6:	fcf416e3          	bne	s0,a5,ffffffffc0201882 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc02018ba:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc02018bc:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc02018be:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc02018c0:	9ebd                	addw	a3,a3,a5
ffffffffc02018c2:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc02018c4:	e70c                	sd	a1,8(a4)
ffffffffc02018c6:	d169                	beqz	a0,ffffffffc0201888 <slob_free+0x50>
}
ffffffffc02018c8:	6402                	ld	s0,0(sp)
ffffffffc02018ca:	60a2                	ld	ra,8(sp)
ffffffffc02018cc:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02018ce:	85cff06f          	j	ffffffffc020092a <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc02018d2:	25bd                	addiw	a1,a1,15
ffffffffc02018d4:	8191                	srli	a1,a1,0x4
ffffffffc02018d6:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02018d8:	100027f3          	csrr	a5,sstatus
ffffffffc02018dc:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02018de:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02018e0:	d7bd                	beqz	a5,ffffffffc020184e <slob_free+0x16>
        intr_disable();
ffffffffc02018e2:	84eff0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        return 1;
ffffffffc02018e6:	4505                	li	a0,1
ffffffffc02018e8:	b79d                	j	ffffffffc020184e <slob_free+0x16>
ffffffffc02018ea:	8082                	ret

ffffffffc02018ec <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc02018ec:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02018ee:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc02018f0:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02018f4:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc02018f6:	34e000ef          	jal	ra,ffffffffc0201c44 <alloc_pages>
	if (!page)
ffffffffc02018fa:	c91d                	beqz	a0,ffffffffc0201930 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc02018fc:	0000c697          	auipc	a3,0xc
ffffffffc0201900:	bbc6b683          	ld	a3,-1092(a3) # ffffffffc020d4b8 <pages>
ffffffffc0201904:	8d15                	sub	a0,a0,a3
ffffffffc0201906:	8519                	srai	a0,a0,0x6
ffffffffc0201908:	00004697          	auipc	a3,0x4
ffffffffc020190c:	fb86b683          	ld	a3,-72(a3) # ffffffffc02058c0 <nbase>
ffffffffc0201910:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201912:	00c51793          	slli	a5,a0,0xc
ffffffffc0201916:	83b1                	srli	a5,a5,0xc
ffffffffc0201918:	0000c717          	auipc	a4,0xc
ffffffffc020191c:	b9873703          	ld	a4,-1128(a4) # ffffffffc020d4b0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201920:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201922:	00e7fa63          	bgeu	a5,a4,ffffffffc0201936 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201926:	0000c697          	auipc	a3,0xc
ffffffffc020192a:	ba26b683          	ld	a3,-1118(a3) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc020192e:	9536                	add	a0,a0,a3
}
ffffffffc0201930:	60a2                	ld	ra,8(sp)
ffffffffc0201932:	0141                	addi	sp,sp,16
ffffffffc0201934:	8082                	ret
ffffffffc0201936:	86aa                	mv	a3,a0
ffffffffc0201938:	00003617          	auipc	a2,0x3
ffffffffc020193c:	2a860613          	addi	a2,a2,680 # ffffffffc0204be0 <default_pmm_manager+0x38>
ffffffffc0201940:	07100593          	li	a1,113
ffffffffc0201944:	00003517          	auipc	a0,0x3
ffffffffc0201948:	2c450513          	addi	a0,a0,708 # ffffffffc0204c08 <default_pmm_manager+0x60>
ffffffffc020194c:	b0ffe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201950 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201950:	1101                	addi	sp,sp,-32
ffffffffc0201952:	ec06                	sd	ra,24(sp)
ffffffffc0201954:	e822                	sd	s0,16(sp)
ffffffffc0201956:	e426                	sd	s1,8(sp)
ffffffffc0201958:	e04a                	sd	s2,0(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc020195a:	01050713          	addi	a4,a0,16
ffffffffc020195e:	6785                	lui	a5,0x1
ffffffffc0201960:	0cf77363          	bgeu	a4,a5,ffffffffc0201a26 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201964:	00f50493          	addi	s1,a0,15
ffffffffc0201968:	8091                	srli	s1,s1,0x4
ffffffffc020196a:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020196c:	10002673          	csrr	a2,sstatus
ffffffffc0201970:	8a09                	andi	a2,a2,2
ffffffffc0201972:	e25d                	bnez	a2,ffffffffc0201a18 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201974:	00007917          	auipc	s2,0x7
ffffffffc0201978:	6ac90913          	addi	s2,s2,1708 # ffffffffc0209020 <slobfree>
ffffffffc020197c:	00093683          	ld	a3,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201980:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta)
ffffffffc0201982:	4398                	lw	a4,0(a5)
ffffffffc0201984:	08975e63          	bge	a4,s1,ffffffffc0201a20 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree)
ffffffffc0201988:	00d78b63          	beq	a5,a3,ffffffffc020199e <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc020198c:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc020198e:	4018                	lw	a4,0(s0)
ffffffffc0201990:	02975a63          	bge	a4,s1,ffffffffc02019c4 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree)
ffffffffc0201994:	00093683          	ld	a3,0(s2)
ffffffffc0201998:	87a2                	mv	a5,s0
ffffffffc020199a:	fed799e3          	bne	a5,a3,ffffffffc020198c <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc020199e:	ee31                	bnez	a2,ffffffffc02019fa <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc02019a0:	4501                	li	a0,0
ffffffffc02019a2:	f4bff0ef          	jal	ra,ffffffffc02018ec <__slob_get_free_pages.constprop.0>
ffffffffc02019a6:	842a                	mv	s0,a0
			if (!cur)
ffffffffc02019a8:	cd05                	beqz	a0,ffffffffc02019e0 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc02019aa:	6585                	lui	a1,0x1
ffffffffc02019ac:	e8dff0ef          	jal	ra,ffffffffc0201838 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019b0:	10002673          	csrr	a2,sstatus
ffffffffc02019b4:	8a09                	andi	a2,a2,2
ffffffffc02019b6:	ee05                	bnez	a2,ffffffffc02019ee <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc02019b8:	00093783          	ld	a5,0(s2)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019bc:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta)
ffffffffc02019be:	4018                	lw	a4,0(s0)
ffffffffc02019c0:	fc974ae3          	blt	a4,s1,ffffffffc0201994 <slob_alloc.constprop.0+0x44>
			if (cur->units == units)	/* exact fit? */
ffffffffc02019c4:	04e48763          	beq	s1,a4,ffffffffc0201a12 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc02019c8:	00449693          	slli	a3,s1,0x4
ffffffffc02019cc:	96a2                	add	a3,a3,s0
ffffffffc02019ce:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc02019d0:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc02019d2:	9f05                	subw	a4,a4,s1
ffffffffc02019d4:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc02019d6:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc02019d8:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc02019da:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc02019de:	e20d                	bnez	a2,ffffffffc0201a00 <slob_alloc.constprop.0+0xb0>
}
ffffffffc02019e0:	60e2                	ld	ra,24(sp)
ffffffffc02019e2:	8522                	mv	a0,s0
ffffffffc02019e4:	6442                	ld	s0,16(sp)
ffffffffc02019e6:	64a2                	ld	s1,8(sp)
ffffffffc02019e8:	6902                	ld	s2,0(sp)
ffffffffc02019ea:	6105                	addi	sp,sp,32
ffffffffc02019ec:	8082                	ret
        intr_disable();
ffffffffc02019ee:	f43fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
			cur = slobfree;
ffffffffc02019f2:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc02019f6:	4605                	li	a2,1
ffffffffc02019f8:	b7d1                	j	ffffffffc02019bc <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc02019fa:	f31fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02019fe:	b74d                	j	ffffffffc02019a0 <slob_alloc.constprop.0+0x50>
ffffffffc0201a00:	f2bfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
}
ffffffffc0201a04:	60e2                	ld	ra,24(sp)
ffffffffc0201a06:	8522                	mv	a0,s0
ffffffffc0201a08:	6442                	ld	s0,16(sp)
ffffffffc0201a0a:	64a2                	ld	s1,8(sp)
ffffffffc0201a0c:	6902                	ld	s2,0(sp)
ffffffffc0201a0e:	6105                	addi	sp,sp,32
ffffffffc0201a10:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201a12:	6418                	ld	a4,8(s0)
ffffffffc0201a14:	e798                	sd	a4,8(a5)
ffffffffc0201a16:	b7d1                	j	ffffffffc02019da <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201a18:	f19fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        return 1;
ffffffffc0201a1c:	4605                	li	a2,1
ffffffffc0201a1e:	bf99                	j	ffffffffc0201974 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta)
ffffffffc0201a20:	843e                	mv	s0,a5
ffffffffc0201a22:	87b6                	mv	a5,a3
ffffffffc0201a24:	b745                	j	ffffffffc02019c4 <slob_alloc.constprop.0+0x74>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201a26:	00003697          	auipc	a3,0x3
ffffffffc0201a2a:	1f268693          	addi	a3,a3,498 # ffffffffc0204c18 <default_pmm_manager+0x70>
ffffffffc0201a2e:	00003617          	auipc	a2,0x3
ffffffffc0201a32:	dca60613          	addi	a2,a2,-566 # ffffffffc02047f8 <commands+0x708>
ffffffffc0201a36:	06300593          	li	a1,99
ffffffffc0201a3a:	00003517          	auipc	a0,0x3
ffffffffc0201a3e:	1fe50513          	addi	a0,a0,510 # ffffffffc0204c38 <default_pmm_manager+0x90>
ffffffffc0201a42:	a19fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201a46 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201a46:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201a48:	00003517          	auipc	a0,0x3
ffffffffc0201a4c:	20850513          	addi	a0,a0,520 # ffffffffc0204c50 <default_pmm_manager+0xa8>
{
ffffffffc0201a50:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201a52:	f42fe0ef          	jal	ra,ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201a56:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201a58:	00003517          	auipc	a0,0x3
ffffffffc0201a5c:	21050513          	addi	a0,a0,528 # ffffffffc0204c68 <default_pmm_manager+0xc0>
}
ffffffffc0201a60:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201a62:	f32fe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201a66 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201a66:	1101                	addi	sp,sp,-32
ffffffffc0201a68:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201a6a:	6905                	lui	s2,0x1
{
ffffffffc0201a6c:	e822                	sd	s0,16(sp)
ffffffffc0201a6e:	ec06                	sd	ra,24(sp)
ffffffffc0201a70:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201a72:	fef90793          	addi	a5,s2,-17 # fef <kern_entry-0xffffffffc01ff011>
{
ffffffffc0201a76:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201a78:	04a7f963          	bgeu	a5,a0,ffffffffc0201aca <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201a7c:	4561                	li	a0,24
ffffffffc0201a7e:	ed3ff0ef          	jal	ra,ffffffffc0201950 <slob_alloc.constprop.0>
ffffffffc0201a82:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201a84:	c929                	beqz	a0,ffffffffc0201ad6 <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201a86:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201a8a:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201a8c:	00f95763          	bge	s2,a5,ffffffffc0201a9a <kmalloc+0x34>
ffffffffc0201a90:	6705                	lui	a4,0x1
ffffffffc0201a92:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201a94:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201a96:	fef74ee3          	blt	a4,a5,ffffffffc0201a92 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201a9a:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201a9c:	e51ff0ef          	jal	ra,ffffffffc02018ec <__slob_get_free_pages.constprop.0>
ffffffffc0201aa0:	e488                	sd	a0,8(s1)
ffffffffc0201aa2:	842a                	mv	s0,a0
	if (bb->pages)
ffffffffc0201aa4:	c525                	beqz	a0,ffffffffc0201b0c <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201aa6:	100027f3          	csrr	a5,sstatus
ffffffffc0201aaa:	8b89                	andi	a5,a5,2
ffffffffc0201aac:	ef8d                	bnez	a5,ffffffffc0201ae6 <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201aae:	0000c797          	auipc	a5,0xc
ffffffffc0201ab2:	9ea78793          	addi	a5,a5,-1558 # ffffffffc020d498 <bigblocks>
ffffffffc0201ab6:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201ab8:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201aba:	e898                	sd	a4,16(s1)
	return __kmalloc(size, 0);
}
ffffffffc0201abc:	60e2                	ld	ra,24(sp)
ffffffffc0201abe:	8522                	mv	a0,s0
ffffffffc0201ac0:	6442                	ld	s0,16(sp)
ffffffffc0201ac2:	64a2                	ld	s1,8(sp)
ffffffffc0201ac4:	6902                	ld	s2,0(sp)
ffffffffc0201ac6:	6105                	addi	sp,sp,32
ffffffffc0201ac8:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201aca:	0541                	addi	a0,a0,16
ffffffffc0201acc:	e85ff0ef          	jal	ra,ffffffffc0201950 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201ad0:	01050413          	addi	s0,a0,16
ffffffffc0201ad4:	f565                	bnez	a0,ffffffffc0201abc <kmalloc+0x56>
ffffffffc0201ad6:	4401                	li	s0,0
}
ffffffffc0201ad8:	60e2                	ld	ra,24(sp)
ffffffffc0201ada:	8522                	mv	a0,s0
ffffffffc0201adc:	6442                	ld	s0,16(sp)
ffffffffc0201ade:	64a2                	ld	s1,8(sp)
ffffffffc0201ae0:	6902                	ld	s2,0(sp)
ffffffffc0201ae2:	6105                	addi	sp,sp,32
ffffffffc0201ae4:	8082                	ret
        intr_disable();
ffffffffc0201ae6:	e4bfe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201aea:	0000c797          	auipc	a5,0xc
ffffffffc0201aee:	9ae78793          	addi	a5,a5,-1618 # ffffffffc020d498 <bigblocks>
ffffffffc0201af2:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201af4:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201af6:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201af8:	e33fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
		return bb->pages;
ffffffffc0201afc:	6480                	ld	s0,8(s1)
}
ffffffffc0201afe:	60e2                	ld	ra,24(sp)
ffffffffc0201b00:	64a2                	ld	s1,8(sp)
ffffffffc0201b02:	8522                	mv	a0,s0
ffffffffc0201b04:	6442                	ld	s0,16(sp)
ffffffffc0201b06:	6902                	ld	s2,0(sp)
ffffffffc0201b08:	6105                	addi	sp,sp,32
ffffffffc0201b0a:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b0c:	45e1                	li	a1,24
ffffffffc0201b0e:	8526                	mv	a0,s1
ffffffffc0201b10:	d29ff0ef          	jal	ra,ffffffffc0201838 <slob_free>
	return __kmalloc(size, 0);
ffffffffc0201b14:	b765                	j	ffffffffc0201abc <kmalloc+0x56>

ffffffffc0201b16 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201b16:	c169                	beqz	a0,ffffffffc0201bd8 <kfree+0xc2>
{
ffffffffc0201b18:	1101                	addi	sp,sp,-32
ffffffffc0201b1a:	e822                	sd	s0,16(sp)
ffffffffc0201b1c:	ec06                	sd	ra,24(sp)
ffffffffc0201b1e:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201b20:	03451793          	slli	a5,a0,0x34
ffffffffc0201b24:	842a                	mv	s0,a0
ffffffffc0201b26:	e3d9                	bnez	a5,ffffffffc0201bac <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b28:	100027f3          	csrr	a5,sstatus
ffffffffc0201b2c:	8b89                	andi	a5,a5,2
ffffffffc0201b2e:	e7d9                	bnez	a5,ffffffffc0201bbc <kfree+0xa6>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b30:	0000c797          	auipc	a5,0xc
ffffffffc0201b34:	9687b783          	ld	a5,-1688(a5) # ffffffffc020d498 <bigblocks>
    return 0;
ffffffffc0201b38:	4601                	li	a2,0
ffffffffc0201b3a:	cbad                	beqz	a5,ffffffffc0201bac <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201b3c:	0000c697          	auipc	a3,0xc
ffffffffc0201b40:	95c68693          	addi	a3,a3,-1700 # ffffffffc020d498 <bigblocks>
ffffffffc0201b44:	a021                	j	ffffffffc0201b4c <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b46:	01048693          	addi	a3,s1,16
ffffffffc0201b4a:	c3a5                	beqz	a5,ffffffffc0201baa <kfree+0x94>
		{
			if (bb->pages == block)
ffffffffc0201b4c:	6798                	ld	a4,8(a5)
ffffffffc0201b4e:	84be                	mv	s1,a5
			{
				*last = bb->next;
ffffffffc0201b50:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201b52:	fe871ae3          	bne	a4,s0,ffffffffc0201b46 <kfree+0x30>
				*last = bb->next;
ffffffffc0201b56:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc0201b58:	ee2d                	bnez	a2,ffffffffc0201bd2 <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201b5a:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201b5e:	4098                	lw	a4,0(s1)
ffffffffc0201b60:	08f46963          	bltu	s0,a5,ffffffffc0201bf2 <kfree+0xdc>
ffffffffc0201b64:	0000c697          	auipc	a3,0xc
ffffffffc0201b68:	9646b683          	ld	a3,-1692(a3) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0201b6c:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage)
ffffffffc0201b6e:	8031                	srli	s0,s0,0xc
ffffffffc0201b70:	0000c797          	auipc	a5,0xc
ffffffffc0201b74:	9407b783          	ld	a5,-1728(a5) # ffffffffc020d4b0 <npage>
ffffffffc0201b78:	06f47163          	bgeu	s0,a5,ffffffffc0201bda <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201b7c:	00004517          	auipc	a0,0x4
ffffffffc0201b80:	d4453503          	ld	a0,-700(a0) # ffffffffc02058c0 <nbase>
ffffffffc0201b84:	8c09                	sub	s0,s0,a0
ffffffffc0201b86:	041a                	slli	s0,s0,0x6
	free_pages(kva2page((void *)kva), 1 << order);
ffffffffc0201b88:	0000c517          	auipc	a0,0xc
ffffffffc0201b8c:	93053503          	ld	a0,-1744(a0) # ffffffffc020d4b8 <pages>
ffffffffc0201b90:	4585                	li	a1,1
ffffffffc0201b92:	9522                	add	a0,a0,s0
ffffffffc0201b94:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201b98:	0ea000ef          	jal	ra,ffffffffc0201c82 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201b9c:	6442                	ld	s0,16(sp)
ffffffffc0201b9e:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201ba0:	8526                	mv	a0,s1
}
ffffffffc0201ba2:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201ba4:	45e1                	li	a1,24
}
ffffffffc0201ba6:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201ba8:	b941                	j	ffffffffc0201838 <slob_free>
ffffffffc0201baa:	e20d                	bnez	a2,ffffffffc0201bcc <kfree+0xb6>
ffffffffc0201bac:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201bb0:	6442                	ld	s0,16(sp)
ffffffffc0201bb2:	60e2                	ld	ra,24(sp)
ffffffffc0201bb4:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201bb6:	4581                	li	a1,0
}
ffffffffc0201bb8:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201bba:	b9bd                	j	ffffffffc0201838 <slob_free>
        intr_disable();
ffffffffc0201bbc:	d75fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201bc0:	0000c797          	auipc	a5,0xc
ffffffffc0201bc4:	8d87b783          	ld	a5,-1832(a5) # ffffffffc020d498 <bigblocks>
        return 1;
ffffffffc0201bc8:	4605                	li	a2,1
ffffffffc0201bca:	fbad                	bnez	a5,ffffffffc0201b3c <kfree+0x26>
        intr_enable();
ffffffffc0201bcc:	d5ffe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201bd0:	bff1                	j	ffffffffc0201bac <kfree+0x96>
ffffffffc0201bd2:	d59fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201bd6:	b751                	j	ffffffffc0201b5a <kfree+0x44>
ffffffffc0201bd8:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201bda:	00003617          	auipc	a2,0x3
ffffffffc0201bde:	0d660613          	addi	a2,a2,214 # ffffffffc0204cb0 <default_pmm_manager+0x108>
ffffffffc0201be2:	06900593          	li	a1,105
ffffffffc0201be6:	00003517          	auipc	a0,0x3
ffffffffc0201bea:	02250513          	addi	a0,a0,34 # ffffffffc0204c08 <default_pmm_manager+0x60>
ffffffffc0201bee:	86dfe0ef          	jal	ra,ffffffffc020045a <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201bf2:	86a2                	mv	a3,s0
ffffffffc0201bf4:	00003617          	auipc	a2,0x3
ffffffffc0201bf8:	09460613          	addi	a2,a2,148 # ffffffffc0204c88 <default_pmm_manager+0xe0>
ffffffffc0201bfc:	07700593          	li	a1,119
ffffffffc0201c00:	00003517          	auipc	a0,0x3
ffffffffc0201c04:	00850513          	addi	a0,a0,8 # ffffffffc0204c08 <default_pmm_manager+0x60>
ffffffffc0201c08:	853fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201c0c <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201c0c:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201c0e:	00003617          	auipc	a2,0x3
ffffffffc0201c12:	0a260613          	addi	a2,a2,162 # ffffffffc0204cb0 <default_pmm_manager+0x108>
ffffffffc0201c16:	06900593          	li	a1,105
ffffffffc0201c1a:	00003517          	auipc	a0,0x3
ffffffffc0201c1e:	fee50513          	addi	a0,a0,-18 # ffffffffc0204c08 <default_pmm_manager+0x60>
pa2page(uintptr_t pa)
ffffffffc0201c22:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201c24:	837fe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201c28 <pte2page.part.0>:
pte2page(pte_t pte)
ffffffffc0201c28:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0201c2a:	00003617          	auipc	a2,0x3
ffffffffc0201c2e:	0a660613          	addi	a2,a2,166 # ffffffffc0204cd0 <default_pmm_manager+0x128>
ffffffffc0201c32:	07f00593          	li	a1,127
ffffffffc0201c36:	00003517          	auipc	a0,0x3
ffffffffc0201c3a:	fd250513          	addi	a0,a0,-46 # ffffffffc0204c08 <default_pmm_manager+0x60>
pte2page(pte_t pte)
ffffffffc0201c3e:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0201c40:	81bfe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201c44 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c44:	100027f3          	csrr	a5,sstatus
ffffffffc0201c48:	8b89                	andi	a5,a5,2
ffffffffc0201c4a:	e799                	bnez	a5,ffffffffc0201c58 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201c4c:	0000c797          	auipc	a5,0xc
ffffffffc0201c50:	8747b783          	ld	a5,-1932(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201c54:	6f9c                	ld	a5,24(a5)
ffffffffc0201c56:	8782                	jr	a5
{
ffffffffc0201c58:	1141                	addi	sp,sp,-16
ffffffffc0201c5a:	e406                	sd	ra,8(sp)
ffffffffc0201c5c:	e022                	sd	s0,0(sp)
ffffffffc0201c5e:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201c60:	cd1fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201c64:	0000c797          	auipc	a5,0xc
ffffffffc0201c68:	85c7b783          	ld	a5,-1956(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201c6c:	6f9c                	ld	a5,24(a5)
ffffffffc0201c6e:	8522                	mv	a0,s0
ffffffffc0201c70:	9782                	jalr	a5
ffffffffc0201c72:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201c74:	cb7fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201c78:	60a2                	ld	ra,8(sp)
ffffffffc0201c7a:	8522                	mv	a0,s0
ffffffffc0201c7c:	6402                	ld	s0,0(sp)
ffffffffc0201c7e:	0141                	addi	sp,sp,16
ffffffffc0201c80:	8082                	ret

ffffffffc0201c82 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c82:	100027f3          	csrr	a5,sstatus
ffffffffc0201c86:	8b89                	andi	a5,a5,2
ffffffffc0201c88:	e799                	bnez	a5,ffffffffc0201c96 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201c8a:	0000c797          	auipc	a5,0xc
ffffffffc0201c8e:	8367b783          	ld	a5,-1994(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201c92:	739c                	ld	a5,32(a5)
ffffffffc0201c94:	8782                	jr	a5
{
ffffffffc0201c96:	1101                	addi	sp,sp,-32
ffffffffc0201c98:	ec06                	sd	ra,24(sp)
ffffffffc0201c9a:	e822                	sd	s0,16(sp)
ffffffffc0201c9c:	e426                	sd	s1,8(sp)
ffffffffc0201c9e:	842a                	mv	s0,a0
ffffffffc0201ca0:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201ca2:	c8ffe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201ca6:	0000c797          	auipc	a5,0xc
ffffffffc0201caa:	81a7b783          	ld	a5,-2022(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201cae:	739c                	ld	a5,32(a5)
ffffffffc0201cb0:	85a6                	mv	a1,s1
ffffffffc0201cb2:	8522                	mv	a0,s0
ffffffffc0201cb4:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201cb6:	6442                	ld	s0,16(sp)
ffffffffc0201cb8:	60e2                	ld	ra,24(sp)
ffffffffc0201cba:	64a2                	ld	s1,8(sp)
ffffffffc0201cbc:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201cbe:	c6dfe06f          	j	ffffffffc020092a <intr_enable>

ffffffffc0201cc2 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201cc2:	100027f3          	csrr	a5,sstatus
ffffffffc0201cc6:	8b89                	andi	a5,a5,2
ffffffffc0201cc8:	e799                	bnez	a5,ffffffffc0201cd6 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201cca:	0000b797          	auipc	a5,0xb
ffffffffc0201cce:	7f67b783          	ld	a5,2038(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201cd2:	779c                	ld	a5,40(a5)
ffffffffc0201cd4:	8782                	jr	a5
{
ffffffffc0201cd6:	1141                	addi	sp,sp,-16
ffffffffc0201cd8:	e406                	sd	ra,8(sp)
ffffffffc0201cda:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201cdc:	c55fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201ce0:	0000b797          	auipc	a5,0xb
ffffffffc0201ce4:	7e07b783          	ld	a5,2016(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201ce8:	779c                	ld	a5,40(a5)
ffffffffc0201cea:	9782                	jalr	a5
ffffffffc0201cec:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201cee:	c3dfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201cf2:	60a2                	ld	ra,8(sp)
ffffffffc0201cf4:	8522                	mv	a0,s0
ffffffffc0201cf6:	6402                	ld	s0,0(sp)
ffffffffc0201cf8:	0141                	addi	sp,sp,16
ffffffffc0201cfa:	8082                	ret

ffffffffc0201cfc <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201cfc:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201d00:	1ff7f793          	andi	a5,a5,511
{
ffffffffc0201d04:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201d06:	078e                	slli	a5,a5,0x3
{
ffffffffc0201d08:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201d0a:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201d0e:	6094                	ld	a3,0(s1)
{
ffffffffc0201d10:	f04a                	sd	s2,32(sp)
ffffffffc0201d12:	ec4e                	sd	s3,24(sp)
ffffffffc0201d14:	e852                	sd	s4,16(sp)
ffffffffc0201d16:	fc06                	sd	ra,56(sp)
ffffffffc0201d18:	f822                	sd	s0,48(sp)
ffffffffc0201d1a:	e456                	sd	s5,8(sp)
ffffffffc0201d1c:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201d1e:	0016f793          	andi	a5,a3,1
{
ffffffffc0201d22:	892e                	mv	s2,a1
ffffffffc0201d24:	8a32                	mv	s4,a2
ffffffffc0201d26:	0000b997          	auipc	s3,0xb
ffffffffc0201d2a:	78a98993          	addi	s3,s3,1930 # ffffffffc020d4b0 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201d2e:	efbd                	bnez	a5,ffffffffc0201dac <get_pte+0xb0>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201d30:	14060c63          	beqz	a2,ffffffffc0201e88 <get_pte+0x18c>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d34:	100027f3          	csrr	a5,sstatus
ffffffffc0201d38:	8b89                	andi	a5,a5,2
ffffffffc0201d3a:	14079963          	bnez	a5,ffffffffc0201e8c <get_pte+0x190>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201d3e:	0000b797          	auipc	a5,0xb
ffffffffc0201d42:	7827b783          	ld	a5,1922(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201d46:	6f9c                	ld	a5,24(a5)
ffffffffc0201d48:	4505                	li	a0,1
ffffffffc0201d4a:	9782                	jalr	a5
ffffffffc0201d4c:	842a                	mv	s0,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201d4e:	12040d63          	beqz	s0,ffffffffc0201e88 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201d52:	0000bb17          	auipc	s6,0xb
ffffffffc0201d56:	766b0b13          	addi	s6,s6,1894 # ffffffffc020d4b8 <pages>
ffffffffc0201d5a:	000b3503          	ld	a0,0(s6)
ffffffffc0201d5e:	00080ab7          	lui	s5,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201d62:	0000b997          	auipc	s3,0xb
ffffffffc0201d66:	74e98993          	addi	s3,s3,1870 # ffffffffc020d4b0 <npage>
ffffffffc0201d6a:	40a40533          	sub	a0,s0,a0
ffffffffc0201d6e:	8519                	srai	a0,a0,0x6
ffffffffc0201d70:	9556                	add	a0,a0,s5
ffffffffc0201d72:	0009b703          	ld	a4,0(s3)
ffffffffc0201d76:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201d7a:	4685                	li	a3,1
ffffffffc0201d7c:	c014                	sw	a3,0(s0)
ffffffffc0201d7e:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201d80:	0532                	slli	a0,a0,0xc
ffffffffc0201d82:	16e7f763          	bgeu	a5,a4,ffffffffc0201ef0 <get_pte+0x1f4>
ffffffffc0201d86:	0000b797          	auipc	a5,0xb
ffffffffc0201d8a:	7427b783          	ld	a5,1858(a5) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0201d8e:	6605                	lui	a2,0x1
ffffffffc0201d90:	4581                	li	a1,0
ffffffffc0201d92:	953e                	add	a0,a0,a5
ffffffffc0201d94:	0a2020ef          	jal	ra,ffffffffc0203e36 <memset>
    return page - pages + nbase;
ffffffffc0201d98:	000b3683          	ld	a3,0(s6)
ffffffffc0201d9c:	40d406b3          	sub	a3,s0,a3
ffffffffc0201da0:	8699                	srai	a3,a3,0x6
ffffffffc0201da2:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201da4:	06aa                	slli	a3,a3,0xa
ffffffffc0201da6:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201daa:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201dac:	77fd                	lui	a5,0xfffff
ffffffffc0201dae:	068a                	slli	a3,a3,0x2
ffffffffc0201db0:	0009b703          	ld	a4,0(s3)
ffffffffc0201db4:	8efd                	and	a3,a3,a5
ffffffffc0201db6:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201dba:	10e7ff63          	bgeu	a5,a4,ffffffffc0201ed8 <get_pte+0x1dc>
ffffffffc0201dbe:	0000ba97          	auipc	s5,0xb
ffffffffc0201dc2:	70aa8a93          	addi	s5,s5,1802 # ffffffffc020d4c8 <va_pa_offset>
ffffffffc0201dc6:	000ab403          	ld	s0,0(s5)
ffffffffc0201dca:	01595793          	srli	a5,s2,0x15
ffffffffc0201dce:	1ff7f793          	andi	a5,a5,511
ffffffffc0201dd2:	96a2                	add	a3,a3,s0
ffffffffc0201dd4:	00379413          	slli	s0,a5,0x3
ffffffffc0201dd8:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201dda:	6014                	ld	a3,0(s0)
ffffffffc0201ddc:	0016f793          	andi	a5,a3,1
ffffffffc0201de0:	ebad                	bnez	a5,ffffffffc0201e52 <get_pte+0x156>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201de2:	0a0a0363          	beqz	s4,ffffffffc0201e88 <get_pte+0x18c>
ffffffffc0201de6:	100027f3          	csrr	a5,sstatus
ffffffffc0201dea:	8b89                	andi	a5,a5,2
ffffffffc0201dec:	efcd                	bnez	a5,ffffffffc0201ea6 <get_pte+0x1aa>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201dee:	0000b797          	auipc	a5,0xb
ffffffffc0201df2:	6d27b783          	ld	a5,1746(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201df6:	6f9c                	ld	a5,24(a5)
ffffffffc0201df8:	4505                	li	a0,1
ffffffffc0201dfa:	9782                	jalr	a5
ffffffffc0201dfc:	84aa                	mv	s1,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201dfe:	c4c9                	beqz	s1,ffffffffc0201e88 <get_pte+0x18c>
    return page - pages + nbase;
ffffffffc0201e00:	0000bb17          	auipc	s6,0xb
ffffffffc0201e04:	6b8b0b13          	addi	s6,s6,1720 # ffffffffc020d4b8 <pages>
ffffffffc0201e08:	000b3503          	ld	a0,0(s6)
ffffffffc0201e0c:	00080a37          	lui	s4,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201e10:	0009b703          	ld	a4,0(s3)
ffffffffc0201e14:	40a48533          	sub	a0,s1,a0
ffffffffc0201e18:	8519                	srai	a0,a0,0x6
ffffffffc0201e1a:	9552                	add	a0,a0,s4
ffffffffc0201e1c:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc0201e20:	4685                	li	a3,1
ffffffffc0201e22:	c094                	sw	a3,0(s1)
ffffffffc0201e24:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201e26:	0532                	slli	a0,a0,0xc
ffffffffc0201e28:	0ee7f163          	bgeu	a5,a4,ffffffffc0201f0a <get_pte+0x20e>
ffffffffc0201e2c:	000ab783          	ld	a5,0(s5)
ffffffffc0201e30:	6605                	lui	a2,0x1
ffffffffc0201e32:	4581                	li	a1,0
ffffffffc0201e34:	953e                	add	a0,a0,a5
ffffffffc0201e36:	000020ef          	jal	ra,ffffffffc0203e36 <memset>
    return page - pages + nbase;
ffffffffc0201e3a:	000b3683          	ld	a3,0(s6)
ffffffffc0201e3e:	40d486b3          	sub	a3,s1,a3
ffffffffc0201e42:	8699                	srai	a3,a3,0x6
ffffffffc0201e44:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201e46:	06aa                	slli	a3,a3,0xa
ffffffffc0201e48:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201e4c:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201e4e:	0009b703          	ld	a4,0(s3)
ffffffffc0201e52:	068a                	slli	a3,a3,0x2
ffffffffc0201e54:	757d                	lui	a0,0xfffff
ffffffffc0201e56:	8ee9                	and	a3,a3,a0
ffffffffc0201e58:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201e5c:	06e7f263          	bgeu	a5,a4,ffffffffc0201ec0 <get_pte+0x1c4>
ffffffffc0201e60:	000ab503          	ld	a0,0(s5)
ffffffffc0201e64:	00c95913          	srli	s2,s2,0xc
ffffffffc0201e68:	1ff97913          	andi	s2,s2,511
ffffffffc0201e6c:	96aa                	add	a3,a3,a0
ffffffffc0201e6e:	00391513          	slli	a0,s2,0x3
ffffffffc0201e72:	9536                	add	a0,a0,a3
}
ffffffffc0201e74:	70e2                	ld	ra,56(sp)
ffffffffc0201e76:	7442                	ld	s0,48(sp)
ffffffffc0201e78:	74a2                	ld	s1,40(sp)
ffffffffc0201e7a:	7902                	ld	s2,32(sp)
ffffffffc0201e7c:	69e2                	ld	s3,24(sp)
ffffffffc0201e7e:	6a42                	ld	s4,16(sp)
ffffffffc0201e80:	6aa2                	ld	s5,8(sp)
ffffffffc0201e82:	6b02                	ld	s6,0(sp)
ffffffffc0201e84:	6121                	addi	sp,sp,64
ffffffffc0201e86:	8082                	ret
            return NULL;
ffffffffc0201e88:	4501                	li	a0,0
ffffffffc0201e8a:	b7ed                	j	ffffffffc0201e74 <get_pte+0x178>
        intr_disable();
ffffffffc0201e8c:	aa5fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e90:	0000b797          	auipc	a5,0xb
ffffffffc0201e94:	6307b783          	ld	a5,1584(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201e98:	6f9c                	ld	a5,24(a5)
ffffffffc0201e9a:	4505                	li	a0,1
ffffffffc0201e9c:	9782                	jalr	a5
ffffffffc0201e9e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201ea0:	a8bfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201ea4:	b56d                	j	ffffffffc0201d4e <get_pte+0x52>
        intr_disable();
ffffffffc0201ea6:	a8bfe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0201eaa:	0000b797          	auipc	a5,0xb
ffffffffc0201eae:	6167b783          	ld	a5,1558(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201eb2:	6f9c                	ld	a5,24(a5)
ffffffffc0201eb4:	4505                	li	a0,1
ffffffffc0201eb6:	9782                	jalr	a5
ffffffffc0201eb8:	84aa                	mv	s1,a0
        intr_enable();
ffffffffc0201eba:	a71fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0201ebe:	b781                	j	ffffffffc0201dfe <get_pte+0x102>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201ec0:	00003617          	auipc	a2,0x3
ffffffffc0201ec4:	d2060613          	addi	a2,a2,-736 # ffffffffc0204be0 <default_pmm_manager+0x38>
ffffffffc0201ec8:	0fb00593          	li	a1,251
ffffffffc0201ecc:	00003517          	auipc	a0,0x3
ffffffffc0201ed0:	e2c50513          	addi	a0,a0,-468 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0201ed4:	d86fe0ef          	jal	ra,ffffffffc020045a <__panic>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201ed8:	00003617          	auipc	a2,0x3
ffffffffc0201edc:	d0860613          	addi	a2,a2,-760 # ffffffffc0204be0 <default_pmm_manager+0x38>
ffffffffc0201ee0:	0ee00593          	li	a1,238
ffffffffc0201ee4:	00003517          	auipc	a0,0x3
ffffffffc0201ee8:	e1450513          	addi	a0,a0,-492 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0201eec:	d6efe0ef          	jal	ra,ffffffffc020045a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201ef0:	86aa                	mv	a3,a0
ffffffffc0201ef2:	00003617          	auipc	a2,0x3
ffffffffc0201ef6:	cee60613          	addi	a2,a2,-786 # ffffffffc0204be0 <default_pmm_manager+0x38>
ffffffffc0201efa:	0eb00593          	li	a1,235
ffffffffc0201efe:	00003517          	auipc	a0,0x3
ffffffffc0201f02:	dfa50513          	addi	a0,a0,-518 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0201f06:	d54fe0ef          	jal	ra,ffffffffc020045a <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f0a:	86aa                	mv	a3,a0
ffffffffc0201f0c:	00003617          	auipc	a2,0x3
ffffffffc0201f10:	cd460613          	addi	a2,a2,-812 # ffffffffc0204be0 <default_pmm_manager+0x38>
ffffffffc0201f14:	0f800593          	li	a1,248
ffffffffc0201f18:	00003517          	auipc	a0,0x3
ffffffffc0201f1c:	de050513          	addi	a0,a0,-544 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0201f20:	d3afe0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0201f24 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0201f24:	1141                	addi	sp,sp,-16
ffffffffc0201f26:	e022                	sd	s0,0(sp)
ffffffffc0201f28:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f2a:	4601                	li	a2,0
{
ffffffffc0201f2c:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f2e:	dcfff0ef          	jal	ra,ffffffffc0201cfc <get_pte>
    if (ptep_store != NULL)
ffffffffc0201f32:	c011                	beqz	s0,ffffffffc0201f36 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0201f34:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f36:	c511                	beqz	a0,ffffffffc0201f42 <get_page+0x1e>
ffffffffc0201f38:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201f3a:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f3c:	0017f713          	andi	a4,a5,1
ffffffffc0201f40:	e709                	bnez	a4,ffffffffc0201f4a <get_page+0x26>
}
ffffffffc0201f42:	60a2                	ld	ra,8(sp)
ffffffffc0201f44:	6402                	ld	s0,0(sp)
ffffffffc0201f46:	0141                	addi	sp,sp,16
ffffffffc0201f48:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201f4a:	078a                	slli	a5,a5,0x2
ffffffffc0201f4c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201f4e:	0000b717          	auipc	a4,0xb
ffffffffc0201f52:	56273703          	ld	a4,1378(a4) # ffffffffc020d4b0 <npage>
ffffffffc0201f56:	00e7ff63          	bgeu	a5,a4,ffffffffc0201f74 <get_page+0x50>
ffffffffc0201f5a:	60a2                	ld	ra,8(sp)
ffffffffc0201f5c:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0201f5e:	fff80537          	lui	a0,0xfff80
ffffffffc0201f62:	97aa                	add	a5,a5,a0
ffffffffc0201f64:	079a                	slli	a5,a5,0x6
ffffffffc0201f66:	0000b517          	auipc	a0,0xb
ffffffffc0201f6a:	55253503          	ld	a0,1362(a0) # ffffffffc020d4b8 <pages>
ffffffffc0201f6e:	953e                	add	a0,a0,a5
ffffffffc0201f70:	0141                	addi	sp,sp,16
ffffffffc0201f72:	8082                	ret
ffffffffc0201f74:	c99ff0ef          	jal	ra,ffffffffc0201c0c <pa2page.part.0>

ffffffffc0201f78 <page_remove>:
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la)
{
ffffffffc0201f78:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f7a:	4601                	li	a2,0
{
ffffffffc0201f7c:	ec26                	sd	s1,24(sp)
ffffffffc0201f7e:	f406                	sd	ra,40(sp)
ffffffffc0201f80:	f022                	sd	s0,32(sp)
ffffffffc0201f82:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f84:	d79ff0ef          	jal	ra,ffffffffc0201cfc <get_pte>
    if (ptep != NULL)
ffffffffc0201f88:	c511                	beqz	a0,ffffffffc0201f94 <page_remove+0x1c>
    if (*ptep & PTE_V)
ffffffffc0201f8a:	611c                	ld	a5,0(a0)
ffffffffc0201f8c:	842a                	mv	s0,a0
ffffffffc0201f8e:	0017f713          	andi	a4,a5,1
ffffffffc0201f92:	e711                	bnez	a4,ffffffffc0201f9e <page_remove+0x26>
    {
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0201f94:	70a2                	ld	ra,40(sp)
ffffffffc0201f96:	7402                	ld	s0,32(sp)
ffffffffc0201f98:	64e2                	ld	s1,24(sp)
ffffffffc0201f9a:	6145                	addi	sp,sp,48
ffffffffc0201f9c:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0201f9e:	078a                	slli	a5,a5,0x2
ffffffffc0201fa0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201fa2:	0000b717          	auipc	a4,0xb
ffffffffc0201fa6:	50e73703          	ld	a4,1294(a4) # ffffffffc020d4b0 <npage>
ffffffffc0201faa:	06e7f363          	bgeu	a5,a4,ffffffffc0202010 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0201fae:	fff80537          	lui	a0,0xfff80
ffffffffc0201fb2:	97aa                	add	a5,a5,a0
ffffffffc0201fb4:	079a                	slli	a5,a5,0x6
ffffffffc0201fb6:	0000b517          	auipc	a0,0xb
ffffffffc0201fba:	50253503          	ld	a0,1282(a0) # ffffffffc020d4b8 <pages>
ffffffffc0201fbe:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0201fc0:	411c                	lw	a5,0(a0)
ffffffffc0201fc2:	fff7871b          	addiw	a4,a5,-1
ffffffffc0201fc6:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0201fc8:	cb11                	beqz	a4,ffffffffc0201fdc <page_remove+0x64>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0201fca:	00043023          	sd	zero,0(s0)
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201fce:	12048073          	sfence.vma	s1
}
ffffffffc0201fd2:	70a2                	ld	ra,40(sp)
ffffffffc0201fd4:	7402                	ld	s0,32(sp)
ffffffffc0201fd6:	64e2                	ld	s1,24(sp)
ffffffffc0201fd8:	6145                	addi	sp,sp,48
ffffffffc0201fda:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201fdc:	100027f3          	csrr	a5,sstatus
ffffffffc0201fe0:	8b89                	andi	a5,a5,2
ffffffffc0201fe2:	eb89                	bnez	a5,ffffffffc0201ff4 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0201fe4:	0000b797          	auipc	a5,0xb
ffffffffc0201fe8:	4dc7b783          	ld	a5,1244(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0201fec:	739c                	ld	a5,32(a5)
ffffffffc0201fee:	4585                	li	a1,1
ffffffffc0201ff0:	9782                	jalr	a5
    if (flag) {
ffffffffc0201ff2:	bfe1                	j	ffffffffc0201fca <page_remove+0x52>
        intr_disable();
ffffffffc0201ff4:	e42a                	sd	a0,8(sp)
ffffffffc0201ff6:	93bfe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0201ffa:	0000b797          	auipc	a5,0xb
ffffffffc0201ffe:	4c67b783          	ld	a5,1222(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc0202002:	739c                	ld	a5,32(a5)
ffffffffc0202004:	6522                	ld	a0,8(sp)
ffffffffc0202006:	4585                	li	a1,1
ffffffffc0202008:	9782                	jalr	a5
        intr_enable();
ffffffffc020200a:	921fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020200e:	bf75                	j	ffffffffc0201fca <page_remove+0x52>
ffffffffc0202010:	bfdff0ef          	jal	ra,ffffffffc0201c0c <pa2page.part.0>

ffffffffc0202014 <page_insert>:
{
ffffffffc0202014:	7139                	addi	sp,sp,-64
ffffffffc0202016:	e852                	sd	s4,16(sp)
ffffffffc0202018:	8a32                	mv	s4,a2
ffffffffc020201a:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020201c:	4605                	li	a2,1
{
ffffffffc020201e:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202020:	85d2                	mv	a1,s4
{
ffffffffc0202022:	f426                	sd	s1,40(sp)
ffffffffc0202024:	fc06                	sd	ra,56(sp)
ffffffffc0202026:	f04a                	sd	s2,32(sp)
ffffffffc0202028:	ec4e                	sd	s3,24(sp)
ffffffffc020202a:	e456                	sd	s5,8(sp)
ffffffffc020202c:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020202e:	ccfff0ef          	jal	ra,ffffffffc0201cfc <get_pte>
    if (ptep == NULL)
ffffffffc0202032:	c961                	beqz	a0,ffffffffc0202102 <page_insert+0xee>
    page->ref += 1;
ffffffffc0202034:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202036:	611c                	ld	a5,0(a0)
ffffffffc0202038:	89aa                	mv	s3,a0
ffffffffc020203a:	0016871b          	addiw	a4,a3,1
ffffffffc020203e:	c018                	sw	a4,0(s0)
ffffffffc0202040:	0017f713          	andi	a4,a5,1
ffffffffc0202044:	ef05                	bnez	a4,ffffffffc020207c <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0202046:	0000b717          	auipc	a4,0xb
ffffffffc020204a:	47273703          	ld	a4,1138(a4) # ffffffffc020d4b8 <pages>
ffffffffc020204e:	8c19                	sub	s0,s0,a4
ffffffffc0202050:	000807b7          	lui	a5,0x80
ffffffffc0202054:	8419                	srai	s0,s0,0x6
ffffffffc0202056:	943e                	add	s0,s0,a5
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202058:	042a                	slli	s0,s0,0xa
ffffffffc020205a:	8cc1                	or	s1,s1,s0
ffffffffc020205c:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0202060:	0099b023          	sd	s1,0(s3)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202064:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0202068:	4501                	li	a0,0
}
ffffffffc020206a:	70e2                	ld	ra,56(sp)
ffffffffc020206c:	7442                	ld	s0,48(sp)
ffffffffc020206e:	74a2                	ld	s1,40(sp)
ffffffffc0202070:	7902                	ld	s2,32(sp)
ffffffffc0202072:	69e2                	ld	s3,24(sp)
ffffffffc0202074:	6a42                	ld	s4,16(sp)
ffffffffc0202076:	6aa2                	ld	s5,8(sp)
ffffffffc0202078:	6121                	addi	sp,sp,64
ffffffffc020207a:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020207c:	078a                	slli	a5,a5,0x2
ffffffffc020207e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202080:	0000b717          	auipc	a4,0xb
ffffffffc0202084:	43073703          	ld	a4,1072(a4) # ffffffffc020d4b0 <npage>
ffffffffc0202088:	06e7ff63          	bgeu	a5,a4,ffffffffc0202106 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc020208c:	0000ba97          	auipc	s5,0xb
ffffffffc0202090:	42ca8a93          	addi	s5,s5,1068 # ffffffffc020d4b8 <pages>
ffffffffc0202094:	000ab703          	ld	a4,0(s5)
ffffffffc0202098:	fff80937          	lui	s2,0xfff80
ffffffffc020209c:	993e                	add	s2,s2,a5
ffffffffc020209e:	091a                	slli	s2,s2,0x6
ffffffffc02020a0:	993a                	add	s2,s2,a4
        if (p == page)
ffffffffc02020a2:	01240c63          	beq	s0,s2,ffffffffc02020ba <page_insert+0xa6>
    page->ref -= 1;
ffffffffc02020a6:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fd72b14>
ffffffffc02020aa:	fff7869b          	addiw	a3,a5,-1
ffffffffc02020ae:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc02020b2:	c691                	beqz	a3,ffffffffc02020be <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02020b4:	120a0073          	sfence.vma	s4
}
ffffffffc02020b8:	bf59                	j	ffffffffc020204e <page_insert+0x3a>
ffffffffc02020ba:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc02020bc:	bf49                	j	ffffffffc020204e <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02020be:	100027f3          	csrr	a5,sstatus
ffffffffc02020c2:	8b89                	andi	a5,a5,2
ffffffffc02020c4:	ef91                	bnez	a5,ffffffffc02020e0 <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc02020c6:	0000b797          	auipc	a5,0xb
ffffffffc02020ca:	3fa7b783          	ld	a5,1018(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc02020ce:	739c                	ld	a5,32(a5)
ffffffffc02020d0:	4585                	li	a1,1
ffffffffc02020d2:	854a                	mv	a0,s2
ffffffffc02020d4:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc02020d6:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02020da:	120a0073          	sfence.vma	s4
ffffffffc02020de:	bf85                	j	ffffffffc020204e <page_insert+0x3a>
        intr_disable();
ffffffffc02020e0:	851fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02020e4:	0000b797          	auipc	a5,0xb
ffffffffc02020e8:	3dc7b783          	ld	a5,988(a5) # ffffffffc020d4c0 <pmm_manager>
ffffffffc02020ec:	739c                	ld	a5,32(a5)
ffffffffc02020ee:	4585                	li	a1,1
ffffffffc02020f0:	854a                	mv	a0,s2
ffffffffc02020f2:	9782                	jalr	a5
        intr_enable();
ffffffffc02020f4:	837fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02020f8:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02020fc:	120a0073          	sfence.vma	s4
ffffffffc0202100:	b7b9                	j	ffffffffc020204e <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0202102:	5571                	li	a0,-4
ffffffffc0202104:	b79d                	j	ffffffffc020206a <page_insert+0x56>
ffffffffc0202106:	b07ff0ef          	jal	ra,ffffffffc0201c0c <pa2page.part.0>

ffffffffc020210a <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020210a:	00003797          	auipc	a5,0x3
ffffffffc020210e:	a9e78793          	addi	a5,a5,-1378 # ffffffffc0204ba8 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202112:	638c                	ld	a1,0(a5)
{
ffffffffc0202114:	7159                	addi	sp,sp,-112
ffffffffc0202116:	f85a                	sd	s6,48(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202118:	00003517          	auipc	a0,0x3
ffffffffc020211c:	bf050513          	addi	a0,a0,-1040 # ffffffffc0204d08 <default_pmm_manager+0x160>
    pmm_manager = &default_pmm_manager;
ffffffffc0202120:	0000bb17          	auipc	s6,0xb
ffffffffc0202124:	3a0b0b13          	addi	s6,s6,928 # ffffffffc020d4c0 <pmm_manager>
{
ffffffffc0202128:	f486                	sd	ra,104(sp)
ffffffffc020212a:	e8ca                	sd	s2,80(sp)
ffffffffc020212c:	e4ce                	sd	s3,72(sp)
ffffffffc020212e:	f0a2                	sd	s0,96(sp)
ffffffffc0202130:	eca6                	sd	s1,88(sp)
ffffffffc0202132:	e0d2                	sd	s4,64(sp)
ffffffffc0202134:	fc56                	sd	s5,56(sp)
ffffffffc0202136:	f45e                	sd	s7,40(sp)
ffffffffc0202138:	f062                	sd	s8,32(sp)
ffffffffc020213a:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020213c:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202140:	854fe0ef          	jal	ra,ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc0202144:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202148:	0000b997          	auipc	s3,0xb
ffffffffc020214c:	38098993          	addi	s3,s3,896 # ffffffffc020d4c8 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202150:	679c                	ld	a5,8(a5)
ffffffffc0202152:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202154:	57f5                	li	a5,-3
ffffffffc0202156:	07fa                	slli	a5,a5,0x1e
ffffffffc0202158:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc020215c:	fbafe0ef          	jal	ra,ffffffffc0200916 <get_memory_base>
ffffffffc0202160:	892a                	mv	s2,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0202162:	fbefe0ef          	jal	ra,ffffffffc0200920 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0202166:	200505e3          	beqz	a0,ffffffffc0202b70 <pmm_init+0xa66>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc020216a:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc020216c:	00003517          	auipc	a0,0x3
ffffffffc0202170:	bd450513          	addi	a0,a0,-1068 # ffffffffc0204d40 <default_pmm_manager+0x198>
ffffffffc0202174:	820fe0ef          	jal	ra,ffffffffc0200194 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0202178:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc020217c:	fff40693          	addi	a3,s0,-1
ffffffffc0202180:	864a                	mv	a2,s2
ffffffffc0202182:	85a6                	mv	a1,s1
ffffffffc0202184:	00003517          	auipc	a0,0x3
ffffffffc0202188:	bd450513          	addi	a0,a0,-1068 # ffffffffc0204d58 <default_pmm_manager+0x1b0>
ffffffffc020218c:	808fe0ef          	jal	ra,ffffffffc0200194 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0202190:	c8000737          	lui	a4,0xc8000
ffffffffc0202194:	87a2                	mv	a5,s0
ffffffffc0202196:	54876163          	bltu	a4,s0,ffffffffc02026d8 <pmm_init+0x5ce>
ffffffffc020219a:	757d                	lui	a0,0xfffff
ffffffffc020219c:	0000c617          	auipc	a2,0xc
ffffffffc02021a0:	34f60613          	addi	a2,a2,847 # ffffffffc020e4eb <end+0xfff>
ffffffffc02021a4:	8e69                	and	a2,a2,a0
ffffffffc02021a6:	0000b497          	auipc	s1,0xb
ffffffffc02021aa:	30a48493          	addi	s1,s1,778 # ffffffffc020d4b0 <npage>
ffffffffc02021ae:	00c7d513          	srli	a0,a5,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02021b2:	0000bb97          	auipc	s7,0xb
ffffffffc02021b6:	306b8b93          	addi	s7,s7,774 # ffffffffc020d4b8 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02021ba:	e088                	sd	a0,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02021bc:	00cbb023          	sd	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02021c0:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02021c4:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02021c6:	02f50863          	beq	a0,a5,ffffffffc02021f6 <pmm_init+0xec>
ffffffffc02021ca:	4781                	li	a5,0
ffffffffc02021cc:	4585                	li	a1,1
ffffffffc02021ce:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc02021d2:	00679513          	slli	a0,a5,0x6
ffffffffc02021d6:	9532                	add	a0,a0,a2
ffffffffc02021d8:	00850713          	addi	a4,a0,8 # fffffffffffff008 <end+0x3fdf1b1c>
ffffffffc02021dc:	40b7302f          	amoor.d	zero,a1,(a4)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02021e0:	6088                	ld	a0,0(s1)
ffffffffc02021e2:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc02021e4:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02021e8:	00d50733          	add	a4,a0,a3
ffffffffc02021ec:	fee7e3e3          	bltu	a5,a4,ffffffffc02021d2 <pmm_init+0xc8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02021f0:	071a                	slli	a4,a4,0x6
ffffffffc02021f2:	00e606b3          	add	a3,a2,a4
ffffffffc02021f6:	c02007b7          	lui	a5,0xc0200
ffffffffc02021fa:	2ef6ece3          	bltu	a3,a5,ffffffffc0202cf2 <pmm_init+0xbe8>
ffffffffc02021fe:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0202202:	77fd                	lui	a5,0xfffff
ffffffffc0202204:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202206:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202208:	5086eb63          	bltu	a3,s0,ffffffffc020271e <pmm_init+0x614>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc020220c:	00003517          	auipc	a0,0x3
ffffffffc0202210:	b7450513          	addi	a0,a0,-1164 # ffffffffc0204d80 <default_pmm_manager+0x1d8>
ffffffffc0202214:	f81fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202218:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020221c:	0000b917          	auipc	s2,0xb
ffffffffc0202220:	28c90913          	addi	s2,s2,652 # ffffffffc020d4a8 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202224:	7b9c                	ld	a5,48(a5)
ffffffffc0202226:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202228:	00003517          	auipc	a0,0x3
ffffffffc020222c:	b7050513          	addi	a0,a0,-1168 # ffffffffc0204d98 <default_pmm_manager+0x1f0>
ffffffffc0202230:	f65fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202234:	00006697          	auipc	a3,0x6
ffffffffc0202238:	dcc68693          	addi	a3,a3,-564 # ffffffffc0208000 <boot_page_table_sv39>
ffffffffc020223c:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202240:	c02007b7          	lui	a5,0xc0200
ffffffffc0202244:	28f6ebe3          	bltu	a3,a5,ffffffffc0202cda <pmm_init+0xbd0>
ffffffffc0202248:	0009b783          	ld	a5,0(s3)
ffffffffc020224c:	8e9d                	sub	a3,a3,a5
ffffffffc020224e:	0000b797          	auipc	a5,0xb
ffffffffc0202252:	24d7b923          	sd	a3,594(a5) # ffffffffc020d4a0 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202256:	100027f3          	csrr	a5,sstatus
ffffffffc020225a:	8b89                	andi	a5,a5,2
ffffffffc020225c:	4a079763          	bnez	a5,ffffffffc020270a <pmm_init+0x600>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202260:	000b3783          	ld	a5,0(s6)
ffffffffc0202264:	779c                	ld	a5,40(a5)
ffffffffc0202266:	9782                	jalr	a5
ffffffffc0202268:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020226a:	6098                	ld	a4,0(s1)
ffffffffc020226c:	c80007b7          	lui	a5,0xc8000
ffffffffc0202270:	83b1                	srli	a5,a5,0xc
ffffffffc0202272:	66e7e363          	bltu	a5,a4,ffffffffc02028d8 <pmm_init+0x7ce>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202276:	00093503          	ld	a0,0(s2)
ffffffffc020227a:	62050f63          	beqz	a0,ffffffffc02028b8 <pmm_init+0x7ae>
ffffffffc020227e:	03451793          	slli	a5,a0,0x34
ffffffffc0202282:	62079b63          	bnez	a5,ffffffffc02028b8 <pmm_init+0x7ae>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202286:	4601                	li	a2,0
ffffffffc0202288:	4581                	li	a1,0
ffffffffc020228a:	c9bff0ef          	jal	ra,ffffffffc0201f24 <get_page>
ffffffffc020228e:	60051563          	bnez	a0,ffffffffc0202898 <pmm_init+0x78e>
ffffffffc0202292:	100027f3          	csrr	a5,sstatus
ffffffffc0202296:	8b89                	andi	a5,a5,2
ffffffffc0202298:	44079e63          	bnez	a5,ffffffffc02026f4 <pmm_init+0x5ea>
        page = pmm_manager->alloc_pages(n);
ffffffffc020229c:	000b3783          	ld	a5,0(s6)
ffffffffc02022a0:	4505                	li	a0,1
ffffffffc02022a2:	6f9c                	ld	a5,24(a5)
ffffffffc02022a4:	9782                	jalr	a5
ffffffffc02022a6:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02022a8:	00093503          	ld	a0,0(s2)
ffffffffc02022ac:	4681                	li	a3,0
ffffffffc02022ae:	4601                	li	a2,0
ffffffffc02022b0:	85d2                	mv	a1,s4
ffffffffc02022b2:	d63ff0ef          	jal	ra,ffffffffc0202014 <page_insert>
ffffffffc02022b6:	26051ae3          	bnez	a0,ffffffffc0202d2a <pmm_init+0xc20>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02022ba:	00093503          	ld	a0,0(s2)
ffffffffc02022be:	4601                	li	a2,0
ffffffffc02022c0:	4581                	li	a1,0
ffffffffc02022c2:	a3bff0ef          	jal	ra,ffffffffc0201cfc <get_pte>
ffffffffc02022c6:	240502e3          	beqz	a0,ffffffffc0202d0a <pmm_init+0xc00>
    assert(pte2page(*ptep) == p1);
ffffffffc02022ca:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc02022cc:	0017f713          	andi	a4,a5,1
ffffffffc02022d0:	5a070263          	beqz	a4,ffffffffc0202874 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02022d4:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02022d6:	078a                	slli	a5,a5,0x2
ffffffffc02022d8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02022da:	58e7fb63          	bgeu	a5,a4,ffffffffc0202870 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02022de:	000bb683          	ld	a3,0(s7)
ffffffffc02022e2:	fff80637          	lui	a2,0xfff80
ffffffffc02022e6:	97b2                	add	a5,a5,a2
ffffffffc02022e8:	079a                	slli	a5,a5,0x6
ffffffffc02022ea:	97b6                	add	a5,a5,a3
ffffffffc02022ec:	14fa17e3          	bne	s4,a5,ffffffffc0202c3a <pmm_init+0xb30>
    assert(page_ref(p1) == 1);
ffffffffc02022f0:	000a2683          	lw	a3,0(s4) # 80000 <kern_entry-0xffffffffc0180000>
ffffffffc02022f4:	4785                	li	a5,1
ffffffffc02022f6:	12f692e3          	bne	a3,a5,ffffffffc0202c1a <pmm_init+0xb10>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02022fa:	00093503          	ld	a0,0(s2)
ffffffffc02022fe:	77fd                	lui	a5,0xfffff
ffffffffc0202300:	6114                	ld	a3,0(a0)
ffffffffc0202302:	068a                	slli	a3,a3,0x2
ffffffffc0202304:	8efd                	and	a3,a3,a5
ffffffffc0202306:	00c6d613          	srli	a2,a3,0xc
ffffffffc020230a:	0ee67ce3          	bgeu	a2,a4,ffffffffc0202c02 <pmm_init+0xaf8>
ffffffffc020230e:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202312:	96e2                	add	a3,a3,s8
ffffffffc0202314:	0006ba83          	ld	s5,0(a3)
ffffffffc0202318:	0a8a                	slli	s5,s5,0x2
ffffffffc020231a:	00fafab3          	and	s5,s5,a5
ffffffffc020231e:	00cad793          	srli	a5,s5,0xc
ffffffffc0202322:	0ce7f3e3          	bgeu	a5,a4,ffffffffc0202be8 <pmm_init+0xade>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202326:	4601                	li	a2,0
ffffffffc0202328:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020232a:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020232c:	9d1ff0ef          	jal	ra,ffffffffc0201cfc <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202330:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202332:	55551363          	bne	a0,s5,ffffffffc0202878 <pmm_init+0x76e>
ffffffffc0202336:	100027f3          	csrr	a5,sstatus
ffffffffc020233a:	8b89                	andi	a5,a5,2
ffffffffc020233c:	3a079163          	bnez	a5,ffffffffc02026de <pmm_init+0x5d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202340:	000b3783          	ld	a5,0(s6)
ffffffffc0202344:	4505                	li	a0,1
ffffffffc0202346:	6f9c                	ld	a5,24(a5)
ffffffffc0202348:	9782                	jalr	a5
ffffffffc020234a:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc020234c:	00093503          	ld	a0,0(s2)
ffffffffc0202350:	46d1                	li	a3,20
ffffffffc0202352:	6605                	lui	a2,0x1
ffffffffc0202354:	85e2                	mv	a1,s8
ffffffffc0202356:	cbfff0ef          	jal	ra,ffffffffc0202014 <page_insert>
ffffffffc020235a:	060517e3          	bnez	a0,ffffffffc0202bc8 <pmm_init+0xabe>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020235e:	00093503          	ld	a0,0(s2)
ffffffffc0202362:	4601                	li	a2,0
ffffffffc0202364:	6585                	lui	a1,0x1
ffffffffc0202366:	997ff0ef          	jal	ra,ffffffffc0201cfc <get_pte>
ffffffffc020236a:	02050fe3          	beqz	a0,ffffffffc0202ba8 <pmm_init+0xa9e>
    assert(*ptep & PTE_U);
ffffffffc020236e:	611c                	ld	a5,0(a0)
ffffffffc0202370:	0107f713          	andi	a4,a5,16
ffffffffc0202374:	7c070e63          	beqz	a4,ffffffffc0202b50 <pmm_init+0xa46>
    assert(*ptep & PTE_W);
ffffffffc0202378:	8b91                	andi	a5,a5,4
ffffffffc020237a:	7a078b63          	beqz	a5,ffffffffc0202b30 <pmm_init+0xa26>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc020237e:	00093503          	ld	a0,0(s2)
ffffffffc0202382:	611c                	ld	a5,0(a0)
ffffffffc0202384:	8bc1                	andi	a5,a5,16
ffffffffc0202386:	78078563          	beqz	a5,ffffffffc0202b10 <pmm_init+0xa06>
    assert(page_ref(p2) == 1);
ffffffffc020238a:	000c2703          	lw	a4,0(s8) # ff0000 <kern_entry-0xffffffffbf210000>
ffffffffc020238e:	4785                	li	a5,1
ffffffffc0202390:	76f71063          	bne	a4,a5,ffffffffc0202af0 <pmm_init+0x9e6>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202394:	4681                	li	a3,0
ffffffffc0202396:	6605                	lui	a2,0x1
ffffffffc0202398:	85d2                	mv	a1,s4
ffffffffc020239a:	c7bff0ef          	jal	ra,ffffffffc0202014 <page_insert>
ffffffffc020239e:	72051963          	bnez	a0,ffffffffc0202ad0 <pmm_init+0x9c6>
    assert(page_ref(p1) == 2);
ffffffffc02023a2:	000a2703          	lw	a4,0(s4)
ffffffffc02023a6:	4789                	li	a5,2
ffffffffc02023a8:	70f71463          	bne	a4,a5,ffffffffc0202ab0 <pmm_init+0x9a6>
    assert(page_ref(p2) == 0);
ffffffffc02023ac:	000c2783          	lw	a5,0(s8)
ffffffffc02023b0:	6e079063          	bnez	a5,ffffffffc0202a90 <pmm_init+0x986>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02023b4:	00093503          	ld	a0,0(s2)
ffffffffc02023b8:	4601                	li	a2,0
ffffffffc02023ba:	6585                	lui	a1,0x1
ffffffffc02023bc:	941ff0ef          	jal	ra,ffffffffc0201cfc <get_pte>
ffffffffc02023c0:	6a050863          	beqz	a0,ffffffffc0202a70 <pmm_init+0x966>
    assert(pte2page(*ptep) == p1);
ffffffffc02023c4:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc02023c6:	00177793          	andi	a5,a4,1
ffffffffc02023ca:	4a078563          	beqz	a5,ffffffffc0202874 <pmm_init+0x76a>
    if (PPN(pa) >= npage)
ffffffffc02023ce:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02023d0:	00271793          	slli	a5,a4,0x2
ffffffffc02023d4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02023d6:	48d7fd63          	bgeu	a5,a3,ffffffffc0202870 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc02023da:	000bb683          	ld	a3,0(s7)
ffffffffc02023de:	fff80ab7          	lui	s5,0xfff80
ffffffffc02023e2:	97d6                	add	a5,a5,s5
ffffffffc02023e4:	079a                	slli	a5,a5,0x6
ffffffffc02023e6:	97b6                	add	a5,a5,a3
ffffffffc02023e8:	66fa1463          	bne	s4,a5,ffffffffc0202a50 <pmm_init+0x946>
    assert((*ptep & PTE_U) == 0);
ffffffffc02023ec:	8b41                	andi	a4,a4,16
ffffffffc02023ee:	64071163          	bnez	a4,ffffffffc0202a30 <pmm_init+0x926>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc02023f2:	00093503          	ld	a0,0(s2)
ffffffffc02023f6:	4581                	li	a1,0
ffffffffc02023f8:	b81ff0ef          	jal	ra,ffffffffc0201f78 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc02023fc:	000a2c83          	lw	s9,0(s4)
ffffffffc0202400:	4785                	li	a5,1
ffffffffc0202402:	60fc9763          	bne	s9,a5,ffffffffc0202a10 <pmm_init+0x906>
    assert(page_ref(p2) == 0);
ffffffffc0202406:	000c2783          	lw	a5,0(s8)
ffffffffc020240a:	5e079363          	bnez	a5,ffffffffc02029f0 <pmm_init+0x8e6>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc020240e:	00093503          	ld	a0,0(s2)
ffffffffc0202412:	6585                	lui	a1,0x1
ffffffffc0202414:	b65ff0ef          	jal	ra,ffffffffc0201f78 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202418:	000a2783          	lw	a5,0(s4)
ffffffffc020241c:	52079a63          	bnez	a5,ffffffffc0202950 <pmm_init+0x846>
    assert(page_ref(p2) == 0);
ffffffffc0202420:	000c2783          	lw	a5,0(s8)
ffffffffc0202424:	50079663          	bnez	a5,ffffffffc0202930 <pmm_init+0x826>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202428:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc020242c:	608c                	ld	a1,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020242e:	000a3683          	ld	a3,0(s4)
ffffffffc0202432:	068a                	slli	a3,a3,0x2
ffffffffc0202434:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202436:	42b6fd63          	bgeu	a3,a1,ffffffffc0202870 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020243a:	000bb503          	ld	a0,0(s7)
ffffffffc020243e:	96d6                	add	a3,a3,s5
ffffffffc0202440:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0202442:	00d507b3          	add	a5,a0,a3
ffffffffc0202446:	439c                	lw	a5,0(a5)
ffffffffc0202448:	4d979463          	bne	a5,s9,ffffffffc0202910 <pmm_init+0x806>
    return page - pages + nbase;
ffffffffc020244c:	8699                	srai	a3,a3,0x6
ffffffffc020244e:	00080637          	lui	a2,0x80
ffffffffc0202452:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc0202454:	00c69713          	slli	a4,a3,0xc
ffffffffc0202458:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020245a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020245c:	48b77e63          	bgeu	a4,a1,ffffffffc02028f8 <pmm_init+0x7ee>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202460:	0009b703          	ld	a4,0(s3)
ffffffffc0202464:	96ba                	add	a3,a3,a4
    return pa2page(PDE_ADDR(pde));
ffffffffc0202466:	629c                	ld	a5,0(a3)
ffffffffc0202468:	078a                	slli	a5,a5,0x2
ffffffffc020246a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020246c:	40b7f263          	bgeu	a5,a1,ffffffffc0202870 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202470:	8f91                	sub	a5,a5,a2
ffffffffc0202472:	079a                	slli	a5,a5,0x6
ffffffffc0202474:	953e                	add	a0,a0,a5
ffffffffc0202476:	100027f3          	csrr	a5,sstatus
ffffffffc020247a:	8b89                	andi	a5,a5,2
ffffffffc020247c:	30079963          	bnez	a5,ffffffffc020278e <pmm_init+0x684>
        pmm_manager->free_pages(base, n);
ffffffffc0202480:	000b3783          	ld	a5,0(s6)
ffffffffc0202484:	4585                	li	a1,1
ffffffffc0202486:	739c                	ld	a5,32(a5)
ffffffffc0202488:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020248a:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc020248e:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202490:	078a                	slli	a5,a5,0x2
ffffffffc0202492:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202494:	3ce7fe63          	bgeu	a5,a4,ffffffffc0202870 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc0202498:	000bb503          	ld	a0,0(s7)
ffffffffc020249c:	fff80737          	lui	a4,0xfff80
ffffffffc02024a0:	97ba                	add	a5,a5,a4
ffffffffc02024a2:	079a                	slli	a5,a5,0x6
ffffffffc02024a4:	953e                	add	a0,a0,a5
ffffffffc02024a6:	100027f3          	csrr	a5,sstatus
ffffffffc02024aa:	8b89                	andi	a5,a5,2
ffffffffc02024ac:	2c079563          	bnez	a5,ffffffffc0202776 <pmm_init+0x66c>
ffffffffc02024b0:	000b3783          	ld	a5,0(s6)
ffffffffc02024b4:	4585                	li	a1,1
ffffffffc02024b6:	739c                	ld	a5,32(a5)
ffffffffc02024b8:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc02024ba:	00093783          	ld	a5,0(s2)
ffffffffc02024be:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fdf1b14>
    asm volatile("sfence.vma");
ffffffffc02024c2:	12000073          	sfence.vma
ffffffffc02024c6:	100027f3          	csrr	a5,sstatus
ffffffffc02024ca:	8b89                	andi	a5,a5,2
ffffffffc02024cc:	28079b63          	bnez	a5,ffffffffc0202762 <pmm_init+0x658>
        ret = pmm_manager->nr_free_pages();
ffffffffc02024d0:	000b3783          	ld	a5,0(s6)
ffffffffc02024d4:	779c                	ld	a5,40(a5)
ffffffffc02024d6:	9782                	jalr	a5
ffffffffc02024d8:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc02024da:	4b441b63          	bne	s0,s4,ffffffffc0202990 <pmm_init+0x886>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc02024de:	00003517          	auipc	a0,0x3
ffffffffc02024e2:	be250513          	addi	a0,a0,-1054 # ffffffffc02050c0 <default_pmm_manager+0x518>
ffffffffc02024e6:	caffd0ef          	jal	ra,ffffffffc0200194 <cprintf>
ffffffffc02024ea:	100027f3          	csrr	a5,sstatus
ffffffffc02024ee:	8b89                	andi	a5,a5,2
ffffffffc02024f0:	24079f63          	bnez	a5,ffffffffc020274e <pmm_init+0x644>
        ret = pmm_manager->nr_free_pages();
ffffffffc02024f4:	000b3783          	ld	a5,0(s6)
ffffffffc02024f8:	779c                	ld	a5,40(a5)
ffffffffc02024fa:	9782                	jalr	a5
ffffffffc02024fc:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc02024fe:	6098                	ld	a4,0(s1)
ffffffffc0202500:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202504:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202506:	00c71793          	slli	a5,a4,0xc
ffffffffc020250a:	6a05                	lui	s4,0x1
ffffffffc020250c:	02f47c63          	bgeu	s0,a5,ffffffffc0202544 <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202510:	00c45793          	srli	a5,s0,0xc
ffffffffc0202514:	00093503          	ld	a0,0(s2)
ffffffffc0202518:	2ee7ff63          	bgeu	a5,a4,ffffffffc0202816 <pmm_init+0x70c>
ffffffffc020251c:	0009b583          	ld	a1,0(s3)
ffffffffc0202520:	4601                	li	a2,0
ffffffffc0202522:	95a2                	add	a1,a1,s0
ffffffffc0202524:	fd8ff0ef          	jal	ra,ffffffffc0201cfc <get_pte>
ffffffffc0202528:	32050463          	beqz	a0,ffffffffc0202850 <pmm_init+0x746>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020252c:	611c                	ld	a5,0(a0)
ffffffffc020252e:	078a                	slli	a5,a5,0x2
ffffffffc0202530:	0157f7b3          	and	a5,a5,s5
ffffffffc0202534:	2e879e63          	bne	a5,s0,ffffffffc0202830 <pmm_init+0x726>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202538:	6098                	ld	a4,0(s1)
ffffffffc020253a:	9452                	add	s0,s0,s4
ffffffffc020253c:	00c71793          	slli	a5,a4,0xc
ffffffffc0202540:	fcf468e3          	bltu	s0,a5,ffffffffc0202510 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202544:	00093783          	ld	a5,0(s2)
ffffffffc0202548:	639c                	ld	a5,0(a5)
ffffffffc020254a:	42079363          	bnez	a5,ffffffffc0202970 <pmm_init+0x866>
ffffffffc020254e:	100027f3          	csrr	a5,sstatus
ffffffffc0202552:	8b89                	andi	a5,a5,2
ffffffffc0202554:	24079963          	bnez	a5,ffffffffc02027a6 <pmm_init+0x69c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202558:	000b3783          	ld	a5,0(s6)
ffffffffc020255c:	4505                	li	a0,1
ffffffffc020255e:	6f9c                	ld	a5,24(a5)
ffffffffc0202560:	9782                	jalr	a5
ffffffffc0202562:	8a2a                	mv	s4,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202564:	00093503          	ld	a0,0(s2)
ffffffffc0202568:	4699                	li	a3,6
ffffffffc020256a:	10000613          	li	a2,256
ffffffffc020256e:	85d2                	mv	a1,s4
ffffffffc0202570:	aa5ff0ef          	jal	ra,ffffffffc0202014 <page_insert>
ffffffffc0202574:	44051e63          	bnez	a0,ffffffffc02029d0 <pmm_init+0x8c6>
    assert(page_ref(p) == 1);
ffffffffc0202578:	000a2703          	lw	a4,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc020257c:	4785                	li	a5,1
ffffffffc020257e:	42f71963          	bne	a4,a5,ffffffffc02029b0 <pmm_init+0x8a6>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202582:	00093503          	ld	a0,0(s2)
ffffffffc0202586:	6405                	lui	s0,0x1
ffffffffc0202588:	4699                	li	a3,6
ffffffffc020258a:	10040613          	addi	a2,s0,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc020258e:	85d2                	mv	a1,s4
ffffffffc0202590:	a85ff0ef          	jal	ra,ffffffffc0202014 <page_insert>
ffffffffc0202594:	72051363          	bnez	a0,ffffffffc0202cba <pmm_init+0xbb0>
    assert(page_ref(p) == 2);
ffffffffc0202598:	000a2703          	lw	a4,0(s4)
ffffffffc020259c:	4789                	li	a5,2
ffffffffc020259e:	6ef71e63          	bne	a4,a5,ffffffffc0202c9a <pmm_init+0xb90>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc02025a2:	00003597          	auipc	a1,0x3
ffffffffc02025a6:	c6658593          	addi	a1,a1,-922 # ffffffffc0205208 <default_pmm_manager+0x660>
ffffffffc02025aa:	10000513          	li	a0,256
ffffffffc02025ae:	01d010ef          	jal	ra,ffffffffc0203dca <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02025b2:	10040593          	addi	a1,s0,256
ffffffffc02025b6:	10000513          	li	a0,256
ffffffffc02025ba:	023010ef          	jal	ra,ffffffffc0203ddc <strcmp>
ffffffffc02025be:	6a051e63          	bnez	a0,ffffffffc0202c7a <pmm_init+0xb70>
    return page - pages + nbase;
ffffffffc02025c2:	000bb683          	ld	a3,0(s7)
ffffffffc02025c6:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc02025ca:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc02025cc:	40da06b3          	sub	a3,s4,a3
ffffffffc02025d0:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02025d2:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc02025d4:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc02025d6:	8031                	srli	s0,s0,0xc
ffffffffc02025d8:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc02025dc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02025de:	30f77d63          	bgeu	a4,a5,ffffffffc02028f8 <pmm_init+0x7ee>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc02025e2:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc02025e6:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc02025ea:	96be                	add	a3,a3,a5
ffffffffc02025ec:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc02025f0:	7a4010ef          	jal	ra,ffffffffc0203d94 <strlen>
ffffffffc02025f4:	66051363          	bnez	a0,ffffffffc0202c5a <pmm_init+0xb50>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc02025f8:	00093a83          	ld	s5,0(s2)
    if (PPN(pa) >= npage)
ffffffffc02025fc:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02025fe:	000ab683          	ld	a3,0(s5) # fffffffffffff000 <end+0x3fdf1b14>
ffffffffc0202602:	068a                	slli	a3,a3,0x2
ffffffffc0202604:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage)
ffffffffc0202606:	26f6f563          	bgeu	a3,a5,ffffffffc0202870 <pmm_init+0x766>
    return KADDR(page2pa(page));
ffffffffc020260a:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc020260c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020260e:	2ef47563          	bgeu	s0,a5,ffffffffc02028f8 <pmm_init+0x7ee>
ffffffffc0202612:	0009b403          	ld	s0,0(s3)
ffffffffc0202616:	9436                	add	s0,s0,a3
ffffffffc0202618:	100027f3          	csrr	a5,sstatus
ffffffffc020261c:	8b89                	andi	a5,a5,2
ffffffffc020261e:	1e079163          	bnez	a5,ffffffffc0202800 <pmm_init+0x6f6>
        pmm_manager->free_pages(base, n);
ffffffffc0202622:	000b3783          	ld	a5,0(s6)
ffffffffc0202626:	4585                	li	a1,1
ffffffffc0202628:	8552                	mv	a0,s4
ffffffffc020262a:	739c                	ld	a5,32(a5)
ffffffffc020262c:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020262e:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage)
ffffffffc0202630:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202632:	078a                	slli	a5,a5,0x2
ffffffffc0202634:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202636:	22e7fd63          	bgeu	a5,a4,ffffffffc0202870 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020263a:	000bb503          	ld	a0,0(s7)
ffffffffc020263e:	fff80737          	lui	a4,0xfff80
ffffffffc0202642:	97ba                	add	a5,a5,a4
ffffffffc0202644:	079a                	slli	a5,a5,0x6
ffffffffc0202646:	953e                	add	a0,a0,a5
ffffffffc0202648:	100027f3          	csrr	a5,sstatus
ffffffffc020264c:	8b89                	andi	a5,a5,2
ffffffffc020264e:	18079d63          	bnez	a5,ffffffffc02027e8 <pmm_init+0x6de>
ffffffffc0202652:	000b3783          	ld	a5,0(s6)
ffffffffc0202656:	4585                	li	a1,1
ffffffffc0202658:	739c                	ld	a5,32(a5)
ffffffffc020265a:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020265c:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage)
ffffffffc0202660:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202662:	078a                	slli	a5,a5,0x2
ffffffffc0202664:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202666:	20e7f563          	bgeu	a5,a4,ffffffffc0202870 <pmm_init+0x766>
    return &pages[PPN(pa) - nbase];
ffffffffc020266a:	000bb503          	ld	a0,0(s7)
ffffffffc020266e:	fff80737          	lui	a4,0xfff80
ffffffffc0202672:	97ba                	add	a5,a5,a4
ffffffffc0202674:	079a                	slli	a5,a5,0x6
ffffffffc0202676:	953e                	add	a0,a0,a5
ffffffffc0202678:	100027f3          	csrr	a5,sstatus
ffffffffc020267c:	8b89                	andi	a5,a5,2
ffffffffc020267e:	14079963          	bnez	a5,ffffffffc02027d0 <pmm_init+0x6c6>
ffffffffc0202682:	000b3783          	ld	a5,0(s6)
ffffffffc0202686:	4585                	li	a1,1
ffffffffc0202688:	739c                	ld	a5,32(a5)
ffffffffc020268a:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc020268c:	00093783          	ld	a5,0(s2)
ffffffffc0202690:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202694:	12000073          	sfence.vma
ffffffffc0202698:	100027f3          	csrr	a5,sstatus
ffffffffc020269c:	8b89                	andi	a5,a5,2
ffffffffc020269e:	10079f63          	bnez	a5,ffffffffc02027bc <pmm_init+0x6b2>
        ret = pmm_manager->nr_free_pages();
ffffffffc02026a2:	000b3783          	ld	a5,0(s6)
ffffffffc02026a6:	779c                	ld	a5,40(a5)
ffffffffc02026a8:	9782                	jalr	a5
ffffffffc02026aa:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc02026ac:	4c8c1e63          	bne	s8,s0,ffffffffc0202b88 <pmm_init+0xa7e>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc02026b0:	00003517          	auipc	a0,0x3
ffffffffc02026b4:	bd050513          	addi	a0,a0,-1072 # ffffffffc0205280 <default_pmm_manager+0x6d8>
ffffffffc02026b8:	addfd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc02026bc:	7406                	ld	s0,96(sp)
ffffffffc02026be:	70a6                	ld	ra,104(sp)
ffffffffc02026c0:	64e6                	ld	s1,88(sp)
ffffffffc02026c2:	6946                	ld	s2,80(sp)
ffffffffc02026c4:	69a6                	ld	s3,72(sp)
ffffffffc02026c6:	6a06                	ld	s4,64(sp)
ffffffffc02026c8:	7ae2                	ld	s5,56(sp)
ffffffffc02026ca:	7b42                	ld	s6,48(sp)
ffffffffc02026cc:	7ba2                	ld	s7,40(sp)
ffffffffc02026ce:	7c02                	ld	s8,32(sp)
ffffffffc02026d0:	6ce2                	ld	s9,24(sp)
ffffffffc02026d2:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc02026d4:	b72ff06f          	j	ffffffffc0201a46 <kmalloc_init>
    npage = maxpa / PGSIZE;
ffffffffc02026d8:	c80007b7          	lui	a5,0xc8000
ffffffffc02026dc:	bc7d                	j	ffffffffc020219a <pmm_init+0x90>
        intr_disable();
ffffffffc02026de:	a52fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02026e2:	000b3783          	ld	a5,0(s6)
ffffffffc02026e6:	4505                	li	a0,1
ffffffffc02026e8:	6f9c                	ld	a5,24(a5)
ffffffffc02026ea:	9782                	jalr	a5
ffffffffc02026ec:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc02026ee:	a3cfe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02026f2:	b9a9                	j	ffffffffc020234c <pmm_init+0x242>
        intr_disable();
ffffffffc02026f4:	a3cfe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc02026f8:	000b3783          	ld	a5,0(s6)
ffffffffc02026fc:	4505                	li	a0,1
ffffffffc02026fe:	6f9c                	ld	a5,24(a5)
ffffffffc0202700:	9782                	jalr	a5
ffffffffc0202702:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202704:	a26fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202708:	b645                	j	ffffffffc02022a8 <pmm_init+0x19e>
        intr_disable();
ffffffffc020270a:	a26fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020270e:	000b3783          	ld	a5,0(s6)
ffffffffc0202712:	779c                	ld	a5,40(a5)
ffffffffc0202714:	9782                	jalr	a5
ffffffffc0202716:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202718:	a12fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020271c:	b6b9                	j	ffffffffc020226a <pmm_init+0x160>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020271e:	6705                	lui	a4,0x1
ffffffffc0202720:	177d                	addi	a4,a4,-1
ffffffffc0202722:	96ba                	add	a3,a3,a4
ffffffffc0202724:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202726:	00c7d713          	srli	a4,a5,0xc
ffffffffc020272a:	14a77363          	bgeu	a4,a0,ffffffffc0202870 <pmm_init+0x766>
    pmm_manager->init_memmap(base, n);
ffffffffc020272e:	000b3683          	ld	a3,0(s6)
    return &pages[PPN(pa) - nbase];
ffffffffc0202732:	fff80537          	lui	a0,0xfff80
ffffffffc0202736:	972a                	add	a4,a4,a0
ffffffffc0202738:	6a94                	ld	a3,16(a3)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020273a:	8c1d                	sub	s0,s0,a5
ffffffffc020273c:	00671513          	slli	a0,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc0202740:	00c45593          	srli	a1,s0,0xc
ffffffffc0202744:	9532                	add	a0,a0,a2
ffffffffc0202746:	9682                	jalr	a3
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202748:	0009b583          	ld	a1,0(s3)
}
ffffffffc020274c:	b4c1                	j	ffffffffc020220c <pmm_init+0x102>
        intr_disable();
ffffffffc020274e:	9e2fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202752:	000b3783          	ld	a5,0(s6)
ffffffffc0202756:	779c                	ld	a5,40(a5)
ffffffffc0202758:	9782                	jalr	a5
ffffffffc020275a:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc020275c:	9cefe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202760:	bb79                	j	ffffffffc02024fe <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202762:	9cefe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0202766:	000b3783          	ld	a5,0(s6)
ffffffffc020276a:	779c                	ld	a5,40(a5)
ffffffffc020276c:	9782                	jalr	a5
ffffffffc020276e:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202770:	9bafe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202774:	b39d                	j	ffffffffc02024da <pmm_init+0x3d0>
ffffffffc0202776:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202778:	9b8fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020277c:	000b3783          	ld	a5,0(s6)
ffffffffc0202780:	6522                	ld	a0,8(sp)
ffffffffc0202782:	4585                	li	a1,1
ffffffffc0202784:	739c                	ld	a5,32(a5)
ffffffffc0202786:	9782                	jalr	a5
        intr_enable();
ffffffffc0202788:	9a2fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc020278c:	b33d                	j	ffffffffc02024ba <pmm_init+0x3b0>
ffffffffc020278e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202790:	9a0fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0202794:	000b3783          	ld	a5,0(s6)
ffffffffc0202798:	6522                	ld	a0,8(sp)
ffffffffc020279a:	4585                	li	a1,1
ffffffffc020279c:	739c                	ld	a5,32(a5)
ffffffffc020279e:	9782                	jalr	a5
        intr_enable();
ffffffffc02027a0:	98afe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027a4:	b1dd                	j	ffffffffc020248a <pmm_init+0x380>
        intr_disable();
ffffffffc02027a6:	98afe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02027aa:	000b3783          	ld	a5,0(s6)
ffffffffc02027ae:	4505                	li	a0,1
ffffffffc02027b0:	6f9c                	ld	a5,24(a5)
ffffffffc02027b2:	9782                	jalr	a5
ffffffffc02027b4:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02027b6:	974fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027ba:	b36d                	j	ffffffffc0202564 <pmm_init+0x45a>
        intr_disable();
ffffffffc02027bc:	974fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02027c0:	000b3783          	ld	a5,0(s6)
ffffffffc02027c4:	779c                	ld	a5,40(a5)
ffffffffc02027c6:	9782                	jalr	a5
ffffffffc02027c8:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02027ca:	960fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027ce:	bdf9                	j	ffffffffc02026ac <pmm_init+0x5a2>
ffffffffc02027d0:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027d2:	95efe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02027d6:	000b3783          	ld	a5,0(s6)
ffffffffc02027da:	6522                	ld	a0,8(sp)
ffffffffc02027dc:	4585                	li	a1,1
ffffffffc02027de:	739c                	ld	a5,32(a5)
ffffffffc02027e0:	9782                	jalr	a5
        intr_enable();
ffffffffc02027e2:	948fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027e6:	b55d                	j	ffffffffc020268c <pmm_init+0x582>
ffffffffc02027e8:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027ea:	946fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc02027ee:	000b3783          	ld	a5,0(s6)
ffffffffc02027f2:	6522                	ld	a0,8(sp)
ffffffffc02027f4:	4585                	li	a1,1
ffffffffc02027f6:	739c                	ld	a5,32(a5)
ffffffffc02027f8:	9782                	jalr	a5
        intr_enable();
ffffffffc02027fa:	930fe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc02027fe:	bdb9                	j	ffffffffc020265c <pmm_init+0x552>
        intr_disable();
ffffffffc0202800:	930fe0ef          	jal	ra,ffffffffc0200930 <intr_disable>
ffffffffc0202804:	000b3783          	ld	a5,0(s6)
ffffffffc0202808:	4585                	li	a1,1
ffffffffc020280a:	8552                	mv	a0,s4
ffffffffc020280c:	739c                	ld	a5,32(a5)
ffffffffc020280e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202810:	91afe0ef          	jal	ra,ffffffffc020092a <intr_enable>
ffffffffc0202814:	bd29                	j	ffffffffc020262e <pmm_init+0x524>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202816:	86a2                	mv	a3,s0
ffffffffc0202818:	00002617          	auipc	a2,0x2
ffffffffc020281c:	3c860613          	addi	a2,a2,968 # ffffffffc0204be0 <default_pmm_manager+0x38>
ffffffffc0202820:	1a400593          	li	a1,420
ffffffffc0202824:	00002517          	auipc	a0,0x2
ffffffffc0202828:	4d450513          	addi	a0,a0,1236 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc020282c:	c2ffd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202830:	00003697          	auipc	a3,0x3
ffffffffc0202834:	8f068693          	addi	a3,a3,-1808 # ffffffffc0205120 <default_pmm_manager+0x578>
ffffffffc0202838:	00002617          	auipc	a2,0x2
ffffffffc020283c:	fc060613          	addi	a2,a2,-64 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202840:	1a500593          	li	a1,421
ffffffffc0202844:	00002517          	auipc	a0,0x2
ffffffffc0202848:	4b450513          	addi	a0,a0,1204 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc020284c:	c0ffd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202850:	00003697          	auipc	a3,0x3
ffffffffc0202854:	89068693          	addi	a3,a3,-1904 # ffffffffc02050e0 <default_pmm_manager+0x538>
ffffffffc0202858:	00002617          	auipc	a2,0x2
ffffffffc020285c:	fa060613          	addi	a2,a2,-96 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202860:	1a400593          	li	a1,420
ffffffffc0202864:	00002517          	auipc	a0,0x2
ffffffffc0202868:	49450513          	addi	a0,a0,1172 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc020286c:	beffd0ef          	jal	ra,ffffffffc020045a <__panic>
ffffffffc0202870:	b9cff0ef          	jal	ra,ffffffffc0201c0c <pa2page.part.0>
ffffffffc0202874:	bb4ff0ef          	jal	ra,ffffffffc0201c28 <pte2page.part.0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202878:	00002697          	auipc	a3,0x2
ffffffffc020287c:	66068693          	addi	a3,a3,1632 # ffffffffc0204ed8 <default_pmm_manager+0x330>
ffffffffc0202880:	00002617          	auipc	a2,0x2
ffffffffc0202884:	f7860613          	addi	a2,a2,-136 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202888:	17400593          	li	a1,372
ffffffffc020288c:	00002517          	auipc	a0,0x2
ffffffffc0202890:	46c50513          	addi	a0,a0,1132 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202894:	bc7fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202898:	00002697          	auipc	a3,0x2
ffffffffc020289c:	58068693          	addi	a3,a3,1408 # ffffffffc0204e18 <default_pmm_manager+0x270>
ffffffffc02028a0:	00002617          	auipc	a2,0x2
ffffffffc02028a4:	f5860613          	addi	a2,a2,-168 # ffffffffc02047f8 <commands+0x708>
ffffffffc02028a8:	16700593          	li	a1,359
ffffffffc02028ac:	00002517          	auipc	a0,0x2
ffffffffc02028b0:	44c50513          	addi	a0,a0,1100 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc02028b4:	ba7fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02028b8:	00002697          	auipc	a3,0x2
ffffffffc02028bc:	52068693          	addi	a3,a3,1312 # ffffffffc0204dd8 <default_pmm_manager+0x230>
ffffffffc02028c0:	00002617          	auipc	a2,0x2
ffffffffc02028c4:	f3860613          	addi	a2,a2,-200 # ffffffffc02047f8 <commands+0x708>
ffffffffc02028c8:	16600593          	li	a1,358
ffffffffc02028cc:	00002517          	auipc	a0,0x2
ffffffffc02028d0:	42c50513          	addi	a0,a0,1068 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc02028d4:	b87fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02028d8:	00002697          	auipc	a3,0x2
ffffffffc02028dc:	4e068693          	addi	a3,a3,1248 # ffffffffc0204db8 <default_pmm_manager+0x210>
ffffffffc02028e0:	00002617          	auipc	a2,0x2
ffffffffc02028e4:	f1860613          	addi	a2,a2,-232 # ffffffffc02047f8 <commands+0x708>
ffffffffc02028e8:	16500593          	li	a1,357
ffffffffc02028ec:	00002517          	auipc	a0,0x2
ffffffffc02028f0:	40c50513          	addi	a0,a0,1036 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc02028f4:	b67fd0ef          	jal	ra,ffffffffc020045a <__panic>
    return KADDR(page2pa(page));
ffffffffc02028f8:	00002617          	auipc	a2,0x2
ffffffffc02028fc:	2e860613          	addi	a2,a2,744 # ffffffffc0204be0 <default_pmm_manager+0x38>
ffffffffc0202900:	07100593          	li	a1,113
ffffffffc0202904:	00002517          	auipc	a0,0x2
ffffffffc0202908:	30450513          	addi	a0,a0,772 # ffffffffc0204c08 <default_pmm_manager+0x60>
ffffffffc020290c:	b4ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202910:	00002697          	auipc	a3,0x2
ffffffffc0202914:	75868693          	addi	a3,a3,1880 # ffffffffc0205068 <default_pmm_manager+0x4c0>
ffffffffc0202918:	00002617          	auipc	a2,0x2
ffffffffc020291c:	ee060613          	addi	a2,a2,-288 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202920:	18d00593          	li	a1,397
ffffffffc0202924:	00002517          	auipc	a0,0x2
ffffffffc0202928:	3d450513          	addi	a0,a0,980 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc020292c:	b2ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202930:	00002697          	auipc	a3,0x2
ffffffffc0202934:	6f068693          	addi	a3,a3,1776 # ffffffffc0205020 <default_pmm_manager+0x478>
ffffffffc0202938:	00002617          	auipc	a2,0x2
ffffffffc020293c:	ec060613          	addi	a2,a2,-320 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202940:	18b00593          	li	a1,395
ffffffffc0202944:	00002517          	auipc	a0,0x2
ffffffffc0202948:	3b450513          	addi	a0,a0,948 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc020294c:	b0ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202950:	00002697          	auipc	a3,0x2
ffffffffc0202954:	70068693          	addi	a3,a3,1792 # ffffffffc0205050 <default_pmm_manager+0x4a8>
ffffffffc0202958:	00002617          	auipc	a2,0x2
ffffffffc020295c:	ea060613          	addi	a2,a2,-352 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202960:	18a00593          	li	a1,394
ffffffffc0202964:	00002517          	auipc	a0,0x2
ffffffffc0202968:	39450513          	addi	a0,a0,916 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc020296c:	aeffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202970:	00002697          	auipc	a3,0x2
ffffffffc0202974:	7c868693          	addi	a3,a3,1992 # ffffffffc0205138 <default_pmm_manager+0x590>
ffffffffc0202978:	00002617          	auipc	a2,0x2
ffffffffc020297c:	e8060613          	addi	a2,a2,-384 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202980:	1a800593          	li	a1,424
ffffffffc0202984:	00002517          	auipc	a0,0x2
ffffffffc0202988:	37450513          	addi	a0,a0,884 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc020298c:	acffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202990:	00002697          	auipc	a3,0x2
ffffffffc0202994:	70868693          	addi	a3,a3,1800 # ffffffffc0205098 <default_pmm_manager+0x4f0>
ffffffffc0202998:	00002617          	auipc	a2,0x2
ffffffffc020299c:	e6060613          	addi	a2,a2,-416 # ffffffffc02047f8 <commands+0x708>
ffffffffc02029a0:	19500593          	li	a1,405
ffffffffc02029a4:	00002517          	auipc	a0,0x2
ffffffffc02029a8:	35450513          	addi	a0,a0,852 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc02029ac:	aaffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p) == 1);
ffffffffc02029b0:	00002697          	auipc	a3,0x2
ffffffffc02029b4:	7e068693          	addi	a3,a3,2016 # ffffffffc0205190 <default_pmm_manager+0x5e8>
ffffffffc02029b8:	00002617          	auipc	a2,0x2
ffffffffc02029bc:	e4060613          	addi	a2,a2,-448 # ffffffffc02047f8 <commands+0x708>
ffffffffc02029c0:	1ad00593          	li	a1,429
ffffffffc02029c4:	00002517          	auipc	a0,0x2
ffffffffc02029c8:	33450513          	addi	a0,a0,820 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc02029cc:	a8ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02029d0:	00002697          	auipc	a3,0x2
ffffffffc02029d4:	78068693          	addi	a3,a3,1920 # ffffffffc0205150 <default_pmm_manager+0x5a8>
ffffffffc02029d8:	00002617          	auipc	a2,0x2
ffffffffc02029dc:	e2060613          	addi	a2,a2,-480 # ffffffffc02047f8 <commands+0x708>
ffffffffc02029e0:	1ac00593          	li	a1,428
ffffffffc02029e4:	00002517          	auipc	a0,0x2
ffffffffc02029e8:	31450513          	addi	a0,a0,788 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc02029ec:	a6ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02029f0:	00002697          	auipc	a3,0x2
ffffffffc02029f4:	63068693          	addi	a3,a3,1584 # ffffffffc0205020 <default_pmm_manager+0x478>
ffffffffc02029f8:	00002617          	auipc	a2,0x2
ffffffffc02029fc:	e0060613          	addi	a2,a2,-512 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202a00:	18700593          	li	a1,391
ffffffffc0202a04:	00002517          	auipc	a0,0x2
ffffffffc0202a08:	2f450513          	addi	a0,a0,756 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202a0c:	a4ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202a10:	00002697          	auipc	a3,0x2
ffffffffc0202a14:	4b068693          	addi	a3,a3,1200 # ffffffffc0204ec0 <default_pmm_manager+0x318>
ffffffffc0202a18:	00002617          	auipc	a2,0x2
ffffffffc0202a1c:	de060613          	addi	a2,a2,-544 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202a20:	18600593          	li	a1,390
ffffffffc0202a24:	00002517          	auipc	a0,0x2
ffffffffc0202a28:	2d450513          	addi	a0,a0,724 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202a2c:	a2ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a30:	00002697          	auipc	a3,0x2
ffffffffc0202a34:	60868693          	addi	a3,a3,1544 # ffffffffc0205038 <default_pmm_manager+0x490>
ffffffffc0202a38:	00002617          	auipc	a2,0x2
ffffffffc0202a3c:	dc060613          	addi	a2,a2,-576 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202a40:	18300593          	li	a1,387
ffffffffc0202a44:	00002517          	auipc	a0,0x2
ffffffffc0202a48:	2b450513          	addi	a0,a0,692 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202a4c:	a0ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a50:	00002697          	auipc	a3,0x2
ffffffffc0202a54:	45868693          	addi	a3,a3,1112 # ffffffffc0204ea8 <default_pmm_manager+0x300>
ffffffffc0202a58:	00002617          	auipc	a2,0x2
ffffffffc0202a5c:	da060613          	addi	a2,a2,-608 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202a60:	18200593          	li	a1,386
ffffffffc0202a64:	00002517          	auipc	a0,0x2
ffffffffc0202a68:	29450513          	addi	a0,a0,660 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202a6c:	9effd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a70:	00002697          	auipc	a3,0x2
ffffffffc0202a74:	4d868693          	addi	a3,a3,1240 # ffffffffc0204f48 <default_pmm_manager+0x3a0>
ffffffffc0202a78:	00002617          	auipc	a2,0x2
ffffffffc0202a7c:	d8060613          	addi	a2,a2,-640 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202a80:	18100593          	li	a1,385
ffffffffc0202a84:	00002517          	auipc	a0,0x2
ffffffffc0202a88:	27450513          	addi	a0,a0,628 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202a8c:	9cffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202a90:	00002697          	auipc	a3,0x2
ffffffffc0202a94:	59068693          	addi	a3,a3,1424 # ffffffffc0205020 <default_pmm_manager+0x478>
ffffffffc0202a98:	00002617          	auipc	a2,0x2
ffffffffc0202a9c:	d6060613          	addi	a2,a2,-672 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202aa0:	18000593          	li	a1,384
ffffffffc0202aa4:	00002517          	auipc	a0,0x2
ffffffffc0202aa8:	25450513          	addi	a0,a0,596 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202aac:	9affd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202ab0:	00002697          	auipc	a3,0x2
ffffffffc0202ab4:	55868693          	addi	a3,a3,1368 # ffffffffc0205008 <default_pmm_manager+0x460>
ffffffffc0202ab8:	00002617          	auipc	a2,0x2
ffffffffc0202abc:	d4060613          	addi	a2,a2,-704 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202ac0:	17f00593          	li	a1,383
ffffffffc0202ac4:	00002517          	auipc	a0,0x2
ffffffffc0202ac8:	23450513          	addi	a0,a0,564 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202acc:	98ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202ad0:	00002697          	auipc	a3,0x2
ffffffffc0202ad4:	50868693          	addi	a3,a3,1288 # ffffffffc0204fd8 <default_pmm_manager+0x430>
ffffffffc0202ad8:	00002617          	auipc	a2,0x2
ffffffffc0202adc:	d2060613          	addi	a2,a2,-736 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202ae0:	17e00593          	li	a1,382
ffffffffc0202ae4:	00002517          	auipc	a0,0x2
ffffffffc0202ae8:	21450513          	addi	a0,a0,532 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202aec:	96ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202af0:	00002697          	auipc	a3,0x2
ffffffffc0202af4:	4d068693          	addi	a3,a3,1232 # ffffffffc0204fc0 <default_pmm_manager+0x418>
ffffffffc0202af8:	00002617          	auipc	a2,0x2
ffffffffc0202afc:	d0060613          	addi	a2,a2,-768 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202b00:	17c00593          	li	a1,380
ffffffffc0202b04:	00002517          	auipc	a0,0x2
ffffffffc0202b08:	1f450513          	addi	a0,a0,500 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202b0c:	94ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202b10:	00002697          	auipc	a3,0x2
ffffffffc0202b14:	49068693          	addi	a3,a3,1168 # ffffffffc0204fa0 <default_pmm_manager+0x3f8>
ffffffffc0202b18:	00002617          	auipc	a2,0x2
ffffffffc0202b1c:	ce060613          	addi	a2,a2,-800 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202b20:	17b00593          	li	a1,379
ffffffffc0202b24:	00002517          	auipc	a0,0x2
ffffffffc0202b28:	1d450513          	addi	a0,a0,468 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202b2c:	92ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(*ptep & PTE_W);
ffffffffc0202b30:	00002697          	auipc	a3,0x2
ffffffffc0202b34:	46068693          	addi	a3,a3,1120 # ffffffffc0204f90 <default_pmm_manager+0x3e8>
ffffffffc0202b38:	00002617          	auipc	a2,0x2
ffffffffc0202b3c:	cc060613          	addi	a2,a2,-832 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202b40:	17a00593          	li	a1,378
ffffffffc0202b44:	00002517          	auipc	a0,0x2
ffffffffc0202b48:	1b450513          	addi	a0,a0,436 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202b4c:	90ffd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202b50:	00002697          	auipc	a3,0x2
ffffffffc0202b54:	43068693          	addi	a3,a3,1072 # ffffffffc0204f80 <default_pmm_manager+0x3d8>
ffffffffc0202b58:	00002617          	auipc	a2,0x2
ffffffffc0202b5c:	ca060613          	addi	a2,a2,-864 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202b60:	17900593          	li	a1,377
ffffffffc0202b64:	00002517          	auipc	a0,0x2
ffffffffc0202b68:	19450513          	addi	a0,a0,404 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202b6c:	8effd0ef          	jal	ra,ffffffffc020045a <__panic>
        panic("DTB memory info not available");
ffffffffc0202b70:	00002617          	auipc	a2,0x2
ffffffffc0202b74:	1b060613          	addi	a2,a2,432 # ffffffffc0204d20 <default_pmm_manager+0x178>
ffffffffc0202b78:	06400593          	li	a1,100
ffffffffc0202b7c:	00002517          	auipc	a0,0x2
ffffffffc0202b80:	17c50513          	addi	a0,a0,380 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202b84:	8d7fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202b88:	00002697          	auipc	a3,0x2
ffffffffc0202b8c:	51068693          	addi	a3,a3,1296 # ffffffffc0205098 <default_pmm_manager+0x4f0>
ffffffffc0202b90:	00002617          	auipc	a2,0x2
ffffffffc0202b94:	c6860613          	addi	a2,a2,-920 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202b98:	1bf00593          	li	a1,447
ffffffffc0202b9c:	00002517          	auipc	a0,0x2
ffffffffc0202ba0:	15c50513          	addi	a0,a0,348 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202ba4:	8b7fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202ba8:	00002697          	auipc	a3,0x2
ffffffffc0202bac:	3a068693          	addi	a3,a3,928 # ffffffffc0204f48 <default_pmm_manager+0x3a0>
ffffffffc0202bb0:	00002617          	auipc	a2,0x2
ffffffffc0202bb4:	c4860613          	addi	a2,a2,-952 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202bb8:	17800593          	li	a1,376
ffffffffc0202bbc:	00002517          	auipc	a0,0x2
ffffffffc0202bc0:	13c50513          	addi	a0,a0,316 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202bc4:	897fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202bc8:	00002697          	auipc	a3,0x2
ffffffffc0202bcc:	34068693          	addi	a3,a3,832 # ffffffffc0204f08 <default_pmm_manager+0x360>
ffffffffc0202bd0:	00002617          	auipc	a2,0x2
ffffffffc0202bd4:	c2860613          	addi	a2,a2,-984 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202bd8:	17700593          	li	a1,375
ffffffffc0202bdc:	00002517          	auipc	a0,0x2
ffffffffc0202be0:	11c50513          	addi	a0,a0,284 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202be4:	877fd0ef          	jal	ra,ffffffffc020045a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202be8:	86d6                	mv	a3,s5
ffffffffc0202bea:	00002617          	auipc	a2,0x2
ffffffffc0202bee:	ff660613          	addi	a2,a2,-10 # ffffffffc0204be0 <default_pmm_manager+0x38>
ffffffffc0202bf2:	17300593          	li	a1,371
ffffffffc0202bf6:	00002517          	auipc	a0,0x2
ffffffffc0202bfa:	10250513          	addi	a0,a0,258 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202bfe:	85dfd0ef          	jal	ra,ffffffffc020045a <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202c02:	00002617          	auipc	a2,0x2
ffffffffc0202c06:	fde60613          	addi	a2,a2,-34 # ffffffffc0204be0 <default_pmm_manager+0x38>
ffffffffc0202c0a:	17200593          	li	a1,370
ffffffffc0202c0e:	00002517          	auipc	a0,0x2
ffffffffc0202c12:	0ea50513          	addi	a0,a0,234 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202c16:	845fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202c1a:	00002697          	auipc	a3,0x2
ffffffffc0202c1e:	2a668693          	addi	a3,a3,678 # ffffffffc0204ec0 <default_pmm_manager+0x318>
ffffffffc0202c22:	00002617          	auipc	a2,0x2
ffffffffc0202c26:	bd660613          	addi	a2,a2,-1066 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202c2a:	17000593          	li	a1,368
ffffffffc0202c2e:	00002517          	auipc	a0,0x2
ffffffffc0202c32:	0ca50513          	addi	a0,a0,202 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202c36:	825fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202c3a:	00002697          	auipc	a3,0x2
ffffffffc0202c3e:	26e68693          	addi	a3,a3,622 # ffffffffc0204ea8 <default_pmm_manager+0x300>
ffffffffc0202c42:	00002617          	auipc	a2,0x2
ffffffffc0202c46:	bb660613          	addi	a2,a2,-1098 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202c4a:	16f00593          	li	a1,367
ffffffffc0202c4e:	00002517          	auipc	a0,0x2
ffffffffc0202c52:	0aa50513          	addi	a0,a0,170 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202c56:	805fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c5a:	00002697          	auipc	a3,0x2
ffffffffc0202c5e:	5fe68693          	addi	a3,a3,1534 # ffffffffc0205258 <default_pmm_manager+0x6b0>
ffffffffc0202c62:	00002617          	auipc	a2,0x2
ffffffffc0202c66:	b9660613          	addi	a2,a2,-1130 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202c6a:	1b600593          	li	a1,438
ffffffffc0202c6e:	00002517          	auipc	a0,0x2
ffffffffc0202c72:	08a50513          	addi	a0,a0,138 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202c76:	fe4fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202c7a:	00002697          	auipc	a3,0x2
ffffffffc0202c7e:	5a668693          	addi	a3,a3,1446 # ffffffffc0205220 <default_pmm_manager+0x678>
ffffffffc0202c82:	00002617          	auipc	a2,0x2
ffffffffc0202c86:	b7660613          	addi	a2,a2,-1162 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202c8a:	1b300593          	li	a1,435
ffffffffc0202c8e:	00002517          	auipc	a0,0x2
ffffffffc0202c92:	06a50513          	addi	a0,a0,106 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202c96:	fc4fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_ref(p) == 2);
ffffffffc0202c9a:	00002697          	auipc	a3,0x2
ffffffffc0202c9e:	55668693          	addi	a3,a3,1366 # ffffffffc02051f0 <default_pmm_manager+0x648>
ffffffffc0202ca2:	00002617          	auipc	a2,0x2
ffffffffc0202ca6:	b5660613          	addi	a2,a2,-1194 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202caa:	1af00593          	li	a1,431
ffffffffc0202cae:	00002517          	auipc	a0,0x2
ffffffffc0202cb2:	04a50513          	addi	a0,a0,74 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202cb6:	fa4fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202cba:	00002697          	auipc	a3,0x2
ffffffffc0202cbe:	4ee68693          	addi	a3,a3,1262 # ffffffffc02051a8 <default_pmm_manager+0x600>
ffffffffc0202cc2:	00002617          	auipc	a2,0x2
ffffffffc0202cc6:	b3660613          	addi	a2,a2,-1226 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202cca:	1ae00593          	li	a1,430
ffffffffc0202cce:	00002517          	auipc	a0,0x2
ffffffffc0202cd2:	02a50513          	addi	a0,a0,42 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202cd6:	f84fd0ef          	jal	ra,ffffffffc020045a <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202cda:	00002617          	auipc	a2,0x2
ffffffffc0202cde:	fae60613          	addi	a2,a2,-82 # ffffffffc0204c88 <default_pmm_manager+0xe0>
ffffffffc0202ce2:	0cb00593          	li	a1,203
ffffffffc0202ce6:	00002517          	auipc	a0,0x2
ffffffffc0202cea:	01250513          	addi	a0,a0,18 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202cee:	f6cfd0ef          	jal	ra,ffffffffc020045a <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202cf2:	00002617          	auipc	a2,0x2
ffffffffc0202cf6:	f9660613          	addi	a2,a2,-106 # ffffffffc0204c88 <default_pmm_manager+0xe0>
ffffffffc0202cfa:	08000593          	li	a1,128
ffffffffc0202cfe:	00002517          	auipc	a0,0x2
ffffffffc0202d02:	ffa50513          	addi	a0,a0,-6 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202d06:	f54fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202d0a:	00002697          	auipc	a3,0x2
ffffffffc0202d0e:	16e68693          	addi	a3,a3,366 # ffffffffc0204e78 <default_pmm_manager+0x2d0>
ffffffffc0202d12:	00002617          	auipc	a2,0x2
ffffffffc0202d16:	ae660613          	addi	a2,a2,-1306 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202d1a:	16e00593          	li	a1,366
ffffffffc0202d1e:	00002517          	auipc	a0,0x2
ffffffffc0202d22:	fda50513          	addi	a0,a0,-38 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202d26:	f34fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202d2a:	00002697          	auipc	a3,0x2
ffffffffc0202d2e:	11e68693          	addi	a3,a3,286 # ffffffffc0204e48 <default_pmm_manager+0x2a0>
ffffffffc0202d32:	00002617          	auipc	a2,0x2
ffffffffc0202d36:	ac660613          	addi	a2,a2,-1338 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202d3a:	16b00593          	li	a1,363
ffffffffc0202d3e:	00002517          	auipc	a0,0x2
ffffffffc0202d42:	fba50513          	addi	a0,a0,-70 # ffffffffc0204cf8 <default_pmm_manager+0x150>
ffffffffc0202d46:	f14fd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0202d4a <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202d4a:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0202d4c:	00002697          	auipc	a3,0x2
ffffffffc0202d50:	55468693          	addi	a3,a3,1364 # ffffffffc02052a0 <default_pmm_manager+0x6f8>
ffffffffc0202d54:	00002617          	auipc	a2,0x2
ffffffffc0202d58:	aa460613          	addi	a2,a2,-1372 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202d5c:	08800593          	li	a1,136
ffffffffc0202d60:	00002517          	auipc	a0,0x2
ffffffffc0202d64:	56050513          	addi	a0,a0,1376 # ffffffffc02052c0 <default_pmm_manager+0x718>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202d68:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0202d6a:	ef0fd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0202d6e <find_vma>:
{
ffffffffc0202d6e:	86aa                	mv	a3,a0
    if (mm != NULL)
ffffffffc0202d70:	c505                	beqz	a0,ffffffffc0202d98 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0202d72:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202d74:	c501                	beqz	a0,ffffffffc0202d7c <find_vma+0xe>
ffffffffc0202d76:	651c                	ld	a5,8(a0)
ffffffffc0202d78:	02f5f263          	bgeu	a1,a5,ffffffffc0202d9c <find_vma+0x2e>
    return listelm->next;
ffffffffc0202d7c:	669c                	ld	a5,8(a3)
            while ((le = list_next(le)) != list)
ffffffffc0202d7e:	00f68d63          	beq	a3,a5,ffffffffc0202d98 <find_vma+0x2a>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0202d82:	fe87b703          	ld	a4,-24(a5) # ffffffffc7ffffe8 <end+0x7df2afc>
ffffffffc0202d86:	00e5e663          	bltu	a1,a4,ffffffffc0202d92 <find_vma+0x24>
ffffffffc0202d8a:	ff07b703          	ld	a4,-16(a5)
ffffffffc0202d8e:	00e5ec63          	bltu	a1,a4,ffffffffc0202da6 <find_vma+0x38>
ffffffffc0202d92:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0202d94:	fef697e3          	bne	a3,a5,ffffffffc0202d82 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0202d98:	4501                	li	a0,0
}
ffffffffc0202d9a:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202d9c:	691c                	ld	a5,16(a0)
ffffffffc0202d9e:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0202d7c <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0202da2:	ea88                	sd	a0,16(a3)
ffffffffc0202da4:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0202da6:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0202daa:	ea88                	sd	a0,16(a3)
ffffffffc0202dac:	8082                	ret

ffffffffc0202dae <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202dae:	6590                	ld	a2,8(a1)
ffffffffc0202db0:	0105b803          	ld	a6,16(a1)
{
ffffffffc0202db4:	1141                	addi	sp,sp,-16
ffffffffc0202db6:	e406                	sd	ra,8(sp)
ffffffffc0202db8:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202dba:	01066763          	bltu	a2,a6,ffffffffc0202dc8 <insert_vma_struct+0x1a>
ffffffffc0202dbe:	a085                	j	ffffffffc0202e1e <insert_vma_struct+0x70>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202dc0:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202dc4:	04e66863          	bltu	a2,a4,ffffffffc0202e14 <insert_vma_struct+0x66>
ffffffffc0202dc8:	86be                	mv	a3,a5
ffffffffc0202dca:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0202dcc:	fef51ae3          	bne	a0,a5,ffffffffc0202dc0 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0202dd0:	02a68463          	beq	a3,a0,ffffffffc0202df8 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0202dd4:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202dd8:	fe86b883          	ld	a7,-24(a3)
ffffffffc0202ddc:	08e8f163          	bgeu	a7,a4,ffffffffc0202e5e <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202de0:	04e66f63          	bltu	a2,a4,ffffffffc0202e3e <insert_vma_struct+0x90>
    }
    if (le_next != list)
ffffffffc0202de4:	00f50a63          	beq	a0,a5,ffffffffc0202df8 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202de8:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202dec:	05076963          	bltu	a4,a6,ffffffffc0202e3e <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0202df0:	ff07b603          	ld	a2,-16(a5)
ffffffffc0202df4:	02c77363          	bgeu	a4,a2,ffffffffc0202e1a <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0202df8:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0202dfa:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0202dfc:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0202e00:	e390                	sd	a2,0(a5)
ffffffffc0202e02:	e690                	sd	a2,8(a3)
}
ffffffffc0202e04:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0202e06:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0202e08:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0202e0a:	0017079b          	addiw	a5,a4,1
ffffffffc0202e0e:	d11c                	sw	a5,32(a0)
}
ffffffffc0202e10:	0141                	addi	sp,sp,16
ffffffffc0202e12:	8082                	ret
    if (le_prev != list)
ffffffffc0202e14:	fca690e3          	bne	a3,a0,ffffffffc0202dd4 <insert_vma_struct+0x26>
ffffffffc0202e18:	bfd1                	j	ffffffffc0202dec <insert_vma_struct+0x3e>
ffffffffc0202e1a:	f31ff0ef          	jal	ra,ffffffffc0202d4a <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202e1e:	00002697          	auipc	a3,0x2
ffffffffc0202e22:	4b268693          	addi	a3,a3,1202 # ffffffffc02052d0 <default_pmm_manager+0x728>
ffffffffc0202e26:	00002617          	auipc	a2,0x2
ffffffffc0202e2a:	9d260613          	addi	a2,a2,-1582 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202e2e:	08e00593          	li	a1,142
ffffffffc0202e32:	00002517          	auipc	a0,0x2
ffffffffc0202e36:	48e50513          	addi	a0,a0,1166 # ffffffffc02052c0 <default_pmm_manager+0x718>
ffffffffc0202e3a:	e20fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e3e:	00002697          	auipc	a3,0x2
ffffffffc0202e42:	4d268693          	addi	a3,a3,1234 # ffffffffc0205310 <default_pmm_manager+0x768>
ffffffffc0202e46:	00002617          	auipc	a2,0x2
ffffffffc0202e4a:	9b260613          	addi	a2,a2,-1614 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202e4e:	08700593          	li	a1,135
ffffffffc0202e52:	00002517          	auipc	a0,0x2
ffffffffc0202e56:	46e50513          	addi	a0,a0,1134 # ffffffffc02052c0 <default_pmm_manager+0x718>
ffffffffc0202e5a:	e00fd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202e5e:	00002697          	auipc	a3,0x2
ffffffffc0202e62:	49268693          	addi	a3,a3,1170 # ffffffffc02052f0 <default_pmm_manager+0x748>
ffffffffc0202e66:	00002617          	auipc	a2,0x2
ffffffffc0202e6a:	99260613          	addi	a2,a2,-1646 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202e6e:	08600593          	li	a1,134
ffffffffc0202e72:	00002517          	auipc	a0,0x2
ffffffffc0202e76:	44e50513          	addi	a0,a0,1102 # ffffffffc02052c0 <default_pmm_manager+0x718>
ffffffffc0202e7a:	de0fd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0202e7e <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0202e7e:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202e80:	03000513          	li	a0,48
{
ffffffffc0202e84:	fc06                	sd	ra,56(sp)
ffffffffc0202e86:	f822                	sd	s0,48(sp)
ffffffffc0202e88:	f426                	sd	s1,40(sp)
ffffffffc0202e8a:	f04a                	sd	s2,32(sp)
ffffffffc0202e8c:	ec4e                	sd	s3,24(sp)
ffffffffc0202e8e:	e852                	sd	s4,16(sp)
ffffffffc0202e90:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202e92:	bd5fe0ef          	jal	ra,ffffffffc0201a66 <kmalloc>
    if (mm != NULL)
ffffffffc0202e96:	2e050f63          	beqz	a0,ffffffffc0203194 <vmm_init+0x316>
ffffffffc0202e9a:	84aa                	mv	s1,a0
    elm->prev = elm->next = elm;
ffffffffc0202e9c:	e508                	sd	a0,8(a0)
ffffffffc0202e9e:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0202ea0:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0202ea4:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0202ea8:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0202eac:	02053423          	sd	zero,40(a0)
ffffffffc0202eb0:	03200413          	li	s0,50
ffffffffc0202eb4:	a811                	j	ffffffffc0202ec8 <vmm_init+0x4a>
        vma->vm_start = vm_start;
ffffffffc0202eb6:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202eb8:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202eba:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
ffffffffc0202ebe:	146d                	addi	s0,s0,-5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202ec0:	8526                	mv	a0,s1
ffffffffc0202ec2:	eedff0ef          	jal	ra,ffffffffc0202dae <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0202ec6:	c80d                	beqz	s0,ffffffffc0202ef8 <vmm_init+0x7a>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202ec8:	03000513          	li	a0,48
ffffffffc0202ecc:	b9bfe0ef          	jal	ra,ffffffffc0201a66 <kmalloc>
ffffffffc0202ed0:	85aa                	mv	a1,a0
ffffffffc0202ed2:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0202ed6:	f165                	bnez	a0,ffffffffc0202eb6 <vmm_init+0x38>
        assert(vma != NULL);
ffffffffc0202ed8:	00002697          	auipc	a3,0x2
ffffffffc0202edc:	5d068693          	addi	a3,a3,1488 # ffffffffc02054a8 <default_pmm_manager+0x900>
ffffffffc0202ee0:	00002617          	auipc	a2,0x2
ffffffffc0202ee4:	91860613          	addi	a2,a2,-1768 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202ee8:	0da00593          	li	a1,218
ffffffffc0202eec:	00002517          	auipc	a0,0x2
ffffffffc0202ef0:	3d450513          	addi	a0,a0,980 # ffffffffc02052c0 <default_pmm_manager+0x718>
ffffffffc0202ef4:	d66fd0ef          	jal	ra,ffffffffc020045a <__panic>
ffffffffc0202ef8:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202efc:	1f900913          	li	s2,505
ffffffffc0202f00:	a819                	j	ffffffffc0202f16 <vmm_init+0x98>
        vma->vm_start = vm_start;
ffffffffc0202f02:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0202f04:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202f06:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f0a:	0415                	addi	s0,s0,5
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202f0c:	8526                	mv	a0,s1
ffffffffc0202f0e:	ea1ff0ef          	jal	ra,ffffffffc0202dae <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202f12:	03240a63          	beq	s0,s2,ffffffffc0202f46 <vmm_init+0xc8>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202f16:	03000513          	li	a0,48
ffffffffc0202f1a:	b4dfe0ef          	jal	ra,ffffffffc0201a66 <kmalloc>
ffffffffc0202f1e:	85aa                	mv	a1,a0
ffffffffc0202f20:	00240793          	addi	a5,s0,2
    if (vma != NULL)
ffffffffc0202f24:	fd79                	bnez	a0,ffffffffc0202f02 <vmm_init+0x84>
        assert(vma != NULL);
ffffffffc0202f26:	00002697          	auipc	a3,0x2
ffffffffc0202f2a:	58268693          	addi	a3,a3,1410 # ffffffffc02054a8 <default_pmm_manager+0x900>
ffffffffc0202f2e:	00002617          	auipc	a2,0x2
ffffffffc0202f32:	8ca60613          	addi	a2,a2,-1846 # ffffffffc02047f8 <commands+0x708>
ffffffffc0202f36:	0e100593          	li	a1,225
ffffffffc0202f3a:	00002517          	auipc	a0,0x2
ffffffffc0202f3e:	38650513          	addi	a0,a0,902 # ffffffffc02052c0 <default_pmm_manager+0x718>
ffffffffc0202f42:	d18fd0ef          	jal	ra,ffffffffc020045a <__panic>
    return listelm->next;
ffffffffc0202f46:	649c                	ld	a5,8(s1)
ffffffffc0202f48:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0202f4a:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0202f4e:	18f48363          	beq	s1,a5,ffffffffc02030d4 <vmm_init+0x256>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202f52:	fe87b603          	ld	a2,-24(a5)
ffffffffc0202f56:	ffe70693          	addi	a3,a4,-2 # ffe <kern_entry-0xffffffffc01ff002>
ffffffffc0202f5a:	10d61d63          	bne	a2,a3,ffffffffc0203074 <vmm_init+0x1f6>
ffffffffc0202f5e:	ff07b683          	ld	a3,-16(a5)
ffffffffc0202f62:	10e69963          	bne	a3,a4,ffffffffc0203074 <vmm_init+0x1f6>
    for (i = 1; i <= step2; i++)
ffffffffc0202f66:	0715                	addi	a4,a4,5
ffffffffc0202f68:	679c                	ld	a5,8(a5)
ffffffffc0202f6a:	feb712e3          	bne	a4,a1,ffffffffc0202f4e <vmm_init+0xd0>
ffffffffc0202f6e:	4a1d                	li	s4,7
ffffffffc0202f70:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0202f72:	1f900a93          	li	s5,505
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0202f76:	85a2                	mv	a1,s0
ffffffffc0202f78:	8526                	mv	a0,s1
ffffffffc0202f7a:	df5ff0ef          	jal	ra,ffffffffc0202d6e <find_vma>
ffffffffc0202f7e:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0202f80:	18050a63          	beqz	a0,ffffffffc0203114 <vmm_init+0x296>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0202f84:	00140593          	addi	a1,s0,1
ffffffffc0202f88:	8526                	mv	a0,s1
ffffffffc0202f8a:	de5ff0ef          	jal	ra,ffffffffc0202d6e <find_vma>
ffffffffc0202f8e:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0202f90:	16050263          	beqz	a0,ffffffffc02030f4 <vmm_init+0x276>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0202f94:	85d2                	mv	a1,s4
ffffffffc0202f96:	8526                	mv	a0,s1
ffffffffc0202f98:	dd7ff0ef          	jal	ra,ffffffffc0202d6e <find_vma>
        assert(vma3 == NULL);
ffffffffc0202f9c:	18051c63          	bnez	a0,ffffffffc0203134 <vmm_init+0x2b6>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0202fa0:	00340593          	addi	a1,s0,3
ffffffffc0202fa4:	8526                	mv	a0,s1
ffffffffc0202fa6:	dc9ff0ef          	jal	ra,ffffffffc0202d6e <find_vma>
        assert(vma4 == NULL);
ffffffffc0202faa:	1c051563          	bnez	a0,ffffffffc0203174 <vmm_init+0x2f6>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0202fae:	00440593          	addi	a1,s0,4
ffffffffc0202fb2:	8526                	mv	a0,s1
ffffffffc0202fb4:	dbbff0ef          	jal	ra,ffffffffc0202d6e <find_vma>
        assert(vma5 == NULL);
ffffffffc0202fb8:	18051e63          	bnez	a0,ffffffffc0203154 <vmm_init+0x2d6>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0202fbc:	00893783          	ld	a5,8(s2)
ffffffffc0202fc0:	0c879a63          	bne	a5,s0,ffffffffc0203094 <vmm_init+0x216>
ffffffffc0202fc4:	01093783          	ld	a5,16(s2)
ffffffffc0202fc8:	0d479663          	bne	a5,s4,ffffffffc0203094 <vmm_init+0x216>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0202fcc:	0089b783          	ld	a5,8(s3)
ffffffffc0202fd0:	0e879263          	bne	a5,s0,ffffffffc02030b4 <vmm_init+0x236>
ffffffffc0202fd4:	0109b783          	ld	a5,16(s3)
ffffffffc0202fd8:	0d479e63          	bne	a5,s4,ffffffffc02030b4 <vmm_init+0x236>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0202fdc:	0415                	addi	s0,s0,5
ffffffffc0202fde:	0a15                	addi	s4,s4,5
ffffffffc0202fe0:	f9541be3          	bne	s0,s5,ffffffffc0202f76 <vmm_init+0xf8>
ffffffffc0202fe4:	4411                	li	s0,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0202fe6:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0202fe8:	85a2                	mv	a1,s0
ffffffffc0202fea:	8526                	mv	a0,s1
ffffffffc0202fec:	d83ff0ef          	jal	ra,ffffffffc0202d6e <find_vma>
ffffffffc0202ff0:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL)
ffffffffc0202ff4:	c90d                	beqz	a0,ffffffffc0203026 <vmm_init+0x1a8>
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0202ff6:	6914                	ld	a3,16(a0)
ffffffffc0202ff8:	6510                	ld	a2,8(a0)
ffffffffc0202ffa:	00002517          	auipc	a0,0x2
ffffffffc0202ffe:	43650513          	addi	a0,a0,1078 # ffffffffc0205430 <default_pmm_manager+0x888>
ffffffffc0203002:	992fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0203006:	00002697          	auipc	a3,0x2
ffffffffc020300a:	45268693          	addi	a3,a3,1106 # ffffffffc0205458 <default_pmm_manager+0x8b0>
ffffffffc020300e:	00001617          	auipc	a2,0x1
ffffffffc0203012:	7ea60613          	addi	a2,a2,2026 # ffffffffc02047f8 <commands+0x708>
ffffffffc0203016:	10700593          	li	a1,263
ffffffffc020301a:	00002517          	auipc	a0,0x2
ffffffffc020301e:	2a650513          	addi	a0,a0,678 # ffffffffc02052c0 <default_pmm_manager+0x718>
ffffffffc0203022:	c38fd0ef          	jal	ra,ffffffffc020045a <__panic>
    for (i = 4; i >= 0; i--)
ffffffffc0203026:	147d                	addi	s0,s0,-1
ffffffffc0203028:	fd2410e3          	bne	s0,s2,ffffffffc0202fe8 <vmm_init+0x16a>
ffffffffc020302c:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list)
ffffffffc020302e:	00a48c63          	beq	s1,a0,ffffffffc0203046 <vmm_init+0x1c8>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203032:	6118                	ld	a4,0(a0)
ffffffffc0203034:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0203036:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203038:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020303a:	e398                	sd	a4,0(a5)
ffffffffc020303c:	adbfe0ef          	jal	ra,ffffffffc0201b16 <kfree>
    return listelm->next;
ffffffffc0203040:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list)
ffffffffc0203042:	fea498e3          	bne	s1,a0,ffffffffc0203032 <vmm_init+0x1b4>
    kfree(mm); // kfree mm
ffffffffc0203046:	8526                	mv	a0,s1
ffffffffc0203048:	acffe0ef          	jal	ra,ffffffffc0201b16 <kfree>
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc020304c:	00002517          	auipc	a0,0x2
ffffffffc0203050:	42450513          	addi	a0,a0,1060 # ffffffffc0205470 <default_pmm_manager+0x8c8>
ffffffffc0203054:	940fd0ef          	jal	ra,ffffffffc0200194 <cprintf>
}
ffffffffc0203058:	7442                	ld	s0,48(sp)
ffffffffc020305a:	70e2                	ld	ra,56(sp)
ffffffffc020305c:	74a2                	ld	s1,40(sp)
ffffffffc020305e:	7902                	ld	s2,32(sp)
ffffffffc0203060:	69e2                	ld	s3,24(sp)
ffffffffc0203062:	6a42                	ld	s4,16(sp)
ffffffffc0203064:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203066:	00002517          	auipc	a0,0x2
ffffffffc020306a:	42a50513          	addi	a0,a0,1066 # ffffffffc0205490 <default_pmm_manager+0x8e8>
}
ffffffffc020306e:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203070:	924fd06f          	j	ffffffffc0200194 <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203074:	00002697          	auipc	a3,0x2
ffffffffc0203078:	2d468693          	addi	a3,a3,724 # ffffffffc0205348 <default_pmm_manager+0x7a0>
ffffffffc020307c:	00001617          	auipc	a2,0x1
ffffffffc0203080:	77c60613          	addi	a2,a2,1916 # ffffffffc02047f8 <commands+0x708>
ffffffffc0203084:	0eb00593          	li	a1,235
ffffffffc0203088:	00002517          	auipc	a0,0x2
ffffffffc020308c:	23850513          	addi	a0,a0,568 # ffffffffc02052c0 <default_pmm_manager+0x718>
ffffffffc0203090:	bcafd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203094:	00002697          	auipc	a3,0x2
ffffffffc0203098:	33c68693          	addi	a3,a3,828 # ffffffffc02053d0 <default_pmm_manager+0x828>
ffffffffc020309c:	00001617          	auipc	a2,0x1
ffffffffc02030a0:	75c60613          	addi	a2,a2,1884 # ffffffffc02047f8 <commands+0x708>
ffffffffc02030a4:	0fc00593          	li	a1,252
ffffffffc02030a8:	00002517          	auipc	a0,0x2
ffffffffc02030ac:	21850513          	addi	a0,a0,536 # ffffffffc02052c0 <default_pmm_manager+0x718>
ffffffffc02030b0:	baafd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc02030b4:	00002697          	auipc	a3,0x2
ffffffffc02030b8:	34c68693          	addi	a3,a3,844 # ffffffffc0205400 <default_pmm_manager+0x858>
ffffffffc02030bc:	00001617          	auipc	a2,0x1
ffffffffc02030c0:	73c60613          	addi	a2,a2,1852 # ffffffffc02047f8 <commands+0x708>
ffffffffc02030c4:	0fd00593          	li	a1,253
ffffffffc02030c8:	00002517          	auipc	a0,0x2
ffffffffc02030cc:	1f850513          	addi	a0,a0,504 # ffffffffc02052c0 <default_pmm_manager+0x718>
ffffffffc02030d0:	b8afd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc02030d4:	00002697          	auipc	a3,0x2
ffffffffc02030d8:	25c68693          	addi	a3,a3,604 # ffffffffc0205330 <default_pmm_manager+0x788>
ffffffffc02030dc:	00001617          	auipc	a2,0x1
ffffffffc02030e0:	71c60613          	addi	a2,a2,1820 # ffffffffc02047f8 <commands+0x708>
ffffffffc02030e4:	0e900593          	li	a1,233
ffffffffc02030e8:	00002517          	auipc	a0,0x2
ffffffffc02030ec:	1d850513          	addi	a0,a0,472 # ffffffffc02052c0 <default_pmm_manager+0x718>
ffffffffc02030f0:	b6afd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma2 != NULL);
ffffffffc02030f4:	00002697          	auipc	a3,0x2
ffffffffc02030f8:	29c68693          	addi	a3,a3,668 # ffffffffc0205390 <default_pmm_manager+0x7e8>
ffffffffc02030fc:	00001617          	auipc	a2,0x1
ffffffffc0203100:	6fc60613          	addi	a2,a2,1788 # ffffffffc02047f8 <commands+0x708>
ffffffffc0203104:	0f400593          	li	a1,244
ffffffffc0203108:	00002517          	auipc	a0,0x2
ffffffffc020310c:	1b850513          	addi	a0,a0,440 # ffffffffc02052c0 <default_pmm_manager+0x718>
ffffffffc0203110:	b4afd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma1 != NULL);
ffffffffc0203114:	00002697          	auipc	a3,0x2
ffffffffc0203118:	26c68693          	addi	a3,a3,620 # ffffffffc0205380 <default_pmm_manager+0x7d8>
ffffffffc020311c:	00001617          	auipc	a2,0x1
ffffffffc0203120:	6dc60613          	addi	a2,a2,1756 # ffffffffc02047f8 <commands+0x708>
ffffffffc0203124:	0f200593          	li	a1,242
ffffffffc0203128:	00002517          	auipc	a0,0x2
ffffffffc020312c:	19850513          	addi	a0,a0,408 # ffffffffc02052c0 <default_pmm_manager+0x718>
ffffffffc0203130:	b2afd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma3 == NULL);
ffffffffc0203134:	00002697          	auipc	a3,0x2
ffffffffc0203138:	26c68693          	addi	a3,a3,620 # ffffffffc02053a0 <default_pmm_manager+0x7f8>
ffffffffc020313c:	00001617          	auipc	a2,0x1
ffffffffc0203140:	6bc60613          	addi	a2,a2,1724 # ffffffffc02047f8 <commands+0x708>
ffffffffc0203144:	0f600593          	li	a1,246
ffffffffc0203148:	00002517          	auipc	a0,0x2
ffffffffc020314c:	17850513          	addi	a0,a0,376 # ffffffffc02052c0 <default_pmm_manager+0x718>
ffffffffc0203150:	b0afd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma5 == NULL);
ffffffffc0203154:	00002697          	auipc	a3,0x2
ffffffffc0203158:	26c68693          	addi	a3,a3,620 # ffffffffc02053c0 <default_pmm_manager+0x818>
ffffffffc020315c:	00001617          	auipc	a2,0x1
ffffffffc0203160:	69c60613          	addi	a2,a2,1692 # ffffffffc02047f8 <commands+0x708>
ffffffffc0203164:	0fa00593          	li	a1,250
ffffffffc0203168:	00002517          	auipc	a0,0x2
ffffffffc020316c:	15850513          	addi	a0,a0,344 # ffffffffc02052c0 <default_pmm_manager+0x718>
ffffffffc0203170:	aeafd0ef          	jal	ra,ffffffffc020045a <__panic>
        assert(vma4 == NULL);
ffffffffc0203174:	00002697          	auipc	a3,0x2
ffffffffc0203178:	23c68693          	addi	a3,a3,572 # ffffffffc02053b0 <default_pmm_manager+0x808>
ffffffffc020317c:	00001617          	auipc	a2,0x1
ffffffffc0203180:	67c60613          	addi	a2,a2,1660 # ffffffffc02047f8 <commands+0x708>
ffffffffc0203184:	0f800593          	li	a1,248
ffffffffc0203188:	00002517          	auipc	a0,0x2
ffffffffc020318c:	13850513          	addi	a0,a0,312 # ffffffffc02052c0 <default_pmm_manager+0x718>
ffffffffc0203190:	acafd0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(mm != NULL);
ffffffffc0203194:	00002697          	auipc	a3,0x2
ffffffffc0203198:	32468693          	addi	a3,a3,804 # ffffffffc02054b8 <default_pmm_manager+0x910>
ffffffffc020319c:	00001617          	auipc	a2,0x1
ffffffffc02031a0:	65c60613          	addi	a2,a2,1628 # ffffffffc02047f8 <commands+0x708>
ffffffffc02031a4:	0d200593          	li	a1,210
ffffffffc02031a8:	00002517          	auipc	a0,0x2
ffffffffc02031ac:	11850513          	addi	a0,a0,280 # ffffffffc02052c0 <default_pmm_manager+0x718>
ffffffffc02031b0:	aaafd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc02031b4 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc02031b4:	8526                	mv	a0,s1
	jalr s0
ffffffffc02031b6:	9402                	jalr	s0

	jal do_exit
ffffffffc02031b8:	422000ef          	jal	ra,ffffffffc02035da <do_exit>

ffffffffc02031bc <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc02031bc:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc02031be:	0e800513          	li	a0,232
{
ffffffffc02031c2:	e022                	sd	s0,0(sp)
ffffffffc02031c4:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc02031c6:	8a1fe0ef          	jal	ra,ffffffffc0201a66 <kmalloc>
ffffffffc02031ca:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc02031cc:	c129                	beqz	a0,ffffffffc020320e <alloc_proc+0x52>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        proc->state = PROC_UNINIT;
ffffffffc02031ce:	57fd                	li	a5,-1
ffffffffc02031d0:	1782                	slli	a5,a5,0x20
        proc->runs = 0;
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc02031d2:	07000613          	li	a2,112
ffffffffc02031d6:	4581                	li	a1,0
        proc->state = PROC_UNINIT;
ffffffffc02031d8:	e11c                	sd	a5,0(a0)
        proc->runs = 0;
ffffffffc02031da:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;
ffffffffc02031de:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc02031e2:	00052c23          	sw	zero,24(a0)
        proc->parent = NULL;
ffffffffc02031e6:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc02031ea:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc02031ee:	03050513          	addi	a0,a0,48
ffffffffc02031f2:	445000ef          	jal	ra,ffffffffc0203e36 <memset>
        proc->tf = NULL;
        proc->pgdir = 0;
        proc->flags = 0;
        memset(proc->name, 0, PROC_NAME_LEN + 1);
ffffffffc02031f6:	4641                	li	a2,16
        proc->tf = NULL;
ffffffffc02031f8:	0a043023          	sd	zero,160(s0)
        proc->pgdir = 0;
ffffffffc02031fc:	0a043423          	sd	zero,168(s0)
        proc->flags = 0;
ffffffffc0203200:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);
ffffffffc0203204:	4581                	li	a1,0
ffffffffc0203206:	0b440513          	addi	a0,s0,180
ffffffffc020320a:	42d000ef          	jal	ra,ffffffffc0203e36 <memset>
    }
    return proc;
}
ffffffffc020320e:	60a2                	ld	ra,8(sp)
ffffffffc0203210:	8522                	mv	a0,s0
ffffffffc0203212:	6402                	ld	s0,0(sp)
ffffffffc0203214:	0141                	addi	sp,sp,16
ffffffffc0203216:	8082                	ret

ffffffffc0203218 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203218:	0000a797          	auipc	a5,0xa
ffffffffc020321c:	2b87b783          	ld	a5,696(a5) # ffffffffc020d4d0 <current>
ffffffffc0203220:	73c8                	ld	a0,160(a5)
ffffffffc0203222:	b63fd06f          	j	ffffffffc0200d84 <forkrets>

ffffffffc0203226 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0203226:	7179                	addi	sp,sp,-48
ffffffffc0203228:	ec26                	sd	s1,24(sp)
    memset(name, 0, sizeof(name));
ffffffffc020322a:	0000a497          	auipc	s1,0xa
ffffffffc020322e:	21e48493          	addi	s1,s1,542 # ffffffffc020d448 <name.2>
{
ffffffffc0203232:	f022                	sd	s0,32(sp)
ffffffffc0203234:	e84a                	sd	s2,16(sp)
ffffffffc0203236:	842a                	mv	s0,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc0203238:	0000a917          	auipc	s2,0xa
ffffffffc020323c:	29893903          	ld	s2,664(s2) # ffffffffc020d4d0 <current>
    memset(name, 0, sizeof(name));
ffffffffc0203240:	4641                	li	a2,16
ffffffffc0203242:	4581                	li	a1,0
ffffffffc0203244:	8526                	mv	a0,s1
{
ffffffffc0203246:	f406                	sd	ra,40(sp)
ffffffffc0203248:	e44e                	sd	s3,8(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc020324a:	00492983          	lw	s3,4(s2)
    memset(name, 0, sizeof(name));
ffffffffc020324e:	3e9000ef          	jal	ra,ffffffffc0203e36 <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc0203252:	0b490593          	addi	a1,s2,180
ffffffffc0203256:	463d                	li	a2,15
ffffffffc0203258:	8526                	mv	a0,s1
ffffffffc020325a:	3ef000ef          	jal	ra,ffffffffc0203e48 <memcpy>
ffffffffc020325e:	862a                	mv	a2,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc0203260:	85ce                	mv	a1,s3
ffffffffc0203262:	00002517          	auipc	a0,0x2
ffffffffc0203266:	26650513          	addi	a0,a0,614 # ffffffffc02054c8 <default_pmm_manager+0x920>
ffffffffc020326a:	f2bfc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg);
ffffffffc020326e:	85a2                	mv	a1,s0
ffffffffc0203270:	00002517          	auipc	a0,0x2
ffffffffc0203274:	28050513          	addi	a0,a0,640 # ffffffffc02054f0 <default_pmm_manager+0x948>
ffffffffc0203278:	f1dfc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
ffffffffc020327c:	00002517          	auipc	a0,0x2
ffffffffc0203280:	28450513          	addi	a0,a0,644 # ffffffffc0205500 <default_pmm_manager+0x958>
ffffffffc0203284:	f11fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc0203288:	70a2                	ld	ra,40(sp)
ffffffffc020328a:	7402                	ld	s0,32(sp)
ffffffffc020328c:	64e2                	ld	s1,24(sp)
ffffffffc020328e:	6942                	ld	s2,16(sp)
ffffffffc0203290:	69a2                	ld	s3,8(sp)
ffffffffc0203292:	4501                	li	a0,0
ffffffffc0203294:	6145                	addi	sp,sp,48
ffffffffc0203296:	8082                	ret

ffffffffc0203298 <proc_run>:
{
ffffffffc0203298:	7179                	addi	sp,sp,-48
ffffffffc020329a:	f026                	sd	s1,32(sp)
    if (proc != current)
ffffffffc020329c:	0000a497          	auipc	s1,0xa
ffffffffc02032a0:	23448493          	addi	s1,s1,564 # ffffffffc020d4d0 <current>
{
ffffffffc02032a4:	ec4a                	sd	s2,24(sp)
    if (proc != current)
ffffffffc02032a6:	0004b903          	ld	s2,0(s1)
{
ffffffffc02032aa:	f406                	sd	ra,40(sp)
    if (proc != current)
ffffffffc02032ac:	04a90563          	beq	s2,a0,ffffffffc02032f6 <proc_run+0x5e>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02032b0:	100027f3          	csrr	a5,sstatus
ffffffffc02032b4:	8b89                	andi	a5,a5,2
ffffffffc02032b6:	ebb5                	bnez	a5,ffffffffc020332a <proc_run+0x92>
        if (proc->mm != NULL)
ffffffffc02032b8:	751c                	ld	a5,40(a0)
        current = proc;
ffffffffc02032ba:	e088                	sd	a0,0(s1)
    return 0;
ffffffffc02032bc:	4481                	li	s1,0
        if (proc->mm != NULL)
ffffffffc02032be:	cfa9                	beqz	a5,ffffffffc0203318 <proc_run+0x80>
            uintptr_t satp = (PADDR(proc->pgdir) >> 12) | (0x8UL << 60);
ffffffffc02032c0:	7554                	ld	a3,168(a0)
ffffffffc02032c2:	c02007b7          	lui	a5,0xc0200
ffffffffc02032c6:	06f6eb63          	bltu	a3,a5,ffffffffc020333c <proc_run+0xa4>
ffffffffc02032ca:	0000a797          	auipc	a5,0xa
ffffffffc02032ce:	1fe7b783          	ld	a5,510(a5) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc02032d2:	8e9d                	sub	a3,a3,a5
ffffffffc02032d4:	82b1                	srli	a3,a3,0xc
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned int pgdir)
{
  write_csr(satp, SATP32_MODE | (pgdir >> RISCV_PGSHIFT));
ffffffffc02032d6:	800007b7          	lui	a5,0x80000
ffffffffc02032da:	00c6d69b          	srliw	a3,a3,0xc
ffffffffc02032de:	8edd                	or	a3,a3,a5
ffffffffc02032e0:	18069073          	csrw	satp,a3
            asm volatile("sfence.vma"); // Flush TLB after changing satp
ffffffffc02032e4:	12000073          	sfence.vma
        switch_to(&(prev->context), &(proc->context));
ffffffffc02032e8:	03050593          	addi	a1,a0,48
ffffffffc02032ec:	03090513          	addi	a0,s2,48
ffffffffc02032f0:	570000ef          	jal	ra,ffffffffc0203860 <switch_to>
    if (flag) {
ffffffffc02032f4:	ec81                	bnez	s1,ffffffffc020330c <proc_run+0x74>
}
ffffffffc02032f6:	70a2                	ld	ra,40(sp)
ffffffffc02032f8:	7482                	ld	s1,32(sp)
ffffffffc02032fa:	6962                	ld	s2,24(sp)
ffffffffc02032fc:	6145                	addi	sp,sp,48
ffffffffc02032fe:	8082                	ret
        switch_to(&(prev->context), &(proc->context));
ffffffffc0203300:	03050593          	addi	a1,a0,48
ffffffffc0203304:	03090513          	addi	a0,s2,48
ffffffffc0203308:	558000ef          	jal	ra,ffffffffc0203860 <switch_to>
}
ffffffffc020330c:	70a2                	ld	ra,40(sp)
ffffffffc020330e:	7482                	ld	s1,32(sp)
ffffffffc0203310:	6962                	ld	s2,24(sp)
ffffffffc0203312:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0203314:	e16fd06f          	j	ffffffffc020092a <intr_enable>
ffffffffc0203318:	70a2                	ld	ra,40(sp)
ffffffffc020331a:	7482                	ld	s1,32(sp)
        switch_to(&(prev->context), &(proc->context));
ffffffffc020331c:	03050593          	addi	a1,a0,48
ffffffffc0203320:	03090513          	addi	a0,s2,48
}
ffffffffc0203324:	6962                	ld	s2,24(sp)
ffffffffc0203326:	6145                	addi	sp,sp,48
        switch_to(&(prev->context), &(proc->context));
ffffffffc0203328:	ab25                	j	ffffffffc0203860 <switch_to>
ffffffffc020332a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020332c:	e04fd0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        if (proc->mm != NULL)
ffffffffc0203330:	6522                	ld	a0,8(sp)
ffffffffc0203332:	751c                	ld	a5,40(a0)
        current = proc;
ffffffffc0203334:	e088                	sd	a0,0(s1)
        if (proc->mm != NULL)
ffffffffc0203336:	d7e9                	beqz	a5,ffffffffc0203300 <proc_run+0x68>
        return 1;
ffffffffc0203338:	4485                	li	s1,1
ffffffffc020333a:	b759                	j	ffffffffc02032c0 <proc_run+0x28>
            uintptr_t satp = (PADDR(proc->pgdir) >> 12) | (0x8UL << 60);
ffffffffc020333c:	00002617          	auipc	a2,0x2
ffffffffc0203340:	94c60613          	addi	a2,a2,-1716 # ffffffffc0204c88 <default_pmm_manager+0xe0>
ffffffffc0203344:	0d100593          	li	a1,209
ffffffffc0203348:	00002517          	auipc	a0,0x2
ffffffffc020334c:	1d850513          	addi	a0,a0,472 # ffffffffc0205520 <default_pmm_manager+0x978>
ffffffffc0203350:	90afd0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0203354 <do_fork>:
{
ffffffffc0203354:	7179                	addi	sp,sp,-48
ffffffffc0203356:	ec26                	sd	s1,24(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc0203358:	0000a497          	auipc	s1,0xa
ffffffffc020335c:	19048493          	addi	s1,s1,400 # ffffffffc020d4e8 <nr_process>
ffffffffc0203360:	4098                	lw	a4,0(s1)
{
ffffffffc0203362:	f406                	sd	ra,40(sp)
ffffffffc0203364:	f022                	sd	s0,32(sp)
ffffffffc0203366:	e84a                	sd	s2,16(sp)
ffffffffc0203368:	e44e                	sd	s3,8(sp)
    if (nr_process >= MAX_PROCESS)
ffffffffc020336a:	6785                	lui	a5,0x1
ffffffffc020336c:	1cf75c63          	bge	a4,a5,ffffffffc0203544 <do_fork+0x1f0>
ffffffffc0203370:	892e                	mv	s2,a1
ffffffffc0203372:	8432                	mv	s0,a2
    proc = alloc_proc();
ffffffffc0203374:	e49ff0ef          	jal	ra,ffffffffc02031bc <alloc_proc>
ffffffffc0203378:	89aa                	mv	s3,a0
    if (!proc)
ffffffffc020337a:	1c050a63          	beqz	a0,ffffffffc020354e <do_fork+0x1fa>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc020337e:	4509                	li	a0,2
ffffffffc0203380:	8c5fe0ef          	jal	ra,ffffffffc0201c44 <alloc_pages>
    if (page != NULL)
ffffffffc0203384:	1a050b63          	beqz	a0,ffffffffc020353a <do_fork+0x1e6>
    return page - pages + nbase;
ffffffffc0203388:	0000a697          	auipc	a3,0xa
ffffffffc020338c:	1306b683          	ld	a3,304(a3) # ffffffffc020d4b8 <pages>
ffffffffc0203390:	40d506b3          	sub	a3,a0,a3
ffffffffc0203394:	8699                	srai	a3,a3,0x6
ffffffffc0203396:	00002517          	auipc	a0,0x2
ffffffffc020339a:	52a53503          	ld	a0,1322(a0) # ffffffffc02058c0 <nbase>
ffffffffc020339e:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc02033a0:	00c69793          	slli	a5,a3,0xc
ffffffffc02033a4:	83b1                	srli	a5,a5,0xc
ffffffffc02033a6:	0000a717          	auipc	a4,0xa
ffffffffc02033aa:	10a73703          	ld	a4,266(a4) # ffffffffc020d4b0 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc02033ae:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02033b0:	1ce7f163          	bgeu	a5,a4,ffffffffc0203572 <do_fork+0x21e>
    assert(current->mm == NULL);
ffffffffc02033b4:	0000ae17          	auipc	t3,0xa
ffffffffc02033b8:	11ce3e03          	ld	t3,284(t3) # ffffffffc020d4d0 <current>
ffffffffc02033bc:	028e3783          	ld	a5,40(t3)
ffffffffc02033c0:	0000a717          	auipc	a4,0xa
ffffffffc02033c4:	10873703          	ld	a4,264(a4) # ffffffffc020d4c8 <va_pa_offset>
ffffffffc02033c8:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02033ca:	00d9b823          	sd	a3,16(s3)
    assert(current->mm == NULL);
ffffffffc02033ce:	18079263          	bnez	a5,ffffffffc0203552 <do_fork+0x1fe>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc02033d2:	6789                	lui	a5,0x2
ffffffffc02033d4:	ee078793          	addi	a5,a5,-288 # 1ee0 <kern_entry-0xffffffffc01fe120>
ffffffffc02033d8:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc02033da:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc02033dc:	0ad9b023          	sd	a3,160(s3)
    *(proc->tf) = *tf;
ffffffffc02033e0:	87b6                	mv	a5,a3
ffffffffc02033e2:	12040893          	addi	a7,s0,288
ffffffffc02033e6:	00063803          	ld	a6,0(a2)
ffffffffc02033ea:	6608                	ld	a0,8(a2)
ffffffffc02033ec:	6a0c                	ld	a1,16(a2)
ffffffffc02033ee:	6e18                	ld	a4,24(a2)
ffffffffc02033f0:	0107b023          	sd	a6,0(a5)
ffffffffc02033f4:	e788                	sd	a0,8(a5)
ffffffffc02033f6:	eb8c                	sd	a1,16(a5)
ffffffffc02033f8:	ef98                	sd	a4,24(a5)
ffffffffc02033fa:	02060613          	addi	a2,a2,32
ffffffffc02033fe:	02078793          	addi	a5,a5,32
ffffffffc0203402:	ff1612e3          	bne	a2,a7,ffffffffc02033e6 <do_fork+0x92>
    proc->tf->gpr.a0 = 0;
ffffffffc0203406:	0406b823          	sd	zero,80(a3)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020340a:	10090b63          	beqz	s2,ffffffffc0203520 <do_fork+0x1cc>
    if (++last_pid >= MAX_PID)
ffffffffc020340e:	00006317          	auipc	t1,0x6
ffffffffc0203412:	c1a30313          	addi	t1,t1,-998 # ffffffffc0209028 <last_pid.1>
ffffffffc0203416:	00032783          	lw	a5,0(t1)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020341a:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020341e:	00000717          	auipc	a4,0x0
ffffffffc0203422:	dfa70713          	addi	a4,a4,-518 # ffffffffc0203218 <forkret>
    if (++last_pid >= MAX_PID)
ffffffffc0203426:	0017851b          	addiw	a0,a5,1
ffffffffc020342a:	0000a617          	auipc	a2,0xa
ffffffffc020342e:	02e60613          	addi	a2,a2,46 # ffffffffc020d458 <proc_list>
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0203432:	02e9b823          	sd	a4,48(s3)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0203436:	02d9bc23          	sd	a3,56(s3)
    if (++last_pid >= MAX_PID)
ffffffffc020343a:	00a32023          	sw	a0,0(t1)
ffffffffc020343e:	6789                	lui	a5,0x2
ffffffffc0203440:	00863883          	ld	a7,8(a2)
ffffffffc0203444:	06f55c63          	bge	a0,a5,ffffffffc02034bc <do_fork+0x168>
    if (last_pid >= next_safe)
ffffffffc0203448:	00006f17          	auipc	t5,0x6
ffffffffc020344c:	be4f0f13          	addi	t5,t5,-1052 # ffffffffc020902c <next_safe.0>
ffffffffc0203450:	000f2783          	lw	a5,0(t5)
ffffffffc0203454:	06f55c63          	bge	a0,a5,ffffffffc02034cc <do_fork+0x178>
    proc->pid = get_pid();
ffffffffc0203458:	00a9a223          	sw	a0,4(s3)
    list_add(&proc_list, &proc->list_link);
ffffffffc020345c:	0c898793          	addi	a5,s3,200
    proc->parent = current;
ffffffffc0203460:	03c9b023          	sd	t3,32(s3)
    prev->next = next->prev = elm;
ffffffffc0203464:	00f8b023          	sd	a5,0(a7)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0203468:	45a9                	li	a1,10
    elm->next = next;
ffffffffc020346a:	0d19b823          	sd	a7,208(s3)
    elm->prev = prev;
ffffffffc020346e:	0cc9b423          	sd	a2,200(s3)
ffffffffc0203472:	2501                	sext.w	a0,a0
    prev->next = next->prev = elm;
ffffffffc0203474:	e61c                	sd	a5,8(a2)
ffffffffc0203476:	51a000ef          	jal	ra,ffffffffc0203990 <hash32>
ffffffffc020347a:	02051793          	slli	a5,a0,0x20
ffffffffc020347e:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0203482:	00006797          	auipc	a5,0x6
ffffffffc0203486:	fc678793          	addi	a5,a5,-58 # ffffffffc0209448 <hash_list>
ffffffffc020348a:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc020348c:	6518                	ld	a4,8(a0)
    nr_process++;
ffffffffc020348e:	409c                	lw	a5,0(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0203490:	0d898693          	addi	a3,s3,216
    prev->next = next->prev = elm;
ffffffffc0203494:	e314                	sd	a3,0(a4)
ffffffffc0203496:	e514                	sd	a3,8(a0)
    nr_process++;
ffffffffc0203498:	2785                	addiw	a5,a5,1
    elm->prev = prev;
ffffffffc020349a:	0ca9bc23          	sd	a0,216(s3)
    elm->next = next;
ffffffffc020349e:	0ee9b023          	sd	a4,224(s3)
    wakeup_proc(proc);
ffffffffc02034a2:	854e                	mv	a0,s3
    nr_process++;
ffffffffc02034a4:	c09c                	sw	a5,0(s1)
    wakeup_proc(proc);
ffffffffc02034a6:	424000ef          	jal	ra,ffffffffc02038ca <wakeup_proc>
    ret = proc->pid;
ffffffffc02034aa:	0049a503          	lw	a0,4(s3)
}
ffffffffc02034ae:	70a2                	ld	ra,40(sp)
ffffffffc02034b0:	7402                	ld	s0,32(sp)
ffffffffc02034b2:	64e2                	ld	s1,24(sp)
ffffffffc02034b4:	6942                	ld	s2,16(sp)
ffffffffc02034b6:	69a2                	ld	s3,8(sp)
ffffffffc02034b8:	6145                	addi	sp,sp,48
ffffffffc02034ba:	8082                	ret
        last_pid = 1;
ffffffffc02034bc:	4785                	li	a5,1
ffffffffc02034be:	00f32023          	sw	a5,0(t1)
        goto inside;
ffffffffc02034c2:	4505                	li	a0,1
ffffffffc02034c4:	00006f17          	auipc	t5,0x6
ffffffffc02034c8:	b68f0f13          	addi	t5,t5,-1176 # ffffffffc020902c <next_safe.0>
        next_safe = MAX_PID;
ffffffffc02034cc:	6789                	lui	a5,0x2
ffffffffc02034ce:	00ff2023          	sw	a5,0(t5)
ffffffffc02034d2:	86aa                	mv	a3,a0
ffffffffc02034d4:	4801                	li	a6,0
        while ((le = list_next(le)) != list)
ffffffffc02034d6:	6f89                	lui	t6,0x2
ffffffffc02034d8:	04c88b63          	beq	a7,a2,ffffffffc020352e <do_fork+0x1da>
ffffffffc02034dc:	8ec2                	mv	t4,a6
ffffffffc02034de:	87c6                	mv	a5,a7
ffffffffc02034e0:	6589                	lui	a1,0x2
ffffffffc02034e2:	a811                	j	ffffffffc02034f6 <do_fork+0x1a2>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02034e4:	00e6d663          	bge	a3,a4,ffffffffc02034f0 <do_fork+0x19c>
ffffffffc02034e8:	00b75463          	bge	a4,a1,ffffffffc02034f0 <do_fork+0x19c>
ffffffffc02034ec:	85ba                	mv	a1,a4
ffffffffc02034ee:	4e85                	li	t4,1
    return listelm->next;
ffffffffc02034f0:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02034f2:	00c78d63          	beq	a5,a2,ffffffffc020350c <do_fork+0x1b8>
            if (proc->pid == last_pid)
ffffffffc02034f6:	f3c7a703          	lw	a4,-196(a5) # 1f3c <kern_entry-0xffffffffc01fe0c4>
ffffffffc02034fa:	fed715e3          	bne	a4,a3,ffffffffc02034e4 <do_fork+0x190>
                if (++last_pid >= next_safe)
ffffffffc02034fe:	2685                	addiw	a3,a3,1
ffffffffc0203500:	02b6d263          	bge	a3,a1,ffffffffc0203524 <do_fork+0x1d0>
ffffffffc0203504:	679c                	ld	a5,8(a5)
ffffffffc0203506:	4805                	li	a6,1
        while ((le = list_next(le)) != list)
ffffffffc0203508:	fec797e3          	bne	a5,a2,ffffffffc02034f6 <do_fork+0x1a2>
ffffffffc020350c:	00080563          	beqz	a6,ffffffffc0203516 <do_fork+0x1c2>
ffffffffc0203510:	00d32023          	sw	a3,0(t1)
ffffffffc0203514:	8536                	mv	a0,a3
ffffffffc0203516:	f40e81e3          	beqz	t4,ffffffffc0203458 <do_fork+0x104>
ffffffffc020351a:	00bf2023          	sw	a1,0(t5)
ffffffffc020351e:	bf2d                	j	ffffffffc0203458 <do_fork+0x104>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0203520:	8936                	mv	s2,a3
ffffffffc0203522:	b5f5                	j	ffffffffc020340e <do_fork+0xba>
                    if (last_pid >= MAX_PID)
ffffffffc0203524:	01f6c363          	blt	a3,t6,ffffffffc020352a <do_fork+0x1d6>
                        last_pid = 1;
ffffffffc0203528:	4685                	li	a3,1
                    goto repeat;
ffffffffc020352a:	4805                	li	a6,1
ffffffffc020352c:	b775                	j	ffffffffc02034d8 <do_fork+0x184>
ffffffffc020352e:	00080d63          	beqz	a6,ffffffffc0203548 <do_fork+0x1f4>
ffffffffc0203532:	00d32023          	sw	a3,0(t1)
    return last_pid;
ffffffffc0203536:	8536                	mv	a0,a3
ffffffffc0203538:	b705                	j	ffffffffc0203458 <do_fork+0x104>
    kfree(proc);
ffffffffc020353a:	854e                	mv	a0,s3
ffffffffc020353c:	ddafe0ef          	jal	ra,ffffffffc0201b16 <kfree>
    goto fork_out;
ffffffffc0203540:	5571                	li	a0,-4
ffffffffc0203542:	b7b5                	j	ffffffffc02034ae <do_fork+0x15a>
    int ret = -E_NO_FREE_PROC;
ffffffffc0203544:	556d                	li	a0,-5
ffffffffc0203546:	b7a5                	j	ffffffffc02034ae <do_fork+0x15a>
    return last_pid;
ffffffffc0203548:	00032503          	lw	a0,0(t1)
ffffffffc020354c:	b731                	j	ffffffffc0203458 <do_fork+0x104>
    ret = -E_NO_MEM;
ffffffffc020354e:	5571                	li	a0,-4
    return ret;
ffffffffc0203550:	bfb9                	j	ffffffffc02034ae <do_fork+0x15a>
    assert(current->mm == NULL);
ffffffffc0203552:	00002697          	auipc	a3,0x2
ffffffffc0203556:	fe668693          	addi	a3,a3,-26 # ffffffffc0205538 <default_pmm_manager+0x990>
ffffffffc020355a:	00001617          	auipc	a2,0x1
ffffffffc020355e:	29e60613          	addi	a2,a2,670 # ffffffffc02047f8 <commands+0x708>
ffffffffc0203562:	12600593          	li	a1,294
ffffffffc0203566:	00002517          	auipc	a0,0x2
ffffffffc020356a:	fba50513          	addi	a0,a0,-70 # ffffffffc0205520 <default_pmm_manager+0x978>
ffffffffc020356e:	eedfc0ef          	jal	ra,ffffffffc020045a <__panic>
ffffffffc0203572:	00001617          	auipc	a2,0x1
ffffffffc0203576:	66e60613          	addi	a2,a2,1646 # ffffffffc0204be0 <default_pmm_manager+0x38>
ffffffffc020357a:	07100593          	li	a1,113
ffffffffc020357e:	00001517          	auipc	a0,0x1
ffffffffc0203582:	68a50513          	addi	a0,a0,1674 # ffffffffc0204c08 <default_pmm_manager+0x60>
ffffffffc0203586:	ed5fc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc020358a <kernel_thread>:
{
ffffffffc020358a:	7129                	addi	sp,sp,-320
ffffffffc020358c:	fa22                	sd	s0,304(sp)
ffffffffc020358e:	f626                	sd	s1,296(sp)
ffffffffc0203590:	f24a                	sd	s2,288(sp)
ffffffffc0203592:	84ae                	mv	s1,a1
ffffffffc0203594:	892a                	mv	s2,a0
ffffffffc0203596:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0203598:	4581                	li	a1,0
ffffffffc020359a:	12000613          	li	a2,288
ffffffffc020359e:	850a                	mv	a0,sp
{
ffffffffc02035a0:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02035a2:	095000ef          	jal	ra,ffffffffc0203e36 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02035a6:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02035a8:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02035aa:	100027f3          	csrr	a5,sstatus
ffffffffc02035ae:	edd7f793          	andi	a5,a5,-291
ffffffffc02035b2:	1207e793          	ori	a5,a5,288
ffffffffc02035b6:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02035b8:	860a                	mv	a2,sp
ffffffffc02035ba:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02035be:	00000797          	auipc	a5,0x0
ffffffffc02035c2:	bf678793          	addi	a5,a5,-1034 # ffffffffc02031b4 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02035c6:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02035c8:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02035ca:	d8bff0ef          	jal	ra,ffffffffc0203354 <do_fork>
}
ffffffffc02035ce:	70f2                	ld	ra,312(sp)
ffffffffc02035d0:	7452                	ld	s0,304(sp)
ffffffffc02035d2:	74b2                	ld	s1,296(sp)
ffffffffc02035d4:	7912                	ld	s2,288(sp)
ffffffffc02035d6:	6131                	addi	sp,sp,320
ffffffffc02035d8:	8082                	ret

ffffffffc02035da <do_exit>:
{
ffffffffc02035da:	1141                	addi	sp,sp,-16
    panic("process exit!!.\n");
ffffffffc02035dc:	00002617          	auipc	a2,0x2
ffffffffc02035e0:	f7460613          	addi	a2,a2,-140 # ffffffffc0205550 <default_pmm_manager+0x9a8>
ffffffffc02035e4:	19900593          	li	a1,409
ffffffffc02035e8:	00002517          	auipc	a0,0x2
ffffffffc02035ec:	f3850513          	addi	a0,a0,-200 # ffffffffc0205520 <default_pmm_manager+0x978>
{
ffffffffc02035f0:	e406                	sd	ra,8(sp)
    panic("process exit!!.\n");
ffffffffc02035f2:	e69fc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc02035f6 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc02035f6:	7179                	addi	sp,sp,-48
ffffffffc02035f8:	ec26                	sd	s1,24(sp)
    elm->prev = elm->next = elm;
ffffffffc02035fa:	0000a797          	auipc	a5,0xa
ffffffffc02035fe:	e5e78793          	addi	a5,a5,-418 # ffffffffc020d458 <proc_list>
ffffffffc0203602:	f406                	sd	ra,40(sp)
ffffffffc0203604:	f022                	sd	s0,32(sp)
ffffffffc0203606:	e84a                	sd	s2,16(sp)
ffffffffc0203608:	e44e                	sd	s3,8(sp)
ffffffffc020360a:	00006497          	auipc	s1,0x6
ffffffffc020360e:	e3e48493          	addi	s1,s1,-450 # ffffffffc0209448 <hash_list>
ffffffffc0203612:	e79c                	sd	a5,8(a5)
ffffffffc0203614:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0203616:	0000a717          	auipc	a4,0xa
ffffffffc020361a:	e3270713          	addi	a4,a4,-462 # ffffffffc020d448 <name.2>
ffffffffc020361e:	87a6                	mv	a5,s1
ffffffffc0203620:	e79c                	sd	a5,8(a5)
ffffffffc0203622:	e39c                	sd	a5,0(a5)
ffffffffc0203624:	07c1                	addi	a5,a5,16
ffffffffc0203626:	fef71de3          	bne	a4,a5,ffffffffc0203620 <proc_init+0x2a>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc020362a:	b93ff0ef          	jal	ra,ffffffffc02031bc <alloc_proc>
ffffffffc020362e:	0000a917          	auipc	s2,0xa
ffffffffc0203632:	eaa90913          	addi	s2,s2,-342 # ffffffffc020d4d8 <idleproc>
ffffffffc0203636:	00a93023          	sd	a0,0(s2)
ffffffffc020363a:	18050d63          	beqz	a0,ffffffffc02037d4 <proc_init+0x1de>
    {
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc020363e:	07000513          	li	a0,112
ffffffffc0203642:	c24fe0ef          	jal	ra,ffffffffc0201a66 <kmalloc>
    memset(context_mem, 0, sizeof(struct context));
ffffffffc0203646:	07000613          	li	a2,112
ffffffffc020364a:	4581                	li	a1,0
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc020364c:	842a                	mv	s0,a0
    memset(context_mem, 0, sizeof(struct context));
ffffffffc020364e:	7e8000ef          	jal	ra,ffffffffc0203e36 <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
ffffffffc0203652:	00093503          	ld	a0,0(s2)
ffffffffc0203656:	85a2                	mv	a1,s0
ffffffffc0203658:	07000613          	li	a2,112
ffffffffc020365c:	03050513          	addi	a0,a0,48
ffffffffc0203660:	001000ef          	jal	ra,ffffffffc0203e60 <memcmp>
ffffffffc0203664:	89aa                	mv	s3,a0

    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc0203666:	453d                	li	a0,15
ffffffffc0203668:	bfefe0ef          	jal	ra,ffffffffc0201a66 <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc020366c:	463d                	li	a2,15
ffffffffc020366e:	4581                	li	a1,0
    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc0203670:	842a                	mv	s0,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc0203672:	7c4000ef          	jal	ra,ffffffffc0203e36 <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
ffffffffc0203676:	00093503          	ld	a0,0(s2)
ffffffffc020367a:	463d                	li	a2,15
ffffffffc020367c:	85a2                	mv	a1,s0
ffffffffc020367e:	0b450513          	addi	a0,a0,180
ffffffffc0203682:	7de000ef          	jal	ra,ffffffffc0203e60 <memcmp>

    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc0203686:	00093783          	ld	a5,0(s2)
ffffffffc020368a:	0000a717          	auipc	a4,0xa
ffffffffc020368e:	e1673703          	ld	a4,-490(a4) # ffffffffc020d4a0 <boot_pgdir_pa>
ffffffffc0203692:	77d4                	ld	a3,168(a5)
ffffffffc0203694:	0ee68463          	beq	a3,a4,ffffffffc020377c <proc_init+0x186>
    {
        cprintf("alloc_proc() correct!\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0203698:	4709                	li	a4,2
ffffffffc020369a:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc020369c:	00003717          	auipc	a4,0x3
ffffffffc02036a0:	96470713          	addi	a4,a4,-1692 # ffffffffc0206000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02036a4:	0b478413          	addi	s0,a5,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc02036a8:	eb98                	sd	a4,16(a5)
    idleproc->need_resched = 1;
ffffffffc02036aa:	4705                	li	a4,1
ffffffffc02036ac:	cf98                	sw	a4,24(a5)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02036ae:	4641                	li	a2,16
ffffffffc02036b0:	4581                	li	a1,0
ffffffffc02036b2:	8522                	mv	a0,s0
ffffffffc02036b4:	782000ef          	jal	ra,ffffffffc0203e36 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02036b8:	463d                	li	a2,15
ffffffffc02036ba:	00002597          	auipc	a1,0x2
ffffffffc02036be:	ede58593          	addi	a1,a1,-290 # ffffffffc0205598 <default_pmm_manager+0x9f0>
ffffffffc02036c2:	8522                	mv	a0,s0
ffffffffc02036c4:	784000ef          	jal	ra,ffffffffc0203e48 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc02036c8:	0000a717          	auipc	a4,0xa
ffffffffc02036cc:	e2070713          	addi	a4,a4,-480 # ffffffffc020d4e8 <nr_process>
ffffffffc02036d0:	431c                	lw	a5,0(a4)

    current = idleproc;
ffffffffc02036d2:	00093683          	ld	a3,0(s2)

    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02036d6:	4601                	li	a2,0
    nr_process++;
ffffffffc02036d8:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02036da:	00002597          	auipc	a1,0x2
ffffffffc02036de:	ec658593          	addi	a1,a1,-314 # ffffffffc02055a0 <default_pmm_manager+0x9f8>
ffffffffc02036e2:	00000517          	auipc	a0,0x0
ffffffffc02036e6:	b4450513          	addi	a0,a0,-1212 # ffffffffc0203226 <init_main>
    nr_process++;
ffffffffc02036ea:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc02036ec:	0000a797          	auipc	a5,0xa
ffffffffc02036f0:	ded7b223          	sd	a3,-540(a5) # ffffffffc020d4d0 <current>
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc02036f4:	e97ff0ef          	jal	ra,ffffffffc020358a <kernel_thread>
ffffffffc02036f8:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc02036fa:	0ea05963          	blez	a0,ffffffffc02037ec <proc_init+0x1f6>
    if (0 < pid && pid < MAX_PID)
ffffffffc02036fe:	6789                	lui	a5,0x2
ffffffffc0203700:	fff5071b          	addiw	a4,a0,-1
ffffffffc0203704:	17f9                	addi	a5,a5,-2
ffffffffc0203706:	2501                	sext.w	a0,a0
ffffffffc0203708:	02e7e363          	bltu	a5,a4,ffffffffc020372e <proc_init+0x138>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc020370c:	45a9                	li	a1,10
ffffffffc020370e:	282000ef          	jal	ra,ffffffffc0203990 <hash32>
ffffffffc0203712:	02051793          	slli	a5,a0,0x20
ffffffffc0203716:	01c7d693          	srli	a3,a5,0x1c
ffffffffc020371a:	96a6                	add	a3,a3,s1
ffffffffc020371c:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc020371e:	a029                	j	ffffffffc0203728 <proc_init+0x132>
            if (proc->pid == pid)
ffffffffc0203720:	f2c7a703          	lw	a4,-212(a5) # 1f2c <kern_entry-0xffffffffc01fe0d4>
ffffffffc0203724:	0a870563          	beq	a4,s0,ffffffffc02037ce <proc_init+0x1d8>
    return listelm->next;
ffffffffc0203728:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc020372a:	fef69be3          	bne	a3,a5,ffffffffc0203720 <proc_init+0x12a>
    return NULL;
ffffffffc020372e:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203730:	0b478493          	addi	s1,a5,180
ffffffffc0203734:	4641                	li	a2,16
ffffffffc0203736:	4581                	li	a1,0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0203738:	0000a417          	auipc	s0,0xa
ffffffffc020373c:	da840413          	addi	s0,s0,-600 # ffffffffc020d4e0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203740:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0203742:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203744:	6f2000ef          	jal	ra,ffffffffc0203e36 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0203748:	463d                	li	a2,15
ffffffffc020374a:	00002597          	auipc	a1,0x2
ffffffffc020374e:	e8658593          	addi	a1,a1,-378 # ffffffffc02055d0 <default_pmm_manager+0xa28>
ffffffffc0203752:	8526                	mv	a0,s1
ffffffffc0203754:	6f4000ef          	jal	ra,ffffffffc0203e48 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0203758:	00093783          	ld	a5,0(s2)
ffffffffc020375c:	c7e1                	beqz	a5,ffffffffc0203824 <proc_init+0x22e>
ffffffffc020375e:	43dc                	lw	a5,4(a5)
ffffffffc0203760:	e3f1                	bnez	a5,ffffffffc0203824 <proc_init+0x22e>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0203762:	601c                	ld	a5,0(s0)
ffffffffc0203764:	c3c5                	beqz	a5,ffffffffc0203804 <proc_init+0x20e>
ffffffffc0203766:	43d8                	lw	a4,4(a5)
ffffffffc0203768:	4785                	li	a5,1
ffffffffc020376a:	08f71d63          	bne	a4,a5,ffffffffc0203804 <proc_init+0x20e>
}
ffffffffc020376e:	70a2                	ld	ra,40(sp)
ffffffffc0203770:	7402                	ld	s0,32(sp)
ffffffffc0203772:	64e2                	ld	s1,24(sp)
ffffffffc0203774:	6942                	ld	s2,16(sp)
ffffffffc0203776:	69a2                	ld	s3,8(sp)
ffffffffc0203778:	6145                	addi	sp,sp,48
ffffffffc020377a:	8082                	ret
    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc020377c:	73d8                	ld	a4,160(a5)
ffffffffc020377e:	ff09                	bnez	a4,ffffffffc0203698 <proc_init+0xa2>
ffffffffc0203780:	f0099ce3          	bnez	s3,ffffffffc0203698 <proc_init+0xa2>
ffffffffc0203784:	6394                	ld	a3,0(a5)
ffffffffc0203786:	577d                	li	a4,-1
ffffffffc0203788:	1702                	slli	a4,a4,0x20
ffffffffc020378a:	f0e697e3          	bne	a3,a4,ffffffffc0203698 <proc_init+0xa2>
ffffffffc020378e:	4798                	lw	a4,8(a5)
ffffffffc0203790:	f00714e3          	bnez	a4,ffffffffc0203698 <proc_init+0xa2>
ffffffffc0203794:	6b98                	ld	a4,16(a5)
ffffffffc0203796:	f00711e3          	bnez	a4,ffffffffc0203698 <proc_init+0xa2>
ffffffffc020379a:	4f98                	lw	a4,24(a5)
ffffffffc020379c:	2701                	sext.w	a4,a4
ffffffffc020379e:	ee071de3          	bnez	a4,ffffffffc0203698 <proc_init+0xa2>
ffffffffc02037a2:	7398                	ld	a4,32(a5)
ffffffffc02037a4:	ee071ae3          	bnez	a4,ffffffffc0203698 <proc_init+0xa2>
ffffffffc02037a8:	7798                	ld	a4,40(a5)
ffffffffc02037aa:	ee0717e3          	bnez	a4,ffffffffc0203698 <proc_init+0xa2>
ffffffffc02037ae:	0b07a703          	lw	a4,176(a5)
ffffffffc02037b2:	8d59                	or	a0,a0,a4
ffffffffc02037b4:	0005071b          	sext.w	a4,a0
ffffffffc02037b8:	ee0710e3          	bnez	a4,ffffffffc0203698 <proc_init+0xa2>
        cprintf("alloc_proc() correct!\n");
ffffffffc02037bc:	00002517          	auipc	a0,0x2
ffffffffc02037c0:	dc450513          	addi	a0,a0,-572 # ffffffffc0205580 <default_pmm_manager+0x9d8>
ffffffffc02037c4:	9d1fc0ef          	jal	ra,ffffffffc0200194 <cprintf>
    idleproc->pid = 0;
ffffffffc02037c8:	00093783          	ld	a5,0(s2)
ffffffffc02037cc:	b5f1                	j	ffffffffc0203698 <proc_init+0xa2>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02037ce:	f2878793          	addi	a5,a5,-216
ffffffffc02037d2:	bfb9                	j	ffffffffc0203730 <proc_init+0x13a>
        panic("cannot alloc idleproc.\n");
ffffffffc02037d4:	00002617          	auipc	a2,0x2
ffffffffc02037d8:	d9460613          	addi	a2,a2,-620 # ffffffffc0205568 <default_pmm_manager+0x9c0>
ffffffffc02037dc:	1b400593          	li	a1,436
ffffffffc02037e0:	00002517          	auipc	a0,0x2
ffffffffc02037e4:	d4050513          	addi	a0,a0,-704 # ffffffffc0205520 <default_pmm_manager+0x978>
ffffffffc02037e8:	c73fc0ef          	jal	ra,ffffffffc020045a <__panic>
        panic("create init_main failed.\n");
ffffffffc02037ec:	00002617          	auipc	a2,0x2
ffffffffc02037f0:	dc460613          	addi	a2,a2,-572 # ffffffffc02055b0 <default_pmm_manager+0xa08>
ffffffffc02037f4:	1d100593          	li	a1,465
ffffffffc02037f8:	00002517          	auipc	a0,0x2
ffffffffc02037fc:	d2850513          	addi	a0,a0,-728 # ffffffffc0205520 <default_pmm_manager+0x978>
ffffffffc0203800:	c5bfc0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0203804:	00002697          	auipc	a3,0x2
ffffffffc0203808:	dfc68693          	addi	a3,a3,-516 # ffffffffc0205600 <default_pmm_manager+0xa58>
ffffffffc020380c:	00001617          	auipc	a2,0x1
ffffffffc0203810:	fec60613          	addi	a2,a2,-20 # ffffffffc02047f8 <commands+0x708>
ffffffffc0203814:	1d800593          	li	a1,472
ffffffffc0203818:	00002517          	auipc	a0,0x2
ffffffffc020381c:	d0850513          	addi	a0,a0,-760 # ffffffffc0205520 <default_pmm_manager+0x978>
ffffffffc0203820:	c3bfc0ef          	jal	ra,ffffffffc020045a <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0203824:	00002697          	auipc	a3,0x2
ffffffffc0203828:	db468693          	addi	a3,a3,-588 # ffffffffc02055d8 <default_pmm_manager+0xa30>
ffffffffc020382c:	00001617          	auipc	a2,0x1
ffffffffc0203830:	fcc60613          	addi	a2,a2,-52 # ffffffffc02047f8 <commands+0x708>
ffffffffc0203834:	1d700593          	li	a1,471
ffffffffc0203838:	00002517          	auipc	a0,0x2
ffffffffc020383c:	ce850513          	addi	a0,a0,-792 # ffffffffc0205520 <default_pmm_manager+0x978>
ffffffffc0203840:	c1bfc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc0203844 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0203844:	1141                	addi	sp,sp,-16
ffffffffc0203846:	e022                	sd	s0,0(sp)
ffffffffc0203848:	e406                	sd	ra,8(sp)
ffffffffc020384a:	0000a417          	auipc	s0,0xa
ffffffffc020384e:	c8640413          	addi	s0,s0,-890 # ffffffffc020d4d0 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0203852:	6018                	ld	a4,0(s0)
ffffffffc0203854:	4f1c                	lw	a5,24(a4)
ffffffffc0203856:	2781                	sext.w	a5,a5
ffffffffc0203858:	dff5                	beqz	a5,ffffffffc0203854 <cpu_idle+0x10>
        {
            schedule();
ffffffffc020385a:	0a2000ef          	jal	ra,ffffffffc02038fc <schedule>
ffffffffc020385e:	bfd5                	j	ffffffffc0203852 <cpu_idle+0xe>

ffffffffc0203860 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0203860:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0203864:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0203868:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc020386a:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc020386c:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0203870:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0203874:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0203878:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc020387c:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0203880:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0203884:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0203888:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc020388c:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0203890:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0203894:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0203898:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc020389c:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc020389e:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc02038a0:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc02038a4:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc02038a8:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc02038ac:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc02038b0:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc02038b4:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc02038b8:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc02038bc:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc02038c0:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02038c4:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02038c8:	8082                	ret

ffffffffc02038ca <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02038ca:	411c                	lw	a5,0(a0)
ffffffffc02038cc:	4705                	li	a4,1
ffffffffc02038ce:	37f9                	addiw	a5,a5,-2
ffffffffc02038d0:	00f77563          	bgeu	a4,a5,ffffffffc02038da <wakeup_proc+0x10>
    proc->state = PROC_RUNNABLE;
ffffffffc02038d4:	4789                	li	a5,2
ffffffffc02038d6:	c11c                	sw	a5,0(a0)
ffffffffc02038d8:	8082                	ret
wakeup_proc(struct proc_struct *proc) {
ffffffffc02038da:	1141                	addi	sp,sp,-16
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02038dc:	00002697          	auipc	a3,0x2
ffffffffc02038e0:	d4c68693          	addi	a3,a3,-692 # ffffffffc0205628 <default_pmm_manager+0xa80>
ffffffffc02038e4:	00001617          	auipc	a2,0x1
ffffffffc02038e8:	f1460613          	addi	a2,a2,-236 # ffffffffc02047f8 <commands+0x708>
ffffffffc02038ec:	45a5                	li	a1,9
ffffffffc02038ee:	00002517          	auipc	a0,0x2
ffffffffc02038f2:	d7a50513          	addi	a0,a0,-646 # ffffffffc0205668 <default_pmm_manager+0xac0>
wakeup_proc(struct proc_struct *proc) {
ffffffffc02038f6:	e406                	sd	ra,8(sp)
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02038f8:	b63fc0ef          	jal	ra,ffffffffc020045a <__panic>

ffffffffc02038fc <schedule>:
}

void
schedule(void) {
ffffffffc02038fc:	1141                	addi	sp,sp,-16
ffffffffc02038fe:	e406                	sd	ra,8(sp)
ffffffffc0203900:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203902:	100027f3          	csrr	a5,sstatus
ffffffffc0203906:	8b89                	andi	a5,a5,2
ffffffffc0203908:	4401                	li	s0,0
ffffffffc020390a:	efbd                	bnez	a5,ffffffffc0203988 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc020390c:	0000a897          	auipc	a7,0xa
ffffffffc0203910:	bc48b883          	ld	a7,-1084(a7) # ffffffffc020d4d0 <current>
ffffffffc0203914:	0008ac23          	sw	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0203918:	0000a517          	auipc	a0,0xa
ffffffffc020391c:	bc053503          	ld	a0,-1088(a0) # ffffffffc020d4d8 <idleproc>
ffffffffc0203920:	04a88e63          	beq	a7,a0,ffffffffc020397c <schedule+0x80>
ffffffffc0203924:	0c888693          	addi	a3,a7,200
ffffffffc0203928:	0000a617          	auipc	a2,0xa
ffffffffc020392c:	b3060613          	addi	a2,a2,-1232 # ffffffffc020d458 <proc_list>
        le = last;
ffffffffc0203930:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc0203932:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc0203934:	4809                	li	a6,2
ffffffffc0203936:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc0203938:	00c78863          	beq	a5,a2,ffffffffc0203948 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) {
ffffffffc020393c:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0203940:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc0203944:	03070163          	beq	a4,a6,ffffffffc0203966 <schedule+0x6a>
                    break;
                }
            }
        } while (le != last);
ffffffffc0203948:	fef697e3          	bne	a3,a5,ffffffffc0203936 <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc020394c:	ed89                	bnez	a1,ffffffffc0203966 <schedule+0x6a>
            next = idleproc;
        }
        next->runs ++;
ffffffffc020394e:	451c                	lw	a5,8(a0)
ffffffffc0203950:	2785                	addiw	a5,a5,1
ffffffffc0203952:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc0203954:	00a88463          	beq	a7,a0,ffffffffc020395c <schedule+0x60>
            proc_run(next);
ffffffffc0203958:	941ff0ef          	jal	ra,ffffffffc0203298 <proc_run>
    if (flag) {
ffffffffc020395c:	e819                	bnez	s0,ffffffffc0203972 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc020395e:	60a2                	ld	ra,8(sp)
ffffffffc0203960:	6402                	ld	s0,0(sp)
ffffffffc0203962:	0141                	addi	sp,sp,16
ffffffffc0203964:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0203966:	4198                	lw	a4,0(a1)
ffffffffc0203968:	4789                	li	a5,2
ffffffffc020396a:	fef712e3          	bne	a4,a5,ffffffffc020394e <schedule+0x52>
ffffffffc020396e:	852e                	mv	a0,a1
ffffffffc0203970:	bff9                	j	ffffffffc020394e <schedule+0x52>
}
ffffffffc0203972:	6402                	ld	s0,0(sp)
ffffffffc0203974:	60a2                	ld	ra,8(sp)
ffffffffc0203976:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0203978:	fb3fc06f          	j	ffffffffc020092a <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020397c:	0000a617          	auipc	a2,0xa
ffffffffc0203980:	adc60613          	addi	a2,a2,-1316 # ffffffffc020d458 <proc_list>
ffffffffc0203984:	86b2                	mv	a3,a2
ffffffffc0203986:	b76d                	j	ffffffffc0203930 <schedule+0x34>
        intr_disable();
ffffffffc0203988:	fa9fc0ef          	jal	ra,ffffffffc0200930 <intr_disable>
        return 1;
ffffffffc020398c:	4405                	li	s0,1
ffffffffc020398e:	bfbd                	j	ffffffffc020390c <schedule+0x10>

ffffffffc0203990 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0203990:	9e3707b7          	lui	a5,0x9e370
ffffffffc0203994:	2785                	addiw	a5,a5,1
ffffffffc0203996:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc020399a:	02000793          	li	a5,32
ffffffffc020399e:	9f8d                	subw	a5,a5,a1
}
ffffffffc02039a0:	00f5553b          	srlw	a0,a0,a5
ffffffffc02039a4:	8082                	ret

ffffffffc02039a6 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02039a6:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02039aa:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02039ac:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02039b0:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02039b2:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02039b6:	f022                	sd	s0,32(sp)
ffffffffc02039b8:	ec26                	sd	s1,24(sp)
ffffffffc02039ba:	e84a                	sd	s2,16(sp)
ffffffffc02039bc:	f406                	sd	ra,40(sp)
ffffffffc02039be:	e44e                	sd	s3,8(sp)
ffffffffc02039c0:	84aa                	mv	s1,a0
ffffffffc02039c2:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02039c4:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02039c8:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02039ca:	03067e63          	bgeu	a2,a6,ffffffffc0203a06 <printnum+0x60>
ffffffffc02039ce:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02039d0:	00805763          	blez	s0,ffffffffc02039de <printnum+0x38>
ffffffffc02039d4:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02039d6:	85ca                	mv	a1,s2
ffffffffc02039d8:	854e                	mv	a0,s3
ffffffffc02039da:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02039dc:	fc65                	bnez	s0,ffffffffc02039d4 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02039de:	1a02                	slli	s4,s4,0x20
ffffffffc02039e0:	00002797          	auipc	a5,0x2
ffffffffc02039e4:	ca078793          	addi	a5,a5,-864 # ffffffffc0205680 <default_pmm_manager+0xad8>
ffffffffc02039e8:	020a5a13          	srli	s4,s4,0x20
ffffffffc02039ec:	9a3e                	add	s4,s4,a5
}
ffffffffc02039ee:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02039f0:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02039f4:	70a2                	ld	ra,40(sp)
ffffffffc02039f6:	69a2                	ld	s3,8(sp)
ffffffffc02039f8:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02039fa:	85ca                	mv	a1,s2
ffffffffc02039fc:	87a6                	mv	a5,s1
}
ffffffffc02039fe:	6942                	ld	s2,16(sp)
ffffffffc0203a00:	64e2                	ld	s1,24(sp)
ffffffffc0203a02:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203a04:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203a06:	03065633          	divu	a2,a2,a6
ffffffffc0203a0a:	8722                	mv	a4,s0
ffffffffc0203a0c:	f9bff0ef          	jal	ra,ffffffffc02039a6 <printnum>
ffffffffc0203a10:	b7f9                	j	ffffffffc02039de <printnum+0x38>

ffffffffc0203a12 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0203a12:	7119                	addi	sp,sp,-128
ffffffffc0203a14:	f4a6                	sd	s1,104(sp)
ffffffffc0203a16:	f0ca                	sd	s2,96(sp)
ffffffffc0203a18:	ecce                	sd	s3,88(sp)
ffffffffc0203a1a:	e8d2                	sd	s4,80(sp)
ffffffffc0203a1c:	e4d6                	sd	s5,72(sp)
ffffffffc0203a1e:	e0da                	sd	s6,64(sp)
ffffffffc0203a20:	fc5e                	sd	s7,56(sp)
ffffffffc0203a22:	f06a                	sd	s10,32(sp)
ffffffffc0203a24:	fc86                	sd	ra,120(sp)
ffffffffc0203a26:	f8a2                	sd	s0,112(sp)
ffffffffc0203a28:	f862                	sd	s8,48(sp)
ffffffffc0203a2a:	f466                	sd	s9,40(sp)
ffffffffc0203a2c:	ec6e                	sd	s11,24(sp)
ffffffffc0203a2e:	892a                	mv	s2,a0
ffffffffc0203a30:	84ae                	mv	s1,a1
ffffffffc0203a32:	8d32                	mv	s10,a2
ffffffffc0203a34:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a36:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0203a3a:	5b7d                	li	s6,-1
ffffffffc0203a3c:	00002a97          	auipc	s5,0x2
ffffffffc0203a40:	c70a8a93          	addi	s5,s5,-912 # ffffffffc02056ac <default_pmm_manager+0xb04>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203a44:	00002b97          	auipc	s7,0x2
ffffffffc0203a48:	e44b8b93          	addi	s7,s7,-444 # ffffffffc0205888 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a4c:	000d4503          	lbu	a0,0(s10)
ffffffffc0203a50:	001d0413          	addi	s0,s10,1
ffffffffc0203a54:	01350a63          	beq	a0,s3,ffffffffc0203a68 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0203a58:	c121                	beqz	a0,ffffffffc0203a98 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0203a5a:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a5c:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0203a5e:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203a60:	fff44503          	lbu	a0,-1(s0)
ffffffffc0203a64:	ff351ae3          	bne	a0,s3,ffffffffc0203a58 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203a68:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0203a6c:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0203a70:	4c81                	li	s9,0
ffffffffc0203a72:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0203a74:	5c7d                	li	s8,-1
ffffffffc0203a76:	5dfd                	li	s11,-1
ffffffffc0203a78:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0203a7c:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203a7e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0203a82:	0ff5f593          	zext.b	a1,a1
ffffffffc0203a86:	00140d13          	addi	s10,s0,1
ffffffffc0203a8a:	04b56263          	bltu	a0,a1,ffffffffc0203ace <vprintfmt+0xbc>
ffffffffc0203a8e:	058a                	slli	a1,a1,0x2
ffffffffc0203a90:	95d6                	add	a1,a1,s5
ffffffffc0203a92:	4194                	lw	a3,0(a1)
ffffffffc0203a94:	96d6                	add	a3,a3,s5
ffffffffc0203a96:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0203a98:	70e6                	ld	ra,120(sp)
ffffffffc0203a9a:	7446                	ld	s0,112(sp)
ffffffffc0203a9c:	74a6                	ld	s1,104(sp)
ffffffffc0203a9e:	7906                	ld	s2,96(sp)
ffffffffc0203aa0:	69e6                	ld	s3,88(sp)
ffffffffc0203aa2:	6a46                	ld	s4,80(sp)
ffffffffc0203aa4:	6aa6                	ld	s5,72(sp)
ffffffffc0203aa6:	6b06                	ld	s6,64(sp)
ffffffffc0203aa8:	7be2                	ld	s7,56(sp)
ffffffffc0203aaa:	7c42                	ld	s8,48(sp)
ffffffffc0203aac:	7ca2                	ld	s9,40(sp)
ffffffffc0203aae:	7d02                	ld	s10,32(sp)
ffffffffc0203ab0:	6de2                	ld	s11,24(sp)
ffffffffc0203ab2:	6109                	addi	sp,sp,128
ffffffffc0203ab4:	8082                	ret
            padc = '0';
ffffffffc0203ab6:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0203ab8:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203abc:	846a                	mv	s0,s10
ffffffffc0203abe:	00140d13          	addi	s10,s0,1
ffffffffc0203ac2:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0203ac6:	0ff5f593          	zext.b	a1,a1
ffffffffc0203aca:	fcb572e3          	bgeu	a0,a1,ffffffffc0203a8e <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0203ace:	85a6                	mv	a1,s1
ffffffffc0203ad0:	02500513          	li	a0,37
ffffffffc0203ad4:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0203ad6:	fff44783          	lbu	a5,-1(s0)
ffffffffc0203ada:	8d22                	mv	s10,s0
ffffffffc0203adc:	f73788e3          	beq	a5,s3,ffffffffc0203a4c <vprintfmt+0x3a>
ffffffffc0203ae0:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0203ae4:	1d7d                	addi	s10,s10,-1
ffffffffc0203ae6:	ff379de3          	bne	a5,s3,ffffffffc0203ae0 <vprintfmt+0xce>
ffffffffc0203aea:	b78d                	j	ffffffffc0203a4c <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0203aec:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0203af0:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203af4:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0203af6:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0203afa:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203afe:	02d86463          	bltu	a6,a3,ffffffffc0203b26 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0203b02:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0203b06:	002c169b          	slliw	a3,s8,0x2
ffffffffc0203b0a:	0186873b          	addw	a4,a3,s8
ffffffffc0203b0e:	0017171b          	slliw	a4,a4,0x1
ffffffffc0203b12:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0203b14:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0203b18:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0203b1a:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0203b1e:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203b22:	fed870e3          	bgeu	a6,a3,ffffffffc0203b02 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0203b26:	f40ddce3          	bgez	s11,ffffffffc0203a7e <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0203b2a:	8de2                	mv	s11,s8
ffffffffc0203b2c:	5c7d                	li	s8,-1
ffffffffc0203b2e:	bf81                	j	ffffffffc0203a7e <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0203b30:	fffdc693          	not	a3,s11
ffffffffc0203b34:	96fd                	srai	a3,a3,0x3f
ffffffffc0203b36:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b3a:	00144603          	lbu	a2,1(s0)
ffffffffc0203b3e:	2d81                	sext.w	s11,s11
ffffffffc0203b40:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203b42:	bf35                	j	ffffffffc0203a7e <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0203b44:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b48:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0203b4c:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b4e:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0203b50:	bfd9                	j	ffffffffc0203b26 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0203b52:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203b54:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203b58:	01174463          	blt	a4,a7,ffffffffc0203b60 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0203b5c:	1a088e63          	beqz	a7,ffffffffc0203d18 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0203b60:	000a3603          	ld	a2,0(s4)
ffffffffc0203b64:	46c1                	li	a3,16
ffffffffc0203b66:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0203b68:	2781                	sext.w	a5,a5
ffffffffc0203b6a:	876e                	mv	a4,s11
ffffffffc0203b6c:	85a6                	mv	a1,s1
ffffffffc0203b6e:	854a                	mv	a0,s2
ffffffffc0203b70:	e37ff0ef          	jal	ra,ffffffffc02039a6 <printnum>
            break;
ffffffffc0203b74:	bde1                	j	ffffffffc0203a4c <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0203b76:	000a2503          	lw	a0,0(s4)
ffffffffc0203b7a:	85a6                	mv	a1,s1
ffffffffc0203b7c:	0a21                	addi	s4,s4,8
ffffffffc0203b7e:	9902                	jalr	s2
            break;
ffffffffc0203b80:	b5f1                	j	ffffffffc0203a4c <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0203b82:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203b84:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203b88:	01174463          	blt	a4,a7,ffffffffc0203b90 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0203b8c:	18088163          	beqz	a7,ffffffffc0203d0e <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0203b90:	000a3603          	ld	a2,0(s4)
ffffffffc0203b94:	46a9                	li	a3,10
ffffffffc0203b96:	8a2e                	mv	s4,a1
ffffffffc0203b98:	bfc1                	j	ffffffffc0203b68 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b9a:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0203b9e:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203ba0:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203ba2:	bdf1                	j	ffffffffc0203a7e <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0203ba4:	85a6                	mv	a1,s1
ffffffffc0203ba6:	02500513          	li	a0,37
ffffffffc0203baa:	9902                	jalr	s2
            break;
ffffffffc0203bac:	b545                	j	ffffffffc0203a4c <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bae:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0203bb2:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203bb4:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0203bb6:	b5e1                	j	ffffffffc0203a7e <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0203bb8:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203bba:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203bbe:	01174463          	blt	a4,a7,ffffffffc0203bc6 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0203bc2:	14088163          	beqz	a7,ffffffffc0203d04 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0203bc6:	000a3603          	ld	a2,0(s4)
ffffffffc0203bca:	46a1                	li	a3,8
ffffffffc0203bcc:	8a2e                	mv	s4,a1
ffffffffc0203bce:	bf69                	j	ffffffffc0203b68 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0203bd0:	03000513          	li	a0,48
ffffffffc0203bd4:	85a6                	mv	a1,s1
ffffffffc0203bd6:	e03e                	sd	a5,0(sp)
ffffffffc0203bd8:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0203bda:	85a6                	mv	a1,s1
ffffffffc0203bdc:	07800513          	li	a0,120
ffffffffc0203be0:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203be2:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0203be4:	6782                	ld	a5,0(sp)
ffffffffc0203be6:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203be8:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0203bec:	bfb5                	j	ffffffffc0203b68 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203bee:	000a3403          	ld	s0,0(s4)
ffffffffc0203bf2:	008a0713          	addi	a4,s4,8
ffffffffc0203bf6:	e03a                	sd	a4,0(sp)
ffffffffc0203bf8:	14040263          	beqz	s0,ffffffffc0203d3c <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0203bfc:	0fb05763          	blez	s11,ffffffffc0203cea <vprintfmt+0x2d8>
ffffffffc0203c00:	02d00693          	li	a3,45
ffffffffc0203c04:	0cd79163          	bne	a5,a3,ffffffffc0203cc6 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c08:	00044783          	lbu	a5,0(s0)
ffffffffc0203c0c:	0007851b          	sext.w	a0,a5
ffffffffc0203c10:	cf85                	beqz	a5,ffffffffc0203c48 <vprintfmt+0x236>
ffffffffc0203c12:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203c16:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c1a:	000c4563          	bltz	s8,ffffffffc0203c24 <vprintfmt+0x212>
ffffffffc0203c1e:	3c7d                	addiw	s8,s8,-1
ffffffffc0203c20:	036c0263          	beq	s8,s6,ffffffffc0203c44 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0203c24:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203c26:	0e0c8e63          	beqz	s9,ffffffffc0203d22 <vprintfmt+0x310>
ffffffffc0203c2a:	3781                	addiw	a5,a5,-32
ffffffffc0203c2c:	0ef47b63          	bgeu	s0,a5,ffffffffc0203d22 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0203c30:	03f00513          	li	a0,63
ffffffffc0203c34:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c36:	000a4783          	lbu	a5,0(s4)
ffffffffc0203c3a:	3dfd                	addiw	s11,s11,-1
ffffffffc0203c3c:	0a05                	addi	s4,s4,1
ffffffffc0203c3e:	0007851b          	sext.w	a0,a5
ffffffffc0203c42:	ffe1                	bnez	a5,ffffffffc0203c1a <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0203c44:	01b05963          	blez	s11,ffffffffc0203c56 <vprintfmt+0x244>
ffffffffc0203c48:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0203c4a:	85a6                	mv	a1,s1
ffffffffc0203c4c:	02000513          	li	a0,32
ffffffffc0203c50:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0203c52:	fe0d9be3          	bnez	s11,ffffffffc0203c48 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203c56:	6a02                	ld	s4,0(sp)
ffffffffc0203c58:	bbd5                	j	ffffffffc0203a4c <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0203c5a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203c5c:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0203c60:	01174463          	blt	a4,a7,ffffffffc0203c68 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0203c64:	08088d63          	beqz	a7,ffffffffc0203cfe <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0203c68:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0203c6c:	0a044d63          	bltz	s0,ffffffffc0203d26 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0203c70:	8622                	mv	a2,s0
ffffffffc0203c72:	8a66                	mv	s4,s9
ffffffffc0203c74:	46a9                	li	a3,10
ffffffffc0203c76:	bdcd                	j	ffffffffc0203b68 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0203c78:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203c7c:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0203c7e:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0203c80:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0203c84:	8fb5                	xor	a5,a5,a3
ffffffffc0203c86:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203c8a:	02d74163          	blt	a4,a3,ffffffffc0203cac <vprintfmt+0x29a>
ffffffffc0203c8e:	00369793          	slli	a5,a3,0x3
ffffffffc0203c92:	97de                	add	a5,a5,s7
ffffffffc0203c94:	639c                	ld	a5,0(a5)
ffffffffc0203c96:	cb99                	beqz	a5,ffffffffc0203cac <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0203c98:	86be                	mv	a3,a5
ffffffffc0203c9a:	00000617          	auipc	a2,0x0
ffffffffc0203c9e:	21660613          	addi	a2,a2,534 # ffffffffc0203eb0 <etext+0x2c>
ffffffffc0203ca2:	85a6                	mv	a1,s1
ffffffffc0203ca4:	854a                	mv	a0,s2
ffffffffc0203ca6:	0ce000ef          	jal	ra,ffffffffc0203d74 <printfmt>
ffffffffc0203caa:	b34d                	j	ffffffffc0203a4c <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0203cac:	00002617          	auipc	a2,0x2
ffffffffc0203cb0:	9f460613          	addi	a2,a2,-1548 # ffffffffc02056a0 <default_pmm_manager+0xaf8>
ffffffffc0203cb4:	85a6                	mv	a1,s1
ffffffffc0203cb6:	854a                	mv	a0,s2
ffffffffc0203cb8:	0bc000ef          	jal	ra,ffffffffc0203d74 <printfmt>
ffffffffc0203cbc:	bb41                	j	ffffffffc0203a4c <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0203cbe:	00002417          	auipc	s0,0x2
ffffffffc0203cc2:	9da40413          	addi	s0,s0,-1574 # ffffffffc0205698 <default_pmm_manager+0xaf0>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203cc6:	85e2                	mv	a1,s8
ffffffffc0203cc8:	8522                	mv	a0,s0
ffffffffc0203cca:	e43e                	sd	a5,8(sp)
ffffffffc0203ccc:	0e2000ef          	jal	ra,ffffffffc0203dae <strnlen>
ffffffffc0203cd0:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0203cd4:	01b05b63          	blez	s11,ffffffffc0203cea <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0203cd8:	67a2                	ld	a5,8(sp)
ffffffffc0203cda:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203cde:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0203ce0:	85a6                	mv	a1,s1
ffffffffc0203ce2:	8552                	mv	a0,s4
ffffffffc0203ce4:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203ce6:	fe0d9ce3          	bnez	s11,ffffffffc0203cde <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203cea:	00044783          	lbu	a5,0(s0)
ffffffffc0203cee:	00140a13          	addi	s4,s0,1
ffffffffc0203cf2:	0007851b          	sext.w	a0,a5
ffffffffc0203cf6:	d3a5                	beqz	a5,ffffffffc0203c56 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203cf8:	05e00413          	li	s0,94
ffffffffc0203cfc:	bf39                	j	ffffffffc0203c1a <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0203cfe:	000a2403          	lw	s0,0(s4)
ffffffffc0203d02:	b7ad                	j	ffffffffc0203c6c <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0203d04:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d08:	46a1                	li	a3,8
ffffffffc0203d0a:	8a2e                	mv	s4,a1
ffffffffc0203d0c:	bdb1                	j	ffffffffc0203b68 <vprintfmt+0x156>
ffffffffc0203d0e:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d12:	46a9                	li	a3,10
ffffffffc0203d14:	8a2e                	mv	s4,a1
ffffffffc0203d16:	bd89                	j	ffffffffc0203b68 <vprintfmt+0x156>
ffffffffc0203d18:	000a6603          	lwu	a2,0(s4)
ffffffffc0203d1c:	46c1                	li	a3,16
ffffffffc0203d1e:	8a2e                	mv	s4,a1
ffffffffc0203d20:	b5a1                	j	ffffffffc0203b68 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0203d22:	9902                	jalr	s2
ffffffffc0203d24:	bf09                	j	ffffffffc0203c36 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0203d26:	85a6                	mv	a1,s1
ffffffffc0203d28:	02d00513          	li	a0,45
ffffffffc0203d2c:	e03e                	sd	a5,0(sp)
ffffffffc0203d2e:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0203d30:	6782                	ld	a5,0(sp)
ffffffffc0203d32:	8a66                	mv	s4,s9
ffffffffc0203d34:	40800633          	neg	a2,s0
ffffffffc0203d38:	46a9                	li	a3,10
ffffffffc0203d3a:	b53d                	j	ffffffffc0203b68 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0203d3c:	03b05163          	blez	s11,ffffffffc0203d5e <vprintfmt+0x34c>
ffffffffc0203d40:	02d00693          	li	a3,45
ffffffffc0203d44:	f6d79de3          	bne	a5,a3,ffffffffc0203cbe <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0203d48:	00002417          	auipc	s0,0x2
ffffffffc0203d4c:	95040413          	addi	s0,s0,-1712 # ffffffffc0205698 <default_pmm_manager+0xaf0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203d50:	02800793          	li	a5,40
ffffffffc0203d54:	02800513          	li	a0,40
ffffffffc0203d58:	00140a13          	addi	s4,s0,1
ffffffffc0203d5c:	bd6d                	j	ffffffffc0203c16 <vprintfmt+0x204>
ffffffffc0203d5e:	00002a17          	auipc	s4,0x2
ffffffffc0203d62:	93ba0a13          	addi	s4,s4,-1733 # ffffffffc0205699 <default_pmm_manager+0xaf1>
ffffffffc0203d66:	02800513          	li	a0,40
ffffffffc0203d6a:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203d6e:	05e00413          	li	s0,94
ffffffffc0203d72:	b565                	j	ffffffffc0203c1a <vprintfmt+0x208>

ffffffffc0203d74 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203d74:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0203d76:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203d7a:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203d7c:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203d7e:	ec06                	sd	ra,24(sp)
ffffffffc0203d80:	f83a                	sd	a4,48(sp)
ffffffffc0203d82:	fc3e                	sd	a5,56(sp)
ffffffffc0203d84:	e0c2                	sd	a6,64(sp)
ffffffffc0203d86:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0203d88:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203d8a:	c89ff0ef          	jal	ra,ffffffffc0203a12 <vprintfmt>
}
ffffffffc0203d8e:	60e2                	ld	ra,24(sp)
ffffffffc0203d90:	6161                	addi	sp,sp,80
ffffffffc0203d92:	8082                	ret

ffffffffc0203d94 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203d94:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0203d98:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0203d9a:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0203d9c:	cb81                	beqz	a5,ffffffffc0203dac <strlen+0x18>
        cnt ++;
ffffffffc0203d9e:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0203da0:	00a707b3          	add	a5,a4,a0
ffffffffc0203da4:	0007c783          	lbu	a5,0(a5)
ffffffffc0203da8:	fbfd                	bnez	a5,ffffffffc0203d9e <strlen+0xa>
ffffffffc0203daa:	8082                	ret
    }
    return cnt;
}
ffffffffc0203dac:	8082                	ret

ffffffffc0203dae <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0203dae:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203db0:	e589                	bnez	a1,ffffffffc0203dba <strnlen+0xc>
ffffffffc0203db2:	a811                	j	ffffffffc0203dc6 <strnlen+0x18>
        cnt ++;
ffffffffc0203db4:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203db6:	00f58863          	beq	a1,a5,ffffffffc0203dc6 <strnlen+0x18>
ffffffffc0203dba:	00f50733          	add	a4,a0,a5
ffffffffc0203dbe:	00074703          	lbu	a4,0(a4)
ffffffffc0203dc2:	fb6d                	bnez	a4,ffffffffc0203db4 <strnlen+0x6>
ffffffffc0203dc4:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0203dc6:	852e                	mv	a0,a1
ffffffffc0203dc8:	8082                	ret

ffffffffc0203dca <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0203dca:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0203dcc:	0005c703          	lbu	a4,0(a1)
ffffffffc0203dd0:	0785                	addi	a5,a5,1
ffffffffc0203dd2:	0585                	addi	a1,a1,1
ffffffffc0203dd4:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0203dd8:	fb75                	bnez	a4,ffffffffc0203dcc <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0203dda:	8082                	ret

ffffffffc0203ddc <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203ddc:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203de0:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203de4:	cb89                	beqz	a5,ffffffffc0203df6 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0203de6:	0505                	addi	a0,a0,1
ffffffffc0203de8:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203dea:	fee789e3          	beq	a5,a4,ffffffffc0203ddc <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203dee:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203df2:	9d19                	subw	a0,a0,a4
ffffffffc0203df4:	8082                	ret
ffffffffc0203df6:	4501                	li	a0,0
ffffffffc0203df8:	bfed                	j	ffffffffc0203df2 <strcmp+0x16>

ffffffffc0203dfa <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203dfa:	c20d                	beqz	a2,ffffffffc0203e1c <strncmp+0x22>
ffffffffc0203dfc:	962e                	add	a2,a2,a1
ffffffffc0203dfe:	a031                	j	ffffffffc0203e0a <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0203e00:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e02:	00e79a63          	bne	a5,a4,ffffffffc0203e16 <strncmp+0x1c>
ffffffffc0203e06:	00b60b63          	beq	a2,a1,ffffffffc0203e1c <strncmp+0x22>
ffffffffc0203e0a:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0203e0e:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203e10:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0203e14:	f7f5                	bnez	a5,ffffffffc0203e00 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e16:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0203e1a:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e1c:	4501                	li	a0,0
ffffffffc0203e1e:	8082                	ret

ffffffffc0203e20 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0203e20:	00054783          	lbu	a5,0(a0)
ffffffffc0203e24:	c799                	beqz	a5,ffffffffc0203e32 <strchr+0x12>
        if (*s == c) {
ffffffffc0203e26:	00f58763          	beq	a1,a5,ffffffffc0203e34 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0203e2a:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0203e2e:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0203e30:	fbfd                	bnez	a5,ffffffffc0203e26 <strchr+0x6>
    }
    return NULL;
ffffffffc0203e32:	4501                	li	a0,0
}
ffffffffc0203e34:	8082                	ret

ffffffffc0203e36 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0203e36:	ca01                	beqz	a2,ffffffffc0203e46 <memset+0x10>
ffffffffc0203e38:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0203e3a:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0203e3c:	0785                	addi	a5,a5,1
ffffffffc0203e3e:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0203e42:	fec79de3          	bne	a5,a2,ffffffffc0203e3c <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0203e46:	8082                	ret

ffffffffc0203e48 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0203e48:	ca19                	beqz	a2,ffffffffc0203e5e <memcpy+0x16>
ffffffffc0203e4a:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0203e4c:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0203e4e:	0005c703          	lbu	a4,0(a1)
ffffffffc0203e52:	0585                	addi	a1,a1,1
ffffffffc0203e54:	0785                	addi	a5,a5,1
ffffffffc0203e56:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0203e5a:	fec59ae3          	bne	a1,a2,ffffffffc0203e4e <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0203e5e:	8082                	ret

ffffffffc0203e60 <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0203e60:	c205                	beqz	a2,ffffffffc0203e80 <memcmp+0x20>
ffffffffc0203e62:	962e                	add	a2,a2,a1
ffffffffc0203e64:	a019                	j	ffffffffc0203e6a <memcmp+0xa>
ffffffffc0203e66:	00c58d63          	beq	a1,a2,ffffffffc0203e80 <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc0203e6a:	00054783          	lbu	a5,0(a0)
ffffffffc0203e6e:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0203e72:	0505                	addi	a0,a0,1
ffffffffc0203e74:	0585                	addi	a1,a1,1
        if (*s1 != *s2) {
ffffffffc0203e76:	fee788e3          	beq	a5,a4,ffffffffc0203e66 <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203e7a:	40e7853b          	subw	a0,a5,a4
ffffffffc0203e7e:	8082                	ret
    }
    return 0;
ffffffffc0203e80:	4501                	li	a0,0
}
ffffffffc0203e82:	8082                	ret
