//
//  LSAPISignatureManager.m
//  LSNetworkingExample
//
//  Created by Terry Zhang on 15/12/11.
//  Copyright © 2015年 BasePod. All rights reserved.
//

#import "LSAPISignatureManager.h"
#import "LSNetworkAgent.h"
#import <CommonCrypto/CommonDigest.h>

@implementation LSAPIServiceSignatureObject

@end

@interface LSAPISignatureManager ()

@end

@implementation LSAPISignatureManager

+ (void)handleObject:(LSAPIServiceSignatureObject *)object signatureType:(LSRequestSignatureType)type
{
    switch (type) {
        case LSRequestSignatureTypeSortValue:
        {
            
            NSMutableDictionary *signParams = [NSMutableDictionary dictionaryWithDictionary:object.commParams];
            if (object.httpMethod == LSRequestHTTPMethodGET || object.httpMethod == LSRequestHTTPMethodDELETE) {
                [signParams addEntriesFromDictionary:object.requestParams];
            }
            NSString *sig = [LSAPISignatureManager getSigWithValueSortWithParams:signParams secret:object.secret];
            
            
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:object.commParams];
            [params setValue:sig forKey:@"sign"];
            object.commParams = params;
            
            NSURLRequest *request = [[LSNetworkAgent sharedInstance] generateRequestWithURL:object.url serializerType:object.serializerType HTTPMethod:LSRequestHTTPMethodGET httpHeader:nil requestParams:object.commParams];
            NSString *url = request.URL.absoluteString;
            object.url = url;
            
        }
            break;
        case LSRequestSignatureTypeSortKeyValue:
        {
            
            NSMutableDictionary *signParams = [NSMutableDictionary dictionaryWithDictionary:object.commParams];
            [signParams addEntriesFromDictionary:object.requestParams];
            NSString *sig = [LSAPISignatureManager getSigWithKeyValueSortWithParams:signParams secret:object.secret];
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:object.commParams];
            [params setValue:sig forKey:@"sign"];
            object.commParams = params;
            
            NSURLRequest *request = [[LSNetworkAgent sharedInstance] generateRequestWithURL:object.url serializerType:object.serializerType HTTPMethod:object.httpMethod httpHeader:nil requestParams:object.commParams];
            NSString *url = request.URL.absoluteString;
            object.url = url;
            
        }
            break;
        default:
            break;
    }
}

+ (NSString *)getSigWithKeyValueSortWithParams:(NSDictionary *)params secret:(NSString *)secret
{
    NSString *sig = @"";
    NSArray *allKeys = [params allKeys];
    NSArray *array2 = [allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSMutableString *string = [[NSMutableString alloc] init];
    [array2 enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [string appendFormat:@"%@=%@&", obj, params[obj]];
    }];
    [string appendFormat:@"app_secret=%@", secret];
    sig = [self _lsntwk_md5:string];
    sig = [sig uppercaseString];
    return sig;
}


+ (NSString *)getSigWithValueSortWithParams:(NSDictionary *)params secret:(NSString *)secret
{
    NSString *sig = @"";
    NSArray *allKeys = [params allKeys];
    NSArray *array2 = [allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSMutableString *string = [[NSMutableString alloc] init];
    [array2 enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [string appendFormat:@"%@", params[obj]];
    }];
    [string appendFormat:@"%@", secret];
    sig = [self _lsntwk_md5:string];
    return sig;
}

+ (NSString *)generateURLString:(NSString *)url params:(NSDictionary *)params
{
    NSString *paramString = @"";
    for (NSString *key in params) {
        id value = [params objectForKey:key];
        if (paramString.length > 1) {
            paramString = [paramString stringByAppendingString:@"&"];
        }
        paramString = [paramString stringByAppendingString:[NSString stringWithFormat:@"%@=%@", key, value]];
    }
    
    NSString *newURL = [url stringByAppendingFormat:[NSURL URLWithString:url].query ? @"&%@" : @"?%@", paramString];
    return newURL;
}

+ (NSString *)_lsntwk_md5:(NSString *)originStr
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