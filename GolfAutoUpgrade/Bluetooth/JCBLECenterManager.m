//
//  JCBLECenterManager.m
//  DuoTrac-Ball
//

/*
 *  蓝牙设备管理
 *  多设备版
 */

//  Created by 郭吉成 on 2017/10/30.
//  Copyright © 2017年 KOOSPUR. All rights reserved.
//

#import "JCBLECenterManager.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "JCBLEConfig.h"
#import "JCBLEDataManager.h"
#import "JCDataConvert.h"
#import "JCBLEDevice.h"
//#import "JCError.h"
//#import "JCUser.h"
//#import "DTUserStore.h"

static JCBLECenterManager *_manager;
static CBCentralManager *_myCentralManager;

@interface JCBLECenterManager ()<CBCentralManagerDelegate, JCDeviceDelegate>

@property (nonatomic, weak) JCBLEDataManager *bluetoothDataManager;
@property (nonatomic, strong) NSMutableArray *uartBuffer;
@property (nonatomic, copy) connectingCallBack connectingCompletion;
@property (nonatomic, assign) ConnectDeviceMode connectMode;
@property (nonatomic, strong) NSTimer *connectingTimer;
@property (nonatomic, strong) NSTimer *scanTimer;
@property (nonatomic, strong) NSTimer *reconnectTimer;
@property (nonatomic, assign) BOOL isUpgrade;
@property (nonatomic, assign) BOOL isAutoConnect;
@property (nonatomic, assign) BOOL isEditName;
@property (nonatomic, assign) BOOL timeOut;
@property (nonatomic, copy) void(^checkVersionBlock)(BOOL isNeed, NSError *error);
@property (nonatomic, assign) BOOL isManualDisconnect;

@end

@implementation JCBLECenterManager

#pragma mark 【1】创建单例蓝牙管理中心
+ (JCBLECenterManager *)shareCBCentralManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[JCBLECenterManager alloc]init];
        _myCentralManager = [[CBCentralManager alloc] initWithDelegate:_manager queue:nil];
        _manager.bluetoothDataManager = [JCBLEDataManager shareBluetoothData];
        _manager.uartArray = [NSMutableArray array];
        _manager.uartBuffer = [NSMutableArray array];
    });
    return _manager;
}

- (CBCentralManager *)centerManager{
    
    return _myCentralManager;
}

#pragma mark 【2】监测蓝牙状态
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state){
        case CBCentralManagerStateUnknown:
            self.bluetoothState = BluetoothOpenStateIsClosed;
            break;
        case CBCentralManagerStateUnsupported:
            self.bluetoothState = BluetoothOpenStateIsClosed;
            break;
        case CBCentralManagerStateUnauthorized:
            self.bluetoothState = BluetoothOpenStateIsClosed;
            break;
        case CBCentralManagerStatePoweredOff:{
            self.bluetoothState = BluetoothOpenStateIsClosed;
            if ([self.delegate respondsToSelector:@selector(bluetoothStateChange:state:)]) {
                [self.delegate bluetoothStateChange:self state:BluetoothOpenStateIsClosed];
            }
        }
            break;
        case CBCentralManagerStateResetting:
            self.bluetoothState = BluetoothOpenStateIsClosed;
            break;
        case CBCentralManagerStatePoweredOn:{
            self.bluetoothState = BluetoothOpenStateIsOpen;
            if ([self.delegate respondsToSelector:@selector(bluetoothStateChange:state:)]) {
                [self.delegate bluetoothStateChange:self state:BluetoothOpenStateIsOpen];
            }
        }
            break;
    }
}

#pragma mark 【3】发现外部设备
- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI{
    
    JCBLEDevice *device = [self creatDeviceWithdidDiscoverPeripheral:peripheral
                                                   advertisementData:advertisementData
                                                                RSSI:RSSI];
    if (device && self.delegate && [self.delegate respondsToSelector:@selector(foundPeripheral:device:)]) {
        [self.delegate foundPeripheral:self device:device];
    }
}

/**
 创建device模型、过滤device
 */
- (JCBLEDevice *)creatDeviceWithdidDiscoverPeripheral:(CBPeripheral *)peripheral
                                    advertisementData:(NSDictionary *)advertisementData
                                                 RSSI:(NSNumber *)RSSI{
    
    NSData *manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey];
    
    NSString *pid = [self getPIDWithManufaturerData:manufacturerData];
    OemType oemtype = [self filterWithPid:pid];
    NSString *mac = [self getMacWithManufaturerData:manufacturerData];
    JCBLEDevice *bleDevice;
    if (oemtype == OemTypeGolfDT2 ||
        oemtype == OemTypeGolfDT3 ||
        oemtype == OemTypeGolfDT4 ||
        oemtype == OemTypeGolfBall) {
        bleDevice = [JCBLEDevice UARTWith:peripheral
                        advertisementData:advertisementData
                                  oemtype:oemtype
                               macAddress:mac
                                  andRSSI:RSSI];
    }
    return bleDevice;
}

