

#include <pthread.h>


typedef NSUInteger AMURLRequestManagerTicket;

#define kAMURLRequestManagerTicketInvalid -1

#define kAMURLRequestManagerDefaultTimeout 60


@interface AMURLRequestManager : NSObject
{
	NSUInteger _ticketCounter;
	
	NSMutableArray* _pendingRequests;
	NSMutableArray* _activeRequests;
	
	pthread_mutex_t _mutex;
	pthread_cond_t _cond;
	NSThread* _internalThread;
	NSRunLoop* _myRunLoop;
}

- (id) initUsingBackgroundThread:(BOOL)useThread;

@property (nonatomic, assign) NSInteger maxConcurrentConnectionCount;

@property (readonly) BOOL hasConnections;

// selector should be of the form:
// - (void) thingDidFinish:(NSData*)data userInfo:(id)userInfo error:(NSError*)error

- (AMURLRequestManagerTicket) queueRequest:(NSURLRequest*)request informingTarget:(id<NSObject>)target selector:(SEL)selector userInfo:(id<NSObject>)contextInfo;
- (AMURLRequestManagerTicket) queueGETRequestForURL:(NSURL *)URL informingTarget:(id<NSObject>)target selector:(SEL)selector userInfo:(id<NSObject>)contextInfo;

@property (readonly) BOOL paused;
- (void) pause;
- (void) resume;

- (void)cancelRequestWithID:(AMURLRequestManagerTicket)connectionID;
- (void)cancelAllRequestsWithTarget:(id)target;


@end
