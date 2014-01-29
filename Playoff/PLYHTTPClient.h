//
//  PLYHTTPClient.h
//  Playoff
//
//  Created by Arie Lakeman on 27/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "AFHTTPClient.h"

#import "AFURLConnectionOperation.h"

@interface PLYHTTPClient : AFHTTPClient

- (void)setReachabilityStatusChangeBlock:(void (^)(AFNetworkReachabilityStatus status))block;

@end
