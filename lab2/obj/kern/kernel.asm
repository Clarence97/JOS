
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 79 11 f0       	mov    $0xf0117970,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 73 11 f0       	push   $0xf0117300
f0100058:	e8 4f 31 00 00       	call   f01031ac <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 40 36 10 f0       	push   $0xf0103640
f010006f:	e8 8f 26 00 00       	call   f0102703 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 b4 0f 00 00       	call   f010102d <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 40 07 00 00       	call   f01007c6 <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 60 79 11 f0 00 	cmpl   $0x0,0xf0117960
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 60 79 11 f0    	mov    %esi,0xf0117960

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 5b 36 10 f0       	push   $0xf010365b
f01000b5:	e8 49 26 00 00       	call   f0102703 <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 19 26 00 00       	call   f01026dd <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 0d 46 10 f0 	movl   $0xf010460d,(%esp)
f01000cb:	e8 33 26 00 00       	call   f0102703 <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 e9 06 00 00       	call   f01007c6 <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 73 36 10 f0       	push   $0xf0103673
f01000f7:	e8 07 26 00 00       	call   f0102703 <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 d5 25 00 00       	call   f01026dd <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 0d 46 10 f0 	movl   $0xf010460d,(%esp)
f010010f:	e8 ef 25 00 00       	call   f0102703 <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 75 11 f0    	mov    0xf0117524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 75 11 f0    	mov    %edx,0xf0117524
f0100159:	88 81 20 73 11 f0    	mov    %al,-0xfee8ce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f8 00 00 00    	je     f0100284 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f010018c:	a8 20                	test   $0x20,%al
f010018e:	0f 85 f6 00 00 00    	jne    f010028a <kbd_proc_data+0x10c>
f0100194:	ba 60 00 00 00       	mov    $0x60,%edx
f0100199:	ec                   	in     (%dx),%al
f010019a:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010019c:	3c e0                	cmp    $0xe0,%al
f010019e:	75 0d                	jne    f01001ad <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001a0:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
		return 0;
f01001a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01001ac:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ad:	55                   	push   %ebp
f01001ae:	89 e5                	mov    %esp,%ebp
f01001b0:	53                   	push   %ebx
f01001b1:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001b4:	84 c0                	test   %al,%al
f01001b6:	79 36                	jns    f01001ee <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b8:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001be:	89 cb                	mov    %ecx,%ebx
f01001c0:	83 e3 40             	and    $0x40,%ebx
f01001c3:	83 e0 7f             	and    $0x7f,%eax
f01001c6:	85 db                	test   %ebx,%ebx
f01001c8:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001cb:	0f b6 d2             	movzbl %dl,%edx
f01001ce:	0f b6 82 e0 37 10 f0 	movzbl -0xfefc820(%edx),%eax
f01001d5:	83 c8 40             	or     $0x40,%eax
f01001d8:	0f b6 c0             	movzbl %al,%eax
f01001db:	f7 d0                	not    %eax
f01001dd:	21 c8                	and    %ecx,%eax
f01001df:	a3 00 73 11 f0       	mov    %eax,0xf0117300
		return 0;
f01001e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e9:	e9 a4 00 00 00       	jmp    f0100292 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f01001ee:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001f4:	f6 c1 40             	test   $0x40,%cl
f01001f7:	74 0e                	je     f0100207 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f9:	83 c8 80             	or     $0xffffff80,%eax
f01001fc:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001fe:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100201:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
	}

	shift |= shiftcode[data];
f0100207:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010020a:	0f b6 82 e0 37 10 f0 	movzbl -0xfefc820(%edx),%eax
f0100211:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
f0100217:	0f b6 8a e0 36 10 f0 	movzbl -0xfefc920(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 73 11 f0       	mov    %eax,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d c0 36 10 f0 	mov    -0xfefc940(,%ecx,4),%ecx
f0100231:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100235:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100238:	a8 08                	test   $0x8,%al
f010023a:	74 1b                	je     f0100257 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f010023c:	89 da                	mov    %ebx,%edx
f010023e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100241:	83 f9 19             	cmp    $0x19,%ecx
f0100244:	77 05                	ja     f010024b <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f0100246:	83 eb 20             	sub    $0x20,%ebx
f0100249:	eb 0c                	jmp    f0100257 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f010024b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010024e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100251:	83 fa 19             	cmp    $0x19,%edx
f0100254:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100257:	f7 d0                	not    %eax
f0100259:	a8 06                	test   $0x6,%al
f010025b:	75 33                	jne    f0100290 <kbd_proc_data+0x112>
f010025d:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100263:	75 2b                	jne    f0100290 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f0100265:	83 ec 0c             	sub    $0xc,%esp
f0100268:	68 8d 36 10 f0       	push   $0xf010368d
f010026d:	e8 91 24 00 00       	call   f0102703 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100272:	ba 92 00 00 00       	mov    $0x92,%edx
f0100277:	b8 03 00 00 00       	mov    $0x3,%eax
f010027c:	ee                   	out    %al,(%dx)
f010027d:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100280:	89 d8                	mov    %ebx,%eax
f0100282:	eb 0e                	jmp    f0100292 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100284:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100289:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010028a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010028f:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100290:	89 d8                	mov    %ebx,%eax
}
f0100292:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100295:	c9                   	leave  
f0100296:	c3                   	ret    

f0100297 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100297:	55                   	push   %ebp
f0100298:	89 e5                	mov    %esp,%ebp
f010029a:	57                   	push   %edi
f010029b:	56                   	push   %esi
f010029c:	53                   	push   %ebx
f010029d:	83 ec 1c             	sub    $0x1c,%esp
f01002a0:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a2:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002a7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002ac:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b1:	eb 09                	jmp    f01002bc <cons_putc+0x25>
f01002b3:	89 ca                	mov    %ecx,%edx
f01002b5:	ec                   	in     (%dx),%al
f01002b6:	ec                   	in     (%dx),%al
f01002b7:	ec                   	in     (%dx),%al
f01002b8:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002b9:	83 c3 01             	add    $0x1,%ebx
f01002bc:	89 f2                	mov    %esi,%edx
f01002be:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002bf:	a8 20                	test   $0x20,%al
f01002c1:	75 08                	jne    f01002cb <cons_putc+0x34>
f01002c3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002c9:	7e e8                	jle    f01002b3 <cons_putc+0x1c>
f01002cb:	89 f8                	mov    %edi,%eax
f01002cd:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002d5:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002d6:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002db:	be 79 03 00 00       	mov    $0x379,%esi
f01002e0:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002e5:	eb 09                	jmp    f01002f0 <cons_putc+0x59>
f01002e7:	89 ca                	mov    %ecx,%edx
f01002e9:	ec                   	in     (%dx),%al
f01002ea:	ec                   	in     (%dx),%al
f01002eb:	ec                   	in     (%dx),%al
f01002ec:	ec                   	in     (%dx),%al
f01002ed:	83 c3 01             	add    $0x1,%ebx
f01002f0:	89 f2                	mov    %esi,%edx
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002f9:	7f 04                	jg     f01002ff <cons_putc+0x68>
f01002fb:	84 c0                	test   %al,%al
f01002fd:	79 e8                	jns    f01002e7 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ff:	ba 78 03 00 00       	mov    $0x378,%edx
f0100304:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100308:	ee                   	out    %al,(%dx)
f0100309:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010030e:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100313:	ee                   	out    %al,(%dx)
f0100314:	b8 08 00 00 00       	mov    $0x8,%eax
f0100319:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010031a:	89 fa                	mov    %edi,%edx
f010031c:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100322:	89 f8                	mov    %edi,%eax
f0100324:	80 cc 07             	or     $0x7,%ah
f0100327:	85 d2                	test   %edx,%edx
f0100329:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010032c:	89 f8                	mov    %edi,%eax
f010032e:	0f b6 c0             	movzbl %al,%eax
f0100331:	83 f8 09             	cmp    $0x9,%eax
f0100334:	74 74                	je     f01003aa <cons_putc+0x113>
f0100336:	83 f8 09             	cmp    $0x9,%eax
f0100339:	7f 0a                	jg     f0100345 <cons_putc+0xae>
f010033b:	83 f8 08             	cmp    $0x8,%eax
f010033e:	74 14                	je     f0100354 <cons_putc+0xbd>
f0100340:	e9 99 00 00 00       	jmp    f01003de <cons_putc+0x147>
f0100345:	83 f8 0a             	cmp    $0xa,%eax
f0100348:	74 3a                	je     f0100384 <cons_putc+0xed>
f010034a:	83 f8 0d             	cmp    $0xd,%eax
f010034d:	74 3d                	je     f010038c <cons_putc+0xf5>
f010034f:	e9 8a 00 00 00       	jmp    f01003de <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100354:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f010035b:	66 85 c0             	test   %ax,%ax
f010035e:	0f 84 e6 00 00 00    	je     f010044a <cons_putc+0x1b3>
			crt_pos--;
f0100364:	83 e8 01             	sub    $0x1,%eax
f0100367:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010036d:	0f b7 c0             	movzwl %ax,%eax
f0100370:	66 81 e7 00 ff       	and    $0xff00,%di
f0100375:	83 cf 20             	or     $0x20,%edi
f0100378:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f010037e:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100382:	eb 78                	jmp    f01003fc <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100384:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f010038b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038c:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100393:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100399:	c1 e8 16             	shr    $0x16,%eax
f010039c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010039f:	c1 e0 04             	shl    $0x4,%eax
f01003a2:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
f01003a8:	eb 52                	jmp    f01003fc <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003aa:	b8 20 00 00 00       	mov    $0x20,%eax
f01003af:	e8 e3 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003b4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b9:	e8 d9 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003be:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c3:	e8 cf fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003c8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003cd:	e8 c5 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d7:	e8 bb fe ff ff       	call   f0100297 <cons_putc>
f01003dc:	eb 1e                	jmp    f01003fc <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003de:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003e5:	8d 50 01             	lea    0x1(%eax),%edx
f01003e8:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
f01003ef:	0f b7 c0             	movzwl %ax,%eax
f01003f2:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f01003f8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003fc:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f0100403:	cf 07 
f0100405:	76 43                	jbe    f010044a <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100407:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f010040c:	83 ec 04             	sub    $0x4,%esp
f010040f:	68 00 0f 00 00       	push   $0xf00
f0100414:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041a:	52                   	push   %edx
f010041b:	50                   	push   %eax
f010041c:	e8 d8 2d 00 00       	call   f01031f9 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100421:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100427:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010042d:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100433:	83 c4 10             	add    $0x10,%esp
f0100436:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010043b:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010043e:	39 d0                	cmp    %edx,%eax
f0100440:	75 f4                	jne    f0100436 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100442:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f0100449:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044a:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100450:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100455:	89 ca                	mov    %ecx,%edx
f0100457:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100458:	0f b7 1d 28 75 11 f0 	movzwl 0xf0117528,%ebx
f010045f:	8d 71 01             	lea    0x1(%ecx),%esi
f0100462:	89 d8                	mov    %ebx,%eax
f0100464:	66 c1 e8 08          	shr    $0x8,%ax
f0100468:	89 f2                	mov    %esi,%edx
f010046a:	ee                   	out    %al,(%dx)
f010046b:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100470:	89 ca                	mov    %ecx,%edx
f0100472:	ee                   	out    %al,(%dx)
f0100473:	89 d8                	mov    %ebx,%eax
f0100475:	89 f2                	mov    %esi,%edx
f0100477:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100478:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010047b:	5b                   	pop    %ebx
f010047c:	5e                   	pop    %esi
f010047d:	5f                   	pop    %edi
f010047e:	5d                   	pop    %ebp
f010047f:	c3                   	ret    

f0100480 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100480:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
f0100487:	74 11                	je     f010049a <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100489:	55                   	push   %ebp
f010048a:	89 e5                	mov    %esp,%ebp
f010048c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010048f:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100494:	e8 a2 fc ff ff       	call   f010013b <cons_intr>
}
f0100499:	c9                   	leave  
f010049a:	f3 c3                	repz ret 

f010049c <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010049c:	55                   	push   %ebp
f010049d:	89 e5                	mov    %esp,%ebp
f010049f:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a2:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f01004a7:	e8 8f fc ff ff       	call   f010013b <cons_intr>
}
f01004ac:	c9                   	leave  
f01004ad:	c3                   	ret    

f01004ae <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004ae:	55                   	push   %ebp
f01004af:	89 e5                	mov    %esp,%ebp
f01004b1:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004b4:	e8 c7 ff ff ff       	call   f0100480 <serial_intr>
	kbd_intr();
f01004b9:	e8 de ff ff ff       	call   f010049c <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004be:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01004c3:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01004c9:	74 26                	je     f01004f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004cb:	8d 50 01             	lea    0x1(%eax),%edx
f01004ce:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f01004d4:	0f b6 88 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004db:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004dd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004e3:	75 11                	jne    f01004f6 <cons_getc+0x48>
			cons.rpos = 0;
f01004e5:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
f01004ec:	00 00 00 
f01004ef:	eb 05                	jmp    f01004f6 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004f6:	c9                   	leave  
f01004f7:	c3                   	ret    

f01004f8 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004f8:	55                   	push   %ebp
f01004f9:	89 e5                	mov    %esp,%ebp
f01004fb:	57                   	push   %edi
f01004fc:	56                   	push   %esi
f01004fd:	53                   	push   %ebx
f01004fe:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100501:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100508:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010050f:	5a a5 
	if (*cp != 0xA55A) {
f0100511:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100518:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010051c:	74 11                	je     f010052f <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010051e:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
f0100525:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100528:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010052d:	eb 16                	jmp    f0100545 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010052f:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100536:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
f010053d:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100540:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100545:	8b 3d 30 75 11 f0    	mov    0xf0117530,%edi
f010054b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100550:	89 fa                	mov    %edi,%edx
f0100552:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100553:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100556:	89 da                	mov    %ebx,%edx
f0100558:	ec                   	in     (%dx),%al
f0100559:	0f b6 c8             	movzbl %al,%ecx
f010055c:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010055f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100564:	89 fa                	mov    %edi,%edx
f0100566:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100567:	89 da                	mov    %ebx,%edx
f0100569:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010056a:	89 35 2c 75 11 f0    	mov    %esi,0xf011752c
	crt_pos = pos;
f0100570:	0f b6 c0             	movzbl %al,%eax
f0100573:	09 c8                	or     %ecx,%eax
f0100575:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010057b:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100580:	b8 00 00 00 00       	mov    $0x0,%eax
f0100585:	89 f2                	mov    %esi,%edx
f0100587:	ee                   	out    %al,(%dx)
f0100588:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010058d:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100592:	ee                   	out    %al,(%dx)
f0100593:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100598:	b8 0c 00 00 00       	mov    $0xc,%eax
f010059d:	89 da                	mov    %ebx,%edx
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005aa:	ee                   	out    %al,(%dx)
f01005ab:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b0:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b5:	ee                   	out    %al,(%dx)
f01005b6:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c0:	ee                   	out    %al,(%dx)
f01005c1:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01005cb:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cc:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d4:	3c ff                	cmp    $0xff,%al
f01005d6:	0f 95 05 34 75 11 f0 	setne  0xf0117534
f01005dd:	89 f2                	mov    %esi,%edx
f01005df:	ec                   	in     (%dx),%al
f01005e0:	89 da                	mov    %ebx,%edx
f01005e2:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e3:	80 f9 ff             	cmp    $0xff,%cl
f01005e6:	75 10                	jne    f01005f8 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005e8:	83 ec 0c             	sub    $0xc,%esp
f01005eb:	68 99 36 10 f0       	push   $0xf0103699
f01005f0:	e8 0e 21 00 00       	call   f0102703 <cprintf>
f01005f5:	83 c4 10             	add    $0x10,%esp
}
f01005f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005fb:	5b                   	pop    %ebx
f01005fc:	5e                   	pop    %esi
f01005fd:	5f                   	pop    %edi
f01005fe:	5d                   	pop    %ebp
f01005ff:	c3                   	ret    

f0100600 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100600:	55                   	push   %ebp
f0100601:	89 e5                	mov    %esp,%ebp
f0100603:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100606:	8b 45 08             	mov    0x8(%ebp),%eax
f0100609:	e8 89 fc ff ff       	call   f0100297 <cons_putc>
}
f010060e:	c9                   	leave  
f010060f:	c3                   	ret    

f0100610 <getchar>:

int
getchar(void)
{
f0100610:	55                   	push   %ebp
f0100611:	89 e5                	mov    %esp,%ebp
f0100613:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100616:	e8 93 fe ff ff       	call   f01004ae <cons_getc>
f010061b:	85 c0                	test   %eax,%eax
f010061d:	74 f7                	je     f0100616 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010061f:	c9                   	leave  
f0100620:	c3                   	ret    

f0100621 <iscons>:

int
iscons(int fdnum)
{
f0100621:	55                   	push   %ebp
f0100622:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100624:	b8 01 00 00 00       	mov    $0x1,%eax
f0100629:	5d                   	pop    %ebp
f010062a:	c3                   	ret    

f010062b <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010062b:	55                   	push   %ebp
f010062c:	89 e5                	mov    %esp,%ebp
f010062e:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100631:	68 e0 38 10 f0       	push   $0xf01038e0
f0100636:	68 fe 38 10 f0       	push   $0xf01038fe
f010063b:	68 03 39 10 f0       	push   $0xf0103903
f0100640:	e8 be 20 00 00       	call   f0102703 <cprintf>
f0100645:	83 c4 0c             	add    $0xc,%esp
f0100648:	68 b4 39 10 f0       	push   $0xf01039b4
f010064d:	68 0c 39 10 f0       	push   $0xf010390c
f0100652:	68 03 39 10 f0       	push   $0xf0103903
f0100657:	e8 a7 20 00 00       	call   f0102703 <cprintf>
f010065c:	83 c4 0c             	add    $0xc,%esp
f010065f:	68 dc 39 10 f0       	push   $0xf01039dc
f0100664:	68 15 39 10 f0       	push   $0xf0103915
f0100669:	68 03 39 10 f0       	push   $0xf0103903
f010066e:	e8 90 20 00 00       	call   f0102703 <cprintf>
	return 0;
}
f0100673:	b8 00 00 00 00       	mov    $0x0,%eax
f0100678:	c9                   	leave  
f0100679:	c3                   	ret    

f010067a <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010067a:	55                   	push   %ebp
f010067b:	89 e5                	mov    %esp,%ebp
f010067d:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100680:	68 1f 39 10 f0       	push   $0xf010391f
f0100685:	e8 79 20 00 00       	call   f0102703 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010068a:	83 c4 08             	add    $0x8,%esp
f010068d:	68 0c 00 10 00       	push   $0x10000c
f0100692:	68 fc 39 10 f0       	push   $0xf01039fc
f0100697:	e8 67 20 00 00       	call   f0102703 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010069c:	83 c4 0c             	add    $0xc,%esp
f010069f:	68 0c 00 10 00       	push   $0x10000c
f01006a4:	68 0c 00 10 f0       	push   $0xf010000c
f01006a9:	68 24 3a 10 f0       	push   $0xf0103a24
f01006ae:	e8 50 20 00 00       	call   f0102703 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 31 36 10 00       	push   $0x103631
f01006bb:	68 31 36 10 f0       	push   $0xf0103631
f01006c0:	68 48 3a 10 f0       	push   $0xf0103a48
f01006c5:	e8 39 20 00 00       	call   f0102703 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 00 73 11 00       	push   $0x117300
f01006d2:	68 00 73 11 f0       	push   $0xf0117300
f01006d7:	68 6c 3a 10 f0       	push   $0xf0103a6c
f01006dc:	e8 22 20 00 00       	call   f0102703 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006e1:	83 c4 0c             	add    $0xc,%esp
f01006e4:	68 70 79 11 00       	push   $0x117970
f01006e9:	68 70 79 11 f0       	push   $0xf0117970
f01006ee:	68 90 3a 10 f0       	push   $0xf0103a90
f01006f3:	e8 0b 20 00 00       	call   f0102703 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006f8:	b8 6f 7d 11 f0       	mov    $0xf0117d6f,%eax
f01006fd:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100702:	83 c4 08             	add    $0x8,%esp
f0100705:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010070a:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100710:	85 c0                	test   %eax,%eax
f0100712:	0f 48 c2             	cmovs  %edx,%eax
f0100715:	c1 f8 0a             	sar    $0xa,%eax
f0100718:	50                   	push   %eax
f0100719:	68 b4 3a 10 f0       	push   $0xf0103ab4
f010071e:	e8 e0 1f 00 00       	call   f0102703 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100723:	b8 00 00 00 00       	mov    $0x0,%eax
f0100728:	c9                   	leave  
f0100729:	c3                   	ret    

f010072a <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010072a:	55                   	push   %ebp
f010072b:	89 e5                	mov    %esp,%ebp
f010072d:	57                   	push   %edi
f010072e:	56                   	push   %esi
f010072f:	53                   	push   %ebx
f0100730:	83 ec 38             	sub    $0x38,%esp
	// Your code here.
	cprintf("Stack backtrace:\n");
f0100733:	68 38 39 10 f0       	push   $0xf0103938
f0100738:	e8 c6 1f 00 00       	call   f0102703 <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f010073d:	89 eb                	mov    %ebp,%ebx
	unsigned int* ebp = (unsigned int*)read_ebp();
	while(ebp != 0){
f010073f:	83 c4 10             	add    $0x10,%esp
		unsigned int eip = *(ebp + 1);
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
f0100742:	8d 7d d0             	lea    -0x30(%ebp),%edi
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	cprintf("Stack backtrace:\n");
	unsigned int* ebp = (unsigned int*)read_ebp();
	while(ebp != 0){
f0100745:	eb 6e                	jmp    f01007b5 <mon_backtrace+0x8b>
		unsigned int eip = *(ebp + 1);
f0100747:	8b 73 04             	mov    0x4(%ebx),%esi
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
f010074a:	83 ec 08             	sub    $0x8,%esp
f010074d:	57                   	push   %edi
f010074e:	56                   	push   %esi
f010074f:	e8 b9 20 00 00       	call   f010280d <debuginfo_eip>
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, eip, \
f0100754:	ff 73 18             	pushl  0x18(%ebx)
f0100757:	ff 73 14             	pushl  0x14(%ebx)
f010075a:	ff 73 10             	pushl  0x10(%ebx)
f010075d:	ff 73 0c             	pushl  0xc(%ebx)
f0100760:	ff 73 08             	pushl  0x8(%ebx)
f0100763:	56                   	push   %esi
f0100764:	53                   	push   %ebx
f0100765:	68 e0 3a 10 f0       	push   $0xf0103ae0
f010076a:	e8 94 1f 00 00       	call   f0102703 <cprintf>
			*(ebp + 2), *(ebp + 3), *(ebp + 4), *(ebp + 5), *(ebp + 6));
		cprintf("         ");
f010076f:	83 c4 24             	add    $0x24,%esp
f0100772:	68 4a 39 10 f0       	push   $0xf010394a
f0100777:	e8 87 1f 00 00       	call   f0102703 <cprintf>
		cprintf("%s:", info.eip_file);
f010077c:	83 c4 08             	add    $0x8,%esp
f010077f:	ff 75 d0             	pushl  -0x30(%ebp)
f0100782:	68 54 39 10 f0       	push   $0xf0103954
f0100787:	e8 77 1f 00 00       	call   f0102703 <cprintf>
		cprintf("%u: ", info.eip_line);
f010078c:	83 c4 08             	add    $0x8,%esp
f010078f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100792:	68 58 39 10 f0       	push   $0xf0103958
f0100797:	e8 67 1f 00 00       	call   f0102703 <cprintf>
		cprintf("%.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
f010079c:	2b 75 e0             	sub    -0x20(%ebp),%esi
f010079f:	56                   	push   %esi
f01007a0:	ff 75 d8             	pushl  -0x28(%ebp)
f01007a3:	ff 75 dc             	pushl  -0x24(%ebp)
f01007a6:	68 5d 39 10 f0       	push   $0xf010395d
f01007ab:	e8 53 1f 00 00       	call   f0102703 <cprintf>
		ebp = (unsigned int*)*ebp;
f01007b0:	8b 1b                	mov    (%ebx),%ebx
f01007b2:	83 c4 20             	add    $0x20,%esp
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	cprintf("Stack backtrace:\n");
	unsigned int* ebp = (unsigned int*)read_ebp();
	while(ebp != 0){
f01007b5:	85 db                	test   %ebx,%ebx
f01007b7:	75 8e                	jne    f0100747 <mon_backtrace+0x1d>
		cprintf("%u: ", info.eip_line);
		cprintf("%.*s+%d\n", info.eip_fn_namelen, info.eip_fn_name, eip - info.eip_fn_addr);
		ebp = (unsigned int*)*ebp;
	}
	return 0;
}
f01007b9:	b8 00 00 00 00       	mov    $0x0,%eax
f01007be:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007c1:	5b                   	pop    %ebx
f01007c2:	5e                   	pop    %esi
f01007c3:	5f                   	pop    %edi
f01007c4:	5d                   	pop    %ebp
f01007c5:	c3                   	ret    

f01007c6 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007c6:	55                   	push   %ebp
f01007c7:	89 e5                	mov    %esp,%ebp
f01007c9:	57                   	push   %edi
f01007ca:	56                   	push   %esi
f01007cb:	53                   	push   %ebx
f01007cc:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007cf:	68 18 3b 10 f0       	push   $0xf0103b18
f01007d4:	e8 2a 1f 00 00       	call   f0102703 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007d9:	c7 04 24 3c 3b 10 f0 	movl   $0xf0103b3c,(%esp)
f01007e0:	e8 1e 1f 00 00       	call   f0102703 <cprintf>

        //unsigned int i = 0x00646c72;
        //cprintf("x=%d, y=%d", 3);
        int x = 1, y = 3, z = 4;
        cprintf("x %d, y %x, z %d\n", x, y, z);
f01007e5:	6a 04                	push   $0x4
f01007e7:	6a 03                	push   $0x3
f01007e9:	6a 01                	push   $0x1
f01007eb:	68 66 39 10 f0       	push   $0xf0103966
f01007f0:	e8 0e 1f 00 00       	call   f0102703 <cprintf>
f01007f5:	83 c4 20             	add    $0x20,%esp

	while (1) {
		buf = readline("K> ");
f01007f8:	83 ec 0c             	sub    $0xc,%esp
f01007fb:	68 78 39 10 f0       	push   $0xf0103978
f0100800:	e8 50 27 00 00       	call   f0102f55 <readline>
f0100805:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100807:	83 c4 10             	add    $0x10,%esp
f010080a:	85 c0                	test   %eax,%eax
f010080c:	74 ea                	je     f01007f8 <monitor+0x32>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010080e:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100815:	be 00 00 00 00       	mov    $0x0,%esi
f010081a:	eb 0a                	jmp    f0100826 <monitor+0x60>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010081c:	c6 03 00             	movb   $0x0,(%ebx)
f010081f:	89 f7                	mov    %esi,%edi
f0100821:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100824:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100826:	0f b6 03             	movzbl (%ebx),%eax
f0100829:	84 c0                	test   %al,%al
f010082b:	74 63                	je     f0100890 <monitor+0xca>
f010082d:	83 ec 08             	sub    $0x8,%esp
f0100830:	0f be c0             	movsbl %al,%eax
f0100833:	50                   	push   %eax
f0100834:	68 7c 39 10 f0       	push   $0xf010397c
f0100839:	e8 31 29 00 00       	call   f010316f <strchr>
f010083e:	83 c4 10             	add    $0x10,%esp
f0100841:	85 c0                	test   %eax,%eax
f0100843:	75 d7                	jne    f010081c <monitor+0x56>
			*buf++ = 0;
		if (*buf == 0)
f0100845:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100848:	74 46                	je     f0100890 <monitor+0xca>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010084a:	83 fe 0f             	cmp    $0xf,%esi
f010084d:	75 14                	jne    f0100863 <monitor+0x9d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010084f:	83 ec 08             	sub    $0x8,%esp
f0100852:	6a 10                	push   $0x10
f0100854:	68 81 39 10 f0       	push   $0xf0103981
f0100859:	e8 a5 1e 00 00       	call   f0102703 <cprintf>
f010085e:	83 c4 10             	add    $0x10,%esp
f0100861:	eb 95                	jmp    f01007f8 <monitor+0x32>
			return 0;
		}
		argv[argc++] = buf;
f0100863:	8d 7e 01             	lea    0x1(%esi),%edi
f0100866:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010086a:	eb 03                	jmp    f010086f <monitor+0xa9>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010086c:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010086f:	0f b6 03             	movzbl (%ebx),%eax
f0100872:	84 c0                	test   %al,%al
f0100874:	74 ae                	je     f0100824 <monitor+0x5e>
f0100876:	83 ec 08             	sub    $0x8,%esp
f0100879:	0f be c0             	movsbl %al,%eax
f010087c:	50                   	push   %eax
f010087d:	68 7c 39 10 f0       	push   $0xf010397c
f0100882:	e8 e8 28 00 00       	call   f010316f <strchr>
f0100887:	83 c4 10             	add    $0x10,%esp
f010088a:	85 c0                	test   %eax,%eax
f010088c:	74 de                	je     f010086c <monitor+0xa6>
f010088e:	eb 94                	jmp    f0100824 <monitor+0x5e>
			buf++;
	}
	argv[argc] = 0;
f0100890:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100897:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100898:	85 f6                	test   %esi,%esi
f010089a:	0f 84 58 ff ff ff    	je     f01007f8 <monitor+0x32>
f01008a0:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008a5:	83 ec 08             	sub    $0x8,%esp
f01008a8:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008ab:	ff 34 85 80 3b 10 f0 	pushl  -0xfefc480(,%eax,4)
f01008b2:	ff 75 a8             	pushl  -0x58(%ebp)
f01008b5:	e8 57 28 00 00       	call   f0103111 <strcmp>
f01008ba:	83 c4 10             	add    $0x10,%esp
f01008bd:	85 c0                	test   %eax,%eax
f01008bf:	75 21                	jne    f01008e2 <monitor+0x11c>
			return commands[i].func(argc, argv, tf);
f01008c1:	83 ec 04             	sub    $0x4,%esp
f01008c4:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008c7:	ff 75 08             	pushl  0x8(%ebp)
f01008ca:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008cd:	52                   	push   %edx
f01008ce:	56                   	push   %esi
f01008cf:	ff 14 85 88 3b 10 f0 	call   *-0xfefc478(,%eax,4)
        cprintf("x %d, y %x, z %d\n", x, y, z);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008d6:	83 c4 10             	add    $0x10,%esp
f01008d9:	85 c0                	test   %eax,%eax
f01008db:	78 25                	js     f0100902 <monitor+0x13c>
f01008dd:	e9 16 ff ff ff       	jmp    f01007f8 <monitor+0x32>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01008e2:	83 c3 01             	add    $0x1,%ebx
f01008e5:	83 fb 03             	cmp    $0x3,%ebx
f01008e8:	75 bb                	jne    f01008a5 <monitor+0xdf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008ea:	83 ec 08             	sub    $0x8,%esp
f01008ed:	ff 75 a8             	pushl  -0x58(%ebp)
f01008f0:	68 9e 39 10 f0       	push   $0xf010399e
f01008f5:	e8 09 1e 00 00       	call   f0102703 <cprintf>
f01008fa:	83 c4 10             	add    $0x10,%esp
f01008fd:	e9 f6 fe ff ff       	jmp    f01007f8 <monitor+0x32>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100902:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100905:	5b                   	pop    %ebx
f0100906:	5e                   	pop    %esi
f0100907:	5f                   	pop    %edi
f0100908:	5d                   	pop    %ebp
f0100909:	c3                   	ret    

f010090a <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f010090a:	55                   	push   %ebp
f010090b:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f010090d:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f0100914:	75 11                	jne    f0100927 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100916:	ba 6f 89 11 f0       	mov    $0xf011896f,%edx
f010091b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100921:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if(n == 0){
f0100927:	85 c0                	test   %eax,%eax
f0100929:	75 07                	jne    f0100932 <boot_alloc+0x28>
		return nextfree;
f010092b:	a1 38 75 11 f0       	mov    0xf0117538,%eax
f0100930:	eb 15                	jmp    f0100947 <boot_alloc+0x3d>
	}
	else{
		nextfree = ROUNDUP((char *)(nextfree + n), PGSIZE);
f0100932:	03 05 38 75 11 f0    	add    0xf0117538,%eax
f0100938:	05 ff 0f 00 00       	add    $0xfff,%eax
f010093d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100942:	a3 38 75 11 f0       	mov    %eax,0xf0117538
		return nextfree;
	}
	return NULL;
}
f0100947:	5d                   	pop    %ebp
f0100948:	c3                   	ret    

