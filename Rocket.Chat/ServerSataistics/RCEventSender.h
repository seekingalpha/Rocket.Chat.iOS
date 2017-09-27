//
//  RCEventSender.h
//  Rocket.Chat
//
//  Created by Alexander Bugara on 9/25/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

@interface RCEventSender : NSObject
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;
- (void)sendParams:(NSDictionary *)params;
- (void)sendData:(NSData *)data;
@end
