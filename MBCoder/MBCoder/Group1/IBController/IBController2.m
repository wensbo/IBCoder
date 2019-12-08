//
//  IBController2.m
//  IBCoder1
//
//  Created by Bowen on 2018/4/24.
//  Copyright © 2018年 BowenCoder. All rights reserved.
//

#import "IBController2.h"

@implementation Personal

- (void)setName:(NSString *)name {
    _name = name;
    if ([self.delegate respondsToSelector:@selector(personNameChange)]) {
        [self.delegate personNameChange];
    }
}

- (void)dealloc {
    NSLog(@"person %@ dealloc", self.name);
}

@end



@interface IBController2 ()<PersonDelegate>

@property (nonatomic, strong) Personal *person;
@property (nonatomic, copy) NSString *name;

@end

@implementation IBController2

- (Personal *)person {
    if (!_person) {
        _person = [[Personal alloc] init];
    }
    return _person;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [self test1];
    
//    [self test2];
//    NSLog(@"%@",self.person.delegate);
//    [self test3];
//    [self test3_1];
    [self test3_2];
}

/**
 Tagged Pointer
 1、从64bit开始，iOS引入了Tagged Pointer技术，用于优化NSNumber、NSDate、NSString等小对象的存储
 2、在没有使用Tagged Pointer之前， NSNumber等对象需要动态分配内存、维护引用计数等，NSNumber指针存储的是堆中NSNumber对象的地址值
 3、使用Tagged Pointer之后，NSNumber指针里面存储的数据变成了：Tag + Data，也就是将数据直接存储在了指针中
 4、当指针不够存储数据时，才会使用动态分配内存的方式来存储数据
 5、objc_msgSend能识别Tagged Pointer，比如NSNumber的intValue方法，直接从指针提取数据，节省了以前的调用开销

 6、如何判断一个指针是否为Tagged Pointer？
 1）iOS平台，最高有效位是1（第64bit），#define  _OBJC_TAG_MASK (1UL<<63)
 2）Mac平台，最低有效位是1，                 #define  _OBJC_TAG_MASK (1UL)
 方法：
 BOOL isTaggedPointer(id pointer)
 {
    return (long)(__bridge void *)pointer & _OBJC_TAG_MASK == _OBJC_TAG_MASK;
 }

- (void)setName:(NSString *)name
{
    if (_name != name) {
        [_name release];
        _name = [name retain];
    }
}
 */

- (void)test4
{
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    
    /**
     会崩溃
     1、是对象
     2、异步执行，但不是原子操作
     */
//    for (int i = 0; i < 1000; i++) {
//        dispatch_async(queue, ^{
//            // 加锁
//            self.name = [NSString stringWithFormat:@"abcdefghijk"];
//            // 解锁
//        });
//    }
    
    /**
     不会崩溃
     1、Tagged Pointer，不是对象，指针赋值
     */
    for (int i = 0; i < 1000; i++) {
        dispatch_async(queue, ^{
            self.name = [NSString stringWithFormat:@"abc"];
        });
    }
}

// MRC 文件置为-fno-objc-arc
- (void)test3_2
{    
    @autoreleasepool {
        Personal *p = [[[Personal alloc] init] autorelease];
        p.name = @"猫";
    }
    NSLog(@"@autoreleasepool之后");
    {
        // 这个Personal什么时候调用release，是由RunLoop来控制的
        // 它可能是在某次RunLoop循环中，RunLoop休眠之前调用了release
        Personal *p = [[[Personal alloc] init] autorelease];
        p.name = @"狗";
    }
    NSLog(@"花括号之后");
}

/**
 ARC，编译器会在花括号结束之前主动调用release
 */
- (void)test3_1 {
    
    @autoreleasepool {
        Personal *p = [[Personal alloc] init];
        p.name = @"猫";
    }
    NSLog(@"@autoreleasepool之后");
    {
        Personal *p = [[Personal alloc] init];
        p.name = @"狗";
    }
    NSLog(@"花括号之后");
}

