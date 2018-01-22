//
//  JCBlutoothInfoModel.m
//  Turing
//
//  Created by 郭吉成 on 2017/10/30.
//  Copyright © 2017年 KOOSPUR. All rights reserved.
//

#import "JCBLEDevice.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "JCBLEConfig.h"
#import "JCBLECenterManager.h"
#import "JCBLEDataManager.h"
#import "JCDataConvert.h"
#import <AudioToolbox/AudioToolbox.h>
//#import "JCThreeDModeItem.h"
//#import "JCUserManager.h"
//#import "NSDate+FormateString.h"
//#import "JCDataHelper.h"
//#import "JCRealTimeData.h"
//#import "JCError.h"

@interface JCBLEDevice ()

@property (nonatomic, copy) GetBluetoothDataComplete complete;

@property (nonatomic, strong) CBCharacteristic *readCharacteristic;     //读取数据特性
@property (nonatomic, strong) CBCharacteristic *writeCharacteristic;    //写数据特性
@property (nonatomic, strong) CBCharacteristic *readMACCharacteristic;  //读取mac地址特性

@property (nonatomic, copy) DeviceShutDownComplete shutDownComplete;//关闭设备
@property (nonatomic, copy) DeviceRebootComplete rebootComplete;//重启设备
@property (nonatomic, copy) ClearDataComplete clearDataComplete;//清除数据
@property (nonatomic, copy) DeviceUpgradeComplete readMacAddressComplete;//读取mac地址
@property (nonatomic, copy) DeviceRecoverComplete recoverComplete;//恢复出厂
@property (nonatomic, copy) DeviceUpgradeComplete upgradeComplete;//固件升级
@property (nonatomic, copy) DeviceEditNameComplete editNameComplete;//设备名修改
@property (nonatomic, copy) DeviceSetHandleNameComplete setHandleComplete;//左右手设置

@property (nonatomic, copy) GetDeviceVersionComplete getVersionComplete;//读取固件版本
@property (nonatomic, copy) GetDeviceBaterryComplete getBatteryComplete;//读取电池电量
@property (nonatomic, copy) GetDeviceFactoryInfoComplete getFactoryInfoComplete;//读取生产信息
@property (nonatomic, strong) NSTimer *getFactoryTimer;//读取生产信息Timer

@property (nonatomic, copy) GetDeviceMainDataComplete getMainDataComplete;///主页数据
@property (nonatomic, copy) GetDeviceSwingInfoComplete getSwingInfoComplete;///动作详情
@property (nonatomic, assign) NSInteger dateIndex;
@property (nonatomic, assign) NSInteger swingCount;
@property (nonatomic, assign) NSInteger alreadyCount;
@property (nonatomic, strong) NSMutableArray *swingInfoBuffer;

@property (nonatomic, copy) GetDeviceRealDataComplete getRealDataComplete;//实时数据

@property (nonatomic, copy) void(^getRealDataState)(BOOL);//实时数据获取状态
@property (nonatomic, copy) void (^get3DDataState)(BOOL);//3D数据获取状态
@property (nonatomic, copy) ThreeDSwingGeneralResultBlock threeDSwingGeneralResultBlock;//3D数据
@property (nonatomic, copy) ThreeDModeItemBlock threeDModeItemBlock;//3D数据详情
@property (nonatomic, copy) void (^finish3DDataRecieve)(BOOL);//3D数据是否接收完成
@property (nonatomic, strong) NSTimer *enter3DTimer;
@property (nonatomic, strong) NSTimer *finish3DTimer;

@property (nullable, nonatomic, copy) NSString *editingName;
@property (nullable, nonatomic, strong) NSTimer *editNameTimer;

@property (nonatomic, assign) BOOL isReboot;
@property (nonatomic, strong) NSTimer *rebootTimer;

@end

@implementation JCBLEDevice

+(instancetype)UARTWith:(CBPeripheral *)peripheral
      advertisementData:(NSDictionary *)advertisementData
                oemtype:(OemType)oemtype
             macAddress:(NSString *)macAddress
                andRSSI:(NSNumber *)RSSI{
    
    JCBLEDevice *uart = [JCBLEDevice new];
    uart.peripheral = peripheral;
    uart.name = peripheral.name;
    uart.oemtype = oemtype;
    uart.macAddr = macAddress;
    uart.RSSI = RSSI;
    uart.advertisementData = advertisementData;
    uart.swingInfoBuffer = [NSMutableArray array];
    peripheral.delegate = uart;
    return uart;
}

#pragma mark 【1】寻找蓝牙服务
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    
    if(error){
        NSLog(@"外围设备寻找服务过程中发生错误，错误信息：%@",error.localizedDescription);
    }
    NSLog(@"%@---> 查找服务",_name);
    CBUUID *serviceUUID=[CBUUID UUIDWithString:kServiceUUID];
    for (CBService *service in peripheral.services) {
        
        if([service.UUID isEqual:serviceUUID]){
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:kNotifyUUID],[CBUUID UUIDWithString:kWriteUUID],[CBUUID UUIDWithString:kReadMacUUID]] forService:service];
        }
    }
}

