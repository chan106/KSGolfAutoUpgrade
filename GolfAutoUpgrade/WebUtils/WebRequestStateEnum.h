//
//  WebRequestStateEnum.h
//  Victor
//
//  Created by Guo.JC on 17/3/10.
//  Copyright © 2017年 coollang. All rights reserved.
//

#import <Foundation/Foundation.h>  


#define         kMsgLoginSuccess        @"登录成功,正在加载..."
#define         kMsgFail                @"数据获取失败,请稍后重试"
#define         kMsgNoUser              @"该账号不存在"
#define         kMsgNotLogin            @"您还未登录"
#define         kMsgDataIsNil           @"数据为空"
#define         kMsgNetError            @"网络错误"
#define         kMsgVerifyCodeError     @"验证码错误"
#define         kMsgSendCodeSuccess     @"验证码发送成功"
#define         kMsgSendCodeFail        @"验证码发送失败"
#define         kMsgUpLoadingSuccess    @"数据上传成功"
#define         NET_ERROR               @"Net Error!"



typedef NS_ENUM(NSInteger,WebRespondType) {
    WebRespondTypeFail = -1,//数据获取失败
    WebRespondTypeSuccess = 0,//数据请求成功
    WebRespondTypeNoUser = -10002,//该账号不存在
    WebRespondTypeNotLogin = -10003,//未登录
    WebRespondTypeDataIsNil = -10006,//数据为空
    WebRespondTypeUknowDevice = -10009,//非法登录设备
    WebRespondTypeParamsError = -20001,//参数错误
    WebRespondTypeVerifyCodeWrong = -50007,//验证码错误
    WebRespondTypeChangePassVerifyCodeError = -468,//验证码错误
    WebRespondTypeMobServerError = -50009,//mob服务器请求失败
    WebRespondTypeTimeOut = 10086,//网络超时、网络错误
    
    WebRespondTypeSystemError = -101,//系统错误
    WebRespondTypeMailboxHasRegister = -20001,//邮箱已被注册
    WebRespondTypePasswordIncorrect = -20004,//密码错误
    WebRespondTypeRegisterHasFailed = -20005,//注册失败
    WebRespondTypePosswordDoNotMatch = -20006,//密码不一致
    WebRespondTypeParamsIsRequired = -20009,//缺少参数
    WebRespondTypeEmailIsInvalid = -20010,//邮箱地址无效
    WebRespondTypeParamsContainOnlyNumbers = -20012,//
    WebRespondTypeUnknowError = -20015,//未知错误
    WebRespondTypeUserDoesNotExist = -20020//用户不存在
} ;

typedef NS_ENUM(NSInteger, ChartDataType) {
    
    ChartDataType4Week,
    ChartDataType6Mouth,
    ChartDataType12Mouth
    
};

#define         kLoadDataTimestamp                  @"LoadDataTimestamp"            //历史数据加载时间戳
#define         kUploadSportRecordTimestamp         @"uploadSportRecordTimestamp"   //主页面统计数据上传时间戳
#define         kDBUploadSportRecordTime            @"DBuploadSportRecordTimestamp" //本地统计数据已上传的时间戳
#define         kDBUploadSportNumber                @"DBuploadSportRecordNumber"    //本地统计数据已上传的条数


