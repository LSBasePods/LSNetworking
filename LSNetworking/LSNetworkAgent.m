//
//  LSNetworkAgent.m
//  LSNetworkingExample
//
//  Created by Terry Zhang on 15/12/11.
//  Copyright © 2015年 BasePod. All rights reserved.
//

#import "LSNetworkAgent.h"
#import "AFHTTPRequestOperationManager.h"
#import "LSAPISignatureManager.h"

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

@property (nonatomic, strong) AFHTTPRequestOperationManager *operationManager;
@property (nonatomic, strong) NSMutableDictionary *requestOperationRecord;

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

- (NSNumber *)startRequest:(LSRequest *)request complete:(LSRequestComplete)complete
{
    // 首先 检查参数
    if (![self checkRequestParams:request complete:complete]) {
        return nil;
    }
    
    //  创建请求
    NSNumber *requestId = [self generateRequestId];

    LSResponse *response = [LSResponse new];
    response.requestId = requestId;
    NSURLRequest *urlRequest = [self generateURLRequest:request];
    __weak __typeof(self)weakSelf = self;
    AFHTTPRequestOperation *httpRequestOperation = [self.operationManager HTTPRequestOperationWithRequest:urlRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // 成功返回
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (![strongSelf isCanceled:requestId]) {
            [strongSelf removeOperationForRequest:requestId];
            response.userInfo = operation.userInfo;
            response.responseString = operation.responseString;
            
            // 针对 Response String 进行结果处理
            if (![strongSelf handleSuccessResponse:response forRequest:request complete:complete]) {
                return ;
            }
            
            response.responseStatusCode = LSResponseStatusCodeSuccess;
            complete ? complete(response, nil) : nil;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // 请求错误
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf removeOperationForRequest:requestId];
        if (![strongSelf isCanceled:requestId]) {
            response.responseStatusCode = LSResponseStatusCodeErrorRequest;
            if (operation.response) {
                response.responseString = operation.responseString;
                response.requestStatusCode = operation.response.statusCode;
            } else {
                response.requestStatusCode = error.code;//kCFURLErrorTimedOut
            }
            response.userInfo = operation.userInfo;
            
            NSString *message = nil;
            message = [request.serviceConfig getHttpMessageWithResponse:response];
            if (message.length == 0) {
                message = [request getLocalizedDescriptionWithStatusCode:response.requestStatusCode];
            }
            response.message = message;
            
            complete ? complete(response, error) : nil;
        }
    }];
    
    httpRequestOperation.userInfo = request.userInfo;
    [self addOperation:httpRequestOperation forRequest:requestId];
    [[self.operationManager operationQueue] addOperation:httpRequestOperation];
    
    return requestId;
}

- (void)cancelRequest:(NSNumber *)requestId
{
    AFHTTPRequestOperation *requestOperation = self.requestOperationRecord[requestId];
    [requestOperation cancel];
    [self removeOperationForRequest:requestId];
}

- (void)cancelAllRequest
{
    for (NSNumber *requestId in self.requestOperationRecord.allKeys) {
        [self cancelRequest:requestId];
    }
}

