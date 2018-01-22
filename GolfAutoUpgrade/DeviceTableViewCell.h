//
//  DeviceTableViewCell.h
//  Golf-Test
//
//  Created by Guo.JC on 17/4/11.
//  Copyright © 2017年 coollang. All rights reserved.
//

#import <UIKit/UIKit.h>
@class JCBLEDevice;

@interface DeviceTableViewCell : UITableViewCell

- (void)setDevice:(JCBLEDevice *)device;
- (void)connectLoading;
- (void)connectDone;
@end
