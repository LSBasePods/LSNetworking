//
//  LSAPISignatureManager.h
//  LSNetworkingExample
//
//  Created by Terry Zhang on 15/12/11.
//  Copyright © 2015年 BasePod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LSNetworkDefine.h"

typedef NS_ENUM(NSUInteger, LSRequestSignatureType)
{
    LSRequestSignatureTypeNone = 0,
    LSRequestSignatureTypeSortValue,
    LSRequestSignaturetypeCustomConfig
};

@class LSAPIServiceSignatureObject;

@interface LSAPISignatureManager : NSObject

+ (void)generateSigWithObject:(LSAPIServiceSignatureObject *)object type:(LSRequestSignatureType)type;
+ (NSString *)getSigWithValueSortWithParams:(NSDictionary *)params secret:(NSString *)secret;

@end

@interface LSAPIServiceSignatureObject  : NSObject

@property (nonatomic, copy) NSString *url;
@property (nonatomic, strong) NSDictionary *commParams;
@property (nonatomic, strong) NSDictionary *requestParams;
@property (nonatomic, copy) NSString *secret;
@property (nonatomic, assign) LSRequestSerializerType serializerType;
@property (nonatomic, assign) LSRequestHTTPMethodType httpMethod;

@end