#pragma mark 【2】寻找蓝牙服务中的特性
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {//报错直接返回退出
        NSLog(@"didDiscoverCharacteristicsForService error : %@", [error localizedDescription]);
        return;
    }
    NSLog(@"%@---> 查找特性",_name);
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kNotifyUUID]]){
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            self.readCharacteristic = characteristic;
        }
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kWriteUUID]]) {
            self.writeCharacteristic = characteristic;
        }
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kReadMacUUID]]) {
            self.readMACCharacteristic = characteristic;
        }
    }
    self.name = peripheral.name;
    if (_readCharacteristic && _writeCharacteristic) {
        self.state = CBPeripheralStateConnected;
        NSLog(@"%@---> 查找成功！",_name);
        if ([self.delegate respondsToSelector:@selector(foundCharacterSuccess:)]) {
            [self.delegate foundCharacterSuccess:self];
        }
        if (_isReboot) {
            if (self.rebootComplete) {
                self.rebootComplete(RequestDeviceDataStateSuccess,self,nil);
                self.rebootComplete = nil;
            }
            _isReboot = NO;
            [_rebootTimer invalidate];
            _rebootTimer = nil;
        }
    }
}

#pragma mark 【3】直接读取特征值被更新后
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    __weak __typeof(self) weakSelf = self;
    
    if (error) {
        NSLog(@"更新特征值时发生错误，错误信息：%@",error.localizedDescription);
        return;
    }
    
    if (characteristic.value) {
        //数据
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kNotifyUUID]]) {
//            NSLog(@"********蓝牙数据：%@",characteristic.value);
            [JCBLEDataManager dealRecieveData:characteristic.value
                                       device:weakSelf
                                   deviceType:weakSelf.oemtype
                                     complete:^(JCBLEDevice *device, RespondType respondType, id obj) {
                                         switch (respondType) {
                                                 //关机
                                             case RespondTypeShutdown:{
                                                 if (weakSelf.shutDownComplete) {
                                                     weakSelf.shutDownComplete(RequestDeviceDataStateSuccess, weakSelf, nil);
                                                     weakSelf.shutDownComplete = nil;
                                                 }
                                             }
                                                 break;
                                                 //重启
                                             case RespondTypeRest:{
//                                                 if (weakSelf.rebootComplete) {
//                                                     weakSelf.rebootComplete(RequestDeviceDataStateSuccess,weakSelf,nil);
//                                                     weakSelf.rebootComplete = nil;
//                                                 }
                                             }
                                                 break;
                                                 //缓存清理
                                             case RespondTypeClearData:{
                                                 if (weakSelf.clearDataComplete) {
                                                     weakSelf.clearDataComplete(RequestDeviceDataStateSuccess,weakSelf,nil);
                                                     weakSelf.clearDataComplete = nil;
                                                 }
                                             }
                                                 break;
                                                 //恢复出厂
                                             case RespondTypeFactoryRest:{
                                                 if (weakSelf.recoverComplete) {
                                                     weakSelf.recoverComplete(RequestDeviceDataStateSuccess, weakSelf, nil);
                                                     weakSelf.recoverComplete = nil;
                                                 }
                                             }
                                                 break;
                                                 //固件升级
                                             case RespondTypeUpdateFirmware:{
                                                 if (weakSelf.upgradeComplete) {
                                                     weakSelf.upgradeComplete(RequestDeviceDataStateSuccess, weakSelf, nil);
                                                     weakSelf.upgradeComplete = nil;
                                                 }
                                             }
                                                 break;
                                                 //时间戳校准
                                             case RespondTypeTimestampVerify:{
                                                 
                                             }
                                                 break;
                                                 //修改设备名
                                             case RespondTypeEditDeviceName:{
                                                 [weakSelf editName];
                                             }
                                                 break;
                                                 //设置左右手
                                             case RespondTypeSetupHandle:{
                                                 if (weakSelf.setHandleComplete) {
                                                     weakSelf.setHandleComplete(RequestDeviceDataStateSuccess, weakSelf, nil);
                                                     weakSelf.setHandleComplete = nil;
                                                 }
                                             }
                                                 break;
                                                 //固件版本号
                                             case RespondTypeFirmwareRev:{
                                                 NSString *rev = obj;
                                                 NSString *version = [[rev componentsSeparatedByString:@"-"] firstObject];
                                                 weakSelf.version = [version substringWithRange:NSMakeRange(1, version.length - 1)];
                                                 if (weakSelf.getVersionComplete) {
                                                     weakSelf.getVersionComplete(RequestDeviceDataStateSuccess, weakSelf, rev);
                                                     weakSelf.getVersionComplete = nil;
                                                 }
                                             }
                                                 break;
                                                 //电池电量
                                             case RespondTypeBattery:{
                                                 weakSelf.power = obj;
                                                 if (self.power.integerValue <= 15) {//电量低，弹框报警 
                                                      AudioServicesPlaySystemSound(1006);
                                                 }
                                                 if (weakSelf.getBatteryComplete) {
                                                     weakSelf.getBatteryComplete(RequestDeviceDataStateSuccess, weakSelf, obj);
                                                     weakSelf.getBatteryComplete = nil;
                                                 }
                                             }break;
                                                 
                                                 ///主界面所有数据（近十天数据）
                                             case RespondTypeMainData:{
                                                 if (weakSelf.getMainDataComplete) {
                                                     weakSelf.getMainDataComplete(obj,nil);
                                                 }
                                             }break;
                                                 
                                                 ///动作详情
                                             case RespondTypeSwingInfo:{
//                                                 if (weakSelf.getSwingInfoComplete) {
//                                                     if ([obj isKindOfClass:[JCSwingDetails class]]) {
//                                                         weakSelf.getSwingInfoComplete(obj,nil);
//                                                     }else{
////                                                         @throw RLMException(@"类型不匹配");
//                                                     }
//                                                 }
                                             }break;
                                                 
                                                 ///实时挥杆数据
                                             case RespondTypeRealData:{
                                                 
                                                 if (weakSelf.getRealDataState && !obj) {
                                                     weakSelf.getRealDataState(YES);
                                                 }
                                                 
                                                 if (weakSelf.getRealDataComplete) {
//                                                     if ([obj isKindOfClass:[JCRealTimeData class]]) {
//                                                         weakSelf.getRealDataComplete(RequestDeviceDataStateSuccess, weakSelf, obj, nil);
//                                                     }else if ([obj isKindOfClass:[NSError class]]){
//                                                         weakSelf.getRealDataComplete(RequestDeviceDataStateSuccess, weakSelf, nil, obj);
//                                                     }
//                                                     weakSelf.getRealDataComplete = nil;
                                                 }
                                             }break;
                                                 
                                                 ///3D数据
                                             case RespondType3DData:{
                                                 [weakSelf deal3DData:device
                                                          respondType:RespondType3DData
                                                                  obj:obj];
                                             }break;
                                                 
                                                 ///生产信息
                                             case RespondTypeFactoryInfo:{
                                                 if (_getFactoryInfoComplete) {
                                                     [_getFactoryTimer invalidate];
                                                     _getFactoryTimer = nil;
                                                     _getFactoryInfoComplete(RequestDeviceDataStateSuccess,
                                                                             device,
                                                                             self.PCBVersion,
                                                                             self.productionBatch,
                                                                             self.burnTimestamp);
                                                 }
                                             }break;
                                                 
                                             default:
                                                 break;
                                         }
            }];
        }
        //mac地址
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:kReadMacUUID]]) {
            self.macAddr = [JCDataConvert convertHexToString:characteristic.value];
            NSLog(@" \n%@的mac地址：%@",peripheral.name,characteristic.value);
            if (self.readMacAddressComplete) {
                self.readMacAddressComplete(RequestDeviceDataStateSuccess, self, nil);
            }
        }
    }
}