f0100949 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100949:	55                   	push   %ebp
f010094a:	89 e5                	mov    %esp,%ebp
f010094c:	56                   	push   %esi
f010094d:	53                   	push   %ebx
f010094e:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100950:	83 ec 0c             	sub    $0xc,%esp
f0100953:	50                   	push   %eax
f0100954:	e8 43 1d 00 00       	call   f010269c <mc146818_read>
f0100959:	89 c6                	mov    %eax,%esi
f010095b:	83 c3 01             	add    $0x1,%ebx
f010095e:	89 1c 24             	mov    %ebx,(%esp)
f0100961:	e8 36 1d 00 00       	call   f010269c <mc146818_read>
f0100966:	c1 e0 08             	shl    $0x8,%eax
f0100969:	09 f0                	or     %esi,%eax
}
f010096b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010096e:	5b                   	pop    %ebx
f010096f:	5e                   	pop    %esi
f0100970:	5d                   	pop    %ebp
f0100971:	c3                   	ret    

f0100972 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100972:	89 d1                	mov    %edx,%ecx
f0100974:	c1 e9 16             	shr    $0x16,%ecx
f0100977:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f010097a:	a8 01                	test   $0x1,%al
f010097c:	74 52                	je     f01009d0 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f010097e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100983:	89 c1                	mov    %eax,%ecx
f0100985:	c1 e9 0c             	shr    $0xc,%ecx
f0100988:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f010098e:	72 1b                	jb     f01009ab <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100990:	55                   	push   %ebp
f0100991:	89 e5                	mov    %esp,%ebp
f0100993:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100996:	50                   	push   %eax
f0100997:	68 a4 3b 10 f0       	push   $0xf0103ba4
f010099c:	68 e1 02 00 00       	push   $0x2e1
f01009a1:	68 f8 42 10 f0       	push   $0xf01042f8
f01009a6:	e8 e0 f6 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f01009ab:	c1 ea 0c             	shr    $0xc,%edx
f01009ae:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009b4:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f01009bb:	89 c2                	mov    %eax,%edx
f01009bd:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009c0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009c5:	85 d2                	test   %edx,%edx
f01009c7:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009cc:	0f 44 c2             	cmove  %edx,%eax
f01009cf:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f01009d0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f01009d5:	c3                   	ret    

f01009d6 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01009d6:	55                   	push   %ebp
f01009d7:	89 e5                	mov    %esp,%ebp
f01009d9:	57                   	push   %edi
f01009da:	56                   	push   %esi
f01009db:	53                   	push   %ebx
f01009dc:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01009df:	84 c0                	test   %al,%al
f01009e1:	0f 85 72 02 00 00    	jne    f0100c59 <check_page_free_list+0x283>
f01009e7:	e9 7f 02 00 00       	jmp    f0100c6b <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f01009ec:	83 ec 04             	sub    $0x4,%esp
f01009ef:	68 c8 3b 10 f0       	push   $0xf0103bc8
f01009f4:	68 24 02 00 00       	push   $0x224
f01009f9:	68 f8 42 10 f0       	push   $0xf01042f8
f01009fe:	e8 88 f6 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a03:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a06:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a09:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a0c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a0f:	89 c2                	mov    %eax,%edx
f0100a11:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0100a17:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a1d:	0f 95 c2             	setne  %dl
f0100a20:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a23:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a27:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a29:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a2d:	8b 00                	mov    (%eax),%eax
f0100a2f:	85 c0                	test   %eax,%eax
f0100a31:	75 dc                	jne    f0100a0f <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a33:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a36:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a3c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a3f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a42:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a44:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a47:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a4c:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a51:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100a57:	eb 53                	jmp    f0100aac <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a59:	89 d8                	mov    %ebx,%eax
f0100a5b:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100a61:	c1 f8 03             	sar    $0x3,%eax
f0100a64:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a67:	89 c2                	mov    %eax,%edx
f0100a69:	c1 ea 16             	shr    $0x16,%edx
f0100a6c:	39 f2                	cmp    %esi,%edx
f0100a6e:	73 3a                	jae    f0100aaa <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a70:	89 c2                	mov    %eax,%edx
f0100a72:	c1 ea 0c             	shr    $0xc,%edx
f0100a75:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100a7b:	72 12                	jb     f0100a8f <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a7d:	50                   	push   %eax
f0100a7e:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0100a83:	6a 52                	push   $0x52
f0100a85:	68 04 43 10 f0       	push   $0xf0104304
f0100a8a:	e8 fc f5 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a8f:	83 ec 04             	sub    $0x4,%esp
f0100a92:	68 80 00 00 00       	push   $0x80
f0100a97:	68 97 00 00 00       	push   $0x97
f0100a9c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100aa1:	50                   	push   %eax
f0100aa2:	e8 05 27 00 00       	call   f01031ac <memset>
f0100aa7:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100aaa:	8b 1b                	mov    (%ebx),%ebx
f0100aac:	85 db                	test   %ebx,%ebx
f0100aae:	75 a9                	jne    f0100a59 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100ab0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ab5:	e8 50 fe ff ff       	call   f010090a <boot_alloc>
f0100aba:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100abd:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ac3:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
		assert(pp < pages + npages);
f0100ac9:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0100ace:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100ad1:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ad4:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100ad7:	be 00 00 00 00       	mov    $0x0,%esi
f0100adc:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100adf:	e9 30 01 00 00       	jmp    f0100c14 <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100ae4:	39 ca                	cmp    %ecx,%edx
f0100ae6:	73 19                	jae    f0100b01 <check_page_free_list+0x12b>
f0100ae8:	68 12 43 10 f0       	push   $0xf0104312
f0100aed:	68 1e 43 10 f0       	push   $0xf010431e
f0100af2:	68 3e 02 00 00       	push   $0x23e
f0100af7:	68 f8 42 10 f0       	push   $0xf01042f8
f0100afc:	e8 8a f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100b01:	39 fa                	cmp    %edi,%edx
f0100b03:	72 19                	jb     f0100b1e <check_page_free_list+0x148>
f0100b05:	68 33 43 10 f0       	push   $0xf0104333
f0100b0a:	68 1e 43 10 f0       	push   $0xf010431e
f0100b0f:	68 3f 02 00 00       	push   $0x23f
f0100b14:	68 f8 42 10 f0       	push   $0xf01042f8
f0100b19:	e8 6d f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b1e:	89 d0                	mov    %edx,%eax
f0100b20:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b23:	a8 07                	test   $0x7,%al
f0100b25:	74 19                	je     f0100b40 <check_page_free_list+0x16a>
f0100b27:	68 ec 3b 10 f0       	push   $0xf0103bec
f0100b2c:	68 1e 43 10 f0       	push   $0xf010431e
f0100b31:	68 40 02 00 00       	push   $0x240
f0100b36:	68 f8 42 10 f0       	push   $0xf01042f8
f0100b3b:	e8 4b f5 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b40:	c1 f8 03             	sar    $0x3,%eax
f0100b43:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b46:	85 c0                	test   %eax,%eax
f0100b48:	75 19                	jne    f0100b63 <check_page_free_list+0x18d>
f0100b4a:	68 47 43 10 f0       	push   $0xf0104347
f0100b4f:	68 1e 43 10 f0       	push   $0xf010431e
f0100b54:	68 43 02 00 00       	push   $0x243
f0100b59:	68 f8 42 10 f0       	push   $0xf01042f8
f0100b5e:	e8 28 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b63:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b68:	75 19                	jne    f0100b83 <check_page_free_list+0x1ad>
f0100b6a:	68 58 43 10 f0       	push   $0xf0104358
f0100b6f:	68 1e 43 10 f0       	push   $0xf010431e
f0100b74:	68 44 02 00 00       	push   $0x244
f0100b79:	68 f8 42 10 f0       	push   $0xf01042f8
f0100b7e:	e8 08 f5 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b83:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b88:	75 19                	jne    f0100ba3 <check_page_free_list+0x1cd>
f0100b8a:	68 20 3c 10 f0       	push   $0xf0103c20
f0100b8f:	68 1e 43 10 f0       	push   $0xf010431e
f0100b94:	68 45 02 00 00       	push   $0x245
f0100b99:	68 f8 42 10 f0       	push   $0xf01042f8
f0100b9e:	e8 e8 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100ba3:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100ba8:	75 19                	jne    f0100bc3 <check_page_free_list+0x1ed>
f0100baa:	68 71 43 10 f0       	push   $0xf0104371
f0100baf:	68 1e 43 10 f0       	push   $0xf010431e
f0100bb4:	68 46 02 00 00       	push   $0x246
f0100bb9:	68 f8 42 10 f0       	push   $0xf01042f8
f0100bbe:	e8 c8 f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100bc3:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100bc8:	76 3f                	jbe    f0100c09 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bca:	89 c3                	mov    %eax,%ebx
f0100bcc:	c1 eb 0c             	shr    $0xc,%ebx
f0100bcf:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100bd2:	77 12                	ja     f0100be6 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bd4:	50                   	push   %eax
f0100bd5:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0100bda:	6a 52                	push   $0x52
f0100bdc:	68 04 43 10 f0       	push   $0xf0104304
f0100be1:	e8 a5 f4 ff ff       	call   f010008b <_panic>
f0100be6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100beb:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100bee:	76 1e                	jbe    f0100c0e <check_page_free_list+0x238>
f0100bf0:	68 44 3c 10 f0       	push   $0xf0103c44
f0100bf5:	68 1e 43 10 f0       	push   $0xf010431e
f0100bfa:	68 47 02 00 00       	push   $0x247
f0100bff:	68 f8 42 10 f0       	push   $0xf01042f8
f0100c04:	e8 82 f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c09:	83 c6 01             	add    $0x1,%esi
f0100c0c:	eb 04                	jmp    f0100c12 <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100c0e:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c12:	8b 12                	mov    (%edx),%edx
f0100c14:	85 d2                	test   %edx,%edx
f0100c16:	0f 85 c8 fe ff ff    	jne    f0100ae4 <check_page_free_list+0x10e>
f0100c1c:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c1f:	85 f6                	test   %esi,%esi
f0100c21:	7f 19                	jg     f0100c3c <check_page_free_list+0x266>
f0100c23:	68 8b 43 10 f0       	push   $0xf010438b
f0100c28:	68 1e 43 10 f0       	push   $0xf010431e
f0100c2d:	68 4f 02 00 00       	push   $0x24f
f0100c32:	68 f8 42 10 f0       	push   $0xf01042f8
f0100c37:	e8 4f f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c3c:	85 db                	test   %ebx,%ebx
f0100c3e:	7f 42                	jg     f0100c82 <check_page_free_list+0x2ac>
f0100c40:	68 9d 43 10 f0       	push   $0xf010439d
f0100c45:	68 1e 43 10 f0       	push   $0xf010431e
f0100c4a:	68 50 02 00 00       	push   $0x250
f0100c4f:	68 f8 42 10 f0       	push   $0xf01042f8
f0100c54:	e8 32 f4 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c59:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100c5e:	85 c0                	test   %eax,%eax
f0100c60:	0f 85 9d fd ff ff    	jne    f0100a03 <check_page_free_list+0x2d>
f0100c66:	e9 81 fd ff ff       	jmp    f01009ec <check_page_free_list+0x16>
f0100c6b:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f0100c72:	0f 84 74 fd ff ff    	je     f01009ec <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c78:	be 00 04 00 00       	mov    $0x400,%esi
f0100c7d:	e9 cf fd ff ff       	jmp    f0100a51 <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100c82:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c85:	5b                   	pop    %ebx
f0100c86:	5e                   	pop    %esi
f0100c87:	5f                   	pop    %edi
f0100c88:	5d                   	pop    %ebp
f0100c89:	c3                   	ret    

f0100c8a <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c8a:	55                   	push   %ebp
f0100c8b:	89 e5                	mov    %esp,%ebp
f0100c8d:	57                   	push   %edi
f0100c8e:	56                   	push   %esi
f0100c8f:	53                   	push   %ebx
f0100c90:	83 ec 14             	sub    $0x14,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	cprintf("address of pages: %x\n",pages); 
f0100c93:	ff 35 6c 79 11 f0    	pushl  0xf011796c
f0100c99:	68 ae 43 10 f0       	push   $0xf01043ae
f0100c9e:	e8 60 1a 00 00       	call   f0102703 <cprintf>
	cprintf("number of PageInfos: %d\n", npages);
f0100ca3:	83 c4 08             	add    $0x8,%esp
f0100ca6:	ff 35 64 79 11 f0    	pushl  0xf0117964
f0100cac:	68 c4 43 10 f0       	push   $0xf01043c4
f0100cb1:	e8 4d 1a 00 00       	call   f0102703 <cprintf>
	cprintf("value of EXTPHYSMEM: %x\n", EXTPHYSMEM);
f0100cb6:	83 c4 08             	add    $0x8,%esp
f0100cb9:	68 00 00 10 00       	push   $0x100000
f0100cbe:	68 dd 43 10 f0       	push   $0xf01043dd
f0100cc3:	e8 3b 1a 00 00       	call   f0102703 <cprintf>
	size_t IOHole = ROUNDUP(EXTPHYSMEM, PGSIZE) / PGSIZE;
	size_t EndOfPages = (size_t)pages + (sizeof(struct PageInfo) * npages);
	//Map to physical address
	EndOfPages -= 0xf0000000;
	EndOfPages = ROUNDUP(EndOfPages, PGSIZE) / PGSIZE;
f0100cc8:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0100ccd:	8b 15 64 79 11 f0    	mov    0xf0117964,%edx
f0100cd3:	8d 9c d0 ff 0f 00 10 	lea    0x10000fff(%eax,%edx,8),%ebx
f0100cda:	c1 eb 0c             	shr    $0xc,%ebx
f0100cdd:	83 c4 08             	add    $0x8,%esp
f0100ce0:	81 fb 00 01 00 00    	cmp    $0x100,%ebx
f0100ce6:	b8 00 01 00 00       	mov    $0x100,%eax
f0100ceb:	0f 42 d8             	cmovb  %eax,%ebx
	if(IOHole < EndOfPages){
		IOHole = EndOfPages;
	}
	cprintf("IOHole: %d\n", IOHole);
f0100cee:	53                   	push   %ebx
f0100cef:	68 f6 43 10 f0       	push   $0xf01043f6
f0100cf4:	e8 0a 1a 00 00       	call   f0102703 <cprintf>
	for (i = 1; i < npages; i++) {
		if(i >= npages_basemem && i < IOHole) continue;
f0100cf9:	8b 3d 40 75 11 f0    	mov    0xf0117540,%edi
f0100cff:	8b 35 3c 75 11 f0    	mov    0xf011753c,%esi
	EndOfPages = ROUNDUP(EndOfPages, PGSIZE) / PGSIZE;
	if(IOHole < EndOfPages){
		IOHole = EndOfPages;
	}
	cprintf("IOHole: %d\n", IOHole);
	for (i = 1; i < npages; i++) {
f0100d05:	83 c4 10             	add    $0x10,%esp
f0100d08:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d0d:	b8 01 00 00 00       	mov    $0x1,%eax
f0100d12:	eb 2f                	jmp    f0100d43 <page_init+0xb9>
		if(i >= npages_basemem && i < IOHole) continue;
f0100d14:	39 d8                	cmp    %ebx,%eax
f0100d16:	73 04                	jae    f0100d1c <page_init+0x92>
f0100d18:	39 f8                	cmp    %edi,%eax
f0100d1a:	73 24                	jae    f0100d40 <page_init+0xb6>
		pages[i].pp_ref = 0;
f0100d1c:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100d23:	89 d1                	mov    %edx,%ecx
f0100d25:	03 0d 6c 79 11 f0    	add    0xf011796c,%ecx
f0100d2b:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100d31:	89 31                	mov    %esi,(%ecx)
		page_free_list = &pages[i];
f0100d33:	89 d6                	mov    %edx,%esi
f0100d35:	03 35 6c 79 11 f0    	add    0xf011796c,%esi
f0100d3b:	ba 01 00 00 00       	mov    $0x1,%edx
	EndOfPages = ROUNDUP(EndOfPages, PGSIZE) / PGSIZE;
	if(IOHole < EndOfPages){
		IOHole = EndOfPages;
	}
	cprintf("IOHole: %d\n", IOHole);
	for (i = 1; i < npages; i++) {
f0100d40:	83 c0 01             	add    $0x1,%eax
f0100d43:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0100d49:	72 c9                	jb     f0100d14 <page_init+0x8a>
f0100d4b:	84 d2                	test   %dl,%dl
f0100d4d:	74 06                	je     f0100d55 <page_init+0xcb>
f0100d4f:	89 35 3c 75 11 f0    	mov    %esi,0xf011753c
		if(i >= npages_basemem && i < IOHole) continue;
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0100d55:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d58:	5b                   	pop    %ebx
f0100d59:	5e                   	pop    %esi
f0100d5a:	5f                   	pop    %edi
f0100d5b:	5d                   	pop    %ebp
f0100d5c:	c3                   	ret    

f0100d5d <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d5d:	55                   	push   %ebp
f0100d5e:	89 e5                	mov    %esp,%ebp
f0100d60:	53                   	push   %ebx
f0100d61:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	if(page_free_list == NULL){
f0100d64:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100d6a:	85 db                	test   %ebx,%ebx
f0100d6c:	74 58                	je     f0100dc6 <page_alloc+0x69>
		return NULL;
	}
	struct PageInfo* free_addr = page_free_list;
	page_free_list = page_free_list -> pp_link;
f0100d6e:	8b 03                	mov    (%ebx),%eax
f0100d70:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
	free_addr -> pp_link = NULL;
f0100d75:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if(alloc_flags & ALLOC_ZERO){
f0100d7b:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d7f:	74 45                	je     f0100dc6 <page_alloc+0x69>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d81:	89 d8                	mov    %ebx,%eax
f0100d83:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100d89:	c1 f8 03             	sar    $0x3,%eax
f0100d8c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d8f:	89 c2                	mov    %eax,%edx
f0100d91:	c1 ea 0c             	shr    $0xc,%edx
f0100d94:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100d9a:	72 12                	jb     f0100dae <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d9c:	50                   	push   %eax
f0100d9d:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0100da2:	6a 52                	push   $0x52
f0100da4:	68 04 43 10 f0       	push   $0xf0104304
f0100da9:	e8 dd f2 ff ff       	call   f010008b <_panic>
		memset(page2kva(free_addr), 0, PGSIZE);
f0100dae:	83 ec 04             	sub    $0x4,%esp
f0100db1:	68 00 10 00 00       	push   $0x1000
f0100db6:	6a 00                	push   $0x0
f0100db8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100dbd:	50                   	push   %eax
f0100dbe:	e8 e9 23 00 00       	call   f01031ac <memset>
f0100dc3:	83 c4 10             	add    $0x10,%esp
	}
	//cprintf("free address: %x\n", free_addr);
	return free_addr;
}
f0100dc6:	89 d8                	mov    %ebx,%eax
f0100dc8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100dcb:	c9                   	leave  
f0100dcc:	c3                   	ret    

f0100dcd <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100dcd:	55                   	push   %ebp
f0100dce:	89 e5                	mov    %esp,%ebp
f0100dd0:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	pp -> pp_link = page_free_list;
f0100dd3:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100dd9:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100ddb:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
}
f0100de0:	5d                   	pop    %ebp
f0100de1:	c3                   	ret    

f0100de2 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100de2:	55                   	push   %ebp
f0100de3:	89 e5                	mov    %esp,%ebp
f0100de5:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0100de8:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f0100dec:	83 e8 01             	sub    $0x1,%eax
f0100def:	66 89 42 04          	mov    %ax,0x4(%edx)
f0100df3:	66 85 c0             	test   %ax,%ax
f0100df6:	75 09                	jne    f0100e01 <page_decref+0x1f>
		page_free(pp);
f0100df8:	52                   	push   %edx
f0100df9:	e8 cf ff ff ff       	call   f0100dcd <page_free>
f0100dfe:	83 c4 04             	add    $0x4,%esp
}
f0100e01:	c9                   	leave  
f0100e02:	c3                   	ret    

f0100e03 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e03:	55                   	push   %ebp
f0100e04:	89 e5                	mov    %esp,%ebp
f0100e06:	56                   	push   %esi
f0100e07:	53                   	push   %ebx
f0100e08:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	int pgdirIndex = PDX(va);
	int pgtableIndex = PTX(va);
f0100e0b:	89 de                	mov    %ebx,%esi
f0100e0d:	c1 ee 0c             	shr    $0xc,%esi
f0100e10:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	uintptr_t pgAddr = (uintptr_t)pgdir[pgdirIndex];
f0100e16:	c1 eb 16             	shr    $0x16,%ebx
f0100e19:	c1 e3 02             	shl    $0x2,%ebx
f0100e1c:	03 5d 08             	add    0x8(%ebp),%ebx
	pte_t * phAddr = NULL;
	if((pgAddr & PTE_P) == 0){
f0100e1f:	f6 03 01             	testb  $0x1,(%ebx)
f0100e22:	75 2d                	jne    f0100e51 <pgdir_walk+0x4e>
		struct PageInfo* newPage;
		if(create == false){
f0100e24:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e28:	74 59                	je     f0100e83 <pgdir_walk+0x80>
			return NULL;
		}
		else{
			newPage = page_alloc(1);
f0100e2a:	83 ec 0c             	sub    $0xc,%esp
f0100e2d:	6a 01                	push   $0x1
f0100e2f:	e8 29 ff ff ff       	call   f0100d5d <page_alloc>
			if(newPage == NULL){
f0100e34:	83 c4 10             	add    $0x10,%esp
f0100e37:	85 c0                	test   %eax,%eax
f0100e39:	74 4f                	je     f0100e8a <pgdir_walk+0x87>
				return NULL;
			}
			else{
				newPage -> pp_ref += 1;
f0100e3b:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
				pgdir[pgdirIndex] = page2pa(newPage) | PTE_P | PTE_U | PTE_W;
f0100e40:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100e46:	c1 f8 03             	sar    $0x3,%eax
f0100e49:	c1 e0 0c             	shl    $0xc,%eax
f0100e4c:	83 c8 07             	or     $0x7,%eax
f0100e4f:	89 03                	mov    %eax,(%ebx)
			}
		}
	}
	phAddr = KADDR(PTE_ADDR(pgdir[pgdirIndex]));
f0100e51:	8b 03                	mov    (%ebx),%eax
f0100e53:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e58:	89 c2                	mov    %eax,%edx
f0100e5a:	c1 ea 0c             	shr    $0xc,%edx
f0100e5d:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100e63:	72 15                	jb     f0100e7a <pgdir_walk+0x77>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e65:	50                   	push   %eax
f0100e66:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0100e6b:	68 84 01 00 00       	push   $0x184
f0100e70:	68 f8 42 10 f0       	push   $0xf01042f8
f0100e75:	e8 11 f2 ff ff       	call   f010008b <_panic>
	return phAddr + pgtableIndex;
f0100e7a:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100e81:	eb 0c                	jmp    f0100e8f <pgdir_walk+0x8c>
	uintptr_t pgAddr = (uintptr_t)pgdir[pgdirIndex];
	pte_t * phAddr = NULL;
	if((pgAddr & PTE_P) == 0){
		struct PageInfo* newPage;
		if(create == false){
			return NULL;
f0100e83:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e88:	eb 05                	jmp    f0100e8f <pgdir_walk+0x8c>
		}
		else{
			newPage = page_alloc(1);
			if(newPage == NULL){
				return NULL;
f0100e8a:	b8 00 00 00 00       	mov    $0x0,%eax
			}
		}
	}
	phAddr = KADDR(PTE_ADDR(pgdir[pgdirIndex]));
	return phAddr + pgtableIndex;
}
f0100e8f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100e92:	5b                   	pop    %ebx
f0100e93:	5e                   	pop    %esi
f0100e94:	5d                   	pop    %ebp
f0100e95:	c3                   	ret    

