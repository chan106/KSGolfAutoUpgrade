//
//  JCWebDataRequst.m
//  Zebra
//
//  Created by Guo.JC on 2016/12/29.
//  Copyright © 2016年 奥赛龙科技. All rights reserved.
//

#import "JCWebDataRequst.h"
#import "JCBaseWebUtils.h"
//#import "DTUserStore.h"
#import "NSString+JCMD5Encryption.h"
#import "JCWebRequestConfig.h"
//#import "DTSwingStore.h"
//#import "NSDate+FormateString.h"
#import "AESCipher.h"
//#import "NSString+CheckIsString.h"
//#import "DTGolfStatisticStore.h"
#import <AFNetworking/AFNetworking.h>
//#import "DTSessionStore.h"
#import "DTError.h"
#import "SSZipArchive.h"

#define         AES_KEY        @"tkidvnhgfloiu678"

@implementation JCWebDataRequst


+ (AFNetworkReachabilityManager *)shareNetworkReachability{

    return [JCBaseWebUtils shareManager].reachabilityManager;
}

+ (BOOL)isNetWorking{
    if([JCBaseWebUtils shareManager].reachabilityManager.networkReachabilityStatus == AFNetworkReachabilityStatusReachableViaWWAN ||
       [JCBaseWebUtils shareManager].reachabilityManager.networkReachabilityStatus == AFNetworkReachabilityStatusReachableViaWiFi){
        return YES;
    }else{
        return NO;
    }
}

