//
//  SXNetwork.m
//  SXT
//
//  Created by KB on 2018/4/11.
//  Copyright © 2018年 KeBing. All rights reserved.
//

#import "SXNetwork.h"

@interface SXNetwork ()
@property (nonatomic) dispatch_semaphore_t semaphore;
@end

@implementation SXNetwork

@synthesize token = _token;
@synthesize refreshToken = _refreshToken;
@synthesize timeoutInterval = _timeoutInterval;

+ (instancetype)shareInstance {
    static SXNetwork * instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}
- (instancetype)init {
    if(self = [super init]) {
        self.semaphore = dispatch_semaphore_create(1);
        [self createSessionManager];
    }
    return self;
}
- (void)createSessionManager {
    self.sessionManager = [self sessionWithTimeoutInterval:NetworkTimeoutInterval];
    
    [self setupHTTPHeaderField];
}
- (AFHTTPSessionManager *)sessionWithTimeoutInterval:(NSTimeInterval)timeInterval {
    AFHTTPSessionManager *session= [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:CurrentBaseUrl]];
    
    AFJSONRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
    [requestSerializer setValue:@"zh-cn,zh;q=0.5" forHTTPHeaderField:@"Accept-Language"];
    [requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [requestSerializer setTimeoutInterval:timeInterval];
    [session setRequestSerializer:requestSerializer];
    
    AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializer];
    [responseSerializer setRemovesKeysWithNullValues:YES];
    [responseSerializer setAcceptableContentTypes:[NSSet setWithObjects:@"text/html",@"application/json", @"text/json", @"text/javascript",@"text/plain",nil]];
    [session setResponseSerializer:responseSerializer];
    
    return session;
}
- (void)setupHTTPHeaderField {
    NSDictionary *dic = [[NSUserDefaults standardUserDefaults] dictionaryForKey:HTTPHeaderFieldKey];
    if (dic && dic.count>0) {
        [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [self.sessionManager.requestSerializer setValue:obj forHTTPHeaderField:key];
        }];
    }
}


- (NSString *)token {
    if (_token == nil) {
        _token = [[NSUserDefaults standardUserDefaults] objectForKey:SXTokenKey];
    }
    return _token;
}
- (void)setToken:(NSString *)token {
    _token = token;
    if(token) {
        [self.sessionManager.requestSerializer setValue:token forHTTPHeaderField:@"token"];
    } else {
        [self.sessionManager.requestSerializer setValue:nil forHTTPHeaderField:@"token"];
    }
}
- (NSString *)refreshToken {
    if (_refreshToken == nil) {
        _refreshToken = [[NSUserDefaults standardUserDefaults] objectForKey:SXRefreshTokenKey];
    }
    return _refreshToken;
}
- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval {
    _timeoutInterval = timeoutInterval;
    [self.sessionManager.requestSerializer setTimeoutInterval:timeoutInterval];
}

- (NSString *)uuidString{
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef strUuid = CFUUIDCreateString(kCFAllocatorDefault,uuid);
    NSString * str = [NSString stringWithString:(__bridge NSString *)strUuid];
    CFRelease(strUuid);
    CFRelease(uuid);
    return  str;
}
- (void)setRequestId {
    NSString *traceId = [self uuidString];
    [self.sessionManager.requestSerializer setValue:traceId forHTTPHeaderField:@"Trace-Id"];
}







