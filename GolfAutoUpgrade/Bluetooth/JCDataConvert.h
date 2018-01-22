//
//  JCDataConvert.h
//  Zebra
//
//  Created by 郭吉成 on 2017/10/30.
//  Copyright © 2017年 KOOSPUR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JCDataConvert : NSObject

/*!
 *  @将字符串中制定字符删除
 *  @str -[in] 需要处理的字符串
 *  @deleChar -[in] 需要删除的字符
 *  @return -[out] 转换后的字符
 */
+(NSString *) stringDeleteString:(NSString *)str by:(unichar)deleChar;

/*!
 *  @将十六进制数据转换成字符串
 *  @needConvertHex -[in] 需要转换的Hex
 *  @return -[out] 转换后的字符串
 */
+ (NSString *)convertHexToString:(NSData *)needConvertHex;

/*!
 *  @字符串转data（十六进制）
 *  @str -[in] 需要转换的字符串
 *  @return -[out] 转换后的字符串(十六进制)
 */
+ (NSData*)hexToBytes:(NSString *)str;

/*!
 *  @将十进制转化为十六进制
 *  @tmpid -[in] 需要转换的数字
 *  @return -[out] 转换后的字符串
 */
+ (NSString *)toHex:(int)tmpid;

/*!
 *  @将十六进制转化为十进制
 *  @tmpid -[in] 需要转换的十六进制
 *  @return -[out] 转换后的整数
 */
+ (NSInteger)toInteger:(NSData *)hexData;

/*!
 *  @将十六进制双字节转化为十进制
 *  @hexData -[in] 需要转换的十六进制(双字节)
 *  @return -[out] 转换后的整数
 */
+ (NSInteger)toIntegerWithDoubleByte:(NSData *)hexData;

//普通字符串转换为十六进制数据。
+ (NSData *)hexDataFromString:(NSString *)string;

@end
