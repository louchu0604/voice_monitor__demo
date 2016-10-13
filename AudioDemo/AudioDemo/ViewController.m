//
//  ViewController.m
//  AudioDemo
//
//  Created by louchu on 16/9/28.
//  Copyright © 2016年 Cy Lou. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreMotion/CoreMotion.h>
#import "DBMgr.h"
#import "SCSiriWaveformView.h"
#import <MessageUI/MFMailComposeViewController.h>
#import "AFNetworking.h"
#import "UtilAPI.h"
#import "UtilUserDefault.h"
#import "SVProgressHUD.h"

#define sample_recipients @"380192098@qq.com"
#define serverUrl @"https://zs.somnic.com/api/file/1/uploadfile"


#define kRecordAudioFile @"myRecord.caf"
#define scale_device_value(float)   (float)*SCREEN_WIDTH/750
#define SCREEN_WIDTH          [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT          [[UIScreen mainScreen] bounds].size.height
#define RGB(r,g,b)            [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0]
#define main_rgb                RGB(241, 139, 0)
#define mainBlue_rgb                RGB(0, 160, 233)
typedef NS_ENUM(NSUInteger, SCSiriWaveformViewInputType) {
    SCSiriWaveformViewInputTypeRecorder,
    SCSiriWaveformViewInputTypePlayer
};

@interface ViewController ()
<AVAudioRecorderDelegate,
AVAudioPlayerDelegate,
AVAudioPlayerDelegate,
UITextFieldDelegate,
MFMailComposeViewControllerDelegate
>
@property (nonatomic, strong)  SCSiriWaveformView *waveformView;
@property (nonatomic, assign) SCSiriWaveformViewInputType selectedInputType;
@property (nonatomic,strong) AVAudioRecorder *audioRecorder;//音频录音机
@property (nonatomic,strong) NSTimer *timer;//录音声波监控
@property (nonatomic,strong) AVAudioPlayer *audioPlayer;
@property (nonatomic,strong) UIView *userInfo;
@property (nonatomic,strong) UIView *dataSpace;
@property (strong,nonatomic) UIButton *startBtn;
@property (strong,nonatomic) UIButton *stopBtn;
@property (strong,nonatomic) UIButton *cBtn;
@property (strong,nonatomic) UIButton *showAll;
@property (strong,nonatomic) UIButton *clearAll;
@property (strong,nonatomic) UIButton *editBtn;
@property (strong,nonatomic) UIButton *sendmailBtn;


@property (nonatomic,strong) NSMutableArray *datas;
@property (nonatomic,strong) NSMutableString *data_string;
@property (nonatomic, strong) CMMotionManager *mManager;

@property (nonatomic,strong) UITextField *time_interval;
@property (nonatomic,strong) UITextField *user_name;
@property (nonatomic,strong) UITextField *user_phone;

@property (nonatomic,strong) UITextView *sample_content;
@property (nonatomic) NSTimeInterval updateInterval;
@property (nonatomic,strong) NSMutableArray *mdatas;

@property (nonatomic) double zz;
@property (nonatomic) double zx;
@property (nonatomic) double zy;

@property (nonatomic,strong) NSDate *time_stamp;