- (void)postRequestWithCommand:(NSString *)url params:(NSDictionary *)params resultHandler:(RequestResultHandler)resultHandler {
    NSString *holdToken = [self.token copy];
    [self setRequestId];
    [self.sessionManager POST:url parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self checkTokenOverdue:responseObject holdToken:holdToken completion:^(BOOL refreshedToken) {
            if (refreshedToken) {
                [self postRequestWithCommand:url params:params resultHandler:resultHandler];
            } else {
                [self printRequest:url params:params result:responseObject];
                [self dealResult:responseObject resultHandler:resultHandler];
            }
        }];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self printRequest:url params:params result:error];
        [self dealResult:error resultHandler:resultHandler];
    }];
}
- (void)getRequestWithCommand:(NSString *)url params:(NSDictionary *)params resultHandler:(RequestResultHandler)resultHandler {
    NSString *holdToken = [self.token copy];
    [self setRequestId];
    [self.sessionManager GET:url parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self checkTokenOverdue:responseObject holdToken:holdToken completion:^(BOOL refreshedToken) {
            if (refreshedToken) {
                [self getRequestWithCommand:url params:params resultHandler:resultHandler];
            } else {
                [self printRequest:url params:params result:responseObject];
                [self dealResult:responseObject resultHandler:resultHandler];
            }
        }];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self printRequest:url params:params result:error];
        [self dealResult:error resultHandler:resultHandler];
    }];
}
- (void)postRequestWithCommand:(NSString *)url params:(NSDictionary *)params success:(RequestSuccessHandler)successBlock error:(RequestFailedHandler)errorBlock {
    NSString *holdToken = [self.token copy];
    [self setRequestId];
    [self.sessionManager POST:url parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self checkTokenOverdue:responseObject holdToken:holdToken completion:^(BOOL refreshedToken) {
            if (refreshedToken) {
                [self postRequestWithCommand:url params:params success:successBlock error:errorBlock];
            } else {
                [self printRequest:url params:params result:responseObject];
                [self dealResult:responseObject success:successBlock error:errorBlock];
            }
        }];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self printRequest:url params:params result:error];
        [self dealResult:error success:successBlock error:errorBlock];
    }];
}
- (void)putRequestByAppendingQuery:(NSString *)url params:(NSDictionary *)params success:(RequestSuccessHandler)successBlock error:(RequestFailedHandler)errorBlock {
    
    if (params.count) {
        url = [self appendingParams:params toUrl:url];
    }
    
    NSString *holdToken = [self.token copy];
    [self setRequestId];
    [self.sessionManager PUT:url parameters:params headers:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self checkTokenOverdue:responseObject holdToken:holdToken completion:^(BOOL refreshedToken) {
            if (refreshedToken) {
                [self putRequestByAppendingQuery:url params:params success:successBlock error:errorBlock];
            } else {
                [self printRequest:url params:params result:responseObject];
                [self dealResult:responseObject success:successBlock error:errorBlock];
            }
        }];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self printRequest:url params:params result:error];
        [self dealResult:error success:successBlock error:errorBlock];
    }];
}
- (void)deleteRequestByAppendingQuery:(NSString *)url params:(NSDictionary *)params success:(RequestSuccessHandler)successBlock error:(RequestFailedHandler)errorBlock {
    
    if (params.count) {
        url = [self appendingParams:params toUrl:url];
    }
    
    NSString *holdToken = [self.token copy];
    [self setRequestId];
    [self.sessionManager DELETE:url parameters:nil headers:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self checkTokenOverdue:responseObject holdToken:holdToken completion:^(BOOL refreshedToken) {
            if (refreshedToken) {
                [self deleteRequestByAppendingQuery:url params:nil success:successBlock error:errorBlock];
            } else {
                [self printRequest:url params:params result:responseObject];
                [self dealResult:responseObject success:successBlock error:errorBlock];
            }
        }];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self printRequest:url params:params result:error];
        [self dealResult:error success:successBlock error:errorBlock];
    }];
}
- (void)putRequestWithCommand:(NSString *)url params:(NSDictionary *)params success:(RequestSuccessHandler)successBlock error:(RequestFailedHandler)errorBlock {
    NSString *holdToken = [self.token copy];
    [self setRequestId];
    [self.sessionManager PUT:url parameters:params headers:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self checkTokenOverdue:responseObject holdToken:holdToken completion:^(BOOL refreshedToken) {
            if (refreshedToken) {
                [self putRequestWithCommand:url params:params success:successBlock error:errorBlock];
            } else {
                [self printRequest:url params:params result:responseObject];
                [self dealResult:responseObject success:successBlock error:errorBlock];
            }
        }];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self printRequest:url params:params result:error];
        [self dealResult:error success:successBlock error:errorBlock];
    }];
}
- (void)getRequestWithCommand:(NSString *)url params:(NSDictionary *)params success:(RequestSuccessHandler)successBlock error:(void (^)(NSString *))errorBlock {
    
    if (params.count) {
        url = [self appendingParams:params toUrl:url];
    }
    
    NSString *holdToken = [self.token copy];
    [self setRequestId];
    [self.sessionManager GET:url parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self checkTokenOverdue:responseObject holdToken:holdToken completion:^(BOOL refreshedToken) {
            if (refreshedToken) {
                [self getRequestWithCommand:url params:nil success:successBlock error:errorBlock];
            } else {
                [self printRequest:url params:params result:responseObject];
                [self dealResult:responseObject success:successBlock error:errorBlock];
            }
        }];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self printRequest:url params:params result:error];
        [self dealResult:error success:successBlock error:errorBlock];
    }];
}
- (void)deleteRequestWithCommand:(NSString *)command params:(id)params success:(RequestSuccessHandler)successBlock error:(void (^)(NSString *))errorBlock {
    NSString *holdToken = [self.token copy];
    [self setRequestId];
    self.sessionManager.requestSerializer.HTTPMethodsEncodingParametersInURI = [NSSet setWithObjects:@"GET", @"HEAD", nil];
    [self.sessionManager DELETE:command parameters:params headers:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self checkTokenOverdue:responseObject holdToken:holdToken completion:^(BOOL refreshedToken) {
            if (refreshedToken) {
                [self deleteRequestWithCommand:command params:params success:successBlock error:errorBlock];
            } else {
                [self printRequest:command params:params result:responseObject];
                [self dealResult:responseObject success:successBlock error:errorBlock];
            }
        }];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self printRequest:command params:params result:error];
        [self dealResult:error success:successBlock error:errorBlock];
    }];
}
- (void)postRequestByAppendingQuery:(NSString *)url params:(NSDictionary *)params success:(RequestSuccessHandler)successBlock error:(RequestFailedHandler)errorBlock {
    
    if (params.count) {
        url = [self appendingParams:params toUrl:url];
    }
    
    NSString *holdToken = [self.token copy];
    [self setRequestId];
    [self.sessionManager POST:url parameters:params headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self checkTokenOverdue:responseObject holdToken:holdToken completion:^(BOOL refreshedToken) {
            if (refreshedToken) {
                [self postRequestByAppendingQuery:url params:nil success:successBlock error:errorBlock];
            } else {
                [self printRequest:url params:params result:responseObject];
                [self dealResult:responseObject success:successBlock error:errorBlock];
            }
        }];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self printRequest:url params:params result:error];
        [self dealResult:error success:successBlock error:errorBlock];
    }];
}








