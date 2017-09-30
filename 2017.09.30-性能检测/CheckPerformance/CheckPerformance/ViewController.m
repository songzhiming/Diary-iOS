//
//  ViewController.m
//  CheckPerformance
//
//  Created by zhiming9 on 2017/9/30.
//  Copyright © 2017年 zhiming9. All rights reserved.
//

#import "ViewController.h"

#define SuppressPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)



@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) NSArray *arr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.arr =@[@{@"name":@"UncaughtException",@"function":@"UncaughtException"},
                @{@"name":@"SIGABRT",@"function":@"testSIGABRT"},
                @{@"name":@"SIGILL",@"function":@"testSIGILL"},
                @{@"name":@"SIGSEGV",@"function":@"testSIGSEGV"},
                @{@"name":@"SIGFPE",@"function":@"testSIGFPE"},
                @{@"name":@"SIGBUS",@"function":@"testSIGBUS"},
                @{@"name":@"SIGPIPE",@"function":@"testSIGPIPE"}];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UITableViewDelegate  UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.arr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = self.arr[indexPath.row][@"name"];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *function = self.arr[indexPath.row][@"function"];
    SEL selector = NSSelectorFromString(function);
    SuppressPerformSelectorLeakWarning(
                                       [self performSelector:selector];
    );
}

- (void)UncaughtException
{
    NSException *e = [NSException exceptionWithName:@"aaa" reason:@"bbb" userInfo:nil];
    @throw e;
//    NSMutableArray *arr = [NSMutableArray new];
//    [arr removeObjectAtIndex:1];
}
- (void)testSIGABRT
{
    abort();
}

- (void)testSIGILL
{
    typedef void(*FUNC)(void);
    const static unsigned char insn[4] = { 0xff, 0xff, 0xff, 0xff };
    void (*func)(void) = (FUNC)insn;
    func();
}
- (void)testSIGSEGV
{
    //MRC
//    NSString *str = [[NSString alloc] initWithUTF8String:"SIGSEGV STRING"];
//    [str release];
//    NSLog(@"String %@", str);
}
- (void)testSIGFPE
{
    int zero = 0;  // LLVM is smart and actually catches divide by zero if it is constant
    int i = 10/zero;
    NSLog(@"Int: %i", i);
}
- (void)testSIGBUS
{
    void (*func)(void) = 0;
    func();
}
- (void)testSIGPIPE
{
    FILE *f = popen("ls", "r");
    const char *buf[128];
    pwrite(fileno(f), buf, 128, 0);
}




@end
