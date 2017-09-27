//
//  Analytics.m
//  Rocket.Chat
//
//  Created by Alexander Bugara on 9/25/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

#import "Analytics.h"
#import <UIKit/UIKit.h>
#import "Rocket_Chat-Swift.h"
#import "SALAnalytics.h"
#import "RCAnalyticsBuilder.h"
#import "RCEventSender.h"

@implementation Analytics
+ (void)createPageView:(NSString *)pageView source:(NSString *)source parameters:(NSDictionary *)parameters
{
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:parameters];
    if (pageView) {
        [mutableDictionary setObject:pageView forKey:SALAnalyticsPageViewKey];
    }
    
    if (source) {
        [mutableDictionary setObject:source forKey:SALAnalyticsSourceKey];
    }
    
    //if ([SALUserDataManager sharedManager].userID) {
    //if ([SALUserDataManager sharedManager].email) {
       // mutableDictionary[SALAnalyticsUserEmailKey] = [SALUserDataManager sharedManager].email;
    //}
    if ([AuthManager currentUser].identifier) {
        mutableDictionary[SALAnalyticsUserIdKey] = [AuthManager currentUser].identifier;
    }
    //if ([SALDeviceDataManager sharedManager].deviceID) {
    //  mutableDictionary[SALAnalyticsDeviceTokenKey] = [SALDeviceDataManager sharedManager].deviceID;
    //}
    //}
    
    mutableDictionary[SALAnalyticsTimestampKey] = [NSNumber numberWithInt:(int)[[NSDate date] timeIntervalSince1970]];
    
    
    NSString *url = [[NSString stringWithFormat:@"/%@", mutableDictionary[SALAnalyticsPageViewKey]] lowercaseString];
    
    if ([mutableDictionary[SALAnalyticsActionKey] length] > 0) {
        url = [[url stringByAppendingFormat:@"/%@", mutableDictionary[SALAnalyticsActionKey]] lowercaseString];
    }
    
    mutableDictionary[SALAnalyticsURLCompleteKey] = url;
    
    NSString *uniqueString = [SALAnalytics generateUniqueString];
    mutableDictionary[SALAnalyticsUniqueStringKey] = uniqueString;
    
    mutableDictionary[SALAnalyticsLastTrackKey] = [[SALAnalytics sharedManager] lastTrackKey];
    mutableDictionary[SALAnalyticsLastReferrerKey] = [[SALAnalytics sharedManager] lastReferrer];
    
    
    [[SALAnalytics sharedManager] setLastTrackKey:uniqueString];
    [[SALAnalytics sharedManager] setLastReferrer:url];
    
    NSData *data = [RCAnalyticsBuilder _analyticsDataFromPageView:mutableDictionary];
    
    [self _sendPageViewTrackingData:data];
}

+ (void)createEvent:(NSString *)event source:(NSString *)source parameters:(NSDictionary *)parameters
{
    NSParameterAssert(source);
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionary];
    
    [mutableDictionary setObject:[[event stringByReplacingOccurrencesOfString:@" " withString:@"_"] lowercaseString] forKey:SALAnalyticsEventKey];
    
    [mutableDictionary setObject:[source lowercaseString] forKey:SALAnalyticsSourceKey];
    
    mutableDictionary[SALAnalyticsLastTrackKey] = [[SALAnalytics sharedManager] lastTrackKey];
    
    if (parameters) {
        mutableDictionary[SALAnalyticsAdditionalParametersKey] = parameters;
    }
    
    NSDictionary *paramsToSend = [RCAnalyticsBuilder _analyticsDictionaryFromEvent:mutableDictionary];
    
    [self _sendMoneEventToServer:paramsToSend];
}


- (void)send:(RCEventSender *)sender
{
    UIApplication *application = [UIApplication sharedApplication];
    
    __block UIBackgroundTaskIdentifier backgroundTask;
    backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:[NSString stringWithFormat:@"%@", [[NSUUID UUID] UUIDString]] expirationHandler:^{
        [application endBackgroundTask:backgroundTask];
        backgroundTask = UIBackgroundTaskInvalid;
    }];
    
    if (self.typeValue == SALAnalyticsTypePageView) {
        NSData *data = [RCAnalyticsBuilder analyticsDataFromPageView:self];
        
        dispatch_async(dispatch_get_main_queue(), ^{
//            [[SALAPIClient sharedClient] pageViewTrackingData:data success:^(NSURLSessionDataTask *task, id responseObject) {
//                [self didSendToServerWithBackroundTaskIdentifier:backgroundTask];
//            } failure:nil];
            [sender sendData:data];
        });
    } else if (self.typeValue == SALAnalyticsTypeEvent) {
        NSDictionary *parameters = [RCAnalyticsBuilder analyticsDictionaryFromEvent:self];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [sender sendParams:parameters];
//            [[SALAPIClient sharedClient].httpSessionManager POST:@"/mone_event" parameters:parameters progress:nil success:^(NSURLSessionDataTask *task, id responseObject) {
//                [self didSendToServerWithBackroundTaskIdentifier:backgroundTask];
//            } failure:nil];
        });
    }
}

- (void)didSendToServerWithBackroundTaskIdentifier:(UIBackgroundTaskIdentifier)backgroundTask
{
    //NSManagedObjectContext *context = [SALCoreDataStore privateQueueContext];
    
    __block UIBackgroundTaskIdentifier backgroundTaskBlock = backgroundTask;
    
//    [context performBlock:^{
//        Analytics *thisAnalytics = (Analytics *) [context objectWithID:[self objectID]];
//        [context deleteObject:thisAnalytics];
//        [context save:nil];
//        
//        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskBlock];
//        backgroundTaskBlock = UIBackgroundTaskInvalid;
//    }];
}

+ (void)_sendPageViewTrackingData:(NSData *)trackingData
{
  // [[SALAPIClient sharedClient] pageViewTrackingData:trackingData success:nil failure:nil];
}

+ (void)_sendMoneEventToServer:(NSDictionary *)parameters
{
  //  [[SALAPIClient sharedClient].httpSessionManager POST:@"/mone_event" parameters:parameters progress:nil success:nil failure:nil];
}

@end
