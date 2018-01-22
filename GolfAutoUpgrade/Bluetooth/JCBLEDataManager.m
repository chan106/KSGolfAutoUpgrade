//
//  JCBluetoothData.m
//  Zebra
//
//  Created by 郭吉成 on 2017/10/30.
//  Copyright © 2017年 KOOSPUR. All rights reserved.
//

#import "JCBLEDataManager.h"
#import "JCBLECenterManager.h"
#import "JCBLEDevice.h"
#import "JCDataConvert.h"
#import "JCBLEConfig.h"

static JCBLEDataManager *_bluetoothData;

@interface JCBLEDataManager ()

@property (nonatomic, strong) NSMutableArray *allStatisticArray;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, assign) NSInteger threeDStartIndex;
@property (nonatomic, assign) NSInteger threeDEndIndex;
@end

@implementation JCBLEDataManager

#pragma mark - 创建单例蓝牙数据模型
+ (JCBLEDataManager *)shareBluetoothData{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _bluetoothData = [JCBLEDataManager new];
        _bluetoothData.allStatisticArray = [NSMutableArray arrayWithCapacity:10];
    });
    return _bluetoothData;
}

/*!
 *@处理接收到的数据信息
 *@param   data        待处理data数据
 *@param   complete    处理完后的回调
 */
-(void)dealRecieveData:(NSData *)data
                device:(JCBLEDevice *)device
            deviceType:(OemType)deviceType
              complete:(GetBluetoothDataComplete)complete{
    
    //校验数据，丢弃不合法数据
    if([self verifyData:data]){
        [self dealData:data device:device deviceType:deviceType complete:complete];
    }
}

+ (void)dealRecieveData:(NSData *)data
                 device:(JCBLEDevice*)device
             deviceType:(OemType)deviceType
               complete:(GetBluetoothDataComplete)complete{
    
    JCBLEDataManager *dataManager = [JCBLEDataManager shareBluetoothData];
    
    //校验数据，丢弃不合法数据
    if ([dataManager verifyData:data]) {
        [dataManager dealData:data device:device deviceType:deviceType complete:complete];
    }
}

#pragma mark - 处理数据
/*!
 *@处理接收到的【有效数据】
 */
- (void)dealData:(NSData *)data
          device:(JCBLEDevice*)device
      deviceType:(OemType)deviceType
        complete:(GetBluetoothDataComplete)complete{
    //    NSLog(@" \n <<<--- 读取到%@的数据：%@",device.name,data);
    const u_int8_t *bytes = [data bytes];
    NSInteger respondType = bytes[1];
    
    switch (respondType) {
            //关机
        case RespondTypeShutdown:{
            [self shutDown:device complete:complete];
        }
            break;
            
            //重启
        case RespondTypeRest:{
            [self reboot:device complete:complete];
        }
            break;
            
            //缓存清理
        case RespondTypeClearData:{
            [self clearCache:device complete:complete];
        }
            break;
            
            //恢复出厂
        case RespondTypeFactoryRest:{
            [self recover:device complete:complete];
        }
            break;
            
            //固件升级
        case RespondTypeUpdateFirmware:{
            [self upgrade:device complete:complete];
        }
            break;
            
            //时间戳校准
        case RespondTypeTimestampVerify:{
            [self timestampCalibration:device complete:complete];
        }
            break;
            
            //修改设备名
        case RespondTypeEditDeviceName:{
            NSLog(@"修改设备名：%@",data);
            [self editDeviceName:device complete:complete];
        }
            break;
            
            //设置左右手
        case RespondTypeSetupHandle:{
            [self setHandle:device complete:complete];
        }
            break;
            
            //固件版本号
        case RespondTypeFirmwareRev:{
            [self getVersion:device validData:data complete:complete];
        }
            break;
            
            //电池电量
        case RespondTypeBattery:{
            [self getBattery:device validData:data complete:complete];
        }
            break;
            
            //主界面所有数据
        case RespondTypeMainData:{
            [self getMainData:device validData:data complete:complete];
        }
            break;
            
            //动作详情
        case RespondTypeSwingInfo:{
            [self getSwingInfo:device validData:data complete:complete];
        }
            break;
            
            //实时挥杆数据
        case RespondTypeRealData:{
            [self getRealData:device data:data deviceType:deviceType complete:complete];
        }
            break;
            //3D挥杆数据
        case RespondType3DData:{
            [self get3DData:device data:data complete:complete];
        }
            break;
            //3D生产信息
        case RespondTypeFactoryInfo:{
            [self getFactoryInfo:device data:data complete:complete];
        }
            break;
            
        default:
            break;
    }
}

/*!
 *关机
 */
