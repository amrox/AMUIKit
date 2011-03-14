//
//  AMGetImageCall.m
//  ConcertVault
//
//  Created by Andy Mroczkowski on 2/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AMGetImageCall.h"


@interface AMGetImageCall ()
@property (nonatomic, retain) NSURL* url;
@end

@implementation AMGetImageCall

@synthesize url = _url;


- (id) initWithURL:(NSURL*)url
{
	self = [super init];
	if (self != nil)
	{
		_url = [url retain];
	}
	return self;
}


- (void) dealloc
{
	[_url release];
	[super dealloc];
}


- (NSURLRequest*) URLRequest
{
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:self.url];
	[request setHTTPMethod:@"GET"];
	return request;
}


- (id) resultFromResponseData:(NSData*)responseData error:(NSError**)outError
{
	UIImage* image = [[UIImage alloc] initWithData:responseData];
	return [image autorelease];
	
	// TODO: handle is image is nil;
}


@end
