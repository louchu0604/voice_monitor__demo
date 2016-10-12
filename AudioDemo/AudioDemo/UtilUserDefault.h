//
//  UtilUserDefault.h
//  Anyis
//
//  Created by Jerry Chen on 15/7/14.
//  Copyright (c) 2015年 Jerry Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 
 操作缓存在NSUserDefaults中的数据
 
*/

@interface UtilUserDefault : NSObject


/*
 样本用户信息
*/
+(BOOL) set_user_info:(NSMutableDictionary*) data;
+(NSMutableDictionary*) get_user_info;




@end
