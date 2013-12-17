
#import "ToastView.h"
#import <QuartzCore/QuartzCore.h>

@implementation ToastView
static ToastView *instance = nil;
+ (ToastView *)getInstance {
    if (instance == nil)
    {
        instance = [[ToastView alloc] init];
    }
	return instance;
}
-(UIViewController*)getTopViewController
{
    UINavigationController*  naviController = (UINavigationController*)[UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController* topViewController = naviController.topViewController;
    return topViewController;
}
- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
        UIViewController* topViewController = [self getTopViewController];
        contentLabel_ = [[UILabel alloc] initWithFrame:CGRectZero];
        contentLabel_.font = [UIFont systemFontOfSize:12];
        contentLabel_.textColor = [UIColor whiteColor];
        contentLabel_.backgroundColor = [UIColor clearColor];
        
        toastView_ = [[UIView alloc] initWithFrame:CGRectZero];
        toastView_.userInteractionEnabled = NO;
        toastView_.backgroundColor = [UIColor colorWithRed:0.184f green:0.184f blue:0.184f alpha:0.8];
        toastView_.layer.borderWidth = 1;
        toastView_.layer.borderColor = [[UIColor colorWithRed:0.145f green:0.145f blue:0.145f alpha:0.8] CGColor];
        toastView_.layer.cornerRadius = 4;
        [toastView_.layer setMasksToBounds:YES];
        [toastView_ addSubview:contentLabel_];
        toastView_.alpha = 0;
        //[topViewController.view addSubview:toastView_];
        [topViewController.navigationController.view addSubview:toastView_];
       
        //[contentLabel release];
        //[toastView_ release];

    }
    return self;
}

-(void)showToastViewWithContent:(NSString*)content
{
    NSLog(@"showToastViewWithContent=%@",content);
    UIViewController* topViewController = [self getTopViewController];
    contentLabel_.frame = CGRectMake(0, 0, 290, 21);
    contentLabel_.text = content;
    [contentLabel_ sizeToFit];
    int labelWidth = contentLabel_.frame.size.width;
    if (labelWidth > 280)
    {
        contentLabel_.frame = CGRectMake(0, 0, 280, 21);
        labelWidth = 280;
    }
     CGRect toastFrame = CGRectMake(0, 412, labelWidth + 20, 28);
     toastView_.frame = toastFrame;
    toastView_.center = CGPointMake(topViewController.view.center.x, 416);
     contentLabel_.center = CGPointMake(toastFrame.size.width * 0.5, 14);
    
    if (toastView_.alpha != 0)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    }
    [UIView animateWithDuration:0.5
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         toastView_.alpha = 0.8f;
                     }
                     completion:^(BOOL finished) {
                         [self performSelector:@selector(removeToastView) withObject:nil afterDelay:1];
                         
                     }];
    
}

-(void)removeToastView
{
    [UIView animateWithDuration:1
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         toastView_.alpha = 0;
                     }
                     completion:^(BOOL finished) {

                     }];
}

@end