/**
 按Mac地址匹配连接
 */
- (void)connectDevice:(JCBLEDevice *)device withMacDictionary:(NSDictionary *)macDictionary{
    for (NSString *key in macDictionary.allKeys) {
        NSString *macString = macDictionary[key];
        NSString *deviceMac = device.macAddr;
        BOOL isEqua = NO;
        if ([deviceMac isEqualToString:macString]) {
            isEqua = YES;
            [self connectDevice:device];
        }
    }
}

/**
 连接device
 */
- (void)connectDevice:(JCBLEDevice *)device{
    
    if (![_uartBuffer containsObject:device]) {
        [_uartBuffer addObject:device];
    }
    device.delegate = self;

    NSString *type = @"未知";
    if (device.oemtype == OemTypeGolfBall) {
        type = @"高尔夫 - 球";
    }else if (device.oemtype == OemTypeGolfDT2){
        type = @"高尔夫 - DT2";
    }else if (device.oemtype == OemTypeGolfDT3){
        type = @"高尔夫 - DT3";
    }else if (device.oemtype == OemTypeGolfDT4){
        type = @"高尔夫 - DT4";
    }
    NSLog(@"连接\n--> %@--> %@\n--> mac:%@\n--> oemtype:%@",device.name,device.RSSI,device.macAddr,type);
    [self connectToPeripheral:device.peripheral];
    if ([self.delegate respondsToSelector:@selector(bluetoothManager:didConectingPeripheral:)]) {
        [self.delegate bluetoothManager:self didConectingPeripheral:device];
    }
}

#pragma mark 【4】连接外部蓝牙设备
- (void)connectToPeripheral:(CBPeripheral *)peripheral{
    if (!peripheral) {
        return;
    }
    [_myCentralManager connectPeripheral:peripheral options:nil];
}

/*!
 *  连接到外设蓝牙（JCBLEDevice）
 *  @param device -[in] 要连接的外设
 */
- (void)connectToDevice:(nullable JCBLEDevice *)device
             completion:(nullable connectingCallBack) completion{
//    device.delegate = self;
//    device.peripheral.delegate = device;
    [self connectToPeripheral:device.peripheral];
//    self.connectingCompletion = completion;
//    self.connectingTimer = [NSTimer scheduledTimerWithTimeInterval:kDeviceConnectOutTime
//                                                            target:self
//                                                          selector:@selector(connectSensorTimeOut)
//                                                          userInfo:nil
//                                                           repeats:NO];
}

- (void)connectSensorTimeOut{
    if (self.connectingCompletion) {
        self.connectingCompletion(NO);
    }
    [self.connectingTimer invalidate];
    self.connectingTimer = nil;
}

#pragma mark 【5】连接外部蓝牙设备成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    [peripheral discoverServices:nil];//寻找服务
}

#pragma mark - 设备回调查找 服务及特征结束 Delegate
- (void)foundCharacterSuccess:(JCBLEDevice *)device{
    if (self.connectingCompletion) {
        self.connectingCompletion(YES);
        [self.connectingTimer invalidate];
        self.connectingTimer = nil;
        self.connectingCompletion = nil;
    }
}
#pragma mark 【6】连接外部蓝牙设备失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    if ([self.delegate respondsToSelector:@selector(bluetoothManager:didFailConectPeripheral:)]) {
        [self.delegate bluetoothManager:self didFailConectPeripheral:nil];
    }
}

#pragma mark 【7】蓝牙外设连接断开，自动重连
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
    if (_isUpgrade || _isEditName || _isManualDisconnect) {
        _isManualDisconnect = NO;
        return;
    }

    ///断开连接
    [[NSNotificationCenter defaultCenter] postNotificationName:kDeviceDisconnect
                                                        object:nil
                                                      userInfo:nil];
    //正常连接时，出现断连
    if (self.state == DeviceConnectStateConnected ||
        self.state == DeviceConnectStateRecover) {
     
        if (peripheral) {
            NSLog(@"\n\n断开与%@的连接，正在重连...\n\n",peripheral.name);
            self.state = DeviceConnectStateRecover;
            [self connectToPeripheral:peripheral];
//            _reconnectTimer = [self startObserveRecoverConnect];
//            [[NSNotificationCenter defaultCenter] postNotificationName:kDeviceDisconnectRecover
//                                                                object:nil
//                                                              userInfo:nil];
        }
    }
    else{
        self.state = DeviceConnectStateIDE;
        if ([self.delegate respondsToSelector:@selector(bluetoothManager:didDisconnectPeripheral:error:)]) {
            [self.delegate bluetoothManager:self didDisconnectPeripheral:peripheral error:error];
        }
    }
}