f0100e96 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100e96:	55                   	push   %ebp
f0100e97:	89 e5                	mov    %esp,%ebp
f0100e99:	57                   	push   %edi
f0100e9a:	56                   	push   %esi
f0100e9b:	53                   	push   %ebx
f0100e9c:	83 ec 1c             	sub    $0x1c,%esp
f0100e9f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100ea2:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	size_t pagenum = size / PGSIZE;
f0100ea5:	c1 e9 0c             	shr    $0xc,%ecx
f0100ea8:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	size_t i;
	for(i = 0; i < pagenum; i++){
f0100eab:	89 c3                	mov    %eax,%ebx
f0100ead:	be 00 00 00 00       	mov    $0x0,%esi
		uintptr_t virAddr = (uintptr_t)((char *)va + PGSIZE * i);
		physaddr_t currPhyAddr = (physaddr_t)((char *)pa + PGSIZE * i);
		pde_t * phyAddr = pgdir_walk(pgdir, (void*)virAddr, 1);
f0100eb2:	89 d7                	mov    %edx,%edi
f0100eb4:	29 c7                	sub    %eax,%edi
		if(phyAddr == NULL){
			panic("Out of memory!\n");
			continue;
		}
		*phyAddr = currPhyAddr | perm | PTE_P;
f0100eb6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100eb9:	83 c8 01             	or     $0x1,%eax
f0100ebc:	89 45 dc             	mov    %eax,-0x24(%ebp)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size_t pagenum = size / PGSIZE;
	size_t i;
	for(i = 0; i < pagenum; i++){
f0100ebf:	eb 3f                	jmp    f0100f00 <boot_map_region+0x6a>
		uintptr_t virAddr = (uintptr_t)((char *)va + PGSIZE * i);
		physaddr_t currPhyAddr = (physaddr_t)((char *)pa + PGSIZE * i);
		pde_t * phyAddr = pgdir_walk(pgdir, (void*)virAddr, 1);
f0100ec1:	83 ec 04             	sub    $0x4,%esp
f0100ec4:	6a 01                	push   $0x1
f0100ec6:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0100ec9:	50                   	push   %eax
f0100eca:	ff 75 e0             	pushl  -0x20(%ebp)
f0100ecd:	e8 31 ff ff ff       	call   f0100e03 <pgdir_walk>
f0100ed2:	8d 93 00 10 00 00    	lea    0x1000(%ebx),%edx
		if(phyAddr == NULL){
f0100ed8:	83 c4 10             	add    $0x10,%esp
f0100edb:	85 c0                	test   %eax,%eax
f0100edd:	75 17                	jne    f0100ef6 <boot_map_region+0x60>
			panic("Out of memory!\n");
f0100edf:	83 ec 04             	sub    $0x4,%esp
f0100ee2:	68 02 44 10 f0       	push   $0xf0104402
f0100ee7:	68 9e 01 00 00       	push   $0x19e
f0100eec:	68 f8 42 10 f0       	push   $0xf01042f8
f0100ef1:	e8 95 f1 ff ff       	call   f010008b <_panic>
			continue;
		}
		*phyAddr = currPhyAddr | perm | PTE_P;
f0100ef6:	0b 5d dc             	or     -0x24(%ebp),%ebx
f0100ef9:	89 18                	mov    %ebx,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	size_t pagenum = size / PGSIZE;
	size_t i;
	for(i = 0; i < pagenum; i++){
f0100efb:	83 c6 01             	add    $0x1,%esi
f0100efe:	89 d3                	mov    %edx,%ebx
f0100f00:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0100f03:	75 bc                	jne    f0100ec1 <boot_map_region+0x2b>
			panic("Out of memory!\n");
			continue;
		}
		*phyAddr = currPhyAddr | perm | PTE_P;
	}
}
f0100f05:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f08:	5b                   	pop    %ebx
f0100f09:	5e                   	pop    %esi
f0100f0a:	5f                   	pop    %edi
f0100f0b:	5d                   	pop    %ebp
f0100f0c:	c3                   	ret    

f0100f0d <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f0d:	55                   	push   %ebp
f0100f0e:	89 e5                	mov    %esp,%ebp
f0100f10:	53                   	push   %ebx
f0100f11:	83 ec 08             	sub    $0x8,%esp
f0100f14:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t * phyAddr = pgdir_walk(pgdir, va, 0);
f0100f17:	6a 00                	push   $0x0
f0100f19:	ff 75 0c             	pushl  0xc(%ebp)
f0100f1c:	ff 75 08             	pushl  0x8(%ebp)
f0100f1f:	e8 df fe ff ff       	call   f0100e03 <pgdir_walk>
	if(pte_store != NULL){
f0100f24:	83 c4 10             	add    $0x10,%esp
f0100f27:	85 db                	test   %ebx,%ebx
f0100f29:	74 02                	je     f0100f2d <page_lookup+0x20>
		*pte_store = phyAddr;
f0100f2b:	89 03                	mov    %eax,(%ebx)
	}
	if(phyAddr != NULL){
f0100f2d:	85 c0                	test   %eax,%eax
f0100f2f:	74 30                	je     f0100f61 <page_lookup+0x54>
		if((*phyAddr & PTE_P) != 0){
f0100f31:	8b 00                	mov    (%eax),%eax
f0100f33:	a8 01                	test   $0x1,%al
f0100f35:	74 31                	je     f0100f68 <page_lookup+0x5b>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f37:	c1 e8 0c             	shr    $0xc,%eax
f0100f3a:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0100f40:	72 14                	jb     f0100f56 <page_lookup+0x49>
		panic("pa2page called with invalid pa");
f0100f42:	83 ec 04             	sub    $0x4,%esp
f0100f45:	68 8c 3c 10 f0       	push   $0xf0103c8c
f0100f4a:	6a 4b                	push   $0x4b
f0100f4c:	68 04 43 10 f0       	push   $0xf0104304
f0100f51:	e8 35 f1 ff ff       	call   f010008b <_panic>
	return &pages[PGNUM(pa)];
f0100f56:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f0100f5c:	8d 04 c2             	lea    (%edx,%eax,8),%eax
			return pa2page((physaddr_t)*phyAddr & 0xfffff000);
f0100f5f:	eb 0c                	jmp    f0100f6d <page_lookup+0x60>
		}
	}
	return NULL;
f0100f61:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f66:	eb 05                	jmp    f0100f6d <page_lookup+0x60>
f0100f68:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100f6d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f70:	c9                   	leave  
f0100f71:	c3                   	ret    

f0100f72 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100f72:	55                   	push   %ebp
f0100f73:	89 e5                	mov    %esp,%ebp
f0100f75:	56                   	push   %esi
f0100f76:	53                   	push   %ebx
f0100f77:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f7a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	if(page_lookup(pgdir, va, NULL) == NULL) return;
f0100f7d:	83 ec 04             	sub    $0x4,%esp
f0100f80:	6a 00                	push   $0x0
f0100f82:	53                   	push   %ebx
f0100f83:	56                   	push   %esi
f0100f84:	e8 84 ff ff ff       	call   f0100f0d <page_lookup>
f0100f89:	83 c4 10             	add    $0x10,%esp
f0100f8c:	85 c0                	test   %eax,%eax
f0100f8e:	74 30                	je     f0100fc0 <page_remove+0x4e>
	struct PageInfo* page = page_lookup(pgdir, va, NULL);
f0100f90:	83 ec 04             	sub    $0x4,%esp
f0100f93:	6a 00                	push   $0x0
f0100f95:	53                   	push   %ebx
f0100f96:	56                   	push   %esi
f0100f97:	e8 71 ff ff ff       	call   f0100f0d <page_lookup>
	page_decref(page);
f0100f9c:	89 04 24             	mov    %eax,(%esp)
f0100f9f:	e8 3e fe ff ff       	call   f0100de2 <page_decref>
	pte_t * phyAddr = pgdir_walk(pgdir, va, 0);
f0100fa4:	83 c4 0c             	add    $0xc,%esp
f0100fa7:	6a 00                	push   $0x0
f0100fa9:	53                   	push   %ebx
f0100faa:	56                   	push   %esi
f0100fab:	e8 53 fe ff ff       	call   f0100e03 <pgdir_walk>
	if(phyAddr != NULL){
f0100fb0:	83 c4 10             	add    $0x10,%esp
f0100fb3:	85 c0                	test   %eax,%eax
f0100fb5:	74 06                	je     f0100fbd <page_remove+0x4b>
		*phyAddr = 0;
f0100fb7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100fbd:	0f 01 3b             	invlpg (%ebx)
	}	
	tlb_invalidate(pgdir, va);
}
f0100fc0:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100fc3:	5b                   	pop    %ebx
f0100fc4:	5e                   	pop    %esi
f0100fc5:	5d                   	pop    %ebp
f0100fc6:	c3                   	ret    

f0100fc7 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100fc7:	55                   	push   %ebp
f0100fc8:	89 e5                	mov    %esp,%ebp
f0100fca:	57                   	push   %edi
f0100fcb:	56                   	push   %esi
f0100fcc:	53                   	push   %ebx
f0100fcd:	83 ec 10             	sub    $0x10,%esp
f0100fd0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100fd3:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t * pgtEntry = pgdir_walk(pgdir, va, 1);
f0100fd6:	6a 01                	push   $0x1
f0100fd8:	57                   	push   %edi
f0100fd9:	ff 75 08             	pushl  0x8(%ebp)
f0100fdc:	e8 22 fe ff ff       	call   f0100e03 <pgdir_walk>
	if(pgtEntry == NULL){
f0100fe1:	83 c4 10             	add    $0x10,%esp
f0100fe4:	85 c0                	test   %eax,%eax
f0100fe6:	74 38                	je     f0101020 <page_insert+0x59>
f0100fe8:	89 c6                	mov    %eax,%esi
		return -E_NO_MEM;
	}
	//Put this beforehand, or trouble may come.
	pp->pp_ref++;
f0100fea:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if((*pgtEntry & PTE_P) != 0){
f0100fef:	f6 00 01             	testb  $0x1,(%eax)
f0100ff2:	74 0f                	je     f0101003 <page_insert+0x3c>
		page_remove(pgdir, va);
f0100ff4:	83 ec 08             	sub    $0x8,%esp
f0100ff7:	57                   	push   %edi
f0100ff8:	ff 75 08             	pushl  0x8(%ebp)
f0100ffb:	e8 72 ff ff ff       	call   f0100f72 <page_remove>
f0101000:	83 c4 10             	add    $0x10,%esp
	}
	*pgtEntry = page2pa(pp) | perm | PTE_P;
f0101003:	2b 1d 6c 79 11 f0    	sub    0xf011796c,%ebx
f0101009:	c1 fb 03             	sar    $0x3,%ebx
f010100c:	c1 e3 0c             	shl    $0xc,%ebx
f010100f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101012:	83 c8 01             	or     $0x1,%eax
f0101015:	09 c3                	or     %eax,%ebx
f0101017:	89 1e                	mov    %ebx,(%esi)
	return 0;
f0101019:	b8 00 00 00 00       	mov    $0x0,%eax
f010101e:	eb 05                	jmp    f0101025 <page_insert+0x5e>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
	pte_t * pgtEntry = pgdir_walk(pgdir, va, 1);
	if(pgtEntry == NULL){
		return -E_NO_MEM;
f0101020:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	if((*pgtEntry & PTE_P) != 0){
		page_remove(pgdir, va);
	}
	*pgtEntry = page2pa(pp) | perm | PTE_P;
	return 0;
}
f0101025:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101028:	5b                   	pop    %ebx
f0101029:	5e                   	pop    %esi
f010102a:	5f                   	pop    %edi
f010102b:	5d                   	pop    %ebp
f010102c:	c3                   	ret    

f010102d <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010102d:	55                   	push   %ebp
f010102e:	89 e5                	mov    %esp,%ebp
f0101030:	57                   	push   %edi
f0101031:	56                   	push   %esi
f0101032:	53                   	push   %ebx
f0101033:	83 ec 2c             	sub    $0x2c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0101036:	b8 15 00 00 00       	mov    $0x15,%eax
f010103b:	e8 09 f9 ff ff       	call   f0100949 <nvram_read>
f0101040:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101042:	b8 17 00 00 00       	mov    $0x17,%eax
f0101047:	e8 fd f8 ff ff       	call   f0100949 <nvram_read>
f010104c:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f010104e:	b8 34 00 00 00       	mov    $0x34,%eax
f0101053:	e8 f1 f8 ff ff       	call   f0100949 <nvram_read>
f0101058:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f010105b:	85 c0                	test   %eax,%eax
f010105d:	74 07                	je     f0101066 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f010105f:	05 00 40 00 00       	add    $0x4000,%eax
f0101064:	eb 0b                	jmp    f0101071 <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0101066:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f010106c:	85 f6                	test   %esi,%esi
f010106e:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0101071:	89 c2                	mov    %eax,%edx
f0101073:	c1 ea 02             	shr    $0x2,%edx
f0101076:	89 15 64 79 11 f0    	mov    %edx,0xf0117964
	npages_basemem = basemem / (PGSIZE / 1024);
f010107c:	89 da                	mov    %ebx,%edx
f010107e:	c1 ea 02             	shr    $0x2,%edx
f0101081:	89 15 40 75 11 f0    	mov    %edx,0xf0117540

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101087:	89 c2                	mov    %eax,%edx
f0101089:	29 da                	sub    %ebx,%edx
f010108b:	52                   	push   %edx
f010108c:	53                   	push   %ebx
f010108d:	50                   	push   %eax
f010108e:	68 ac 3c 10 f0       	push   $0xf0103cac
f0101093:	e8 6b 16 00 00       	call   f0102703 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101098:	b8 00 10 00 00       	mov    $0x1000,%eax
f010109d:	e8 68 f8 ff ff       	call   f010090a <boot_alloc>
f01010a2:	a3 68 79 11 f0       	mov    %eax,0xf0117968
	memset(kern_pgdir, 0, PGSIZE);
f01010a7:	83 c4 0c             	add    $0xc,%esp
f01010aa:	68 00 10 00 00       	push   $0x1000
f01010af:	6a 00                	push   $0x0
f01010b1:	50                   	push   %eax
f01010b2:	e8 f5 20 00 00       	call   f01031ac <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01010b7:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01010bc:	83 c4 10             	add    $0x10,%esp
f01010bf:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01010c4:	77 15                	ja     f01010db <mem_init+0xae>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01010c6:	50                   	push   %eax
f01010c7:	68 e8 3c 10 f0       	push   $0xf0103ce8
f01010cc:	68 94 00 00 00       	push   $0x94
f01010d1:	68 f8 42 10 f0       	push   $0xf01042f8
f01010d6:	e8 b0 ef ff ff       	call   f010008b <_panic>
f01010db:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01010e1:	83 ca 05             	or     $0x5,%edx
f01010e4:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *)boot_alloc(npages * sizeof(struct PageInfo));
f01010ea:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01010ef:	c1 e0 03             	shl    $0x3,%eax
f01010f2:	e8 13 f8 ff ff       	call   f010090a <boot_alloc>
f01010f7:	a3 6c 79 11 f0       	mov    %eax,0xf011796c
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01010fc:	e8 89 fb ff ff       	call   f0100c8a <page_init>

	check_page_free_list(1);
f0101101:	b8 01 00 00 00       	mov    $0x1,%eax
f0101106:	e8 cb f8 ff ff       	call   f01009d6 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010110b:	83 3d 6c 79 11 f0 00 	cmpl   $0x0,0xf011796c
f0101112:	75 17                	jne    f010112b <mem_init+0xfe>
		panic("'pages' is a null pointer!");
f0101114:	83 ec 04             	sub    $0x4,%esp
f0101117:	68 12 44 10 f0       	push   $0xf0104412
f010111c:	68 61 02 00 00       	push   $0x261
f0101121:	68 f8 42 10 f0       	push   $0xf01042f8
f0101126:	e8 60 ef ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010112b:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101130:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101135:	eb 05                	jmp    f010113c <mem_init+0x10f>
		++nfree;
f0101137:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010113a:	8b 00                	mov    (%eax),%eax
f010113c:	85 c0                	test   %eax,%eax
f010113e:	75 f7                	jne    f0101137 <mem_init+0x10a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101140:	83 ec 0c             	sub    $0xc,%esp
f0101143:	6a 00                	push   $0x0
f0101145:	e8 13 fc ff ff       	call   f0100d5d <page_alloc>
f010114a:	89 c7                	mov    %eax,%edi
f010114c:	83 c4 10             	add    $0x10,%esp
f010114f:	85 c0                	test   %eax,%eax
f0101151:	75 19                	jne    f010116c <mem_init+0x13f>
f0101153:	68 2d 44 10 f0       	push   $0xf010442d
f0101158:	68 1e 43 10 f0       	push   $0xf010431e
f010115d:	68 69 02 00 00       	push   $0x269
f0101162:	68 f8 42 10 f0       	push   $0xf01042f8
f0101167:	e8 1f ef ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010116c:	83 ec 0c             	sub    $0xc,%esp
f010116f:	6a 00                	push   $0x0
f0101171:	e8 e7 fb ff ff       	call   f0100d5d <page_alloc>
f0101176:	89 c6                	mov    %eax,%esi
f0101178:	83 c4 10             	add    $0x10,%esp
f010117b:	85 c0                	test   %eax,%eax
f010117d:	75 19                	jne    f0101198 <mem_init+0x16b>
f010117f:	68 43 44 10 f0       	push   $0xf0104443
f0101184:	68 1e 43 10 f0       	push   $0xf010431e
f0101189:	68 6a 02 00 00       	push   $0x26a
f010118e:	68 f8 42 10 f0       	push   $0xf01042f8
f0101193:	e8 f3 ee ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101198:	83 ec 0c             	sub    $0xc,%esp
f010119b:	6a 00                	push   $0x0
f010119d:	e8 bb fb ff ff       	call   f0100d5d <page_alloc>
f01011a2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01011a5:	83 c4 10             	add    $0x10,%esp
f01011a8:	85 c0                	test   %eax,%eax
f01011aa:	75 19                	jne    f01011c5 <mem_init+0x198>
f01011ac:	68 59 44 10 f0       	push   $0xf0104459
f01011b1:	68 1e 43 10 f0       	push   $0xf010431e
f01011b6:	68 6b 02 00 00       	push   $0x26b
f01011bb:	68 f8 42 10 f0       	push   $0xf01042f8
f01011c0:	e8 c6 ee ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01011c5:	39 f7                	cmp    %esi,%edi
f01011c7:	75 19                	jne    f01011e2 <mem_init+0x1b5>
f01011c9:	68 6f 44 10 f0       	push   $0xf010446f
f01011ce:	68 1e 43 10 f0       	push   $0xf010431e
f01011d3:	68 6e 02 00 00       	push   $0x26e
f01011d8:	68 f8 42 10 f0       	push   $0xf01042f8
f01011dd:	e8 a9 ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01011e2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01011e5:	39 c6                	cmp    %eax,%esi
f01011e7:	74 04                	je     f01011ed <mem_init+0x1c0>
f01011e9:	39 c7                	cmp    %eax,%edi
f01011eb:	75 19                	jne    f0101206 <mem_init+0x1d9>
f01011ed:	68 0c 3d 10 f0       	push   $0xf0103d0c
f01011f2:	68 1e 43 10 f0       	push   $0xf010431e
f01011f7:	68 6f 02 00 00       	push   $0x26f
f01011fc:	68 f8 42 10 f0       	push   $0xf01042f8
f0101201:	e8 85 ee ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101206:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f010120c:	8b 15 64 79 11 f0    	mov    0xf0117964,%edx
f0101212:	c1 e2 0c             	shl    $0xc,%edx
f0101215:	89 f8                	mov    %edi,%eax
f0101217:	29 c8                	sub    %ecx,%eax
f0101219:	c1 f8 03             	sar    $0x3,%eax
f010121c:	c1 e0 0c             	shl    $0xc,%eax
f010121f:	39 d0                	cmp    %edx,%eax
f0101221:	72 19                	jb     f010123c <mem_init+0x20f>
f0101223:	68 81 44 10 f0       	push   $0xf0104481
f0101228:	68 1e 43 10 f0       	push   $0xf010431e
f010122d:	68 70 02 00 00       	push   $0x270
f0101232:	68 f8 42 10 f0       	push   $0xf01042f8
f0101237:	e8 4f ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f010123c:	89 f0                	mov    %esi,%eax
f010123e:	29 c8                	sub    %ecx,%eax
f0101240:	c1 f8 03             	sar    $0x3,%eax
f0101243:	c1 e0 0c             	shl    $0xc,%eax
f0101246:	39 c2                	cmp    %eax,%edx
f0101248:	77 19                	ja     f0101263 <mem_init+0x236>
f010124a:	68 9e 44 10 f0       	push   $0xf010449e
f010124f:	68 1e 43 10 f0       	push   $0xf010431e
f0101254:	68 71 02 00 00       	push   $0x271
f0101259:	68 f8 42 10 f0       	push   $0xf01042f8
f010125e:	e8 28 ee ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101263:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101266:	29 c8                	sub    %ecx,%eax
f0101268:	c1 f8 03             	sar    $0x3,%eax
f010126b:	c1 e0 0c             	shl    $0xc,%eax
f010126e:	39 c2                	cmp    %eax,%edx
f0101270:	77 19                	ja     f010128b <mem_init+0x25e>
f0101272:	68 bb 44 10 f0       	push   $0xf01044bb
f0101277:	68 1e 43 10 f0       	push   $0xf010431e
f010127c:	68 72 02 00 00       	push   $0x272
f0101281:	68 f8 42 10 f0       	push   $0xf01042f8
f0101286:	e8 00 ee ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010128b:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101290:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101293:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f010129a:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010129d:	83 ec 0c             	sub    $0xc,%esp
f01012a0:	6a 00                	push   $0x0
f01012a2:	e8 b6 fa ff ff       	call   f0100d5d <page_alloc>
f01012a7:	83 c4 10             	add    $0x10,%esp
f01012aa:	85 c0                	test   %eax,%eax
f01012ac:	74 19                	je     f01012c7 <mem_init+0x29a>
f01012ae:	68 d8 44 10 f0       	push   $0xf01044d8
f01012b3:	68 1e 43 10 f0       	push   $0xf010431e
f01012b8:	68 79 02 00 00       	push   $0x279
f01012bd:	68 f8 42 10 f0       	push   $0xf01042f8
f01012c2:	e8 c4 ed ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f01012c7:	83 ec 0c             	sub    $0xc,%esp
f01012ca:	57                   	push   %edi
f01012cb:	e8 fd fa ff ff       	call   f0100dcd <page_free>
	page_free(pp1);
f01012d0:	89 34 24             	mov    %esi,(%esp)
f01012d3:	e8 f5 fa ff ff       	call   f0100dcd <page_free>
	page_free(pp2);
f01012d8:	83 c4 04             	add    $0x4,%esp
f01012db:	ff 75 d4             	pushl  -0x2c(%ebp)
f01012de:	e8 ea fa ff ff       	call   f0100dcd <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01012e3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012ea:	e8 6e fa ff ff       	call   f0100d5d <page_alloc>
f01012ef:	89 c6                	mov    %eax,%esi
f01012f1:	83 c4 10             	add    $0x10,%esp
f01012f4:	85 c0                	test   %eax,%eax
f01012f6:	75 19                	jne    f0101311 <mem_init+0x2e4>
f01012f8:	68 2d 44 10 f0       	push   $0xf010442d
f01012fd:	68 1e 43 10 f0       	push   $0xf010431e
f0101302:	68 80 02 00 00       	push   $0x280
f0101307:	68 f8 42 10 f0       	push   $0xf01042f8
f010130c:	e8 7a ed ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101311:	83 ec 0c             	sub    $0xc,%esp
f0101314:	6a 00                	push   $0x0
f0101316:	e8 42 fa ff ff       	call   f0100d5d <page_alloc>
f010131b:	89 c7                	mov    %eax,%edi
f010131d:	83 c4 10             	add    $0x10,%esp
f0101320:	85 c0                	test   %eax,%eax
f0101322:	75 19                	jne    f010133d <mem_init+0x310>
f0101324:	68 43 44 10 f0       	push   $0xf0104443
f0101329:	68 1e 43 10 f0       	push   $0xf010431e
f010132e:	68 81 02 00 00       	push   $0x281
f0101333:	68 f8 42 10 f0       	push   $0xf01042f8
f0101338:	e8 4e ed ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f010133d:	83 ec 0c             	sub    $0xc,%esp
f0101340:	6a 00                	push   $0x0
f0101342:	e8 16 fa ff ff       	call   f0100d5d <page_alloc>
f0101347:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010134a:	83 c4 10             	add    $0x10,%esp
f010134d:	85 c0                	test   %eax,%eax
f010134f:	75 19                	jne    f010136a <mem_init+0x33d>
f0101351:	68 59 44 10 f0       	push   $0xf0104459
f0101356:	68 1e 43 10 f0       	push   $0xf010431e
f010135b:	68 82 02 00 00       	push   $0x282
f0101360:	68 f8 42 10 f0       	push   $0xf01042f8
f0101365:	e8 21 ed ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010136a:	39 fe                	cmp    %edi,%esi
f010136c:	75 19                	jne    f0101387 <mem_init+0x35a>
f010136e:	68 6f 44 10 f0       	push   $0xf010446f
f0101373:	68 1e 43 10 f0       	push   $0xf010431e
f0101378:	68 84 02 00 00       	push   $0x284
f010137d:	68 f8 42 10 f0       	push   $0xf01042f8
f0101382:	e8 04 ed ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101387:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010138a:	39 c7                	cmp    %eax,%edi
f010138c:	74 04                	je     f0101392 <mem_init+0x365>
f010138e:	39 c6                	cmp    %eax,%esi
f0101390:	75 19                	jne    f01013ab <mem_init+0x37e>
f0101392:	68 0c 3d 10 f0       	push   $0xf0103d0c
f0101397:	68 1e 43 10 f0       	push   $0xf010431e
f010139c:	68 85 02 00 00       	push   $0x285
f01013a1:	68 f8 42 10 f0       	push   $0xf01042f8
f01013a6:	e8 e0 ec ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f01013ab:	83 ec 0c             	sub    $0xc,%esp
f01013ae:	6a 00                	push   $0x0
f01013b0:	e8 a8 f9 ff ff       	call   f0100d5d <page_alloc>
f01013b5:	83 c4 10             	add    $0x10,%esp
f01013b8:	85 c0                	test   %eax,%eax
f01013ba:	74 19                	je     f01013d5 <mem_init+0x3a8>
f01013bc:	68 d8 44 10 f0       	push   $0xf01044d8
f01013c1:	68 1e 43 10 f0       	push   $0xf010431e
f01013c6:	68 86 02 00 00       	push   $0x286
f01013cb:	68 f8 42 10 f0       	push   $0xf01042f8
f01013d0:	e8 b6 ec ff ff       	call   f010008b <_panic>
f01013d5:	89 f0                	mov    %esi,%eax
f01013d7:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01013dd:	c1 f8 03             	sar    $0x3,%eax
f01013e0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01013e3:	89 c2                	mov    %eax,%edx
f01013e5:	c1 ea 0c             	shr    $0xc,%edx
f01013e8:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01013ee:	72 12                	jb     f0101402 <mem_init+0x3d5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01013f0:	50                   	push   %eax
f01013f1:	68 a4 3b 10 f0       	push   $0xf0103ba4
f01013f6:	6a 52                	push   $0x52
f01013f8:	68 04 43 10 f0       	push   $0xf0104304
f01013fd:	e8 89 ec ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101402:	83 ec 04             	sub    $0x4,%esp
f0101405:	68 00 10 00 00       	push   $0x1000
f010140a:	6a 01                	push   $0x1
f010140c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101411:	50                   	push   %eax
f0101412:	e8 95 1d 00 00       	call   f01031ac <memset>
	page_free(pp0);
f0101417:	89 34 24             	mov    %esi,(%esp)
f010141a:	e8 ae f9 ff ff       	call   f0100dcd <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010141f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101426:	e8 32 f9 ff ff       	call   f0100d5d <page_alloc>
f010142b:	83 c4 10             	add    $0x10,%esp
f010142e:	85 c0                	test   %eax,%eax
f0101430:	75 19                	jne    f010144b <mem_init+0x41e>
f0101432:	68 e7 44 10 f0       	push   $0xf01044e7
f0101437:	68 1e 43 10 f0       	push   $0xf010431e
f010143c:	68 8b 02 00 00       	push   $0x28b
f0101441:	68 f8 42 10 f0       	push   $0xf01042f8
f0101446:	e8 40 ec ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f010144b:	39 c6                	cmp    %eax,%esi
f010144d:	74 19                	je     f0101468 <mem_init+0x43b>
f010144f:	68 05 45 10 f0       	push   $0xf0104505
f0101454:	68 1e 43 10 f0       	push   $0xf010431e
f0101459:	68 8c 02 00 00       	push   $0x28c
f010145e:	68 f8 42 10 f0       	push   $0xf01042f8
f0101463:	e8 23 ec ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101468:	89 f0                	mov    %esi,%eax
f010146a:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101470:	c1 f8 03             	sar    $0x3,%eax
f0101473:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101476:	89 c2                	mov    %eax,%edx
f0101478:	c1 ea 0c             	shr    $0xc,%edx
f010147b:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0101481:	72 12                	jb     f0101495 <mem_init+0x468>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101483:	50                   	push   %eax
f0101484:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0101489:	6a 52                	push   $0x52
f010148b:	68 04 43 10 f0       	push   $0xf0104304
f0101490:	e8 f6 eb ff ff       	call   f010008b <_panic>
f0101495:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010149b:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01014a1:	80 38 00             	cmpb   $0x0,(%eax)
f01014a4:	74 19                	je     f01014bf <mem_init+0x492>
f01014a6:	68 15 45 10 f0       	push   $0xf0104515
f01014ab:	68 1e 43 10 f0       	push   $0xf010431e
f01014b0:	68 8f 02 00 00       	push   $0x28f
f01014b5:	68 f8 42 10 f0       	push   $0xf01042f8
f01014ba:	e8 cc eb ff ff       	call   f010008b <_panic>
f01014bf:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01014c2:	39 d0                	cmp    %edx,%eax
f01014c4:	75 db                	jne    f01014a1 <mem_init+0x474>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01014c6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01014c9:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f01014ce:	83 ec 0c             	sub    $0xc,%esp
f01014d1:	56                   	push   %esi
f01014d2:	e8 f6 f8 ff ff       	call   f0100dcd <page_free>
	page_free(pp1);
