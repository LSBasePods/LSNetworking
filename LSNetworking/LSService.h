//
//  LSBaseService.h
//  LSNetworkingExample
//
//  Created by Terry Zhang on 15/12/22.
//  Copyright © 2015年 BasePod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LSAPISignatureManager.h"

@class LSResponse;

@interface LSService : NSObject

@property (nonatomic, copy) NSString *serviceDomain; //!< 服务的域, 默认返回 defaultServiceDomain
@property (nonatomic, copy) NSString *serviceName;  //!< 服务名称, 默认返回 defaultServiceName

/**
 *  自定义网络层错误信息，兼容后台某些框架，某些错误无法进入业务层
 *
 *  @param response 返回值
 *
 *  @return 错误信息， 如果没有错误返回nil
 */
- (NSString *)getHttpMessageWithResponse:(LSResponse *)response;

#pragma mark - For Subclasses Overwritte
@property (nonatomic, copy) NSDictionary *commParams; //!< 共用参数信息
@property (nonatomic, copy) NSDictionary *commHeader; //!< 共用header信息
@property (nonatomic, copy) NSString *privateKey; //!< 加密的私钥
@property (nonatomic, copy) NSString *NSLocalizedFileName; //!< 指定本地化语言文件 (不包括后缀名.strings)
@property (nonatomic, assign) LSRequestSerializerType serializerType; // HTTP协议 的序列化方式

- (NSString *)defaultServiceDomain; //!< 线上服务地址,serviceDomain的默认值
- (NSString *)defaultServiceName;  //!<  线上服务名称,serviceName的默认值

/**
 *  指定签名方式，如果未提供可使用- (void)signatureWithObject: 来自定义
 *  如果两个方式都提供了 - (LSRequestSignatureType)signatureType 优先
 */
- (LSRequestSignatureType)signatureType;

/**
 *  如果现成未签名方式不符合，可自定义
 */
- (void)customSignatureWithObject:(LSAPIServiceSignatureObject *)signature;

/**
 *  可用来APIManager成功会回去数据后的回调，检查返回的数据的是否正确只要正对是code，结构上
 *
 *  @param data 返回的数据字典
 *
 *  @return error 为nil正确的
 */
- (NSError *)checkReturnStructure:(LSResponse *)response;

@end
