//
//  rootViewController.m
//  WifiFtpServer
//
//  Created by 吴晓明 on 13-11-7.
//  Copyright (c) 2013年 吴晓明. All rights reserved.
//

#import "rootViewController.h"
#import "wifiFtpServerStartViewController.h"
#import <QuartzCore/QuartzCore.h>


@interface rootViewController ()

@end

@implementation rootViewController

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
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGRect btnFrame = CGRectMake(100, 100, 200, 50);
    UIButton* button = [[UIButton alloc] initWithFrame:btnFrame];
    [button setTitle:@"启动wifiFtp服务" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    button.layer.borderWidth = 1;
    button.layer.cornerRadius = 4;
    [self.view addSubview:button];
    button.center = self.view.center;
    [button addTarget:self action:@selector(showStartView) forControlEvents:UIControlEventTouchUpInside];
    
}
-(void)showStartView
{
    wifiFtpServerStartViewController* wifiView = [[wifiFtpServerStartViewController alloc] init];
    [self.navigationController pushViewController:wifiView animated:YES];
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