f01014d7:	89 3c 24             	mov    %edi,(%esp)
f01014da:	e8 ee f8 ff ff       	call   f0100dcd <page_free>
	page_free(pp2);
f01014df:	83 c4 04             	add    $0x4,%esp
f01014e2:	ff 75 d4             	pushl  -0x2c(%ebp)
f01014e5:	e8 e3 f8 ff ff       	call   f0100dcd <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01014ea:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01014ef:	83 c4 10             	add    $0x10,%esp
f01014f2:	eb 05                	jmp    f01014f9 <mem_init+0x4cc>
		--nfree;
f01014f4:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01014f7:	8b 00                	mov    (%eax),%eax
f01014f9:	85 c0                	test   %eax,%eax
f01014fb:	75 f7                	jne    f01014f4 <mem_init+0x4c7>
		--nfree;
	assert(nfree == 0);
f01014fd:	85 db                	test   %ebx,%ebx
f01014ff:	74 19                	je     f010151a <mem_init+0x4ed>
f0101501:	68 1f 45 10 f0       	push   $0xf010451f
f0101506:	68 1e 43 10 f0       	push   $0xf010431e
f010150b:	68 9c 02 00 00       	push   $0x29c
f0101510:	68 f8 42 10 f0       	push   $0xf01042f8
f0101515:	e8 71 eb ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010151a:	83 ec 0c             	sub    $0xc,%esp
f010151d:	68 2c 3d 10 f0       	push   $0xf0103d2c
f0101522:	e8 dc 11 00 00       	call   f0102703 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101527:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010152e:	e8 2a f8 ff ff       	call   f0100d5d <page_alloc>
f0101533:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101536:	83 c4 10             	add    $0x10,%esp
f0101539:	85 c0                	test   %eax,%eax
f010153b:	75 19                	jne    f0101556 <mem_init+0x529>
f010153d:	68 2d 44 10 f0       	push   $0xf010442d
f0101542:	68 1e 43 10 f0       	push   $0xf010431e
f0101547:	68 f5 02 00 00       	push   $0x2f5
f010154c:	68 f8 42 10 f0       	push   $0xf01042f8
f0101551:	e8 35 eb ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0101556:	83 ec 0c             	sub    $0xc,%esp
f0101559:	6a 00                	push   $0x0
f010155b:	e8 fd f7 ff ff       	call   f0100d5d <page_alloc>
f0101560:	89 c3                	mov    %eax,%ebx
f0101562:	83 c4 10             	add    $0x10,%esp
f0101565:	85 c0                	test   %eax,%eax
f0101567:	75 19                	jne    f0101582 <mem_init+0x555>
f0101569:	68 43 44 10 f0       	push   $0xf0104443
f010156e:	68 1e 43 10 f0       	push   $0xf010431e
f0101573:	68 f6 02 00 00       	push   $0x2f6
f0101578:	68 f8 42 10 f0       	push   $0xf01042f8
f010157d:	e8 09 eb ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101582:	83 ec 0c             	sub    $0xc,%esp
f0101585:	6a 00                	push   $0x0
f0101587:	e8 d1 f7 ff ff       	call   f0100d5d <page_alloc>
f010158c:	89 c6                	mov    %eax,%esi
f010158e:	83 c4 10             	add    $0x10,%esp
f0101591:	85 c0                	test   %eax,%eax
f0101593:	75 19                	jne    f01015ae <mem_init+0x581>
f0101595:	68 59 44 10 f0       	push   $0xf0104459
f010159a:	68 1e 43 10 f0       	push   $0xf010431e
f010159f:	68 f7 02 00 00       	push   $0x2f7
f01015a4:	68 f8 42 10 f0       	push   $0xf01042f8
f01015a9:	e8 dd ea ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015ae:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01015b1:	75 19                	jne    f01015cc <mem_init+0x59f>
f01015b3:	68 6f 44 10 f0       	push   $0xf010446f
f01015b8:	68 1e 43 10 f0       	push   $0xf010431e
f01015bd:	68 fa 02 00 00       	push   $0x2fa
f01015c2:	68 f8 42 10 f0       	push   $0xf01042f8
f01015c7:	e8 bf ea ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015cc:	39 c3                	cmp    %eax,%ebx
f01015ce:	74 05                	je     f01015d5 <mem_init+0x5a8>
f01015d0:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01015d3:	75 19                	jne    f01015ee <mem_init+0x5c1>
f01015d5:	68 0c 3d 10 f0       	push   $0xf0103d0c
f01015da:	68 1e 43 10 f0       	push   $0xf010431e
f01015df:	68 fb 02 00 00       	push   $0x2fb
f01015e4:	68 f8 42 10 f0       	push   $0xf01042f8
f01015e9:	e8 9d ea ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01015ee:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01015f3:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01015f6:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f01015fd:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101600:	83 ec 0c             	sub    $0xc,%esp
f0101603:	6a 00                	push   $0x0
f0101605:	e8 53 f7 ff ff       	call   f0100d5d <page_alloc>
f010160a:	83 c4 10             	add    $0x10,%esp
f010160d:	85 c0                	test   %eax,%eax
f010160f:	74 19                	je     f010162a <mem_init+0x5fd>
f0101611:	68 d8 44 10 f0       	push   $0xf01044d8
f0101616:	68 1e 43 10 f0       	push   $0xf010431e
f010161b:	68 02 03 00 00       	push   $0x302
f0101620:	68 f8 42 10 f0       	push   $0xf01042f8
f0101625:	e8 61 ea ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010162a:	83 ec 04             	sub    $0x4,%esp
f010162d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101630:	50                   	push   %eax
f0101631:	6a 00                	push   $0x0
f0101633:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101639:	e8 cf f8 ff ff       	call   f0100f0d <page_lookup>
f010163e:	83 c4 10             	add    $0x10,%esp
f0101641:	85 c0                	test   %eax,%eax
f0101643:	74 19                	je     f010165e <mem_init+0x631>
f0101645:	68 4c 3d 10 f0       	push   $0xf0103d4c
f010164a:	68 1e 43 10 f0       	push   $0xf010431e
f010164f:	68 05 03 00 00       	push   $0x305
f0101654:	68 f8 42 10 f0       	push   $0xf01042f8
f0101659:	e8 2d ea ff ff       	call   f010008b <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010165e:	6a 02                	push   $0x2
f0101660:	6a 00                	push   $0x0
f0101662:	53                   	push   %ebx
f0101663:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101669:	e8 59 f9 ff ff       	call   f0100fc7 <page_insert>
f010166e:	83 c4 10             	add    $0x10,%esp
f0101671:	85 c0                	test   %eax,%eax
f0101673:	78 19                	js     f010168e <mem_init+0x661>
f0101675:	68 84 3d 10 f0       	push   $0xf0103d84
f010167a:	68 1e 43 10 f0       	push   $0xf010431e
f010167f:	68 08 03 00 00       	push   $0x308
f0101684:	68 f8 42 10 f0       	push   $0xf01042f8
f0101689:	e8 fd e9 ff ff       	call   f010008b <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f010168e:	83 ec 0c             	sub    $0xc,%esp
f0101691:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101694:	e8 34 f7 ff ff       	call   f0100dcd <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101699:	6a 02                	push   $0x2
f010169b:	6a 00                	push   $0x0
f010169d:	53                   	push   %ebx
f010169e:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01016a4:	e8 1e f9 ff ff       	call   f0100fc7 <page_insert>
f01016a9:	83 c4 20             	add    $0x20,%esp
f01016ac:	85 c0                	test   %eax,%eax
f01016ae:	74 19                	je     f01016c9 <mem_init+0x69c>
f01016b0:	68 b4 3d 10 f0       	push   $0xf0103db4
f01016b5:	68 1e 43 10 f0       	push   $0xf010431e
f01016ba:	68 0c 03 00 00       	push   $0x30c
f01016bf:	68 f8 42 10 f0       	push   $0xf01042f8
f01016c4:	e8 c2 e9 ff ff       	call   f010008b <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01016c9:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01016cf:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f01016d4:	89 c1                	mov    %eax,%ecx
f01016d6:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01016d9:	8b 17                	mov    (%edi),%edx
f01016db:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01016e1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016e4:	29 c8                	sub    %ecx,%eax
f01016e6:	c1 f8 03             	sar    $0x3,%eax
f01016e9:	c1 e0 0c             	shl    $0xc,%eax
f01016ec:	39 c2                	cmp    %eax,%edx
f01016ee:	74 19                	je     f0101709 <mem_init+0x6dc>
f01016f0:	68 e4 3d 10 f0       	push   $0xf0103de4
f01016f5:	68 1e 43 10 f0       	push   $0xf010431e
f01016fa:	68 0d 03 00 00       	push   $0x30d
f01016ff:	68 f8 42 10 f0       	push   $0xf01042f8
f0101704:	e8 82 e9 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101709:	ba 00 00 00 00       	mov    $0x0,%edx
f010170e:	89 f8                	mov    %edi,%eax
f0101710:	e8 5d f2 ff ff       	call   f0100972 <check_va2pa>
f0101715:	89 da                	mov    %ebx,%edx
f0101717:	2b 55 cc             	sub    -0x34(%ebp),%edx
f010171a:	c1 fa 03             	sar    $0x3,%edx
f010171d:	c1 e2 0c             	shl    $0xc,%edx
f0101720:	39 d0                	cmp    %edx,%eax
f0101722:	74 19                	je     f010173d <mem_init+0x710>
f0101724:	68 0c 3e 10 f0       	push   $0xf0103e0c
f0101729:	68 1e 43 10 f0       	push   $0xf010431e
f010172e:	68 0e 03 00 00       	push   $0x30e
f0101733:	68 f8 42 10 f0       	push   $0xf01042f8
f0101738:	e8 4e e9 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f010173d:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101742:	74 19                	je     f010175d <mem_init+0x730>
f0101744:	68 2a 45 10 f0       	push   $0xf010452a
f0101749:	68 1e 43 10 f0       	push   $0xf010431e
f010174e:	68 0f 03 00 00       	push   $0x30f
f0101753:	68 f8 42 10 f0       	push   $0xf01042f8
f0101758:	e8 2e e9 ff ff       	call   f010008b <_panic>
	assert(pp0->pp_ref == 1);
f010175d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101760:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101765:	74 19                	je     f0101780 <mem_init+0x753>
f0101767:	68 3b 45 10 f0       	push   $0xf010453b
f010176c:	68 1e 43 10 f0       	push   $0xf010431e
f0101771:	68 10 03 00 00       	push   $0x310
f0101776:	68 f8 42 10 f0       	push   $0xf01042f8
f010177b:	e8 0b e9 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101780:	6a 02                	push   $0x2
f0101782:	68 00 10 00 00       	push   $0x1000
f0101787:	56                   	push   %esi
f0101788:	57                   	push   %edi
f0101789:	e8 39 f8 ff ff       	call   f0100fc7 <page_insert>
f010178e:	83 c4 10             	add    $0x10,%esp
f0101791:	85 c0                	test   %eax,%eax
f0101793:	74 19                	je     f01017ae <mem_init+0x781>
f0101795:	68 3c 3e 10 f0       	push   $0xf0103e3c
f010179a:	68 1e 43 10 f0       	push   $0xf010431e
f010179f:	68 13 03 00 00       	push   $0x313
f01017a4:	68 f8 42 10 f0       	push   $0xf01042f8
f01017a9:	e8 dd e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01017ae:	ba 00 10 00 00       	mov    $0x1000,%edx
f01017b3:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01017b8:	e8 b5 f1 ff ff       	call   f0100972 <check_va2pa>
f01017bd:	89 f2                	mov    %esi,%edx
f01017bf:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01017c5:	c1 fa 03             	sar    $0x3,%edx
f01017c8:	c1 e2 0c             	shl    $0xc,%edx
f01017cb:	39 d0                	cmp    %edx,%eax
f01017cd:	74 19                	je     f01017e8 <mem_init+0x7bb>
f01017cf:	68 78 3e 10 f0       	push   $0xf0103e78
f01017d4:	68 1e 43 10 f0       	push   $0xf010431e
f01017d9:	68 14 03 00 00       	push   $0x314
f01017de:	68 f8 42 10 f0       	push   $0xf01042f8
f01017e3:	e8 a3 e8 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01017e8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01017ed:	74 19                	je     f0101808 <mem_init+0x7db>
f01017ef:	68 4c 45 10 f0       	push   $0xf010454c
f01017f4:	68 1e 43 10 f0       	push   $0xf010431e
f01017f9:	68 15 03 00 00       	push   $0x315
f01017fe:	68 f8 42 10 f0       	push   $0xf01042f8
f0101803:	e8 83 e8 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101808:	83 ec 0c             	sub    $0xc,%esp
f010180b:	6a 00                	push   $0x0
f010180d:	e8 4b f5 ff ff       	call   f0100d5d <page_alloc>
f0101812:	83 c4 10             	add    $0x10,%esp
f0101815:	85 c0                	test   %eax,%eax
f0101817:	74 19                	je     f0101832 <mem_init+0x805>
f0101819:	68 d8 44 10 f0       	push   $0xf01044d8
f010181e:	68 1e 43 10 f0       	push   $0xf010431e
f0101823:	68 18 03 00 00       	push   $0x318
f0101828:	68 f8 42 10 f0       	push   $0xf01042f8
f010182d:	e8 59 e8 ff ff       	call   f010008b <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101832:	6a 02                	push   $0x2
f0101834:	68 00 10 00 00       	push   $0x1000
f0101839:	56                   	push   %esi
f010183a:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101840:	e8 82 f7 ff ff       	call   f0100fc7 <page_insert>
f0101845:	83 c4 10             	add    $0x10,%esp
f0101848:	85 c0                	test   %eax,%eax
f010184a:	74 19                	je     f0101865 <mem_init+0x838>
f010184c:	68 3c 3e 10 f0       	push   $0xf0103e3c
f0101851:	68 1e 43 10 f0       	push   $0xf010431e
f0101856:	68 1b 03 00 00       	push   $0x31b
f010185b:	68 f8 42 10 f0       	push   $0xf01042f8
f0101860:	e8 26 e8 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101865:	ba 00 10 00 00       	mov    $0x1000,%edx
f010186a:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010186f:	e8 fe f0 ff ff       	call   f0100972 <check_va2pa>
f0101874:	89 f2                	mov    %esi,%edx
f0101876:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f010187c:	c1 fa 03             	sar    $0x3,%edx
f010187f:	c1 e2 0c             	shl    $0xc,%edx
f0101882:	39 d0                	cmp    %edx,%eax
f0101884:	74 19                	je     f010189f <mem_init+0x872>
f0101886:	68 78 3e 10 f0       	push   $0xf0103e78
f010188b:	68 1e 43 10 f0       	push   $0xf010431e
f0101890:	68 1c 03 00 00       	push   $0x31c
f0101895:	68 f8 42 10 f0       	push   $0xf01042f8
f010189a:	e8 ec e7 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010189f:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01018a4:	74 19                	je     f01018bf <mem_init+0x892>
f01018a6:	68 4c 45 10 f0       	push   $0xf010454c
f01018ab:	68 1e 43 10 f0       	push   $0xf010431e
f01018b0:	68 1d 03 00 00       	push   $0x31d
f01018b5:	68 f8 42 10 f0       	push   $0xf01042f8
f01018ba:	e8 cc e7 ff ff       	call   f010008b <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01018bf:	83 ec 0c             	sub    $0xc,%esp
f01018c2:	6a 00                	push   $0x0
f01018c4:	e8 94 f4 ff ff       	call   f0100d5d <page_alloc>
f01018c9:	83 c4 10             	add    $0x10,%esp
f01018cc:	85 c0                	test   %eax,%eax
f01018ce:	74 19                	je     f01018e9 <mem_init+0x8bc>
f01018d0:	68 d8 44 10 f0       	push   $0xf01044d8
f01018d5:	68 1e 43 10 f0       	push   $0xf010431e
f01018da:	68 21 03 00 00       	push   $0x321
f01018df:	68 f8 42 10 f0       	push   $0xf01042f8
f01018e4:	e8 a2 e7 ff ff       	call   f010008b <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01018e9:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f01018ef:	8b 02                	mov    (%edx),%eax
f01018f1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01018f6:	89 c1                	mov    %eax,%ecx
f01018f8:	c1 e9 0c             	shr    $0xc,%ecx
f01018fb:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0101901:	72 15                	jb     f0101918 <mem_init+0x8eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101903:	50                   	push   %eax
f0101904:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0101909:	68 24 03 00 00       	push   $0x324
f010190e:	68 f8 42 10 f0       	push   $0xf01042f8
f0101913:	e8 73 e7 ff ff       	call   f010008b <_panic>
f0101918:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010191d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101920:	83 ec 04             	sub    $0x4,%esp
f0101923:	6a 00                	push   $0x0
f0101925:	68 00 10 00 00       	push   $0x1000
f010192a:	52                   	push   %edx
f010192b:	e8 d3 f4 ff ff       	call   f0100e03 <pgdir_walk>
f0101930:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101933:	8d 51 04             	lea    0x4(%ecx),%edx
f0101936:	83 c4 10             	add    $0x10,%esp
f0101939:	39 d0                	cmp    %edx,%eax
f010193b:	74 19                	je     f0101956 <mem_init+0x929>
f010193d:	68 a8 3e 10 f0       	push   $0xf0103ea8
f0101942:	68 1e 43 10 f0       	push   $0xf010431e
f0101947:	68 25 03 00 00       	push   $0x325
f010194c:	68 f8 42 10 f0       	push   $0xf01042f8
f0101951:	e8 35 e7 ff ff       	call   f010008b <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101956:	6a 06                	push   $0x6
f0101958:	68 00 10 00 00       	push   $0x1000
f010195d:	56                   	push   %esi
f010195e:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101964:	e8 5e f6 ff ff       	call   f0100fc7 <page_insert>
f0101969:	83 c4 10             	add    $0x10,%esp
f010196c:	85 c0                	test   %eax,%eax
f010196e:	74 19                	je     f0101989 <mem_init+0x95c>
f0101970:	68 e8 3e 10 f0       	push   $0xf0103ee8
f0101975:	68 1e 43 10 f0       	push   $0xf010431e
f010197a:	68 28 03 00 00       	push   $0x328
f010197f:	68 f8 42 10 f0       	push   $0xf01042f8
f0101984:	e8 02 e7 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101989:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f010198f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101994:	89 f8                	mov    %edi,%eax
f0101996:	e8 d7 ef ff ff       	call   f0100972 <check_va2pa>
f010199b:	89 f2                	mov    %esi,%edx
f010199d:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01019a3:	c1 fa 03             	sar    $0x3,%edx
f01019a6:	c1 e2 0c             	shl    $0xc,%edx
f01019a9:	39 d0                	cmp    %edx,%eax
f01019ab:	74 19                	je     f01019c6 <mem_init+0x999>
f01019ad:	68 78 3e 10 f0       	push   $0xf0103e78
f01019b2:	68 1e 43 10 f0       	push   $0xf010431e
f01019b7:	68 29 03 00 00       	push   $0x329
f01019bc:	68 f8 42 10 f0       	push   $0xf01042f8
f01019c1:	e8 c5 e6 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f01019c6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019cb:	74 19                	je     f01019e6 <mem_init+0x9b9>
f01019cd:	68 4c 45 10 f0       	push   $0xf010454c
f01019d2:	68 1e 43 10 f0       	push   $0xf010431e
f01019d7:	68 2a 03 00 00       	push   $0x32a
f01019dc:	68 f8 42 10 f0       	push   $0xf01042f8
f01019e1:	e8 a5 e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01019e6:	83 ec 04             	sub    $0x4,%esp
f01019e9:	6a 00                	push   $0x0
f01019eb:	68 00 10 00 00       	push   $0x1000
f01019f0:	57                   	push   %edi
f01019f1:	e8 0d f4 ff ff       	call   f0100e03 <pgdir_walk>
f01019f6:	83 c4 10             	add    $0x10,%esp
f01019f9:	f6 00 04             	testb  $0x4,(%eax)
f01019fc:	75 19                	jne    f0101a17 <mem_init+0x9ea>
f01019fe:	68 28 3f 10 f0       	push   $0xf0103f28
f0101a03:	68 1e 43 10 f0       	push   $0xf010431e
f0101a08:	68 2b 03 00 00       	push   $0x32b
f0101a0d:	68 f8 42 10 f0       	push   $0xf01042f8
f0101a12:	e8 74 e6 ff ff       	call   f010008b <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101a17:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101a1c:	f6 00 04             	testb  $0x4,(%eax)
f0101a1f:	75 19                	jne    f0101a3a <mem_init+0xa0d>
f0101a21:	68 5d 45 10 f0       	push   $0xf010455d
f0101a26:	68 1e 43 10 f0       	push   $0xf010431e
f0101a2b:	68 2c 03 00 00       	push   $0x32c
f0101a30:	68 f8 42 10 f0       	push   $0xf01042f8
f0101a35:	e8 51 e6 ff ff       	call   f010008b <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a3a:	6a 02                	push   $0x2
f0101a3c:	68 00 10 00 00       	push   $0x1000
f0101a41:	56                   	push   %esi
f0101a42:	50                   	push   %eax
f0101a43:	e8 7f f5 ff ff       	call   f0100fc7 <page_insert>
f0101a48:	83 c4 10             	add    $0x10,%esp
f0101a4b:	85 c0                	test   %eax,%eax
f0101a4d:	74 19                	je     f0101a68 <mem_init+0xa3b>
f0101a4f:	68 3c 3e 10 f0       	push   $0xf0103e3c
f0101a54:	68 1e 43 10 f0       	push   $0xf010431e
f0101a59:	68 2f 03 00 00       	push   $0x32f
f0101a5e:	68 f8 42 10 f0       	push   $0xf01042f8
f0101a63:	e8 23 e6 ff ff       	call   f010008b <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101a68:	83 ec 04             	sub    $0x4,%esp
f0101a6b:	6a 00                	push   $0x0
f0101a6d:	68 00 10 00 00       	push   $0x1000
f0101a72:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101a78:	e8 86 f3 ff ff       	call   f0100e03 <pgdir_walk>
f0101a7d:	83 c4 10             	add    $0x10,%esp
f0101a80:	f6 00 02             	testb  $0x2,(%eax)
f0101a83:	75 19                	jne    f0101a9e <mem_init+0xa71>
f0101a85:	68 5c 3f 10 f0       	push   $0xf0103f5c
f0101a8a:	68 1e 43 10 f0       	push   $0xf010431e
f0101a8f:	68 30 03 00 00       	push   $0x330
f0101a94:	68 f8 42 10 f0       	push   $0xf01042f8
f0101a99:	e8 ed e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101a9e:	83 ec 04             	sub    $0x4,%esp
f0101aa1:	6a 00                	push   $0x0
f0101aa3:	68 00 10 00 00       	push   $0x1000
f0101aa8:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101aae:	e8 50 f3 ff ff       	call   f0100e03 <pgdir_walk>
f0101ab3:	83 c4 10             	add    $0x10,%esp
f0101ab6:	f6 00 04             	testb  $0x4,(%eax)
f0101ab9:	74 19                	je     f0101ad4 <mem_init+0xaa7>
f0101abb:	68 90 3f 10 f0       	push   $0xf0103f90
f0101ac0:	68 1e 43 10 f0       	push   $0xf010431e
f0101ac5:	68 31 03 00 00       	push   $0x331
f0101aca:	68 f8 42 10 f0       	push   $0xf01042f8
f0101acf:	e8 b7 e5 ff ff       	call   f010008b <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101ad4:	6a 02                	push   $0x2
f0101ad6:	68 00 00 40 00       	push   $0x400000
f0101adb:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101ade:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101ae4:	e8 de f4 ff ff       	call   f0100fc7 <page_insert>
f0101ae9:	83 c4 10             	add    $0x10,%esp
f0101aec:	85 c0                	test   %eax,%eax
f0101aee:	78 19                	js     f0101b09 <mem_init+0xadc>
f0101af0:	68 c8 3f 10 f0       	push   $0xf0103fc8
f0101af5:	68 1e 43 10 f0       	push   $0xf010431e
f0101afa:	68 34 03 00 00       	push   $0x334
f0101aff:	68 f8 42 10 f0       	push   $0xf01042f8
f0101b04:	e8 82 e5 ff ff       	call   f010008b <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101b09:	6a 02                	push   $0x2
f0101b0b:	68 00 10 00 00       	push   $0x1000
f0101b10:	53                   	push   %ebx
f0101b11:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101b17:	e8 ab f4 ff ff       	call   f0100fc7 <page_insert>
f0101b1c:	83 c4 10             	add    $0x10,%esp
f0101b1f:	85 c0                	test   %eax,%eax
f0101b21:	74 19                	je     f0101b3c <mem_init+0xb0f>
f0101b23:	68 00 40 10 f0       	push   $0xf0104000
f0101b28:	68 1e 43 10 f0       	push   $0xf010431e
f0101b2d:	68 37 03 00 00       	push   $0x337
f0101b32:	68 f8 42 10 f0       	push   $0xf01042f8
f0101b37:	e8 4f e5 ff ff       	call   f010008b <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101b3c:	83 ec 04             	sub    $0x4,%esp
f0101b3f:	6a 00                	push   $0x0
f0101b41:	68 00 10 00 00       	push   $0x1000
f0101b46:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101b4c:	e8 b2 f2 ff ff       	call   f0100e03 <pgdir_walk>
f0101b51:	83 c4 10             	add    $0x10,%esp
f0101b54:	f6 00 04             	testb  $0x4,(%eax)
f0101b57:	74 19                	je     f0101b72 <mem_init+0xb45>
f0101b59:	68 90 3f 10 f0       	push   $0xf0103f90
f0101b5e:	68 1e 43 10 f0       	push   $0xf010431e
f0101b63:	68 38 03 00 00       	push   $0x338
f0101b68:	68 f8 42 10 f0       	push   $0xf01042f8
f0101b6d:	e8 19 e5 ff ff       	call   f010008b <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101b72:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101b78:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b7d:	89 f8                	mov    %edi,%eax
f0101b7f:	e8 ee ed ff ff       	call   f0100972 <check_va2pa>
f0101b84:	89 c1                	mov    %eax,%ecx
f0101b86:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101b89:	89 d8                	mov    %ebx,%eax
f0101b8b:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101b91:	c1 f8 03             	sar    $0x3,%eax
f0101b94:	c1 e0 0c             	shl    $0xc,%eax
f0101b97:	39 c1                	cmp    %eax,%ecx
f0101b99:	74 19                	je     f0101bb4 <mem_init+0xb87>
f0101b9b:	68 3c 40 10 f0       	push   $0xf010403c
f0101ba0:	68 1e 43 10 f0       	push   $0xf010431e
f0101ba5:	68 3b 03 00 00       	push   $0x33b
f0101baa:	68 f8 42 10 f0       	push   $0xf01042f8
f0101baf:	e8 d7 e4 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101bb4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bb9:	89 f8                	mov    %edi,%eax
f0101bbb:	e8 b2 ed ff ff       	call   f0100972 <check_va2pa>
f0101bc0:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101bc3:	74 19                	je     f0101bde <mem_init+0xbb1>
f0101bc5:	68 68 40 10 f0       	push   $0xf0104068
f0101bca:	68 1e 43 10 f0       	push   $0xf010431e
f0101bcf:	68 3c 03 00 00       	push   $0x33c
f0101bd4:	68 f8 42 10 f0       	push   $0xf01042f8
f0101bd9:	e8 ad e4 ff ff       	call   f010008b <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101bde:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101be3:	74 19                	je     f0101bfe <mem_init+0xbd1>
f0101be5:	68 73 45 10 f0       	push   $0xf0104573
f0101bea:	68 1e 43 10 f0       	push   $0xf010431e
f0101bef:	68 3e 03 00 00       	push   $0x33e
f0101bf4:	68 f8 42 10 f0       	push   $0xf01042f8
f0101bf9:	e8 8d e4 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101bfe:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101c03:	74 19                	je     f0101c1e <mem_init+0xbf1>
f0101c05:	68 84 45 10 f0       	push   $0xf0104584
f0101c0a:	68 1e 43 10 f0       	push   $0xf010431e
f0101c0f:	68 3f 03 00 00       	push   $0x33f
f0101c14:	68 f8 42 10 f0       	push   $0xf01042f8
f0101c19:	e8 6d e4 ff ff       	call   f010008b <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101c1e:	83 ec 0c             	sub    $0xc,%esp
f0101c21:	6a 00                	push   $0x0
f0101c23:	e8 35 f1 ff ff       	call   f0100d5d <page_alloc>
f0101c28:	83 c4 10             	add    $0x10,%esp
f0101c2b:	85 c0                	test   %eax,%eax
f0101c2d:	74 04                	je     f0101c33 <mem_init+0xc06>
f0101c2f:	39 c6                	cmp    %eax,%esi
f0101c31:	74 19                	je     f0101c4c <mem_init+0xc1f>
f0101c33:	68 98 40 10 f0       	push   $0xf0104098
f0101c38:	68 1e 43 10 f0       	push   $0xf010431e
f0101c3d:	68 42 03 00 00       	push   $0x342
f0101c42:	68 f8 42 10 f0       	push   $0xf01042f8
f0101c47:	e8 3f e4 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101c4c:	83 ec 08             	sub    $0x8,%esp
f0101c4f:	6a 00                	push   $0x0
f0101c51:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101c57:	e8 16 f3 ff ff       	call   f0100f72 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101c5c:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101c62:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c67:	89 f8                	mov    %edi,%eax
f0101c69:	e8 04 ed ff ff       	call   f0100972 <check_va2pa>
f0101c6e:	83 c4 10             	add    $0x10,%esp
f0101c71:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101c74:	74 19                	je     f0101c8f <mem_init+0xc62>
f0101c76:	68 bc 40 10 f0       	push   $0xf01040bc
f0101c7b:	68 1e 43 10 f0       	push   $0xf010431e
f0101c80:	68 46 03 00 00       	push   $0x346
f0101c85:	68 f8 42 10 f0       	push   $0xf01042f8
f0101c8a:	e8 fc e3 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101c8f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c94:	89 f8                	mov    %edi,%eax
f0101c96:	e8 d7 ec ff ff       	call   f0100972 <check_va2pa>
f0101c9b:	89 da                	mov    %ebx,%edx
f0101c9d:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101ca3:	c1 fa 03             	sar    $0x3,%edx
f0101ca6:	c1 e2 0c             	shl    $0xc,%edx
f0101ca9:	39 d0                	cmp    %edx,%eax
f0101cab:	74 19                	je     f0101cc6 <mem_init+0xc99>
f0101cad:	68 68 40 10 f0       	push   $0xf0104068
f0101cb2:	68 1e 43 10 f0       	push   $0xf010431e
f0101cb7:	68 47 03 00 00       	push   $0x347
f0101cbc:	68 f8 42 10 f0       	push   $0xf01042f8
f0101cc1:	e8 c5 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 1);
f0101cc6:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ccb:	74 19                	je     f0101ce6 <mem_init+0xcb9>
f0101ccd:	68 2a 45 10 f0       	push   $0xf010452a
f0101cd2:	68 1e 43 10 f0       	push   $0xf010431e
f0101cd7:	68 48 03 00 00       	push   $0x348
f0101cdc:	68 f8 42 10 f0       	push   $0xf01042f8
f0101ce1:	e8 a5 e3 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101ce6:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101ceb:	74 19                	je     f0101d06 <mem_init+0xcd9>
f0101ced:	68 84 45 10 f0       	push   $0xf0104584
f0101cf2:	68 1e 43 10 f0       	push   $0xf010431e
f0101cf7:	68 49 03 00 00       	push   $0x349
f0101cfc:	68 f8 42 10 f0       	push   $0xf01042f8
f0101d01:	e8 85 e3 ff ff       	call   f010008b <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d06:	6a 00                	push   $0x0
f0101d08:	68 00 10 00 00       	push   $0x1000
f0101d0d:	53                   	push   %ebx
f0101d0e:	57                   	push   %edi
f0101d0f:	e8 b3 f2 ff ff       	call   f0100fc7 <page_insert>
f0101d14:	83 c4 10             	add    $0x10,%esp
f0101d17:	85 c0                	test   %eax,%eax
f0101d19:	74 19                	je     f0101d34 <mem_init+0xd07>
f0101d1b:	68 e0 40 10 f0       	push   $0xf01040e0
f0101d20:	68 1e 43 10 f0       	push   $0xf010431e
f0101d25:	68 4c 03 00 00       	push   $0x34c
f0101d2a:	68 f8 42 10 f0       	push   $0xf01042f8
f0101d2f:	e8 57 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref);
f0101d34:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101d39:	75 19                	jne    f0101d54 <mem_init+0xd27>
f0101d3b:	68 95 45 10 f0       	push   $0xf0104595
f0101d40:	68 1e 43 10 f0       	push   $0xf010431e
f0101d45:	68 4d 03 00 00       	push   $0x34d
f0101d4a:	68 f8 42 10 f0       	push   $0xf01042f8
f0101d4f:	e8 37 e3 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_link == NULL);
f0101d54:	83 3b 00             	cmpl   $0x0,(%ebx)
f0101d57:	74 19                	je     f0101d72 <mem_init+0xd45>
f0101d59:	68 a1 45 10 f0       	push   $0xf01045a1
f0101d5e:	68 1e 43 10 f0       	push   $0xf010431e
f0101d63:	68 4e 03 00 00       	push   $0x34e
f0101d68:	68 f8 42 10 f0       	push   $0xf01042f8
f0101d6d:	e8 19 e3 ff ff       	call   f010008b <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101d72:	83 ec 08             	sub    $0x8,%esp
f0101d75:	68 00 10 00 00       	push   $0x1000
f0101d7a:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101d80:	e8 ed f1 ff ff       	call   f0100f72 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101d85:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101d8b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d90:	89 f8                	mov    %edi,%eax
f0101d92:	e8 db eb ff ff       	call   f0100972 <check_va2pa>
f0101d97:	83 c4 10             	add    $0x10,%esp
f0101d9a:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101d9d:	74 19                	je     f0101db8 <mem_init+0xd8b>
f0101d9f:	68 bc 40 10 f0       	push   $0xf01040bc
f0101da4:	68 1e 43 10 f0       	push   $0xf010431e
f0101da9:	68 52 03 00 00       	push   $0x352
f0101dae:	68 f8 42 10 f0       	push   $0xf01042f8
f0101db3:	e8 d3 e2 ff ff       	call   f010008b <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101db8:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dbd:	89 f8                	mov    %edi,%eax
f0101dbf:	e8 ae eb ff ff       	call   f0100972 <check_va2pa>
f0101dc4:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101dc7:	74 19                	je     f0101de2 <mem_init+0xdb5>
f0101dc9:	68 18 41 10 f0       	push   $0xf0104118
f0101dce:	68 1e 43 10 f0       	push   $0xf010431e
f0101dd3:	68 53 03 00 00       	push   $0x353
f0101dd8:	68 f8 42 10 f0       	push   $0xf01042f8
f0101ddd:	e8 a9 e2 ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f0101de2:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0101de7:	74 19                	je     f0101e02 <mem_init+0xdd5>
f0101de9:	68 b6 45 10 f0       	push   $0xf01045b6
f0101dee:	68 1e 43 10 f0       	push   $0xf010431e
f0101df3:	68 54 03 00 00       	push   $0x354
f0101df8:	68 f8 42 10 f0       	push   $0xf01042f8
f0101dfd:	e8 89 e2 ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 0);
f0101e02:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0101e07:	74 19                	je     f0101e22 <mem_init+0xdf5>
f0101e09:	68 84 45 10 f0       	push   $0xf0104584
f0101e0e:	68 1e 43 10 f0       	push   $0xf010431e
f0101e13:	68 55 03 00 00       	push   $0x355
f0101e18:	68 f8 42 10 f0       	push   $0xf01042f8
f0101e1d:	e8 69 e2 ff ff       	call   f010008b <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101e22:	83 ec 0c             	sub    $0xc,%esp
f0101e25:	6a 00                	push   $0x0
f0101e27:	e8 31 ef ff ff       	call   f0100d5d <page_alloc>
f0101e2c:	83 c4 10             	add    $0x10,%esp
f0101e2f:	39 c3                	cmp    %eax,%ebx
f0101e31:	75 04                	jne    f0101e37 <mem_init+0xe0a>
f0101e33:	85 c0                	test   %eax,%eax
f0101e35:	75 19                	jne    f0101e50 <mem_init+0xe23>
f0101e37:	68 40 41 10 f0       	push   $0xf0104140
f0101e3c:	68 1e 43 10 f0       	push   $0xf010431e
f0101e41:	68 58 03 00 00       	push   $0x358
f0101e46:	68 f8 42 10 f0       	push   $0xf01042f8
f0101e4b:	e8 3b e2 ff ff       	call   f010008b <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101e50:	83 ec 0c             	sub    $0xc,%esp
f0101e53:	6a 00                	push   $0x0
f0101e55:	e8 03 ef ff ff       	call   f0100d5d <page_alloc>
f0101e5a:	83 c4 10             	add    $0x10,%esp
f0101e5d:	85 c0                	test   %eax,%eax
f0101e5f:	74 19                	je     f0101e7a <mem_init+0xe4d>
f0101e61:	68 d8 44 10 f0       	push   $0xf01044d8
f0101e66:	68 1e 43 10 f0       	push   $0xf010431e
f0101e6b:	68 5b 03 00 00       	push   $0x35b
f0101e70:	68 f8 42 10 f0       	push   $0xf01042f8
f0101e75:	e8 11 e2 ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e7a:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f0101e80:	8b 11                	mov    (%ecx),%edx
f0101e82:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101e88:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e8b:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101e91:	c1 f8 03             	sar    $0x3,%eax
f0101e94:	c1 e0 0c             	shl    $0xc,%eax
f0101e97:	39 c2                	cmp    %eax,%edx
f0101e99:	74 19                	je     f0101eb4 <mem_init+0xe87>
f0101e9b:	68 e4 3d 10 f0       	push   $0xf0103de4
f0101ea0:	68 1e 43 10 f0       	push   $0xf010431e
f0101ea5:	68 5e 03 00 00       	push   $0x35e
f0101eaa:	68 f8 42 10 f0       	push   $0xf01042f8
f0101eaf:	e8 d7 e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0101eb4:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0101eba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ebd:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ec2:	74 19                	je     f0101edd <mem_init+0xeb0>
f0101ec4:	68 3b 45 10 f0       	push   $0xf010453b
f0101ec9:	68 1e 43 10 f0       	push   $0xf010431e
f0101ece:	68 60 03 00 00       	push   $0x360
f0101ed3:	68 f8 42 10 f0       	push   $0xf01042f8
f0101ed8:	e8 ae e1 ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f0101edd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ee0:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0101ee6:	83 ec 0c             	sub    $0xc,%esp
f0101ee9:	50                   	push   %eax
f0101eea:	e8 de ee ff ff       	call   f0100dcd <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0101eef:	83 c4 0c             	add    $0xc,%esp
f0101ef2:	6a 01                	push   $0x1
f0101ef4:	68 00 10 40 00       	push   $0x401000
f0101ef9:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101eff:	e8 ff ee ff ff       	call   f0100e03 <pgdir_walk>
f0101f04:	89 c7                	mov    %eax,%edi
f0101f06:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0101f09:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101f0e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f11:	8b 40 04             	mov    0x4(%eax),%eax
f0101f14:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f19:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f0101f1f:	89 c2                	mov    %eax,%edx
f0101f21:	c1 ea 0c             	shr    $0xc,%edx
f0101f24:	83 c4 10             	add    $0x10,%esp
f0101f27:	39 ca                	cmp    %ecx,%edx
f0101f29:	72 15                	jb     f0101f40 <mem_init+0xf13>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f2b:	50                   	push   %eax
f0101f2c:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0101f31:	68 67 03 00 00       	push   $0x367
f0101f36:	68 f8 42 10 f0       	push   $0xf01042f8
f0101f3b:	e8 4b e1 ff ff       	call   f010008b <_panic>
	assert(ptep == ptep1 + PTX(va));
