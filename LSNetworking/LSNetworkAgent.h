//
//  LSNetworkAgent.h
//  LSNetworkingExample
//
//  Created by Terry Zhang on 15/12/11.
//  Copyright © 2015年 BasePod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LSNetworkDefine.h"
#import "LSRequest.h"

typedef NS_ENUM(NSUInteger, LKNetworkDetailStatus)
{
    LKNetworkDetailStatusNone,
    LKNetworkDetailStatus2G,
    LKNetworkDetailStatus3G,
    LKNetworkDetailStatus4G,
    LKNetworkDetailStatusLTE,
    LKNetworkDetailStatusWIFI,
    LKNetworkDetailStatusUnknown
};

@interface LSNetworkAgent : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, readonly) BOOL isInternetAvailiable;  //!< 是否有网络
@property (nonatomic, readonly) BOOL isWiFiAvailiable;  //!< 是否有WIFI
@property (nonatomic, readonly) LKNetworkDetailStatus networkDetailStatus;  //!< 精确的网络状态，可区分2G/3G/4G/WIFI
@property (nonatomic, readonly) NSString *networkDetailStatusDescription;   //!< 网络状态LKNetworkReachabilityStatus的文字描述

- (NSNumber *)startRequest:(LSRequest *)request complete:(LSRequestComplete)complete;
- (BOOL)isRequestLoading:(NSNumber *)requestId;
- (void)cancelRequest:(NSNumber *)requestID;
- (void)cancelAllRequest;

- (NSURLRequest *)generateURLRequest:(LSRequest *)request;
- (NSURLRequest *)generateRequestWithURL:(NSString *)url serializerType:(LSRequestSerializerType)serializerType HTTPMethod:(LSRequestHTTPMethodType)HTTPMethod httpHeader:(NSDictionary *)httpHeader requestParams:(NSDictionary *)requestParams;

@end
