
#import "AMURLRequestManager.h"

#define kInitialConnectionCapacity 4

#ifdef LOG_DEBUG
#define _LOG_DEBUG LOG_DEBUG
#else
#define _LOG_DEBUG(...)
#endif

typedef struct
{
	AMURLRequestManagerTicket	connectionID;
	id<NSObject>				target;
	SEL							selector;
	id							userInfo;
	
	NSURLRequest*				request;
	NSURLConnection*			connection;
	NSMutableData*				data;
	NSError*					error;
} AMURLRequestManagerConnectionDetails;


static AMURLRequestManagerConnectionDetails *NewConnectionDetails()
{
	AMURLRequestManagerConnectionDetails *details = calloc( 1, sizeof(AMURLRequestManagerConnectionDetails) );
	return details;
}


static void FreeConnectionDetails( AMURLRequestManagerConnectionDetails *details )
{
	[details->request release];
	[details->connection release];
	[details->data release];
	[details->error release];
	[details->userInfo release];
	[details->target release];
	free( details );
}


@interface AMURLRequestManager ()

- (NSUInteger)nextTicket;
- (void)removeConnectionDetails:(AMURLRequestManagerConnectionDetails *)details;
- (void) startInternalThread;
- (void) checkQueue;

@property (assign) BOOL started;
@property (assign) BOOL paused;

@end


@implementation AMURLRequestManager

@synthesize maxConcurrentConnectionCount = _maxConcurrentConnectionCount;
@synthesize started = _started;
@synthesize paused = _paused;

- (id) initUsingBackgroundThread:(BOOL)useThread
{
	self = [super init];
	if (self != nil)
	{
		pthread_mutex_init( &_mutex, NULL );
		pthread_cond_init( &_cond, NULL );
		_ticketCounter = 0;
		_maxConcurrentConnectionCount = kInitialConnectionCapacity;
		_activeRequests = [[NSMutableArray alloc] initWithCapacity:kInitialConnectionCapacity];	
		_pendingRequests = [[NSMutableArray alloc] initWithCapacity:kInitialConnectionCapacity];
		
		if( useThread )
		{
			[self startInternalThread];
		}
		else
		{
			_myRunLoop = [NSRunLoop currentRunLoop];
			self.started = YES;
		}
	}
	return self;
}


- (void) dealloc
{
	for( NSValue *value in _activeRequests )
	{
		FreeConnectionDetails( (AMURLRequestManagerConnectionDetails *)[value pointerValue] );
	}
	
	pthread_mutex_destroy( &_mutex );
	[_activeRequests release];
	[_internalThread release];
	[super dealloc];
}


- (void) startInternalThread
{
	if( !self.started )
	{
		_internalThread = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
		[_internalThread start];
	}
}


- (void) stopInternalThread
{
	if( _internalThread != nil )
	{
		[_internalThread cancel];
		
		pthread_mutex_lock(&_mutex);
		pthread_cond_signal(&_cond);
		pthread_mutex_unlock(&_mutex);
		
		while( self.started )
			[NSThread sleepForTimeInterval:0.5];
	}
}


- (void) run
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	_myRunLoop = [NSRunLoop currentRunLoop];
	
	self.started = YES;
	
	while (![_internalThread isCancelled])
	{
        NSAutoreleasePool *subpool = [[NSAutoreleasePool alloc] init];
//		[self checkQueue];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantFuture]];
        [subpool release];
		
		pthread_mutex_lock(&_mutex);
		while( (self.paused || ![self hasConnections]) && ![_internalThread isCancelled] )
			pthread_cond_wait(&_cond, &_mutex);
		pthread_mutex_unlock(&_mutex);
    }
	
	self.started = NO;
	
	[pool release];
}


- (BOOL) hasConnections
{
	return (([_activeRequests count] > 0) || ([_pendingRequests count] > 0)); 
}


- (NSUInteger) nextTicket
{
	NSUInteger ret;
	pthread_mutex_lock( &_mutex );
	ret = ++_ticketCounter;
	_LOG_DEBUG( @"new ticket: %d", ret );
	pthread_mutex_unlock( &_mutex );
	return ret;
}


