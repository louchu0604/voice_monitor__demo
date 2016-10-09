 //
//  DBMgr.m
//  51huanyou
//
//  Created by Jerry Chen on 15/5/23.
//  Copyright (c) 2015年 Jerry Chen. All rights reserved.
//

#import "DBMgr.h"
#import "FMDB.h"

#import <Foundation/Foundation.h>

#define db_tb_chart          @"sampleoftwo_chart"
#define get_msg_mid         [NSString stringWithFormat:@"%@_%@",[dic valueForKey:@"imsg"],[dic valueForKey:@"icontent"]]

@interface DBMgr()

@property (nonatomic,strong) NSString* m_path;
@property (nonatomic,strong) NSMutableSet *timeSet;
@property (nonatomic) int sampleCount;

@end

@implementation DBMgr
-(id)init
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    self.m_path = [documentDirectory stringByAppendingPathComponent:@"somnic_sample.db"];
    _timeSet = [NSMutableSet new];
    FMDatabase *db = [FMDatabase databaseWithPath:self.m_path];
    
    if (![db open]) {
        NSLog(@"db could not open.");
        NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
    }
    
    NSString *sql = [NSString stringWithFormat:@"create table if not exists %@ (id integer primary key autoincrement, sample text, timestamp text,endtime text)",db_tb_chart ];
    
    if (![db executeUpdate:sql]) {
        NSLog(@"db init executeUpdate failed");
        if ([db hadError]) {
            NSLog(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        }
    }
    
    [db close];
    
    return self;
}

-(void) clear_all_data
{
    NSFileManager *fm=[NSFileManager defaultManager];
    
    if([fm fileExistsAtPath:_m_path])
    {
       [fm removeItemAtPath:_m_path error:nil];
    }
   
}
-(float) get_db_size
{
    float size = 0.0;
    
    NSFileManager* manager = [NSFileManager defaultManager];
    
    if ([manager fileExistsAtPath:_m_path]){
        
        size = [[manager attributesOfItemAtPath:_m_path error:nil] fileSize];
    }
    return size;
}
-(void)add_data:(NSMutableString *)datas time:(NSDate*) sdate endtime:(NSDate*) endTime
{
    NSDateFormatter *formatter =[[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM/dd HH:mm:ss"];
    NSString *time = [formatter stringFromDate:sdate];
    NSString *eTime = [formatter stringFromDate:endTime];

    FMDatabase *db = [FMDatabase databaseWithPath:self.m_path];
    
    NSString *sql = @"";

    if (![db open]) {
        NSLog(@"db could not open. add_msgs");
    }
    
    [db beginTransaction];
    sql = [NSString stringWithFormat:@"select * from %@ where timestamp ='%@' and endtime ='%@' ",db_tb_chart,time,eTime];
    
    FMResultSet *rs = [db executeQuery:sql];

    if ([rs next]) {
        NSString *oldStr=[rs stringForColumn:@"sample"];
        if (oldStr.length<datas.length) {
             sql = [NSString stringWithFormat:@"update %@ set sample ='%@'  where  endtime='%@' and timestamp = '%@'",db_tb_chart, datas, eTime,time];
        }
        
    }else
    {
            sql = [NSString stringWithFormat:@"insert into %@ (sample, timestamp,endtime) values ('%@', '%@', '%@')",db_tb_chart, datas, time,eTime];
    }

    [db executeUpdate:sql];

    if (![db executeUpdate:sql])
    {
        NSLog(@"插入失败");

        if ([db hadError]) {
            NSLog(@"add_Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        }
    }
    [rs close];
    [db commit];
    [db close];

}

-(NSMutableString*) get_data:(NSDate*) sdate
{
    [_timeSet removeAllObjects];
    NSDateFormatter *formatter =[[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM/dd HH:mm:ss"];
    
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *comp = [gregorian components:(NSDayCalendarUnit | NSWeekdayCalendarUnit) fromDate:sdate];
    NSRange range = [gregorian rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:sdate];
    NSUInteger numberOfDaysInMonth = range.length;
    NSDate *yestD=[sdate addTimeInterval:-60*60*24];
    
    NSString *st = [formatter stringFromDate:yestD];
    NSString *et = [formatter stringFromDate:sdate];
    NSMutableString *ret = [NSMutableString stringWithCapacity:0];
    FMDatabase *db = [FMDatabase databaseWithPath:self.m_path];
    
    if (![db open]) {
        NSLog(@"db could not open. add_msgs");
    }
    
    NSString *sql = [NSString stringWithFormat:@"select * from %@ where timestamp >='%@' and timestamp <='%@' ",db_tb_chart,st,et];
    
    FMResultSet *rs = [db executeQuery:sql];
    int newC=0;
    int oldC;

    while ([rs next]) {
        NSString *timeBreak =[NSString stringWithFormat:@"%@--%@\r",[rs stringForColumn:@"timestamp"],[rs stringForColumn:@"endtime"]];
        oldC = _timeSet.count;
        [_timeSet addObject:timeBreak];
        newC = _timeSet.count;
        if (newC>oldC) {
            [ret appendString:[NSString stringWithFormat:@"(%@--%@) %@",[rs stringForColumn:@"timestamp"],[rs stringForColumn:@"endtime"],[rs stringForColumn:@"sample"]]];
        }
    }
    
    [rs close];
    [db close];
    return ret;

}

-(NSString *)get_time_stamp
{
    return [NSString stringWithFormat:@"有%lu条数据\r%@",(unsigned long)_timeSet.count,_timeSet];
}

@end
