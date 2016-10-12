//
//  UtilAPI.h
//  mobileplatform
//
//  Created by Jerry Chen on 15-3-5.
//  Copyright (c) 2015年 Jerry Chen. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "AFHTTPRequestOperationManager.h"

@interface UtilAPI : NSObject



+(NSString *)md5sum :(NSString*) _data;


+(NSString *)URLDecodedString:(NSString *)str;
+(NSString *)URLEncodedString:(NSString *)str;
@end
