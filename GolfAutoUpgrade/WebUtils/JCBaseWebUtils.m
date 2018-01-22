//
//  JCBaseWebUtils.m
//  Zebra
//
//  Created by 奥赛龙-Guo.JC on 2016/11/11.
//  Copyright © 2016年 奥赛龙科技. All rights reserved.
//

#import "JCBaseWebUtils.h"
#import <AFNetworking/AFNetworking.h>

static AFHTTPSessionManager *_manager = nil;

@implementation JCBaseWebUtils

+ (AFHTTPSessionManager *)shareManager{
    
    return [self sharedManager];
}

+(AFHTTPSessionManager*)sharedManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [AFHTTPSessionManager manager];
        
        _manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        _manager.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        _manager.requestSerializer.timeoutInterval = 20; //超时时间
        _manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",
                                                              @"text/html",
                                                              @"text/plain",
                                                              @"text/javascript",
                                                              @"image/jpeg",
                                                              @"image/png",
                                                              @"application/octet-stream",
                                                              @"text/json",
                                                              nil];
        
    });
    return _manager;
}

#pragma mark - GET请求
+(void)get:(NSString *)path andParams:(id)params andCallback:(BaseRequestCallback)callback{
    
    AFHTTPSessionManager *manager = [self sharedManager];
        
    [manager GET:path parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
        callback(YES, resultDic);
        JCLog(@"GET请求成功，数据为：%@",resultDic);
    
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
     
        JCLog(@"GET请求失败 -- \n-%@",error);
        callback(NO, error);
    
    }];
}

#pragma mark - POST请求
+(void)post:(NSString *)path andParams:(id)params andCallback:(BaseRequestCallback)callback{
    
    AFHTTPSessionManager *manager = [self sharedManager];
    [manager POST:path parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSError *err;
        NSDictionary *resultDic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:&err];
        if (resultDic) {
            JCLog(@"\nPOST请求成功，数据为：%@",resultDic);
            callback(YES, resultDic);
        }
        else if (err){
            NSString *jsonString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
            jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\t" withString:@""];
            JCLog(@"\nJSON解析报错：%@",err);
            JCLog(@"\nPOST请求成功，数据为：%@",[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
            NSError *reerr;
            resultDic = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&reerr];
            if (resultDic) {
                callback(YES, resultDic);
            }
        }

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        JCLog(@"POST请求失败 -- \n-%@",error);
        callback(NO ,error);
    }];
}