f0101f40:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101f45:	39 c7                	cmp    %eax,%edi
f0101f47:	74 19                	je     f0101f62 <mem_init+0xf35>
f0101f49:	68 c7 45 10 f0       	push   $0xf01045c7
f0101f4e:	68 1e 43 10 f0       	push   $0xf010431e
f0101f53:	68 68 03 00 00       	push   $0x368
f0101f58:	68 f8 42 10 f0       	push   $0xf01042f8
f0101f5d:	e8 29 e1 ff ff       	call   f010008b <_panic>
	kern_pgdir[PDX(va)] = 0;
f0101f62:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101f65:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f0101f6c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f6f:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101f75:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101f7b:	c1 f8 03             	sar    $0x3,%eax
f0101f7e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f81:	89 c2                	mov    %eax,%edx
f0101f83:	c1 ea 0c             	shr    $0xc,%edx
f0101f86:	39 d1                	cmp    %edx,%ecx
f0101f88:	77 12                	ja     f0101f9c <mem_init+0xf6f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f8a:	50                   	push   %eax
f0101f8b:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0101f90:	6a 52                	push   $0x52
f0101f92:	68 04 43 10 f0       	push   $0xf0104304
f0101f97:	e8 ef e0 ff ff       	call   f010008b <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0101f9c:	83 ec 04             	sub    $0x4,%esp
f0101f9f:	68 00 10 00 00       	push   $0x1000
f0101fa4:	68 ff 00 00 00       	push   $0xff
f0101fa9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101fae:	50                   	push   %eax
f0101faf:	e8 f8 11 00 00       	call   f01031ac <memset>
	page_free(pp0);
f0101fb4:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101fb7:	89 3c 24             	mov    %edi,(%esp)
f0101fba:	e8 0e ee ff ff       	call   f0100dcd <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0101fbf:	83 c4 0c             	add    $0xc,%esp
f0101fc2:	6a 01                	push   $0x1
f0101fc4:	6a 00                	push   $0x0
f0101fc6:	ff 35 68 79 11 f0    	pushl  0xf0117968
f0101fcc:	e8 32 ee ff ff       	call   f0100e03 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101fd1:	89 fa                	mov    %edi,%edx
f0101fd3:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101fd9:	c1 fa 03             	sar    $0x3,%edx
f0101fdc:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101fdf:	89 d0                	mov    %edx,%eax
f0101fe1:	c1 e8 0c             	shr    $0xc,%eax
f0101fe4:	83 c4 10             	add    $0x10,%esp
f0101fe7:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0101fed:	72 12                	jb     f0102001 <mem_init+0xfd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101fef:	52                   	push   %edx
f0101ff0:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0101ff5:	6a 52                	push   $0x52
f0101ff7:	68 04 43 10 f0       	push   $0xf0104304
f0101ffc:	e8 8a e0 ff ff       	call   f010008b <_panic>
	return (void *)(pa + KERNBASE);
f0102001:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102007:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010200a:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102010:	f6 00 01             	testb  $0x1,(%eax)
f0102013:	74 19                	je     f010202e <mem_init+0x1001>
f0102015:	68 df 45 10 f0       	push   $0xf01045df
f010201a:	68 1e 43 10 f0       	push   $0xf010431e
f010201f:	68 72 03 00 00       	push   $0x372
f0102024:	68 f8 42 10 f0       	push   $0xf01042f8
f0102029:	e8 5d e0 ff ff       	call   f010008b <_panic>
f010202e:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102031:	39 d0                	cmp    %edx,%eax
f0102033:	75 db                	jne    f0102010 <mem_init+0xfe3>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102035:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010203a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102040:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102043:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102049:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f010204c:	89 0d 3c 75 11 f0    	mov    %ecx,0xf011753c

	// free the pages we took
	page_free(pp0);
f0102052:	83 ec 0c             	sub    $0xc,%esp
f0102055:	50                   	push   %eax
f0102056:	e8 72 ed ff ff       	call   f0100dcd <page_free>
	page_free(pp1);
f010205b:	89 1c 24             	mov    %ebx,(%esp)
f010205e:	e8 6a ed ff ff       	call   f0100dcd <page_free>
	page_free(pp2);
f0102063:	89 34 24             	mov    %esi,(%esp)
f0102066:	e8 62 ed ff ff       	call   f0100dcd <page_free>

	cprintf("check_page() succeeded!\n");
f010206b:	c7 04 24 f6 45 10 f0 	movl   $0xf01045f6,(%esp)
f0102072:	e8 8c 06 00 00       	call   f0102703 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U | PTE_P);
f0102077:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010207c:	83 c4 10             	add    $0x10,%esp
f010207f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102084:	77 15                	ja     f010209b <mem_init+0x106e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102086:	50                   	push   %eax
f0102087:	68 e8 3c 10 f0       	push   $0xf0103ce8
f010208c:	68 b6 00 00 00       	push   $0xb6
f0102091:	68 f8 42 10 f0       	push   $0xf01042f8
f0102096:	e8 f0 df ff ff       	call   f010008b <_panic>
f010209b:	83 ec 08             	sub    $0x8,%esp
f010209e:	6a 05                	push   $0x5
f01020a0:	05 00 00 00 10       	add    $0x10000000,%eax
f01020a5:	50                   	push   %eax
f01020a6:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01020ab:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01020b0:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01020b5:	e8 dc ed ff ff       	call   f0100e96 <boot_map_region>
	boot_map_region(kern_pgdir, (uintptr_t)pages, PTSIZE, PADDR(pages), PTE_W | PTE_P);
f01020ba:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020c0:	83 c4 10             	add    $0x10,%esp
f01020c3:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01020c9:	77 15                	ja     f01020e0 <mem_init+0x10b3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01020cb:	52                   	push   %edx
f01020cc:	68 e8 3c 10 f0       	push   $0xf0103ce8
f01020d1:	68 b7 00 00 00       	push   $0xb7
f01020d6:	68 f8 42 10 f0       	push   $0xf01042f8
f01020db:	e8 ab df ff ff       	call   f010008b <_panic>
f01020e0:	83 ec 08             	sub    $0x8,%esp
f01020e3:	6a 03                	push   $0x3
f01020e5:	8d 82 00 00 00 10    	lea    0x10000000(%edx),%eax
f01020eb:	50                   	push   %eax
f01020ec:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01020f1:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01020f6:	e8 9b ed ff ff       	call   f0100e96 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01020fb:	83 c4 10             	add    $0x10,%esp
f01020fe:	b8 00 d0 10 f0       	mov    $0xf010d000,%eax
f0102103:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102108:	77 15                	ja     f010211f <mem_init+0x10f2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010210a:	50                   	push   %eax
f010210b:	68 e8 3c 10 f0       	push   $0xf0103ce8
f0102110:	68 c5 00 00 00       	push   $0xc5
f0102115:	68 f8 42 10 f0       	push   $0xf01042f8
f010211a:	e8 6c df ff ff       	call   f010008b <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P);
f010211f:	83 ec 08             	sub    $0x8,%esp
f0102122:	6a 03                	push   $0x3
f0102124:	68 00 d0 10 00       	push   $0x10d000
f0102129:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010212e:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102133:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102138:	e8 59 ed ff ff       	call   f0100e96 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, (2^32) - KERNBASE, 0, PTE_W | PTE_P);
f010213d:	83 c4 08             	add    $0x8,%esp
f0102140:	6a 03                	push   $0x3
f0102142:	6a 00                	push   $0x0
f0102144:	b9 22 00 00 10       	mov    $0x10000022,%ecx
f0102149:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010214e:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102153:	e8 3e ed ff ff       	call   f0100e96 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102158:	8b 35 68 79 11 f0    	mov    0xf0117968,%esi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010215e:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0102163:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102166:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010216d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102172:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102175:	8b 3d 6c 79 11 f0    	mov    0xf011796c,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010217b:	89 7d d0             	mov    %edi,-0x30(%ebp)
f010217e:	83 c4 10             	add    $0x10,%esp

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102181:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102186:	eb 55                	jmp    f01021dd <mem_init+0x11b0>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102188:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f010218e:	89 f0                	mov    %esi,%eax
f0102190:	e8 dd e7 ff ff       	call   f0100972 <check_va2pa>
f0102195:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f010219c:	77 15                	ja     f01021b3 <mem_init+0x1186>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010219e:	57                   	push   %edi
f010219f:	68 e8 3c 10 f0       	push   $0xf0103ce8
f01021a4:	68 b4 02 00 00       	push   $0x2b4
f01021a9:	68 f8 42 10 f0       	push   $0xf01042f8
f01021ae:	e8 d8 de ff ff       	call   f010008b <_panic>
f01021b3:	8d 94 1f 00 00 00 10 	lea    0x10000000(%edi,%ebx,1),%edx
f01021ba:	39 c2                	cmp    %eax,%edx
f01021bc:	74 19                	je     f01021d7 <mem_init+0x11aa>
f01021be:	68 64 41 10 f0       	push   $0xf0104164
f01021c3:	68 1e 43 10 f0       	push   $0xf010431e
f01021c8:	68 b4 02 00 00       	push   $0x2b4
f01021cd:	68 f8 42 10 f0       	push   $0xf01042f8
f01021d2:	e8 b4 de ff ff       	call   f010008b <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01021d7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01021dd:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01021e0:	77 a6                	ja     f0102188 <mem_init+0x115b>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01021e2:	8b 7d cc             	mov    -0x34(%ebp),%edi
f01021e5:	c1 e7 0c             	shl    $0xc,%edi
f01021e8:	bb 00 00 00 00       	mov    $0x0,%ebx
f01021ed:	eb 30                	jmp    f010221f <mem_init+0x11f2>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01021ef:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f01021f5:	89 f0                	mov    %esi,%eax
f01021f7:	e8 76 e7 ff ff       	call   f0100972 <check_va2pa>
f01021fc:	39 c3                	cmp    %eax,%ebx
f01021fe:	74 19                	je     f0102219 <mem_init+0x11ec>
f0102200:	68 98 41 10 f0       	push   $0xf0104198
f0102205:	68 1e 43 10 f0       	push   $0xf010431e
f010220a:	68 b9 02 00 00       	push   $0x2b9
f010220f:	68 f8 42 10 f0       	push   $0xf01042f8
f0102214:	e8 72 de ff ff       	call   f010008b <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102219:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010221f:	39 fb                	cmp    %edi,%ebx
f0102221:	72 cc                	jb     f01021ef <mem_init+0x11c2>
f0102223:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102228:	89 da                	mov    %ebx,%edx
f010222a:	89 f0                	mov    %esi,%eax
f010222c:	e8 41 e7 ff ff       	call   f0100972 <check_va2pa>
f0102231:	8d 93 00 50 11 10    	lea    0x10115000(%ebx),%edx
f0102237:	39 c2                	cmp    %eax,%edx
f0102239:	74 19                	je     f0102254 <mem_init+0x1227>
f010223b:	68 c0 41 10 f0       	push   $0xf01041c0
f0102240:	68 1e 43 10 f0       	push   $0xf010431e
f0102245:	68 bd 02 00 00       	push   $0x2bd
f010224a:	68 f8 42 10 f0       	push   $0xf01042f8
f010224f:	e8 37 de ff ff       	call   f010008b <_panic>
f0102254:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010225a:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102260:	75 c6                	jne    f0102228 <mem_init+0x11fb>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102262:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102267:	89 f0                	mov    %esi,%eax
f0102269:	e8 04 e7 ff ff       	call   f0100972 <check_va2pa>
f010226e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102271:	74 51                	je     f01022c4 <mem_init+0x1297>
f0102273:	68 08 42 10 f0       	push   $0xf0104208
f0102278:	68 1e 43 10 f0       	push   $0xf010431e
f010227d:	68 be 02 00 00       	push   $0x2be
f0102282:	68 f8 42 10 f0       	push   $0xf01042f8
f0102287:	e8 ff dd ff ff       	call   f010008b <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010228c:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102291:	72 36                	jb     f01022c9 <mem_init+0x129c>
f0102293:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102298:	76 07                	jbe    f01022a1 <mem_init+0x1274>
f010229a:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010229f:	75 28                	jne    f01022c9 <mem_init+0x129c>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01022a1:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f01022a5:	0f 85 83 00 00 00    	jne    f010232e <mem_init+0x1301>
f01022ab:	68 0f 46 10 f0       	push   $0xf010460f
f01022b0:	68 1e 43 10 f0       	push   $0xf010431e
f01022b5:	68 c6 02 00 00       	push   $0x2c6
f01022ba:	68 f8 42 10 f0       	push   $0xf01042f8
f01022bf:	e8 c7 dd ff ff       	call   f010008b <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01022c4:	b8 00 00 00 00       	mov    $0x0,%eax
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01022c9:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01022ce:	76 3f                	jbe    f010230f <mem_init+0x12e2>
				assert(pgdir[i] & PTE_P);
f01022d0:	8b 14 86             	mov    (%esi,%eax,4),%edx
f01022d3:	f6 c2 01             	test   $0x1,%dl
f01022d6:	75 19                	jne    f01022f1 <mem_init+0x12c4>
f01022d8:	68 0f 46 10 f0       	push   $0xf010460f
f01022dd:	68 1e 43 10 f0       	push   $0xf010431e
f01022e2:	68 ca 02 00 00       	push   $0x2ca
f01022e7:	68 f8 42 10 f0       	push   $0xf01042f8
f01022ec:	e8 9a dd ff ff       	call   f010008b <_panic>
				assert(pgdir[i] & PTE_W);
f01022f1:	f6 c2 02             	test   $0x2,%dl
f01022f4:	75 38                	jne    f010232e <mem_init+0x1301>
f01022f6:	68 20 46 10 f0       	push   $0xf0104620
f01022fb:	68 1e 43 10 f0       	push   $0xf010431e
f0102300:	68 cb 02 00 00       	push   $0x2cb
f0102305:	68 f8 42 10 f0       	push   $0xf01042f8
f010230a:	e8 7c dd ff ff       	call   f010008b <_panic>
			} else
				assert(pgdir[i] == 0);
f010230f:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102313:	74 19                	je     f010232e <mem_init+0x1301>
f0102315:	68 31 46 10 f0       	push   $0xf0104631
f010231a:	68 1e 43 10 f0       	push   $0xf010431e
f010231f:	68 cd 02 00 00       	push   $0x2cd
f0102324:	68 f8 42 10 f0       	push   $0xf01042f8
f0102329:	e8 5d dd ff ff       	call   f010008b <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f010232e:	83 c0 01             	add    $0x1,%eax
f0102331:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102336:	0f 86 50 ff ff ff    	jbe    f010228c <mem_init+0x125f>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010233c:	83 ec 0c             	sub    $0xc,%esp
f010233f:	68 38 42 10 f0       	push   $0xf0104238
f0102344:	e8 ba 03 00 00       	call   f0102703 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102349:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010234e:	83 c4 10             	add    $0x10,%esp
f0102351:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102356:	77 15                	ja     f010236d <mem_init+0x1340>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102358:	50                   	push   %eax
f0102359:	68 e8 3c 10 f0       	push   $0xf0103ce8
f010235e:	68 dc 00 00 00       	push   $0xdc
f0102363:	68 f8 42 10 f0       	push   $0xf01042f8
f0102368:	e8 1e dd ff ff       	call   f010008b <_panic>
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010236d:	05 00 00 00 10       	add    $0x10000000,%eax
f0102372:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102375:	b8 00 00 00 00       	mov    $0x0,%eax
f010237a:	e8 57 e6 ff ff       	call   f01009d6 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f010237f:	0f 20 c0             	mov    %cr0,%eax
f0102382:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102385:	0d 23 00 05 80       	or     $0x80050023,%eax
f010238a:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010238d:	83 ec 0c             	sub    $0xc,%esp
f0102390:	6a 00                	push   $0x0
f0102392:	e8 c6 e9 ff ff       	call   f0100d5d <page_alloc>
f0102397:	89 c3                	mov    %eax,%ebx
f0102399:	83 c4 10             	add    $0x10,%esp
f010239c:	85 c0                	test   %eax,%eax
f010239e:	75 19                	jne    f01023b9 <mem_init+0x138c>
f01023a0:	68 2d 44 10 f0       	push   $0xf010442d
f01023a5:	68 1e 43 10 f0       	push   $0xf010431e
f01023aa:	68 8d 03 00 00       	push   $0x38d
f01023af:	68 f8 42 10 f0       	push   $0xf01042f8
f01023b4:	e8 d2 dc ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f01023b9:	83 ec 0c             	sub    $0xc,%esp
f01023bc:	6a 00                	push   $0x0
f01023be:	e8 9a e9 ff ff       	call   f0100d5d <page_alloc>
f01023c3:	89 c7                	mov    %eax,%edi
f01023c5:	83 c4 10             	add    $0x10,%esp
f01023c8:	85 c0                	test   %eax,%eax
f01023ca:	75 19                	jne    f01023e5 <mem_init+0x13b8>
f01023cc:	68 43 44 10 f0       	push   $0xf0104443
f01023d1:	68 1e 43 10 f0       	push   $0xf010431e
f01023d6:	68 8e 03 00 00       	push   $0x38e
f01023db:	68 f8 42 10 f0       	push   $0xf01042f8
f01023e0:	e8 a6 dc ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01023e5:	83 ec 0c             	sub    $0xc,%esp
f01023e8:	6a 00                	push   $0x0
f01023ea:	e8 6e e9 ff ff       	call   f0100d5d <page_alloc>
f01023ef:	89 c6                	mov    %eax,%esi
f01023f1:	83 c4 10             	add    $0x10,%esp
f01023f4:	85 c0                	test   %eax,%eax
f01023f6:	75 19                	jne    f0102411 <mem_init+0x13e4>
f01023f8:	68 59 44 10 f0       	push   $0xf0104459
f01023fd:	68 1e 43 10 f0       	push   $0xf010431e
f0102402:	68 8f 03 00 00       	push   $0x38f
f0102407:	68 f8 42 10 f0       	push   $0xf01042f8
f010240c:	e8 7a dc ff ff       	call   f010008b <_panic>
	page_free(pp0);
