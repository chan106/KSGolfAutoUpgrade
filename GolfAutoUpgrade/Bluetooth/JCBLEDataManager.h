//
//  JCBluetoothData.h
//  Zebra

//  蓝牙数据处理

//  Created by 郭吉成 on 2017/10/30.
//  Copyright © 2017年 KOOSPUR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "JCBLEEnum.h"

@interface JCBLEDataManager : NSObject

+ (JCBLEDataManager *)shareBluetoothData;

/**
 处理数据 
 */
+ (void)dealRecieveData:(NSData *)data
                 device:(JCBLEDevice*)device
             deviceType:(OemType)deviceType
               complete:(GetBluetoothDataComplete)complete;

/**
 处理数据
 */
- (void)dealRecieveData:(NSData *)data
                 device:(JCBLEDevice*)device
             deviceType:(OemType)deviceType
               complete:(GetBluetoothDataComplete)complete;

- (void)dealRealTimeSwingData:(NSData *)data
                       device:(JCBLEDevice *)device;

@end
