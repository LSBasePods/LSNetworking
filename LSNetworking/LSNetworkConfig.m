//
//  LSNetworkConfig.m
//  LSNetworkingExample
//
//  Created by Terry Zhang on 15/12/11.
//  Copyright © 2015年 BasePod. All rights reserved.
//

#import "LSNetworkConfig.h"

NSString * const LSNetworkingAPIIsOnline = @"ls.networking.isOnlineApi";

@implementation LSNetworkConfig

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static LSNetworkConfig *sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[LSNetworkConfig alloc] init];
    });
    return sharedInstance;
}

@end
