//
//  BaseDataControl.m
//  GeLongPro
//
//  Created by willonboy on 15/6/24.
//  Copyright (c) 2015年 com.willonboy. All rights reserved.
//

#import "BaseDataControl.h"


@implementation NSError(Ext)

- (void)setErrMsg:(NSString *)msg
{
    objc_setAssociatedObject(self, "errMsg", msg, OBJC_ASSOCIATION_RETAIN);
}

- (NSString *)errMsg
{
    return objc_getAssociatedObject(self, "errMsg");
}

- (NSString *)localizedDescription
{
#ifdef DEBUG
    return self.errMsg ? self.errMsg : [NSString stringWithFormat:@"未知错误, 错误码%ld, 原始错误信息:\n%@\n", (long)self.code, [self.userInfo objectForKey:NSLocalizedDescriptionKey]];
#else
    return self.errMsg ? self.errMsg : [NSString stringWithFormat:@"未知错误, 错误码%ld", (long)self.code];
#endif
}

@end



@implementation BaseDataControl
static MKNetworkEngine *_shareInstanceEngine = nil;

+ (MKNetworkEngine *)shareEngine
{
    if (!_shareInstanceEngine)
    {
        _shareInstanceEngine = [[MKNetworkEngine alloc] init];
    }
    return _shareInstanceEngine;
}

+ (NSError *)errorWithApiErrorCode:(long)errCode errMsg:(NSString *)errMsg
{
        //这里最好是读取一个配置文件(json格式{"404":"服务错误"}), 根据errCode找对应的错误提示信息
    switch (errCode)
    {
        case 504:
            errMsg = @"网络连接失败, 服务器出问题了(504)";
            break;
        case 306:
            errMsg = @"网络连接失败, 服务器出问题了(306)";
            break;
        case -1009:
            errMsg = @"网络连接失败, 请检查您的网络. 如是否设置了代理等";
            break;
        case -1001:
            errMsg = @"网络请求超时(-1001)";
            break;
        case -1004:
            errMsg = @"未能连接到服务器(-1004)";
            break;
        case 400:
        case 404:
            errMsg = @"http错误";
            break;
        case 500:
            errMsg = @"服务器出现错误(http status code 500)";
            break;
        default:
            break;
    }
    
    NSError *err = [NSError errorWithDomain:@"com.willonboy.err" code:errCode userInfo:nil];
    err.errMsg = errMsg;
    return err;
}


    ///如果子类也要使用, 则子类必须实现该方法
+ (instancetype)shareDataControl
{
    return nil;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        NSString *baseUrl = kApiBaseUrl;
        if (kIsEnterpriseBuild)
        {
            baseUrl = kApiBaseUrlEnter;
        }
        self.hostName   = baseUrl;
        self.portNum    = 0;
        self.isNeedSSL  = NO;
            /// 设置默认post encoding
        self.defPostDataEncoding = MKNKPostDataEncodingTypeJSON;
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"cancelOperation by dealloc %@", [NSString stringWithFormat:@"%@", self]);
    [self cancelOperation];
}

- (void)cancelOperation
{
    NSLog(@"cancelOperation %@", [NSString stringWithFormat:@"%@", self]);
    [MKNetworkEngine cancelOperationsContainingURLString:[NSString stringWithFormat:@"%@", self]];
}

- (void)getApiWithPath:(NSString *)path params:(NSDictionary *)params completeBlock:(void (^)(BOOL isSuccess, MKNetworkOperation *operation, NSError *err))completeBlock
{
    [self makeRequestOperation:path params:params files:nil httpMethod:@"GET" networkEngine:nil postDataEncoding:self.defPostDataEncoding completeBlock:completeBlock];
}

- (void)postApiWithPath:(NSString *)path params:(NSDictionary *)params completeBlock:(void (^)(BOOL isSuccess, MKNetworkOperation *operation, NSError *err))completeBlock
{
    [self makeRequestOperation:path params:params files:nil httpMethod:@"POST" networkEngine:nil postDataEncoding:self.defPostDataEncoding completeBlock:completeBlock];
}

    /// 直接给出postDataEncoding
- (void)postApiWithPath:(NSString *)path params:(NSDictionary *)params postDataEncoding:(MKNKPostDataEncodingType)postDataEncoding completeBlock:(void (^)(BOOL isSuccess, MKNetworkOperation *operation, NSError *err))completeBlock
{
    [self makeRequestOperation:path params:params files:nil httpMethod:@"POST" networkEngine:nil postDataEncoding:postDataEncoding completeBlock:completeBlock];
}

- (void)postApiWithPath:(NSString *)path params:(NSDictionary *)params files:(NSDictionary *)files completeBlock:(void (^)(BOOL isSuccess, MKNetworkOperation *operation, NSError *err))completeBlock
{
    [self makeRequestOperation:path params:params files:files httpMethod:@"POST" networkEngine:nil postDataEncoding:self.defPostDataEncoding completeBlock:completeBlock];
}

- (void)makeRequestOperation:(NSString *)path params:(NSDictionary *)params files:(NSDictionary *)files httpMethod:(NSString *)method networkEngine:(MKNetworkEngine *)netEngine postDataEncoding:(MKNKPostDataEncodingType)postDataEncoding completeBlock:(void (^)(BOOL isSuccess, MKNetworkOperation *operation, NSError *err))completeBlock
{
    [self makeRequestOperationWithHost:self.hostName portNum:self.portNum apiPath:path ssl:self.isNeedSSL params:params files:files httpMethod:method networkEngine:netEngine postDataEncoding:postDataEncoding completeBlock:completeBlock];
}

