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

#define sample_recipients @"38019****@qq.com"

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

@property (strong,nonatomic) UIButton *startBtn;
@property (strong,nonatomic) UIButton *stopBtn;
@property (strong,nonatomic) UIButton *cBtn;
@property (strong,nonatomic) UIButton *showAll;
@property (strong,nonatomic) UIButton *clearAll;

@property (nonatomic,strong) NSMutableArray *datas;
@property (nonatomic,strong) NSMutableString *data_string;
@property (nonatomic, strong) CMMotionManager *mManager;

@property (nonatomic,strong) UITextField *time_interval;
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
    // Do any additional setup after loading the view, typically from a nib.
}
- (void)init_datas
{
  _data_string =  [NSMutableString stringWithCapacity:0];

}
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}
- (void)init_ui
{
    _sample_content = [[UITextView alloc] init];
    _startBtn = [UIButton new];
    _stopBtn = [UIButton new];
    _cBtn = [UIButton new];
    _clearAll = [UIButton new];

    _showAll=  [UIButton new];
    _time_interval = [UITextField new];
    _mManager = [[CMMotionManager alloc]init];
    [self.view addSubview:_time_interval];
    [self.view addSubview:_sample_content];
    [self.view addSubview:_stopBtn];
    [self.view addSubview:_startBtn];
    [self.view addSubview:_cBtn];
    [self.view addSubview:_showAll];
    [self.view addSubview:_clearAll];
    
    _sample_content.backgroundColor = RGB(247, 247, 247);
    _sample_content.editable = NO;
    _sample_content.textColor = mainBlue_rgb;
    _sample_content.contentInset = UIEdgeInsetsMake(2, 2, 2, 2);
    _sample_content.font = [UIFont systemFontOfSize:17];
    
    [_startBtn setTitle:@"开始" forState:0];
    [_startBtn setTitleColor:main_rgb forState:0];
    [_startBtn setBackgroundColor:RGB(247, 247, 247)];
    [_startBtn addTarget:self action:@selector(begin_collect) forControlEvents:UIControlEventTouchUpInside];
    
    [_stopBtn setTitle:@"停止" forState:0];
    [_stopBtn setTitleColor:main_rgb forState:0];
    [_stopBtn setBackgroundColor:RGB(247, 247, 247)];
    [_stopBtn addTarget:self action:@selector(stop_collect) forControlEvents:UIControlEventTouchUpInside];
    
    [_cBtn setTitle:@"复制" forState:0];
    [_cBtn setTitleColor:main_rgb forState:0];
    [_cBtn setBackgroundColor:RGB(247, 247, 247)];
    [_cBtn addTarget:self action:@selector(on_copy) forControlEvents:UIControlEventTouchUpInside];
    
    [_showAll setTitle:@"复制24h数据并发送" forState:0];
    [_showAll setTitleColor:main_rgb forState:0];
    [_showAll setBackgroundColor:RGB(247, 247, 247)];
    [_showAll addTarget:self action:@selector(show_all) forControlEvents:UIControlEventTouchUpInside];
    
    [_clearAll setTitle:@"清除缓存" forState:0];
    [_clearAll setTitleColor:main_rgb forState:0];
    [_clearAll setBackgroundColor:RGB(247, 247, 247)];
    [_clearAll addTarget:self action:@selector(clear_all) forControlEvents:UIControlEventTouchUpInside];
    
    _time_interval.backgroundColor = [[UIColor whiteColor]colorWithAlphaComponent:0.8];
    _time_interval.textAlignment = NSTextAlignmentCenter;
    _time_interval.font = [UIFont systemFontOfSize:18];
    _time_interval.textColor = mainBlue_rgb;
    _time_interval.placeholder = @"采样频率（HZ)";
    _time_interval.backgroundColor =RGB(247, 247, 247);
    _time_interval.delegate = self;
    _time_interval.keyboardType = UIKeyboardTypeNumberPad;

    
    float ss = SCREEN_WIDTH/4;
    float hh= 40;
    [_time_interval setFrame:CGRectMake(10, hh, ss*2-20, 40)];

    [_startBtn setFrame:CGRectMake(ss*2, hh, ss-10, 40)];
    [_stopBtn setFrame:CGRectMake(ss*3, hh, ss-10, 40)];
    hh+=50;
    float ww = (SCREEN_WIDTH-40)/7;
    [_cBtn setFrame:CGRectMake(10, hh, ww, 40)];
    [_showAll setFrame:CGRectMake(ww+20, hh, ww*4, 40)];
    [_clearAll setFrame:CGRectMake(ww*5+30, hh, ww*2, 40)];

    hh+=50;
    float newh =SCREEN_HEIGHT-hh-5;
    _waveformView = [[SCSiriWaveformView alloc]initWithFrame:CGRectMake(10, hh, SCREEN_WIDTH-20, newh*0.34)];
    [self.view addSubview:_waveformView];
    hh+=newh*0.34+5;
    _sample_content.frame = CGRectMake(10, hh, SCREEN_WIDTH-20, newh*0.66);
    
    [self.waveformView setWaveColor:[UIColor whiteColor]];
    [self.waveformView setPrimaryWaveLineWidth:3.0f];
    [self.waveformView setSecondaryWaveLineWidth:1.0];
    

}
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result) {
        case MFMailComposeResultCancelled: {
            NSLog(@"Mail send canceled.");
            break;
        }
        case MFMailComposeResultSaved: {
            NSLog(@"Mail saved.");
            break;
        }
        case MFMailComposeResultSent: {
            NSLog(@"Mail sent.");
            break;
        }
        case MFMailComposeResultFailed: {
            NSLog(@"Mail sent Failed.");
            break;
        }
        default:
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)sendEmailBtnPressed:(NSString *)msg
{
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
    
    // 视图呈现
    [self presentViewController:sendMailViewController animated:YES completion:nil];
}
-(void)launchMailAppOnDevice:(NSString *)msg
{
    NSString *recipients =[NSString stringWithFormat:@"mailto:%@&subject=样本",sample_recipients] ;
    NSString *body = [NSString stringWithFormat:@"&body=%@",msg];
    NSString *email = [NSString stringWithFormat:@"%@%@", recipients, body];
    email = [email stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    [[UIApplication sharedApplication] openURL: [NSURL URLWithString:email]];
}
- (void)begin_collect
{
    if (![_data_string isEqualToString:@""]&&_time_stamp) {
        DBMgr *db = [[DBMgr alloc] init];
        [db add_data:_data_string time:_time_stamp endtime:[NSDate date]];
    }
    [_data_string setString:@""];
    [_time_interval resignFirstResponder];
    _time_stamp = [NSDate date];
    
    /* 设置采样的频率，单位是秒 */
    if ([_time_interval.text doubleValue] > 0) {
        _updateInterval = 1/[_time_interval.text doubleValue];
        [self startUpdateAccelerometer];
    }
    
}
- (void)stop_collect
{
    if ([self.mManager isDeviceMotionActive] == YES)
    {
        [self.mManager stopDeviceMotionUpdates];
    }
    if ([_audioRecorder isRecording]==YES) {
        [self stop_recorder];
    }
    _sample_content.text = _data_string;
    
    DBMgr *db = [[DBMgr alloc] init];
    [db add_data:_data_string time:_time_stamp endtime:[NSDate date]];
    [_data_string setString:@""];

    
}
- (void)viewWillDisappear:(BOOL)animated
{

    if (![_data_string isEqualToString:@""]) {
        DBMgr *db = [[DBMgr alloc] init];
        [db add_data:_data_string time:_time_stamp endtime:[NSDate date]];
    }
}
- (void)on_copy
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string =_data_string;
    [self sendEmailBtnPressed:_data_string];
    //[SVProgressHUD showSuccessWithStatus:@"拷贝成功"];
}
- (void)show_all
{
    DBMgr *db = [[DBMgr alloc] init];
    NSString *ll = [db get_data:[NSDate date]];
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string =ll;
    
    NSString *ss = [db get_time_stamp];
    _sample_content.text = [NSString stringWithFormat:@"最近24小时%@\r详细数据如下，已粘贴到剪切板\r%@",ss,ll];
    [self sendEmailBtnPressed:ll];
    
}
- (void)clear_all
{
    DBMgr *db = [[DBMgr alloc] init];
    [db clear_all_data];
    
}
#pragma mark - 开始采样