- (void) checkQueue
{
	if (self.paused) return;
	
	NSValue* detailsValue = nil;
	AMURLRequestManagerConnectionDetails* details = NULL;
	
	pthread_mutex_lock( &_mutex );
	if(([_pendingRequests count] > 0) &&
	   ([_activeRequests count] < self.maxConcurrentConnectionCount) )
	{
		detailsValue = [_pendingRequests objectAtIndex:0];
		[_activeRequests addObject:detailsValue];
		[_pendingRequests removeObjectAtIndex:0];
		
		
		details = (AMURLRequestManagerConnectionDetails *)[detailsValue pointerValue];
		details->data = [[NSMutableData alloc] init];
		details->connection = [[NSURLConnection alloc] initWithRequest:details->request
															  delegate:self
													  startImmediately:NO];
		
		_LOG_DEBUG( @"starting: %@", [details->request URL] );

	}
	pthread_mutex_unlock( &_mutex );
	
	if( details != NULL )
	{
		[details->connection scheduleInRunLoop:_myRunLoop forMode:NSDefaultRunLoopMode];
		[details->connection start];
		
		pthread_mutex_lock(&_mutex);
		pthread_cond_signal(&_cond);
		pthread_mutex_unlock(&_mutex);
		
		[self performSelector:_cmd withObject:nil afterDelay:0.];
	}
}


- (AMURLRequestManagerTicket) queueRequest:(NSURLRequest*)request informingTarget:(id<NSObject>)target selector:(SEL)selector userInfo:(id)userInfo
{
	if( !self.started )
		kAMURLRequestManagerTicketInvalid;
	
	NSUInteger newTicket = [self nextTicket];
	
	AMURLRequestManagerConnectionDetails *details = NewConnectionDetails();
	details->connectionID = newTicket;
	details->target = [target retain];
	details->selector = selector;
	details->userInfo = [userInfo retain];
	details->request = [request retain];
	details->connection = nil;
	details->data = nil;
	details->error = nil;
	
	pthread_mutex_lock(&_mutex);
	_LOG_DEBUG( @"queueing %@", [details->request URL] );
	[_pendingRequests addObject:[NSValue valueWithPointer:details]];
	pthread_mutex_unlock(&_mutex);
	
	[self checkQueue];
	
	return newTicket;
}


- (AMURLRequestManagerTicket)queueGETRequestForURL:(NSURL *)URL informingTarget:(NSObject *)target selector:(SEL)selector userInfo:(id)userInfo
{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	[request setHTTPMethod:@"GET"];
	return [self queueRequest:request informingTarget:target selector:selector userInfo:userInfo];
}


- (AMURLRequestManagerConnectionDetails *)detailsForConnection:(NSURLConnection *)connection
{
	AMURLRequestManagerConnectionDetails* targetDetails = NULL;
	pthread_mutex_lock( &_mutex );
	for( NSValue* value in [_activeRequests arrayByAddingObjectsFromArray:_pendingRequests] )
	{
		AMURLRequestManagerConnectionDetails* details = (AMURLRequestManagerConnectionDetails *)[value pointerValue];
		if( details->connection == connection )
		{
			targetDetails = details;
			break;
		}
	}
	pthread_mutex_unlock( &_mutex );
	
	if( targetDetails == NULL )
	{
		_LOG_DEBUG( @"halp" );
	}
	
	NSAssert( targetDetails, @"Could not find connection details for connection %@", connection );
	return targetDetails;
}


- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	AMURLRequestManagerConnectionDetails* details = [self detailsForConnection:connection];
	[details->data appendData:data];
}


