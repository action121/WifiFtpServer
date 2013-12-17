//
//  wifiFtpSettingViewController.h
//  iphoneLibTest
//
//  Created by wu xiaoming on 13-7-2.
//
//

#import <UIKit/UIKit.h>

extern NSString* savedFilePath();

@interface wifiFtpSettingViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>

@property (retain, nonatomic) IBOutlet UITableView *baseTable;
@property (retain, nonatomic) IBOutlet UIButton *anonymousCheckBox;
@property (retain, nonatomic) IBOutlet UITextField *ftpUserNameTextField;
@property (retain, nonatomic) IBOutlet UITextField *ftpPWDTextField;
@property (retain, nonatomic) IBOutlet UITextField *ftpPortTextField;

@property (retain, nonatomic) IBOutlet UITableViewCell *AnonymousTableCell;
@property (retain, nonatomic) IBOutlet UITableViewCell *userNameTableCell;
@property (retain, nonatomic) IBOutlet UITableViewCell *pwdTableCell;
@property (retain, nonatomic) IBOutlet UITableViewCell *portTableCell;
- (IBAction)toggleAnonymous:(id)sender;

@end