- (void)syncTime{
    //发送时间校准
    Byte bytes[4];

    NSDate *date = [NSDate date];
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSTimeInterval time = [zone secondsFromGMTForDate:date];
    NSDate *date1 = [date dateByAddingTimeInterval:time];
    long long timeInterval = [date1 timeIntervalSince1970];
    
    bytes[0] = (Byte)(timeInterval/(256*256*256));
    bytes[1] = (Byte)(timeInterval/(256*256));
    bytes[2] = (Byte)(timeInterval/256);
    bytes[3] = ((Byte)timeInterval)%256;
    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    NSString *valid = [JCDataConvert convertHexToString:data];
    [self sendDataUseCommand:APP_COMMAND_TIMESTAMP_VERIFY validData:valid];
}

//初始化传感器
- (void)initDevice{
    //读取蓝牙mac地址
//    [self readBLEMacAddress];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //发送时间校准
        Byte bytes[4];
        NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
        bytes[0] = (Byte)(timeInterval/(256*256*256));
        bytes[1] = (Byte)(timeInterval/(256*256));
        bytes[2] = (Byte)(timeInterval/256);
        bytes[3] = ((Byte)timeInterval)%256;
        NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
        NSString *valid = [JCDataConvert convertHexToString:data];
        [self sendDataUseCommand:APP_COMMAND_TIMESTAMP_VERIFY validData:valid];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //发送主页数据获取
            [self sendDataUseCommand:APP_COMMAND_READ_MAIN_DATA validData:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //发送电池电量获取
                [self sendDataUseCommand:APP_COMMAND_READ_BATTERY validData:nil];
                //读取蓝牙mac地址
                [self readBLEMacAddress];
            });
        });
    });
    
    //读取电量
    [self sendDataUseCommand:APP_COMMAND_READ_BATTERY validData:nil];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        //读取固件版本
//        [self sendDataUseCommand:APP_COMMAND_READ_FIRMWARE_REV validData:nil];
//    });
}

// 获得对256求模的值
- (Byte)modulusValue:(Byte *)bytes countOfBytes:(NSInteger)size{
    NSUInteger total = 0;
    for (NSInteger index = 0; index < size - 1; index++) {
        total += bytes[index];
    }
    return total % 256;
}

#pragma APP发送指令数据
/*!
 *  通过蓝牙发送 指令+数据 到外设
 *
 *  @param command -[in] 要发送的指令
 *  @param validData -[in] 要发送的数据
 */
- (void)sendDataUseCommand:(nullable NSString *)command
                 validData:(nullable NSString *)validData{
    
    NSString *valid = @"";
    
    if ([command isEqualToString:APP_COMMAND_EDIT_DEVICE_NAME]) {
        valid = [JCDataConvert convertHexToString:[JCDataConvert hexDataFromString:validData]];
    }
    else{
        valid = validData;
    }
    NSData *commandData = [self creatSendDataCommand:command valid:valid];
    [self sendData:commandData];
}

/*!
 *  通过蓝牙发送data数据到外设
 *
 *  @param data -[in] 要发送的data
 */
