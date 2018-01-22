//
//  JCWebRequestConfig.h
//  DuoTrac
//
//  Created by Guo.JC on 17/3/24.
//  Copyright © 2017年 coollang. All rights reserved.
//

#ifndef JCWebRequestConfig_h
#define JCWebRequestConfig_h

//#define         BaseAPI                         @"http://192.168.199.44:8082/"//测试服
#define         BaseAPI                         @"http://52.41.1.197/"//正式服

#define         RegisterUser                    @"Register/userReister?lang=english"
#define         AcountLogin                     @"Register/login?lang=english"

#define         UploadSwing                     @"Sportdata/uploadDate"
#define         DownLoadSingleMouth             @"Sportdata/getSingleMouthDate"
#define         DownLoadMultipleMouth           @"Sportdata/getMultipleMonthData"
#define         StaticsData                     @"Sportdata/getStats"
#define         Chart4WeekData                  @"Sportdata/getLastFourWeek"
#define         Chart6MouthData                 @"Sportdata/getLastSixMonth"
#define         Chart12MouthData                @"Sportdata/getLastYear"

#define         AffirmPassWord                  @"Password/confirm"
#define         PassWordChange                  @"Password/change"

#define         UploadFirware                   @"VersionController/getLastVersionNew"

#endif 
