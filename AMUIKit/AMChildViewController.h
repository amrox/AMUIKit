#import "UIViewController+AMViewController.h"

@protocol AMChildViewController <NSObject>

@property (nonatomic, assign) UIViewController* am_parentViewController;

@end