- (void)makeRequestOperationWithHost:(NSString *)hostName portNum:(int)portNum apiPath:(NSString *)path
                                 ssl:(BOOL)ssl params:(NSDictionary *)params files:(NSDictionary *)files
                          httpMethod:(NSString *)method networkEngine:(MKNetworkEngine *)netEngine
                    postDataEncoding:(MKNKPostDataEncodingType)postDataEncoding completeBlock:(void (^)(BOOL isSuccess, MKNetworkOperation *operation, NSError *err))completeBlock
{
    method = method ? method : @"GET";
    MKNetworkEngine *networkEngine = netEngine ? netEngine : [[self class] shareEngine];
    NSMutableDictionary *conbinePars = [NSMutableDictionary dictionary];
    if ([params count])
    {
        [conbinePars addEntriesFromDictionary:params];
    }
    
    MKNetworkOperation *operation = [networkEngine operationWithHost:hostName portNum:portNum apiPath:path params:conbinePars httpMethod:method ssl:ssl];
    if (!operation)
    {
        mAlertView(nil, @"error code -1234567");
        return;
    }
        /// 添加自定义httphead
    [operation addHeaders:[self defaultHeaders]];
    ((NSMutableURLRequest *)operation.readonlyRequest).timeoutInterval = kRequestTimeOut;
    operation.postDataEncoding      = postDataEncoding;
    operation.operationIdentifier   = [NSString stringWithFormat:@"%@_%lf", self, [[NSDate date] timeIntervalSince1970]];
    
    if ([files count])
    {
        method = @"POST";
        for (NSString *key in files.allKeys)
        {
            if (params && [params count])
            {
                NSString *ext = [[files[key] pathExtension] lowercaseString];
                NSDictionary *mimeTypeDicts = @{@"jpg":@"image/jpg", @"jpeg":@"image/jpeg", @"png":@"image/png",
                                                @"m4a":@"audio/m4a", @"mp4":@"video/mp4"};
                NSString *mimeType = @"multipart/form-data";
                if (ext.length && [mimeTypeDicts.allKeys containsObject:ext])
                {
                    mimeType = mimeTypeDicts[ext];
                }
                [operation addFile:files[key] forKey:key mimeType:mimeType];
            }
            else
            {
                [operation addFile:files[key] forKey:key];
                    // setFreezable uploads your images after connection is restored!
                [operation setFreezable:YES];
            }
        }
    }

    operation.shouldNotCacheResponse = YES;
    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation){
        
        NSLog(@"REQUEST SUCCESS %@", completedOperation);
            //所有接口返回的错误都将会在这里被处理, 转化成相应的NSError并返回给调用方, 以便提示
        NSError *err = nil;
        BOOL isSuccess = [self judgeResponseIsSuccess:&err operation:completedOperation];
        
        if (completeBlock)
        {
            completeBlock(isSuccess, completedOperation, err);
        }
    }
    errorHandler:^(MKNetworkOperation *completedOperation, NSError *error){
        
        NSError *err = [[self class] errorWithApiErrorCode:error.code errMsg:error.localizedDescription];
        if (completeBlock)
        {
            completeBlock(NO, completedOperation, err);
        }
    }];
    [networkEngine enqueueOperation:operation];
}


+ (void)cancelOperationsContainingURLString:(NSString *)url
{
    [MKNetworkEngine cancelOperationsContainingURLString:url];
}


+ (void)cancelAllRequest
{
    NSString *baseUrl = kApiBaseUrl;
    if (kIsEnterpriseBuild)
    {
        baseUrl = kApiBaseUrl;
    }
    [MKNetworkEngine cancelOperationsContainingURLString:baseUrl];
}

+ (NSMutableDictionary *)appendDefaultPars:(NSDictionary *)pars
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    if (pars && [pars isKindOfClass:[NSDictionary class]])
    {
        [params addEntriesFromDictionary:pars];
    }
    return params;
}

- (NSMutableDictionary *)defaultPars:(NSDictionary *)pars
{
    return [[self class] appendDefaultPars:pars];
}

- (NSDictionary *)defaultHeaders
{
    return @{@"FromApp":@"true"};
}

    /// 判断当前请求返回的Response是否成功, 子类可以重写
- (BOOL)judgeResponseIsSuccess:(NSError **)err operation:(MKNetworkOperation *)completedOperation;
{
        //所有接口返回的错误都将会在这里被处理, 转化成相应的NSError并返回给调用方, 以便提示
    BOOL isSuccess = YES;
    NSDictionary *respDict = completedOperation.responseJSON;
    if (completedOperation.HTTPStatusCode != 200)
    {
        *err = [[self class] errorWithApiErrorCode:completedOperation.HTTPStatusCode errMsg:[NSString stringWithFormat:@"http请求错误, 错误码%ld", (long)completedOperation.HTTPStatusCode]];
        isSuccess = NO;
    }
    else if (![respDict isKindOfClass:[NSDictionary class]])
    {
            //ERROR CODE :-10000未知错误
        *err = [[self class] errorWithApiErrorCode:kUnknownApiErrCode errMsg:@"未知错误"];
        isSuccess = NO;
    }
    else
    {
        int errCode         = [[respDict safeBindStringValue:@"statusCode"] intValue];
        NSString *errMsg    = [respDict safeBindStringValue:@"message"];
        if (errCode != kApiResponseOk)
        {
            *err             = [[self class] errorWithApiErrorCode:errCode errMsg:errMsg];
            isSuccess       = NO;
        }
    }
    return isSuccess;
}


@end