- (void)dealResult:(id)result success:(RequestSuccessHandler)successBlock error:(RequestFailedHandler)errorBlock {
    if (result==nil || [result isKindOfClass:[NSError class]]) {
        if (errorBlock) {
            errorBlock(NetworkErrorMessage);
        }
    } else {
        // 成功与否
        BOOL success = [result[@"success"] boolValue];
        // 状态码
        NSInteger code = [result[@"code"] integerValue];
        // 有用数据
        id data = result[@"data"];
        // message
        NSString *message = result[@"message"];
        
        if((code == SXRET_OK || code == 0) && success == YES) {
            if (successBlock) {
                successBlock(data);
            }
        } else {
            if (errorBlock) {
                errorBlock(message);
            }
        }
    }
}

- (void)dealResult:(id)result resultHandler:(RequestResultHandler)resultHandler {
    if (result==nil || [result isKindOfClass:[NSError class]]) {
        if (resultHandler) {
            resultHandler(0, nil, NetworkErrorMessage);
        }
    } else {
        // 状态码
        NSInteger code = [result[@"code"] integerValue];
        // 有用数据
        id data = result[@"data"];
        // message
        NSString *message = result[@"message"];
        
        if (resultHandler) {
            resultHandler(code, data, message);
        }
    }
}

- (void)printRequest:(NSString *)url params:(NSDictionary *)params result:(id)result {
    NSLog(@"\n请求地址:%@%@,\n参数：%@\n请求结果:responseObject:%@",self.sessionManager.baseURL,url,params,result);
}

