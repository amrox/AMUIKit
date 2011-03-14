//
//  WVWebServiceCall2.h
//  ConcertVault
//
//  Created by Andy Mroczkowski on 12/18/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol AMWebServiceCall <NSObject>

- (NSURLRequest*) URLRequest;

- (id) resultFromResponseData:(NSData*)responseData error:(NSError**)outError;

@end