f0102411:	83 ec 0c             	sub    $0xc,%esp
f0102414:	53                   	push   %ebx
f0102415:	e8 b3 e9 ff ff       	call   f0100dcd <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010241a:	89 f8                	mov    %edi,%eax
f010241c:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102422:	c1 f8 03             	sar    $0x3,%eax
f0102425:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102428:	89 c2                	mov    %eax,%edx
f010242a:	c1 ea 0c             	shr    $0xc,%edx
f010242d:	83 c4 10             	add    $0x10,%esp
f0102430:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0102436:	72 12                	jb     f010244a <mem_init+0x141d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102438:	50                   	push   %eax
f0102439:	68 a4 3b 10 f0       	push   $0xf0103ba4
f010243e:	6a 52                	push   $0x52
f0102440:	68 04 43 10 f0       	push   $0xf0104304
f0102445:	e8 41 dc ff ff       	call   f010008b <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f010244a:	83 ec 04             	sub    $0x4,%esp
f010244d:	68 00 10 00 00       	push   $0x1000
f0102452:	6a 01                	push   $0x1
f0102454:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102459:	50                   	push   %eax
f010245a:	e8 4d 0d 00 00       	call   f01031ac <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010245f:	89 f0                	mov    %esi,%eax
f0102461:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102467:	c1 f8 03             	sar    $0x3,%eax
f010246a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010246d:	89 c2                	mov    %eax,%edx
f010246f:	c1 ea 0c             	shr    $0xc,%edx
f0102472:	83 c4 10             	add    $0x10,%esp
f0102475:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f010247b:	72 12                	jb     f010248f <mem_init+0x1462>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010247d:	50                   	push   %eax
f010247e:	68 a4 3b 10 f0       	push   $0xf0103ba4
f0102483:	6a 52                	push   $0x52
f0102485:	68 04 43 10 f0       	push   $0xf0104304
f010248a:	e8 fc db ff ff       	call   f010008b <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f010248f:	83 ec 04             	sub    $0x4,%esp
f0102492:	68 00 10 00 00       	push   $0x1000
f0102497:	6a 02                	push   $0x2
f0102499:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010249e:	50                   	push   %eax
f010249f:	e8 08 0d 00 00       	call   f01031ac <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01024a4:	6a 02                	push   $0x2
f01024a6:	68 00 10 00 00       	push   $0x1000
f01024ab:	57                   	push   %edi
f01024ac:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01024b2:	e8 10 eb ff ff       	call   f0100fc7 <page_insert>
	assert(pp1->pp_ref == 1);
f01024b7:	83 c4 20             	add    $0x20,%esp
f01024ba:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01024bf:	74 19                	je     f01024da <mem_init+0x14ad>
f01024c1:	68 2a 45 10 f0       	push   $0xf010452a
f01024c6:	68 1e 43 10 f0       	push   $0xf010431e
f01024cb:	68 94 03 00 00       	push   $0x394
f01024d0:	68 f8 42 10 f0       	push   $0xf01042f8
f01024d5:	e8 b1 db ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01024da:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01024e1:	01 01 01 
f01024e4:	74 19                	je     f01024ff <mem_init+0x14d2>
f01024e6:	68 58 42 10 f0       	push   $0xf0104258
f01024eb:	68 1e 43 10 f0       	push   $0xf010431e
f01024f0:	68 95 03 00 00       	push   $0x395
f01024f5:	68 f8 42 10 f0       	push   $0xf01042f8
f01024fa:	e8 8c db ff ff       	call   f010008b <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01024ff:	6a 02                	push   $0x2
f0102501:	68 00 10 00 00       	push   $0x1000
f0102506:	56                   	push   %esi
f0102507:	ff 35 68 79 11 f0    	pushl  0xf0117968
f010250d:	e8 b5 ea ff ff       	call   f0100fc7 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102512:	83 c4 10             	add    $0x10,%esp
f0102515:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010251c:	02 02 02 
f010251f:	74 19                	je     f010253a <mem_init+0x150d>
f0102521:	68 7c 42 10 f0       	push   $0xf010427c
f0102526:	68 1e 43 10 f0       	push   $0xf010431e
f010252b:	68 97 03 00 00       	push   $0x397
f0102530:	68 f8 42 10 f0       	push   $0xf01042f8
f0102535:	e8 51 db ff ff       	call   f010008b <_panic>
	assert(pp2->pp_ref == 1);
f010253a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010253f:	74 19                	je     f010255a <mem_init+0x152d>
f0102541:	68 4c 45 10 f0       	push   $0xf010454c
f0102546:	68 1e 43 10 f0       	push   $0xf010431e
f010254b:	68 98 03 00 00       	push   $0x398
f0102550:	68 f8 42 10 f0       	push   $0xf01042f8
f0102555:	e8 31 db ff ff       	call   f010008b <_panic>
	assert(pp1->pp_ref == 0);
f010255a:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010255f:	74 19                	je     f010257a <mem_init+0x154d>
f0102561:	68 b6 45 10 f0       	push   $0xf01045b6
f0102566:	68 1e 43 10 f0       	push   $0xf010431e
f010256b:	68 99 03 00 00       	push   $0x399
f0102570:	68 f8 42 10 f0       	push   $0xf01042f8
f0102575:	e8 11 db ff ff       	call   f010008b <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f010257a:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102581:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102584:	89 f0                	mov    %esi,%eax
f0102586:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f010258c:	c1 f8 03             	sar    $0x3,%eax
f010258f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102592:	89 c2                	mov    %eax,%edx
f0102594:	c1 ea 0c             	shr    $0xc,%edx
f0102597:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f010259d:	72 12                	jb     f01025b1 <mem_init+0x1584>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010259f:	50                   	push   %eax
f01025a0:	68 a4 3b 10 f0       	push   $0xf0103ba4
f01025a5:	6a 52                	push   $0x52
f01025a7:	68 04 43 10 f0       	push   $0xf0104304
f01025ac:	e8 da da ff ff       	call   f010008b <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01025b1:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01025b8:	03 03 03 
f01025bb:	74 19                	je     f01025d6 <mem_init+0x15a9>
f01025bd:	68 a0 42 10 f0       	push   $0xf01042a0
f01025c2:	68 1e 43 10 f0       	push   $0xf010431e
f01025c7:	68 9b 03 00 00       	push   $0x39b
f01025cc:	68 f8 42 10 f0       	push   $0xf01042f8
f01025d1:	e8 b5 da ff ff       	call   f010008b <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01025d6:	83 ec 08             	sub    $0x8,%esp
f01025d9:	68 00 10 00 00       	push   $0x1000
f01025de:	ff 35 68 79 11 f0    	pushl  0xf0117968
f01025e4:	e8 89 e9 ff ff       	call   f0100f72 <page_remove>
	assert(pp2->pp_ref == 0);
f01025e9:	83 c4 10             	add    $0x10,%esp
f01025ec:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01025f1:	74 19                	je     f010260c <mem_init+0x15df>
f01025f3:	68 84 45 10 f0       	push   $0xf0104584
f01025f8:	68 1e 43 10 f0       	push   $0xf010431e
f01025fd:	68 9d 03 00 00       	push   $0x39d
f0102602:	68 f8 42 10 f0       	push   $0xf01042f8
f0102607:	e8 7f da ff ff       	call   f010008b <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010260c:	8b 0d 68 79 11 f0    	mov    0xf0117968,%ecx
f0102612:	8b 11                	mov    (%ecx),%edx
f0102614:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010261a:	89 d8                	mov    %ebx,%eax
f010261c:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0102622:	c1 f8 03             	sar    $0x3,%eax
f0102625:	c1 e0 0c             	shl    $0xc,%eax
f0102628:	39 c2                	cmp    %eax,%edx
f010262a:	74 19                	je     f0102645 <mem_init+0x1618>
f010262c:	68 e4 3d 10 f0       	push   $0xf0103de4
f0102631:	68 1e 43 10 f0       	push   $0xf010431e
f0102636:	68 a0 03 00 00       	push   $0x3a0
f010263b:	68 f8 42 10 f0       	push   $0xf01042f8
f0102640:	e8 46 da ff ff       	call   f010008b <_panic>
	kern_pgdir[0] = 0;
f0102645:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010264b:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102650:	74 19                	je     f010266b <mem_init+0x163e>
f0102652:	68 3b 45 10 f0       	push   $0xf010453b
f0102657:	68 1e 43 10 f0       	push   $0xf010431e
f010265c:	68 a2 03 00 00       	push   $0x3a2
f0102661:	68 f8 42 10 f0       	push   $0xf01042f8
f0102666:	e8 20 da ff ff       	call   f010008b <_panic>
	pp0->pp_ref = 0;
f010266b:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102671:	83 ec 0c             	sub    $0xc,%esp
f0102674:	53                   	push   %ebx
f0102675:	e8 53 e7 ff ff       	call   f0100dcd <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f010267a:	c7 04 24 cc 42 10 f0 	movl   $0xf01042cc,(%esp)
f0102681:	e8 7d 00 00 00       	call   f0102703 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102686:	83 c4 10             	add    $0x10,%esp
f0102689:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010268c:	5b                   	pop    %ebx
f010268d:	5e                   	pop    %esi
f010268e:	5f                   	pop    %edi
f010268f:	5d                   	pop    %ebp
f0102690:	c3                   	ret    

f0102691 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102691:	55                   	push   %ebp
f0102692:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102694:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102697:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010269a:	5d                   	pop    %ebp
f010269b:	c3                   	ret    

f010269c <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010269c:	55                   	push   %ebp
f010269d:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010269f:	ba 70 00 00 00       	mov    $0x70,%edx
f01026a4:	8b 45 08             	mov    0x8(%ebp),%eax
f01026a7:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01026a8:	ba 71 00 00 00       	mov    $0x71,%edx
f01026ad:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01026ae:	0f b6 c0             	movzbl %al,%eax
}
f01026b1:	5d                   	pop    %ebp
f01026b2:	c3                   	ret    

f01026b3 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01026b3:	55                   	push   %ebp
f01026b4:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01026b6:	ba 70 00 00 00       	mov    $0x70,%edx
f01026bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01026be:	ee                   	out    %al,(%dx)
f01026bf:	ba 71 00 00 00       	mov    $0x71,%edx
f01026c4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01026c7:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01026c8:	5d                   	pop    %ebp
f01026c9:	c3                   	ret    

f01026ca <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01026ca:	55                   	push   %ebp
f01026cb:	89 e5                	mov    %esp,%ebp
f01026cd:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01026d0:	ff 75 08             	pushl  0x8(%ebp)
f01026d3:	e8 28 df ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f01026d8:	83 c4 10             	add    $0x10,%esp
f01026db:	c9                   	leave  
f01026dc:	c3                   	ret    

f01026dd <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01026dd:	55                   	push   %ebp
f01026de:	89 e5                	mov    %esp,%ebp
f01026e0:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01026e3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01026ea:	ff 75 0c             	pushl  0xc(%ebp)
f01026ed:	ff 75 08             	pushl  0x8(%ebp)
f01026f0:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01026f3:	50                   	push   %eax
f01026f4:	68 ca 26 10 f0       	push   $0xf01026ca
f01026f9:	e8 42 04 00 00       	call   f0102b40 <vprintfmt>
	return cnt;
}
f01026fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102701:	c9                   	leave  
f0102702:	c3                   	ret    

f0102703 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102703:	55                   	push   %ebp
f0102704:	89 e5                	mov    %esp,%ebp
f0102706:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102709:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010270c:	50                   	push   %eax
f010270d:	ff 75 08             	pushl  0x8(%ebp)
f0102710:	e8 c8 ff ff ff       	call   f01026dd <vcprintf>
	va_end(ap);

	return cnt;
}
f0102715:	c9                   	leave  
f0102716:	c3                   	ret    

f0102717 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102717:	55                   	push   %ebp
f0102718:	89 e5                	mov    %esp,%ebp
f010271a:	57                   	push   %edi
f010271b:	56                   	push   %esi
f010271c:	53                   	push   %ebx
f010271d:	83 ec 14             	sub    $0x14,%esp
f0102720:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102723:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0102726:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102729:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010272c:	8b 1a                	mov    (%edx),%ebx
f010272e:	8b 01                	mov    (%ecx),%eax
f0102730:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102733:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010273a:	eb 7f                	jmp    f01027bb <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010273c:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010273f:	01 d8                	add    %ebx,%eax
f0102741:	89 c6                	mov    %eax,%esi
f0102743:	c1 ee 1f             	shr    $0x1f,%esi
f0102746:	01 c6                	add    %eax,%esi
f0102748:	d1 fe                	sar    %esi
f010274a:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010274d:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102750:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0102753:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102755:	eb 03                	jmp    f010275a <stab_binsearch+0x43>
			m--;
f0102757:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010275a:	39 c3                	cmp    %eax,%ebx
f010275c:	7f 0d                	jg     f010276b <stab_binsearch+0x54>
f010275e:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102762:	83 ea 0c             	sub    $0xc,%edx
f0102765:	39 f9                	cmp    %edi,%ecx
f0102767:	75 ee                	jne    f0102757 <stab_binsearch+0x40>
f0102769:	eb 05                	jmp    f0102770 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010276b:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010276e:	eb 4b                	jmp    f01027bb <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102770:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0102773:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102776:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010277a:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010277d:	76 11                	jbe    f0102790 <stab_binsearch+0x79>
			*region_left = m;
f010277f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0102782:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0102784:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102787:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010278e:	eb 2b                	jmp    f01027bb <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102790:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102793:	73 14                	jae    f01027a9 <stab_binsearch+0x92>
			*region_right = m - 1;
f0102795:	83 e8 01             	sub    $0x1,%eax
f0102798:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010279b:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010279e:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027a0:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01027a7:	eb 12                	jmp    f01027bb <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01027a9:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027ac:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01027ae:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01027b2:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01027b4:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01027bb:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01027be:	0f 8e 78 ff ff ff    	jle    f010273c <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01027c4:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01027c8:	75 0f                	jne    f01027d9 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f01027ca:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01027cd:	8b 00                	mov    (%eax),%eax
f01027cf:	83 e8 01             	sub    $0x1,%eax
f01027d2:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01027d5:	89 06                	mov    %eax,(%esi)
f01027d7:	eb 2c                	jmp    f0102805 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027d9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01027dc:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01027de:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01027e1:	8b 0e                	mov    (%esi),%ecx
f01027e3:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01027e6:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01027e9:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027ec:	eb 03                	jmp    f01027f1 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01027ee:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01027f1:	39 c8                	cmp    %ecx,%eax
f01027f3:	7e 0b                	jle    f0102800 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f01027f5:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01027f9:	83 ea 0c             	sub    $0xc,%edx
f01027fc:	39 df                	cmp    %ebx,%edi
f01027fe:	75 ee                	jne    f01027ee <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102800:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102803:	89 06                	mov    %eax,(%esi)
	}
}
f0102805:	83 c4 14             	add    $0x14,%esp
f0102808:	5b                   	pop    %ebx
f0102809:	5e                   	pop    %esi
f010280a:	5f                   	pop    %edi
f010280b:	5d                   	pop    %ebp
f010280c:	c3                   	ret    

f010280d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010280d:	55                   	push   %ebp
f010280e:	89 e5                	mov    %esp,%ebp
f0102810:	57                   	push   %edi
f0102811:	56                   	push   %esi
f0102812:	53                   	push   %ebx
f0102813:	83 ec 3c             	sub    $0x3c,%esp
f0102816:	8b 75 08             	mov    0x8(%ebp),%esi
f0102819:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010281c:	c7 03 3f 46 10 f0    	movl   $0xf010463f,(%ebx)
	info->eip_line = 0;
f0102822:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102829:	c7 43 08 3f 46 10 f0 	movl   $0xf010463f,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102830:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102837:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f010283a:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102841:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102847:	76 11                	jbe    f010285a <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102849:	b8 0f c0 10 f0       	mov    $0xf010c00f,%eax
f010284e:	3d 09 a2 10 f0       	cmp    $0xf010a209,%eax
f0102853:	77 19                	ja     f010286e <debuginfo_eip+0x61>
f0102855:	e9 a1 01 00 00       	jmp    f01029fb <debuginfo_eip+0x1ee>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f010285a:	83 ec 04             	sub    $0x4,%esp
f010285d:	68 49 46 10 f0       	push   $0xf0104649
f0102862:	6a 7f                	push   $0x7f
f0102864:	68 56 46 10 f0       	push   $0xf0104656
f0102869:	e8 1d d8 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010286e:	80 3d 0e c0 10 f0 00 	cmpb   $0x0,0xf010c00e
f0102875:	0f 85 87 01 00 00    	jne    f0102a02 <debuginfo_eip+0x1f5>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010287b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102882:	b8 08 a2 10 f0       	mov    $0xf010a208,%eax
f0102887:	2d 74 48 10 f0       	sub    $0xf0104874,%eax
f010288c:	c1 f8 02             	sar    $0x2,%eax
f010288f:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102895:	83 e8 01             	sub    $0x1,%eax
f0102898:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010289b:	83 ec 08             	sub    $0x8,%esp
f010289e:	56                   	push   %esi
f010289f:	6a 64                	push   $0x64
f01028a1:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01028a4:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01028a7:	b8 74 48 10 f0       	mov    $0xf0104874,%eax
f01028ac:	e8 66 fe ff ff       	call   f0102717 <stab_binsearch>
	if (lfile == 0)
f01028b1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01028b4:	83 c4 10             	add    $0x10,%esp
f01028b7:	85 c0                	test   %eax,%eax
f01028b9:	0f 84 4a 01 00 00    	je     f0102a09 <debuginfo_eip+0x1fc>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01028bf:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01028c2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01028c5:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01028c8:	83 ec 08             	sub    $0x8,%esp
f01028cb:	56                   	push   %esi
f01028cc:	6a 24                	push   $0x24
f01028ce:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01028d1:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01028d4:	b8 74 48 10 f0       	mov    $0xf0104874,%eax
f01028d9:	e8 39 fe ff ff       	call   f0102717 <stab_binsearch>

	if (lfun <= rfun) {
f01028de:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01028e1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01028e4:	83 c4 10             	add    $0x10,%esp
f01028e7:	39 d0                	cmp    %edx,%eax
f01028e9:	7f 40                	jg     f010292b <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01028eb:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01028ee:	c1 e1 02             	shl    $0x2,%ecx
f01028f1:	8d b9 74 48 10 f0    	lea    -0xfefb78c(%ecx),%edi
f01028f7:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f01028fa:	8b b9 74 48 10 f0    	mov    -0xfefb78c(%ecx),%edi
f0102900:	b9 0f c0 10 f0       	mov    $0xf010c00f,%ecx
f0102905:	81 e9 09 a2 10 f0    	sub    $0xf010a209,%ecx
f010290b:	39 cf                	cmp    %ecx,%edi
f010290d:	73 09                	jae    f0102918 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010290f:	81 c7 09 a2 10 f0    	add    $0xf010a209,%edi
f0102915:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102918:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010291b:	8b 4f 08             	mov    0x8(%edi),%ecx
f010291e:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102921:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102923:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102926:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102929:	eb 0f                	jmp    f010293a <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010292b:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f010292e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102931:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0102934:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102937:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010293a:	83 ec 08             	sub    $0x8,%esp
f010293d:	6a 3a                	push   $0x3a
f010293f:	ff 73 08             	pushl  0x8(%ebx)
f0102942:	e8 49 08 00 00       	call   f0103190 <strfind>
f0102947:	2b 43 08             	sub    0x8(%ebx),%eax
f010294a:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f010294d:	83 c4 08             	add    $0x8,%esp
f0102950:	56                   	push   %esi
f0102951:	6a 44                	push   $0x44
f0102953:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0102956:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0102959:	b8 74 48 10 f0       	mov    $0xf0104874,%eax
f010295e:	e8 b4 fd ff ff       	call   f0102717 <stab_binsearch>
	info->eip_line = stabs[lline].n_desc;
f0102963:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102966:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102969:	8d 04 85 74 48 10 f0 	lea    -0xfefb78c(,%eax,4),%eax
f0102970:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f0102974:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102977:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010297a:	83 c4 10             	add    $0x10,%esp
f010297d:	eb 06                	jmp    f0102985 <debuginfo_eip+0x178>
f010297f:	83 ea 01             	sub    $0x1,%edx
f0102982:	83 e8 0c             	sub    $0xc,%eax
f0102985:	39 d6                	cmp    %edx,%esi
f0102987:	7f 34                	jg     f01029bd <debuginfo_eip+0x1b0>
	       && stabs[lline].n_type != N_SOL
f0102989:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f010298d:	80 f9 84             	cmp    $0x84,%cl
f0102990:	74 0b                	je     f010299d <debuginfo_eip+0x190>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102992:	80 f9 64             	cmp    $0x64,%cl
f0102995:	75 e8                	jne    f010297f <debuginfo_eip+0x172>
f0102997:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f010299b:	74 e2                	je     f010297f <debuginfo_eip+0x172>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010299d:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01029a0:	8b 14 85 74 48 10 f0 	mov    -0xfefb78c(,%eax,4),%edx
f01029a7:	b8 0f c0 10 f0       	mov    $0xf010c00f,%eax
f01029ac:	2d 09 a2 10 f0       	sub    $0xf010a209,%eax
f01029b1:	39 c2                	cmp    %eax,%edx
f01029b3:	73 08                	jae    f01029bd <debuginfo_eip+0x1b0>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01029b5:	81 c2 09 a2 10 f0    	add    $0xf010a209,%edx
f01029bb:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01029bd:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01029c0:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01029c3:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01029c8:	39 f2                	cmp    %esi,%edx
f01029ca:	7d 49                	jge    f0102a15 <debuginfo_eip+0x208>
		for (lline = lfun + 1;
f01029cc:	83 c2 01             	add    $0x1,%edx
f01029cf:	89 d0                	mov    %edx,%eax
f01029d1:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01029d4:	8d 14 95 74 48 10 f0 	lea    -0xfefb78c(,%edx,4),%edx
f01029db:	eb 04                	jmp    f01029e1 <debuginfo_eip+0x1d4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01029dd:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01029e1:	39 c6                	cmp    %eax,%esi
f01029e3:	7e 2b                	jle    f0102a10 <debuginfo_eip+0x203>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01029e5:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01029e9:	83 c0 01             	add    $0x1,%eax
f01029ec:	83 c2 0c             	add    $0xc,%edx
f01029ef:	80 f9 a0             	cmp    $0xa0,%cl
f01029f2:	74 e9                	je     f01029dd <debuginfo_eip+0x1d0>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01029f4:	b8 00 00 00 00       	mov    $0x0,%eax
f01029f9:	eb 1a                	jmp    f0102a15 <debuginfo_eip+0x208>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01029fb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a00:	eb 13                	jmp    f0102a15 <debuginfo_eip+0x208>
f0102a02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a07:	eb 0c                	jmp    f0102a15 <debuginfo_eip+0x208>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0102a09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102a0e:	eb 05                	jmp    f0102a15 <debuginfo_eip+0x208>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102a10:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102a15:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102a18:	5b                   	pop    %ebx
f0102a19:	5e                   	pop    %esi
f0102a1a:	5f                   	pop    %edi
f0102a1b:	5d                   	pop    %ebp
f0102a1c:	c3                   	ret    

f0102a1d <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102a1d:	55                   	push   %ebp
f0102a1e:	89 e5                	mov    %esp,%ebp
f0102a20:	57                   	push   %edi
f0102a21:	56                   	push   %esi
f0102a22:	53                   	push   %ebx
f0102a23:	83 ec 1c             	sub    $0x1c,%esp
f0102a26:	89 c7                	mov    %eax,%edi
f0102a28:	89 d6                	mov    %edx,%esi
f0102a2a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a2d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102a30:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102a33:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102a36:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0102a39:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102a3e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0102a41:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0102a44:	39 d3                	cmp    %edx,%ebx
f0102a46:	72 05                	jb     f0102a4d <printnum+0x30>
f0102a48:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102a4b:	77 45                	ja     f0102a92 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102a4d:	83 ec 0c             	sub    $0xc,%esp
f0102a50:	ff 75 18             	pushl  0x18(%ebp)
f0102a53:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a56:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102a59:	53                   	push   %ebx
f0102a5a:	ff 75 10             	pushl  0x10(%ebp)
f0102a5d:	83 ec 08             	sub    $0x8,%esp
f0102a60:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102a63:	ff 75 e0             	pushl  -0x20(%ebp)
f0102a66:	ff 75 dc             	pushl  -0x24(%ebp)
f0102a69:	ff 75 d8             	pushl  -0x28(%ebp)
f0102a6c:	e8 3f 09 00 00       	call   f01033b0 <__udivdi3>
f0102a71:	83 c4 18             	add    $0x18,%esp
f0102a74:	52                   	push   %edx
f0102a75:	50                   	push   %eax
f0102a76:	89 f2                	mov    %esi,%edx
f0102a78:	89 f8                	mov    %edi,%eax
f0102a7a:	e8 9e ff ff ff       	call   f0102a1d <printnum>
f0102a7f:	83 c4 20             	add    $0x20,%esp
f0102a82:	eb 18                	jmp    f0102a9c <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102a84:	83 ec 08             	sub    $0x8,%esp
f0102a87:	56                   	push   %esi
f0102a88:	ff 75 18             	pushl  0x18(%ebp)
f0102a8b:	ff d7                	call   *%edi
f0102a8d:	83 c4 10             	add    $0x10,%esp
f0102a90:	eb 03                	jmp    f0102a95 <printnum+0x78>
f0102a92:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102a95:	83 eb 01             	sub    $0x1,%ebx
f0102a98:	85 db                	test   %ebx,%ebx
f0102a9a:	7f e8                	jg     f0102a84 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102a9c:	83 ec 08             	sub    $0x8,%esp
f0102a9f:	56                   	push   %esi
f0102aa0:	83 ec 04             	sub    $0x4,%esp
f0102aa3:	ff 75 e4             	pushl  -0x1c(%ebp)
f0102aa6:	ff 75 e0             	pushl  -0x20(%ebp)
f0102aa9:	ff 75 dc             	pushl  -0x24(%ebp)
f0102aac:	ff 75 d8             	pushl  -0x28(%ebp)
f0102aaf:	e8 2c 0a 00 00       	call   f01034e0 <__umoddi3>
f0102ab4:	83 c4 14             	add    $0x14,%esp
f0102ab7:	0f be 80 64 46 10 f0 	movsbl -0xfefb99c(%eax),%eax
f0102abe:	50                   	push   %eax
f0102abf:	ff d7                	call   *%edi
}
f0102ac1:	83 c4 10             	add    $0x10,%esp
f0102ac4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ac7:	5b                   	pop    %ebx
f0102ac8:	5e                   	pop    %esi
f0102ac9:	5f                   	pop    %edi
f0102aca:	5d                   	pop    %ebp
f0102acb:	c3                   	ret    

f0102acc <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102acc:	55                   	push   %ebp
f0102acd:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102acf:	83 fa 01             	cmp    $0x1,%edx
f0102ad2:	7e 0e                	jle    f0102ae2 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102ad4:	8b 10                	mov    (%eax),%edx
f0102ad6:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102ad9:	89 08                	mov    %ecx,(%eax)
f0102adb:	8b 02                	mov    (%edx),%eax
f0102add:	8b 52 04             	mov    0x4(%edx),%edx
f0102ae0:	eb 22                	jmp    f0102b04 <getuint+0x38>
	else if (lflag)
f0102ae2:	85 d2                	test   %edx,%edx
f0102ae4:	74 10                	je     f0102af6 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0102ae6:	8b 10                	mov    (%eax),%edx
f0102ae8:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102aeb:	89 08                	mov    %ecx,(%eax)
f0102aed:	8b 02                	mov    (%edx),%eax
f0102aef:	ba 00 00 00 00       	mov    $0x0,%edx
f0102af4:	eb 0e                	jmp    f0102b04 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0102af6:	8b 10                	mov    (%eax),%edx
f0102af8:	8d 4a 04             	lea    0x4(%edx),%ecx
f0102afb:	89 08                	mov    %ecx,(%eax)
f0102afd:	8b 02                	mov    (%edx),%eax
f0102aff:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0102b04:	5d                   	pop    %ebp
f0102b05:	c3                   	ret    

f0102b06 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102b06:	55                   	push   %ebp
f0102b07:	89 e5                	mov    %esp,%ebp
f0102b09:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0102b0c:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0102b10:	8b 10                	mov    (%eax),%edx
f0102b12:	3b 50 04             	cmp    0x4(%eax),%edx
f0102b15:	73 0a                	jae    f0102b21 <sprintputch+0x1b>
		*b->buf++ = ch;
f0102b17:	8d 4a 01             	lea    0x1(%edx),%ecx
f0102b1a:	89 08                	mov    %ecx,(%eax)
f0102b1c:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b1f:	88 02                	mov    %al,(%edx)
}
f0102b21:	5d                   	pop    %ebp
f0102b22:	c3                   	ret    

