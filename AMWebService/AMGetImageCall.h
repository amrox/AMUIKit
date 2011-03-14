//
//  AMGetImageCall.h
//  ConcertVault
//
//  Created by Andy Mroczkowski on 2/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AMWebServiceCall.h"

@interface AMGetImageCall : NSObject <AMWebServiceCall>
{
}

- (id) initWithURL:(NSURL*)url;

- (NSURLRequest*) URLRequest;

- (id) resultFromResponseData:(NSData*)responseData error:(NSError**)outError;

@end