@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self init_datas];
    
    [self init_ui];
    [self init_userInfo_ui];
    [SVProgressHUD setOffsetFromCenter:UIOffsetMake(0, SCREEN_HEIGHT*0.5-100)];
    [self fresh_clearTitle];
    // Do any additional setup after loading the view, typically from a nib.
}
- (void)init_datas
{
  _data_string =  [NSMutableString stringWithCapacity:0];

}
- (void)init_userInfo_ui
{
    _userInfo = [UIView new];
    UILabel *usernameL = [UILabel new];
    UILabel *userPhoneL = [UILabel new];
    _user_name= [UITextField new];
    _user_phone= [UITextField new];
    UIButton *saveBtn = [UIButton new];
    
    [self.view addSubview:_userInfo];
    [_userInfo addSubview:usernameL];
    [_userInfo addSubview:userPhoneL];
    [_userInfo addSubview:_user_name];
    [_userInfo addSubview:_user_phone];
    [_userInfo addSubview:saveBtn];

    [_userInfo setFrame:CGRectMake(0, -SCREEN_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT)];

    
      float hh = scale_device_value(100);
    UIFont *ff = [UIFont systemFontOfSize:17];
    
    [usernameL setFrame:CGRectMake(20, hh, 100, 40)];
    hh+=50;
    [_user_name setFrame:CGRectMake(20, hh,  SCREEN_WIDTH-40, 40)];
    hh+=50;
    [userPhoneL setFrame:CGRectMake(20, hh,  SCREEN_WIDTH-40, 80)];
    hh+=90;
    [_user_phone setFrame:CGRectMake(20, hh,  SCREEN_WIDTH-40, 40)];
    hh+=50;
    [saveBtn setFrame:CGRectMake(SCREEN_WIDTH-120, 20, 100, 40)];
    
    
    usernameL.textAlignment = NSTextAlignmentLeft;
    usernameL.textColor = [UIColor blackColor];
    usernameL.backgroundColor = [UIColor whiteColor];
    usernameL.font = ff;
    usernameL.numberOfLines = 0;
    usernameL.text = @"测试人姓名";
    
    _user_name.textAlignment = NSTextAlignmentLeft;
    _user_name.textColor = [UIColor blackColor];
    _user_name.backgroundColor = [UIColor whiteColor];
    _user_name.font = ff;
    _user_name.placeholder = @"请输入姓名";
    _user_name.delegate = self;
    
    userPhoneL.textAlignment = NSTextAlignmentLeft;
    userPhoneL.textColor = [UIColor blackColor];
    userPhoneL.backgroundColor = [UIColor whiteColor];
    userPhoneL.font = ff;
    userPhoneL.numberOfLines = 0;
    userPhoneL.text = @"如果你有使用传感带，请在下方输入你在智睡/睡咖平台的用户名（手机号）";
    
    _user_phone.textAlignment = NSTextAlignmentLeft;
    _user_phone.textColor = [UIColor blackColor];
    _user_phone.backgroundColor = [UIColor whiteColor];
    _user_phone.font = ff;
    _user_phone.keyboardType = UIKeyboardTypeNumberPad;
    _user_phone.placeholder = @"智睡/睡咖平台的用户名（手机号）";
    _user_phone.delegate = self;
    
    _userInfo.backgroundColor = [UIColor lightGrayColor];
    
    [saveBtn setTitle:@"保存信息" forState:0];
    [saveBtn setTitleColor:main_rgb forState:0];
    [saveBtn setBackgroundColor:[UIColor blackColor]];
    saveBtn.backgroundColor = [UIColor whiteColor];
    [saveBtn addTarget:self action:@selector(on_save_info) forControlEvents:UIControlEventTouchUpInside];


    NSMutableDictionary *info=[UtilUserDefault get_user_info];
    if (info) {
        _user_phone.text = [info valueForKey:@"userphone"];
        _user_name.text = [info valueForKey:@"username"];
        
        if (_user_name.text.length==0) {
            [_user_name becomeFirstResponder];
            [UIView animateWithDuration:0.5 animations:^{
                [_userInfo setFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
            } completion:^(BOOL finished) {
                
            }];

        }
    }else
    {
        [_time_interval becomeFirstResponder];
        [UIView animateWithDuration:0.5 animations:^{
            [_userInfo setFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        } completion:^(BOOL finished) {
            
        }];
    }
    
}
- (void)on_save_info
{
    [_user_name resignFirstResponder];
    [_user_phone resignFirstResponder];
    if (_user_name.text.length>0) {
        [SVProgressHUD showWithStatus:@"正在保存"];
        NSMutableDictionary *info = [NSMutableDictionary new];
        
        [info setObject:_user_name.text forKey:@"username"];
        [info setObject:_user_phone.text forKey:@"userphone"];
        
        [UtilUserDefault set_user_info:info];
        [UIView animateWithDuration:0.5 animations:^{
            [_userInfo setFrame:CGRectMake(0, -SCREEN_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT)];
        } completion:^(BOOL finished) {
           
            [SVProgressHUD showSuccessWithStatus:@"保存成功"];
            
        }];

    }else
    {
        [SVProgressHUD showErrorWithStatus:@"请填写姓名"];
    }
    
}
- (void)on_edit_info
{
 
    [UIView animateWithDuration:0.5 animations:^{
        [_userInfo setFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    } completion:^(BOOL finished) {
        
    }];
    
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}
- (void)init_ui
{
    _dataSpace = [UIView new];
    _sample_content = [[UITextView alloc] init];
    _startBtn = [UIButton new];
    _stopBtn = [UIButton new];
    _cBtn = [UIButton new];
    _clearAll = [UIButton new];
    _editBtn = [UIButton new];
    _sendmailBtn = [UIButton new];

    _showAll=  [UIButton new];
    _time_interval = [UITextField new];
    _mManager = [[CMMotionManager alloc]init];
    [self.view addSubview:_dataSpace];
    _dataSpace.userInteractionEnabled = YES;
    [_dataSpace addSubview:_time_interval];
    [_dataSpace addSubview:_sample_content];
    [_dataSpace addSubview:_stopBtn];
    [_dataSpace addSubview:_startBtn];
    [_dataSpace addSubview:_cBtn];
    [_dataSpace addSubview:_showAll];
    [_dataSpace addSubview:_clearAll];
    [_dataSpace addSubview:_editBtn];
    [_dataSpace addSubview:_sendmailBtn];
    
    _dataSpace.frame = self.view.bounds;
    _dataSpace.backgroundColor = [UIColor clearColor];
    _sample_content.backgroundColor = RGB(247, 247, 247);
    _sample_content.editable = NO;
    _sample_content.textColor = mainBlue_rgb;
    _sample_content.contentInset = UIEdgeInsetsMake(2, 2, 2, 2);
    _sample_content.font = [UIFont systemFontOfSize:17];
    
    [_startBtn setTitle:@"开始" forState:0];
    [_startBtn setTitleColor:main_rgb forState:0];
    [_startBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [_startBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];

    [_startBtn setBackgroundColor:RGB(247, 247, 247)];
    [_startBtn addTarget:self action:@selector(begin_collect) forControlEvents:UIControlEventTouchUpInside];
    
    [_stopBtn setTitle:@"停止" forState:0];
    [_stopBtn setTitleColor:main_rgb forState:0];
    [_stopBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [_stopBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];


    [_stopBtn setBackgroundColor:RGB(247, 247, 247)];
    [_stopBtn addTarget:self action:@selector(stop_collect) forControlEvents:UIControlEventTouchUpInside];
    
    [_cBtn setTitle:@"复制" forState:0];
    [_cBtn setTitleColor:main_rgb forState:0];
    [_cBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [_cBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];

    [_cBtn setBackgroundColor:RGB(247, 247, 247)];
    [_cBtn addTarget:self action:@selector(on_copy) forControlEvents:UIControlEventTouchUpInside];
    
    [_showAll setTitle:@"发给服务器" forState:0];
    [_showAll setTitleColor:main_rgb forState:0];
    [_showAll setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [_showAll setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];

    [_showAll setBackgroundColor:RGB(247, 247, 247)];
    [_showAll addTarget:self action:@selector(show_all) forControlEvents:UIControlEventTouchUpInside];
    
    [_clearAll setTitle:@"清除缓存" forState:0];
    [_clearAll setTitleColor:main_rgb forState:0];
     [_clearAll setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [_clearAll setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];

    [_clearAll setBackgroundColor:RGB(247, 247, 247)];
    [_clearAll addTarget:self action:@selector(clear_all) forControlEvents:UIControlEventTouchUpInside];
    
    [_editBtn setTitle:@"修改信息" forState:0];
    [_editBtn setTitleColor:main_rgb forState:0];
    [_editBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [_editBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];

    [_editBtn setBackgroundColor:RGB(247, 247, 247)];
    [_editBtn addTarget:self action:@selector(on_edit_info) forControlEvents:UIControlEventTouchUpInside];
    
    [_sendmailBtn setTitle:@"发送邮件" forState:0];
    [_sendmailBtn setTitleColor:main_rgb forState:0];
    [_sendmailBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [_sendmailBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];

    [_sendmailBtn setBackgroundColor:RGB(247, 247, 247)];
    [_sendmailBtn addTarget:self action:@selector(uptomail) forControlEvents:UIControlEventTouchUpInside];
    
    _time_interval.backgroundColor = [[UIColor whiteColor]colorWithAlphaComponent:0.8];
    _time_interval.textAlignment = NSTextAlignmentCenter;
    _time_interval.font = [UIFont systemFontOfSize:18];
    _time_interval.textColor = mainBlue_rgb;
    _time_interval.placeholder = @"采样频率（HZ)";
    _time_interval.backgroundColor =RGB(247, 247, 247);
    _time_interval.delegate = self;
    _time_interval.keyboardType = UIKeyboardTypeNumberPad;
    _time_interval.text = @"10";
    
    float ss = (SCREEN_WIDTH-50)/14;
    float hh= 40;
    [_time_interval setFrame:CGRectMake(10, hh, ss*4, 40)];
    [_startBtn setFrame:CGRectMake(ss*4+20, hh, ss*2, 40)];
    [_stopBtn setFrame:CGRectMake(ss*6+30, hh, ss*2, 40)];
    [_clearAll setFrame:CGRectMake(ss*8+40, hh, ss*6, 40)];

    hh+=50;
    float ww = (SCREEN_WIDTH-50)/15;
    [_cBtn setFrame:CGRectMake(10, hh, ww*2, 40)];
    [_showAll setFrame:CGRectMake(ww*2+20, hh, ww*5, 40)];
    [_sendmailBtn setFrame:CGRectMake(ww*7+30, hh, ww*4, 40)];
    [_editBtn setFrame:CGRectMake(ww*11+40, hh, ww*4, 40)];
    hh+=50;
    float newh =SCREEN_HEIGHT-hh-5;
    _waveformView = [[SCSiriWaveformView alloc]initWithFrame:CGRectMake(10, hh, SCREEN_WIDTH-20, newh*0.34)];
    [self.view addSubview:_waveformView];
    hh+=newh*0.34+5;
    _sample_content.frame = CGRectMake(10, hh, SCREEN_WIDTH-20, newh*0.66);
    
    [self.waveformView setWaveColor:[UIColor whiteColor]];
    [self.waveformView setPrimaryWaveLineWidth:1.5f];
    [self.waveformView setSecondaryWaveLineWidth:1.0];
    
    _timer=[NSTimer scheduledTimerWithTimeInterval:60*60 target:self selector:@selector(anto_save) userInfo:nil repeats:YES];

    
    
    _startBtn.enabled =YES;
    _stopBtn.enabled = NO;
    _editBtn.enabled = YES;
    _clearAll.enabled = YES;
    _cBtn.enabled = YES;
    _showAll.enabled = YES;
    _editBtn.enabled =YES;
    _sendmailBtn.enabled = YES;
}
#pragma mark - 邮件回调
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result) {
        case MFMailComposeResultCancelled: {
            [SVProgressHUD showErrorWithStatus:@"取消发送"];
            break;
        }
        case MFMailComposeResultSaved: {
            [SVProgressHUD showSuccessWithStatus:@"保存成功"];
            break;
        }
        case MFMailComposeResultSent: {
            [SVProgressHUD showSuccessWithStatus:@"发送成功"];
            break;
        }
        case MFMailComposeResultFailed: {
            [SVProgressHUD showErrorWithStatus:@"发送失败"];
            break;
        }
        default:
            break;
    }
    _sendmailBtn.enabled = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)sendEmailBtnPressed:(NSString *)msg
{
    _sample_content.text = @" ";

    Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
    if (mailClass != nil)
    {
        if ([mailClass canSendMail])
        {
            [self sendEmail:msg];   // 调用发送邮件的方法
        }
        else {
            [self launchMailAppOnDevice:msg];   // 调用客户端邮件程序
        }
    }
    else {
        [self launchMailAppOnDevice:msg];    // 调用客户端邮件程序
    }
    
}
- (void)sendEmail:(NSString *)msg
{
    MFMailComposeViewController *sendMailViewController = [[MFMailComposeViewController alloc] init];
    sendMailViewController.mailComposeDelegate = self;
    
    // 设置邮件主题
    [sendMailViewController setSubject:@"样本"];
    
    /*
     * 设置收件人，收件人有三种
     */
    // 设置主收件人
    [sendMailViewController setToRecipients:[NSArray arrayWithObject:sample_recipients]];
//    // 设置CC
//    [sendMailViewController setCcRecipients:[NSArray arrayWithObject:@"example@hotmail.com"]];
//    // 设置BCC
//    [sendMailViewController setBccRecipients:[NSArray arrayWithObject:@"example@gmail.com"]];
    
    /*
     * 设置邮件主体，有两种格式
     */
    // 一种是纯文本
    [sendMailViewController setMessageBody:msg isHTML:NO];
    // 一种是HTML格式（HTML和纯文本两种格式按需求选择一种即可）
    //[mailVC setMessageBody:@"<HTML><B>Hello World!</B><BR/>Is everything OK?</HTML>" isHTML:YES];
    
    // 添加附件
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"feedback" ofType:@"png"];
//    NSData *data = [NSData dataWithContentsOfFile:path];
//    [sendMailViewController addAttachmentData:data mimeType:@"image/png" fileName:@"feedback"];
    [SVProgressHUD dismiss];
    // 视图呈现
    [self presentViewController:sendMailViewController animated:YES completion:nil];
}
-(void)launchMailAppOnDevice:(NSString *)msg
{
    NSString *recipients =[NSString stringWithFormat:@"mailto:%@&subject=样本",sample_recipients] ;
    NSString *body = [NSString stringWithFormat:@"&body=%@",msg];
    NSString *email = [NSString stringWithFormat:@"%@%@", recipients, body];
    email = [email stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    [SVProgressHUD dismiss];

    [[UIApplication sharedApplication] openURL: [NSURL URLWithString:email]];
}
- (void)begin_collect
{
    
    if (_data_string.length>2&&_time_stamp) {
        DBMgr *db = [[DBMgr alloc] init];
        [db add_data:_data_string time:_time_stamp endtime:[NSDate date]];
        [self fresh_clearTitle];
    }
    [_data_string setString:@""];
    [_time_interval resignFirstResponder];

    /* 设置采样的频率，单位是秒 */
    if ([_time_interval.text doubleValue] > 0) {
        _startBtn.enabled = NO;
        _stopBtn.enabled = YES;

        _updateInterval = 1/[_time_interval.text doubleValue];
        [SVProgressHUD showWithStatus:@"开始采集数据"];
        [self startUpdateAccelerometer];
        
    }else
    {
        [SVProgressHUD showErrorWithStatus:@"请填写采样频率"];
    }
    
}
- (void)stop_collect
{
    _startBtn.enabled = YES;
    _stopBtn.enabled = NO;
    [SVProgressHUD showSuccessWithStatus:@"停止采集数据"];

    [_timer invalidate];

    if ([self.mManager isDeviceMotionActive] == YES)
    {
        [self.mManager stopDeviceMotionUpdates];
    }
    if ([_audioRecorder isRecording]==YES) {
        [self.audioRecorder stop];

    }
    _sample_content.text = _data_string;
    
    if (_data_string.length>2) {
        DBMgr *db = [[DBMgr alloc] init];
        [db add_data:_data_string time:_time_stamp endtime:[NSDate date]];
        [self fresh_clearTitle];
    }

    [_data_string setString:@""];
    
}
- (void)anto_save
{
    if (_data_string.length>2) {
        DBMgr *db = [[DBMgr alloc] init];
        [db add_data:_data_string time:_time_stamp endtime:[NSDate date]];
        [self fresh_clearTitle];
    }
    [_data_string setString:@""];
    _time_stamp = [NSDate date];

}
- (void)viewWillDisappear:(BOOL)animated
{

    if (_data_string.length>2) {
        DBMgr *db = [[DBMgr alloc] init];
        [db add_data:_data_string time:_time_stamp endtime:[NSDate date]];
        [self fresh_clearTitle];
        [_data_string setString:@""];

    }
}
#pragma mark - 将数据发送给服务器
- (void)send_to_server:(NSString *)msg
{
    _sample_content.text = @"正在准备数据，请等待";
    NSMutableDictionary *info=[UtilUserDefault get_user_info];
    
    NSString *phone =[info valueForKey:@"userphone"];
    NSString *name =[info valueForKey:@"username"];

    NSMutableString *filename = [NSMutableString stringWithCapacity:0];
    [filename setString:@""];

    if (name.length>0) {
        [filename appendString:name];
    }
    if (phone.length>0) {
        [filename appendString:phone];
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentDirectory = [directoryPaths objectAtIndex:0];
    NSString *filePath = [documentDirectory stringByAppendingPathComponent:@"UserNameAndPassWord.txt"];
    if (![fileManager fileExistsAtPath:filePath]) {
        
        [fileManager createFileAtPath:filePath contents:nil attributes:nil];
        
    }

    BOOL result =[msg writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    if (filename.length==0) {
        [filename appendString:@"未提供姓名"];
    }
    if (result) {
        _sample_content.text = @"";

        [SVProgressHUD showWithStatus:@"正在发送数据"];

        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSMutableDictionary *data = [NSMutableDictionary new];
        NSString *uid =@"18605849405";
        NSString *passwd =[UtilAPI md5sum:@"123456" ];
        [manager.requestSerializer setValue:@"1" forHTTPHeaderField:@"appid"];
        [manager.requestSerializer setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html",@"text/json",@"text/javascript", nil];
        
        [data setObject:uid forKey:@"name"];
        [data setObject:passwd forKey:@"password"];
        NSData *txtdata = [NSData dataWithContentsOfFile:filePath];

        [manager POST:serverUrl parameters:data constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            
            [formData appendPartWithFileData:txtdata name:@"1" fileName:[NSString stringWithFormat:@"%@.txt",filename] mimeType:@"text/plain"];
            
        } success:^(AFHTTPRequestOperation *operation, id responseObject) {

            if ([[responseObject valueForKey:@"error"] intValue]==200) {
                [SVProgressHUD showSuccessWithStatus:@"发送成功！"];

            }else
            {
                [SVProgressHUD showErrorWithStatus:[responseObject valueForKey:@"description"] ];

            }
            _showAll.enabled = YES;
         
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

            NSLog(@"Error: %@", error);
            [SVProgressHUD showErrorWithStatus:@"发送失败，请稍后再试！"];
            _showAll.enabled = YES;

        }];

    }else
    {
        [SVProgressHUD showErrorWithStatus:@"发送失败，请稍后再试！"];
        _showAll.enabled = YES;

    }
 
}

- (void)on_copy
{
    _cBtn.enabled=NO;
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string =_data_string;
//    [self sendEmailBtnPressed:_data_string];
    [SVProgressHUD showSuccessWithStatus:@"拷贝成功！"];

    _cBtn.enabled = YES;
}

- (void)show_all
{
    _showAll.enabled = NO;
    DBMgr *db = [[DBMgr alloc] init];
    NSString *ll = [db get_data:[NSDate date]];
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string =ll;
    
    NSString *ss = [db get_time_stamp];
    _sample_content.text = [NSString stringWithFormat:@"最近24小时%@\r详细数据如下，已粘贴到剪切板\r%@",ss,ll];
//    [self sendEmailBtnPressed:ll];
    if (ll.length<38) {
      
        [SVProgressHUD showErrorWithStatus:@"还没有收集到数据，请稍后再试！"];
        return;

    }
    [self send_to_server:ll];
    
}
- (void)uptomail
{
    [SVProgressHUD showWithStatus:@"准备数据"];
    _sample_content.text = @"正在准备数据，请等待";

    _sendmailBtn.enabled = NO;
    DBMgr *db = [[DBMgr alloc] init];
    NSString *ll = [db get_data:[NSDate date]];
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string =ll;
    
    NSString *ss = [db get_time_stamp];
    _sample_content.text = [NSString stringWithFormat:@"最近24小时%@\r详细数据如下，已粘贴到剪切板\r%@",ss,ll];
   
    if (ll.length<38) {
        [SVProgressHUD showErrorWithStatus:@"没有收集到数据，请稍后再试！"];
        
    }else
    {
        _sendmailBtn.enabled = NO;
     [self sendEmailBtnPressed:ll];
    }
    
}
- (void)clear_all
{
    _clearAll.enabled = NO;
    [SVProgressHUD showWithStatus:@"正在清除"];

    DBMgr *db = [[DBMgr alloc] init];
    [db clear_all_data];
    
    [self fresh_clearTitle];
    
    [SVProgressHUD showSuccessWithStatus:@"清除成功"];
    _clearAll.enabled = YES;
    
}
- (void)fresh_clearTitle
{
    float dbSize = [[[DBMgr alloc] init] get_db_size];
    float sum = (dbSize)/1024/1024;
    NSString *title = [NSString stringWithFormat:@"清除缓存(%.1fM)", sum];
    [_clearAll setTitle:title forState:0];

}
#pragma mark - 开始采样
- (void)startUpdateAccelerometer
{
    [SVProgressHUD showWithStatus:@"正在采集数据"];
        if ([self.mManager isDeviceMotionAvailable] == YES) {
        [self.mManager setDeviceMotionUpdateInterval:_updateInterval];
            _time_stamp = [NSDate date];
            [_timer fire];
        [self.mManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {

            if (![self.audioRecorder isRecording])
            {
                [self.audioRecorder record];
            }
            //1. Accelerometer 获取手机加速度数据
            
            double accelerationX = motion.userAcceleration.x;
            double accelerationY = motion.userAcceleration.y;
            double accelerationZ = motion.userAcceleration.z;
            
            //2. Gravity 获取手机的重力值在各个方向上的分量，根据这个就可以获得手机的空间位置，倾斜角度等
            
            double gravityX = motion.gravity.x;
            double gravityY = motion.gravity.y;
            double gravityZ = motion.gravity.z;
            //获取手机的倾斜角度：
            //            double zTheta = atan2(gravityZ,sqrtf(gravityX*gravityX+gravityY*gravityY))/M_PI*180.0;
            //            double xyTheta = atan2(gravityX,gravityY)/M_PI*180.0;
            
            double zTheta = acos((sqrtf(gravityZ*gravityZ))/(sqrtf(gravityX*gravityX+gravityY*gravityY+gravityZ*gravityZ)))/M_PI*180.0;
            double yTheta = acos((sqrtf(gravityY*gravityY))/(sqrtf(gravityX*gravityX+gravityY*gravityY+gravityZ*gravityZ)))/M_PI*180.0;
            double xTheta = acos((sqrtf(gravityX*gravityX))/(sqrtf(gravityX*gravityX+gravityY*gravityY+gravityZ*gravityZ)))/M_PI*180.0;
            [self.waveformView updateWithLevel:[self _normalizedPowerLevelFromDecibels:[[self get_audioPowerChange][0]integerValue]-160]];

            if (_zz) {
                int change_value = sqrtf((_zz-zTheta)*(_zz-zTheta))+sqrtf((_zx-xTheta)*(_zx-xTheta))+sqrtf((_zy-yTheta)*(_zy-yTheta));
//                int change_value = fabs sqrtf((_zz-zTheta)*(_zz-zTheta))+sqrtf((_zx-xTheta)*(_zx-xTheta))+sqrtf((_zy-yTheta)*(_zy-yTheta));
                
                _zz = zTheta;
                _zx = xTheta;
                _zy = yTheta;
                NSMutableArray *sample =[self get_audioPowerChange];
                [_data_string appendString:[NSString stringWithFormat:@"%d %@ ",change_value,sample[0]]];
                [self log_data_angle:change_value power:[self get_audioPowerChange]];
            }else
            {
                _zz = zTheta;
                _zx = xTheta;
                _zy = yTheta;
            }
            
            //zTheta是手机与水平面的夹角， yTheta是手机与垂直面的夹角 xTheta两面同垂面
            
            //3. DeviceMotion 获取陀螺仪的数据 包括角速度，空间位置等
            //旋转角速度：
            CMRotationRate rotationRate = _mManager.deviceMotion.rotationRate;
            double rotationX = rotationRate.x;
            double rotationY = rotationRate.y;
            double rotationZ = rotationRate.z;
            
            //空间位置的欧拉角（通过欧拉角可以算得手机两个时刻之间的夹角，比用角速度计算精确地多）
            //            double roll    = _mManager.deviceMotion.attitude.roll/M_PI*180.0;
            //            double pitch   = _mManager.deviceMotion.attitude.pitch/M_PI*180.0;
            //            double yaw     = _mManager.deviceMotion.attitude.yaw/M_PI*180.0;
            //            //空间位置的四元数（与欧拉角类似，但解决了万向结死锁问题）
            //            double w = _mManager.deviceMotion.attitude.quaternion.w;
            //            double wx = _mManager.deviceMotion.attitude.quaternion.x;
            //            double wy = _mManager.deviceMotion.attitude.quaternion.y;
            //            double wz = _mManager.deviceMotion.attitude.quaternion.z;
            
            
        }];
    }
}
#pragma mark - 波纹参数
- (CGFloat)_normalizedPowerLevelFromDecibels:(CGFloat)decibels
{
    if (decibels < -60.0f || decibels == 0.0f) {
        return 0.0f;
    }
    
    return powf((powf(10.0f, 0.05f * decibels) - powf(10.0f, 0.05f * -60.0f)) * (1.0f / (1.0f - powf(10.0f, 0.05f * -60.0f))), 1.0f / 2.0f);
}

#pragma mark - 打印
- (void)log_data_angle:(int)change_value  power:(NSMutableArray *)power
{
    _sample_content.text = [NSString stringWithFormat:@"正在收集数据\r实时数据：\r手机三轴变化的角度总和：%d \r声音分贝平均值：%@ \r",change_value,power[0]];
}

#pragma mark - 录音声波状态监测
-(NSMutableArray *)get_audioPowerChange{
    [self.audioRecorder updateMeters];//更新测量值
    int power= [self.audioRecorder averagePowerForChannel:0]+160;
    int wp = [_audioRecorder peakPowerForChannel:0]+160;
    NSMutableArray *sample = [NSMutableArray new];
    [sample addObject:[NSString stringWithFormat:@"%d",power]];
//    [sample addObject:[NSString stringWithFormat:@"%d",wp]];
    //取得第一个通道的音频，注意音频强度范围时-160到0
  //  NSLog(@"%.1f------->>%.1f",power,wp);
  //  CGFloat progress=(1.0/160.0)*(power+160.0);
  //  [self.audioPower setProgress:progress];
    return sample;

}
-(NSURL *)getSavePath
{
    NSString *urlStr=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    urlStr=[urlStr stringByAppendingPathComponent:kRecordAudioFile];
    NSLog(@"file path:%@",urlStr);
    NSURL *url=[NSURL fileURLWithPath:urlStr];
    return url;
}

- (NSData *)getVideoStremData
{
    return [NSData dataWithContentsOfURL:[self getSavePath]];
}

#pragma mark - 录音文件设置
-(NSDictionary *)getAudioSetting{
    NSMutableDictionary *dicM=[NSMutableDictionary dictionary];
    //设置录音格式
    [dicM setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
    //设置录音采样率 采样率   赫兹，8000是电话采样率，对于一般录音已经够了
    [dicM setObject:@(8000) forKey:AVSampleRateKey];
    //设置声道数,这里采用单声道
    [dicM setObject:@(1) forKey:AVNumberOfChannelsKey];
    //每个采样点位数,分为8、16、24、32
    [dicM setObject:@(8) forKey:AVLinearPCMBitDepthKey];
    //是否使用浮点数采样
    [dicM setObject:@(YES) forKey:AVLinearPCMIsFloatKey];
    //录音的质量
    [dicM setValue:[NSNumber numberWithInt:AVAudioQualityMax] forKey:AVEncoderAudioQualityKey];
    //....其他设置等
    return dicM;
}
#pragma mark - 录音机对象
-(AVAudioRecorder *)audioRecorder
{
    if (!_audioRecorder) {
        //创建录音文件保存路径
        NSURL *url=[self getSavePath];
        //创建录音格式设置
        NSDictionary *setting=[self getAudioSetting];
        //创建录音机
        NSError *error=nil;
        _audioRecorder=[[AVAudioRecorder alloc]initWithURL:url settings:setting error:&error];
        _audioRecorder.delegate=self;
        _audioRecorder.meteringEnabled=YES;//如果要监控声波则必须设置为YES
        if (error) {
            NSLog(@"创建录音机对象时发生错误，错误信息：%@",error.localizedDescription);
            return nil;
        }
    }
    return _audioRecorder;
}

#pragma mark - 录音机代理方法

-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{

    NSLog(@"录音完成!");
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