- (void)sendData:(nullable NSData *)data{
    if (self.peripheral.state == CBPeripheralStateConnected) {
        
        if (!self.readCharacteristic || !self.writeCharacteristic) {
            NSAssert(@"特征值为空", @"特征值为空");
            NSLog(@"%@ - %@ - %@",self.name,_readCharacteristic,_writeCharacteristic);
        }
        else{
            [self.peripheral writeValue:data
                      forCharacteristic:self.writeCharacteristic
                                   type:CBCharacteristicWriteWithResponse];
            NSLog(@" \n ---> 给 %@ 发送的数据：%@",self.name,data);
        }
    }
}

/*!
 *  创建数据
 *  @param command       -[in] 指令
 *  @param validData       -[in] 有效数据
 */
- (NSData *)creatSendDataCommand:(NSString *)command valid:(NSString *)validData{
    
    //拼接帧头+指令+有效数据
    NSString *sendStr = [FH stringByAppendingString:command];
    if (validData != nil) {
        sendStr = [sendStr stringByAppendingString:validData];
    }
    //计算checkSum
    NSUInteger checkSum = 168;
    for (NSInteger i = 0; i < 2; i++) {
        switch (i) {
            case 0:
                checkSum += strtoul([command UTF8String], 0, 16);
                break;
            case 1:
            {
                NSInteger subCheckNum = 0;
                for (NSInteger calcuChekNum = 0; calcuChekNum < validData.length/2.0; calcuChekNum++) {
                    NSString *cutStr = [validData substringWithRange:NSMakeRange(calcuChekNum*2, 2)];
                    subCheckNum += strtoul([cutStr UTF8String], 0, 16);
                }
                
                checkSum += subCheckNum;
            }
                break;
            default:
                break;
        }
    }
    checkSum %= 256;
    NSInteger missNum = 19 - sendStr.length/2.0;
    NSString *checkSumStr = [JCDataConvert toHex:(int)checkSum];
    
    for (NSInteger i = 0; i < missNum; i++) {
        sendStr = [sendStr stringByAppendingString:@"00"];
    }
    
    sendStr = [sendStr stringByAppendingFormat:@"%@",checkSumStr];
    return [JCDataConvert hexToBytes:sendStr];
}

#pragma mark - 发送指令，回调数据
/*!
 *  读取蓝牙mac地址
 */
- (void)readBLEMacAddress{
    if (self.peripheral != nil && self.readMACCharacteristic != nil) {
        [self.peripheral readValueForCharacteristic:self.readMACCharacteristic];
    }
}

/**
 关机
 @params complete   回调
 */
- (void)shutDownComplete:(nullable DeviceShutDownComplete)complete{
    _shutDownComplete = complete;
    [self sendDataUseCommand:APP_COMMAND_SHUTDOWN validData:nil];
}

/**
 重启
 @params complete   回调
 */
- (void)rebootComplete:(nullable DeviceRebootComplete)complete{
    _rebootComplete = complete;
    _isReboot = YES;
    [self sendDataUseCommand:APP_COMMAND_RESET validData:nil];
    _rebootTimer = [NSTimer scheduledTimerWithTimeInterval:kRebootTimeOut target:self selector:@selector(rebootTimeOut) userInfo:nil repeats:NO];
}
///重启超时
- (void)rebootTimeOut{
    if (self.rebootComplete) {
        self.rebootComplete(RequestDeviceDataStateFail,self,nil);
        self.rebootComplete = nil;
    }
    _isReboot = NO;
}

/**
 清除数据
 @params complete   回调
 */
- (void)clearDataComplete:(nullable ClearDataComplete)complete{
    _clearDataComplete = complete;
    [self sendDataUseCommand:APP_COMMAND_CLEAR_DATA validData:nil];
}

/**
 恢复出厂
 @params complete   回调
 */
- (void)recoverComplete:(nullable DeviceRecoverComplete)complete{
    _recoverComplete = complete;
    [self sendDataUseCommand:APP_COMMAND_FACTORY_RESET validData:nil];
}

/**
 固件升级
 @params complete   回调
 */
- (void)upgradeDeviceComplete:(nullable DeviceUpgradeComplete)complete{
    _upgradeComplete = complete;
    NSString *deviceType = @"01";//胜利固件
    NSString *OEM_ID = [NSString stringWithFormat:@"%02ld",self.oemtype];
    [self sendDataUseCommand:APP_COMMAND_UPDATE_FIRMWARE validData:[NSString stringWithFormat:@"%@%@",deviceType,OEM_ID]];
}

/**
 读取MAC地址
 @params complete   回调
 */
- (void)getMacAddressComplete:(nullable DeviceUpgradeComplete)complete{
    _readMacAddressComplete = complete;
    [self readBLEMacAddress];
}

/**
 设备名修改
 @params name       需要修改的设备名
 @params complete   回调
 */
- (void)editName:(nullable NSString *)name Complete:(nullable DeviceEditNameComplete)complete{
    _editNameComplete = complete;
    [self sendDataUseCommand:APP_COMMAND_EDIT_DEVICE_NAME validData:name];
    self.editingName = name;
    ///超时
    _editNameTimer = [NSTimer scheduledTimerWithTimeInterval:kNormalTimeOut target:self selector:@selector(editNameTimeOut) userInfo:nil repeats:NO];
}
///编辑名字超时
- (void)editNameTimeOut{
    if (self.editNameComplete) {
        self.editNameComplete(RequestDeviceDataStateFail, self, nil);
        self.editNameComplete = nil;
    }
    [[JCBLECenterManager shareCBCentralManager] enterEditNameMode:NO];
}