- (BOOL)isRequestLoading:(NSNumber *)requestId
{
    if ([self.requestOperationRecord.allKeys containsObject:requestId]) {
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

// 根据请求ID 判断请求是否被取消
- (BOOL)isCanceled:(NSNumber *)requestId
{
    return !self.requestOperationRecord[requestId];
}

// 创建请求时， 向字典中添加记录
- (void)addOperation:(AFHTTPRequestOperation *)opertation forRequest:(NSNumber *)requestId
{
    @synchronized(self) {
        self.requestOperationRecord[requestId] = opertation;
    }
}

// 请求完成、取消时， 从字典中移除记录
- (void)removeOperationForRequest:(NSNumber *)requestId
{
    if (!requestId) {
        return;
    }
    @synchronized(self) {
        [self.requestOperationRecord removeObjectForKey:requestId];
    }
}

- (NSNumber *)generateRequestId
{
    static NSNumber *requestId = nil;
    if (requestId == nil) {
        requestId = @(1);
    } else {
        if ([requestId integerValue] == NSIntegerMax) {
            requestId = @(1);
        } else {
            requestId = @([requestId integerValue] + 1);
        }
    }
    return requestId;
}

- (NSString *)buildRequestUrl:(LSRequest *)request
{
    NSString *url = [NSString stringWithFormat:@"%@%@%@",request.serviceConfig.serviceDomain,request.serviceConfig.serviceName,request.methodName];
    if (url.length == 0) {
        NSLog(@"serviceConfig is nil");
    }
    return url;
}

- (NSURLRequest *)generateURLRequest:(LSRequest *)request
{
    NSString *url = [self buildRequestUrl:request];
    LSRequestSerializerType contentType = request.serviceConfig.serializerType;
    LSRequestHTTPMethodType httpMethod = request.httpMethod;
    NSDictionary *httpHeader = request.serviceConfig.commHeader;
    NSString *privateKey = request.serviceConfig.privateKey;
    NSDictionary *requestParams = request.requestParams;
    NSMutableDictionary *commParams = [request.serviceConfig.commParams mutableCopy];
    
    //实现apiParams的键值对覆盖commParams的键值对
    [commParams enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id value = requestParams[key];
        if (value) {
            [commParams setValue:value forKey:key];
        }
    }];
    
    LSAPIServiceSignatureObject *signature = [LSAPIServiceSignatureObject new];
    signature.url = url;
    signature.commParams = commParams;
    signature.requestParams = requestParams;
    signature.secret = privateKey;
    signature.httpMethod = httpMethod;
    signature.serializerType = contentType;
    if ([request.serviceConfig respondsToSelector:@selector(signatureType)] && [request.serviceConfig signatureType]!=LSRequestSignaturetypeCustomConfig) {
        [LSAPISignatureManager generateSigWithObject:signature type:[request.serviceConfig signatureType]];
    } else if ([request.serviceConfig respondsToSelector:@selector(customSignatureWithObject:)]) {
        [request.serviceConfig customSignatureWithObject:signature];
    } else {
        NSMutableDictionary *temp = [NSMutableDictionary dictionary];
        [temp addEntriesFromDictionary:commParams];
        [temp addEntriesFromDictionary:requestParams];
        signature.requestParams = temp;
    }
    
    return [self generateRequestWithURL:signature.url serializerType:signature.serializerType HTTPMethod:httpMethod httpHeader:httpHeader requestParams:signature.requestParams];
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
 *  根据 responseString 处理返回结果
 *
 *  @param response
 *  @param request
 *  @param complete 用来出错后在方法内调用错误回调
 *
 *  @return 处理成功，返回YES；否则返回 NO
 */
- (BOOL)handleSuccessResponse:(LSResponse *)response forRequest:(LSRequest *)request complete:(LSRequestComplete)complete
{
    NSError *error;
    
    // 转换成字典  或者 mock
    id retunObject = nil;
    
    if ([request respondsToSelector:@selector(mockReturnDic)] && request.mockReturnDic) {
        response.requestStatusCode = LSResponseStatusCodeSuccess;
        response.returnObject = request.mockReturnDic;
    } else {
        NSData *jsonData = [response.responseString dataUsingEncoding:NSUTF8StringEncoding];
        id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
        retunObject = jsonObject;
    }
    if (!retunObject) {
        response.responseStatusCode = LSResponseStatusCodeErrorJSON;
        response.message = [request getLocalizedDescriptionWithStatusCode:response.responseStatusCode];
        error = [NSError errorWithDomain:LSNetworkingErrorDomain code:LSResponseStatusCodeErrorParam userInfo:[NSDictionary dictionaryWithObject:[request getLocalizedDescriptionWithStatusCode:response.responseStatusCode] forKey:NSLocalizedDescriptionKey]];
        complete ? complete(response, error) : nil;
        return NO;
    }
    response.returnObject = retunObject;
    
    // 检查数据结构
    if (![request.serviceConfig checkReturnStructure:response]) {
        response.responseStatusCode = LSResponseStatusCodeErrorFormat;
        response.message = [request getLocalizedDescriptionWithStatusCode:response.responseStatusCode];
        error = [NSError errorWithDomain:LSNetworkingErrorDomain code:LSResponseStatusCodeErrorParam userInfo:[NSDictionary dictionaryWithObject:[request getLocalizedDescriptionWithStatusCode:response.responseStatusCode] forKey:NSLocalizedDescriptionKey]];
        complete ? complete(response, error) : nil;
        return NO;
    }
    
    // 检查返回结果
    if ([request respondsToSelector:@selector(checkResponse:)] && ![request checkResponse:response]) {
        response.responseStatusCode = LSResponseStatusCodeErrorReturn;
        response.message = [request getLocalizedDescriptionWithStatusCode:response.responseStatusCode];
        error = [NSError errorWithDomain:LSNetworkingErrorDomain code:LSResponseStatusCodeErrorParam userInfo:[NSDictionary dictionaryWithObject:[request getLocalizedDescriptionWithStatusCode:response.responseStatusCode] forKey:NSLocalizedDescriptionKey]];
        complete ? complete(response, error) : nil;
        return NO;
    }
    
    // 转换成Model
    if ([request respondsToSelector:@selector(modelMappingFromReturnDic:)]) {
        response.returnObject = [request modelMappingFromReturnDic:retunObject];
    }
    
    return YES;
}

#pragma mark - init

- (AFHTTPRequestOperationManager *)operationManager
{
    if (_operationManager == nil) {
        _operationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:nil];
        _operationManager.responseSerializer.acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(100, 500)];
        _operationManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        _operationManager.operationQueue.maxConcurrentOperationCount = 4;
    }
    return _operationManager;
}

- (NSMutableDictionary *)requestOperationRecord
{
    if (!_requestOperationRecord) {
        _requestOperationRecord = [[NSMutableDictionary alloc] init];
    }
    return _requestOperationRecord;
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
