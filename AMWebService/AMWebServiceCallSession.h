//
//  AMWebServiceCallSession.h
//  ConcertVault
//
//  Created by Andy Mroczkowski on 12/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AMWebServiceSession.h"
#import "AMWebServiceCall.h"

@interface AMWebServiceCallSession : AMWebServiceSession
{
}

- (id) initWithWebServiceCall:(id<AMWebServiceCall>)webServiceCall;

@property (nonatomic, retain, readonly) id result;

@end