- (void)shutDown:(JCBLEDevice *)device
        complete:(GetBluetoothDataComplete)completion{
    NSLog(@"%@ -- > 关机",device.name);
    if (completion) {
        completion( device, RespondTypeShutdown, @"shutDown");
    }
}

/*!
 *重启
 */
- (void)reboot:(JCBLEDevice *)device
      complete:(GetBluetoothDataComplete)completion{
    NSLog(@"%@ -- > 重启",device.name);
    if (completion) {
        completion(device, RespondTypeRest, @"reset");
    }
}

/*!
 *缓存清理
 */
- (void)clearCache:(JCBLEDevice *)device
          complete:(GetBluetoothDataComplete)completion{
    NSLog(@"%@ -- > 清理缓存",device.name);
    if (completion) {
        completion(device, RespondTypeClearData, @"clear");
    }
}

/*!
 *恢复出厂
 */
- (void)recover:(JCBLEDevice *)device
       complete:(GetBluetoothDataComplete)completion{
    NSLog(@"%@ -- > 恢复出厂",device.name);
    if (completion) {
        completion(device, RespondTypeFactoryRest, @"factoryRest");
    }
}

/*!
 *固件升级
 */
- (void)upgrade:(JCBLEDevice *)device
       complete:(GetBluetoothDataComplete)completion{
    NSLog(@"%@ -- > 固件升级",device.name);
    if (completion) {
        completion(device, RespondTypeUpdateFirmware, @"updateFirware");
    }
}

/*!
 *时间戳校准
 */
- (void)timestampCalibration:(JCBLEDevice *)device
                    complete:(GetBluetoothDataComplete)completion{
    NSLog(@"%@ -- > 时间戳校准",device.name);
    if (completion) {
        completion(device, RespondTypeTimestampVerify, @"timestamp");
    }
}

/*!
 *设置左右手
 */
- (void)setHandle:(JCBLEDevice *)device
         complete:(GetBluetoothDataComplete)completion{
    NSLog(@"%@ -- > 设置左右手",device.name);
    if (completion) {
        completion(device, RespondTypeSetupHandle, nil);
    }
}

/*!
 *修改设备名
 */
- (void)editDeviceName:(JCBLEDevice *)device
              complete:(GetBluetoothDataComplete)completion{
    NSLog(@"%@ -- > 改设备名",device.name);
    if (completion) {
        completion(device, RespondTypeEditDeviceName, @"editDeviceName");
    }
}

/*!
 *读取固件版本号
 */
- (void)getVersion:(JCBLEDevice *)device
         validData:(NSData *)validData
          complete:(GetBluetoothDataComplete)completion{
    validData = [validData subdataWithRange:NSMakeRange(2, 15)];
    NSString *rev = [[NSString alloc] initWithData:validData encoding:NSUTF8StringEncoding];
    NSLog(@"%@ -- > 固件版本号:%@",device.name,rev);
    //    [JCDataHelper firmwareVersion:rev];//保存版本号
    if (completion) {
        completion(device, RespondTypeFirmwareRev, rev);
    }
}

/*!
 *读取电池电量
 */
- (void)getBattery:(JCBLEDevice *)device
         validData:(NSData *)validData
          complete:(GetBluetoothDataComplete)completion{
    NSInteger power = [JCDataConvert toInteger:[validData subdataWithRange:NSMakeRange(2, 1)]];
    if (power <= 20) {
    }
    if (completion) {
        completion(device, RespondTypeBattery, @(power));
    }
}

/*!
 *读取主页数据
 */
- (void)getMainData:(JCBLEDevice *)device
          validData:(NSData *)data
           complete:(GetBluetoothDataComplete)completion{
    //    NSLog(@"主页数据：---> %@",data);
    [self dealMainDetailData:data complete:^(id obj) {
        if (completion) {
            completion(device, RespondTypeMainData, obj);
        }
    }];
}

/*!
 *读取动作详情
 */
- (void)getSwingInfo:(JCBLEDevice *)device
           validData:(NSData *)data
            complete:(GetBluetoothDataComplete)completion{
    const u_int8_t *bytes = [data bytes];
    NSInteger stempNumber = bytes[2];
    ///创建数据
    if (stempNumber == 1) {
        if (completion) {
        }
    }
    ///结束当天数据详情传输
    else if (stempNumber == 2){
        if (completion) {
        }
    }
}

/*!
 *读取实时数据
 */
- (void)getRealData:(JCBLEDevice *)device
               data:(NSData *)data
         deviceType:(OemType)deviceType
           complete:(GetBluetoothDataComplete)completion{
    if ([JCBLECenterManager shareCBCentralManager].state != DeviceConnectStateConnected) {
        return;
    }
}

