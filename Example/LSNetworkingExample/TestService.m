//
//  TestService.m
//  LSNetworkingExample
//
//  Created by Terry Zhang on 15/12/22.
//  Copyright © 2015年 BasePod. All rights reserved.
//

#import "TestService.h"

@implementation TestService

- (LSRequestSerializerType)serializerType
{
    
    return LSRequestSerializerTypeURLEncode;
}

- (NSString *)defaultServiceDomain //!< 线上服务地址,serviceDomain的默认值
{
    return @"http://www.baidu.com/";
}

- (NSString *)defaultServiceName  //!<  线上服务名称,serviceName的默认值
{
    return @"s?";
}


- (LSRequestSignatureType)signatureType
{
    return LSRequestSignatureTypeNone;
}


- (BOOL)checkReturnStructure:(LSResponse *)response
{
    return YES;
}


- (NSString *)getHttpMessageWithResponse:(LSResponse *)response
{
    return nil;
}

@end
