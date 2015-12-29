//
//  LSRequest.m
//  LSNetworkingExample
//
//  Created by Terry Zhang on 15/12/11.
//  Copyright © 2015年 BasePod. All rights reserved.
//

#import "LSRequest.h"
#import "AFURLRequestSerialization.h"
#import "LSNetworkConfig.h"
#import "LSNetworkAgent.h"

@interface LSRequest ()

@property (nonatomic, strong) NSNumber *lastRequestId;

@end

@implementation LSRequest

@synthesize requestParams = _requestParams;
@synthesize userInfo = _userInfo;
@synthesize serviceConfig = _serviceConfig;
@synthesize customUrl = _customUrl;
@synthesize customServiceClass = _customServiceClass;

#pragma mark - Public Method

- (NSNumber *)startWithComplete:(LSRequestComplete)complete
{
    return [[LSNetworkAgent sharedInstance] startRequest:self complete:complete];
}

- (void)cancel:(NSNumber *)requestId;
{
    [[LSNetworkAgent sharedInstance] cancelRequest:requestId];
}

- (void)cancelAll
{
    [[LSNetworkAgent sharedInstance] cancelAllRequest];
}

- (BOOL)isLoading:(NSNumber *)requestId
{
    return [[LSNetworkAgent sharedInstance] isRequestLoading:requestId];
}

- (NSString *)getLocalizedDescriptionWithStatusCode:(NSInteger)statusCode
{
    switch (statusCode) {
        case LSResponseStatusCodeErrorParam:
            return @"请求参数错误";
            break;
        case LSResponseStatusCodeErrorRequest:
            return @"Http 请求错误";
            break;

        case LSResponseStatusCodeErrorJSON:
            return @"返回结果不是JSON 格式";
            break;
        case LSResponseStatusCodeErrorFormat:
            return @"返回的JSON格式不符合约定";
            break;
        case LSResponseStatusCodeErrorReturn:
            return @"服务器返回的业务错误";
            break;
        case LSResponseStatusCodeSuccess:
            return @"请求成功";
            break;


        default:
            return @"未定义";
            break;
    }

    return @"";
}

- (LSRequestHTTPMethodType)httpMethod
{
    return 0;
}

- (NSString *)methodName
{
    return @"";
}

# pragma mark - Private Method



#pragma mark - Property Getter & Setter

- (void)setCustomServiceClass:(Class)customServiceClass
{
    if (!customServiceClass) {
        _serviceConfig = nil;
    }
    if ([customServiceClass isKindOfClass:[LSService class]]) {
        _customServiceClass = customServiceClass;
        _serviceConfig = [_customServiceClass new];
    }
}

- (LSService *)serviceConfig
{
    if (!_serviceConfig) {
        return [LSNetworkConfig sharedInstance].commonService;
    }
    return _serviceConfig;
}

@end

@implementation LSResponse
@end
