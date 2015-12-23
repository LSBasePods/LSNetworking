//
//  LSNetworkDefine.h
//  LSNetworkingExample
//
//  Created by Terry Zhang on 15/12/21.
//  Copyright © 2015年 BasePod. All rights reserved.
//

#import <Foundation/Foundation.h>
#define LSNetworkingErrorDomain @"com.basePod.LSNetworking"

typedef NS_ENUM(NSInteger, LSRequestHTTPMethodType) {
    LSRequestHTTPMethodGET = 0,
    LSRequestHTTPMethodPOST,
    LSRequestHTTPMethodPUT,
    LSRequestHTTPMethodDELETE
};

typedef NS_ENUM(NSUInteger, LSRequestSerializerType)
{
    LSRequestSerializerTypeURLEncode = 0,
    LSRequestSerializerTypeFormData,
    LSRequestSerializerTypeJson
};

typedef NS_ENUM(NSUInteger, LSResponseStatusCode)
{
    LSResponseStatusCodeErrorParam = 2000,          //!< 上传参数错误
    LSResponseStatusCodeErrorRequest = 2001,        //!< request失败
    LSResponseStatusCodeErrorJSON = 2002,           //!< 转换JSON失败
    LSResponseStatusCodeErrorFormat = 2003,         //!< api格式返回错误
    LSResponseStatusCodeErrorReturn = 2004,         //!< 业务返回错误, response code
    LSResponseStatusCodeSuccess = 0                 //!< api格式返回正确
};