#pragma mark - 重连设备超时处理
//重连超时
- (NSTimer *)startObserveRecoverConnect{
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:kDeviceDisconnectRecoverTime
                                                      target:self
                                                    selector:@selector(disconnetOutTime:)
                                                    userInfo:nil
                                                     repeats:NO];
    return timer;
}
//超时处理
- (void)disconnetOutTime:(NSTimer *)timer{
    [_reconnectTimer invalidate];
    _reconnectTimer = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:kReconnectOutTime
                                                        object:nil
                                                      userInfo:nil];
    [self disconnectAllDevice];
    NSLog(@"\n\n重连超时失败！\n\n");
}

#pragma mark 【8】重新扫描外设
- (void)reScan{
    
    for (JCBLEDevice *device in _uartArray) {
        [self disConnectToPeripheral:device.peripheral];
    }
    [_uartArray removeAllObjects];
    
    if (_scanTimer) {
        [_scanTimer invalidate];
        _scanTimer = nil;
    }
    _scanTimer = [NSTimer scheduledTimerWithTimeInterval:kScanTime
                                                  target:self
                                                selector:@selector(scanSensor)
                                                userInfo:nil
                                                 repeats:YES];
}
- (void)scanSensor{
    [_myCentralManager scanForPeripheralsWithServices:nil
                                              options:@{CBCentralManagerScanOptionAllowDuplicatesKey:[NSNumber numberWithBool:NO]}];
}
- (void)onlyStartScan{
    if (_scanTimer) {
        [_scanTimer invalidate];
        _scanTimer = nil;
    }
    _scanTimer = [NSTimer scheduledTimerWithTimeInterval:kScanTime
                                                  target:self
                                                selector:@selector(scanSensor)
                                                userInfo:nil
                                                 repeats:YES];
}
#pragma mark 停止扫描外设
- (void)stopScan{
    if (_scanTimer) {
        [_scanTimer invalidate];
        _scanTimer = nil;
    }
    [_myCentralManager stopScan];
    self.state = DeviceConnectStateIDE;
    for (JCBLEDevice *device in _uartArray) {
        [self disConnectToPeripheral:device.peripheral];
    }
    [_uartArray removeAllObjects];
    [_uartBuffer removeAllObjects];
}
- (void)onlyStopScan{
    if (_scanTimer) {
        [_scanTimer invalidate];
        _scanTimer = nil;
    }
    [_myCentralManager stopScan];
    [_uartBuffer removeAllObjects];
}
#pragma mark 断开外设连接
- (void)disConnectToPeripheral:(CBPeripheral *)peripheral{
    [_myCentralManager cancelPeripheralConnection:peripheral];
}

/*!
 *  获取设备
 *  @param deviceType       -[in] 需要获取的设备类型
 *  return                  获取到的设备
 */
- (JCBLEDevice *)getDeviceForDeviceType:(OemType)deviceType{
    JCBLEDevice *device;
    for (JCBLEDevice *bleDevice in self.uartArray) {
        if (bleDevice.oemtype == deviceType) {
            device = bleDevice;
        }
    }
    return device;
}

/*!
 *  获取当前连接的设备
 *  return                  获取到的设备
 */
- (NSArray *)getConnectDevice{
    
    return [_myCentralManager retrieveConnectedPeripheralsWithServices:@[[CBUUID UUIDWithString:kServiceUUID]]];
}

/*!
 *  连接设备 + 超时处理 + 连接模式
 *  @param timeout       -[in] 连接超时时间
 *  @param mode          -[in] 连接模式
 *  @param completion    回调
 */
- (void)connectSensorsWithTimeout:(NSTimeInterval)timeout
                connectDeviceMode:(ConnectDeviceMode)mode
                 isDisconnectUart:(BOOL)isDisconnectUart
                       completion:(nullable connectingCallBack) completion {
    _isAutoConnect = NO;
    _state = DeviceConnectStateScanning;
    if (isDisconnectUart) {
        [self reScan];
    }else{
        [self onlyStartScan];
    }
    
    self.connectingTimer = [NSTimer scheduledTimerWithTimeInterval:timeout
                                                            target:self
                                                          selector:@selector(stopConnecting:)
                                                          userInfo:nil
                                                           repeats:NO];
    self.connectingCompletion = completion;
    self.connectMode = mode;
}

