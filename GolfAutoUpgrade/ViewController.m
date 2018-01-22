//
//  ViewController.m
//  GolfPowerOff
//
//  Created by 郭吉成 on 2017/11/17.
//  Copyright © 2017年 KOOSPUR. All rights reserved.
//

#import "ViewController.h"
#import "JCBLE.h"
#import "DeviceTableViewCell.h"
#import "UpdateFirwareVC.h"
#import "WebRequest.h"
#import <AudioToolbox/AudioToolbox.h>

#define DT2 2
#define DT3 3
#define DT4 4
#define BALL 5
#define kConnectCount 0

#define kScanDeviceTime 10
#define kConnectTime 10

#define SuguePushUpgradeVC @"pushUpgradeVC"

@interface ViewController ()<JCMultiBLEManagerDelegate,UITableViewDataSource,UITableViewDelegate,JCDeviceDelegate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *searchItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *stopItem;
@property (weak, nonatomic) IBOutlet UISlider *rssiSlider;
@property (weak, nonatomic) IBOutlet UILabel *rssiSliderLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *oemButtons;
@property (weak, nonatomic) IBOutlet UILabel *powerOffLabel;
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;

@property (strong, nonatomic) JCBLECenterManager *BLEManager;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *searchLoading;
@property (strong, nonatomic) JCBLEDevice *device;

@property (assign, nonatomic) NSInteger oemTypeR;
@property (strong, nonatomic) NSTimer *scanTimer;

@property (assign, nonatomic) BOOL isUpgradeComplete;

@property (assign, nonatomic) NSInteger totalCount;

@property (strong, nonatomic) NSString *dt2FilePath;
@property (strong, nonatomic) NSString *dt3FilePath;
@property (strong, nonatomic) NSString *dt4FilePath;
@property (strong, nonatomic) NSString *ballFilePath;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _BLEManager = [JCBLECenterManager shareCBCentralManager];
    _BLEManager.delegate = self;
    _oemTypeR = 0;
    [self loadFirmware];
}

- (void)loadFirmware{
    __weak typeof(self)weakSelf = self;
    [JCWebDataRequst uploadFirwareWithOemtype:@"IOS"
                                isCompressZIP:YES
                              downLoadProress:^(float progress) {
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      NSLog(@"------------>> %f",progress);
                                      _stateLabel.text = [NSString stringWithFormat:@"下载固件...%.0f%%",progress*100];
                                  });
                              } complete:^(NSArray *firwares, NSError *error) {
                                  weakSelf.stateLabel.text = @"固件下载完成!";
                                  for (NSString *filePath in firwares) {
                                      weakSelf.searchItem.enabled = YES;
                                      if ([filePath containsString:@"DT2"]) {
                                          weakSelf.dt2FilePath = filePath;
                                      }else if ([filePath containsString:@"DT3"]) {
                                          weakSelf.dt3FilePath = filePath;
                                      }else if ([filePath containsString:@"DT4"]) {
                                          weakSelf.dt4FilePath = filePath;
                                      }else if ([filePath containsString:@"BALL"]) {
                                          weakSelf.ballFilePath = filePath;
                                      }
                                  }
                              }];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //屏幕常亮
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

/**
 OEM选择
 */
- (IBAction)oemSelectAction:(UIButton *)sender {
    // |3  |2  |1  |0   |
    // |DT2|DT3|DT4|BALL|
    sender.selected = !sender.selected;
    switch (sender.tag) {
        case DT2:
        {
            if (sender.selected == YES) {
                _oemTypeR |= 0x08;
            }else{
                _oemTypeR ^= 0x08;
            }
            NSLog(@" --- - >  %lx",(long)_oemTypeR);
        }
            break;
        case DT3:
        {
            if (sender.selected == YES) {
                _oemTypeR |= 0x04;
            }else{
                _oemTypeR ^= 0x04;
            }
            NSLog(@" --- - >  %lx",(long)_oemTypeR);
        }
            break;
        case DT4:
        {
            if (sender.selected == YES) {
                _oemTypeR |= 0x02;
            }else{
                _oemTypeR ^= 0x02;
            }
            NSLog(@" --- - >  %lx",(long)_oemTypeR);
        }
            break;
        case BALL:
        {
            if (sender.selected == YES) {
                _oemTypeR |= 0x01;
            }else{
                _oemTypeR ^= 0x01;
            }
            NSLog(@" --- - >  %lx",(long)_oemTypeR);
        }
            break;
            
        default:
            break;
    }
}

/**
 调节信号
 */
- (IBAction)rssiSliderAction:(UISlider *)sender {
    _rssiSliderLabel.text = [NSString stringWithFormat:@"信号调节：%ld",(NSInteger)(sender.value * 100)];
}

/**
 搜索设备
 */
- (IBAction)searchAction:(UIBarButtonItem *)sender {
    if (!_oemTypeR) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"至少选择一种 OEM " preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    [self searchDevice];
    _searchItem.enabled = NO;
    _stopItem.enabled = YES;
    _rssiSlider.userInteractionEnabled = NO;
    for (UIButton *button in _oemButtons) {
        button.userInteractionEnabled = NO;
    }
}

/**
 停止操作
 */
- (IBAction)stopAction:(UIBarButtonItem *)sender {
    if (_scanTimer) {
        [_scanTimer invalidate];
        _scanTimer = nil;
    }
    
    if (_device) {
        [_BLEManager disconnectDevice:_device];
        _device = nil;
    }
    
    _isUpgradeComplete = NO;

    [self stopSearchDevice];
    _stopItem.enabled = NO;
    _searchItem.enabled = YES;
    _rssiSlider.userInteractionEnabled = YES;
    for (UIButton *button in _oemButtons) {
        button.userInteractionEnabled = YES;
    }
}

