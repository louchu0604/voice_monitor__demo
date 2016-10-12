//
//  UtilUserDefault.m
//  Anyis
//
//  Created by Jerry Chen on 15/7/14.
//  Copyright (c) 2015年 Jerry Chen. All rights reserved.
//



#import "UtilUserDefault.h"
#import <UIKit/UIKit.h>
@implementation UtilUserDefault

+(BOOL) set_user_info:(NSMutableDictionary*) data
{
    BOOL ret = TRUE;
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
   
    [ud setObject:data forKey:@"user_info"];
    return ret;
}


+(NSMutableDictionary*) get_user_info
{
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithCapacity:0];
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    data = [[ud valueForKey:@"user_info"] mutableCopy];
    return data;
}

@end
