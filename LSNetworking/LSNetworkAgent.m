//
//  LSNetworkAgent.m
//  LSNetworkingExample
//
//  Created by Terry Zhang on 15/12/11.
//  Copyright © 2015年 BasePod. All rights reserved.
//

#import "LSNetworkAgent.h"
#import "LSAPISignatureManager.h"
#import "AFURLSessionManager.h"

static NSTimeInterval kLSNetworkingTimeoutSeconds = 20.0f;

static inline NSString * LSRequestHTTPMethod(LSRequestHTTPMethodType type) {
    switch (type) {
        case LSRequestHTTPMethodGET:
            return @"GET";
        case LSRequestHTTPMethodPOST:
            return @"POST";
        case LSRequestHTTPMethodPUT:
            return @"PUT";
        case LSRequestHTTPMethodDELETE:
            return @"DELETE";
        default: {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
            return nil;
#pragma clang diagnostic pop
        }
    }
}


@interface LSNetworkAgent()

@property (nonatomic, strong) AFURLSessionManager *manager;
@property (nonatomic, strong) NSMutableDictionary *requestTaskRecord;

@property (nonatomic, strong) AFHTTPRequestSerializer *httpRequestSerializer;
@property (nonatomic, strong) AFJSONRequestSerializer *JSONRequestSerializer;

@end

@implementation LSNetworkAgent

#pragma mark - Public

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static LSNetworkAgent *sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[LSNetworkAgent alloc] init];
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    });
    return sharedInstance;
}

- (NSDictionary *)commonDicWithCustomDic:(NSDictionary *)customDic origCommonDic:(NSDictionary *)origCommonDic
{
    NSMutableDictionary *commonParams = [origCommonDic mutableCopy];
    [commonParams enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        id value = customDic[key];
        if (value) {
            [commonParams setValue:key forKey:key];
        }
    }];
    return [commonParams copy];
}

- (NSDictionary *)httpParamsWithRequestParams:(NSDictionary *)requestParams commonParams:(NSDictionary *)commonParams
{
    NSMutableDictionary *httpParams = [NSMutableDictionary dictionary];
    [httpParams addEntriesFromDictionary:[self commonDicWithCustomDic:requestParams origCommonDic:commonParams]];
    [httpParams addEntriesFromDictionary:requestParams];
    return httpParams;
}

- (NSNumber *)startRequest:(LSRequest *)request complete:(LSRequestComplete)complete
{
    // 首先 检查参数 是否合法
    if (![self checkRequestParams:request complete:complete]) {
        return nil;
    }
    
    LSResponse *myResponse = [LSResponse new];
    //  创建请求
    NSURLRequest *urlRequest = [self generateURLRequest:request];
    __weak __typeof(self)weakSelf = self;
    NSURLSessionDataTask *dataTask = [self.manager dataTaskWithRequest:urlRequest uploadProgress:0 downloadProgress:0 completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        myResponse.responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        if (responseObject) {
            myResponse.responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        }
        
        if (error) {
            // 请求错误
            if (![strongSelf isRequestCanceled:myResponse.requestId]) {
                myResponse.responseStatusCode = LSResponseStatusCodeErrorRequest;
                myResponse.requestStatusCode = error.code;//kCFURLErrorTimedOut

                NSString *message = nil;
                message = [request.serviceConfig getHttpMessageWithResponse:myResponse];
                if (message.length == 0) {
                    message = [request getLocalizedDescriptionWithStatusCode:myResponse.requestStatusCode];
                }
                myResponse.message = message;
                
                complete ? complete(myResponse, error) : nil;
            }
        } else {
            // 成功返回
            if (![strongSelf isRequestCanceled:myResponse.requestId]) {
                myResponse.returnObject = responseObject;
                
                // 针对 Response Object 进行结果处理
                NSError *error = nil;
                
                [strongSelf handleSuccessResponse:myResponse error:error forRequest:request];
                complete ? complete(myResponse, error) : nil;
            }
        }
        [strongSelf removeRequestTask:myResponse.requestId];
    }];
    
    myResponse.requestId = @(dataTask.taskIdentifier);
    myResponse.userInfo = request.userInfo;
    
    [dataTask resume];
    [self addRequestTask:dataTask];
    
    return @(dataTask.taskIdentifier);
}

- (void)cancelRequest:(NSNumber *)requestId
{
    NSURLSessionDataTask *dataTask = self.requestTaskRecord[requestId];
    [dataTask cancel];
    [self removeRequestTask:requestId];
}

- (void)cancelAllRequest
{
    for (NSNumber *requestId in self.requestTaskRecord.allKeys) {
        [self cancelRequest:requestId];
    }
}