#pragma mark -- JCMultiBLEManagerDelegate
/*!
 *  蓝牙未开启 - 提醒
 */
- (void)bluetoothStateChange:(JCBLECenterManager *)manager
                       state:(BluetoothOpenState)openState{
    if (BluetoothOpenStateIsClosed == openState) {
        _device = nil;
        [self.tableView reloadData];
    }
    else{
    }
}

/*!
 *  发现蓝牙设备
 */

-(void)foundPeripheral:(JCBLECenterManager *)manager device:(JCBLEDevice *)device{
    //过滤信号
    int rssi = abs(device.RSSI.intValue);
    if (rssi > (_rssiSlider.value * 100)) {
        return;
    }
    //过滤OEM
    if (device.oemtype == OemTypeGolfDT2 && (!((_oemTypeR & 0x08) >> 3))) {
        return;
    }else if (device.oemtype == OemTypeGolfDT3 && (!((_oemTypeR & 0x04) >> 2))) {
        return;
    }else if (device.oemtype == OemTypeGolfDT4 && (!((_oemTypeR & 0x02) >> 1))) {
        return;
    }else if (device.oemtype == OemTypeGolfBall && (!((_oemTypeR & 0x01) >> 0))) {
        return;
    }
    
    _device = device;
    [self refreshDeviceList];
}

/*!
 *  蓝牙连接成功
 */
- (void)bluetoothManager:(JCBLECenterManager *)manager didSucceedConectPeripheral:(CBPeripheral *)peripheral//连接成功
{
    [self.tableView reloadData];
}

#pragma mark -- UITableViewDatasource
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section{
    return _device?1:0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    DeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeviceTableViewCell" forIndexPath:indexPath];
    [cell setDevice:_device];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/**
 开始搜索
 */
- (void)searchDevice{
    [_BLEManager onlyStartScan];
    [_searchLoading startAnimating];
    _stateLabel.text = @"开始扫描...";
    //扫描 -> 连接时间
    if (_scanTimer) {
        [_scanTimer invalidate];
        _scanTimer = nil;
    }
    _scanTimer = [NSTimer scheduledTimerWithTimeInterval:kScanDeviceTime repeats:NO block:^(NSTimer * _Nonnull timer) {
        NSLog(@"\n 扫描超时，重新扫描...");
        _stateLabel.text = @"扫描超时，重新扫描...";
        [_BLEManager onlyStartScan];
    }];
}

/**
 停止搜索
 */
- (void)stopSearchDevice{
    _stateLabel.text = @"停止搜索";
    [_BLEManager onlyStopScan];
    [_searchLoading stopAnimating];
    [_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    
}

/**
 刷新列表
 */
- (void)refreshDeviceList{
    [_tableView reloadData];
    [_scanTimer invalidate];
    _scanTimer = nil;
    [_BLEManager onlyStopScan];
    [self connectAllDevice];
}


/**
 连接所有设备
 */
- (void)connectAllDevice{
    if (_device == nil) {
        //无设备，重新开始扫描
        _stateLabel.text = @"未检测到设备，3秒后重新开始扫描...";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self reStartCycle];
        });
        return;
    }
    _device.delegate = self;
    _device.peripheral.delegate = _device;
    [_BLEManager connectToDevice:_device completion:nil];
}

- (void)foundCharacterSuccess:(JCBLEDevice *)device{
    if (_isUpgradeComplete) {
        _isUpgradeComplete = NO;
        _stateLabel.text = @"重连成功、执行关机操作...";
        [_device shutDownComplete:^(RequestDeviceDataState state, JCBLEDevice *device, NSError *error) {
            [_BLEManager disconnectDevice:_device];
            _device = nil;
            [_tableView reloadData];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //重新开始搜索
                _stateLabel.text = @"已关关机,重新搜索设备...";
                [self searchAction:nil];
            });
        }];
    }else{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"\n升级 -- %@",device.name);
            _stateLabel.text = @"升级设备...";
            _totalCount++;
            _powerOffLabel.text = [NSString stringWithFormat:@"已升级数：%ld",_totalCount];
            [self performSegueWithIdentifier:SuguePushUpgradeVC sender:nil];
        });
    }
}

- (void)reStartCycle{
    _stateLabel.text = @"重新扫描中...";
    if (_device) {
        [_BLEManager disconnectDevice:_device];
        _isUpgradeComplete = NO;
    }
    [self searchAction:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:SuguePushUpgradeVC]) {
        UpdateFirwareVC *vc = [segue destinationViewController];
        vc.device = _device;
        if (vc.device.oemtype == OemTypeGolfDT2) {
            vc.filePath = self.dt2FilePath;
        }else if (vc.device.oemtype == OemTypeGolfDT3) {
            vc.filePath = self.dt3FilePath;
        }else if (vc.device.oemtype == OemTypeGolfDT4) {
            vc.filePath = self.dt4FilePath;
        }else if (vc.device.oemtype == OemTypeGolfBall) {
            vc.filePath = self.ballFilePath;
        }
        vc.back = ^(){
            NSLog(@"升级完成！！！！！！！");
            _isUpgradeComplete = YES;
            _device.delegate = self;
            _device.peripheral.delegate = _device;
            _BLEManager.delegate = self;
            _BLEManager.centerManager.delegate = _BLEManager;
            _stateLabel.text = @"升级完成、重连设备...";
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [_BLEManager connectToDevice:_device completion:^(BOOL connectState) {
                    
                }];
            });
        };
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
