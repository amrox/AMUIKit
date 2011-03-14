//
//  WebServiceCallSession.h
//  ConcertVault
//
//  Created by Andy Mroczkowski on 12/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AMURLRequestManager.h"


typedef enum 
{
	AMWebServiceSessionStatusUnknown,
	AMWebServiceSessionInitialized,
	AMWebServiceSessionInProgress,
	AMWebServiceSessionSuccess,
	AMWebServiceSessionCancelled,
	AMWebServiceSessionFailure,
} 
AMWebServiceSessionStatus;




@interface AMWebServiceSession : NSObject
{
}

@property (nonatomic, retain) AMURLRequestManager* URLRequestManager;


@property (nonatomic, readonly) AMWebServiceSessionStatus status;
@property (nonatomic, readonly, retain) NSError* error;

- (void) run;
- (void) cancel;

- (BOOL) isComplete;


@property (nonatomic, assign) NSInteger tag;


@end










// --------------------------------------------------------------------------
#pragma mark -

@interface AMWebServiceSession (SubclassesOnly)

@property (nonatomic, readwrite) AMWebServiceSessionStatus status;
@property (nonatomic, readwrite, retain) NSError* error;

@end