- (BOOL)isRequestLoading:(NSNumber *)requestId
{
    if ([self.requestTaskRecord.allKeys containsObject:requestId]) {
        return YES;
    }
    return NO;
}

- (BOOL)isInternetAvailiable
{
    return [AFNetworkReachabilityManager sharedManager].reachable;
}

- (BOOL)isWiFiAvailiable
{
    AFNetworkReachabilityStatus status = [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
    return status == AFNetworkReachabilityStatusReachableViaWiFi;
}

- (LKNetworkDetailStatus)networkDetailStatus
{
    NSArray *subviews = [[[[UIApplication sharedApplication] valueForKey:@"statusBar"] valueForKey:@"foregroundView"]subviews];
    NSNumber *dataNetworkItemView = nil;
    
    if (subviews) {
        for (id subview in subviews) {
            if([subview isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]]) {
                dataNetworkItemView = subview;
                break;
            }
        }
    }
    
    LKNetworkDetailStatus status = LKNetworkDetailStatusUnknown;
    if (!dataNetworkItemView) {
        return status;
    }
    
    switch ([[dataNetworkItemView valueForKey:@"dataNetworkType"]integerValue]) {
        case 0:
            status = LKNetworkDetailStatusNone;
            break;
        case 1:
            status = LKNetworkDetailStatus2G;
            break;
        case 2:
            status = LKNetworkDetailStatus3G;
            break;
        case 3:
            status = LKNetworkDetailStatus4G;
            break;
        case 4:
            status = LKNetworkDetailStatusLTE;
            break;
        case 5:
            status = LKNetworkDetailStatusWIFI;
            break;
        default:
            break;
    }
    return status;
}

- (NSString *)networkDetailStatusDescription
{
    
    NSString *desc = @"";
    switch (self.networkDetailStatus) {
        case LKNetworkDetailStatusWIFI:
            desc = @"WIFI";
            break;
            
        case LKNetworkDetailStatus2G:
            desc = @"2G";
            break;
            
        case LKNetworkDetailStatus3G:
            desc = @"3G";
            break;
            
        case LKNetworkDetailStatus4G:
            desc = @"4G";
            break;
            
        case LKNetworkDetailStatusLTE:
            desc = @"LTE";
            break;
            
        case LKNetworkDetailStatusUnknown:
            desc = @"unknown";
            break;
        case LKNetworkDetailStatusNone:
            desc = @"none";
            break;
            
        default:
            desc = @"";
            break;
    }
    
    return desc;
}

#pragma mark - Privite

// 根据requestId 判断请求是否被取消
- (BOOL)isRequestCanceled:(NSNumber *)requestId
{
    if (!requestId) {
        return YES;
    }
    return !self.requestTaskRecord[requestId];
}

// 创建请求时， 向字典中添加记录
- (void)addRequestTask:(NSURLSessionDataTask *)dataTask
{
    if (!dataTask) {
        return;
    }
    @synchronized(self) {
        [self.requestTaskRecord setObject:dataTask forKey:@(dataTask.taskIdentifier)];
    }
}

// 请求完成、取消时， 从字典中移除记录
- (void)removeRequestTask:(NSNumber *)requestId
{
    @synchronized(self) {
        [self.requestTaskRecord removeObjectForKey:requestId];
    }
}

- (NSString *)buildRequestUrl:(LSRequest *)request
{
    NSString *url = nil;
    
    if (request.customUrl.length > 0) {
        url = request.customUrl;
    } else {
        url = [NSString stringWithFormat:@"%@%@%@",request.serviceConfig.serviceDomain,request.serviceConfig.serviceName,request.methodName];
    }
    
    if (url.length == 0) {
        NSLog(@"serviceConfig is nil");
    }
    return url;
}

- (NSURLRequest *)generateURLRequest:(LSRequest *)request
{
    // 签名
    LSAPIServiceSignatureObject *signature = [LSAPIServiceSignatureObject new];
    signature.url = [self buildRequestUrl:request];
    signature.commParams = [self commonDicWithCustomDic:request.requestParams origCommonDic:request.serviceConfig.commParams];
    signature.requestParams = request.requestParams;
    signature.secret = request.serviceConfig.privateKey;
    signature.httpMethod = request.httpMethod;
    signature.serializerType = request.serviceConfig.serializerType;
    
    if ([request.serviceConfig respondsToSelector:@selector(signatureType)] && [request.serviceConfig signatureType]!=LSRequestSignaturetypeCustomConfig) {
        [LSAPISignatureManager handleObject:signature signatureType:[request.serviceConfig signatureType]];
    } else if ([request.serviceConfig respondsToSelector:@selector(customSignatureWithObject:)]) {
        [request.serviceConfig customSignatureWithObject:signature];
    } else {
        NSLog(@"Signature Error: Please implementation the selector customSignatureWithObject: in the subclass of LSService");
    }
    
    //TODO if api need server username and password
    
    // 各种参数
    LSRequestHTTPMethodType httpMethod = request.httpMethod;
    NSString *httpUrl = signature.url;
    LSRequestSerializerType httpSerializerType = signature.serializerType;
    NSDictionary *httpHeader = [self httpParamsWithRequestParams:request.requestHeader commonParams:request.serviceConfig.commHeader];
    NSDictionary *httpParams = [self httpParamsWithRequestParams:signature.requestParams commonParams:signature.commParams];
    
    return [self generateRequestWithURL:httpUrl serializerType:httpSerializerType HTTPMethod:httpMethod httpHeader:httpHeader requestParams:httpParams];
}