- (void)editName{
    __weak __typeof(self)weakSelf = self;
    [[JCBLECenterManager shareCBCentralManager] enterEditNameMode:YES];
    [[JCBLECenterManager shareCBCentralManager] disConnectToPeripheral:self.peripheral];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[JCBLECenterManager shareCBCentralManager] connectToDevice:self completion:^(BOOL state) {
            if (weakSelf.editNameComplete) {
                weakSelf.editNameComplete(RequestDeviceDataStateSuccess, weakSelf, nil);
                weakSelf.editNameComplete = nil;
            }
            weakSelf.name = weakSelf.editingName;
            [weakSelf.editNameTimer invalidate];
            [[JCBLECenterManager shareCBCentralManager] enterEditNameMode:NO];
        }];
    });
}

/**
 左右手设置
 @params type       需要设置的左右手
 @params complete   回调
 */
- (void)setHandle:(HandleType)type Complete:(nullable DeviceSetHandleNameComplete)complete{
    _setHandleComplete = complete;
    [self sendDataUseCommand:APP_COMMAND_SETUP_HANDLE validData:[JCDataConvert toHex:type]];
}

/**
 读取电量
 @params complete   回调
 */
- (void)getBatteryComplete:(nullable GetDeviceBaterryComplete)complete{
    _getBatteryComplete = complete;
    [self sendDataUseCommand:APP_COMMAND_READ_BATTERY validData:nil];
}

/**
 读取生产信息
 @params complete   回调
 */
- (void)getFactoryInfoComplete:(nullable GetDeviceFactoryInfoComplete)complete{
    _getFactoryInfoComplete = complete;
    if (_getFactoryTimer) {
        [_getFactoryTimer invalidate];
        _getFactoryTimer = nil;
    }
    _getFactoryTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                        target:self
                                                      selector:@selector(getFactoryOutTimer:)
                                                      userInfo:nil
                                                       repeats:NO];
    [self sendDataUseCommand:APP_COMMAND_READ_FACTORY_INFO validData:nil];
}

/**
 读取生产信息超时
 @params timer     读取生产信息定时器
 */
- (void)getFactoryOutTimer:(NSTimer *)timer{
    if (_getFactoryInfoComplete) {
        self.getFactoryInfoComplete(RequestDeviceDataStateSuccess, self, @"未烧录PCB版本的", 0, 0);
        _getFactoryInfoComplete = nil;
        [_getFactoryTimer invalidate];
        _getFactoryTimer = nil;
    }
}

/**
 读取固件版本
 @params complete   回调
 */
- (void)getVersionComplete:(nullable GetDeviceVersionComplete)complete{
    _getVersionComplete = complete;
    [self sendDataUseCommand:APP_COMMAND_READ_FIRMWARE_REV validData:nil];
}

/**
 读取主页数据
 @params complete   回调
 */
- (void)getMainDataComplete:(nullable GetDeviceMainDataComplete)complete{
    _getMainDataComplete = complete;
    [self sendDataUseCommand:APP_COMMAND_READ_MAIN_DATA validData:nil];
}

/**
 读取动作详情数据
 @params complete   回调
 */
-(void)getSwingInfoDate:(NSInteger)date
                  index:(NSInteger)index
               complete:(GetDeviceSwingInfoComplete)complete{
    
    NSLog(@"请求 ：：：：：：：： %ld - %ld",date,index);
    
    _getSwingInfoComplete = complete;
    NSString *dateHex = [JCDataConvert toHex:date];
    NSString *higthHex = [JCDataConvert toHex:index/256];
    NSString *lowHex = [JCDataConvert toHex:index%256];
    NSString *valid = [dateHex stringByAppendingString:[higthHex stringByAppendingString:lowHex]];
    [self sendDataUseCommand:APP_COMMAND_READ_ACTION_DETAIL validData:valid];
}

#pragma mark - 同步硬件数据
- (void)syncSportDataMainComplete:(void (^)(BOOL, NSError *))mainCompletion
                    swingProgress:(void(^)(CGFloat))progress
                   swingCompelete:(void (^)(BOOL, NSError *))swingCompletion{

    __weak __typeof(self) weakSelf = self;
    ///读取主页统计数据
    [self getMainDataComplete:^(NSArray *dateArray, NSError *error) {
        if (dateArray) {
            [weakSelf getSwingWithStatisticArray:dateArray
                                    mainComplete:mainCompletion
                                   swingProgress:progress
                                  swingCompelete:swingCompletion];
        }else if (error){
            NSLog(@"同步主页出错：%@",error);
            if (mainCompletion) {
                mainCompletion(NO,[NSError errorWithDomain:@"" code:-1 userInfo:@{@"info":@"error"}]);
            }
        }
    }];
}

/**
 读取日期数组中所有的日期详情数据
 @params    statisticArray   硬件获取回来的统计数据
 1 --【1】：新用户、新安装的APP,本地未存有连接过的设备mac地址 和 数据：
                只要大于账户创建时间的数据
                保存当前连接设备的mac地址
                保存最新一拍最为断点
 
     【2】：老用户、新安装的APP,本地只有数据：
                只要大于账户创建时间的数据 && 本地未存有时间的数据 && 今天的数据（覆盖替换掉服务器和本地的）
                保存当前连接设备的mac地址
                保存最新一拍为断点
     【3】：正常状态下的用户、本地有连接过的 mac地址、 数据、 断点：
                只要大于账户创建时间的数据 && 本地未存有时间的数据 && 今天的数据（覆盖替换掉服务器和本地的）
                保存当前连接设备的mac地址
                保存最新一拍为断点
 */