- (void)test3 {
    __weak id obj;
    __strong id objc;
    @autoreleasepool {
        obj = [[NSObject alloc] init];
        objc = [[NSObject alloc] init];
    }
    NSLog(@"%@--%@", obj, objc);
}

/**
 1.assign指针赋值，不对引用计数操作，使用之后如果没有置为nil，可能就会产生野指针
       （delegate指向对象销毁了，仍然存放之前对象地址）（ARC之前用assign）
 2.unsafe_unretained：不会对对象进行retain，当对象销毁时，会依然指向之前的内存空间（野指针）
 3.weak不会对对象进行retain，当对象销毁时，会自动指向nil
 
 */
- (void)test2 {
    IBController2 *ib = [[IBController2 alloc] init];
    self.person.delegate = ib;
    self.person.name = @"bowen";
    NSLog(@"%@",self.person.delegate);
}
- (void)personNameChange {
    NSLog(@"personNameChange");

}

/**
 1.@autoreleasepool是自动释放池，让我们更自由的管理内存
 2.当我们手动创建了一个@autoreleasepool，里面创建了很多临时变量，当@autoreleasepool结束时，里面的内存就会回收
 3.最重要的使用场景，应该是有大量中间临时变量产生时，避免内存使用峰值过高，及时释放内存的场景。
 4.临时生成大量对象,一定要将自动释放池放在for循环里面，要释放在外面，就会因为大量对象得不到及时释放，而造成内存紧张，最后程序意外退出
 5.ARC时代，系统自动管理自己的autoreleasepool，runloop就是iOS中的消息循环机制，当一个runloop结束时系统才会一次性清理掉被
   autorelease处理过的对象
 */

extern void _objc_autoreleasePoolPrint(void);

- (void)test1 {
    NSMutableArray *arr = @[].mutableCopy;
    for (int i = 0; i<10e6; i++) {
        @autoreleasepool {
            NSString *str = [NSString stringWithFormat:@"%d", i];
            [arr addObject:str];
            _objc_autoreleasePoolPrint();
        }
    }
    NSLog(@"123");
    NSLog(@"123");
}

@end

/**
 
 自动释放池的主要底层数据结构是：__AtAutoreleasePool、AutoreleasePoolPage
 
 一、__AtAutoreleasePool的结构
 
 struct __AtAutoreleasePool {
 
 void * atautoreleasepoolobj;

 __AtAutoreleasePool() { // 构造函数，在创建结构体的时候调用
    atautoreleasepoolobj = objc_autoreleasePoolPush();
 }
 
 ~__AtAutoreleasePool() { // 析构函数，在结构体销毁的时候调用
    objc_autoreleasePoolPop(atautoreleasepoolobj);
 }
 
 };

 二、AutoreleasePoolPage的结构
 
 class AutoreleasePoolPage
 {
    magic_t const magic;
    id *next;
    pthread_t const thread;
    AutoreleasePoolPage * const parent;
    AutoreleasePoolPage *child;
    uint32_t const depth;
    uint32_t hiwat;
 }
 
 0、调用了autorelease的对象最终都是通过AutoreleasePoolPage对象来管理的
 1、每个AutoreleasePoolPage对象占用4096字节内存，除了用来存放它内部的成员变量，剩下的空间用来存放autorelease对象的地址
 2、所有的AutoreleasePoolPage对象通过双向链表的形式连接在一起
 3、调用push方法会将一个POOL_BOUNDARY入栈，并且返回其存放的内存地址
 4、调用pop方法时传入一个POOL_BOUNDARY的内存地址，会从最后一个入栈的对象开始发送release消息，直到遇到这个POOL_BOUNDARY
 5、id *next指向了下一个能存放autorelease对象地址的区域
 
 三、Runloop和AutoreleasePool
 iOS在主线程的Runloop中注册了2个Observer
 第1个Observer监听了kCFRunLoopEntry事件，会调用objc_autoreleasePoolPush()
 第2个Observer
 监听了kCFRunLoopBeforeWaiting事件，会调用objc_autoreleasePoolPop()、objc_autoreleasePoolPush()
 监听了kCFRunLoopBeforeExit事件，会调用objc_autoreleasePoolPop()


*/
