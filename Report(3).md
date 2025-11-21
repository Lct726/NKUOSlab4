# 练习1

根据实验要求，需要实现 [alloc_proc] 函数，用于分配并初始化一个进程控制块。进程控制块（PCB）是系统管理进程的重要数据结构，其中包含了进程运行所需的各种信息。

在本次实验中，我按照注释中的提示，对 [proc_struct]结构体中的各个字段进行了初始化：

1. `state`：设置为 PROC_UNINIT，表示进程处于未初始化状态
2. `pid`：设置为 -1，表示进程ID尚未分配
3. `runs`：设置为 0，表示进程尚未运行
4. `kstack`：设置为 0，表示内核栈地址尚未分配
5. `need_resched`：设置为 0，表示当前不需要重新调度
6. `parent`：设置为 NULL，表示父进程为空
7. `mm`：设置为 NULL，表示内存管理结构为空
8. `context`：使用 memset 清零整个 context 结构体
9. `tf`：设置为 NULL，表示中断帧指针为空
10. `pgdir`：设置为 0，表示页目录表基地址尚未设置
11. `flags`：设置为 0，清空所有标志位
12. `name`：使用 memset 清零进程名称数组

通过以上初始化操作，为后续进程的进一步配置和运行做好了准备。

## 问题回答

### 请说明proc_struct中struct context context和struct trapframe *tf成员变量含义和在本实验中的作用是啥？

#### struct context context 的含义和作用

[context] 结构体保存的是进程的上下文信息，主要包括一些被调用者保存的寄存器（如ra、sp以及s0-s11等）。在进程切换时，需要保存当前进程的执行状态，以便之后能够正确地恢复执行。

```c
struct context {
    uintptr_t ra;
    uintptr_t sp;
    uintptr_t s0;
    uintptr_t s1;
    uintptr_t s2;
    uintptr_t s3;
    uintptr_t s4;
    uintptr_t s5;
    uintptr_t s6;
    uintptr_t s7;
    uintptr_t s8;
    uintptr_t s9;
    uintptr_t s10;
    uintptr_t s11;
};
```

