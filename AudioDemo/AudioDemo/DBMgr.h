//
//  DBMgr.h
//  51huanyou
//
//  Created by Jerry Chen on 15/5/23.
//  Copyright (c) 2015年 Jerry Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DBMgr : NSObject

@property (nonatomic,strong)   NSMutableDictionary *uncomplete_data;

-(float) get_db_size;
-(void) clear_all_data;
-(void)add_data:(NSMutableString *)datas time:(NSDate*) sdate endtime:(NSDate*) endTime;
-(NSString*) get_data:(NSDate*) sdate;
-(NSString *)get_time_stamp;

@end
