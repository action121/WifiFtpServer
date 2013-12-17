//
//  wifiFtpSettingViewController.m
//  iphoneLibTest
//
//  Created by wu xiaoming on 13-7-2.
//
//

#import "wifiFtpSettingViewController.h"
#import "AESCrypt.h"
#import "FtpDefines.h"
#import "ToastView.h"

NSString* savedFilePath()
{
    NSArray *docFolders = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES );
    NSString* plistPath = [docFolders.lastObject stringByAppendingPathComponent:@"ftp.plist"];
    return plistPath;
}

@interface wifiFtpSettingViewController ()
@property(nonatomic,assign)BOOL isAnonymous;
@property(nonatomic,retain)NSString* userName;
@property(nonatomic,retain)NSString* userPwd;
@property(nonatomic,assign)int ftpPort;
@end

@implementation wifiFtpSettingViewController

#pragma mark - Life Cycle 

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}
- (void)dealloc {
    [_userName release];
    [_userPwd release];
    [_baseTable release];
    [_anonymousCheckBox release];
    [_ftpUserNameTextField release];
    [_ftpPWDTextField release];
    [_ftpPortTextField release];
    [_AnonymousTableCell release];
    [_userNameTableCell release];
    [_pwdTableCell release];
    [_portTableCell release];
    [super dealloc];
}
- (void)viewDidUnload {
    [self setBaseTable:nil];
    [self setAnonymousCheckBox:nil];
    [self setFtpUserNameTextField:nil];
    [self setFtpPWDTextField:nil];
    [self setFtpPortTextField:nil];
    [self setAnonymousTableCell:nil];
    [self setUserNameTableCell:nil];
    [self setPwdTableCell:nil];
    [self setPortTableCell:nil];
    [super viewDidUnload];
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addTitleNavigationBar];
    [self loadSetting];
    if (self.isAnonymous)
    {
        [self.anonymousCheckBox setImage:[UIImage imageNamed:@"ftp_checked_yes.png"] forState:UIControlStateNormal];
    }
    else
    {
        [self.anonymousCheckBox setImage:[UIImage imageNamed:@"ftp_checked_no.png"] forState:UIControlStateNormal];
    }
    self.ftpUserNameTextField.text = self.userName;
    self.ftpPWDTextField.text = self.userPwd;
    self.ftpPortTextField.text = [NSString stringWithFormat:@"%d",self.ftpPort];
}
#pragma mark - function

-(void)addTitleNavigationBar
{
    CGRect rc = self.view.frame;
    UINavigationBar *navigationBar_ = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, rc.size.width, 44)];
    navigationBar_.tintColor = [UIColor blackColor];//[UIColor colorWithRed:0.4f green:0.537f blue:0.8f alpha:1];

    UINavigationItem* titleBarItem_ = [[UINavigationItem alloc] initWithTitle:nil];
    UIButton* leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftButton setImage:[UIImage imageNamed:@"head_left_close.png"] forState:UIControlStateNormal];
    [leftButton setFrame:CGRectMake(10,8, 30, 28)];
    [leftButton addTarget:self action:@selector(leftBarButtonItemDown) forControlEvents:UIControlEventTouchUpInside];
    [navigationBar_ addSubview:leftButton];
    
    UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightButton setImage:[UIImage imageNamed:@"head_right_save.png"] forState:UIControlStateNormal];
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
    [titleBarItem_ setTitle:@"设置"];
    [titleBarItem_ release];
     navigationBar_.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:navigationBar_];
    [navigationBar_ release];
}

-(void)leftBarButtonItemDown
{
    [self.navigationController popViewControllerAnimated:YES];
}

//右边按钮按下
-(void)rightBarButtonItemDown
{
    //隐藏键盘
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
    if (!self.isAnonymous)
    {
        //不是匿名，用户名和密码都不能为空
        NSString* userNameAfterTrim = [self.ftpUserNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (userNameAfterTrim.length == 0)
        {
            [[ToastView getInstance] showToastViewWithContent:@"用户名不能为空！"];
            return;
        }
        NSString* userPWDAfterTrim = [self.ftpPWDTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (userPWDAfterTrim.length == 0)
        {
            [[ToastView getInstance] showToastViewWithContent:@"密码不能为空！"];
            return;
        }

    }
    //端口无论如何都不能为空
    NSString* portAfterTrim = [self.ftpPortTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (portAfterTrim.length == 0)
    {
        [[ToastView getInstance] showToastViewWithContent:@"端口不能为空！"];
        return;
    }
    //保存设置
    [self saveSetting];
    [self.navigationController popViewControllerAnimated:YES];
}

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
//保存设置，用户名和密码都采用aes加密
-(void)saveSetting
{
    NSString* plistPath = savedFilePath();

    NSMutableDictionary* info = [[NSMutableDictionary alloc] initWithCapacity:0];
    NSNumber* anonymousNumber = [NSNumber numberWithBool:_isAnonymous];
    NSString* aesUserName = [AESCrypt encrypt:self.ftpUserNameTextField.text password:ftp_aes_pwd];
    NSString* aesPwd = [AESCrypt encrypt:self.ftpPWDTextField.text password:ftp_aes_pwd];
    int port = [self.ftpPortTextField.text intValue];
    if (port == 0)
    {
        port = SERVER_PORT;
    }
    NSNumber* portNumber = [NSNumber numberWithInt:port];
    [info setObject:anonymousNumber forKey:FTP_ANONYMOUS_KEY];
    [info setObject:aesUserName forKey:FTP_USERNAME_KEY];
    [info setObject:aesPwd forKey:FTP_PASSWORD_KEY];
    [info setObject:portNumber forKey:FTP_PORT_KEY];
    [info writeToFile:plistPath atomically:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:ftp_paras_changed_notification object:nil userInfo:info];
    [info release];
}
//切换是否匿名
- (IBAction)toggleAnonymous:(id)sender
{
    if (self.isAnonymous)
    {
        self.isAnonymous = false;
        [self.anonymousCheckBox setImage:[UIImage imageNamed:@"ftp_checked_no.png"] forState:UIControlStateNormal];
    }
    else
    {
        self.isAnonymous = true;
        [self.anonymousCheckBox setImage:[UIImage imageNamed:@"ftp_checked_yes.png"] forState:UIControlStateNormal];
    }
}
#pragma mark - tableview delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row)
    {
        case 0:
        {
            return self.AnonymousTableCell;
        }
        case 1:
        {
            return self.userNameTableCell;
        }
        case 2:
        {
            return self.pwdTableCell;
        }
        case 3:
        {
            return self.portTableCell;
        }
        default:
            break;
    }
    return nil;
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
