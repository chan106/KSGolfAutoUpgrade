//
//  BluetoothConfiguration.h
//  Victor
//
//  Created by 郭吉成 on 2017/10/30.
//  Copyright © 2017年 KOOSPUR. All rights reserved.
//

#ifndef JCBLEConfig_h
#define JCBLEConfig_h

#define         kFilterRSSI                        20//过滤的信号值
///正常连接超时时间
#define         kDeviceConnectOutTime              5
///自动连接设备超时时间
#define         kAutoConnectTimeLimit              10
///扫描外设频率
#define         kScanTime                          1
///重连超时时间
#define         kDeviceDisconnectRecoverTime       5
#define         kRebootTimeOut                     10
#define         kNormalTimeOut                     5

#pragma mark - 蓝牙服务及特性
#define     kServiceUUID        @"0001"
#define     kWriteUUID          @"0002"
#define     kNotifyUUID         @"0003"
#define     kReadMacUUID        @"0004"

#define     BALL_MAC                               @"BALL_MAC"
#define     PUTTER_MAC                             @"PUTTER_MAC"


#pragma mark - 蓝牙指令
#define         FH                                 @"A8" //指令帧头
/*-=-=-=-=-=-=-=控制指令-=-=-=-=-=-=-=*/
#define         APP_COMMAND_SHUTDOWN               @"01" //关机
#define         APP_COMMAND_RESET                  @"02" //重启
#define         APP_COMMAND_CLEAR_DATA             @"03" //清除数据
#define         APP_COMMAND_FACTORY_RESET          @"04" //恢复出厂
#define         APP_COMMAND_UPDATE_FIRMWARE        @"05" //固件升级
/*-=-=-=-=-=-=-=设置指令-=-=-=-=-=-=-=*/
#define         APP_COMMAND_TIMESTAMP_VERIFY       @"11" //时间戳校准
#define         APP_COMMAND_EDIT_DEVICE_NAME       @"12" //设备名修改
#define         APP_COMMAND_SETUP_HANDLE           @"13" //左右手设置 0->右 1->左
/*-=-=-=-=-=-=-=读取指令-=-=-=-=-=-=-=*/
#define         APP_COMMAND_READ_FIRMWARE_REV      @"21" //固件版本读取
#define         APP_COMMAND_READ_BATTERY           @"22" //电池电量读取
#define         APP_COMMAND_READ_MAIN_DATA         @"23" //主界面读取
#define         APP_COMMAND_READ_REAL_DATA         @"24" //实时数据读取
#define         APP_COMMAND_READ_ACTION_DETAIL     @"25" //动作详情读取
#define         APP_COMMAND_READ_SWING_WEIGHT      @"26" //挥重测量读取
#define         APP_COMMAND_READ_3D_DATA           @"27" //3D轨迹读取
#define         APP_COMMAND_READ_FACTORY_INFO      @"28" //生产信息读取

#define         kReconnectOutTime                  @"reconnectFail"///重连超时
#define         kDeviceDisconnectRecover           @"deviceDisconnectRecover"///恢复连接
#define         kDeviceDisconnect                  @"deviceDisconnect"///断开链接
#define         kConnectDevice                     @"didConnectDevice"///连接成功


#endif /* BluetoothConfiguration_h */