- (NSString *)translateParams:(NSDictionary *)params {
    if (params.count) {
        __block NSInteger count = 0;
        NSMutableString *queryStr = [NSMutableString new];
        [params enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if (count >= 1) {
                [queryStr appendString:@"&"];
            }
            [queryStr appendFormat:@"%@=%@",key,obj];
            count ++;
        }];
        return queryStr;
    }
    return nil;
}

- (NSString *)appendingParams:(NSDictionary *)params toUrl:(NSString *)url {
    NSString *queryStr = [self translateParams:params];
    NSString *fullUrl = [url stringByAppendingFormat:@"?%@",queryStr];
    fullUrl = [fullUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    return fullUrl;
}







- (void)checkTokenOverdue:(id)responseObject holdToken:(NSString *)holdToken completion:(void(^)(BOOL refreshedToken))completion {
    if (!responseObject && completion) {
        completion(NO);
        return;
    }
    
    // 状态码
    NSInteger code = [responseObject[@"code"] integerValue];
    
    // token过期
    if (code == SXTokenOverdue) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // 信号
            dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20.f * NSEC_PER_SEC));
            dispatch_semaphore_wait(self.semaphore, time);// 等待信号量，如果20秒还没等到，就强行执行下面的操作
            
            // 查看该请求用的token是不是最新的，不是最新的叫他用最新的重新去请求试试
            NSString *currentToken = self.token;
            if (currentToken && ![holdToken isEqualToString:currentToken]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(YES);
                    dispatch_semaphore_signal(self.semaphore);// 释放信号量
                });
                return;
            }
            
            //去刷新token
            [self refreshTokenIfNeededWithCompletion:^(BOOL success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    dispatch_semaphore_signal(self.semaphore);// 释放信号量
                    if (success) {
                        completion(YES);
                    } else {
                        completion(NO);
                    }
                });
            }];
        });
    } else {
        completion(NO);
    }
}

// @(NO):重新登录   @(YES):重新请求接口    NSError:网络请求错误    NSData:接口报错
- (void)refreshTokenIfNeededWithCompletion:(void (^)(BOOL success))completion {
    
    NSString *refreshToken = self.refreshToken;
    if (!refreshToken) {// 缺失refreshToken,无法刷新token，只能退出重新登录
        completion?completion(NO):nil;
        return;
    }
    
    
    // 用refreshToken去获取新的token
    AFHTTPSessionManager *sessionManager = [self sessionWithTimeoutInterval:15];
    [sessionManager.requestSerializer setValue:refreshToken forHTTPHeaderField:@"token"];
    [sessionManager GET:@"/passport/api/auth/refresh_token" parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSLog(@"刷新token啦！！！\n请求结果:responseObject:%@",responseObject);
        
        if(!responseObject) {// 刷新token出现异常
            completion?completion(NO):nil;
            return;
        }
        
        // 状态码
        NSInteger code = [responseObject[@"code"] integerValue];
        // 有用数据
        id data = responseObject[@"data"];
        
        // 刷新成功
        if(code == SXRET_OK || code == 0) {
            
            if (![data isKindOfClass:[NSDictionary class]]) {// 返回数据异常
                completion?completion(NO):nil;
                return;
            }
            
            NSString *newToken = data[@"token"];
            
            // 获取到的新token没法用，还是要重新登录获取token咯
            if (!newToken) {
                completion?completion(NO):nil;
                return;
            }
            
            // 更新数据
            [self updateSomeDataWithToken:newToken];
            
            completion?completion(YES):nil;
        }
        // refreshToken没法使用，退出重新登录
        else if (code == SXTokenError || code == SXTokenOverdue || code == SXTokenSecretError || code == SXTokenLost || code == SXTokenInvalid) {
            // 清空refreshToken
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:SXRefreshTokenKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            completion?completion(NO):nil;
        }
        // 该账号已在其他设备登录
        else if (code == SXAPPLoginOnOtherDevice) {
            completion?completion(NO):nil;
        }
        // 接口报错
        else {
            completion?completion(NO):nil;
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        completion?completion(NO):nil;
    }];
}

- (void)updateSomeDataWithToken:(NSString *)token {
    // 刷新本地token
    [[NSUserDefaults standardUserDefaults] setObject:token forKey:SXTokenKey];
    self.token = token;
}

@end