/*!
 *  恢复上次连接
 */
//- (BOOL)recoverLastConnectCompletion:(nullable connectingCallBack)completion{

//    if ([self getUserDeviceMac:[JCUser currentUser]]) {
//
//        _state = DeviceConnectStateScanning;
//        _isAutoConnect = YES;
//
//        [self reScan];
//
//        self.connectingTimer = [NSTimer scheduledTimerWithTimeInterval:kAutoConnectTimeLimit
//                                                                target:self
//                                                              selector:@selector(stopConnecting:)
//                                                              userInfo:nil
//                                                               repeats:NO];
//        self.connectingCompletion = completion;
//        return YES;
//    }else{
//        completion(NO);
//        return NO;
//    }
//}

/*!
 *  取消连接设备
 */
//- (void)cancelConnect{
//    
//    if (self.connectingTimer) {
//        [self.connectingTimer invalidate];
//        self.connectingTimer = nil;
//    }
//    self.connectingCompletion = nil;
//    [self disconnectAllDevice];
//    [self onlyStopScan];
//}

/**
 恢复连接设备
 */
//- (void)recoverConnectDevice:(JCBLEDevice *)device{
//    [self connectToPeripheral:device.peripheral];
//}

/**
 停止连接
 */
- (void)stopConnecting:(NSTimer *)timer{
    
    [self onlyStopScan];
    self.connectingCompletion(NO);
    self.connectingCompletion = nil;
}

/*!
 *  断开连接的设备
 */
- (void)disconnectDevice:(JCBLEDevice *)device{
//    _isManualDisconnect = YES;
    [self disConnectToPeripheral:device.peripheral];
//    [_uartArray removeObject:device];
}

/*!
 *  断开所有连接的设备
 */
- (void)disconnectAllDevice{
    self.state = DeviceConnectStateIDE;
    self.connectingCompletion = nil;
    for (JCBLEDevice *device in _uartArray) {
        [self disConnectToPeripheral:device.peripheral];
    }
    [_uartArray removeAllObjects];
}

/*!
 *  进入更改设备名字模式 是/否
 */
- (void)enterEditNameMode:(BOOL)isEnter{
    _isEditName = isEnter;
}

/*!
 *  进入固件升级状态
 */
- (void)enterUpgrade{

    _isUpgrade = YES;
    _state = DeviceConnectStateIDE;
}

/*!
 *  退出固件升级状态
 */
- (void)exitUpgrade{
    _isUpgrade = NO;
    [self disconnectAllDevice];
    _myCentralManager.delegate = self;
}

/**
 是否进入了固件升级模式
 */
- (BOOL)isUpgradeMode{
    return _isUpgrade;
}

/**
 过滤pid
 */
- (OemType)filterWithPid:(NSString *)pid{

    if ([pid isEqualToString:@"G002"]){
        return OemTypeGolfDT2;
    }else if ([pid isEqualToString:@"G003"]){
        return OemTypeGolfDT3;
    }else if ([pid isEqualToString:@"G004"]){
        return OemTypeGolfDT4;
    }else if ([pid isEqualToString:@"G005"]){
        return OemTypeGolfBall;
    }
    return OemTypeUnknown;
}

/**
 解析PID
 */
- (NSString *)getPIDWithManufaturerData:(NSData *)manufaturerData{
    
    if (manufaturerData.length < 4) {
        return nil;
    }
    const u_int8_t *bytes = [manufaturerData bytes];
    Byte pidBytes[4];
    for (NSInteger i = 0; i < 4; i++) {
        if (i < 4) {
            pidBytes[i] = bytes[i];
        }
    }
    pidBytes[0] = bytes[1];
    pidBytes[1] = bytes[0];
    NSString *pid = [[NSString alloc] initWithData:[[NSData alloc] initWithBytes:pidBytes length:4] encoding:NSUTF8StringEncoding];
    return pid;
}

/**
 解析mac地址
 */
- (NSString *)getMacWithManufaturerData:(NSData *)manufaturerData {
    if (manufaturerData.length < 10) {
        return nil;
    }
    NSData *macData = [manufaturerData subdataWithRange:NSMakeRange(4, 6)];
    NSString *mac = [JCDataConvert convertHexToString:macData];
    return mac;
}


/**
 保存mac地址
 */
