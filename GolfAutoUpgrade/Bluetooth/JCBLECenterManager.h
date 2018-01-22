//
//  JCBLECenterManager.h
//  DuoTrac-Ball
//

/*
 *  蓝牙设备管理
 *  多设备版
 */

//  Created by 郭吉成 on 2017/10/30.
//  Copyright © 2017年 KOOSPUR. All rights reserved.
//

@import CoreBluetooth;
#import <Foundation/Foundation.h>
#import "JCBLEEnum.h"

@class JCBLECenterManager;

/**
 *  ----------  < 蓝牙管理器中心协议 >  ----------
 */
@protocol JCMultiBLEManagerDelegate <NSObject>

@optional

/*!
 *  蓝牙开启状态改变
 *
 *  @param manager              -[in] 蓝牙管理中心
 *  @param openState            -[in] 蓝牙开启状态
 */
- (void)bluetoothStateChange:(nullable JCBLECenterManager *)manager
                       state:(BluetoothOpenState)openState;

/*!
 *  发现新设备
 *
 *  @param manager              -[in] 蓝牙管理中心
 *  @param device               -[in] 发现的外设
 */
- (void)foundPeripheral:(nullable JCBLECenterManager *)manager
                 device:(nullable JCBLEDevice *)device;

/*!
 *  正在连接外设
 *
 *  @param manager              -[in] 蓝牙管理中心
 *  @param device               -[in] 正在连接的外设
 */
- (void)bluetoothManager:(nullable JCBLECenterManager*)manager
  didConectingPeripheral:(nullable JCBLEDevice *)device;

/*!
 *  蓝牙连接外设成功
 *
 *  @param manager              -[in] 蓝牙管理中心
 *  @param device               -[in] 连接成功的外设
 */
- (void)bluetoothManager:(nullable JCBLECenterManager*)manager
didSucceedConectPeripheral:(nullable JCBLEDevice *)device;

/*!
 *  蓝牙连接外设失败
 *
 *  @param manager              -[in] 蓝牙管理中心
 *  @param device               -[in] 连接失败的外设
 */
- (void)bluetoothManager:(nullable JCBLECenterManager*)manager
 didFailConectPeripheral:(nullable JCBLEDevice *)device;

/*!
 *  收到已连接的外设传过来的数据
 *
 *  @param manager              -[in] 蓝牙管理中心
 *  @param data                 -[in] 外设发过来的data数据
 */
- (void)receiveData:(nullable JCBLECenterManager *)manager
               data:(nullable NSData *)data;

/*!
 *  与外设的连接断开
 *
 *  @param manager              -[in] 蓝牙管理中心
 *  @param peripheral           -[in] 连接的外设
 *  @param error                -[in] 错误信息
 */
- (void)bluetoothManager:(nullable JCBLECenterManager *)manager
 didDisconnectPeripheral:(nullable CBPeripheral *)peripheral
                   error:(nullable NSError *)error;

/*!
 *  已成功连接上所有设备
 *
 *  @param manager              -[in] 蓝牙管理中心
 */
- (void)bluetoothDidSuccessAllConnectManager:(nullable JCBLECenterManager *)manager;

@required

@end








/**
 *  ----------  < 蓝牙管理器中心 >  ----------
 */
@interface JCBLECenterManager : NSObject
//当前手机蓝牙开启状态
@property (nonatomic, assign) BluetoothOpenState bluetoothState;
@property (nonatomic, weak, nullable) id <JCMultiBLEManagerDelegate> delegate;
//所有已连蓝牙外设
@property (nonatomic, strong) NSMutableArray <JCBLEDevice *>* _Nullable uartArray;
//外设连接状态
@property (nonatomic, assign) DeviceConnectState state;
//是否在实时模式
@property (nonatomic, assign) BOOL isEnterReal;

/*!
 *  创建全局蓝牙管理中心
 *  @return 返回蓝牙管理中心对象单例
 */
+ (nullable JCBLECenterManager *)shareCBCentralManager;

- (nullable CBCentralManager *)centerManager;


#pragma mark -- 扫描、停止扫描外设
/*!
 *  重新扫描外设
 *  会断开、清空 调用此方法前的 所有连接及状态
 */
- (void)reScan;

/*!
 *  重新扫描外设
 *  仅仅扫描，不会有其他操作
 */
- (void)onlyStartScan;

/*!
 *  停止扫描外设
 *  会断开、清空 调用此方法前的 所有连接及状态
 */
- (void)stopScan;

/*!
 *  停止扫描外设
 *  仅仅停止扫描，不会有其他操作
 */
- (void)onlyStopScan;


#pragma mark -- 连接、断开 外设
/*!
 *  连接到外设蓝牙（CBPeripheral）
 *  @param peripheral 要连接的外设
 */
- (void)connectToPeripheral:(nullable CBPeripheral *)peripheral;

/*!
 *  连接到外设蓝牙（JCBLEDevice）
 *  @param device -[in] 要连接的外设
 */
- (void)connectToDevice:(nullable JCBLEDevice *)device
             completion:(nullable connectingCallBack) completion;

/*!
 *  断开与外设蓝牙连接
 *  @param peripheral -[in] 要断开的外设
 */
- (void)disConnectToPeripheral:(nullable CBPeripheral *)peripheral;

/*!
 *  进入更改设备名字模式 是/否
 */
- (void)enterEditNameMode:(BOOL)isEnter;

/*!
 *  获取设备
 *  @param deviceType       -[in] 需要获取的设备类型
 *  return                  获取到的设备
 */
- (JCBLEDevice *_Nullable)getDeviceForDeviceType:(OemType)deviceType;

/*!
 *  获取连接上的设备
 *  return                  获取到的设备
 */
- (nullable NSArray *)getConnectDevice;

/*!
 *  连接设备 + 超时处理 + 连接模式
 *  @param timeout       -[in] 连接超时时间
 *  @param mode          -[in] 连接模式
 *  @param completion    回调
 */
- (void)connectSensorsWithTimeout:(NSTimeInterval)timeout
                connectDeviceMode:(ConnectDeviceMode)mode
                 isDisconnectUart:(BOOL)isDisconnectUart
                       completion:(nullable connectingCallBack) completion;

/*!
 *  恢复上次连接（未用）
 *  @param completion   回调
 */
- (BOOL)recoverLastConnectCompletion:(nullable connectingCallBack)completion;

/*!
 *  恢复连接设备
 *  @param device       -[in] 连接的设备
 */
- (void)recoverConnectDevice:(nullable JCBLEDevice *)device;

/*!
 *  取消连接设备
 */
- (void)cancelConnect;

/*!
 *  断开连接的设备
 */
- (void)disconnectDevice:(JCBLEDevice *)device;

/*!
 *  断开所有外设连接
 */
- (void)disconnectAllDevice;

/*!
 *  进入固件升级状态
 */
- (void)enterUpgrade;

/*!
 *  退出固件升级状态
 */
- (void)exitUpgrade;

/**
 是否进入了固件升级模式
 */
- (BOOL)isUpgradeMode;

/*!
 *  检查所有连接上的设备是否需要升级固件
 */
- (void)checkDeviceFirwareCompletion:(void(^_Nullable)(BOOL isNeed, NSError * _Nullable error))completion;

@end
