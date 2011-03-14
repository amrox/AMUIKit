//
//  AMWebServiceCallSession.m
//  ConcertVault
//
//  Created by Andy Mroczkowski on 12/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AMWebServiceCallSession.h"


@interface AMWebServiceCallSession ()
@property (nonatomic, retain, readwrite) id result;
@property (nonatomic, retain) id<AMWebServiceCall> webServiceCall;
@property (nonatomic, assign) AMURLRequestManagerTicket ticket;
@end

@implementation AMWebServiceCallSession

@synthesize webServiceCall = _webServiceCall;
@synthesize result = _result;
@synthesize ticket = _ticket;

- (id) initWithWebServiceCall:(id<AMWebServiceCall>)webServiceCall
{
	self = [super init];
	if (self != nil)
	{
		self.webServiceCall = webServiceCall;
		self.ticket = kAMURLRequestManagerTicketInvalid;
	}
	return self;
}


- (void) dealloc
{
	[_webServiceCall release];
	[_result release];
	[super dealloc];
}


- (void) run
{
	[super run];
	
	self.ticket = [self.URLRequestManager queueRequest:[self.webServiceCall URLRequest]
										 informingTarget:self
											 selector:@selector(requestDidFinish:userInfo:error:)
											 userInfo:nil];
}


- (void) cancel
{
	[self.URLRequestManager cancelRequestWithID:self.ticket];
	self.status = AMWebServiceSessionCancelled;
}


- (void) requestDidFinish:(NSData*)data userInfo:(id)userInfo error:(NSError*)error
{
	if( error != nil )
	{
		self.error = error;
		self.status = AMWebServiceSessionFailure;
		return;
	}
	
	NSError* resultError = nil;
	self.result = [self.webServiceCall resultFromResponseData:data error:&resultError];
	if( self.result == nil )
	{
		self.error = error;
		self.status = AMWebServiceSessionFailure;
		return;
	}
	
	self.status = AMWebServiceSessionSuccess;
}

@end