f0102b23 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102b23:	55                   	push   %ebp
f0102b24:	89 e5                	mov    %esp,%ebp
f0102b26:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0102b29:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0102b2c:	50                   	push   %eax
f0102b2d:	ff 75 10             	pushl  0x10(%ebp)
f0102b30:	ff 75 0c             	pushl  0xc(%ebp)
f0102b33:	ff 75 08             	pushl  0x8(%ebp)
f0102b36:	e8 05 00 00 00       	call   f0102b40 <vprintfmt>
	va_end(ap);
}
f0102b3b:	83 c4 10             	add    $0x10,%esp
f0102b3e:	c9                   	leave  
f0102b3f:	c3                   	ret    

f0102b40 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0102b40:	55                   	push   %ebp
f0102b41:	89 e5                	mov    %esp,%ebp
f0102b43:	57                   	push   %edi
f0102b44:	56                   	push   %esi
f0102b45:	53                   	push   %ebx
f0102b46:	83 ec 2c             	sub    $0x2c,%esp
f0102b49:	8b 75 08             	mov    0x8(%ebp),%esi
f0102b4c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102b4f:	8b 7d 10             	mov    0x10(%ebp),%edi
f0102b52:	eb 12                	jmp    f0102b66 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0102b54:	85 c0                	test   %eax,%eax
f0102b56:	0f 84 89 03 00 00    	je     f0102ee5 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f0102b5c:	83 ec 08             	sub    $0x8,%esp
f0102b5f:	53                   	push   %ebx
f0102b60:	50                   	push   %eax
f0102b61:	ff d6                	call   *%esi
f0102b63:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0102b66:	83 c7 01             	add    $0x1,%edi
f0102b69:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102b6d:	83 f8 25             	cmp    $0x25,%eax
f0102b70:	75 e2                	jne    f0102b54 <vprintfmt+0x14>
f0102b72:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0102b76:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0102b7d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102b84:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0102b8b:	ba 00 00 00 00       	mov    $0x0,%edx
f0102b90:	eb 07                	jmp    f0102b99 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b92:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0102b95:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102b99:	8d 47 01             	lea    0x1(%edi),%eax
f0102b9c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102b9f:	0f b6 07             	movzbl (%edi),%eax
f0102ba2:	0f b6 c8             	movzbl %al,%ecx
f0102ba5:	83 e8 23             	sub    $0x23,%eax
f0102ba8:	3c 55                	cmp    $0x55,%al
f0102baa:	0f 87 1a 03 00 00    	ja     f0102eca <vprintfmt+0x38a>
f0102bb0:	0f b6 c0             	movzbl %al,%eax
f0102bb3:	ff 24 85 f0 46 10 f0 	jmp    *-0xfefb910(,%eax,4)
f0102bba:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102bbd:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0102bc1:	eb d6                	jmp    f0102b99 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bc3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102bc6:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bcb:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0102bce:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0102bd1:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0102bd5:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0102bd8:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0102bdb:	83 fa 09             	cmp    $0x9,%edx
f0102bde:	77 39                	ja     f0102c19 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102be0:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0102be3:	eb e9                	jmp    f0102bce <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0102be5:	8b 45 14             	mov    0x14(%ebp),%eax
f0102be8:	8d 48 04             	lea    0x4(%eax),%ecx
f0102beb:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0102bee:	8b 00                	mov    (%eax),%eax
f0102bf0:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102bf3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0102bf6:	eb 27                	jmp    f0102c1f <vprintfmt+0xdf>
f0102bf8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102bfb:	85 c0                	test   %eax,%eax
f0102bfd:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102c02:	0f 49 c8             	cmovns %eax,%ecx
f0102c05:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c08:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102c0b:	eb 8c                	jmp    f0102b99 <vprintfmt+0x59>
f0102c0d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0102c10:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0102c17:	eb 80                	jmp    f0102b99 <vprintfmt+0x59>
f0102c19:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102c1c:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0102c1f:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102c23:	0f 89 70 ff ff ff    	jns    f0102b99 <vprintfmt+0x59>
				width = precision, precision = -1;
f0102c29:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102c2c:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c2f:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0102c36:	e9 5e ff ff ff       	jmp    f0102b99 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102c3b:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c3e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102c41:	e9 53 ff ff ff       	jmp    f0102b99 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0102c46:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c49:	8d 50 04             	lea    0x4(%eax),%edx
f0102c4c:	89 55 14             	mov    %edx,0x14(%ebp)
f0102c4f:	83 ec 08             	sub    $0x8,%esp
f0102c52:	53                   	push   %ebx
f0102c53:	ff 30                	pushl  (%eax)
f0102c55:	ff d6                	call   *%esi
			break;
f0102c57:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c5a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102c5d:	e9 04 ff ff ff       	jmp    f0102b66 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102c62:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c65:	8d 50 04             	lea    0x4(%eax),%edx
f0102c68:	89 55 14             	mov    %edx,0x14(%ebp)
f0102c6b:	8b 00                	mov    (%eax),%eax
f0102c6d:	99                   	cltd   
f0102c6e:	31 d0                	xor    %edx,%eax
f0102c70:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0102c72:	83 f8 06             	cmp    $0x6,%eax
f0102c75:	7f 0b                	jg     f0102c82 <vprintfmt+0x142>
f0102c77:	8b 14 85 48 48 10 f0 	mov    -0xfefb7b8(,%eax,4),%edx
f0102c7e:	85 d2                	test   %edx,%edx
f0102c80:	75 18                	jne    f0102c9a <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0102c82:	50                   	push   %eax
f0102c83:	68 7c 46 10 f0       	push   $0xf010467c
f0102c88:	53                   	push   %ebx
f0102c89:	56                   	push   %esi
f0102c8a:	e8 94 fe ff ff       	call   f0102b23 <printfmt>
f0102c8f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102c92:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0102c95:	e9 cc fe ff ff       	jmp    f0102b66 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0102c9a:	52                   	push   %edx
f0102c9b:	68 30 43 10 f0       	push   $0xf0104330
f0102ca0:	53                   	push   %ebx
f0102ca1:	56                   	push   %esi
f0102ca2:	e8 7c fe ff ff       	call   f0102b23 <printfmt>
f0102ca7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102caa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102cad:	e9 b4 fe ff ff       	jmp    f0102b66 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102cb2:	8b 45 14             	mov    0x14(%ebp),%eax
f0102cb5:	8d 50 04             	lea    0x4(%eax),%edx
f0102cb8:	89 55 14             	mov    %edx,0x14(%ebp)
f0102cbb:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0102cbd:	85 ff                	test   %edi,%edi
f0102cbf:	b8 75 46 10 f0       	mov    $0xf0104675,%eax
f0102cc4:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0102cc7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0102ccb:	0f 8e 94 00 00 00    	jle    f0102d65 <vprintfmt+0x225>
f0102cd1:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0102cd5:	0f 84 98 00 00 00    	je     f0102d73 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102cdb:	83 ec 08             	sub    $0x8,%esp
f0102cde:	ff 75 d0             	pushl  -0x30(%ebp)
f0102ce1:	57                   	push   %edi
f0102ce2:	e8 5f 03 00 00       	call   f0103046 <strnlen>
f0102ce7:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102cea:	29 c1                	sub    %eax,%ecx
f0102cec:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0102cef:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0102cf2:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0102cf6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102cf9:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102cfc:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102cfe:	eb 0f                	jmp    f0102d0f <vprintfmt+0x1cf>
					putch(padc, putdat);
f0102d00:	83 ec 08             	sub    $0x8,%esp
f0102d03:	53                   	push   %ebx
f0102d04:	ff 75 e0             	pushl  -0x20(%ebp)
f0102d07:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102d09:	83 ef 01             	sub    $0x1,%edi
f0102d0c:	83 c4 10             	add    $0x10,%esp
f0102d0f:	85 ff                	test   %edi,%edi
f0102d11:	7f ed                	jg     f0102d00 <vprintfmt+0x1c0>
f0102d13:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102d16:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102d19:	85 c9                	test   %ecx,%ecx
f0102d1b:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d20:	0f 49 c1             	cmovns %ecx,%eax
f0102d23:	29 c1                	sub    %eax,%ecx
f0102d25:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d28:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d2b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d2e:	89 cb                	mov    %ecx,%ebx
f0102d30:	eb 4d                	jmp    f0102d7f <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102d32:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102d36:	74 1b                	je     f0102d53 <vprintfmt+0x213>
f0102d38:	0f be c0             	movsbl %al,%eax
f0102d3b:	83 e8 20             	sub    $0x20,%eax
f0102d3e:	83 f8 5e             	cmp    $0x5e,%eax
f0102d41:	76 10                	jbe    f0102d53 <vprintfmt+0x213>
					putch('?', putdat);
f0102d43:	83 ec 08             	sub    $0x8,%esp
f0102d46:	ff 75 0c             	pushl  0xc(%ebp)
f0102d49:	6a 3f                	push   $0x3f
f0102d4b:	ff 55 08             	call   *0x8(%ebp)
f0102d4e:	83 c4 10             	add    $0x10,%esp
f0102d51:	eb 0d                	jmp    f0102d60 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0102d53:	83 ec 08             	sub    $0x8,%esp
f0102d56:	ff 75 0c             	pushl  0xc(%ebp)
f0102d59:	52                   	push   %edx
f0102d5a:	ff 55 08             	call   *0x8(%ebp)
f0102d5d:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102d60:	83 eb 01             	sub    $0x1,%ebx
f0102d63:	eb 1a                	jmp    f0102d7f <vprintfmt+0x23f>
f0102d65:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d68:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d6b:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d6e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d71:	eb 0c                	jmp    f0102d7f <vprintfmt+0x23f>
f0102d73:	89 75 08             	mov    %esi,0x8(%ebp)
f0102d76:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0102d79:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0102d7c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0102d7f:	83 c7 01             	add    $0x1,%edi
f0102d82:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0102d86:	0f be d0             	movsbl %al,%edx
f0102d89:	85 d2                	test   %edx,%edx
f0102d8b:	74 23                	je     f0102db0 <vprintfmt+0x270>
f0102d8d:	85 f6                	test   %esi,%esi
f0102d8f:	78 a1                	js     f0102d32 <vprintfmt+0x1f2>
f0102d91:	83 ee 01             	sub    $0x1,%esi
f0102d94:	79 9c                	jns    f0102d32 <vprintfmt+0x1f2>
f0102d96:	89 df                	mov    %ebx,%edi
f0102d98:	8b 75 08             	mov    0x8(%ebp),%esi
f0102d9b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102d9e:	eb 18                	jmp    f0102db8 <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102da0:	83 ec 08             	sub    $0x8,%esp
f0102da3:	53                   	push   %ebx
f0102da4:	6a 20                	push   $0x20
f0102da6:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102da8:	83 ef 01             	sub    $0x1,%edi
f0102dab:	83 c4 10             	add    $0x10,%esp
f0102dae:	eb 08                	jmp    f0102db8 <vprintfmt+0x278>
f0102db0:	89 df                	mov    %ebx,%edi
f0102db2:	8b 75 08             	mov    0x8(%ebp),%esi
f0102db5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102db8:	85 ff                	test   %edi,%edi
f0102dba:	7f e4                	jg     f0102da0 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102dbc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102dbf:	e9 a2 fd ff ff       	jmp    f0102b66 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102dc4:	83 fa 01             	cmp    $0x1,%edx
f0102dc7:	7e 16                	jle    f0102ddf <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0102dc9:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dcc:	8d 50 08             	lea    0x8(%eax),%edx
f0102dcf:	89 55 14             	mov    %edx,0x14(%ebp)
f0102dd2:	8b 50 04             	mov    0x4(%eax),%edx
f0102dd5:	8b 00                	mov    (%eax),%eax
f0102dd7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102dda:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0102ddd:	eb 32                	jmp    f0102e11 <vprintfmt+0x2d1>
	else if (lflag)
f0102ddf:	85 d2                	test   %edx,%edx
f0102de1:	74 18                	je     f0102dfb <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0102de3:	8b 45 14             	mov    0x14(%ebp),%eax
f0102de6:	8d 50 04             	lea    0x4(%eax),%edx
f0102de9:	89 55 14             	mov    %edx,0x14(%ebp)
f0102dec:	8b 00                	mov    (%eax),%eax
f0102dee:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102df1:	89 c1                	mov    %eax,%ecx
f0102df3:	c1 f9 1f             	sar    $0x1f,%ecx
f0102df6:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0102df9:	eb 16                	jmp    f0102e11 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0102dfb:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dfe:	8d 50 04             	lea    0x4(%eax),%edx
f0102e01:	89 55 14             	mov    %edx,0x14(%ebp)
f0102e04:	8b 00                	mov    (%eax),%eax
f0102e06:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102e09:	89 c1                	mov    %eax,%ecx
f0102e0b:	c1 f9 1f             	sar    $0x1f,%ecx
f0102e0e:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102e11:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102e14:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0102e17:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0102e1c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102e20:	79 74                	jns    f0102e96 <vprintfmt+0x356>
				putch('-', putdat);
f0102e22:	83 ec 08             	sub    $0x8,%esp
f0102e25:	53                   	push   %ebx
f0102e26:	6a 2d                	push   $0x2d
f0102e28:	ff d6                	call   *%esi
				num = -(long long) num;
f0102e2a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102e2d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102e30:	f7 d8                	neg    %eax
f0102e32:	83 d2 00             	adc    $0x0,%edx
f0102e35:	f7 da                	neg    %edx
f0102e37:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0102e3a:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0102e3f:	eb 55                	jmp    f0102e96 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102e41:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e44:	e8 83 fc ff ff       	call   f0102acc <getuint>
			base = 10;
f0102e49:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0102e4e:	eb 46                	jmp    f0102e96 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
                        num = getuint(&ap, lflag);
f0102e50:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e53:	e8 74 fc ff ff       	call   f0102acc <getuint>
                        base = 8;
f0102e58:	b9 08 00 00 00       	mov    $0x8,%ecx
                        goto number;
f0102e5d:	eb 37                	jmp    f0102e96 <vprintfmt+0x356>

		// pointer
		case 'p':
			putch('0', putdat);
f0102e5f:	83 ec 08             	sub    $0x8,%esp
f0102e62:	53                   	push   %ebx
f0102e63:	6a 30                	push   $0x30
f0102e65:	ff d6                	call   *%esi
			putch('x', putdat);
f0102e67:	83 c4 08             	add    $0x8,%esp
f0102e6a:	53                   	push   %ebx
f0102e6b:	6a 78                	push   $0x78
f0102e6d:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0102e6f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102e72:	8d 50 04             	lea    0x4(%eax),%edx
f0102e75:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102e78:	8b 00                	mov    (%eax),%eax
f0102e7a:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0102e7f:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102e82:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0102e87:	eb 0d                	jmp    f0102e96 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102e89:	8d 45 14             	lea    0x14(%ebp),%eax
f0102e8c:	e8 3b fc ff ff       	call   f0102acc <getuint>
			base = 16;
f0102e91:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102e96:	83 ec 0c             	sub    $0xc,%esp
f0102e99:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0102e9d:	57                   	push   %edi
f0102e9e:	ff 75 e0             	pushl  -0x20(%ebp)
f0102ea1:	51                   	push   %ecx
f0102ea2:	52                   	push   %edx
f0102ea3:	50                   	push   %eax
f0102ea4:	89 da                	mov    %ebx,%edx
f0102ea6:	89 f0                	mov    %esi,%eax
f0102ea8:	e8 70 fb ff ff       	call   f0102a1d <printnum>
			break;
f0102ead:	83 c4 20             	add    $0x20,%esp
f0102eb0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102eb3:	e9 ae fc ff ff       	jmp    f0102b66 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102eb8:	83 ec 08             	sub    $0x8,%esp
f0102ebb:	53                   	push   %ebx
f0102ebc:	51                   	push   %ecx
f0102ebd:	ff d6                	call   *%esi
			break;
f0102ebf:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102ec2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0102ec5:	e9 9c fc ff ff       	jmp    f0102b66 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102eca:	83 ec 08             	sub    $0x8,%esp
f0102ecd:	53                   	push   %ebx
f0102ece:	6a 25                	push   $0x25
f0102ed0:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0102ed2:	83 c4 10             	add    $0x10,%esp
f0102ed5:	eb 03                	jmp    f0102eda <vprintfmt+0x39a>
f0102ed7:	83 ef 01             	sub    $0x1,%edi
f0102eda:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0102ede:	75 f7                	jne    f0102ed7 <vprintfmt+0x397>
f0102ee0:	e9 81 fc ff ff       	jmp    f0102b66 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0102ee5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102ee8:	5b                   	pop    %ebx
f0102ee9:	5e                   	pop    %esi
f0102eea:	5f                   	pop    %edi
f0102eeb:	5d                   	pop    %ebp
f0102eec:	c3                   	ret    

f0102eed <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102eed:	55                   	push   %ebp
f0102eee:	89 e5                	mov    %esp,%ebp
f0102ef0:	83 ec 18             	sub    $0x18,%esp
f0102ef3:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ef6:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102ef9:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102efc:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0102f00:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102f03:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0102f0a:	85 c0                	test   %eax,%eax
f0102f0c:	74 26                	je     f0102f34 <vsnprintf+0x47>
f0102f0e:	85 d2                	test   %edx,%edx
f0102f10:	7e 22                	jle    f0102f34 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102f12:	ff 75 14             	pushl  0x14(%ebp)
f0102f15:	ff 75 10             	pushl  0x10(%ebp)
f0102f18:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0102f1b:	50                   	push   %eax
f0102f1c:	68 06 2b 10 f0       	push   $0xf0102b06
f0102f21:	e8 1a fc ff ff       	call   f0102b40 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102f26:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102f29:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102f2c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f2f:	83 c4 10             	add    $0x10,%esp
f0102f32:	eb 05                	jmp    f0102f39 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102f34:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0102f39:	c9                   	leave  
f0102f3a:	c3                   	ret    

f0102f3b <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102f3b:	55                   	push   %ebp
f0102f3c:	89 e5                	mov    %esp,%ebp
f0102f3e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102f41:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102f44:	50                   	push   %eax
f0102f45:	ff 75 10             	pushl  0x10(%ebp)
f0102f48:	ff 75 0c             	pushl  0xc(%ebp)
f0102f4b:	ff 75 08             	pushl  0x8(%ebp)
f0102f4e:	e8 9a ff ff ff       	call   f0102eed <vsnprintf>
	va_end(ap);

	return rc;
}
f0102f53:	c9                   	leave  
f0102f54:	c3                   	ret    

f0102f55 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102f55:	55                   	push   %ebp
f0102f56:	89 e5                	mov    %esp,%ebp
f0102f58:	57                   	push   %edi
f0102f59:	56                   	push   %esi
f0102f5a:	53                   	push   %ebx
f0102f5b:	83 ec 0c             	sub    $0xc,%esp
f0102f5e:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0102f61:	85 c0                	test   %eax,%eax
f0102f63:	74 11                	je     f0102f76 <readline+0x21>
		cprintf("%s", prompt);
f0102f65:	83 ec 08             	sub    $0x8,%esp
f0102f68:	50                   	push   %eax
f0102f69:	68 30 43 10 f0       	push   $0xf0104330
f0102f6e:	e8 90 f7 ff ff       	call   f0102703 <cprintf>
f0102f73:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0102f76:	83 ec 0c             	sub    $0xc,%esp
f0102f79:	6a 00                	push   $0x0
f0102f7b:	e8 a1 d6 ff ff       	call   f0100621 <iscons>
f0102f80:	89 c7                	mov    %eax,%edi
f0102f82:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0102f85:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102f8a:	e8 81 d6 ff ff       	call   f0100610 <getchar>
f0102f8f:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0102f91:	85 c0                	test   %eax,%eax
f0102f93:	79 18                	jns    f0102fad <readline+0x58>
			cprintf("read error: %e\n", c);
f0102f95:	83 ec 08             	sub    $0x8,%esp
f0102f98:	50                   	push   %eax
f0102f99:	68 64 48 10 f0       	push   $0xf0104864
f0102f9e:	e8 60 f7 ff ff       	call   f0102703 <cprintf>
			return NULL;
f0102fa3:	83 c4 10             	add    $0x10,%esp
f0102fa6:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fab:	eb 79                	jmp    f0103026 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0102fad:	83 f8 08             	cmp    $0x8,%eax
f0102fb0:	0f 94 c2             	sete   %dl
f0102fb3:	83 f8 7f             	cmp    $0x7f,%eax
f0102fb6:	0f 94 c0             	sete   %al
f0102fb9:	08 c2                	or     %al,%dl
f0102fbb:	74 1a                	je     f0102fd7 <readline+0x82>
f0102fbd:	85 f6                	test   %esi,%esi
f0102fbf:	7e 16                	jle    f0102fd7 <readline+0x82>
			if (echoing)
f0102fc1:	85 ff                	test   %edi,%edi
f0102fc3:	74 0d                	je     f0102fd2 <readline+0x7d>
				cputchar('\b');
f0102fc5:	83 ec 0c             	sub    $0xc,%esp
f0102fc8:	6a 08                	push   $0x8
f0102fca:	e8 31 d6 ff ff       	call   f0100600 <cputchar>
f0102fcf:	83 c4 10             	add    $0x10,%esp
			i--;
f0102fd2:	83 ee 01             	sub    $0x1,%esi
f0102fd5:	eb b3                	jmp    f0102f8a <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102fd7:	83 fb 1f             	cmp    $0x1f,%ebx
f0102fda:	7e 23                	jle    f0102fff <readline+0xaa>
f0102fdc:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0102fe2:	7f 1b                	jg     f0102fff <readline+0xaa>
			if (echoing)
f0102fe4:	85 ff                	test   %edi,%edi
f0102fe6:	74 0c                	je     f0102ff4 <readline+0x9f>
				cputchar(c);
f0102fe8:	83 ec 0c             	sub    $0xc,%esp
f0102feb:	53                   	push   %ebx
f0102fec:	e8 0f d6 ff ff       	call   f0100600 <cputchar>
f0102ff1:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0102ff4:	88 9e 60 75 11 f0    	mov    %bl,-0xfee8aa0(%esi)
f0102ffa:	8d 76 01             	lea    0x1(%esi),%esi
f0102ffd:	eb 8b                	jmp    f0102f8a <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0102fff:	83 fb 0a             	cmp    $0xa,%ebx
f0103002:	74 05                	je     f0103009 <readline+0xb4>
f0103004:	83 fb 0d             	cmp    $0xd,%ebx
f0103007:	75 81                	jne    f0102f8a <readline+0x35>
			if (echoing)
f0103009:	85 ff                	test   %edi,%edi
f010300b:	74 0d                	je     f010301a <readline+0xc5>
				cputchar('\n');
f010300d:	83 ec 0c             	sub    $0xc,%esp
f0103010:	6a 0a                	push   $0xa
f0103012:	e8 e9 d5 ff ff       	call   f0100600 <cputchar>
f0103017:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010301a:	c6 86 60 75 11 f0 00 	movb   $0x0,-0xfee8aa0(%esi)
			return buf;
f0103021:	b8 60 75 11 f0       	mov    $0xf0117560,%eax
		}
	}
}
f0103026:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103029:	5b                   	pop    %ebx
f010302a:	5e                   	pop    %esi
f010302b:	5f                   	pop    %edi
f010302c:	5d                   	pop    %ebp
f010302d:	c3                   	ret    

f010302e <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010302e:	55                   	push   %ebp
f010302f:	89 e5                	mov    %esp,%ebp
f0103031:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103034:	b8 00 00 00 00       	mov    $0x0,%eax
f0103039:	eb 03                	jmp    f010303e <strlen+0x10>
		n++;
f010303b:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010303e:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103042:	75 f7                	jne    f010303b <strlen+0xd>
		n++;
	return n;
}
f0103044:	5d                   	pop    %ebp
f0103045:	c3                   	ret    

f0103046 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103046:	55                   	push   %ebp
f0103047:	89 e5                	mov    %esp,%ebp
f0103049:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010304c:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010304f:	ba 00 00 00 00       	mov    $0x0,%edx
f0103054:	eb 03                	jmp    f0103059 <strnlen+0x13>
		n++;
f0103056:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103059:	39 c2                	cmp    %eax,%edx
f010305b:	74 08                	je     f0103065 <strnlen+0x1f>
f010305d:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0103061:	75 f3                	jne    f0103056 <strnlen+0x10>
f0103063:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0103065:	5d                   	pop    %ebp
f0103066:	c3                   	ret    

f0103067 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103067:	55                   	push   %ebp
f0103068:	89 e5                	mov    %esp,%ebp
f010306a:	53                   	push   %ebx
f010306b:	8b 45 08             	mov    0x8(%ebp),%eax
f010306e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103071:	89 c2                	mov    %eax,%edx
f0103073:	83 c2 01             	add    $0x1,%edx
f0103076:	83 c1 01             	add    $0x1,%ecx
f0103079:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010307d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103080:	84 db                	test   %bl,%bl
f0103082:	75 ef                	jne    f0103073 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103084:	5b                   	pop    %ebx
f0103085:	5d                   	pop    %ebp
f0103086:	c3                   	ret    

f0103087 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103087:	55                   	push   %ebp
f0103088:	89 e5                	mov    %esp,%ebp
f010308a:	53                   	push   %ebx
f010308b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010308e:	53                   	push   %ebx
f010308f:	e8 9a ff ff ff       	call   f010302e <strlen>
f0103094:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0103097:	ff 75 0c             	pushl  0xc(%ebp)
f010309a:	01 d8                	add    %ebx,%eax
f010309c:	50                   	push   %eax
f010309d:	e8 c5 ff ff ff       	call   f0103067 <strcpy>
	return dst;
}
f01030a2:	89 d8                	mov    %ebx,%eax
f01030a4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01030a7:	c9                   	leave  
f01030a8:	c3                   	ret    

f01030a9 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01030a9:	55                   	push   %ebp
f01030aa:	89 e5                	mov    %esp,%ebp
f01030ac:	56                   	push   %esi
f01030ad:	53                   	push   %ebx
f01030ae:	8b 75 08             	mov    0x8(%ebp),%esi
f01030b1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01030b4:	89 f3                	mov    %esi,%ebx
f01030b6:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01030b9:	89 f2                	mov    %esi,%edx
f01030bb:	eb 0f                	jmp    f01030cc <strncpy+0x23>
		*dst++ = *src;
f01030bd:	83 c2 01             	add    $0x1,%edx
f01030c0:	0f b6 01             	movzbl (%ecx),%eax
f01030c3:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01030c6:	80 39 01             	cmpb   $0x1,(%ecx)
f01030c9:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01030cc:	39 da                	cmp    %ebx,%edx
f01030ce:	75 ed                	jne    f01030bd <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01030d0:	89 f0                	mov    %esi,%eax
f01030d2:	5b                   	pop    %ebx
f01030d3:	5e                   	pop    %esi
f01030d4:	5d                   	pop    %ebp
f01030d5:	c3                   	ret    

f01030d6 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01030d6:	55                   	push   %ebp
f01030d7:	89 e5                	mov    %esp,%ebp
f01030d9:	56                   	push   %esi
f01030da:	53                   	push   %ebx
f01030db:	8b 75 08             	mov    0x8(%ebp),%esi
f01030de:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01030e1:	8b 55 10             	mov    0x10(%ebp),%edx
f01030e4:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01030e6:	85 d2                	test   %edx,%edx
f01030e8:	74 21                	je     f010310b <strlcpy+0x35>
f01030ea:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01030ee:	89 f2                	mov    %esi,%edx
f01030f0:	eb 09                	jmp    f01030fb <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01030f2:	83 c2 01             	add    $0x1,%edx
f01030f5:	83 c1 01             	add    $0x1,%ecx
f01030f8:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01030fb:	39 c2                	cmp    %eax,%edx
f01030fd:	74 09                	je     f0103108 <strlcpy+0x32>
f01030ff:	0f b6 19             	movzbl (%ecx),%ebx
f0103102:	84 db                	test   %bl,%bl
f0103104:	75 ec                	jne    f01030f2 <strlcpy+0x1c>
f0103106:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103108:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010310b:	29 f0                	sub    %esi,%eax
}
f010310d:	5b                   	pop    %ebx
f010310e:	5e                   	pop    %esi
f010310f:	5d                   	pop    %ebp
f0103110:	c3                   	ret    

f0103111 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103111:	55                   	push   %ebp
f0103112:	89 e5                	mov    %esp,%ebp
f0103114:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103117:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010311a:	eb 06                	jmp    f0103122 <strcmp+0x11>
		p++, q++;
f010311c:	83 c1 01             	add    $0x1,%ecx
f010311f:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103122:	0f b6 01             	movzbl (%ecx),%eax
f0103125:	84 c0                	test   %al,%al
f0103127:	74 04                	je     f010312d <strcmp+0x1c>
f0103129:	3a 02                	cmp    (%edx),%al
f010312b:	74 ef                	je     f010311c <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010312d:	0f b6 c0             	movzbl %al,%eax
f0103130:	0f b6 12             	movzbl (%edx),%edx
f0103133:	29 d0                	sub    %edx,%eax
}
f0103135:	5d                   	pop    %ebp
f0103136:	c3                   	ret    

