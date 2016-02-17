//
//  LSBaseService.m
//  LSNetworkingExample
//
//  Created by Terry Zhang on 15/12/22.
//  Copyright © 2015年 BasePod. All rights reserved.
//

#import "LSService.h"
#import "LSRequest.h"

@implementation LSService

- (NSString *)defaultServiceDomain
{
    return @"";
}

- (NSString *)defaultServiceName
{
    return @"";
}

- (NSError *)checkReturnStructure:(LSResponse *)response
{
    return nil;
}

- (NSString *)getHttpMessageWithResponse:(LSResponse *)response
{
    NSString *responseString = response.responseString;
    if ([responseString isKindOfClass:[NSString class]] && responseString.length < 50 && responseString.length > 0) {
        return responseString;
    }
    return nil;
}

- (LSRequestSignatureType)signatureType
{
    return LSRequestSignatureTypeNone;
}

- (void)customSignatureWithObject:(LSAPIServiceSignatureObject *)signature
{
    return ;
}

-(NSString *)serviceDomain
{
    if (!_serviceDomain) {
        return [self defaultServiceDomain];
    }
    return _serviceDomain;
}

- (NSString *)serviceName
{
    if (!_serviceName) {
        return [self defaultServiceName];
    }
    return _serviceName;
}

@end