- (void) notifyTarget:(NSValue*)detailsValue
{
	AMURLRequestManagerConnectionDetails* details = (AMURLRequestManagerConnectionDetails*)[detailsValue pointerValue];
	
	objc_msgSend( details->target, details->selector,
				 details->data, details->userInfo, details->error );
	
	[self removeConnectionDetails:details];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	AMURLRequestManagerConnectionDetails *details = [self detailsForConnection:connection];
	
	_LOG_DEBUG( @"Finished URL:\n%@", [details->request URL] );
	
	if( [details->target respondsToSelector:details->selector] )
	{
		[self performSelectorOnMainThread:@selector(notifyTarget:) withObject:[NSValue valueWithPointer:details] waitUntilDone:NO];
	}
	else
	{
		// TODO:
		//LOG_DEBUG( @"target does not respond to selector" );
		[self removeConnectionDetails:details];
	}
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	AMURLRequestManagerConnectionDetails *details = [self detailsForConnection:connection];
	
	if( [details->target respondsToSelector:details->selector] )
	{
		details->error = [error retain];
		
		objc_msgSend( details->target, details->selector,
					 details->data, details->userInfo, details->error );
	}
	else
	{
		//LOG_WARNING( @"target does not respond to selector" );
	}
	
	[self removeConnectionDetails:details];
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
	NSInteger statusCode = HTTPResponse.statusCode;
	//LOG_DEBUG( @"response status: %d",  statusCode );
	if( HTTPResponse.statusCode != 200 )
	{
		AMURLRequestManagerConnectionDetails *details = [self detailsForConnection:connection];
		if( details->error == nil ) /* only set error if unset */
		{
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSHTTPURLResponse localizedStringForStatusCode:statusCode]
																 forKey:NSLocalizedDescriptionKey];
			details->error = [[NSError errorWithDomain:NSURLErrorDomain
												  code:statusCode
											  userInfo:userInfo] retain];
		}
	}
}


- (void)cancelRequestWithID:(AMURLRequestManagerTicket)ticket
{
	for( NSValue* value in [_activeRequests arrayByAddingObjectsFromArray:_pendingRequests] )
	{
		AMURLRequestManagerConnectionDetails* details = (AMURLRequestManagerConnectionDetails *)[value pointerValue];
		if( details->connectionID == ticket )
		{
			[details->connection cancel];
			[self removeConnectionDetails:details];
			break;
		}
	}
}


- (void)cancelAllRequestsWithTarget:(id)target
{
	for( NSValue *value in [_activeRequests arrayByAddingObjectsFromArray:_pendingRequests] )
	{
		AMURLRequestManagerConnectionDetails* details = (AMURLRequestManagerConnectionDetails *)[value pointerValue];
		if( details->target == target )
		{
			[details->connection cancel];
			[self removeConnectionDetails:details];
		}
	}
}


- (void)removeConnectionDetails:(AMURLRequestManagerConnectionDetails *)targetDetails
{
	/* save this value so we can do proper kvo */
	BOOL didHaveConnections = [self hasConnections];
	
	NSMutableArray* array = nil;
	if( targetDetails->connection != nil ) /* already started, must be in _active */
		array = _activeRequests;
	else
		array = _pendingRequests;
	
	AMURLRequestManagerConnectionDetails *detailsToRemove = NULL;
	NSUInteger index;
	
	pthread_mutex_lock( &_mutex );
	
	for( index=0; index<[array count]; index++ )
	{
		AMURLRequestManagerConnectionDetails *details = (AMURLRequestManagerConnectionDetails *)[(NSValue *)[array objectAtIndex:index] pointerValue];
		if( details->connectionID == targetDetails->connectionID )
		{
			detailsToRemove = targetDetails;
			break;
		}
	}
	
	if( detailsToRemove != NULL )
	{
		_LOG_DEBUG( @"removing details for URL: %@", [detailsToRemove->request URL] );
		[array removeObjectAtIndex:index];
		FreeConnectionDetails( detailsToRemove );
	}
	
	pthread_mutex_unlock( &_mutex );
	
	if( didHaveConnections != [self hasConnections] )
		[self didChangeValueForKey:@"hasConnections"];
	
	[self checkQueue];
}


- (void) pause
{
	self.paused = YES;
}


- (void) resume
{
	self.paused = NO;
	[self checkQueue];
}



@end
