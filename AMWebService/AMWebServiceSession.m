//
//  WebServiceCallSession.m
//  ConcertVault
//
//  Created by Andy Mroczkowski on 12/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AMWebServiceSession.h"

@interface AMWebServiceSession ()
@property (nonatomic, readwrite) AMWebServiceSessionStatus status;
@property (nonatomic, readwrite, retain) NSError* error;
@end


@implementation AMWebServiceSession

@synthesize URLRequestManager = _networkManager;
@synthesize status = _status;
@synthesize error = _error;
@synthesize tag;


- (id) init
{
	self = [super init];
	if (self != nil)
	{
		self.status = AMWebServiceSessionInitialized;
	}
	return self;
}


- (void) dealloc
{
	[_error release];
	[_networkManager release];
	[super dealloc];
}


- (void) run
{
	NSAssert( self.URLRequestManager, @"URLRequestManager is nil at runtime" );
}

- (BOOL) isComplete
{
	return (self.status == AMWebServiceSessionSuccess ||
			self.status == AMWebServiceSessionFailure ||
			self.status == AMWebServiceSessionCancelled);
}

- (void) cancel
{
	[self.URLRequestManager cancelAllRequestsWithTarget:self];
	self.status = AMWebServiceSessionCancelled;
}

@end