//- (void)saveMac:(NSString *)mac forKey:(NSString *)key user:(DTUser *)user{
//    
//    [[NSUserDefaults standardUserDefaults] setObject:mac forKey:[NSString stringWithFormat:@"%@%@",user.ID,key]];
//    [[NSUserDefaults standardUserDefaults] synchronize];
//}

/**
 保存全部mac地址
 */
//- (void)saveCurrentMac{
//    for (JCBLEDevice *device in _uartArray) {
//        NSString *key;
//        if (device.oemtype == OemTypeGolfG02) {
//            key = DT2_MAC;
//        }
//        else if (device.oemtype == OemTypeGolfG03) {
//            key = DT3_MAC;
//        }
//        else if (device.oemtype == OemTypeGolfG04) {
//            key = DT4_MAC;
//        }
//        [self saveMac:device.macAddr forKey:key user:[[DTUserStore sharedInstance] currentUser]];
//    }
//}

/**
 获取用户对应的mac地址
 */
//- (NSDictionary *)getUserDeviceMac:(JCUser *)user{
//
//    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
//    NSString *ballMac = [ud objectForKey:[NSString stringWithFormat:@"%@%@",user.userID,BALL_MAC]];
//    NSString *putterMac = [ud objectForKey:[NSString stringWithFormat:@"%@%@",user.userID,PUTTER_MAC]];
//    if (!ballMac || !putterMac) {
//        return nil;
//    }
//    NSDictionary *dic = @{BALL_MAC : ballMac,
//                          PUTTER_MAC : putterMac};
//    return dic;
//}

/*!
 *  检查所有连接上的设备是否需要升级固件
 */
//- (void)checkDeviceFirwareCompletion:(void(^)(BOOL isNeed, NSError *error))completion{
//
//    __block BOOL need = NO;
//    __block NSInteger readCount = 0;
//    __block NSTimer *timer;
//    _timeOut = NO;
//    _checkVersionBlock = completion;
//
//    timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(checkVersionTimeOut) userInfo:nil repeats:NO];
//
//    if (_timeOut){
//        return;
//    }
//
//    NSString *needVersion;

//    if (_device.version) {
//        needVersion = _device.version;
//        readCount++;
//        if ([self isNeedUpgradeVersion:_device.version targetVersion:_device.serverVersion]) {
//            need = YES;
//            _device.isNeedUpgrade = YES;
//            NSLog(@"%@需要升级。 当前固件：%@ 最新固件：%@",_device.name,needVersion,_device.serverVersion);
//        }
//
//        if (readCount >= 3) {
//            completion(need,nil);
//            if (timer) {
//                [timer invalidate];
//                timer = nil;
//            }
//        }
//    }
//    else{
//        [_device getVersionComplete:^(RequestDeviceDataState state, JCBLEDevice *device, NSString *version) {
//            readCount++;
//
//            if ([self isNeedUpgradeVersion:device.version targetVersion:device.serverVersion]) {
//                need = YES;
//                device.isNeedUpgrade = YES;
//                NSLog(@"%@需要升级。 当前固件：%@ 最新固件：%@",device.name,device.version,device.serverVersion);
//            }
//
//            if (readCount >= 3) {
//                completion(need,nil);
//                if (timer) {
//                    [timer invalidate];
//                    timer = nil;
//                }
//            }
//        }];
//    }
//}

//- (void)checkVersionTimeOut{
//    _timeOut = YES;
//    if (_checkVersionBlock) {
//        _checkVersionBlock(NO,[NSError errorWithDomain:@"版本检测超时" code:-1]);
//    }
//}

/**
 判断版本
 @param     currentVersion  当前版本
 @param     targetVersion   目标版本
 @return    bool            是否更新
 */
- (BOOL)isNeedUpgradeVersion:(NSString *)currentVersion targetVersion:(NSString *)targetVersion{
    /* NSOrderedAscending = -1  升序
     * NSOrderedSame = 0        相等
     * NSOrderedDescending      降序
     */
    NSString *_currentVersion = [currentVersion stringByReplacingOccurrencesOfString:@"v" withString:@""];
    NSString *_targetVersion = [targetVersion stringByReplacingOccurrencesOfString:@"v" withString:@""];
    BOOL isNeedUpgrade = NO;
    NSInteger result = (long)[_currentVersion compare:_targetVersion options:NSCaseInsensitiveSearch];
    if (result == -1) {
        isNeedUpgrade = YES;
    }
    //    NSLog(@"*********************%@",isNeedUpgrade?@"需要升级":@"不需要升级");
    return isNeedUpgrade;
}

@end
