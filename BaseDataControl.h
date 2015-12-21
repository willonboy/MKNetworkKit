//
//  BaseDataControl.h
//  GeLongPro
//
//  Created by willonboy on 15/6/24.
//  Copyright (c) 2015年 com.willonboy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "BaseEntity.h"
#import "MKNetworkKit.h"




    /// 用户信息相关错误码
    /// 无效的token, 登录过期
#define kLoginExp                           (302)
    /// 接口的未知错误
#define kUnknownApiErrCode                  (-10000)
    //接口响应中status正确值(即未出错时)
#define kApiResponseOk                      (200)
#define kRequestTimeOut                     (60)

typedef void (^apiResponseSimpleCompleteBlock)(BOOL isSuccess, NSError *err);
typedef void (^apiResponseWithSimpleArrCompleteBlock)(BOOL isSuccess, NSArray *dataArr, NSError *err);
typedef void (^apiResponseWithArrCompleteBlock)(BOOL isSuccess, NSArray *dataArr, int totalPage, int totalCount, NSError *err);
typedef void (^apiResponseWithEntityCompleteBlock)(BOOL isSuccess, BaseEntity *entity, NSError *err);
typedef void (^apiResponseWithDictCompleteBlock)(BOOL isSuccess, NSDictionary *dict, NSError *err);



@interface NSError(Ext)
    /// 扩展属性
@property(nonatomic, strong) NSString *errMsg;

@end






@interface BaseDataControl : NSObject

@property(nonatomic, strong) NSString   *hostName;
@property(nonatomic, assign) int        portNum;
@property(nonatomic, assign) BOOL       isNeedSSL;
@property(nonatomic, assign) MKNKPostDataEncodingType defPostDataEncoding;

+ (MKNetworkEngine *)shareEngine;

+ (NSError *)errorWithApiErrorCode:(long)errCode errMsg:(NSString *)errMsg;

    ///如果子类也要使用, 则子类必须实现该方法, 默认返回nil
+ (instancetype)shareDataControl;

- (void)getApiWithPath:(NSString *)path params:(NSDictionary *)params completeBlock:(void (^)(BOOL isSuccess, MKNetworkOperation *operation, NSError *err))completeBlock;

- (void)postApiWithPath:(NSString *)path params:(NSDictionary *)params completeBlock:(void (^)(BOOL isSuccess, MKNetworkOperation *operation, NSError *err))completeBlock;

    /// 直接给出postDataEncoding
- (void)postApiWithPath:(NSString *)path params:(NSDictionary *)params postDataEncoding:(MKNKPostDataEncodingType)postDataEncoding completeBlock:(void (^)(BOOL isSuccess, MKNetworkOperation *operation, NSError *err))completeBlock;

- (void)postApiWithPath:(NSString *)path params:(NSDictionary *)params files:(NSDictionary *)files completeBlock:(void (^)(BOOL isSuccess, MKNetworkOperation *operation, NSError *err))completeBlock;

+ (void)cancelOperationsContainingURLString:(NSString *)url;

+ (void)cancelAllRequest;

+ (NSMutableDictionary *)appendDefaultPars:(NSDictionary *)pars;

- (NSMutableDictionary *)defaultPars:(NSDictionary *)pars;

- (void)cancelOperation;

- (NSDictionary *)defaultHeaders;
    /// 判断当前请求返回的Response是否成功, 子类可以重写
- (BOOL)judgeResponseIsSuccess:(NSError **)err operation:(MKNetworkOperation *)completedOperation;

@end