- (NSURLRequest *)generateRequestWithURL:(NSString *)url serializerType:(LSRequestSerializerType)serializerType HTTPMethod:(LSRequestHTTPMethodType)HTTPMethod httpHeader:(NSDictionary *)httpHeader requestParams:(NSDictionary *)requestParams
{
    NSURLRequest *request = nil;
    if (requestParams.count == 0) {
        requestParams = nil;
    }
    switch (serializerType) {
        case LSRequestSerializerTypeURLEncode:
            request = [self generateURLEncodeRequestWithURL:url HTTPMethod:HTTPMethod httpHeader:httpHeader requestParams:requestParams];
            break;
        case LSRequestSerializerTypeJson:
            request =  [self generateJSONRequestWithURL:url HTTPMethod:HTTPMethod httpHeader:httpHeader requestParams:requestParams];
            break;
        case LSRequestSerializerTypeFormData:
            request =  [self generateFormDataRequestWithURL:url HTTPMethod:HTTPMethod httpHeader:httpHeader requestParams:requestParams];
            break;
    }
    
    NSLog(@"request url %@", request.URL);
    NSLog(@"request HTTPMethod %@", request.HTTPMethod);
    NSLog(@"request requestParams %@", requestParams);
    NSLog(@"request HTTPHeaderFields %@", request.allHTTPHeaderFields);
    return request;
}

- (NSURLRequest *)generateURLEncodeRequestWithURL:(NSString *)url HTTPMethod:(LSRequestHTTPMethodType)HTTPMethod httpHeader:(NSDictionary *)httpHeader requestParams:(NSDictionary *)requestParams
{
    [httpHeader enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSNumber class]]) {
            [self.httpRequestSerializer setValue:[obj stringValue] forHTTPHeaderField:key];
        } else {
            [self.httpRequestSerializer setValue:obj forHTTPHeaderField:key];
        }
    }];
    
    return [self.httpRequestSerializer requestWithMethod:LSRequestHTTPMethod(HTTPMethod) URLString:url parameters:requestParams error:nil];
}

- (NSURLRequest *)generateJSONRequestWithURL:(NSString *)url HTTPMethod:(LSRequestHTTPMethodType)HTTPMethod httpHeader:(NSDictionary *)httpHeader requestParams:(NSDictionary *)requestParams
{
    [httpHeader enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSNumber class]]) {
            [self.JSONRequestSerializer setValue:[obj stringValue] forHTTPHeaderField:key];
        } else {
            [self.JSONRequestSerializer setValue:obj forHTTPHeaderField:key];
        }
    }];
    
    return [self.JSONRequestSerializer requestWithMethod:LSRequestHTTPMethod(HTTPMethod) URLString:url parameters:requestParams error:nil];
}

- (NSURLRequest *)generateFormDataRequestWithURL:(NSString *)url HTTPMethod:(LSRequestHTTPMethodType)HTTPMethod httpHeader:(NSDictionary *)httpHeader requestParams:(NSDictionary *)requestParams
{
    [httpHeader enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSNumber class]]) {
            [self.httpRequestSerializer setValue:[obj stringValue] forHTTPHeaderField:key];
        } else {
            [self.httpRequestSerializer setValue:obj forHTTPHeaderField:key];
        }
    }];
    
    return [self.httpRequestSerializer multipartFormRequestWithMethod:LSRequestHTTPMethod(HTTPMethod) URLString:url parameters:requestParams constructingBodyWithBlock:nil error:nil];
}

