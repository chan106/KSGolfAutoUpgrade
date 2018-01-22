//
//  DeviceTableViewCell.m
//  Golf-Test
//
//  Created by Guo.JC on 17/4/11.
//  Copyright © 2017年 coollang. All rights reserved.
//

#import "DeviceTableViewCell.h"
#import "JCBLEDevice.h"

@interface DeviceTableViewCell  ()
@property (weak, nonatomic) IBOutlet UILabel *rssiLabel;
@property (weak, nonatomic) IBOutlet UIImageView *rssiImageView;
@property (weak, nonatomic) IBOutlet UILabel *deviceNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *serverCountLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loading;
@property (weak, nonatomic) IBOutlet UIImageView *doneImageView;

@end

@implementation DeviceTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];

}

- (void)setDevice:(JCBLEDevice *)device{
    
    _rssiLabel.text = [device.RSSI.stringValue stringByAppendingString:@"db"];
    
    /*蓝牙信号值*/
    int iRssi = abs([device.RSSI intValue]);
    
    if (iRssi < 40) {
        self.rssiImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"信号-4"]];
    }
    else if(iRssi > 100){
        self.rssiImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"信号-0"]];
    }
    else if(iRssi <= 100 || iRssi >= 40){
        self.rssiImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"信号-%01d",5-((iRssi - 25)/15)]];
    }
    
    _deviceNameLabel.text = device.name;
    
    if (device.peripheral.state == CBPeripheralStateConnecting) {
        [_loading startAnimating];
        _doneImageView.hidden = YES;
    }
    else if (device.peripheral.state == CBPeripheralStateConnected) {
        [_loading stopAnimating];
        _doneImageView.hidden = NO;
        
    }
    else{
        [_loading stopAnimating];
        _doneImageView.hidden = YES;
    }
    
}

- (void)connectLoading{
    [_loading startAnimating];
}

- (void)connectDone{
    _doneImageView.hidden = NO;
    [_loading stopAnimating];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
