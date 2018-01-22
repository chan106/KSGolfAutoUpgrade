//
//  JCWebDataRequst.h
//  Zebra
//
//  Created by Guo.JC on 2016/12/29.
//  Copyright © 2016年 奥赛龙科技. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "WebRequestStateEnum.h"

//@class DTUser;
//@class DTSwing;
//@class DTSession;
@class AFNetworkReachabilityManager;

typedef void(^webRequestComplete)(id obj);
typedef void(^isExistComplete)(BOOL isExist);
typedef void(^resultCallBack)(BOOL result, id reason);
typedef void(^webRequestCallBack)(WebRespondType respondType, id result);

@interface JCWebDataRequst : NSObject

+ (AFNetworkReachabilityManager *)shareNetworkReachability;

/*!
 *  @brief                   同步用户本地数据
 *
 *  @param user              用户
 *  @param complete          上传结果回调
 */
+ (void)sysSwingDataComplete:(void(^)(BOOL result, NSError *error))completion;

/*!
 *  @brief                   上传挥杆数据
 *
 *  @param swing             挥杆数据
 *  @param complete          上传结果回调
 */
//+ (void)uploadSwing:(DTSwing *)swing
//          toSession:(DTSession *)session
//           complete:(void(^)(BOOL result, NSError *error))completion;

/*!
 *  @brief                   上传一场挥杆数据
 *
 *  @param session           一场数据
 *  @param user              用户
 *  @param complete          上传结果回调
 */
//+ (void)uploadSession:(DTSession *)session
//               toUser:(DTUser *)user
//             complete:(void(^)(BOOL result, NSError *error))completion;

/*!
 *  @brief                   下载运动数据
 *
 */
//+ (void)downUserSportData:(DTUser *)user
//                 complete:(void(^)(BOOL result, NSError *error))completion;

/*!
 *  @brief                   下载多个月运动数据
 *
 */
//+ (void)downUserSportData:(DTUser *)user
//                mouthList:(NSArray *)list
//                 complete:(void(^)(BOOL result, NSError *error))completion;

/*!
 *  @brief                   历史记录统计数据
 *
 */
//+ (void)getStatisticsData:(DTUser *)user
//                 complete:(void(^)(BOOL result, NSError *error))completion;

/*!
 *  @brief                   折线表图数据
 *
 */
//+ (void)getChartData:(DTUser *)user
//           chartType:(ChartDataType)type
//            complete:(void(^)(BOOL result, id obj))completion;


#pragma mark     ------------------------------------
#pragma mark ----------------登录注册---------------------
#pragma mark     ------------------------------------
/*!
 *  @brief                   注册用户
 *
 *  @param user              需要注册的用户
 */
//+ (void)registerWithUser:(DTUser *)user
//                complete:(void(^)(BOOL result, id obj))complete;

/*!
 *  @brief                   账号登录
 *
 *  @param params            登录参数
 */
//+ (void)accountLoginWithParams:(NSDictionary *)params
//                      complete:(void(^)(DTUser *user, NSError *error))completion;

/*!
 *  @brief                   密码确认
 *
 *  @param user              需要确认的用户
 */
//+ (void)affirmPassWordWithUser:(DTUser *)user
//                      passWord:(NSString *)passWord
//                      complete:(void (^)(BOOL, NSError *))completion;

/*!
 *  @brief                   修改密码
 *
 *  @param user              需要修改的用户
 */
//+ (void)changePassWordWithUser:(DTUser *)user
//                      passWord:(NSString *)passWord
//                      complete:(void (^)(BOOL, NSError *))completion;

/*!
 *  @brief                   下载固件包
 *
 *  @param oemtype           设备oemtype
 *  @param isZIP             是否压缩
 *  @param progress          下载进度
 *  @param completion        下载回调
 */
+ (void)uploadFirwareWithOemtype:(NSString *)oemtype
                   isCompressZIP:(BOOL)isZIP
                 downLoadProress:(void (^)(float progress))progress
                        complete:(void (^)(NSArray *, NSError *))completion;

@end
