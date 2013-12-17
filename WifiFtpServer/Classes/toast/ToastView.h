

#import <Foundation/Foundation.h>

@interface ToastView : NSObject
{
    UIView* toastView_;
    UILabel* contentLabel_;
}
+ (ToastView *)getInstance;
-(void)showToastViewWithContent:(NSString*)content;
@end
