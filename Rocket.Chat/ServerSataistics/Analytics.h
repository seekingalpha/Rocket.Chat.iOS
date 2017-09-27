//
//  Analytics.h
//  Rocket.Chat
//
//  Created by Alexander Bugara on 9/25/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger, SALAnalyticsType) {
    SALAnalyticsTypePageView,
    SALAnalyticsTypeEvent
};

static NSString *const SALAnalyticsPageViewKey = @"page";
static NSString *const SALAnalyticsEventKey = @"event";
static NSString *const SALAnalyticsSourceKey = @"source";
static NSString *const SALAnalyticsURLCompleteKey = @"url_complete";
static NSString *const SALAnalyticsActionKey = @"action";
static NSString *const SALAnalyticsProUserCodeKey = @"proCode";
static NSString *const SALAnalyticsPortfoliosSlugsKey = @"portfoliosSlugs";
static NSString *const SALAnalyticsPortfoliosCountsKey = @"portfoliosCount";

static NSString *const SALAnalyticsSectorsKey = @"sectors";
static NSString *const SALAnalyticsThemesKey = @"themes";
static NSString *const SALAnalyticsAuthorsKey = @"authors";
static NSString *const SALAnalyticsSlugsKey = @"authors";

static NSString *const SALAnalyticsUniqueStringKey = @"uniqueString";
static NSString *const SALAnalyticsLastTrackKey = @"lastTrack";
static NSString *const SALAnalyticsLastReferrerKey = @"lastReferrer";

static NSString *const SALAnalyticsDeviceTokenKey = @"deviceToken";
static NSString *const SALAnalyticsUserEmailKey = @"userEmail";
static NSString *const SALAnalyticsUserIdKey = @"userId";
static NSString *const SALAnalyticsTimestampKey = @"timestamp";

static NSString *const SALAnalyticsAdditionalParametersKey = @"SALAnalyticsAdditionalParametersKey";

@interface Analytics : NSObject
+ (void)createPageView:(NSString *)pageView source:(NSString *)source parameters:(NSDictionary *)parameters;

+ (void)createEvent:(NSString *)event source:(NSString *)source parameters:(NSDictionary *)parameters;

+ (void)allAnalyticsWithCompletion:(void (^)(NSArray *allAnalytics))completionBlock;

- (void)send;

@property (nonatomic, strong, nullable) NSNumber* offline;
@property (atomic) BOOL offlineValue;
@property (nonatomic, strong, nullable) NSString* parameters;
@property (nonatomic, strong, nullable) NSNumber* type;
@property (atomic) int64_t typeValue;
@end