- (BOOL)checkRequestParams:(LSRequest *)request complete:(LSRequestComplete)complete
{
    if (![request respondsToSelector:@selector(checkRequestParam:)]) {
        return YES;
    }
    
    NSString *paramsErrorMsg = [request checkRequestParam:request.requestParams];
    if (paramsErrorMsg.length) {
        LSResponse *response = [LSResponse new];
        response.responseStatusCode = LSResponseStatusCodeErrorParam;
        response.message = paramsErrorMsg;
        NSError *error = [NSError errorWithDomain:LSNetworkingErrorDomain code:LSResponseStatusCodeErrorParam userInfo:[NSDictionary dictionaryWithObject:[request getLocalizedDescriptionWithStatusCode:response.responseStatusCode] forKey:NSLocalizedDescriptionKey]];
        complete ? complete(response, error) : nil;
        return 0;
    }
    return YES;
}

/**
 *  处理 Http 请求成功返回的结果
 *
 *  @param response
 *  @param error
 *  @param request
 *
 *  @return 处理成功，返回YES；否则返回 NO
 */
- (BOOL)handleSuccessResponse:(LSResponse *)response error:(NSError *)error forRequest:(LSRequest *)request
{
    // 转换成字典  或者 mock
    id retunObject = nil;
    
    if ([request respondsToSelector:@selector(mockReturnDic)] && request.mockReturnDic) {
        retunObject = request.mockReturnDic;
    } else {
        NSData *jsonData = nil;
        if ([response.returnObject isKindOfClass:[NSData class]]) {
            jsonData = response.returnObject;
        } else {
            jsonData = [response.responseString dataUsingEncoding:NSUTF8StringEncoding];
        }
        id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
        retunObject = jsonObject;
    }
    if (!retunObject) {
        response.responseStatusCode = LSResponseStatusCodeErrorJSON;
        response.message = [request getLocalizedDescriptionWithStatusCode:response.responseStatusCode];
        error = [NSError errorWithDomain:LSNetworkingErrorDomain code:LSResponseStatusCodeErrorJSON userInfo:[NSDictionary dictionaryWithObject:[request getLocalizedDescriptionWithStatusCode:response.responseStatusCode] forKey:NSLocalizedDescriptionKey]];
        return NO;
    }
    response.returnObject = retunObject;
    
    // 检查数据结构
    if (![request.serviceConfig checkReturnStructure:response]) {
        response.responseStatusCode = LSResponseStatusCodeErrorFormat;
        response.message = [request getLocalizedDescriptionWithStatusCode:response.responseStatusCode];
        error = [NSError errorWithDomain:LSNetworkingErrorDomain code:LSResponseStatusCodeErrorFormat userInfo:[NSDictionary dictionaryWithObject:[request getLocalizedDescriptionWithStatusCode:response.responseStatusCode] forKey:NSLocalizedDescriptionKey]];
        return NO;
    }
    
    // 检查返回结果
    if ([request respondsToSelector:@selector(checkResponse:)] && ![request checkResponse:response]) {
        response.responseStatusCode = LSResponseStatusCodeErrorReturn;
        response.message = [request getLocalizedDescriptionWithStatusCode:response.responseStatusCode];
        error = [NSError errorWithDomain:LSNetworkingErrorDomain code:LSResponseStatusCodeErrorReturn userInfo:[NSDictionary dictionaryWithObject:[request getLocalizedDescriptionWithStatusCode:response.responseStatusCode] forKey:NSLocalizedDescriptionKey]];
        return NO;
    }
    
    // 转换成Model
    if ([request respondsToSelector:@selector(modelMappingFromReturnDic:)]) {
        response.returnObject = [request modelMappingFromReturnDic:retunObject];
    }
    
    response.responseStatusCode = LSResponseStatusCodeSuccess;
    return YES;
}

#pragma mark - init

- (AFURLSessionManager *)manager
{
    if (!_manager) {
        _manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        _manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        _manager.operationQueue.maxConcurrentOperationCount = 4;
    }
    return _manager;
}

- (NSMutableDictionary *)requestTaskRecord
{
    if (!_requestTaskRecord) {
        _requestTaskRecord = [[NSMutableDictionary alloc] init];
    }
    return _requestTaskRecord;
}

- (AFHTTPRequestSerializer *)httpRequestSerializer
{
    if (_httpRequestSerializer == nil) {
        _httpRequestSerializer = [AFHTTPRequestSerializer serializer];
        _httpRequestSerializer.timeoutInterval = kLSNetworkingTimeoutSeconds;
        _httpRequestSerializer.cachePolicy = NSURLRequestUseProtocolCachePolicy;
    }
    return _httpRequestSerializer;
}

- (AFJSONRequestSerializer *)JSONRequestSerializer
{
    if (_JSONRequestSerializer == nil) {
        _JSONRequestSerializer = [AFJSONRequestSerializer serializer];
        _JSONRequestSerializer.timeoutInterval = kLSNetworkingTimeoutSeconds;
        _JSONRequestSerializer.cachePolicy = NSURLRequestUseProtocolCachePolicy;
    }
    return _JSONRequestSerializer;
}

@end