f0103137 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103137:	55                   	push   %ebp
f0103138:	89 e5                	mov    %esp,%ebp
f010313a:	53                   	push   %ebx
f010313b:	8b 45 08             	mov    0x8(%ebp),%eax
f010313e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103141:	89 c3                	mov    %eax,%ebx
f0103143:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103146:	eb 06                	jmp    f010314e <strncmp+0x17>
		n--, p++, q++;
f0103148:	83 c0 01             	add    $0x1,%eax
f010314b:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010314e:	39 d8                	cmp    %ebx,%eax
f0103150:	74 15                	je     f0103167 <strncmp+0x30>
f0103152:	0f b6 08             	movzbl (%eax),%ecx
f0103155:	84 c9                	test   %cl,%cl
f0103157:	74 04                	je     f010315d <strncmp+0x26>
f0103159:	3a 0a                	cmp    (%edx),%cl
f010315b:	74 eb                	je     f0103148 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010315d:	0f b6 00             	movzbl (%eax),%eax
f0103160:	0f b6 12             	movzbl (%edx),%edx
f0103163:	29 d0                	sub    %edx,%eax
f0103165:	eb 05                	jmp    f010316c <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103167:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010316c:	5b                   	pop    %ebx
f010316d:	5d                   	pop    %ebp
f010316e:	c3                   	ret    

f010316f <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010316f:	55                   	push   %ebp
f0103170:	89 e5                	mov    %esp,%ebp
f0103172:	8b 45 08             	mov    0x8(%ebp),%eax
f0103175:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103179:	eb 07                	jmp    f0103182 <strchr+0x13>
		if (*s == c)
f010317b:	38 ca                	cmp    %cl,%dl
f010317d:	74 0f                	je     f010318e <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010317f:	83 c0 01             	add    $0x1,%eax
f0103182:	0f b6 10             	movzbl (%eax),%edx
f0103185:	84 d2                	test   %dl,%dl
f0103187:	75 f2                	jne    f010317b <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103189:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010318e:	5d                   	pop    %ebp
f010318f:	c3                   	ret    

f0103190 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103190:	55                   	push   %ebp
f0103191:	89 e5                	mov    %esp,%ebp
f0103193:	8b 45 08             	mov    0x8(%ebp),%eax
f0103196:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010319a:	eb 03                	jmp    f010319f <strfind+0xf>
f010319c:	83 c0 01             	add    $0x1,%eax
f010319f:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01031a2:	38 ca                	cmp    %cl,%dl
f01031a4:	74 04                	je     f01031aa <strfind+0x1a>
f01031a6:	84 d2                	test   %dl,%dl
f01031a8:	75 f2                	jne    f010319c <strfind+0xc>
			break;
	return (char *) s;
}
f01031aa:	5d                   	pop    %ebp
f01031ab:	c3                   	ret    

f01031ac <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01031ac:	55                   	push   %ebp
f01031ad:	89 e5                	mov    %esp,%ebp
f01031af:	57                   	push   %edi
f01031b0:	56                   	push   %esi
f01031b1:	53                   	push   %ebx
f01031b2:	8b 7d 08             	mov    0x8(%ebp),%edi
f01031b5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01031b8:	85 c9                	test   %ecx,%ecx
f01031ba:	74 36                	je     f01031f2 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01031bc:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01031c2:	75 28                	jne    f01031ec <memset+0x40>
f01031c4:	f6 c1 03             	test   $0x3,%cl
f01031c7:	75 23                	jne    f01031ec <memset+0x40>
		c &= 0xFF;
f01031c9:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01031cd:	89 d3                	mov    %edx,%ebx
f01031cf:	c1 e3 08             	shl    $0x8,%ebx
f01031d2:	89 d6                	mov    %edx,%esi
f01031d4:	c1 e6 18             	shl    $0x18,%esi
f01031d7:	89 d0                	mov    %edx,%eax
f01031d9:	c1 e0 10             	shl    $0x10,%eax
f01031dc:	09 f0                	or     %esi,%eax
f01031de:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01031e0:	89 d8                	mov    %ebx,%eax
f01031e2:	09 d0                	or     %edx,%eax
f01031e4:	c1 e9 02             	shr    $0x2,%ecx
f01031e7:	fc                   	cld    
f01031e8:	f3 ab                	rep stos %eax,%es:(%edi)
f01031ea:	eb 06                	jmp    f01031f2 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01031ec:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031ef:	fc                   	cld    
f01031f0:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01031f2:	89 f8                	mov    %edi,%eax
f01031f4:	5b                   	pop    %ebx
f01031f5:	5e                   	pop    %esi
f01031f6:	5f                   	pop    %edi
f01031f7:	5d                   	pop    %ebp
f01031f8:	c3                   	ret    

f01031f9 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01031f9:	55                   	push   %ebp
f01031fa:	89 e5                	mov    %esp,%ebp
f01031fc:	57                   	push   %edi
f01031fd:	56                   	push   %esi
f01031fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0103201:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103204:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103207:	39 c6                	cmp    %eax,%esi
f0103209:	73 35                	jae    f0103240 <memmove+0x47>
f010320b:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010320e:	39 d0                	cmp    %edx,%eax
f0103210:	73 2e                	jae    f0103240 <memmove+0x47>
		s += n;
		d += n;
f0103212:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103215:	89 d6                	mov    %edx,%esi
f0103217:	09 fe                	or     %edi,%esi
f0103219:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010321f:	75 13                	jne    f0103234 <memmove+0x3b>
f0103221:	f6 c1 03             	test   $0x3,%cl
f0103224:	75 0e                	jne    f0103234 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0103226:	83 ef 04             	sub    $0x4,%edi
f0103229:	8d 72 fc             	lea    -0x4(%edx),%esi
f010322c:	c1 e9 02             	shr    $0x2,%ecx
f010322f:	fd                   	std    
f0103230:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103232:	eb 09                	jmp    f010323d <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103234:	83 ef 01             	sub    $0x1,%edi
f0103237:	8d 72 ff             	lea    -0x1(%edx),%esi
f010323a:	fd                   	std    
f010323b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010323d:	fc                   	cld    
f010323e:	eb 1d                	jmp    f010325d <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103240:	89 f2                	mov    %esi,%edx
f0103242:	09 c2                	or     %eax,%edx
f0103244:	f6 c2 03             	test   $0x3,%dl
f0103247:	75 0f                	jne    f0103258 <memmove+0x5f>
f0103249:	f6 c1 03             	test   $0x3,%cl
f010324c:	75 0a                	jne    f0103258 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f010324e:	c1 e9 02             	shr    $0x2,%ecx
f0103251:	89 c7                	mov    %eax,%edi
f0103253:	fc                   	cld    
f0103254:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103256:	eb 05                	jmp    f010325d <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103258:	89 c7                	mov    %eax,%edi
f010325a:	fc                   	cld    
f010325b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010325d:	5e                   	pop    %esi
f010325e:	5f                   	pop    %edi
f010325f:	5d                   	pop    %ebp
f0103260:	c3                   	ret    

f0103261 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103261:	55                   	push   %ebp
f0103262:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0103264:	ff 75 10             	pushl  0x10(%ebp)
f0103267:	ff 75 0c             	pushl  0xc(%ebp)
f010326a:	ff 75 08             	pushl  0x8(%ebp)
f010326d:	e8 87 ff ff ff       	call   f01031f9 <memmove>
}
f0103272:	c9                   	leave  
f0103273:	c3                   	ret    

f0103274 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103274:	55                   	push   %ebp
f0103275:	89 e5                	mov    %esp,%ebp
f0103277:	56                   	push   %esi
f0103278:	53                   	push   %ebx
f0103279:	8b 45 08             	mov    0x8(%ebp),%eax
f010327c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010327f:	89 c6                	mov    %eax,%esi
f0103281:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103284:	eb 1a                	jmp    f01032a0 <memcmp+0x2c>
		if (*s1 != *s2)
f0103286:	0f b6 08             	movzbl (%eax),%ecx
f0103289:	0f b6 1a             	movzbl (%edx),%ebx
f010328c:	38 d9                	cmp    %bl,%cl
f010328e:	74 0a                	je     f010329a <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103290:	0f b6 c1             	movzbl %cl,%eax
f0103293:	0f b6 db             	movzbl %bl,%ebx
f0103296:	29 d8                	sub    %ebx,%eax
f0103298:	eb 0f                	jmp    f01032a9 <memcmp+0x35>
		s1++, s2++;
f010329a:	83 c0 01             	add    $0x1,%eax
f010329d:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01032a0:	39 f0                	cmp    %esi,%eax
f01032a2:	75 e2                	jne    f0103286 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01032a4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01032a9:	5b                   	pop    %ebx
f01032aa:	5e                   	pop    %esi
f01032ab:	5d                   	pop    %ebp
f01032ac:	c3                   	ret    

f01032ad <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01032ad:	55                   	push   %ebp
f01032ae:	89 e5                	mov    %esp,%ebp
f01032b0:	53                   	push   %ebx
f01032b1:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01032b4:	89 c1                	mov    %eax,%ecx
f01032b6:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01032b9:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01032bd:	eb 0a                	jmp    f01032c9 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f01032bf:	0f b6 10             	movzbl (%eax),%edx
f01032c2:	39 da                	cmp    %ebx,%edx
f01032c4:	74 07                	je     f01032cd <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01032c6:	83 c0 01             	add    $0x1,%eax
f01032c9:	39 c8                	cmp    %ecx,%eax
f01032cb:	72 f2                	jb     f01032bf <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01032cd:	5b                   	pop    %ebx
f01032ce:	5d                   	pop    %ebp
f01032cf:	c3                   	ret    

f01032d0 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01032d0:	55                   	push   %ebp
f01032d1:	89 e5                	mov    %esp,%ebp
f01032d3:	57                   	push   %edi
f01032d4:	56                   	push   %esi
f01032d5:	53                   	push   %ebx
f01032d6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01032d9:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01032dc:	eb 03                	jmp    f01032e1 <strtol+0x11>
		s++;
f01032de:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01032e1:	0f b6 01             	movzbl (%ecx),%eax
f01032e4:	3c 20                	cmp    $0x20,%al
f01032e6:	74 f6                	je     f01032de <strtol+0xe>
f01032e8:	3c 09                	cmp    $0x9,%al
f01032ea:	74 f2                	je     f01032de <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01032ec:	3c 2b                	cmp    $0x2b,%al
f01032ee:	75 0a                	jne    f01032fa <strtol+0x2a>
		s++;
f01032f0:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01032f3:	bf 00 00 00 00       	mov    $0x0,%edi
f01032f8:	eb 11                	jmp    f010330b <strtol+0x3b>
f01032fa:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01032ff:	3c 2d                	cmp    $0x2d,%al
f0103301:	75 08                	jne    f010330b <strtol+0x3b>
		s++, neg = 1;
f0103303:	83 c1 01             	add    $0x1,%ecx
f0103306:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010330b:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103311:	75 15                	jne    f0103328 <strtol+0x58>
f0103313:	80 39 30             	cmpb   $0x30,(%ecx)
f0103316:	75 10                	jne    f0103328 <strtol+0x58>
f0103318:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010331c:	75 7c                	jne    f010339a <strtol+0xca>
		s += 2, base = 16;
f010331e:	83 c1 02             	add    $0x2,%ecx
f0103321:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103326:	eb 16                	jmp    f010333e <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0103328:	85 db                	test   %ebx,%ebx
f010332a:	75 12                	jne    f010333e <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010332c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103331:	80 39 30             	cmpb   $0x30,(%ecx)
f0103334:	75 08                	jne    f010333e <strtol+0x6e>
		s++, base = 8;
f0103336:	83 c1 01             	add    $0x1,%ecx
f0103339:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010333e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103343:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103346:	0f b6 11             	movzbl (%ecx),%edx
f0103349:	8d 72 d0             	lea    -0x30(%edx),%esi
f010334c:	89 f3                	mov    %esi,%ebx
f010334e:	80 fb 09             	cmp    $0x9,%bl
f0103351:	77 08                	ja     f010335b <strtol+0x8b>
			dig = *s - '0';
f0103353:	0f be d2             	movsbl %dl,%edx
f0103356:	83 ea 30             	sub    $0x30,%edx
f0103359:	eb 22                	jmp    f010337d <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010335b:	8d 72 9f             	lea    -0x61(%edx),%esi
f010335e:	89 f3                	mov    %esi,%ebx
f0103360:	80 fb 19             	cmp    $0x19,%bl
f0103363:	77 08                	ja     f010336d <strtol+0x9d>
			dig = *s - 'a' + 10;
f0103365:	0f be d2             	movsbl %dl,%edx
f0103368:	83 ea 57             	sub    $0x57,%edx
f010336b:	eb 10                	jmp    f010337d <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f010336d:	8d 72 bf             	lea    -0x41(%edx),%esi
f0103370:	89 f3                	mov    %esi,%ebx
f0103372:	80 fb 19             	cmp    $0x19,%bl
f0103375:	77 16                	ja     f010338d <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103377:	0f be d2             	movsbl %dl,%edx
f010337a:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010337d:	3b 55 10             	cmp    0x10(%ebp),%edx
f0103380:	7d 0b                	jge    f010338d <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0103382:	83 c1 01             	add    $0x1,%ecx
f0103385:	0f af 45 10          	imul   0x10(%ebp),%eax
f0103389:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010338b:	eb b9                	jmp    f0103346 <strtol+0x76>

	if (endptr)
f010338d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103391:	74 0d                	je     f01033a0 <strtol+0xd0>
		*endptr = (char *) s;
f0103393:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103396:	89 0e                	mov    %ecx,(%esi)
f0103398:	eb 06                	jmp    f01033a0 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010339a:	85 db                	test   %ebx,%ebx
f010339c:	74 98                	je     f0103336 <strtol+0x66>
f010339e:	eb 9e                	jmp    f010333e <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01033a0:	89 c2                	mov    %eax,%edx
f01033a2:	f7 da                	neg    %edx
f01033a4:	85 ff                	test   %edi,%edi
f01033a6:	0f 45 c2             	cmovne %edx,%eax
}
f01033a9:	5b                   	pop    %ebx
f01033aa:	5e                   	pop    %esi
f01033ab:	5f                   	pop    %edi
f01033ac:	5d                   	pop    %ebp
f01033ad:	c3                   	ret    
f01033ae:	66 90                	xchg   %ax,%ax

f01033b0 <__udivdi3>:
f01033b0:	55                   	push   %ebp
f01033b1:	57                   	push   %edi
f01033b2:	56                   	push   %esi
f01033b3:	53                   	push   %ebx
f01033b4:	83 ec 1c             	sub    $0x1c,%esp
f01033b7:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f01033bb:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f01033bf:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01033c3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01033c7:	85 f6                	test   %esi,%esi
f01033c9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01033cd:	89 ca                	mov    %ecx,%edx
f01033cf:	89 f8                	mov    %edi,%eax
f01033d1:	75 3d                	jne    f0103410 <__udivdi3+0x60>
f01033d3:	39 cf                	cmp    %ecx,%edi
f01033d5:	0f 87 c5 00 00 00    	ja     f01034a0 <__udivdi3+0xf0>
f01033db:	85 ff                	test   %edi,%edi
f01033dd:	89 fd                	mov    %edi,%ebp
f01033df:	75 0b                	jne    f01033ec <__udivdi3+0x3c>
f01033e1:	b8 01 00 00 00       	mov    $0x1,%eax
f01033e6:	31 d2                	xor    %edx,%edx
f01033e8:	f7 f7                	div    %edi
f01033ea:	89 c5                	mov    %eax,%ebp
f01033ec:	89 c8                	mov    %ecx,%eax
f01033ee:	31 d2                	xor    %edx,%edx
f01033f0:	f7 f5                	div    %ebp
f01033f2:	89 c1                	mov    %eax,%ecx
f01033f4:	89 d8                	mov    %ebx,%eax
f01033f6:	89 cf                	mov    %ecx,%edi
f01033f8:	f7 f5                	div    %ebp
f01033fa:	89 c3                	mov    %eax,%ebx
f01033fc:	89 d8                	mov    %ebx,%eax
f01033fe:	89 fa                	mov    %edi,%edx
f0103400:	83 c4 1c             	add    $0x1c,%esp
f0103403:	5b                   	pop    %ebx
f0103404:	5e                   	pop    %esi
f0103405:	5f                   	pop    %edi
f0103406:	5d                   	pop    %ebp
f0103407:	c3                   	ret    
f0103408:	90                   	nop
f0103409:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103410:	39 ce                	cmp    %ecx,%esi
f0103412:	77 74                	ja     f0103488 <__udivdi3+0xd8>
f0103414:	0f bd fe             	bsr    %esi,%edi
f0103417:	83 f7 1f             	xor    $0x1f,%edi
f010341a:	0f 84 98 00 00 00    	je     f01034b8 <__udivdi3+0x108>
f0103420:	bb 20 00 00 00       	mov    $0x20,%ebx
f0103425:	89 f9                	mov    %edi,%ecx
f0103427:	89 c5                	mov    %eax,%ebp
f0103429:	29 fb                	sub    %edi,%ebx
f010342b:	d3 e6                	shl    %cl,%esi
f010342d:	89 d9                	mov    %ebx,%ecx
f010342f:	d3 ed                	shr    %cl,%ebp
f0103431:	89 f9                	mov    %edi,%ecx
f0103433:	d3 e0                	shl    %cl,%eax
f0103435:	09 ee                	or     %ebp,%esi
f0103437:	89 d9                	mov    %ebx,%ecx
f0103439:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010343d:	89 d5                	mov    %edx,%ebp
f010343f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103443:	d3 ed                	shr    %cl,%ebp
f0103445:	89 f9                	mov    %edi,%ecx
f0103447:	d3 e2                	shl    %cl,%edx
f0103449:	89 d9                	mov    %ebx,%ecx
f010344b:	d3 e8                	shr    %cl,%eax
f010344d:	09 c2                	or     %eax,%edx
f010344f:	89 d0                	mov    %edx,%eax
f0103451:	89 ea                	mov    %ebp,%edx
f0103453:	f7 f6                	div    %esi
f0103455:	89 d5                	mov    %edx,%ebp
f0103457:	89 c3                	mov    %eax,%ebx
f0103459:	f7 64 24 0c          	mull   0xc(%esp)
f010345d:	39 d5                	cmp    %edx,%ebp
f010345f:	72 10                	jb     f0103471 <__udivdi3+0xc1>
f0103461:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103465:	89 f9                	mov    %edi,%ecx
f0103467:	d3 e6                	shl    %cl,%esi
f0103469:	39 c6                	cmp    %eax,%esi
f010346b:	73 07                	jae    f0103474 <__udivdi3+0xc4>
f010346d:	39 d5                	cmp    %edx,%ebp
f010346f:	75 03                	jne    f0103474 <__udivdi3+0xc4>
f0103471:	83 eb 01             	sub    $0x1,%ebx
f0103474:	31 ff                	xor    %edi,%edi
f0103476:	89 d8                	mov    %ebx,%eax
f0103478:	89 fa                	mov    %edi,%edx
f010347a:	83 c4 1c             	add    $0x1c,%esp
f010347d:	5b                   	pop    %ebx
f010347e:	5e                   	pop    %esi
f010347f:	5f                   	pop    %edi
f0103480:	5d                   	pop    %ebp
f0103481:	c3                   	ret    
f0103482:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103488:	31 ff                	xor    %edi,%edi
f010348a:	31 db                	xor    %ebx,%ebx
f010348c:	89 d8                	mov    %ebx,%eax
f010348e:	89 fa                	mov    %edi,%edx
f0103490:	83 c4 1c             	add    $0x1c,%esp
f0103493:	5b                   	pop    %ebx
f0103494:	5e                   	pop    %esi
f0103495:	5f                   	pop    %edi
f0103496:	5d                   	pop    %ebp
f0103497:	c3                   	ret    
f0103498:	90                   	nop
f0103499:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01034a0:	89 d8                	mov    %ebx,%eax
f01034a2:	f7 f7                	div    %edi
f01034a4:	31 ff                	xor    %edi,%edi
f01034a6:	89 c3                	mov    %eax,%ebx
f01034a8:	89 d8                	mov    %ebx,%eax
f01034aa:	89 fa                	mov    %edi,%edx
f01034ac:	83 c4 1c             	add    $0x1c,%esp
f01034af:	5b                   	pop    %ebx
f01034b0:	5e                   	pop    %esi
f01034b1:	5f                   	pop    %edi
f01034b2:	5d                   	pop    %ebp
f01034b3:	c3                   	ret    
f01034b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01034b8:	39 ce                	cmp    %ecx,%esi
f01034ba:	72 0c                	jb     f01034c8 <__udivdi3+0x118>
f01034bc:	31 db                	xor    %ebx,%ebx
f01034be:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01034c2:	0f 87 34 ff ff ff    	ja     f01033fc <__udivdi3+0x4c>
f01034c8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01034cd:	e9 2a ff ff ff       	jmp    f01033fc <__udivdi3+0x4c>
f01034d2:	66 90                	xchg   %ax,%ax
f01034d4:	66 90                	xchg   %ax,%ax
f01034d6:	66 90                	xchg   %ax,%ax
f01034d8:	66 90                	xchg   %ax,%ax
f01034da:	66 90                	xchg   %ax,%ax
f01034dc:	66 90                	xchg   %ax,%ax
f01034de:	66 90                	xchg   %ax,%ax

f01034e0 <__umoddi3>:
f01034e0:	55                   	push   %ebp
f01034e1:	57                   	push   %edi
f01034e2:	56                   	push   %esi
f01034e3:	53                   	push   %ebx
f01034e4:	83 ec 1c             	sub    $0x1c,%esp
f01034e7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01034eb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01034ef:	8b 74 24 34          	mov    0x34(%esp),%esi
f01034f3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01034f7:	85 d2                	test   %edx,%edx
f01034f9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01034fd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103501:	89 f3                	mov    %esi,%ebx
f0103503:	89 3c 24             	mov    %edi,(%esp)
f0103506:	89 74 24 04          	mov    %esi,0x4(%esp)
f010350a:	75 1c                	jne    f0103528 <__umoddi3+0x48>
f010350c:	39 f7                	cmp    %esi,%edi
f010350e:	76 50                	jbe    f0103560 <__umoddi3+0x80>
f0103510:	89 c8                	mov    %ecx,%eax
f0103512:	89 f2                	mov    %esi,%edx
f0103514:	f7 f7                	div    %edi
f0103516:	89 d0                	mov    %edx,%eax
f0103518:	31 d2                	xor    %edx,%edx
f010351a:	83 c4 1c             	add    $0x1c,%esp
f010351d:	5b                   	pop    %ebx
f010351e:	5e                   	pop    %esi
f010351f:	5f                   	pop    %edi
f0103520:	5d                   	pop    %ebp
f0103521:	c3                   	ret    
f0103522:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103528:	39 f2                	cmp    %esi,%edx
f010352a:	89 d0                	mov    %edx,%eax
f010352c:	77 52                	ja     f0103580 <__umoddi3+0xa0>
f010352e:	0f bd ea             	bsr    %edx,%ebp
f0103531:	83 f5 1f             	xor    $0x1f,%ebp
f0103534:	75 5a                	jne    f0103590 <__umoddi3+0xb0>
f0103536:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010353a:	0f 82 e0 00 00 00    	jb     f0103620 <__umoddi3+0x140>
f0103540:	39 0c 24             	cmp    %ecx,(%esp)
f0103543:	0f 86 d7 00 00 00    	jbe    f0103620 <__umoddi3+0x140>
f0103549:	8b 44 24 08          	mov    0x8(%esp),%eax
f010354d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103551:	83 c4 1c             	add    $0x1c,%esp
f0103554:	5b                   	pop    %ebx
f0103555:	5e                   	pop    %esi
f0103556:	5f                   	pop    %edi
f0103557:	5d                   	pop    %ebp
f0103558:	c3                   	ret    
f0103559:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103560:	85 ff                	test   %edi,%edi
f0103562:	89 fd                	mov    %edi,%ebp
f0103564:	75 0b                	jne    f0103571 <__umoddi3+0x91>
f0103566:	b8 01 00 00 00       	mov    $0x1,%eax
f010356b:	31 d2                	xor    %edx,%edx
f010356d:	f7 f7                	div    %edi
f010356f:	89 c5                	mov    %eax,%ebp
f0103571:	89 f0                	mov    %esi,%eax
f0103573:	31 d2                	xor    %edx,%edx
f0103575:	f7 f5                	div    %ebp
f0103577:	89 c8                	mov    %ecx,%eax
f0103579:	f7 f5                	div    %ebp
f010357b:	89 d0                	mov    %edx,%eax
f010357d:	eb 99                	jmp    f0103518 <__umoddi3+0x38>
f010357f:	90                   	nop
f0103580:	89 c8                	mov    %ecx,%eax
f0103582:	89 f2                	mov    %esi,%edx
f0103584:	83 c4 1c             	add    $0x1c,%esp
f0103587:	5b                   	pop    %ebx
f0103588:	5e                   	pop    %esi
f0103589:	5f                   	pop    %edi
f010358a:	5d                   	pop    %ebp
f010358b:	c3                   	ret    
f010358c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103590:	8b 34 24             	mov    (%esp),%esi
f0103593:	bf 20 00 00 00       	mov    $0x20,%edi
f0103598:	89 e9                	mov    %ebp,%ecx
f010359a:	29 ef                	sub    %ebp,%edi
f010359c:	d3 e0                	shl    %cl,%eax
f010359e:	89 f9                	mov    %edi,%ecx
f01035a0:	89 f2                	mov    %esi,%edx
f01035a2:	d3 ea                	shr    %cl,%edx
f01035a4:	89 e9                	mov    %ebp,%ecx
f01035a6:	09 c2                	or     %eax,%edx
f01035a8:	89 d8                	mov    %ebx,%eax
f01035aa:	89 14 24             	mov    %edx,(%esp)
f01035ad:	89 f2                	mov    %esi,%edx
f01035af:	d3 e2                	shl    %cl,%edx
f01035b1:	89 f9                	mov    %edi,%ecx
f01035b3:	89 54 24 04          	mov    %edx,0x4(%esp)
f01035b7:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01035bb:	d3 e8                	shr    %cl,%eax
f01035bd:	89 e9                	mov    %ebp,%ecx
f01035bf:	89 c6                	mov    %eax,%esi
f01035c1:	d3 e3                	shl    %cl,%ebx
f01035c3:	89 f9                	mov    %edi,%ecx
f01035c5:	89 d0                	mov    %edx,%eax
f01035c7:	d3 e8                	shr    %cl,%eax
f01035c9:	89 e9                	mov    %ebp,%ecx
f01035cb:	09 d8                	or     %ebx,%eax
f01035cd:	89 d3                	mov    %edx,%ebx
f01035cf:	89 f2                	mov    %esi,%edx
f01035d1:	f7 34 24             	divl   (%esp)
f01035d4:	89 d6                	mov    %edx,%esi
f01035d6:	d3 e3                	shl    %cl,%ebx
f01035d8:	f7 64 24 04          	mull   0x4(%esp)
f01035dc:	39 d6                	cmp    %edx,%esi
f01035de:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01035e2:	89 d1                	mov    %edx,%ecx
f01035e4:	89 c3                	mov    %eax,%ebx
f01035e6:	72 08                	jb     f01035f0 <__umoddi3+0x110>
f01035e8:	75 11                	jne    f01035fb <__umoddi3+0x11b>
f01035ea:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01035ee:	73 0b                	jae    f01035fb <__umoddi3+0x11b>
f01035f0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01035f4:	1b 14 24             	sbb    (%esp),%edx
f01035f7:	89 d1                	mov    %edx,%ecx
f01035f9:	89 c3                	mov    %eax,%ebx
f01035fb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01035ff:	29 da                	sub    %ebx,%edx
f0103601:	19 ce                	sbb    %ecx,%esi
f0103603:	89 f9                	mov    %edi,%ecx
f0103605:	89 f0                	mov    %esi,%eax
f0103607:	d3 e0                	shl    %cl,%eax
f0103609:	89 e9                	mov    %ebp,%ecx
f010360b:	d3 ea                	shr    %cl,%edx
f010360d:	89 e9                	mov    %ebp,%ecx
f010360f:	d3 ee                	shr    %cl,%esi
f0103611:	09 d0                	or     %edx,%eax
f0103613:	89 f2                	mov    %esi,%edx
f0103615:	83 c4 1c             	add    $0x1c,%esp
f0103618:	5b                   	pop    %ebx
f0103619:	5e                   	pop    %esi
f010361a:	5f                   	pop    %edi
f010361b:	5d                   	pop    %ebp
f010361c:	c3                   	ret    
f010361d:	8d 76 00             	lea    0x0(%esi),%esi
f0103620:	29 f9                	sub    %edi,%ecx
f0103622:	19 d6                	sbb    %edx,%esi
f0103624:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103628:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010362c:	e9 18 ff ff ff       	jmp    f0103549 <__umoddi3+0x69>