- (void)getSwingWithStatisticArray:(NSArray *)statisticArray
                      mainComplete:(void (^)(BOOL, NSError *))mainCompletion
                     swingProgress:(void(^)(CGFloat))progress
                    swingCompelete:(void (^)(BOOL, NSError *))swingCompletion{
    /*
    self.swingCount = 0;
    UserType userType = [[JCUser currentUer] userType];
    NSMutableArray *resultStatisticArray = [NSMutableArray array];
    NSArray *resultArray;///需要的统计模型
    NSInteger creatTimestamp;
    if (kFiltEarlyData == 1) {
        creatTimestamp = [JCUser currentUer].userInfo.createTimestemp;///账号创建日期
    }else{
        creatTimestamp = 17300;
    }
    NSInteger todayTimstamp = [[NSDate new] timeIntervalSince1970] / 86400;
    RLMResults *allHaveStatistic = [JCDailyStatistics allObjects];///数据库中已有的统计模型
    NSString *pointString;///断点
    NSString *lastConnectMac;///上一次使用的mac地址
    ///过滤掉 小于账号创建时间的数据
    for (JCDailyStatistics *statisticItem in statisticArray) {
        NSInteger dateTimestamp = statisticItem.timestamp;
        if (dateTimestamp >= creatTimestamp) {
            [resultStatisticArray addObject:statisticItem];
        }
    }
    resultArray = [resultStatisticArray mutableCopy];
    
    switch (userType) {
            ///只过滤掉 小于账号创建时间的数据
        case UserTypeNewUserNewApp:{
        }
            break;
            ///过滤掉 小于账号创建时间的数据 && 已经有的数据
        case UserTypeOldUserNewApp:{
            for (JCDailyStatistics *statistic in resultArray) {
                NSInteger dateTimestamp = statistic.timestamp;
                BOOL isHave = NO;
                for (JCDailyStatistics *havaStatistic in allHaveStatistic) {
                    NSInteger haveDateTimestamp = havaStatistic.timestamp;
                    if (dateTimestamp == haveDateTimestamp && dateTimestamp != todayTimstamp) {
                        isHave = YES;
                    }
                }
                if (isHave) {
                    [resultStatisticArray removeObject:statistic];
                }
            }
        }
            break;
            ///过滤掉 小于账号创建时间的数据 && 已经有的数据
        case UserTypeNormal:{
            pointString = [JCUser currentUer].syncSwingString;
            lastConnectMac = [JCUser currentUer].lastConnectMac;
            for (JCDailyStatistics *statistic in resultArray) {
                NSInteger dateTimestamp = statistic.timestamp;
                BOOL isHave = NO;
                for (JCDailyStatistics *havaStatistic in allHaveStatistic) {
                    NSInteger haveDateTimestamp = havaStatistic.timestamp;
                    if (dateTimestamp == haveDateTimestamp && dateTimestamp != todayTimstamp) {
                        isHave = YES;
                    }
                }
                if (isHave) {
                    [resultStatisticArray removeObject:statistic];
                }
            }
        }
            break;
        case UserTypeError:{
            NSCAssert(nil, @"同步数据获取账户类型错误！");
        }
            break;
        default:
            break;
    }
    resultArray = [resultStatisticArray mutableCopy];
    [resultStatisticArray removeAllObjects];
    
    for (JCDailyStatistics *item in statisticArray) {
        NSLog(@"硬件传来的日期：%@",item.date);
    }
    for (JCDailyStatistics *item in resultArray) {
        NSLog(@"需要的日期：%@",item.date);
    }
    NSLog(@"断点时间：%@\n上一次连接的Mac:%@",pointString,lastConnectMac);
    
#pragma mark - 到此、需要同步的数据，已经筛选出来，将统计数据存于数据库
    NSMutableArray *resultDateArray = [NSMutableArray array];
    RLMRealm *realm = [RLMRealm defaultRealm];
    ///判断是否切换了设备（本地未保存MAC地址时，默认为切换了设备，需要将重新同步今天的数据）
    BOOL isChangeDevice = lastConnectMac?[lastConnectMac isEqualToString:self.macAddr]?NO:YES : YES;
    BOOL isNeedClear;
    [realm beginWriteTransaction];
    for (JCDailyStatistics *item in resultArray) {
        JCDailyStatistics *temp = [JCDailyStatistics objectForPrimaryKey:item.primaryKey];
        if (temp) {
            ///无断点 && 无Mac && 日期为今天
            ///切换了设备 && 日期为今天   需要清空今日的挥拍详情
            if ((pointString == nil &&  lastConnectMac == nil && temp.timestamp == todayTimstamp)
                || (isChangeDevice && temp.timestamp == todayTimstamp)){
                isNeedClear = YES;
            }else{
                isNeedClear = NO;
            }
            [temp copyFrom:item realm:realm needClearSwingArry:isNeedClear];
        }else{
            [[JCUser currentUer].sportRecordArray addObject:item];
        }
        [resultDateArray addObject:item.date];
    }
    [realm commitWriteTransaction];
    for (JCDailyStatistics *item in resultArray) {
        self.swingCount += item.swingTotal;
    }
    ///无断点、无Mac的
    ///切换了设备的同步（都是从头开始重新同步）
    NSLog(@"\n\n------->>>>> %@\n",isChangeDevice?@"切换了设备":@"没有切换设备");
    if ((pointString == nil && lastConnectMac == nil) || isChangeDevice) {
        [self syncSwingInfoDataWithDateArray:resultDateArray
                                   dateIndex:0
                                  swingIndex:0
                                  swingCount:self.swingCount
                               swingProgress:progress
                              swingCompelete:swingCompletion];
    }
    ///有断点,有Mac,未切换设备的，直接取出断点，正常同步
    else{
        ///断点的拍数序号
        NSInteger swingIndex;
        if (pointString.length < 10) {
            swingIndex = 0;
        }else{
            swingIndex = [[pointString componentsSeparatedByString:@"-"].lastObject integerValue];
        }
        [self syncSwingInfoDataWithDateArray:resultDateArray
                                   dateIndex:0
                                  swingIndex:swingIndex
                                  swingCount:self.swingCount
                               swingProgress:progress
                              swingCompelete:swingCompletion];
    }
    if (mainCompletion) {
        mainCompletion(YES,nil);
    }
     */
}