/*
//生成sign
+ (NSString *)creatSignWithAPI:(NSString *)api
                          user:(DTUser *)user
                     timeStamp:(NSString *)timeStamp {
    NSString *token = [AESCipher decryptAES:user.token key:AES_KEY];
    NSString *sign = [NSString stringWithFormat:@"%@&uid=%@&timestamp=%@&token=%@",api,[user.ID stringValue],timeStamp,token];
    sign = [sign stringToMD5];
    sign = [sign substringWithRange:NSMakeRange(2, 28)];
    sign = [sign stringToMD5];
    return sign;
}

//上传单次挥杆数据
+ (void)uploadSwing:(DTSwing *)swing
          toSession:(DTSession *)session
           complete:(void(^)(BOOL result, NSError *error))completion{
    
    if (![self isNetWorking]) {
        NSError *error = [NSError errorWithDomain:@"No Net!" code:-10086];
        completion(NO, error);
    }

    DTUser *user = [[DTUserStore sharedInstance] userByID:session.userID];
    
    NSString *path = [BaseAPI stringByAppendingString:UploadSwing];
    NSString *timeStamp = [[NSDate new] unixTimeStampWithDateStr];
    NSString *sign = [self creatSignWithAPI:UploadSwing user:user timeStamp:timeStamp];
    path = [NSString stringWithFormat:@"%@?uid=%@&timestamp=%@&sign=%@&lang=english",path,[user.ID stringValue],timeStamp,sign];
    
    NSError *error;
    NSString *swingTimeStamp = swing.timestamp;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy"];
    NSString *year = [dateFormatter stringFromDate:swing.created];
    [dateFormatter setDateFormat:@"MM"];
    NSString *mouth = [dateFormatter stringFromDate:swing.created];
    [dateFormatter setDateFormat:@"dd"];
    NSString *day = [dateFormatter stringFromDate:swing.created];
    
    NSCalendar*calendar = [NSCalendar currentCalendar];
    NSDateComponents *comps = [calendar components:NSCalendarUnitWeekOfYear fromDate:[NSDate date]];
    NSInteger week = [comps weekOfYear]; 
    
    NSDictionary *swingDic = @{  @"y": year,                                    //从本杆时间戳的（年）
                                 @"m": mouth,                                   //从本杆时间戳的（月）
                                 @"d": day,                                     //从本杆时间戳的（日）
                                 @"w": [NSString stringWithFormat:@"%ld",week], //从本杆时间戳的（本年的第几星期）
                                 @"ts": swingTimeStamp,                         //从本杆时间戳(timestamp)
                                 @"i": session.session.stringValue,             //第几场(inning)
                                 @"sc": swing.swingScore.stringValue,           //该杆的整体得分(score)
                                 
                                 @"ct": swing.topClub.stringValue,              //标面角 顶部角度(Club face angle Top)
                                 @"cd": swing.downswingClub.stringValue,        //标面角 底部角度(Club face angle Down)
                                 @"ci": swing.impactClub.stringValue,           //标面角 击球角度(Club face angle Impact)
                                 
                                 @"cts": swing.topClubScore.stringValue,        //标面角 顶部角度得分(club face angle top score)
                                 @"cds": swing.downswingClubScore.stringValue,  //标面角 底部角度得分(club face angle down score)
                                 @"cis": swing.impactClubScore.stringValue,     //标面角 击球角度得分(club face angle impact)
                                 @"cs": swing.clubScore.stringValue,            //标面角 各角度整体得分(club face angle  AVG score)
                                 
                                 @"wt": swing.topHip.stringValue,               //重力偏移 顶部角度(weight shift top)
                                 @"wd": swing.downswingHip.stringValue,         //重力偏移 底部角度(weight shift down)
                                 @"wi": swing.impactHip.stringValue,            //重力偏移 击球角度(weight shift impact)
                                 
                                 @"wts": swing.topHipScore.stringValue,         //重力偏移 顶部角度得分(weight shift top score)
                                 @"wds": swing.downswingHipScore.stringValue,   //重力偏移 底部角度得分(weight shift down score)
                                 @"wis": swing.impactHipScore.stringValue,      //重力偏移 击球角度得分(weight shift impact score)
                                 @"ws": swing.hipScore.stringValue              //重力偏移 各角度整得分(weight shift AVG score)
                                 };
    
    NSData *swingData = [NSJSONSerialization dataWithJSONObject:@[swingDic] options:NSJSONWritingPrettyPrinted error:&error];
    NSString *swingJSON = [[NSString alloc] initWithData:swingData encoding:NSUTF8StringEncoding];
    if (swingJSON == nil) {
        swingJSON = @"";
    }
    NSDictionary *params = @{@"detail":swingJSON};
    
    [JCBaseWebUtils post:path andParams:params andCallback:^(BOOL requestState, id obj) {
        if (requestState == YES) {
            if (!obj) {
                completion(NO,[NSError errorWithDomain:@"System error!" code:-101]);
                return ;
            }
            NSInteger ret = [obj[@"code"] integerValue];
            NSString *msg = obj[@"msg"];
            if (ret == WebRespondTypeSuccess && [msg isEqualToString:@"ok"]) {
                completion(YES, nil);
            }
            else if (ret == WebRespondTypeUnknowError){//重新登录
                [self refreshUserLogin:user complete:^(DTUser *refreshUser, NSError *refreshError) {
                    if (refreshUser) {
                        [self uploadSwing:swing toSession:session complete:completion];
                    }
                    else{
                        completion(NO, refreshError);
                    }
                }];
            }
            else{
                [self errorState:ret complete:completion];
            }
        }
        else{
            NSError *error = [NSError errorWithDomain:NET_ERROR code:-10086];
            completion(NO, error);
        }
    }];
}

//上传一场挥杆数据
+ (void)uploadSession:(DTSession *)session
               toUser:(DTUser *)user
             complete:(void(^)(BOOL result, NSError *error))completion{
    
    if (![self isNetWorking]) {
        NSError *error = [NSError errorWithDomain:@"No Net!" code:-10086];
        completion(NO, error);
    }
    
    NSString *path = [BaseAPI stringByAppendingString:UploadSwing];
    NSString *timeStamp = [[NSDate new]unixTimeStampWithDateStr];
    NSString *sign = [self creatSignWithAPI:UploadSwing user:user timeStamp:timeStamp];
    path = [NSString stringWithFormat:@"%@?uid=%@&timestamp=%@&sign=%@&lang=english",path,[user.ID stringValue],timeStamp,sign];
    
    NSArray *swings = [[DTSwingStore sharedInstance] swingsBySession:session];
    NSMutableArray *unsysSwings = [NSMutableArray array];
    for (DTSwing *swing in swings) {
        if (swing.synced == NO) {
            [unsysSwings addObject:swing];
        }
    }
    
    NSMutableArray *readySycSwings = [NSMutableArray array];
    for (DTSwing *swing in unsysSwings) {
        
        NSString *swingTimeStamp = swing.timestamp;
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy"];
        NSString *year = [dateFormatter stringFromDate:swing.created];
        [dateFormatter setDateFormat:@"MM"];
        NSString *mouth = [dateFormatter stringFromDate:swing.created];
        [dateFormatter setDateFormat:@"dd"];
        NSString *day = [dateFormatter stringFromDate:swing.created];
        
        NSCalendar*calendar = [NSCalendar currentCalendar];
        NSDateComponents *comps = [calendar components:NSCalendarUnitWeekOfYear fromDate:[NSDate date]];
        NSInteger week = [comps weekOfYear];
        
        NSDictionary *swingDic = @{  @"y": year,                                    //从本杆时间戳的（年）
                                     @"m": mouth,                                   //从本杆时间戳的（月）
                                     @"d": day,                                     //从本杆时间戳的（日）
                                     @"w": [NSString stringWithFormat:@"%ld",week], //从本杆时间戳的（本年的第几星期）
                                     @"ts": swingTimeStamp,                         //从本杆时间戳(timestamp)
                                     @"i": session.session.stringValue,             //第几场(inning)
                                     @"sc": swing.swingScore.stringValue,           //该杆的整体得分(score)
                                     
                                     @"ct": swing.topClub.stringValue,              //标面角 顶部角度(Club face angle Top)
                                     @"cd": swing.downswingClub.stringValue,        //标面角 底部角度(Club face angle Down)
                                     @"ci": swing.impactClub.stringValue,           //标面角 击球角度(Club face angle Impact)
                                     
                                     @"cts": swing.topClubScore.stringValue,        //标面角 顶部角度得分(club face angle top score)
                                     @"cds": swing.downswingClubScore.stringValue,  //标面角 底部角度得分(club face angle down score)
                                     @"cis": swing.impactClubScore.stringValue,     //标面角 击球角度得分(club face angle impact)
                                     @"cs": swing.clubScore.stringValue,            //标面角 各角度整体得分(club face angle  AVG score)
                                     
                                     @"wt": swing.topHip.stringValue,               //重力偏移 顶部角度(weight shift top)
                                     @"wd": swing.downswingHip.stringValue,         //重力偏移 底部角度(weight shift down)
                                     @"wi": swing.impactHip.stringValue,            //重力偏移 击球角度(weight shift impact)
                                     
                                     @"wts": swing.topHipScore.stringValue,         //重力偏移 顶部角度得分(weight shift top score)
                                     @"wds": swing.downswingHipScore.stringValue,   //重力偏移 底部角度得分(weight shift down score)
                                     @"wis": swing.impactHipScore.stringValue,      //重力偏移 击球角度得分(weight shift impact score)
                                     @"ws": swing.hipScore.stringValue              //重力偏移 各角度整得分(weight shift AVG score)
                                     };
        [readySycSwings addObject:swingDic];
    }
    
    NSError *error;
    NSData *swingData = [NSJSONSerialization dataWithJSONObject:readySycSwings options:NSJSONWritingPrettyPrinted error:&error];
    NSString *swingJSON = [[NSString alloc] initWithData:swingData encoding:NSUTF8StringEncoding];
    if (swingJSON == nil) {
        swingJSON = @"";
    }
    NSDictionary *params = @{@"detail":swingJSON};
    
    [JCBaseWebUtils post:path andParams:params andCallback:^(BOOL requestState, id obj) {
        if (requestState == YES) {
            if (!obj) {
                completion(NO,[NSError errorWithDomain:@"System error!" code:-101]);
                return ;
            }
            NSInteger ret = [obj[@"code"] integerValue];
            NSString *msg = obj[@"msg"];
            if (ret == WebRespondTypeSuccess && [msg isEqualToString:@"ok"]) {
                for (DTSwing *swing in unsysSwings) {
                    [[DTSwingStore sharedInstance] syncedSwingByID:swing.ID onCompletion:^(BOOL result, NSError *error) {
                        
                    }];
                }
                completion(YES, nil);
            }
            else if (ret == WebRespondTypeUnknowError){//重新登录
                [self refreshUserLogin:user complete:^(DTUser *refreshUser, NSError *refreshError) {
                    if (refreshUser) {
                        [self uploadSession:session toUser:refreshUser complete:completion];
                    }
                    else{
                        completion(NO, refreshError);
                    }
                }];
            }
            else{
                [self errorState:ret complete:completion];
            }
        }
        else{
            NSError *error = [NSError errorWithDomain:NET_ERROR code:-10086];
            completion(NO, error);
        }
    }];
}
//同步用户本地数据
+ (void)sysSwingDataComplete:(void(^)(BOOL result, NSError *error))completion{
    
    if (![self isNetWorking]) {
        NSError *error = [NSError errorWithDomain:@"No Net!" code:-10086];
        completion(NO, error);
    }
    
    NSArray *users = [[DTUserStore sharedInstance] allUsers];
    for (DTUser *user in users) {
        if ([user isDemoUser]) {
            return;
        }
        NSArray *unsysSessions  = [[DTSessionStore sharedInstance] unsyncedSessionsByUserID:user.ID];
        for (DTSession *session in unsysSessions) {
//            if (user.ID.integerValue == session.userID.integerValue) {
                [self uploadSession:session toUser:user complete:^(BOOL result, NSError *error) {
                    if (result) {
                        session.synced = YES;
                        [[DTSessionStore sharedInstance] saveSessionLocally:session];
                    }
                }];
//            }
        }
    }
}

//下载数据
+ (void)downUserSportData:(DTUser *)user
                complete :(void (^)(BOOL , NSError *))completion{
    
    if (![self isNetWorking]) {
        NSError *error = [NSError errorWithDomain:@"No Net!" code:-10086];
        completion(NO, error);
    }
    
    NSString *path = [BaseAPI stringByAppendingString:DownLoadSingleMouth];
    NSString *timeStamp = [[NSDate new] unixTimeStampWithDateStr];
    NSString *sign = [self creatSignWithAPI:DownLoadSingleMouth user:user timeStamp:timeStamp];
    path = [NSString stringWithFormat:@"%@?uid=%@&timestamp=%@&sign=%@&lang=english",path,[user.ID stringValue],timeStamp,sign];
    NSError *error;
    NSData *swingData = [NSJSONSerialization dataWithJSONObject:@[[[NSDate date] formateYearAndMonth]] options:NSJSONWritingPrettyPrinted error:&error];
    NSString *dateJSON = [[NSString alloc] initWithData:swingData encoding:NSUTF8StringEncoding];
    if (dateJSON == nil) {
        dateJSON = @"";
    }
    NSDictionary *params = @{@"month":[[NSDate date] formateYearAndMonth]};
    [JCBaseWebUtils post:path andParams:params andCallback:^(BOOL requestState, id obj) {
        if (requestState == YES) {
            if (!obj) {
                completion(NO,[NSError errorWithDomain:@"System error!" code:-101]);
                return ;
            }
            NSInteger ret = [obj[@"code"] integerValue];
            NSString *msg = obj[@"msg"];
            if (ret == WebRespondTypeSuccess && [msg isEqualToString:@"ok"]) {
                NSDictionary *dataDic = obj[@"data"];
                //将数据写入本地数据库
                [[DTSwingStore sharedInstance] importSwingDataDic:dataDic toUser:user completion:^(BOOL result, NSError *error) {
                    if (result) {
                        completion(YES, nil);
                    }
                    else if (error){
                        completion(NO, error);
                    }
                }];
            }
            else if (ret == WebRespondTypeUnknowError){//重新登录
                [self refreshUserLogin:user complete:^(DTUser *refreshUser, NSError *refreshError) {
                    if (refreshUser) {
                        [self downUserSportData:refreshUser complete:completion];
                    }
                    else{
                        completion(NO, refreshError);
                    }
                }];
            }
            else{
                [self errorState:ret complete:completion];
            }
        }
        else{
            NSError *error = [NSError errorWithDomain:NET_ERROR code:-10086];
            completion(NO, error);
        }
    }];
}

//下载多个月数据
+ (void)downUserSportData:(DTUser *)user mouthList:(NSArray *)list complete:(void (^)(BOOL, NSError *))completion{
    
    if (![self isNetWorking]) {
        NSError *error = [NSError errorWithDomain:@"No Net!" code:-10086];
        completion(NO, error);
    }
    
    NSString *path = [BaseAPI stringByAppendingString:DownLoadMultipleMouth];
    NSString *timeStamp = [[NSDate new] unixTimeStampWithDateStr];
    NSString *sign = [self creatSignWithAPI:DownLoadMultipleMouth user:user timeStamp:timeStamp];
    
    path = [NSString stringWithFormat:@"%@?uid=%@&timestamp=%@&sign=%@&lang=english",path,[user.ID stringValue],timeStamp,sign];
    NSError *error;
    NSData *swingData = [NSJSONSerialization dataWithJSONObject:list options:NSJSONWritingPrettyPrinted error:&error];
    NSString *listJSON = [[NSString alloc] initWithData:swingData encoding:NSUTF8StringEncoding];
    if (listJSON == nil) {
        listJSON = @"";
    }
    NSDictionary *params = @{@"monthlist":listJSON};
    
    [JCBaseWebUtils post:path andParams:params andCallback:^(BOOL requestState, id obj) {
        if (requestState == YES) {
            if (!obj) {
                completion(NO,[NSError errorWithDomain:@"System error!" code:-101]);
                return ;
            }
            NSInteger ret = [obj[@"code"] integerValue];
            NSString *msg = obj[@"msg"];
            if (ret == WebRespondTypeSuccess && [msg isEqualToString:@"ok"]) {
                [[DTSwingStore sharedInstance] importMultiSwingDataDic:obj toUser:user completion:^(BOOL result, NSError *error) {
                    
                }];
                completion(YES, nil);
            }
            else if (ret == WebRespondTypeUnknowError){//重新登录
                [self refreshUserLogin:user complete:^(DTUser *refreshUser, NSError *refreshError) {
                    if (refreshUser) {
                        [self downUserSportData:refreshUser mouthList:list complete:completion];
                    }
                    else{
                        completion(NO, refreshError);
                    }
                }];
            }
            else{
                [self errorState:ret complete:completion];
            }
        }
        else{
            NSError *error = [NSError errorWithDomain:NET_ERROR code:-10086];
            completion(NO, error);
        }
    }];
}

//统计数据
+ (void)getStatisticsData:(DTUser *)user complete:(void (^)(BOOL, NSError *))completion{
    
    if (![self isNetWorking]) {
        NSError *error = [NSError errorWithDomain:@"No Net!" code:-10086];
        completion(NO, error);
    }
    
    NSString *path = [BaseAPI stringByAppendingString:StaticsData];
    NSString *timeStamp = [[NSDate new] unixTimeStampWithDateStr];
    NSString *sign = [self creatSignWithAPI:StaticsData user:user timeStamp:timeStamp];
    path = [NSString stringWithFormat:@"%@?uid=%@&timestamp=%@&sign=%@&lang=english",path,[user.ID stringValue],timeStamp,sign];
    [JCBaseWebUtils post:path andParams:nil andCallback:^(BOOL requestState, id obj) {
        if (requestState == YES) {
            if (!obj) {
                completion(NO,[NSError errorWithDomain:@"System error!" code:-101]);
                return ;
            }
            NSInteger ret = [obj[@"code"] integerValue];
            NSString *msg = obj[@"msg"];
            if (ret == WebRespondTypeSuccess && [msg isEqualToString:@"ok"]) {
                NSDictionary *data = obj[@"data"];
                DTGolfStatistic *golfStatic = [[DTGolfStatisticStore sharedInstance] statisticWithUserID:user.ID];
                if (golfStatic == nil) {
                    golfStatic = [DTGolfStatistic new];
                }
                golfStatic.ID = golfStatic.userID = user.ID;
                golfStatic.allTimeSwings = @([[NSString checkIfNullWithString:data[@"alltime"]] integerValue]);
                golfStatic.yearToDateSwings = @([[NSString checkIfNullWithString:data[@"yeartime"]] integerValue]);
                golfStatic.lastDayScore = @([[NSString checkIfNullWithString:data[@"lastdayscore"]] floatValue]);
                
                golfStatic.highestDate = [NSDate formateYearMonthDayString:[NSString checkIfNullWithString:data[@"maxdaydate"]]];
                golfStatic.highestScore = @([[NSString checkIfNullWithString:data[@"maxdayscore"]] integerValue]);
                
                golfStatic.clubDate = [NSDate formateYearMonthDayString:[NSString checkIfNullWithString:data[@"cfadate"]]];
                golfStatic.clubScore = @([[NSString checkIfNullWithString:data[@"maxcfas"]] integerValue]);
                
                golfStatic.hipDate = [NSDate formateYearMonthDayString:[NSString checkIfNullWithString:data[@"wsdate"]]];
                golfStatic.hipScore = @([[NSString checkIfNullWithString:data[@"maxwss"]] integerValue]);
                
                NSError *savingError = nil;
                [[DTGolfStatisticStore sharedInstance] saveGolfStatistic:golfStatic outError:&savingError];
                if (savingError) {
                    completion(NO, savingError);
                }
                else{
                    completion(YES, nil);
                }
            }
            else if (ret == WebRespondTypeUnknowError){//重新登录
                [self refreshUserLogin:user complete:^(DTUser *refreshUser, NSError *refreshError) {
                    if (refreshUser) {
                        [self getStatisticsData:refreshUser complete:completion];
                    }
                    else{
                        completion(NO, refreshError);
                    }
                }];
            }
            else{
                [self errorState:ret complete:completion];
            }
        }
        else{
            NSError *error = [NSError errorWithDomain:NET_ERROR code:-10086];
            completion(NO, error);
        }
    }];
}

//折线图数据
+ (void)getChartData:(DTUser *)user chartType:(ChartDataType)type complete:(void (^)(BOOL, id ))completion{
    
    if (![self isNetWorking]) {
        NSError *error = [NSError errorWithDomain:@"No Net!" code:-10086];
        completion(NO, error);
    }

    NSString *api = nil;
    switch (type) {
        case ChartDataType4Week:
        {
            api = Chart4WeekData;
        }
            break;
        case ChartDataType6Mouth:
        {
            api = Chart6MouthData;
        }
            break;
        case ChartDataType12Mouth:
        {
            api = Chart12MouthData;
        }
            break;
            
        default:
            break;
    }
    NSString *path = [BaseAPI stringByAppendingString:api];
    NSString *timeStamp = [[NSDate new] unixTimeStampWithDateStr];
    NSString *sign = [self creatSignWithAPI:api user:user timeStamp:timeStamp];
    path = [NSString stringWithFormat:@"%@?uid=%@&timestamp=%@&sign=%@&lang=english",path,[user.ID stringValue],timeStamp,sign];
    [JCBaseWebUtils post:path andParams:nil andCallback:^(BOOL requestState, id obj) {
        if (requestState == YES) {
            if (!obj) {
                completion(NO,[NSError errorWithDomain:@"System error!" code:-101]);
                return ;
            }
            NSInteger ret = [obj[@"code"] integerValue];
            NSString *msg = obj[@"msg"];
            if (ret == WebRespondTypeSuccess && [msg isEqualToString:@"ok"]) {
                NSArray *datas = obj[@"data"];
                NSMutableArray *resultDatas = [NSMutableArray array];
                for (NSDictionary *dic in datas) {
                    
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateStyle:NSDateFormatterMediumStyle];
                    [formatter setTimeStyle:NSDateFormatterShortStyle];
                    [formatter setDateFormat:@"YYYY-MM-dd"];
                    NSTimeZone* timeZone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
                    [formatter setTimeZone:timeZone];
                    NSDate* date = [formatter dateFromString:type == ChartDataType4Week?dic[@"date"]:[dic[@"month"] stringByAppendingString:@"-15"]];

                    NSDictionary *data = @{@"time":[NSString stringWithFormat:@"%f",[date timeIntervalSince1970]],
                                           @"value":[NSString stringWithFormat:@"%ld",(NSInteger)([dic[@"scoreavg"] floatValue] * 100)]};
                    [resultDatas addObject:data];
                }
                NSOrderedSet *result = [NSOrderedSet orderedSetWithArray:resultDatas];
                completion(YES, result);
            }
            else if (ret == WebRespondTypeUnknowError){//重新登录
                [self refreshUserLogin:user complete:^(DTUser *refreshUser, NSError *refreshError) {
                    if (refreshUser) {
                        [self getChartData:refreshUser chartType:type complete:completion];
                    }
                    else{
                        completion(NO, refreshError);
                    }
                }];
            }
            else{
                [self errorState:ret complete:completion];
            }
        }
        else{
            NSError *error = [NSError errorWithDomain:NET_ERROR code:-10086];
            completion(NO, error);
        }
    }];
}

#pragma mark ----------------登录注册---------------------

//注册用户
+ (void)registerWithUser:(DTUser *)user
                complete:(void(^)(BOOL result, id obj))complete{
    
    if (![self isNetWorking]) {
        NSError *error = [NSError errorWithDomain:@"No Net!" code:-10086];
        complete(NO, error);
    }
    
    NSString *path = [BaseAPI stringByAppendingString:RegisterUser];
    DTGolfProfile *golfProfile = user.golfProfile;
    
    NSDictionary *params = @{@"firstname":user.firstName,
                             @"lastname":user.lastName,
                             @"email":user.email,
                             @"password":user.password,
                             @"confirmpassword":user.password,
                             @"height_m":[user.heighInFeet stringValue],
                             @"height_c":[user.heighInInches stringValue],
                             @"weight":[user.weight stringValue],
                             @"gender":user.gender == GenderMale?@"0":@"1",
                             @"age":[user.age stringValue],
                             
                             @"training":[NSString stringWithFormat:@"%@ per %ld",golfProfile.trainingHours,golfProfile.trainingUnit],
                             @"handed":golfProfile.isLeftHanded?@"1":@"2",
                             @"handicap":[golfProfile.handicapLevel stringValue],
                             
                             @"report":user.isDisplaySensorDisclaimer?@"1":@"0",
                             @"update":user.isEmailUpdate?@"1":@"0"};
    
    [JCBaseWebUtils post:path andParams:params andCallback:^(BOOL requestState, id obj) {
        if (requestState == YES) {
            if (!obj) {
                complete(NO,[NSError errorWithDomain:@"System error!" code:-101]);
                return ;
            }
            NSInteger ret = [obj[@"code"] integerValue];
            if (ret == WebRespondTypeSuccess) {
                NSDictionary *data = obj[@"data"];
                NSNumber *userID = @([data[@"userid"] integerValue]);
                complete(YES,userID);
            }
            else{
                [self errorState:ret complete:complete];
            }
        }
        else{
            NSError *error = [NSError errorWithDomain:NET_ERROR code:-10086];
            complete(NO, error);
        }
    }];
    
}

//账号登录
+(void)accountLoginWithParams:(NSDictionary *)params
                     complete:(void (^)(DTUser *, NSError *))completion{
    
    if (![self isNetWorking]) {
        NSError *error = [NSError errorWithDomain:@"No Net!" code:-10086];
        completion(nil, error);
    }
    
    NSString *path = [BaseAPI stringByAppendingString:AcountLogin];
    [JCBaseWebUtils post:path andParams:params andCallback:^(BOOL requestState, id obj) {
        
        if (requestState == YES) {
            NSInteger ret = [obj[@"code"] integerValue];
            
            if (ret == WebRespondTypeSuccess) {
                NSDictionary *dataDic = obj[@"data"];
                NSDictionary *userInfo = dataDic[@"userinfo"];
                DTUser *user = [[DTUserStore sharedInstance] userByID:dataDic[@"userid"]];
                if (user) {
                    user.token = dataDic[@"token"];
                }else{
                    user = [[DTUser alloc] init];
                    user.ID = dataDic[@"userid"];
                    user.password = params[@"password"];
                    user.email = params[@"email"];
                    user.token = dataDic[@"token"];
                }
                user.firstName = [NSString checkIfNullWithString:userInfo[@"firstname"]];
                user.lastName = [NSString checkIfNullWithString:userInfo[@"lastname"]];
                if ([[NSString checkIfNullWithString:userInfo[@"gender"]] integerValue] == GenderMale) {
                    user.gender = GenderMale;
                }else if ([[NSString checkIfNullWithString:userInfo[@"gender"]] integerValue] == GenderFemale){
                    user.gender = GenderFemale;
                }
                else{
                    user.gender = GenderUndefined;
                }
                user.heighInFeet = @([[NSString checkIfNullWithString:userInfo[@"height_c"]] integerValue]);
                user.heighInInches = @([[NSString checkIfNullWithString:userInfo[@"height_m"]] integerValue]);
                user.weight = @([[NSString checkIfNullWithString:userInfo[@"weight"]] integerValue]);
                user.age = @([[NSString checkIfNullWithString:userInfo[@"age"]] integerValue]);
                user.emailProgress = [[NSString checkIfNullWithString:userInfo[@"report"]] boolValue];
                user.emailUpdate = [[NSString checkIfNullWithString:userInfo[@"update"]] boolValue];
                
                DTGolfProfile *golfProfile = user.golfProfile;
                if (!golfProfile) {
                    golfProfile = [[DTGolfProfile alloc] init];
                }
                NSString *training = [NSString checkIfNullWithString:userInfo[@"training"]];
                if (training.length >= 7) {
                    golfProfile.trainingHours = @([[training substringWithRange:NSMakeRange(0, 1)] integerValue]);
                    golfProfile.trainingUnit = [[training substringWithRange:NSMakeRange(6, 1)] integerValue];
                }
                golfProfile.handicapLevel = @([[NSString checkIfNullWithString:userInfo[@"handicap"]] integerValue]);
                golfProfile.leftHanded = [[NSString checkIfNullWithString:userInfo[@"handed"]] integerValue]==1?YES:NO;
                user.golfProfile = golfProfile;
                
                [[DTUserStore sharedInstance] saveUserLocally:user//本地用户添加、更新
                                                 onCompletion:^(BOOL DBresult, NSError *error) {
                                                     if (DBresult) {
                                                         completion(user,  nil);
                                                     }else{
                                                         completion(user,  [NSError errorWithDomain:@"LocalSaveUserError" code:-20012]);
                                                     }
                                                 }];
            }
            else if (ret == WebRespondTypePasswordIncorrect){
                 completion(nil,  [NSError errorWithDomain:@"Account Or Password Incorrect" code:-20004]);
            }
            else if (ret == WebRespondTypeNoUser){
                completion(nil,  [NSError errorWithDomain:@"No User" code:WebRespondTypeNoUser]);
            }
            else if (ret == WebRespondTypeNotLogin){
                completion(nil,  [NSError errorWithDomain:@"Not Login" code:WebRespondTypeNotLogin]);
            }
            else if (ret == WebRespondTypeParamsIsRequired){
                completion(nil,  [NSError errorWithDomain:@"The Email is required." code:WebRespondTypeParamsIsRequired]);
            }
            else if (ret == WebRespondTypeUserDoesNotExist){
                completion(nil,  [NSError errorWithDomain:@"User Does Not Exist." code:WebRespondTypeUserDoesNotExist]);
            }
        }
        else{
            completion(nil,  [NSError errorWithDomain:NET_ERROR code:-10086]);
        }
    }];
}

//刷新登录状态
+ (void)refreshUserLogin:(DTUser *)needRefreshUser
                complete:(void (^)(DTUser *, NSError *))completion{
    
    if (![self isNetWorking]) {
        NSError *error = [NSError errorWithDomain:@"No Net!" code:-10086];
        completion(nil, error);
    }
    
    //刷新登录
    JCLog(@"\n刷新登录 === >>> \n");
    NSDictionary *params = @{@"email":needRefreshUser.email,
                             @"password":needRefreshUser.password,
                             @"clienttimestamp":[NSString stringWithFormat:@"%.0f",[[NSDate new] unixTimeStampWithDate]]};
    [self accountLoginWithParams:params complete:^(DTUser *user, NSError *error) {
        if (error) {
            completion(nil, error);
        }
        else {//登录成功
            [[DTUserStore sharedInstance] loginUser:user onCompletion:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"changeToken" object:user.token];
            completion(user, nil);
        }
    }];
}

//确认密码
+ (void)affirmPassWordWithUser:(DTUser *)user
                      passWord:(NSString *)passWord
                      complete:(void (^)(BOOL, NSError *))completion{
    
    if (![self isNetWorking]) {
        NSError *error = [NSError errorWithDomain:@"No Net!" code:-10086];
        completion(NO, error);
    }
    
    NSString *path = [BaseAPI stringByAppendingString:AffirmPassWord];
    NSString *timeStamp = [NSDate unixTimeStampWithString];
    NSString *sign = [self creatSignWithAPI:AffirmPassWord user:user timeStamp:timeStamp];
    path = [NSString stringWithFormat:@"%@?uid=%@&timestamp=%@&sign=%@&lang=english",path,[user.ID stringValue],timeStamp,sign];
    
    NSDictionary *params = @{@"password":passWord};
    [JCBaseWebUtils post:path andParams:params andCallback:^(BOOL requestState, id obj) {
        if (requestState == YES) {
            if (!obj) {
                completion(NO,[NSError errorWithDomain:@"System error!" code:-101]);
                return ;
            }
            NSInteger ret = [obj[@"code"] integerValue];
            NSString *msg = obj[@"msg"];
            if (ret == WebRespondTypeSuccess && [msg isEqualToString:@"ok"]) {
                
                completion(YES,nil);
            }
            else if (ret == WebRespondTypeUnknowError){//重新登录
                [self refreshUserLogin:user complete:^(DTUser *refreshUser, NSError *refreshError) {
                    if (refreshUser) {
                        [self affirmPassWordWithUser:refreshUser passWord:passWord complete:completion];
                    }
                    else{
                        completion(NO, refreshError);
                    }
                }];
            }
            else{
                [self errorState:ret complete:completion];
            }
        }
        else{
            NSError *error = [NSError errorWithDomain:NET_ERROR code:-10086];
            completion(NO, error);
        }
    }];
}

//修改密码
+ (void)changePassWordWithUser:(DTUser *)user
                      passWord:(NSString *)passWord
                      complete:(void (^)(BOOL, NSError *))completion{
    
    if (![self isNetWorking]) {
        NSError *error = [NSError errorWithDomain:@"No Net!" code:-10086];
        completion(NO, error);
    }

    NSString *path = [BaseAPI stringByAppendingString:PassWordChange];
    NSString *timeStamp = [NSDate unixTimeStampWithString];
    NSString *sign = [self creatSignWithAPI:PassWordChange user:user timeStamp:timeStamp];
    path = [NSString stringWithFormat:@"%@?uid=%@&timestamp=%@&sign=%@&lang=english",path,[user.ID stringValue],timeStamp,sign];
    
    NSDictionary *params = @{@"password":passWord,
                     @"confirmpassword":passWord};
    [JCBaseWebUtils post:path andParams:params andCallback:^(BOOL requestState, id obj) {
        if (requestState == YES) {
            if (!obj) {
                completion(NO,[NSError errorWithDomain:@"System error!" code:-101]);
                return ;
            }
            NSInteger ret = [obj[@"code"] integerValue];
            NSString *msg = obj[@"msg"];
            if (ret == 0 && [msg isEqualToString:@"ok"]) {
                user.password = passWord;
                [[DTUserStore sharedInstance] saveUserLocally:user onCompletion:^(BOOL saveResult, NSError *saveError) {
                    if (saveResult) {
                        completion(YES,nil);
                    }
                    else{
                        completion(NO,saveError);
                    }
                }];
            }
            else if (ret == WebRespondTypeUnknowError){//重新登录
                [self refreshUserLogin:user complete:^(DTUser *refreshUser, NSError *refreshError) {
                    if (refreshUser) {
                        [self changePassWordWithUser:refreshUser passWord:passWord complete:completion];
                    }
                    else{
                        completion(NO, refreshError);
                    }
                }];
            }
            else{
                [self errorState:ret complete:completion];
            }
    
        }
        else{
            NSError *error = [NSError errorWithDomain:NET_ERROR code:-10086];
            completion(NO, error);
        }
    }];
    
} */

