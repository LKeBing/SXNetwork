//
//  NetworkConfiguration.h
//  SXT
//
//  Created by KB on 2018/4/9.
//  Copyright © 2018年 KeBing. All rights reserved.
//

#ifndef NetworkConfiguration_h
#define NetworkConfiguration_h


static NSString * const BaseUrlKey = @"BaseUrlKey";
static NSString * const BaseHtmlUrlKey = @"BaseHtmlUrlKey";

#define CurrentBaseUrl          [[NSUserDefaults standardUserDefaults] stringForKey:BaseUrlKey]
#define CurrentBaseHtmlUrl      [[NSUserDefaults standardUserDefaults] stringForKey:BaseHtmlUrlKey]


static NSString * const SXTokenKey = @"SXTokenKey";
static NSString * const SXRefreshTokenKey = @"SXRefreshTokenKey";
static NSString * const SXLastRefreshTime = @"SXLastRefreshTime";



static NSInteger const SXRET_OK = 200;
static NSInteger const SXTokenSecretError = 8061400;
static NSInteger const SXTokenError     = 8061402;//token错误
static NSInteger const SXTokenOverdue   = 8502;//token过期
static NSInteger const SXTokenLost      = 8500;//token丢失
static NSInteger const SXErrorUnkown    = 5555;//未知错误
static NSInteger const SXTokenInvalid   = 8505;// token invalid
static NSInteger const SXNoChildError   = 801001;//家长无孩子
static NSInteger const SXChildListInvalid   = 801003;//孩子列表已失效
static NSInteger const SXPCLoginQRCodeInvalid   = 8072420;//pc端扫码登录的二维码已经失效


static NSString * const ShouldLoginMessage = @"登录失效，请重新登录";
static NSString * const ShouldLoginNotification = @"ShouldLoginNotification";

static NSInteger const SXAPPLoginOnOtherDevice   = 204;// 

static NSString * const SXTokenRefreshedNotification = @"SXTokenRefreshedNotification";

// 网络请求超时时间
static NSTimeInterval const NetworkTimeoutInterval = 15.f;

static NSString * const HTTPHeaderFieldKey = @"HTTPHeaderField";


static NSString * const NetworkErrorMessage = @"网络异常，请稍后再试";
static NSString * const UnkownErrorMessage = @"请求出错啦，请稍后再试";

#endif /* NetworkConfiguration_h */
