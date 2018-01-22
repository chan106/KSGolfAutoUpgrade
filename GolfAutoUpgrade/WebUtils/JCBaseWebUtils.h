//
//  JCBaseWebUtils.h
//  Zebra
//
//  Created by 奥赛龙-Guo.JC on 2016/11/11.
//  Copyright © 2016年 奥赛龙科技. All rights reserved.
//


#import <Foundation/Foundation.h>
@class AFHTTPSessionManager;


//此行为调试阶段的打印输出，上架时直接注释下行即可关闭项目中所有NSLog打印
#define         DEBUG_LOG               1

#ifdef DEBUG_LOG
#define     JCLog(...) NSLog(@"%s 第%d行 \n %@\n\n",__func__,__LINE__,[NSString stringWithFormat:__VA_ARGS__])
#else
#define     JCLog(...)
#endif


typedef void (^BaseRequestCallback)(BOOL requestState, id obj);

@interface JCBaseWebUtils : NSObject

+ (AFHTTPSessionManager *)shareManager;
#pragma mark GET请求
+(void)get:(NSString *)path andParams:(id)params andCallback:(BaseRequestCallback)callback;

#pragma mark POST请求
+(void)post:(NSString *)path andParams:(id)params andCallback:(BaseRequestCallback)callback;

/*
#pragma mark 上传图片
+(void)uploadImage:(NSString *)path andParams:(NSDictionary *)params andCallback:(MyCallback)callback;

#pragma mark 问题反馈
+(void)feedBack:(NSString *)path andParams:(NSDictionary *)params andCallback:(MyCallback)callback;

#pragma mark 上传多张图片
+ (void)uploadMostImageWithURLString:(NSString *)URLString
                          parameters:(id)parameters
                         uploadDatas:(NSArray *)uploadDatas
                          uploadName:(NSString *)uploadName
                             success:(void (^)())success
                             failure:(void (^)(NSError *))failure;
*/
@end
