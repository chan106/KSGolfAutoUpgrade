//
//  JCBlutoothInfoModel.h
//  Turing
//
//  Created by 郭吉成 on 2017/10/30.
//  Copyright © 2017年 KOOSPUR. All rights reserved.
//

@import CoreBluetooth;
#import <UIKit/UIKit.h>
#import "JCBLEEnum.h"





@protocol JCDeviceDelegate <NSObject>

- (void)foundCharacterSuccess:( JCBLEDevice * _Nonnull )device;

@end







@interface JCBLEDevice : NSObject <CBPeripheralDelegate>

@property (nullable, nonatomic, copy) NSString *name;                         //设备名
@property (nonatomic, assign) OemType oemtype;                                //Oemtype;
@property (nonatomic, assign) CBPeripheralState state;                        //连接状态
@property (nullable, nonatomic, strong) CBPeripheral *peripheral;             //外设
@property (nullable, nonatomic, strong) NSDictionary *advertisementData;      //广播数据
@property (nullable, nonatomic, strong) NSNumber *RSSI;                       //信号值
@property (nullable, nonatomic, copy) NSString *macAddr;                      //mac地址
@property (nullable, nonatomic, strong) NSNumber *power;                      //电量
@property (nullable, nonatomic, copy) NSString *version;                      //固件版本
@property (nullable, nonatomic, copy) NSString *serverVersion;                //服务器上的固件版本
@property (nullable, nonatomic, copy) NSString *serverPath;                   //固件下载地址
@property (nullable, nonatomic, copy) NSString *packagePath;                  //本地固件地址
@property (nonatomic, assign) BOOL isNeedUpgrade;                             //是否需要升级
@property (nullable, nonatomic, weak) id <JCDeviceDelegate> delegate;         //代理
@property (nullable, nonatomic, copy) NSString *PCBVersion;                   //pcb版本
@property (nonatomic, assign) NSInteger productionBatch;                      //生产批次
@property (nonatomic, assign) NSInteger burnTimestamp;                        //烧录时间戳

/*!
 创建设备
 @params peripheral         外设
 @params advertisementData  广播
 @params oemtype            oemtype
 @params macAddress         macAddress
 @params RSSI               信号值
 */
+(nullable instancetype)UARTWith:(nullable CBPeripheral *)peripheral
               advertisementData:(nullable NSDictionary *)advertisementData
                         oemtype:(OemType)oemtype
                      macAddress:(nullable NSString *)macAddress
                         andRSSI:(nullable NSNumber *)RSSI;

/*!
 关机
 @params complete   回调
 */
- (void)shutDownComplete:(nullable DeviceShutDownComplete)complete;

/*!
 重启
 @params complete   回调
 */
- (void)rebootComplete:(nullable DeviceRebootComplete)complete;

/*!
 清除数据
 @params complete   回调
 */
- (void)clearDataComplete:(nullable ClearDataComplete)complete;

/*!
 恢复出厂
 @params complete   回调
 */
- (void)recoverComplete:(nullable DeviceRecoverComplete)complete;

/*!
 固件升级
 @params complete   回调
 */
- (void)upgradeDeviceComplete:(nullable DeviceUpgradeComplete)complete;

/*!
 读取MAC地址
 @params complete   回调
 */
- (void)getMacAddressComplete:(nullable DeviceUpgradeComplete)complete;

/*!
 设备名修改
 @params name       需要修改的设备名
 @params complete   回调
 */
- (void)editName:(nullable NSString *)name Complete:(nullable DeviceEditNameComplete)complete;

/*!
 左右手设置
 @params type       需要设置的左右手
 @params complete   回调
 */
- (void)setHandle:(HandleType)type Complete:(nullable DeviceSetHandleNameComplete)complete;

/*!
 读取电量
 @params complete   回调
 */
- (void)getBatteryComplete:(nullable GetDeviceBaterryComplete)complete;

/*!
 读取生产信息
 @params complete   回调
 */
- (void)getFactoryInfoComplete:(nullable GetDeviceFactoryInfoComplete)complete;

/*!
 同步时间戳
 */
- (void)syncTime;

/*!
 读取固件版本
 @params complete   回调
 */
- (void)getVersionComplete:(nullable GetDeviceVersionComplete)complete;

/*!
 读取主页数据（最近十天）
 @params complete   回调
 */
- (void)getMainDataComplete:(nullable GetDeviceMainDataComplete)complete;

/*!
 读取动作详情数据
 @params complete   回调
 */
- (void)getSwingInfoDate:(NSInteger)date
                   index:(NSInteger)index
                complete:(nullable GetDeviceSwingInfoComplete)complete;

/*!
 同步数据
 */
- (void)syncSportDataMainComplete:(void (^_Nullable)(BOOL, NSError *_Nullable error))mainCompletion
                    swingProgress:(void(^_Nullable)(CGFloat progress))progress
                   swingCompelete:(void (^_Nullable)(BOOL, NSError *_Nullable error))swingCompletion;

/*!
 读取实时数据
 @params complete   回调
 */
- (void)getRealDataState:(void(^ _Nullable)(BOOL success)) realTimeState
                complete:(nullable GetDeviceRealDataComplete)complete;
/*!
 退出读取实时数据
 */
- (void)quitRealMode;

/*!
 读取3D数据
 */
- (void)get3DDataWithCompletionBlock:(void(^ _Nullable )(BOOL success)) completionBlock
       threeDSwingGeneralResultBlock:(nullable ThreeDSwingGeneralResultBlock)threeDSwingGeneralResultBlock
                 threeDModeItemBlock:(nullable ThreeDModeItemBlock)threeDModeItemBlock
              finishReceiveItemBlock:(void(^ _Nullable )(BOOL success))finishReceiveItemBlock;
/**
 退出3D模式
 */
- (void)quit3DMode;

/*!
 *  通过蓝牙发送 指令+数据 到外设
 *
 *  @param command -[in] 要发送的指令
 *  @param validData -[in] 要发送的数据
 */
- (void)sendDataUseCommand:(nullable NSString *)command
                 validData:(nullable NSString *)validData;

/**
 发送数据
 @params data       发送的data
 */
- (void)sendData:(nullable NSData *)data;

/*!
 *  通过蓝牙发送 指令+数据 到外设
 *
 *  @param command -[in] 要发送的指令
 *  @param validData -[in] 要发送的数据
 */
#pragma APP发送指令数据
- (void)sendDataUseCommand:(nullable NSString *)command
                 validData:(nullable NSString *)validData
                  complete:(DeviceUpgradeComplete)complete;

@end
