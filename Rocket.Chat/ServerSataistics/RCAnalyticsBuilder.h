//
//  RCAnalyticsBuilder.h
//  Rocket.Chat
//
//  Created by Alexander Bugara on 9/25/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Analytics.h"

@interface RCAnalyticsBuilder : NSObject
+ (NSData *)analyticsDataFromPageView:(Analytics *)analytics;

+ (NSDictionary *)analyticsDictionaryFromEvent:(Analytics *)analytics;

+ (NSData *)_analyticsDataFromPageView:(NSDictionary *)parameters;

+ (NSDictionary *)_analyticsDictionaryFromEvent:(NSDictionary *)parameters;
@end
