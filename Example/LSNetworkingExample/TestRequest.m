//
//  TestRequest.m
//  LSNetworkingExample
//
//  Created by Terry Zhang on 15/12/22.
//  Copyright © 2015年 BasePod. All rights reserved.
//

#import "TestRequest.h"

@implementation TestRequest


- (NSString *)methodName
{
    return @"good/info/";
}

- (LSRequestHTTPMethodType)httpMethod
{
    return LSRequestHTTPMethodGET;
}

- (NSDictionary *)requestParams
{
    return @{
                @"gid":@"5"
             };
}

@end
