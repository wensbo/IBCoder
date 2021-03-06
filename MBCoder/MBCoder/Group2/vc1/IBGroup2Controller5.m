//
//  IBGroup2Controller5.m
//  IBCoder1
//
//  Created by Bowen on 2019/8/10.
//  Copyright © 2019 BowenCoder. All rights reserved.
//

#import "IBGroup2Controller5.h"

@interface IBGroup2Controller5 ()

@end

@implementation IBGroup2Controller5

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

/*
 一、图片解压缩
 
 1、图片加载的工作流
 概括来说，从磁盘中加载一张图片，并将它显示到屏幕上，中间的主要工作流如下：
 
 1）使用 +imageWithContentsOfFile: 方法从磁盘中加载一张图片，这个时候的图片并没有解压缩；
 2）将生成的 UIImage 赋值给 UIImageView ；
 3）隐式的 CATransaction 捕获到了 UIImageView 图层树的变化；
 4）在主线程的下一个 run loop 到来时，Core Animation 提交了这个隐式的 transaction ，这个过程可能
    会对图片进行 copy 操作，而受图片是否字节对齐等因素的影响，这个 copy 操作可能会涉及以下部分或全部步骤：
    a、分配内存缓冲区用于管理文件 IO 和解压缩操作；
    b、将文件数据从磁盘读到内存中；
    c、将压缩的图片数据解码成未压缩的位图形式，这是一个非常耗时的 CPU 操作；
    d、最后 Core Animation 使用未压缩的位图数据渲染 UIImageView 的图层。
 
 2、为什么需要解压缩
 位图就是一个像素数组，数组中的每个像素就代表着图片中的一个点，JPEG 和 PNG 图片，都是一种压缩的位图图形格式。
 
 假如一张图片像素为：30*30
 解压缩后的图片大小 = 图片的像素宽30 * 图片的像素高30 * 每个像素所占的字节数 4
 
 三、操作系统的内存机制
 
 1、冯·诺依曼结构：输入设备，存储器，运算器，控制器，输出设备。
 输入设备：输入数据和程序
 输出设备：输出处理结果
 存储器： 存放程序的指令和数据
 运算器： 数据加工处理
 控制器： 控制程序的执行
 
 2、冯·诺依曼瓶颈
 CPU 与存储器之间的读写速率远远小于 CPU 的工作效率，造成CPU性能的浪费
 解决：采用多级存储，来平衡存储器的读写速率、容量、价格。因为存在局部性原理，
 被使用过的存储器内容在未来可能会被多次使用，以及它附近的内容也大概率被使用。
 
 3、存储器的层次结构
 易失性存储器速度更快，断电之后数据会丢失（随机访问存储器）；
 非易失性存储器容量更大、价格更低，断电也不会丢失数据（只读存储器 ）。
 随机访问存储器 RAM 也分为两类，其中 SRAM 速度更快，所以用作高速缓存，DRAM 用作主存（也是常说的内存）。
 只读存储器 ROM 实际上只有最开始的时候是只读的，后来随着发展也能够进行读写了，只是沿用了之前的名字。
 
 4、CPU 寻址方式
 1）最简单最直接的方式，就是 CPU 直接通过物理地址去访问对应的内存，这样也被叫做物理寻址（Physical Address）。
 2）物理寻址后来也扩展支持了分段机制，通过在 CPU 中增加段寄存器，将物理地址变成了 "段地址"："段内偏移量" 的形式，
    增加了物理寻址的寻址范围。
 3）物理寻址存在问题：地址空间缺乏保护，因为直接暴露的是物理地址，所以进程可以访问到任何物理地址。
    解决：现代处理器使用的是虚拟寻址的方式，虚拟寻址需要硬件与操作系统之间互相合作。
         CPU中含有一个被称为内存管理单元（Memory Management Unit, MMU）的硬件，
         它的功能是将虚拟地址转换为物理地址。MMU需要借助存放在内存中的页表来动态翻译虚拟地址，该页表由操作系统管理。
 
 四、iOS典型APP内存类型
 
 当内存不足的时候，系统会按照一定策略来腾出更多空间供使用，
 比较常见的做法是将一部分低优先级的数据挪到磁盘上，这个操作称为 Page Out。
 之后当再次访问到这块数据的时候，系统会负责将它重新搬回内存空间中，这个操作称为 Page In。
 
 对于移动设备而言，频繁对磁盘进行IO操作会降低存储设备的寿命。
 从 iOS7 开始，系统开始采用压缩内存的办法来释放内存空间，被压缩的内存称为 Compressed Memory。
 所以iOS没有内存交换机制
 
 Dirty Memory，指的是不能被系统回收的内存占用。
 已被加载到内存中的文件，App 所用到的 frameworks，应用的二进制可执行文件
 Clean Memory，指的是能够被系统清理出内存且在需要时能重新加载的数据。
 所有堆区的对象、图像解码缓冲区
 Compressed Memory，当内存吃紧的时候，系统会将不使用的内存进行压缩，直到下一次访问的时候进行解压。
 
 五、虚拟内存
 
 MMU：分页内存管理单元
 PTE：页表项
 DRAM：动态随机存取存储器
 TLB：MMU中的cache，用来缓存最近用过的PTE
 Frame：物理内存的最小单位被称为帧
 Page：虚拟内存的最小单位被称为页
 
 1、意义
 1）作为缓存工具，提高内存利用率：
    使用 DRAM 当做部分的虚拟地址空间的缓存（虚拟内存就是存储在磁盘上的 N 个连续字节的数组，数组的部分内容会缓存在 DRAM 中）。
    扩大了内存空间，当发生缺页异常时，将会把内存和磁盘中的数据进行置换。
 2）作为内存管理工具，简化内存管理：
    每个进程都有统一的线性地址空间（但实际上在物理内存中可能是间隔、支离破碎的），在内存分配中没有太多限制，每个虚拟页都可以被映射到任何的物理页上。
    这样也带来一个好处，如果两个进程间有共享的数据，那么直接指向同一个物理页即可
 3）作为内存保护工具，隔离地址空间：
    进程之间不会相互影响；用户程序不能访问内核信息和代码。CPU每次进行地址翻译的时候都需要经过PTE，页表中的每个PTE的高位部分是表示权限的位，
    MMU 可以通过检查这些位来进行权限控制（读、写、执行）。
  
 2、内存分页
 基于前文的思路，虚拟内存和物理内存建立了映射的关系。
 为了方便映射和管理，虚拟内存和物理内存都被分割成相同大小的单位，
 物理内存的最小单位被称为帧（Frame），而虚拟内存的最小单位被称为页（Page）。
 
 内存分页最大的意义在于，支持了物理内存的离散使用。由于存在映射过程，
 所以虚拟内存对应的物理内存可以任意存放，这样就方便了操作系统对物理内存的管理，
 也能够可以最大化利用物理内存。同时，也可以采用一些页面调度（Paging）算法，
 利用翻译过程中也存在的局部性原理，将大概率被使用的帧地址加入到 TLB 或者页表之中，提高翻译的效率。

 3、页表
 1）定义：页表就是一个存放在物理内存中的数据结构，它记录了虚拟页与物理页的映射关系。
 2）分类：操作系统通过将虚拟内存分割为大小固定的块来作为硬盘和内存之间的传输单位，
 这个块被称为虚拟页（Virtual Page, VP），每个虚拟页的大小为P=2^p字节。
 物理内存也会按照这种方法分割为物理页（Physical Page, PP），大小也为p字节。
 
 多级页表：不仅节省每个进程的页表占用的内存，还能根据进程使用内存不同动态的调整页表占用内存的大小。
 
 页表是一个元素为页表条目（Page Table Entry, PTE）的集合，每个虚拟页在页表中一个固定偏移量的位置上都有一个PTE。
 
 4、页命中，缺页
 虚拟页没有被缓存在物理内存中（缓存未命中）被称为缺页
 
 
 六、内存占用（Memory Footprint）
 memory footprint = dirty size + compressed size
 
 减少内存指减少 iOS App 的虚拟内存(Virtual Memory) 占用。
 
 iOS 以及 macOS 都采用了虚拟内存技术来突破物理内存(RAM) 的大小限制，
 每个进程都拥有一段由多个大小相同的 page 所构成的逻辑地址空间。
 处理器和内存管理单元 MMU(Memory Management Unit) 维护着由逻辑地址空间到物理地址的 page 映射表，
 当程序访问逻辑内存地址时由 MMU 根据映射表将逻辑地址转换为真实的物理地址。
 
 
 */

@end