在本实验中，[context]的作用主要体现在 [proc_run](lab4/kern/process/proc.c#L180-L210) 函数中，当从一个进程切换到另一个进程运行时，会调用 [switch_to](lab4/kern/process/proc.c#L476-L476) 函数来保存当前进程的上下文，并恢复目标进程的上下文。

[switch_to](lab4/kern/process/proc.c#L476-L476) 函数的实现位于 switch.S 文件中：

```assembly
.text
# void switch_to(struct context *from, struct context *to)
.globl switch_to
switch_to:
    # Save context registers
    sd ra, 0(a0)
    sd sp, 8(a0)
    sd s0, 16(a0)
    sd s1, 24(a0)
    sd s2, 32(a0)
    sd s3, 40(a0)
    sd s4, 48(a0)
    sd s5, 56(a0)
    sd s6, 64(a0)
    sd s7, 72(a0)
    sd s8, 80(a0)
    sd s9, 88(a0)
    sd s10, 96(a0)
    sd s11, 104(a0)

    # Restore context registers
    ld ra, 0(a1)
    ld sp, 8(a1)
    ld s0, 16(a1)
    ld s1, 24(a1)
    ld s2, 32(a1)
    ld s3, 40(a1)
    ld s4, 48(a1)
    ld s5, 56(a1)
    ld s6, 64(a1)
    ld s7, 72(a1)
    ld s8, 80(a1)
    ld s9, 88(a1)
    ld s10, 96(a1)
    ld s11, 104(a1)
    
    ret
```

这段汇编代码的工作原理是：
1. 首先将当前进程（from）的寄存器状态保存到[from](lab4/kern/process/proc.c#L476-L476)指向的[context](lab4/kern/process/proc.h#L20-L34)结构体中
2. 然后从[to](lab4/kern/process/proc.c#L476-L476)指向的[context](lab4/kern/process/proc.h#L20-L34)结构体中恢复目标进程的寄存器状态
3. 最后通过ret指令跳转到目标进程的代码继续执行

在 [proc_run](lab4/kern/process/proc.c#L180-L210) 函数中，切换进程的具体代码如下：

```c
void proc_run(struct proc_struct *proc) {
    if (proc != current) {
        bool intr_flag;
        struct proc_struct *prev = current, *next = proc;
        local_intr_save(intr_flag);
        {
            current = proc;
            lcr3(next->cr3);  // 切换页表
            switch_to(&(prev->context), &(next->context));  // 切换上下文
        }
        local_intr_restore(intr_flag);
    }
}
```

这里我们可以看到，在切换进程时，除了调用[switch_to](lab4/kern/process/proc.c#L476-L476)进行上下文切换外，还需要切换页表（通过lcr3函数），这样才能确保目标进程访问正确的内存空间。

#### struct trapframe *tf 的含义和作用

[tf](lab4/kern/process/proc.h#L51-L51) 是一个指向 [trapframe](lab4/kern/trap/trap.h#L37-L45) 结构体的指针，[trapframe](lab4/kern/trap/trap.h#L37-L45) 保存了进程发生中断或异常时的处理器状态，包括所有通用寄存器以及一些特殊寄存器（如status、epc等）。

```c
struct trapframe {
    struct pushregs gpr;  // 通用寄存器
    uintptr_t status;     // 处理器状态寄存器
    uintptr_t epc;        // 异常程序计数器
    uintptr_t badvaddr;   // 出错的虚拟地址
    uintptr_t cause;      // 异常原因
};
```

其中 [pushregs](lab4/kern/trap/trap.h#L4-L35) 结构体定义了所有通用寄存器：

```c
struct pushregs {
    uintptr_t zero;   // Hard-wired zero
    uintptr_t ra;     // Return address
    uintptr_t sp;     // Stack pointer
    uintptr_t gp;     // Global pointer
    uintptr_t tp;     // Thread pointer
    uintptr_t t0;     // Temporary
    uintptr_t t1;     // Temporary
    uintptr_t t2;     // Temporary
    uintptr_t s0;     // Saved register/frame pointer
    uintptr_t s1;     // Saved register
    uintptr_t a0;     // Function argument/return value
    uintptr_t a1;     // Function argument/return value
    // ... 其他寄存器
};
```

在本实验中，[tf](lab4/kern/process/proc.h#L51-L51) 主要用于在进程启动和系统调用等场景下，通过修改中断帧中的寄存器值来控制进程的行为。例如，在创建内核线程时，会通过设置 [tf](lab4/kern/process/proc.h#L51-L51) 中的寄存器值来指定线程入口函数和参数。

在 [kernel_thread](lab4/kern/process/proc.c#L334-L354) 函数中有如下代码片段：

```c
// 设置中断帧中的寄存器值
tf->gpr.s0 = (uintptr_t)fn;    // 将函数指针放入s0寄存器
tf->gpr.s1 = (uintptr_t)arg;   // 将参数放入s1寄存器
tf->status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE);  // 设置状态寄存器
```

在 [forkrets](lab4/kern/process/proc.c#L477-L479) 函数中，会使用这个 [trapframe](lab4/kern/trap/trap.h#L37-L45) 来恢复进程执行：

```assembly
.text
.globl forkrets
forkrets:
    # 设置栈指针
    ld sp, TF_SP(a0)        # a0 指向 trapframe
    
    # 加载通用寄存器
    ld ra, TF_EPC(a0)       # 从 trapframe 中加载返回地址到 ra
    
    # 跳转到内核线程函数
    ret
```

这使得新建的进程可以从指定的函数开始执行，并且能够获取到传递给它的参数。

# 练习2

## 一、do_fork 函数实现说明

do_fork 的主要功能是创建一个新的子进程，其整体流程包括：分配并初始化进程控制块、创建内核栈、复制或共享父进程的内存空间、设置子进程的初始执行上下文、将子进程加入系统的进程管理结构，并最终将其设置为可调度状态。整个函数严格按照资源分配顺序执行，并在任何步骤失败时按逆序释放已分配资源，确保系统资源不会泄漏。
在函数开头首先检查当前系统的进程数量是否已达到上限，如果超过限制，则直接返回错误。接着将默认的错误码设置为"内存不足"，为后续任何资源分配失败做准备。

## 二、代码补充：

1.alloc_proc：分配并初始化子进程的 PCB（proc_struct）
proc = alloc_proc();
if (!proc) {
    goto fork_out;
}
解释：
这里调用 alloc_proc() 创建一个全新的进程控制块（PCB）。它会完成对 proc_struct 的基本字段初始化（如状态、内核栈指针、内存管理结构指针等）。如果分配失败，则直接返回错误码。

2.setup_kstack：为子进程分配独立的内核栈
if (setup_kstack(proc) < 0) {
    ret = -E_NO_MEM;
    goto bad_fork_cleanup_proc;
}
解释：
每个进程在内核态运行时需要自己的内核栈（例如系统调用、异常处理中都会使用）。这里为子进程分配内核栈，并记录在 proc->kstack 字段中。若分配失败，需要回收上一步创建的 proc。

3.copy_mm：复制或共享父进程的内存空间
if (copy_mm(clone_flags, proc) < 0) {
    ret = -E_NO_MEM;
    goto bad_fork_cleanup_kstack;
}
解释：
根据 clone_flags 决定是复制内存空间（普通 fork）还是共享内存空间（如 Linux clone 的 CLONE_VM）。典型情况下使用 COW（写时复制），保证效率与一致性。如果内存复制失败，则回收内核栈与 proc。

4.copy_thread：设置 trapframe 和子进程的执行上下文
if (copy_thread(proc, stack, tf) < 0) {
    ret = -E_INVAL;
    goto bad_fork_cleanup_kstack;
}
解释：
在内存空间初始化后，copy_thread 被用于构建子进程的初始执行现场，包括在内核栈上设置 trapframe、初始化寄存器状态，并决定子进程从何处开始执行。通过此步骤，子进程未来被调度时才能正确从内核返回到用户态。若此步骤失败，同样需要回滚所有已经分配的资源。

5.将子进程加入进程链表与哈希表
proc->pid = get_pid();
proc->parent = current;

list_add(&proc_list, &proc->list_link);
hash_proc(proc);
解释：
当子进程的基本执行环境准备完成后，通过 get_pid 为其分配唯一的进程号，并设置父子进程关系（即将父进程 current 记录在新进程的 parent 字段中）。随后，子进程被加入全局进程链表和哈希表，使其能够被系统调度器与其他模块正确管理。

6.增加进程计数并将子进程设置为 RUNNABLE
nr_process++;
wakeup_proc(proc);
解释：
nr_process++ 更新系统已创建的进程总数。
wakeup_proc(proc) 将子进程状态设为 PROC_RUNNABLE，使调度器可以在之后的调度周期中选择它运行，相当于真正激活了子进程。

7.返回子进程的 pid（do_fork 的最终返回值）
ret = proc->pid;
解释：
fork 的语义要求父进程返回子进程 pid，而子进程的返回值在 copy_thread 内部已设为 0。此处将子进程 pid 作为 do_fork 的返回值返回给父进程。

通过上述 1–7 步骤，do_fork 完成了创建子进程的全部核心流程：
为子进程创建 PCB → 构建内核栈 → 复制内存空间 → 设置执行上下文 → 挂入全局管理结构 → 设为可运行 → 返回 pid。
这使得子进程能够在下一个调度周期中被调度执行

## 问题回答

uCore 的 do_fork() 通过 get_pid() 为每个新进程分配一个在当前系统中唯一的 pid，并通过扫描全部进程保证无重复。pid 在进程退出后会被回收、循环使用，因此不保证永久唯一，但保证当前所有存活进程的 pid 都是唯一的。

# 练习3
## 问题回答
两个内核线程，一个是第0个内核线程idleproc和第一个真正的内核线程initproc

# challenge1
local_intr_save / restore 通过读写 CSR 寄存器的 SIE 位，实现了"记录旧状态 → 关闭中断 → 恢复旧状态"的中断保护机制，用于保证内核关键区域的原子性。

在sync.h中，有对于函数local_intr_save和函数local_intr_restore的定义：
#define local_intr_save(x) \
    do {                   \
        x = __intr_save(); \
    } while (0)
#define local_intr_restore(x) __intr_restore(x);
由宏定义转到上方的代码，在 __intr_save中，如果读到中断是开启的，就执行函数intr_disable()用来关闭中断，并返回之前"中断开启"，如果不开启，就返回"中断不开启"；在__intr_restore中，如果flag，也就是函数__intr_save的返回值为1，函数intr_enable()打开中断,为0的话不用管。
static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
        intr_disable();
        return 1;
    }
    return 0;
}
static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
    }
}
下面这两个函数的具体实现，分别设置和清除了sstatus的SIE位。
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
所以总结下来就是local_intr_save用来保存上下文，local_intr_restore用来恢复原先的上下文状态，如果原先中断是打开的，恢复到开的状态，如果原先中断是关闭的，恢复到关状态。


# challenge2
深入理解不同分页模式的工作原理（思考题）
get_pte()函数（位于kern/mm/pmm.c）用于在页表中查找或创建页表项，从而实现对指定线性地址对应的物理页的访问和映射操作。这在操作系统中的分页机制下，是实现虚拟内存与物理内存之间映射关系非常重要的内容。

## （1）get_pte()函数中有两段形式类似的代码， 结合sv32，sv39，sv48的异同，解释这两段代码为什么如此相像。

在RISC-V架构中，SV32、SV39和SV48是三种不同的虚拟内存分页模式，它们的主要区别在于页表级数和地址位宽：

1. SV32：采用二级页表，32位虚拟地址
2. SV39：采用三级页表，39位虚拟地址  
3. SV48：采用四级页表，48位虚拟地址

当前代码中使用的SV39模式具有三级页表结构，分别是：
- 第一级：页全局目录(Page Global Directory, PGD)
- 第二级：页中间目录(Page Middle Directory, PMD)
- 第三级：页表(Page Table, PT)

在[get_pte](lab4/kern/mm/pmm.c#L205-L230)函数中，有两段相似的代码分别处理第一级和第二级页表的查找与创建：

```c
// 处理第一级页表(PGD)
pde_t *pdep1 = &pgdir[PDX1(la)];
if (!(*pdep1 & PTE_V))
{
    struct Page *page;
    if (!create || (page = alloc_page()) == NULL)
    {
        return NULL;
    }
    set_page_ref(page, 1);
    uintptr_t pa = page2pa(page);
    memset(KADDR(pa), 0, PGSIZE);
    *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
}

// 处理第二级页表(PMD)
pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
if (!(*pdep0 & PTE_V))
{
    struct Page *page;
    if (!create || (page = alloc_page()) == NULL)
    {
        return NULL;
    }
    set_page_ref(page, 1);
    uintptr_t pa = page2pa(page);
    memset(KADDR(pa), 0, PGSIZE);
    *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
}
```

这两段代码的具体操作步骤如下：

1. **获取页表项指针**：
   - 第一段代码通过[PDX1](lab4/kern/mm/mmu.h#L34-L34)宏提取虚拟地址la的最高9位作为索引，从页目录基地址pgdir中取出对应的页目录项地址
   - 第二段代码通过[PDE_ADDR](lab4/kern/mm/mmu.h#L58-L58)宏从第一级页目录项中提取下一级页表的物理地址，使用[KADDR](lab4/kern/mm/mmu.h#L49-L49)将其转换为内核虚拟地址，再通过[PDX0](lab4/kern/mm/mmu.h#L35-L35)宏提取虚拟地址la的中间9位作为索引，得到第二级页表项的地址

2. **检查有效性**：
   - 通过检查页目录项的PTE_V位确定该项是否有效，如果无效则需要创建新的页表

3. **分配新页表**：
   - 如果页目录项无效且允许创建(create为true)，则调用[alloc_page](lab4/kern/mm/pmm.h#L96-L96)分配一个新的物理页面用于作为下一级页表

4. **初始化新页表**：
   - 设置新分配页面的引用计数为1，表示该页面已被引用一次
   - 通过[page2pa](lab4/kern/mm/pmm.h#L90-L90)函数获取新分配页面的物理地址
   - 使用[KADDR](lab4/kern/mm/mmu.h#L49-L49)宏将物理地址转换为内核虚拟地址，然后将新页表的所有内容清零

5. **创建页表项**：
   - 使用[pte_create](lab4/kern/mm/pmm.h#L137-L137)函数创建一个新的页目录项，指向新分配的页表页面，并设置有效位(PTE_V)和用户访问位(PTE_U)

这两段代码之所以如此相似，是因为它们执行的是相同的操作——在多级页表结构中查找下一级页表是否存在，如果不存在且允许创建则分配新的页表。这种相似性反映了多级页表的递归特性：

1. 每一级页表的结构都是相同的，都是包含512个页表项的页面
2. 查找下一级页表的过程是一致的：通过特定的索引从当前页表中获取下一级页表的地址
3. 如果下一级页表不存在，则需要分配一个新的页面作为页表，并初始化其内容

对于SV32（二级页表）只需要一段这样的代码，而对于SV48（四级页表）则需要三段类似的代码。这种设计体现了RISC-V分页机制的一致性和可扩展性。

## （2）目前get_pte()函数将页表项的查找和页表项的分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？

我认为当前get_pte()函数将查找和分配合并在一起的设计是一种很好的设计选择，没有必要拆分成两个独立的函数。

### 这种设计的优势：

1. **功能完整性**：查找页表项和在需要时分配页表本质上是一个完整操作的不同阶段。当我们要获取一个页表项时，我们真正想要的是无论它是否已经存在都能获得它。如果不存在，自然就需要创建它。这种一体化的设计体现了操作系统的实用主义精神。

2. **原子性保障**：将查找和分配合并为一个函数可以更好地保证操作的原子性。在多线程或多进程环境中，如果将查找和分配分开，可能会出现竞态条件。例如，线程A检查发现页表不存在，正准备分配时，线程B也可能检查到同样结果并也开始分配，最终可能导致重复分配或不一致的状态。

3. **接口简洁性**：用户只需要调用一个函数就能完成完整操作，而不需要关心内部实现细节。通过布尔型参数create，用户可以灵活控制是否需要创建缺失的页表，这种设计既满足了不同需求又保持了接口的简洁性。

4. **性能优化**：合并设计减少了函数调用次数和重复的页表遍历操作，有助于提高性能。如果拆分为两个函数，很可能需要两次遍历页表结构才能完成同样的工作。

5. **代码复用**：在遍历页表的过程中，无论是查找还是分配，都需要执行大部分相同的操作。合并设计避免了代码重复，也降低了维护成本。

### 实际应用场景验证：

观察[page_insert](lab4/kern/mm/pmm.c#L311-L332)函数的实现可以看到：
```c
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
    pte_t *ptep = get_pte(pgdir, la, 1);  // 获取页表项，必要时创建
    if (ptep == NULL) {
        return -E_NO_MEM;
    }
    // ...后续操作
}
```

这里明确需要获取一个页表项用于映射，如果不存在就要创建它。使用合并后的[get_pte](lab4/kern/mm/pmm.c#L205-L230)函数正好满足这一需求。

再看[get_page](lab4/kern/mm/pmm.c#L258-L269)函数：
```c
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
    pte_t *ptep = get_pte(pgdir, la, 0);  // 只查找，不创建
    // ...
}
```

这里只是想查询页表项是否存在，通过传入create=0参数，可以避免不必要的页表分配。

### 设计考量：

操作系统内核的设计往往优先考虑效率和实用性，而不是严格的面向对象设计原则。在这种背景下，将紧密相关的功能组合在一个函数中是合理的选择。通过参数控制行为的方式提供了足够的灵活性，同时保持了接口的简洁性。

### 结论：

综合考虑功能性、性能、安全性和易用性等多个方面，当前的设计是非常优秀的。它既满足了不同使用场景的需求，又保持了良好的性能和安全性，是一种值得推荐的设计模式。因此我认为这种写法很好，没有必要把两个功能拆开。