/**
 全部同步 || 断点续传
 */
- (void)syncSwingInfoDataWithDateArray:(NSArray *)dateArray
                             dateIndex:(NSInteger)dateIndex
                            swingIndex:(NSInteger)swingIndex
                            swingCount:(NSInteger)swingCount
                         swingProgress:(void(^)(CGFloat))progress
                        swingCompelete:(void (^)(BOOL, NSError *))swingCompletion{
    
    /*
    ///同步完成
    if (dateIndex >= dateArray.count) {
        self.dateIndex = 0;
        if (swingCompletion) {
            swingCompletion(YES,nil);
        }
        JCUser *user = [JCUser currentUer];
        JCDailyStatistics *item = [JCDailyStatistics statisticWithDateString:dateArray.firstObject];
        ///保存断点
        [user updateSyncSwingString:[NSString stringWithFormat:@"%@-%ld",item.date,item.swingTotal]];
        [[RLMRealm defaultRealm] beginWriteTransaction];
        ///保存MAC地址
        user.lastConnectMac = self.macAddr;
        [[RLMRealm defaultRealm] commitWriteTransaction];
        [self uploadToServer:dateArray];
        return;
    }
    
    self.dateIndex = dateIndex;
    __weak __typeof(self) weakSelf = self;
    JCDailyStatistics *item = [JCDailyStatistics statisticWithDateString:dateArray[self.dateIndex]];
    
    [self getSwingInfoDate:item.timestamp
                     index:swingIndex
                  complete:^(JCSwingDetails *racketItem, NSError *error){
        ///单天数据传输完成
        if (racketItem.number == -10086) {
            NSLog(@"单天传输至本地完成-%@",item.date);
            [[RLMRealm defaultRealm] transactionWithBlock:^{
                for (JCSwingDetails *saveItem in weakSelf.swingInfoBuffer) {
                    JCSwingDetails *DBItem = [JCSwingDetails objectForPrimaryKey:saveItem.primaryKey];
                    if (DBItem) {
                        [DBItem copyDataFrom:saveItem];///如果存在，则复制数据
                        NSLog(@"!!!已存在%@，复制数据",DBItem.primaryKey);
                    }else{
                        [item.racketDetailArray addObject:saveItem];///不存在，保存数据
                    }
                }
            }];
            [weakSelf.swingInfoBuffer removeAllObjects];
            
            if (weakSelf.dateIndex < dateArray.count) {
                weakSelf.dateIndex++;
                [weakSelf syncSwingInfoDataWithDateArray:dateArray
                                               dateIndex:weakSelf.dateIndex
                                              swingIndex:0
                                              swingCount:swingCount
                                           swingProgress:progress
                                          swingCompelete:swingCompletion];
            }else{
                weakSelf.dateIndex = 0;
            }
        }
        ///数据传输中
        else if (item.swingTotal != 0) {
            weakSelf.alreadyCount++;
            CGFloat progressValue = weakSelf.alreadyCount / (float)swingCount;
            [weakSelf.swingInfoBuffer addObject:racketItem];//缓存挥拍数据
            if (progress) {
                progress(progressValue);
            }
        }
    }];
     */
}

/**
 上传数据至服务器
 */
- (void)uploadToServer:(NSArray *)dateArray{
    
    /*
    [JCWebDataRequst addSportRecordDailyTotal:dateArray
                                       andMac:self.macAddr
                                      oemtype:[self oemtypeString]
                                     complete:^(WebRespondType respondType, id result) {
        if (respondType == WebRespondTypeSuccess) {
            NSLog(@"上传成功");
        }
    }];
     */
}

- (NSString *)oemtypeString{
    NSString *oemtyString = [NSString stringWithFormat:@"v%ld",self.oemtype];
    return oemtyString;
}

/**
 读取实时数据
 @params complete   回调
 */
