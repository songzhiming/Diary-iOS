//
//  ZMCrashTracker.m
//  CheckPerformance
//
//  Created by zhiming9 on 2017/9/30.
//  Copyright © 2017年 zhiming9. All rights reserved.
//

#import "ZMCrashTracker.h"
#include <signal.h>
#include <execinfo.h>

void ZMHandleUncaughtException(NSException *exception);
void ZMHandleSignal(int signal);

@interface ZMCrashTracker()

@end
@implementation ZMCrashTracker

+ (ZMCrashTracker *)shareInstance
{
    static ZMCrashTracker *crashTracker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        crashTracker = [[ZMCrashTracker alloc] init];
    });
    return crashTracker;
}

+ (void)registerUncaughtExceptionHandler
{
    NSSetUncaughtExceptionHandler(&ZMHandleUncaughtException);
    //收到Abort信号，可能自身调用abort()或者收到外部发送过来的信号
    signal(SIGABRT, ZMHandleSignal);
    /* illegal instruction (not reset when caught)
     * 执行了非法指令. 通常是因为可执行文件本身出现错误, 或者试图执行数据段. 堆栈溢出时也有可能产生这个信号。
     */
    signal(SIGILL, ZMHandleSignal);
    // 执行了非法指令. 通常是因为可执行文件本身出现错误, 或者试图执行数据段. 堆栈溢出时也有可能产生这个信号。
    signal(SIGSEGV, ZMHandleSignal);
    
    /* floating point exception
     * 在发生致命的算术运算错误时发出. 不仅包括浮点运算错误, 还包括溢出及除数为0等其它所有的算术的错误
     */
    signal(SIGFPE, ZMHandleSignal);
    
    // 非法地址, 包括内存地址对齐(alignment)出错。比如访问一个四个字长的整数, 但其地址不是4的倍数。
    signal(SIGBUS, ZMHandleSignal);
    signal(SIGPIPE, ZMHandleSignal);
}



#pragma mark private
//处理异常Exception
void ZMHandleUncaughtException(NSException *exception)
{
    //异常调用堆栈
    NSArray *stackArray = [exception callStackSymbols];
    //异常原因
    NSString *reason = [exception reason];
    //异常名称
    NSString *name = [exception name];
    NSString *exceptionInfo = [NSString stringWithFormat:@"Exception reason：%@\nException name：%@\nException stack：%@",name, reason, stackArray];
    NSLog(@"UncaughtException%@", exceptionInfo);
}
//处理系统信号量
void ZMHandleSignal(int signal)
{
    NSLog(@"signal---%d",signal);
    const char* names[NSIG];
    names[SIGABRT] = "SIGABRT";
    names[SIGBUS] = "SIGBUS";
    names[SIGFPE] = "SIGFPE";
    names[SIGILL] = "SIGILL";
    names[SIGPIPE] = "SIGPIPE";
    names[SIGSEGV] = "SIGSEGV";
    NSArray *stackArray = [NSThread callStackSymbols];
    NSLog(@"stackArray--%@",stackArray);
    NSLog(@"Signal Name-%s",names[signal]);
}

@end
