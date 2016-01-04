//
//  LSRequest.h
//  LSNetworkingExample
//
//  Created by Terry Zhang on 15/12/11.
//  Copyright © 2015年 BasePod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LSNetworkDefine.h"
#import "LSService.h"

@class LSResponse;

typedef void(^LSRequestComplete)(LSResponse *response, NSError *error);

@protocol LSRequestConfigProtocol <NSObject>

@required
- (NSString *)methodName; //!< 方法名， 用于URL 的生成
- (LSRequestHTTPMethodType)httpMethod;  // HTTP 方法

@optional

@property (nonatomic, copy) NSDictionary *requestParams; //!< 请求参数，
@property (nonatomic, copy) NSDictionary *requestHeader; //!< 请求Header
@property (nonatomic, copy) NSDictionary *userInfo;     //!< 用于变量的传递
@property (nonatomic, copy) NSString *customUrl;        //!< 定制的URL
@property (nonatomic, copy) Class customServiceClass;      //!< 自定义Service，不设定使用默认的Service

- (NSDictionary *)mockReturnDic;//!< mock API Return ，用于mock借口出来以前，本地定义

@end

@protocol LSRequestDelegateProtocol <NSObject>

@optional

/**
 *  可用来APIManager发出请求前，检查上传的参数是否正确
 *
 *  @param params 上传的参数
 *
 *  @return 错误信息 如果正确，返回nil
 */
- (NSString *)checkRequestParam:(NSDictionary *)params;

/**
 *  可用来APIManager成功会回去数据后的回调，检查返回的数据的是否正确
 *  可以在这里处理 Status Code
 *
 *  @param response 可以在这里对response的内容进行修改
 *
 *  @return 是否符合之前的约定
 */
- (BOOL)checkResponse:(LSResponse *)response;

/**
 *  API返回格式正确，转换成model
 *
 *  @param dic 根据返回的结果转换成的字典
 *
 *  @return 转换后的 model
 */
- (id)modelMappingFromReturnDic:(NSDictionary *)dic;

@end

@interface LSRequest : NSObject <LSRequestConfigProtocol, LSRequestDelegateProtocol>

@property (nonatomic, strong, readonly) NSNumber *lastRequestId;
@property (nonatomic, strong, readonly) LSService *serviceConfig;

@property (nonatomic, copy) Class customServiceClass;


#pragma mark - Public Methods

/**
 *  API的调用，会自动使用self.params做请求参数
 *
 *  @param complete  完成后的回调
 *
 *  @return requestId
 */
- (NSNumber *)startWithComplete:(LSRequestComplete)complete;

/**
 *  取消指定的 request
 *
 *  @param requestId
 */
- (void)cancel:(NSNumber *)requestId;

/**
 *  取消所有的 request
 */
- (void)cancelAll;


/**
 *  判断request是否正在加载
 *
 *  @param requestId
 *
 *  @return 如果正在加载返回YES，否则返回NO
 */
- (BOOL)isLoading:(NSNumber *)requestId;

/**
 *  根据statusCode获取具体描述
 *
 *  @param statusCode  状态码
 *
 *  @return 具体描述
 */
- (NSString *)getLocalizedDescriptionWithStatusCode:(NSInteger)statusCode;

#pragma mark Methods For Subclasses to Overwritte
// LSRequestConfigProtocol Methods
// LSRequestDelegateProtocol Methods

@end

@interface LSResponse : NSObject

@property (nonatomic, strong) NSNumber *requestId;
@property (nonatomic, strong) NSDictionary *userInfo;

///Error codes for CFURLConnection and CFURLProtocol e.g.: kCFURLErrorTimedOut , LSResponseStatusCode = LSResponseStatusCodeErrorRequest时起作用
@property (nonatomic, assign) NSInteger requestStatusCode;
@property (nonatomic, assign) LSResponseStatusCode responseStatusCode;

@property (nonatomic, assign) NSUInteger *code;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *responseString;
@property (nonatomic, strong) id returnObject;

@end

