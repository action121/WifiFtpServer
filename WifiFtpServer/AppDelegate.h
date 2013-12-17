//
//  AppDelegate.h
//  WifiFtpServer
//
//  Created by 吴晓明 on 13-11-7.
//  Copyright (c) 2013年 吴晓明. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ftpNavigationController : UINavigationController

@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property(strong,nonatomic)ftpNavigationController* naviVC;
@end
