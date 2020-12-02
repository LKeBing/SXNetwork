//
//  SXNetwork.h
//  SXT
//
//  Created by KB on 2018/4/11.
//  Copyright © 2018年 KeBing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SXNetworkConfiguration.h"
#import "AFNetworking.h"

typedef void(^RequestResultHandler)(NSInteger code, id data, NSString *message);
typedef void(^RequestSuccessHandler)(id data);
typedef void(^RequestFailedHandler)(NSString *message);

@interface SXNetwork : NSObject

+ ( instancetype ) shareInstance;

- (void)createSessionManager;

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@property (nonatomic, copy)NSString *token;
@property (nonatomic, copy)NSString *refreshToken;
@property (nonatomic, assign)NSTimeInterval timeoutInterval;







- (void)postRequestWithCommand:(NSString *)url
                        params:(NSDictionary *)params
                 resultHandler:(RequestResultHandler)resultHandler;

- (void)getRequestWithCommand:(NSString *)url
                       params:(NSDictionary *)params
                resultHandler:(RequestResultHandler)resultHandler;





- (void)postRequestWithCommand:(NSString *)url
                        params:(NSDictionary *)params
                       success:(RequestSuccessHandler)successBlock
                         error:(RequestFailedHandler)errorBlock;

- (void)postRequestByAppendingQuery:(NSString *)url
                             params:(NSDictionary *)params
                            success:(RequestSuccessHandler)successBlock
                              error:(RequestFailedHandler)errorBlock;

- (void)getRequestWithCommand:(NSString *)url
                       params:(NSDictionary *)params
                      success:(RequestSuccessHandler)successBlock
                        error:(RequestFailedHandler)errorBlock;

- (void)deleteRequestWithCommand:(NSString *)command
                          params:(id)params
                         success:(RequestSuccessHandler)successBlock
                           error:(RequestFailedHandler)errorBlock;

- (void)putRequestWithCommand:(NSString *)url
                       params:(NSDictionary *)params
                      success:(RequestSuccessHandler)successBlock
                        error:(RequestFailedHandler)errorBlock;

- (void)putRequestByAppendingQuery:(NSString *)url
                            params:(NSDictionary *)params
                           success:(RequestSuccessHandler)successBlock
                             error:(RequestFailedHandler)errorBlock;

- (void)deleteRequestByAppendingQuery:(NSString *)url
                               params:(NSDictionary *)params
                              success:(RequestSuccessHandler)successBlock
                                error:(RequestFailedHandler)errorBlock;
@end
