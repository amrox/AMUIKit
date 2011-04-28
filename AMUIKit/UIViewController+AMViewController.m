#import "UIViewController+AMViewController.h"

#import "AMParentViewController.h"


@implementation UIViewController (AMViewController)

- (void) am_pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	NSParameterAssert(viewController);
	
	if( self.navigationController != nil )
	{
		[self.navigationController pushViewController:viewController animated:animated];
		return;
	}
	
	if( [self respondsToSelector:@selector(am_parentViewController)] )
	{
		UIViewController* parentViewController = [self performSelector:@selector(am_parentViewController)];
		[parentViewController am_pushViewController:viewController animated:animated];
		return;
	}
		
	NSAssert(false, @"no navigationController or parentViewController");
}

@end