- (void)startUpdateAccelerometer
{
        if ([self.mManager isDeviceMotionAvailable] == YES) {
        [self.mManager setDeviceMotionUpdateInterval:_updateInterval];
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
            [self.waveformView updateWithLevel:[self _normalizedPowerLevelFromDecibels:[self get_audioPowerChange]-160]];

            if (_zz) {
                int change_value = sqrtf((_zz-zTheta)*(_zz-zTheta))+sqrtf((_zx-xTheta)*(_zx-xTheta))+sqrtf((_zy-yTheta)*(_zy-yTheta));
                _zz = zTheta;
                _zx = xTheta;
                _zy = yTheta;
                [_data_string appendString:[NSString stringWithFormat:@"%d %d ",change_value,[self get_audioPowerChange]]];
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
#pragma mark - Private
         
- (CGFloat)_normalizedPowerLevelFromDecibels:(CGFloat)decibels
{
    if (decibels < -60.0f || decibels == 0.0f) {
        return 0.0f;
    }
    
    return powf((powf(10.0f, 0.05f * decibels) - powf(10.0f, 0.05f * -60.0f)) * (1.0f / (1.0f - powf(10.0f, 0.05f * -60.0f))), 1.0f / 2.0f);
}

#pragma mark - 打印
- (void)log_data_angle:(int)change_value  power:(int)power
{
    _sample_content.text = [NSString stringWithFormat:@"手机三轴变化的角度总和：%d \r声音分贝值：%d",change_value,power];
}

#pragma mark - 获取录音文件
- (void)getsample
{
    NSData *data = [self getVideoStremData];
}
#pragma mark - 录音声波监测定时器
-(NSTimer *)timer{
    if (!_timer) {
        _timer=[NSTimer scheduledTimerWithTimeInterval:0.01f target:self selector:@selector(audioPowerChange) userInfo:nil repeats:YES];
    }
    return _timer;
}

#pragma mark - 录音声波状态监测
-(int)get_audioPowerChange{
    [self.audioRecorder updateMeters];//更新测量值
    int power= [self.audioRecorder averagePowerForChannel:0];
    double wp = [_audioRecorder peakPowerForChannel:0];
    //取得第一个通道的音频，注意音频强度范围时-160到0
  //  NSLog(@"%.1f------->>%.1f",power,wp);
  //  CGFloat progress=(1.0/160.0)*(power+160.0);
  //  [self.audioPower setProgress:progress];
    return power+160;

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

- (void)begin_recorder
{

    if (![self.audioRecorder isRecording])
    {
        [self.audioRecorder record];
    }
}

- (void)pause_recorder
{
    if ([self.audioRecorder isRecording]) {
        [self.audioRecorder pause];
    }
}

- (void)stop_recorder
{
    [self.audioRecorder stop];
    NSData *data = [self getVideoStremData];
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
    [dicM setValue:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
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