- (void)getRealDataState:(void(^)(BOOL)) realTimeState
                complete:(nullable GetDeviceRealDataComplete)complete{
    [JCBLECenterManager shareCBCentralManager].isEnterReal = YES;
    _getRealDataComplete = complete;
    _getRealDataState = realTimeState;
    if (self.oemtype == OemTypeGolfDT2) {
        [self sendDataUseCommand:APP_COMMAND_READ_REAL_DATA validData:@"0001"];
    }else{
        [self sendDataUseCommand:APP_COMMAND_READ_REAL_DATA validData:nil];
    }
}

/**
 退出读取实时数据
 */
- (void)quitRealMode{
    [JCBLECenterManager shareCBCentralManager].isEnterReal = NO;
    [self sendDataUseCommand:APP_COMMAND_READ_REAL_DATA validData:@"FF"];
    _getRealDataState = nil;
    _getRealDataComplete = nil;
}

/**
 获取3D数据
 */
- (void)get3DDataWithCompletionBlock:(void (^)(BOOL))completionBlock
       threeDSwingGeneralResultBlock:(ThreeDSwingGeneralResultBlock)threeDSwingGeneralResultBlock
                 threeDModeItemBlock:(ThreeDModeItemBlock)threeDModeItemBlock
              finishReceiveItemBlock:(void (^)(BOOL))finishReceiveItemBlock{
    self.get3DDataState = completionBlock;
    self.threeDSwingGeneralResultBlock = threeDSwingGeneralResultBlock;
    self.threeDModeItemBlock = threeDModeItemBlock;
    self.finish3DDataRecieve = finishReceiveItemBlock;
    [self sendDataUseCommand:APP_COMMAND_READ_3D_DATA validData:nil];
    self.enter3DTimer = [NSTimer scheduledTimerWithTimeInterval:kNormalTimeOut target:self selector:@selector(enter3DTimeOut) userInfo:nil repeats:NO];
}
- (void)enter3DTimeOut{
    [self.enter3DTimer invalidate];
    self.enter3DTimer = nil;
    if (self.get3DDataState) {
        self.get3DDataState(NO);
        self.get3DDataState = nil;
    }
}

- (void)deal3DData:(JCBLEDevice *)device
       respondType:(RespondType)type
               obj:(id)obj{
    
    __weak __typeof(self)weakSelf = self;
    
    if ([obj isKindOfClass:[NSString class]]) {
        if ([obj isEqualToString:@"enter3DSuccess"] && self.get3DDataState) {
            self.get3DDataState(YES);
            [self.enter3DTimer invalidate];
            self.enter3DTimer = nil;
        }
        else if ([obj isEqualToString:@"finish3D"] && self.finish3DDataRecieve){
            self.finish3DDataRecieve(YES);
            [self.finish3DTimer invalidate];
            self.finish3DTimer = nil;
            [self sendDataUseCommand:APP_COMMAND_READ_3D_DATA validData:@"04"];
        }
    }
    else{
        //超时处理
        if (self.finish3DTimer == nil) {
            self.finish3DTimer = [NSTimer scheduledTimerWithTimeInterval:kNormalTimeOut target:self selector:@selector(finish3DTimeOut) userInfo:nil repeats:NO];
        }
        //完成挥拍
        /*
        if ([obj isKindOfClass:[JCThreeDItem class]] && self.threeDSwingGeneralResultBlock) {
            self.threeDSwingGeneralResultBlock(YES,obj);
        //3D详细数据
        }else if ([obj isKindOfClass:[JCThreeDModeItem class]] && self.threeDModeItemBlock){
            self.threeDModeItemBlock(obj);
        }
         */
    }
}

- (void)finish3DTimeOut{
    [self.finish3DTimer invalidate];
    self.finish3DTimer = nil;
    if (self.finish3DDataRecieve) {
        self.finish3DDataRecieve(NO);
        self.finish3DDataRecieve = nil;
        self.threeDSwingGeneralResultBlock = nil;
        self.threeDModeItemBlock = nil;
    }
}

/**
 退出3D模式
 */
- (void)quit3DMode{
    [self sendDataUseCommand:APP_COMMAND_READ_3D_DATA validData:@"04"];
    [self.enter3DTimer invalidate];
    self.enter3DTimer = nil;
    [self.finish3DTimer invalidate];
    self.finish3DTimer = nil;
    self.threeDModeItemBlock = nil;
    self.threeDSwingGeneralResultBlock = nil;
    self.get3DDataState = nil;
    self.finish3DDataRecieve = nil;
}

/**
 连接状态
 @return state      连接状态
 */
- (CBPeripheralState)state{
    return self.peripheral.state;
}

- (void)dealloc{
//    NSLog(@"释放设备- > %@",self.name);
}


/*!
 *  通过蓝牙发送 指令+数据 到外设
 *
 *  @param command -[in] 要发送的指令
 *  @param validData -[in] 要发送的数据
 */
#pragma APP发送指令数据
- (void)sendDataUseCommand:(nullable NSString *)command
                 validData:(nullable NSString *)validData
                  complete:(DeviceUpgradeComplete)complete{
    
    NSString *valid = @"";
    
    if ([command isEqualToString:APP_COMMAND_EDIT_DEVICE_NAME]) {
        valid = [JCDataConvert convertHexToString:[JCDataConvert hexDataFromString:validData]];
    }
    else{
        valid = validData;
    }
    NSData *commandData = [self creatSendDataCommand:command valid:valid];
    [self sendData:commandData];
    self.upgradeComplete = complete;
}
@end
