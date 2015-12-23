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
    return @"search";
}

- (LSRequestHTTPMethodType)httpMethod
{
    return LSRequestHTTPMethodGET;
}

- (NSDictionary *)requestParams
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    
    if (self.keyword.length) {
        [params setValue:self.keyword forKey:@"wd"];
    }
    
    return params;
}

@end
