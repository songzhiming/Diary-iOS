//
//  ZMCrashTracker.h
//  CheckPerformance
//
//  Created by zhiming9 on 2017/9/30.
//  Copyright © 2017年 zhiming9. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZMCrashTracker : NSObject

+ (ZMCrashTracker *)shareInstance;

+ (void)registerUncaughtExceptionHandler;

@end
