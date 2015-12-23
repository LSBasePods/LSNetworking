//
//  LSNetworkConfig.h
//  LSNetworkingExample
//
//  Created by Terry Zhang on 15/12/11.
//  Copyright © 2015年 BasePod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LSService.h"

/// 公共网络环境
@interface LSNetworkConfig : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, strong) LSService *commonService;

@end