/*
#pragma mark 图片上传
+(void)uploadImage:(NSString *)path andParams:(NSDictionary *)params andCallback:(MyCallback)callback{
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow.rootViewController.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    
    AFHTTPSessionManager *manager = [self sharedManager];
    
    UIImage *image = params[@"file"];

    
    NSDictionary *uploadParams = @{@"userId":params[@"userId"],
                                    @"token":params[@"token"]};
    
    [manager POST:path parameters:uploadParams constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData){
         
         [formData appendPartWithFileData:UIImageJPEGRepresentation(image, 0.5)
                                     name:@"file"
                                 fileName:[NSString stringWithFormat:@"header.jpeg"]
                                 mimeType:@"image/jpeg"];
         
     }progress:^(NSProgress * _Nonnull uploadProgress){
         hud.progress = 0.5;
         JCLog(@"%lld -- %lld",uploadProgress.totalUnitCount,uploadProgress.completedUnitCount);
     }success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject){
         hud.hidden = YES;
         [hud removeFromSuperview];
         NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
         JCLog(@"文件POST请求成功，数据为：%@ -- %@",dic,dic[@"msg"]);
         callback(dic);
     }failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error){
         hud.mode = MBProgressHUDModeText;
         hud.label.text = @"上传失败！";
         [NSTimer scheduledTimerWithTimeInterval:1 repeats:NO block:^(NSTimer * _Nonnull timer)
          {
              hud.hidden = YES;
              [hud removeFromSuperview];
          }];
     }];
}


#pragma mark 问题反馈
+(void)feedBack:(NSString *)path andParams:(NSDictionary *)params andCallback:(MyCallback)callback{
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow.rootViewController.view animated:YES];
    hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
    
    AFHTTPSessionManager *manager = [self sharedManager];
    
    UIImage *imageOne = params[@"fileOne"];
    UIImage *imageTwo = params[@"fileTwo"];
    UIImage *imageThree = params[@"fileThree"];
    
    
    NSDictionary *uploadParams = @{@"userId":params[@"userId"],
                             @"token":params[@"token"],
                             @"message":params[@"message"]};
    
//    NSArray *names = @[@"fileOne",@"fileTwo",@"fileThree"];
//    NSArray *fileNames = @[@"feedback_01.jpg",
//                           @"feedback_02.jpg",
//                           @"feedback_03.jpg"];
    
    NSMutableArray *images = [NSMutableArray array];
    
    if (![imageOne isEqual:[NSNull null]]) {
        NSData *data = UIImageJPEGRepresentation(imageOne, 1);
        [images addObject:data];
    }
    
    if (![imageTwo isEqual:[NSNull null]]){
        NSData *data = UIImageJPEGRepresentation(imageTwo, 1);
        [images addObject:data];
    }
    
    if (![imageThree isEqual:[NSNull null]]){
        NSData *data = UIImageJPEGRepresentation(imageThree, 1);
        [images addObject:data];
    }
    
    
    [manager POST:path parameters:uploadParams constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData){
        
        if (![imageOne isEqual:[NSNull null]]) {
            [formData appendPartWithFileData:UIImageJPEGRepresentation(imageOne, 0.5)
                                        name:@"fileOne"
                                    fileName:[NSString stringWithFormat:@"feedBackOne.jpeg"]
                                    mimeType:@"image/jpeg"];
        }
        
        [NSThread sleepForTimeInterval:0.2];
        
        if (![imageTwo isEqual:[NSNull null]]){
            [formData appendPartWithFileData:UIImageJPEGRepresentation(imageTwo, 0.5)
                                        name:@"fileTwo"
                                    fileName:[NSString stringWithFormat:@"feedBackTwo.jpeg"]
                                    mimeType:@"image/jpeg"];
        }
        
        [NSThread sleepForTimeInterval:0.2];
        
        if (![imageThree isEqual:[NSNull null]]){
            [formData appendPartWithFileData:UIImageJPEGRepresentation(imageThree, 0.5)
                                        name:@"fileThree"
                                    fileName:[NSString stringWithFormat:@"feedBackThree.jpeg"]
                                    mimeType:@"image/jpeg"];
        }
        
        [NSThread sleepForTimeInterval:0.2];
//        
//        for (int i = 0; i < images.count; i++) {
//
//            NSData *imageData = images[i];
//            NSString *name = names[i];
//            NSString *fileName = fileNames[i];
//            
//            [formData appendPartWithFileData:imageData
//                                        name:name
//                                    fileName:fileName
//                                    mimeType:@"image/jpeg/png"];
//        }
        
      
    }progress:^(NSProgress * _Nonnull uploadProgress){
        hud.progress = ((CGFloat)uploadProgress.completedUnitCount)/((CGFloat)uploadProgress.totalUnitCount);
        
        JCLog(@"%lld -- %lld   --->上传进度： %lf%%",uploadProgress.totalUnitCount,uploadProgress.completedUnitCount,(CGFloat)uploadProgress.completedUnitCount/(CGFloat)uploadProgress.totalUnitCount);
        
        
    }success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject){
        hud.hidden = YES;
        [hud removeFromSuperview];
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
        JCLog(@"文件POST请求成功，数据为：%@ -- %@",dic,dic[@"msg"]);
        callback(dic);
    }failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error){
        hud.mode = MBProgressHUDModeText;
        hud.label.text = @"上传失败！";
        [NSTimer scheduledTimerWithTimeInterval:1 repeats:NO block:^(NSTimer * _Nonnull timer)
         {
             hud.hidden = YES;
             [hud removeFromSuperview];
         }];
    }];
}


// 上传多张图片
+ (void)uploadMostImageWithURLString:(NSString *)URLString
                          parameters:(id)parameters
                         uploadDatas:(NSArray *)uploadDatas
                          uploadName:(NSString *)uploadName
                             success:(void (^)())success
                             failure:(void (^)(NSError *))failure{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"text/json", @"text/plain", @"text/html", nil];
    [manager POST:URLString parameters:parameters constructingBodyWithBlock:^(id< AFMultipartFormData >  _Nonnull formData) {
        for (int i=0; i<uploadDatas.count; i++) {
            NSString *imageName = [NSString stringWithFormat:@"%@[%i]", uploadName, i];
            [formData appendPartWithFileData:uploadDatas[i] name:uploadName fileName:imageName mimeType:@"image/png"];
        }
    } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (failure) {
            failure(error);
        }
    }];
}
*/

@end
