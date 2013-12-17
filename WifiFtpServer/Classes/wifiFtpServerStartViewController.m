//
//  wifiFtpServerStartViewController.m
//  iphoneLibTest
//
//  Created by wu xiaoming on 13-7-1.
//
//

#import "wifiFtpServerStartViewController.h"
#import <SystemConfiguration/SystemConfiguration.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
#include <ifaddrs.h>
#import "FtpServer.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import <QuartzCore/QuartzCore.h>
#import "NetworkController.h"
#import <pthread.h>
#import "AESCrypt.h"
#import "wifiFtpSettingViewController.h"
#import "ToastView.h"

@interface wifiFtpServerStartViewController ()
@property(nonatomic,retain)AVAudioPlayer *Player ;
@property(nonatomic,assign)UIBackgroundTaskIdentifier bgTask;
@property(nonatomic,retain)NSString* BSSID;
@property(nonatomic,assign)pthread_mutex_t serverMutex;
@property(nonatomic,assign)pthread_mutex_t BSSIDMutex;
@property(nonatomic,assign)BOOL isAnonymous;
@property(nonatomic,retain)NSString* userName;
@property(nonatomic,retain)NSString* userPwd;
@property(nonatomic,assign)int ftpPort;
@end

@implementation wifiFtpServerStartViewController
@synthesize theServer, baseDir;

#pragma mark - paras for ftpConnection
-(BOOL)getIsAnonymous
{
    return self.isAnonymous;
}
-(NSString*)getFtpUserName
{
    return self.userName;
}
-(NSString*)getFtpPWD
{
    return self.userPwd;
}
#pragma mark - Life Cycle 
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}
-(void)dealloc
{
    pthread_mutex_destroy(&_serverMutex);
    pthread_mutex_destroy(&_BSSIDMutex);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopListenWifiState];
    [self stopFtpServer];
    [_wifiStateImageView release];
    [_wifiStateTipLable release];
    [_BSSID release];
    [_userPwd release];
    [_userName release];
    [_Player release];
    [super dealloc];
}
- (void)viewDidUnload {
    [self setWifiStateTipLable:nil];
    [self setWifiStateImageView:nil];
    [self setToggleServerStateImageView:nil];
    [self setToggleServerStateButtonView:nil];
    [self setFtpUrlLable:nil];
    [self setSsidLabel:nil];
    [self setPlayer:nil];
    [super viewDidUnload];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addTitleNavigationBar];
    NSArray *docFolders = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES );
    self.baseDir = docFolders.lastObject;

    //加载参数 是否匿名、用户名、密码、端口
    [self loadSetting];
    //启动后有个定时器监听网络状态，加互斥锁防止取值有误
    pthread_mutex_init(&_serverMutex, NULL);
    pthread_mutex_init(&_BSSIDMutex, NULL);
    _BSSID = [[NSString alloc] initWithString:@""];
    theServer = nil;
    serverStopedByUser_ = true;
    wifiStateTimer_ = nil;
    currentServerState_ = SERVER_STATE_STOP;
    if ([NetworkController getConnectionType] != 1)
    {
        currentServerState_ = SERVER_STATE_NOWIFI;
    }
    [self setAllStateViewsState];
    //开始监听，除非该页面关闭，否则不停
    [self startListenWifiState];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAppEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAppEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onFtpParasChanged:)
                                                 name:ftp_paras_changed_notification
                                               object:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
  
    //播放一段无音量的音频，程序进入后台后可继续使用
    NSError *activationError = nil;
    [[AVAudioSession sharedInstance] setActive: YES error: &activationError];
    NSString* path = [[NSBundle mainBundle] pathForResource:@"silent" ofType:@"wav"];
    NSURL* filePathUrl = [NSURL fileURLWithPath:path];
	_Player = [[AVAudioPlayer alloc] initWithContentsOfURL: filePathUrl error:nil];
    
    [_Player setDelegate:self];
    _Player.numberOfLoops = -1;
    _Player.volume = 1;
    //注册后台任务
    _bgTask = UIBackgroundTaskInvalid;
}

#pragma mark - function

