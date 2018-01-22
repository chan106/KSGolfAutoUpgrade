//
//  UpdateFirwareVC.m
//  Golf-Test
//
//  Created by Guo.JC on 17/4/11.
//  Copyright © 2017年 coollang. All rights reserved.
//

#import "UpdateFirwareVC.h"
#import "WSProgressHUD.h"
#import "JCBLE.h"
#import "WebRequest.h"
#import <AudioToolbox/AudioToolbox.h>

@import iOSDFULibrary;

#define IS_SRVC_CHANGED_CHARACT_PRESENT 1

@interface UpdateFirwareVC ()<LoggerDelegate, DFUProgressDelegate, DFUServiceDelegate>
@property (weak, nonatomic) IBOutlet UILabel *deviceName;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;

@end

@implementation UpdateFirwareVC


- (void)viewDidLoad {
    [super viewDidLoad];
    _deviceName.text = _device.name;
    [self startAction:nil];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //屏幕常亮
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

//开始固件升级
- (IBAction)startAction:(UIButton *)sender {
    
    sender.enabled = NO;
    _progressLabel.text = @"开始升级";
    
    NSString *valid;
    if (_device.oemtype == OemTypeGolfDT2) {
        valid = @"0A0002";
    }
    else if (_device.oemtype == OemTypeGolfDT3) {
        valid = @"0A0003";
    }
    else if (_device.oemtype == OemTypeGolfDT4) {
        valid = @"0A0004";
    }
    else if (_device.oemtype == OemTypeGolfBall) {
        valid = @"0A0005";
    }
    NSLog(@"\n升级文件：-->>>>%@<<<<--\n",_filePath);
    [_device sendDataUseCommand:APP_COMMAND_UPDATE_FIRMWARE
                      validData:valid
                       complete:^(RequestDeviceDataState state, JCBLEDevice *device, NSError *error) {
                           if (state == RequestDeviceDataStateSuccess) {
                               dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                   _progress.progress = 0;
                                   DFUFirmware *selectedFirmware = [[DFUFirmware alloc] initWithUrlToZipFile:[NSURL fileURLWithPath:_filePath]];
                                   
                                   DFUServiceInitiator *initiator = [[DFUServiceInitiator alloc] initWithCentralManager:[JCBLECenterManager shareCBCentralManager].centerManager target:_device.peripheral];
                                   [initiator withFirmware:selectedFirmware];
                                   // Optional:
                                   // initiator.forceDfu = YES/NO; // default NO
                                   // initiator.packetReceiptNotificationParameter = N; // default is 12
                                   initiator.logger = self; // - to get log info
                                   initiator.delegate = self; // - to be informed about current state and errors
                                   initiator.progressDelegate = self; // - to show progress bar
                                   // initiator.peripheralSelector = ... // the default selector is used
                                   DFUServiceController *controller = [initiator start];
                               });
                           }
                       }];
}

- (void)logWith:(enum LogLevel)level message:(NSString *)message{
 
    
    NSString *levelString;
    switch (level) {
        case LogLevelDebug:
        {
            levelString = @"Debug";
        }
            break;
        case LogLevelVerbose:
        {
            levelString = @"LogLevelVerbose";
        }
            break;
        case LogLevelInfo:
        {
            levelString = @"LogLevelInfo";
        }
            break;
        case LogLevelApplication:
        {
            levelString = @"LogLevelApplication";
        }
            break;
        case LogLevelWarning:
        {
            levelString = @"LogLevelWarning";
        }
            break;
        case LogLevelError:
        {
            levelString = @"LogLevelError";
        }
            break;
            
        default:
            break;
    }
    
    NSLog(@"\n ---> %@  : %@",levelString, message);
}

- (void)dfuStateDidChangeTo:(enum DFUState)state{

    switch (state) {
        case DFUStateConnecting:
        {
            _progressLabel.text = @"Connecting...";
        }
            break;
        case DFUStateStarting:
        {
            _progressLabel.text = @"Start Upgrade...";
        }
            break;
        case DFUStateEnablingDfuMode:
        {
            _progressLabel.text = @"Not Allow Upgrade";
        }
            break;
        case DFUStateUploading:
        {
            _progressLabel.text = @"Upgrade...";
        }
            break;
        case DFUStateValidating:
        {
            _progressLabel.text = @"Invalid Firmware";
        }
            break;
        case DFUStateDisconnecting:
        {
            _progressLabel.text = @"Disconnect";
        }
            break;
        case DFUStateCompleted:
        {
            _progressLabel.text = @"Upgrade Successful";
            AudioServicesPlaySystemSound(1309);
            if (_back) {
                _back();
            }
            [self.navigationController popViewControllerAnimated:YES];
        }
            break;
        case DFUStateAborted:
        {
            _progressLabel.text = @"Upgrade Stop";
        }
            break;
            
        default:
            break;
    }
}

- (void)dfuError:(enum DFUError)error didOccurWithMessage:(NSString *)message{
    
    NSLog(@"\n错误：%@",message);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error!Please Reset APP" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *done = [UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alert addAction:done];
    [self presentViewController:alert animated:YES completion:nil];
    
}

- (void)dfuProgressDidChangeFor:(NSInteger)part outOf:(NSInteger)totalParts to:(NSInteger)progress currentSpeedBytesPerSecond:(double)currentSpeedBytesPerSecond avgSpeedBytesPerSecond:(double)avgSpeedBytesPerSecond{
    
    NSLog(@"升级状态 -->>> %ld%% (part%ld/%ld). speed:%f bps, avgSpeed:%f bps\n",progress,part, totalParts, currentSpeedBytesPerSecond, avgSpeedBytesPerSecond);
    _speedLabel.text = [NSString stringWithFormat:@"speed:%f bps",currentSpeedBytesPerSecond];
    _progress.progress = progress/100.0;
    _progressLabel.text = [NSString stringWithFormat:@"%ld%%",progress];
}

- (IBAction)cancelAction:(UIButton *)sender {
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