/*!
 *读取3D数据
 */
- (void)get3DData:(JCBLEDevice *)device
             data:(NSData *)data
         complete:(GetBluetoothDataComplete)completion{
    
    if ([JCBLECenterManager shareCBCentralManager].state != DeviceConnectStateConnected) {
        return;
    }
    
    const u_int8_t *bytes = [data bytes];
    NSInteger type = bytes[2];
    
    if (type == 0) {//应答3D指令
        completion(device, RespondType3DData, @"enter3DSuccess");
        self.threeDStartIndex = 0;
        self.threeDEndIndex = 0;
    }else if(type == 1){//完成3D挥拍
    }else if (type == 2){//3D详细数据
    }else if (type == 3){//完成数据返回
        completion(device, RespondType3DData, @"finish3D");
        self.threeDStartIndex = 0;
        self.threeDEndIndex = 0;
    }
}
#pragma mark - 主页数据
/*!
 *主界面数据处理
 */
- (void)dealMainDetailData:(NSData *)data complete:(completeCallBack)complete{
    
    const u_int8_t *bytes = [data bytes];
    NSInteger stepNumber = bytes[2];
    
    ///-->1.传输开始
    if (stepNumber == 1) {
        NSInteger time = bytes[3]*256 + bytes[4];
        //判断时间是否合理 2015年以后的数据有效 数组中第一个data 含有时间戳
        if (time < 16500) {//时间节点设为2015年
            NSLog(@"不合理时间戳：%ld",time);
            return;
        }
        //创建统计数据模型
        NSString *date = [self timeWithTimeIntervalString:86400 * time];
    }
}

/*!
 *生产信息
 */
- (void)getFactoryInfo:(JCBLEDevice *)device
                  data:(NSData *)data
              complete:(GetBluetoothDataComplete)completion{
    
    if ([JCBLECenterManager shareCBCentralManager].state != DeviceConnectStateConnected) {
        return;
    }
    
    const u_int8_t *bytes = [data bytes];
    device.PCBVersion = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(2, 4)] encoding:kCFStringEncodingUTF8];
    NSMutableString * reverseString = [NSMutableString string];
    for(int i = 0 ; i < device.PCBVersion.length; i ++){
        //倒序读取字符并且存到可变数组数组中
        unichar c = [device.PCBVersion characterAtIndex:device.PCBVersion.length- i -1];
        [reverseString appendFormat:@"%c",c];
    }
    device.PCBVersion = reverseString;
    device.productionBatch = bytes[6]*16777216 +bytes[7]*65536 +bytes[8]*256 +bytes[9];
    device.burnTimestamp = bytes[10]*16777216 +bytes[11]*65536 +bytes[12]*256 +bytes[13];
    if (completion) {
        completion(device,RespondTypeFactoryInfo,nil);
    }
}
///正负数转换
- (NSInteger)converHexWithHighByte:(Byte)hightByte lowByte:(Byte)lowByte{
    
    BOOL isPositive = hightByte & (0x01 << 7)?NO:YES;//判断符号位
    if (isPositive) {//正数
        return (hightByte * 256 + lowByte);
    }
    else{//负数
        hightByte = hightByte ^ 0xff;
        lowByte = lowByte ^ 0xff;;
        return -((hightByte *256 + lowByte)+1);
    }
}

#pragma mark - 校验数据
/*!
 *校验数据
 *@return   是否合法
 */
- (BOOL)verifyData:(NSData *)data{
    
    if (data.length<20) {
        return NO;
    }
    
    const u_int8_t *bytes = [data bytes];
    
    if (bytes[1] == 39 && bytes[2] == 2) {//3D详细数据，无校验和
        return YES;
    }
    
    NSUInteger checkSum = bytes[19];
    NSInteger functionSum = bytes[1];
    NSUInteger dataSum = [JCDataConvert toInteger:[data subdataWithRange:NSMakeRange(2, data.length - 3)]];
    NSInteger caculSum = (168 + functionSum + dataSum)%256;
    
    if ([[data subdataWithRange:NSMakeRange(0, 1)]isEqualToData:[JCDataConvert hexToBytes:FH]] &&
        checkSum == caculSum){
        return YES;
    }
    return NO;
}

- (NSString *)timeWithTimeIntervalString:(NSInteger)timestamp{
    //    return [NSDate timeWithTimeIntervalString:timestamp];
    return @"";
}

- (dispatch_queue_t)queue{
    
    if (_queue == nil) {
        NSString *indetify = @"dealSwingQueue";
        const char *label = [indetify UTF8String];
        _queue = dispatch_queue_create(label, DISPATCH_QUEUE_SERIAL);
    }
    return _queue;
}

@end