-(void)loadSetting
{
    self.isAnonymous = true;
    self.userName = [[NSString alloc] initWithString:@""];
    self.userPwd = [[NSString alloc] initWithString:@""];
    self.ftpPort = SERVER_PORT;
    NSString* plistPath = savedFilePath();
    if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath])
    {
        NSMutableDictionary* ftpDicInfo = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
        if (ftpDicInfo)
        {
            NSNumber* anonymousNumber = [ftpDicInfo objectForKey:FTP_ANONYMOUS_KEY];
            if (anonymousNumber)
            {
                self.isAnonymous = [anonymousNumber boolValue];
            }
            NSString* userNameStr = [ftpDicInfo objectForKey:FTP_USERNAME_KEY];
            if (userNameStr)
            {
                userNameStr = [AESCrypt decrypt:userNameStr password:ftp_aes_pwd];
                if (userNameStr)
                {
                    [_userName release];
                    self.userName = [[NSString alloc] initWithString:userNameStr];
                }
            }
            NSString* pwdStr = [ftpDicInfo objectForKey:FTP_PASSWORD_KEY];
            if (pwdStr)
            {
                pwdStr = [AESCrypt decrypt:pwdStr password:ftp_aes_pwd];
                if (pwdStr)
                {
                    [_userPwd release];
                    self.userPwd = [[NSString alloc] initWithString:pwdStr];
                }
            }
            NSNumber* portNumber = [ftpDicInfo objectForKey:FTP_PORT_KEY];
            if (portNumber)
            {
                int port = [portNumber intValue];
                if (port == 0)
                {
                    port = SERVER_PORT;
                }
                self.ftpPort = port;
            }
           
        }
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [self starPlay];
}

