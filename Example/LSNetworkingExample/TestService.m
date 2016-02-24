//
//  TestService.m
//  LSNetworkingExample
//
//  Created by Terry Zhang on 15/12/22.
//  Copyright © 2015年 BasePod. All rights reserved.
//

#import "TestService.h"
#import <CommonCrypto/CommonDigest.h>

@implementation TestService

- (LSRequestSerializerType)serializerType
{
    
    return LSRequestSerializerTypeURLEncode;
}

- (NSString *)defaultServiceDomain //!< 线上服务地址,serviceDomain的默认值
{
    return @"http://app.api.test.join10.com/";
}

- (NSString *)defaultServiceName  //!<  线上服务名称,serviceName的默认值
{
    return @"";
}

- (NSString *)privateKey
{
    return @"yourappSecret";
}

- (NSDictionary *)commParams
{
    return @{
             @"app_key":@"yourappkey",
             @"time":@"2015-12-18 17:30:20",
             @"format":@"json",
             @"v":@"1.0"
             };
}

- (LSRequestSignatureType)signatureType
{
    return LSRequestSignatureTypeSortKeyValue;
}

- (void)customSignatureWithObject:(LSAPIServiceSignatureObject *)signature
{
    NSMutableDictionary *signParams = [NSMutableDictionary dictionaryWithDictionary:signature.commParams];
    [signParams addEntriesFromDictionary:signature.requestParams];
    
    NSString *sig = [self getSigWithValueSortWithParams:signParams secret:signature.secret];

    NSMutableDictionary *newParams = [signature.requestParams mutableCopy];
    [newParams setValue:sig forKey:@"sign"];
    signature.requestParams = newParams;
    NSLog(@"request sign %@",sig);
}


- (NSError *)checkReturnStructure:(LSResponse *)response
{
    return nil;
}

- (NSString *)getSigWithValueSortWithParams:(NSDictionary *)params secret:(NSString *)secret
{
    NSString *sig = @"";
    NSArray *allKeys = [params allKeys];
    NSArray *array2 = [allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSMutableString *string = [[NSMutableString alloc] init];
    [array2 enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [string appendFormat:@"%@=%@&",  obj, params[obj]];
    }];
    [string appendFormat:@"app_secret=%@", secret];
    sig = [[self _lsntwk_md5:string] uppercaseString];
    return sig;
}

- (NSString *)_lsntwk_md5:(NSString *)originStr
{
    const char *cStr = [originStr UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), result );
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

@end