//错误状态
+ (void)errorState:(NSInteger)ret complete:(void (^)(BOOL, NSError *))completion{
    if (ret == -101){
        NSError *error = [NSError errorWithDomain:@"System error!" code:-101];
        completion(NO, error);
    }
    else if (ret == -10017){//无数据
        completion(YES, nil);
    }
    else if (ret == -20001){
        NSError *error = [NSError errorWithDomain:@"This mailbox has been registered" code:-20001];
        completion(NO, error);
    }
    else if (ret == -20004){
        NSError *error = [NSError errorWithDomain:@"Username or password incorrect" code:-20004];
        completion(NO, error);
    }
    else if (ret == -20005){
        NSError *error = [NSError errorWithDomain:@"Register has failed" code:-20005];
        completion(NO, error);
    }
    else if (ret == -20006){
        NSError *error = [NSError errorWithDomain:@"Possword DO NOT match" code:-20006];
        completion(NO, error);
    }
    else if (ret == -20009){
        NSError *error = [NSError errorWithDomain:@"The {param name} is required." code:-20009];
        completion(NO, error);
    }
    else if (ret == -20010){
        NSError *error = [NSError errorWithDomain:@"The {param name} must contain a valid email address." code:-20010];
        completion(NO, error);
    }
    else if (ret == -20012){
        NSError *error = [NSError errorWithDomain:@"The {param name} must contain only numbers" code:-20012];
        completion(NO, error);
    }
}