//设置界面改变了参数
-(void)onFtpParasChanged:(NSNotification*)info
{
    if (!info)
    {
        return;
    }
    NSDictionary* userInfo = info.userInfo;
    if (!userInfo)
    {
        return;
    }
    NSNumber* anonymousNumber = [userInfo objectForKey:FTP_ANONYMOUS_KEY];
    bool isAnonymous = true;
    if (anonymousNumber)
    {
        isAnonymous = [anonymousNumber boolValue];
    }
    NSString* userName = [userInfo objectForKey:FTP_USERNAME_KEY];
    userName = [AESCrypt decrypt:userName password:ftp_aes_pwd];
    NSString* password = [userInfo objectForKey:FTP_PASSWORD_KEY];
    password = [AESCrypt decrypt:password password:ftp_aes_pwd];
    NSString* portStr = [userInfo objectForKey:FTP_PORT_KEY];
    bool needStopServer = false;
    if (self.isAnonymous == isAnonymous)
    {
        if (isAnonymous && [portStr intValue] != self.ftpPort)
        {
            //匿名，但端口改变了
            needStopServer = true;
        }
        else if(!isAnonymous && (![userName isEqualToString:self.userName] || ![password isEqualToString:self.userPwd]))
        {
            //非匿名，用户名或者密码改变了
            needStopServer = true;
        }
    }
    else
    {
        //匿名状态改变了
        needStopServer = true;
    }
    if (needStopServer)
    {
        if ([self getServer])
        {
            serverStopedByUser_ = true;
            [[ToastView getInstance] showToastViewWithContent:@"远程管理设置信息已修改，请重新启动"];
        }
        else
        {
            [[ToastView getInstance] showToastViewWithContent:@"修改成功"];
        }
        [self stopFtpServer];
        currentServerState_ = SERVER_STATE_STOP;
        [self setAllStateViewsState];
        [self loadSetting];

    }
}
-(void)onAppEnterBackground:(NSNotification*)info
{
    if([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
    {
        UIApplication* app = [UIApplication sharedApplication];
        UIBackgroundTaskIdentifier newTask = [app beginBackgroundTaskWithExpirationHandler:nil];
        if(_bgTask!= UIBackgroundTaskInvalid) {
            
            [app endBackgroundTask: _bgTask];
        }
        _bgTask = newTask;
        //for debug
        //[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(printBackgroundTime) userInfo:nil repeats:YES];

    }
}
//for debug
//-(void)printBackgroundTime
//{
//    NSLog(@"time : %f",[UIApplication sharedApplication].backgroundTimeRemaining);
//    if ([_Player isPlaying])
//    {
//        NSLog(@"playing");
//    }
//    else
//    {
//        NSLog(@"play stop");
//    }
//}
-(void)onAppEnterForeground:(NSNotification*)info
{
    [self starPlay];
}
- (void)starPlay
{
    if (![_Player isPlaying])
    {
        [_Player play];
    }
}

- (void)stopPlay
{
    if ([_Player isPlaying])
    {
        [_Player stop];
    }
}
-(void)listenWifiState
{
    SERVER_STATE oldState = currentServerState_;
    if ([NetworkController getConnectionType] != 1)
    {
        //非wifi网络
        if ([self getServer])
        {
            //网络状态改变了，此时不是用户点击了切换按钮
            serverStopedByUser_ = false;
        }
        currentServerState_ = SERVER_STATE_NOWIFI;
        [self stopFtpServer]; 
    }
    else
    {
        bool needStop = false;
        NSString* bssid = @"";
        id ssid = [NetworkController fetchSSIDInfo];
        if (ssid && [ssid isKindOfClass:[NSDictionary class]])
        {
            //当前wifi网络的BSSID
            bssid = [ssid objectForKey:@"BSSID"];
        }
        if ([self getBSSID].length > 0 && bssid && ![bssid isEqualToString:[self getBSSID]])
        {
            //用户在系统设置界面更改了wifi连结点，或者wifi自动切换了连结点，网络环境变化了，需要停止ftp服务
            serverStopedByUser_ = true;
            needStop = true;
        }
        if (![self getServer])
        {
            //getServer为空说明ftp服务已经停了
            if (!serverStopedByUser_ && !needStop)
            {
                //既不是用户主动停止也没有改变网络环境，有可能是网络不稳定造成的停止，重启服务
                currentServerState_ = SERVER_STATE_RUNNING;
                [self startFtpServer];
            }
            else
            {
                 currentServerState_ = SERVER_STATE_STOP;
            }
            
        }
        else
        {
            //getServer不为空说明ftp服务正在运行
            if (needStop)
            {
                //网络环境改变，需要停止服务
                serverStopedByUser_ = true;
                currentServerState_ = SERVER_STATE_STOP;
                [self stopFtpServer];
                [self setBSSID:bssid];
            }
            else
            {
                currentServerState_ = SERVER_STATE_RUNNING;
            }
            
        }
    
    }
    if (oldState != currentServerState_)
    {
        //网络状态发生改变，重置页面显示
        [self setAllStateViewsState];
    }
    
}
-(void)startListenWifiState
{
    [self stopListenWifiState];
    wifiStateTimer_ = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(listenWifiState) userInfo:nil repeats:YES];
}

-(void)stopListenWifiState
{
    if (wifiStateTimer_)
    {
        [wifiStateTimer_ invalidate];
        wifiStateTimer_ = nil;
    }
}
-(void)setBSSID:(NSString *)bssid
{
    pthread_mutex_lock(&_BSSIDMutex);
    [_BSSID release];
    _BSSID = [[NSString alloc] initWithString:bssid];
    pthread_mutex_unlock(&_BSSIDMutex);
}
-(NSString*)getBSSID
{
    NSString* ret = nil;
    pthread_mutex_lock(&_BSSIDMutex);
    ret = _BSSID;
    pthread_mutex_unlock(&_BSSIDMutex);
    return ret;
}
-(void)setAllStateViewsState
{
    if (currentServerState_ == SERVER_STATE_STOP)
    {
        _wifiStateTipLable.text = @"启动后可以从电脑远程管理手机文件";
        [_wifiStateTipLable setTextColor:[UIColor colorWithRed:51/255.f green:51/255.f blue:51/255.f alpha:1]];
        _ftpUrlLable.hidden = YES;
        NSString *localIPAddress = [ NetworkController localWifiIPAddress ];
        _ftpUrlLable.text = [NSString stringWithFormat:@"ftp://%@:%d",localIPAddress,self.ftpPort];
        NSString* ssidName = @"未知";
        NSString* bssid = @"";
        id ssid = [NetworkController fetchSSIDInfo];
        if ([ssid isKindOfClass:[NSDictionary class]])
        {
            ssidName = [ssid objectForKey:@"SSID"];
            bssid = [ssid objectForKey:@"BSSID"];
        }
        [self setBSSID:bssid];
        _ssidLabel.hidden = NO;
        _ssidLabel.text = ssidName;
        _ssidLabel.textColor = [UIColor colorWithRed:51/255.f green:51/255.f blue:51/255.f alpha:1];
        _toggleServerStateImageView.hidden = NO;
        _toggleServerStateButtonView.userInteractionEnabled = YES;
        UIEdgeInsets contentEdgeInsets =  UIEdgeInsetsZero;
        contentEdgeInsets.left = 40;
        _toggleServerStateButtonView.contentEdgeInsets = contentEdgeInsets;

        _wifiStateImageView.image = [UIImage imageNamed:@"wifi_state1.png"];
        _toggleServerStateImageView.image = [UIImage imageNamed:@"connect.png"];
        [_toggleServerStateButtonView setTitle:@"启动服务" forState:UIControlStateNormal];
        [_toggleServerStateButtonView setTitleColor:[UIColor colorWithRed:231/255.f green:128/255.f blue:24/255.f alpha:1] forState:UIControlStateNormal];
    }
    else if(currentServerState_ == SERVER_STATE_RUNNING)
    {
        _wifiStateTipLable.text = @"请在“我的电脑”地址栏中输入：";
        [_wifiStateTipLable setTextColor:[UIColor colorWithRed:51/255.f green:51/255.f blue:51/255.f alpha:1]];
        _ftpUrlLable.hidden = NO;
        _ftpUrlLable.layer.cornerRadius = 10;
        NSString *localIPAddress = [ NetworkController localWifiIPAddress ];
        _ftpUrlLable.text = [NSString stringWithFormat:@"ftp://%@:%d",localIPAddress,self.ftpPort];
        NSString* ssidName = @"未知";
        NSString* bssid = @"";
        id ssid = [NetworkController fetchSSIDInfo];
        if ([ssid isKindOfClass:[NSDictionary class]])
        {
            ssidName = [ssid objectForKey:@"SSID"];
            bssid = [ssid objectForKey:@"BSSID"];
        }
        _ssidLabel.hidden = NO;
        _ssidLabel.text = ssidName;
        [self setBSSID:bssid];
        _ssidLabel.textColor = [UIColor colorWithRed:51/255.f green:51/255.f blue:51/255.f alpha:1];
        _toggleServerStateImageView.hidden = NO;
        _toggleServerStateButtonView.userInteractionEnabled = YES;
        UIEdgeInsets contentEdgeInsets =  UIEdgeInsetsZero;
        contentEdgeInsets.left = 40;
        _toggleServerStateButtonView.contentEdgeInsets = contentEdgeInsets;

        _wifiStateImageView.image = [UIImage imageNamed:@"wifi_state1.png"];
        _toggleServerStateImageView.image = [UIImage imageNamed:@"disconnect.png"];
        [_toggleServerStateButtonView setTitle:@"停止服务" forState:UIControlStateNormal];
        [_toggleServerStateButtonView setTitleColor:[UIColor colorWithRed:133/255.f green:11/255.f blue:22/255.f alpha:1] forState:UIControlStateNormal];
    }
    else if(currentServerState_ == SERVER_STATE_NOWIFI)
    {
        _wifiStateTipLable.text = @"启动后可以从电脑远程管理手机文件";
        [_wifiStateTipLable setTextColor:[UIColor colorWithRed:170/255.f green:170/255.f blue:170/255.f alpha:1]];
        _ftpUrlLable.hidden = YES;
        _ssidLabel.hidden = YES;
        _toggleServerStateImageView.hidden = YES;
        _toggleServerStateButtonView.userInteractionEnabled = NO;
        _toggleServerStateButtonView.contentEdgeInsets = UIEdgeInsetsZero;

        [_toggleServerStateButtonView setTitleColor: [UIColor colorWithRed:146/255.f green:146/255.f blue:146/255.f alpha:1] forState:UIControlStateNormal];
        
        _wifiStateImageView.image = [UIImage imageNamed:@"wifi_state0.png"];
        _toggleServerStateImageView.image = [UIImage imageNamed:@"connect.png"];
        [_toggleServerStateButtonView setTitle:@"无WIFI网络" forState:UIControlStateNormal];
        [_toggleServerStateButtonView setTitleColor:[UIColor colorWithRed:170/255.f green:170/255.f blue:170/255.f alpha:1] forState:UIControlStateNormal];
    }
}
//创建头部导航
-(void)addTitleNavigationBar
{
    CGRect rc = self.view.frame;
    UINavigationBar *navigationBar_ = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, rc.size.width, 44)];
    navigationBar_.tintColor = [UIColor blackColor];//[UIColor colorWithRed:0.4f green:0.537f blue:0.8f alpha:1];
    UINavigationItem* titleBarItem_ = [[UINavigationItem alloc] initWithTitle:nil];
    UIButton* leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftButton setImage:[UIImage imageNamed:@"head_left_close.png"] forState:UIControlStateNormal];
    [leftButton setFrame:CGRectMake(10, 8, 30, 28)];
    [leftButton addTarget:self action:@selector(leftBarButtonItemDown) forControlEvents:UIControlEventTouchUpInside];
    [navigationBar_ addSubview:leftButton];
    
    UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightButton setImage:[UIImage imageNamed:@"head_right_set.png"] forState:UIControlStateNormal];
    float x = 0;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        x = 768 - 10 - 26;
    }
    else
    {
        x = 320 - 10 - 26;
    }
    [rightButton setFrame:CGRectMake(x, 12, 26, 20)];
    [rightButton addTarget:self action:@selector(rightBarButtonItemDown) forControlEvents:UIControlEventTouchUpInside];
    rightButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [navigationBar_ addSubview:rightButton];
    
    [navigationBar_ pushNavigationItem:titleBarItem_ animated:NO];
    [titleBarItem_ setTitle:@"远程管理"];
    [titleBarItem_ release];
    navigationBar_.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:navigationBar_];
    [navigationBar_ release];
}
//开始服务／停止服务
- (IBAction)toggleServerState:(id)sender
{
    if (currentServerState_ == SERVER_STATE_STOP)
    {
        serverStopedByUser_ = false;
        currentServerState_ = SERVER_STATE_RUNNING;
        [self startFtpServer];
    }
    else if(currentServerState_ == SERVER_STATE_RUNNING)
    {
        serverStopedByUser_ = true;
        currentServerState_ = SERVER_STATE_STOP;
        [self stopFtpServer];
    }
	
    [self setAllStateViewsState];
}
-(FtpServer*)getServer
{
    FtpServer* ret = nil;
    pthread_mutex_lock(&_serverMutex);
    ret = theServer;
    pthread_mutex_unlock(&_serverMutex);
    return ret;
}
-(void)setServer:(FtpServer*)server
{
    pthread_mutex_lock(&_serverMutex);
    self.theServer = server;
    pthread_mutex_unlock(&_serverMutex);
}
-(void)startFtpServer
{
    if(![self getServer])
	{
        FtpServer *aServer = [[ FtpServer alloc ] initWithPort:self.ftpPort withDir:self.baseDir notifyObject:self ];
        [self setServer:aServer];
        aServer.clientEncoding = NSUTF8StringEncoding;
        [aServer release];
	}
}
- (void)stopFtpServer
{
	if([self getServer])
	{
       
		[theServer stopFtpServer];
		[theServer release];
		theServer=nil;
	}
}
-(void)didReceiveFileListChanged
{
	//NSLog(@"didReceiveFileListChanged");
}
-(void)leftBarButtonItemDown
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@""  message:@"是否退出远程管理" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [alert show];
    [alert release];

}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != 0)
    {
        //点击了确定退出的按钮，停止一切活动，关闭界面
        [self stopPlay];
        [self stopListenWifiState];
        [self stopFtpServer];
        [self.navigationController popViewControllerAnimated:YES];
    }
}
//右边按钮按下
-(void)rightBarButtonItemDown
{
    wifiFtpSettingViewController* settingVC = [[wifiFtpSettingViewController alloc] init];
    [self.navigationController pushViewController:settingVC animated:YES];
    [settingVC release];
}
#pragma mark - supportedInterfaceOrientations 
-(BOOL)shouldAutorotate
{
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}


@end
