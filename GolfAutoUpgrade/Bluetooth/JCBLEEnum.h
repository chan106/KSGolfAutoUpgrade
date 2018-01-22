//
//  JCBLEEnum.h
//  多设备连接
//
//  Created by 郭吉成 on 2017/10/30.
//  Copyright © 2017年 KOOSPUR. All rights reserved.
//

#ifndef JCBLE_ENUM_H
#define JCBLE_ENUM_H

#import <Foundation/Foundation.h>
@class JCBLEDevice;
@class JCRealTimeData;
@class JCThreeDModeItem;
@class JCThreeDItem;
@class JCSwingDetails;

/*
 *@收到的数据类型
 */
typedef NS_ENUM(NSInteger, RespondType) {
    RespondTypeShutdown = 1,//关机
    RespondTypeRest = 2,//重启
    RespondTypeClearData = 3,//清除数据
    RespondTypeFactoryRest = 4,//恢复出厂
    RespondTypeUpdateFirmware = 5,//固件升级
    
    RespondTypeTimestampVerify = 17,//时间戳校验
    RespondTypeEditDeviceName = 18,//编辑设备名称
    RespondTypeSetupHandle = 19,//设置左右手
    
    RespondTypeFirmwareRev = 33,//固件版本
    RespondTypeBattery = 34,//电池电量
    RespondTypeMainData = 35,//主界面数据
    RespondTypeRealData = 36,//实时数据
    RespondTypeSwingInfo = 37,//动作详情
    RespondTypeSwingWeight  = 38,//挥拍力度
    RespondType3DData = 39,//3D显示数据
    RespondTypeFactoryInfo = 40//生产信息
};

typedef NS_ENUM(NSInteger, BluetoothOpenState) {
    BluetoothOpenStateIsOpen = 0,//蓝牙打开
    BluetoothOpenStateIsClosed = 1//蓝牙关闭
};

typedef NS_ENUM(NSInteger, DeviceConnectState) {
    DeviceConnectStateIDE,      //错误
    DeviceConnectStateScanning, //扫描中
    DeviceConnectStateConnected,//已连接
    DeviceConnectStateRecover   //恢复连接中
};

//动作类型
typedef NS_ENUM(NSInteger, JCActionType) {
    JCPoseTypeSmash = 4,  // 扣杀
    JCPoseTypeBlock,      // 挡球
    JCPoseTypeDrop,       // 挑
    JCPoseTypeClear,      // 高远
    JCPoseTypeDrive,      // 抽球
    JCPoseTypeChop,       // 搓球
    JCPoseTypeParrel,     // 吊球
    JCPoseTypeNonstandard //非标准
};

typedef NS_ENUM(NSInteger, ServeDirectionType) {
    
    ServeDirectionTypeCenter = 0,   //出球方向 - 中
    ServeDirectionTypeLeft,         //出球方向 - 左
    ServeDirectionTypeRight         //出球方向 - 右
    
};

typedef NS_ENUM(NSInteger, JCHandType) {
    JCHandTypeLeft ,    // 左手
    JCHandTypeRight ,   // 右手
    JCHandTypeUnknow    //未知
};

typedef NS_ENUM(NSInteger, JCHandBallType) {
    JCHandBallTypeUp,   // 上手球
    JCHandBallTypeDown  // 下手球
};

typedef NS_ENUM(NSInteger, JCHandDirectionType) {
    JCHandDirectionTypeForward,     // 正手
    JCHandDirectionTypeBackward     // 反手
};

typedef NS_ENUM(NSInteger, HandleType) {
    HandleTypeLeft,
    HandleTypeRight
};

typedef NS_ENUM(NSInteger, OemType) {
    OemTypeUnknown = 0,
    OemTypeGolfDT2 = 2,  //DT2
    OemTypeGolfDT3 = 3,  //DT3
    OemTypeGolfDT4 = 4,  //DT4
    OemTypeGolfBall = 5  //高尔夫-球
};

/*!
 *  蓝牙数据请求状态
 */
typedef NS_ENUM(NSInteger, RequestDeviceDataState) {
    RequestDeviceDataStateFail = 0,
    RequestDeviceDataStateSuccess = 1
};

/*!
 *  设备连接模式
 */
typedef NS_ENUM(NSInteger, ConnectDeviceMode) {
    ConnectDeviceModeOnlyBall = 0,      //只连接 - 球
    ConnectDeviceModeOnlyClub = 1,    //只连接 - 推杆
    ConnectDeviceModeBoth               //球 推杆 都连接
};

typedef void(^connectingCallBack)(BOOL connectState);
typedef void(^completeCallBack)(id obj);//基本数据回调
typedef void(^CompleteCallBack)(id obj);//基本数据回调

#pragma mark - 蓝牙读取数据回调
//蓝牙数据处理回调
typedef void(^GetBluetoothDataComplete)(JCBLEDevice *device,
                                        RespondType respondType,
                                        id obj);
//关闭设备
typedef void(^DeviceShutDownComplete)(RequestDeviceDataState state,
                                      JCBLEDevice *device,
                                      NSError *error);
//重启设备
typedef void(^DeviceRebootComplete)(RequestDeviceDataState state,
                                    JCBLEDevice *device,
                                    NSError *error);
//清除数据
typedef void(^ClearDataComplete)(RequestDeviceDataState state,
                                 JCBLEDevice *device,
                                 NSError *error);
//恢复出厂
typedef void(^DeviceRecoverComplete)(RequestDeviceDataState state,
                                     JCBLEDevice *device,
                                     NSError *error);
//固件升级
typedef void(^DeviceUpgradeComplete)(RequestDeviceDataState state,
                                     JCBLEDevice *device,
                                     NSError *error);
//设备名修改
typedef void(^DeviceEditNameComplete)(RequestDeviceDataState state,
                                      JCBLEDevice *device,
                                      NSError *error);
//左右手设置
typedef void(^DeviceSetHandleNameComplete)(RequestDeviceDataState state,
                                           JCBLEDevice *device,
                                           NSError *error);
//读取固件版本
typedef void(^GetDeviceVersionComplete)(RequestDeviceDataState state,
                                        JCBLEDevice *device,
                                        NSString *version);
//读取电池电量
typedef void(^GetDeviceBaterryComplete)(RequestDeviceDataState state,
                                        JCBLEDevice *device,
                                        NSNumber *battery);
//读取生产信息
typedef void(^GetDeviceFactoryInfoComplete)(RequestDeviceDataState state,
                                            JCBLEDevice *device,
                                            NSString *PCBVersion,
                                            NSInteger productionBatch,
                                            NSInteger burnTimestamp);
///主页数据
typedef void(^GetDeviceMainDataComplete)(NSArray *dateArray,
                                         NSError *error);
///动作详情
typedef void(^GetDeviceSwingInfoComplete)(JCSwingDetails *racketItem,
                                          NSError *error);
///实时数据
typedef void(^GetDeviceRealDataComplete)(RequestDeviceDataState state,
                                         JCBLEDevice *device,
                                         JCRealTimeData *realTimeItem,
                                         NSError *error);
//3D挥拍数据
typedef void(^ThreeDSwingGeneralResultBlock)(BOOL success,
                                             JCThreeDItem *item);
//3D详细数据
typedef void(^ThreeDModeItemBlock)(JCThreeDModeItem *item);

typedef void(^getBluetoothDataComplete)(JCBLEDevice *device, RespondType respondType, id obj);//蓝牙数据处理回调

#endif
