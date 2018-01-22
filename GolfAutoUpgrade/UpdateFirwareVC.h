//
//  UpdateFirwareVC.h
//  Golf-Test
//
//  Created by Guo.JC on 17/4/11.
//  Copyright © 2017年 coollang. All rights reserved.
//

#import <UIKit/UIKit.h>
@class JCBLEDevice;
typedef void(^UpgradeBackBlock)(void);

@interface UpdateFirwareVC : UIViewController

@property (nonatomic, strong) JCBLEDevice *device;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, copy) UpgradeBackBlock back;

@end
