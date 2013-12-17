//
//  wifiFtpServerStartViewController.h
//  iphoneLibTest
//
//  Created by wu xiaoming on 13-7-1.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class FtpServer;
typedef enum SERVER_STATE
{
    SERVER_STATE_RUNNING,
    SERVER_STATE_STOP,
    SERVER_STATE_NOWIFI,
    
}SERVER_STATE;
@interface wifiFtpServerStartViewController : UIViewController<AVAudioPlayerDelegate>
{
    FtpServer	*theServer;
	NSString *baseDir;
    SERVER_STATE currentServerState_;
    NSTimer* wifiStateTimer_;
    bool serverStopedByUser_;
}
@property (nonatomic, retain) FtpServer *theServer;
@property (nonatomic, copy) NSString *baseDir;

@property (retain, nonatomic) IBOutlet UILabel *wifiStateTipLable;
@property (retain, nonatomic) IBOutlet UIImageView *wifiStateImageView;
@property (retain, nonatomic) IBOutlet UIImageView *toggleServerStateImageView;
@property (retain, nonatomic) IBOutlet UIButton *toggleServerStateButtonView;
@property (retain, nonatomic) IBOutlet UILabel *ftpUrlLable;
@property (retain, nonatomic) IBOutlet UILabel *ssidLabel;

-(void)didReceiveFileListChanged;
- (void)stopFtpServer;
- (IBAction)toggleServerState:(id)sender;
-(BOOL)getIsAnonymous;
-(NSString*)getFtpUserName;
-(NSString*)getFtpPWD;
@end