+ (void)uploadFirwareWithOemtype:(NSString *)oemtype
                   isCompressZIP:(BOOL)isZIP
                 downLoadProress:(void (^)(float progress))progress
                        complete:(void (^)(NSArray *, NSError *))completion{
    
//    if (![self isNetWorking]) {
//        NSError *error = [NSError errorWithDomain:@"No Net!" code:-10086];
//        completion(nil, error);
//    }
    
    NSString *path = [BaseAPI stringByAppendingString:UploadFirware];
    
    NSDictionary *params = @{@"oemtype":oemtype,
                             @"zip":[NSString stringWithFormat:@"%@",isZIP?@"1":@"0"]};
    [JCBaseWebUtils post:path andParams:params andCallback:^(BOOL requestState, id obj) {
        if (requestState == YES) {
            if (!obj) {
                completion(nil,[NSError errorWithDomain:@"System error!" code:-101]);
                return;
            }
            NSInteger ret = [obj[@"code"] integerValue];
            if (ret == WebRespondTypeSuccess) {
                
                //清空掉cache文件夹下所有文件
                NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
                NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:cachesPath];
                for (NSString *fileName in enumerator) {
                    [[NSFileManager defaultManager] removeItemAtPath:[cachesPath stringByAppendingPathComponent:fileName] error:nil];
                }
                
                NSString *fileUrl = obj[@"data"][@"path"];
                [self downLoadFirware:[NSURL URLWithString:fileUrl] downLoadProress:^(float downProgress) {
                    if (progress) {
                        progress(downProgress);
                    }
                } completion:^(NSString *path, NSError *error) {
                    if (path) {
                        NSLog(@"\n\n下载完成，得到固件包：%@",path);
                        //解压固件包
                        NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
                        NSString *firwareFold = [cachesPath stringByAppendingPathComponent:@"firware"];
                        NSError *error = [NSError new];
                        if ([SSZipArchive unzipFileAtPath:path toDestination:firwareFold overwrite:YES password:nil error:&error]) {
                            
                            NSFileManager *manager = [NSFileManager defaultManager];
                            BOOL isFold = NO;
                            NSError *error;
                            [manager fileExistsAtPath:firwareFold isDirectory:&isFold];
                            if (isFold) {
                                NSArray *content = [manager contentsOfDirectoryAtPath:firwareFold error:&error];
                                NSMutableArray *firwares = [@[] mutableCopy];
                                for (NSString *file in content) {
                                    if ([file containsString:@".zip"]) {
                                        [firwares addObject:[firwareFold stringByAppendingPathComponent:file]];
                                    }
                                }
                                //获取到全部固件包path
                                NSLog(@"固件包path：\n\n\n%@",firwares);
                                completion([firwares mutableCopy], nil);
                            }
                    
                        }
                        else{
                            completion(nil,error);
                        }
                    }
                }];
            }
            else{
//                [self errorState:ret complete:completion];
            }
        }
        else{
            NSError *error = [NSError errorWithDomain:NET_ERROR code:-10086];
            completion(nil, error);
        }
    }];
    
}

+ (void)downLoadFirware:(NSURL *)url
        downLoadProress:(void (^)(float progress))progress
             completion:(void  (^) (NSString *path, NSError *error))completion{
    
    //默认配置
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    //AFN3.0+基于封住URLSession的句柄
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    //请求
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
//
//    //下载Task操作
//    // 下载句柄
     NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        
        // @property int64_t totalUnitCount;     需要下载文件的总大小
        // @property int64_t completedUnitCount; 当前已经下载的大小
        // 给Progress添加监听 KVO
        NSLog(@"%f",1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
         progress(1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
        // 回到主队列刷新UI
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        //- block的返回值, 要求返回一个URL, 返回的这个URL就是文件的位置的路径
        NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSString *path = [cachesPath stringByAppendingPathComponent:response.suggestedFilename];
        return [NSURL fileURLWithPath:path];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        //设置下载完成操作
        // filePath就是你下载文件的位置，你可以解压，也可以直接拿来使用
        completion([filePath path], nil);
        
    }];
    
    [task resume];
}

@end
