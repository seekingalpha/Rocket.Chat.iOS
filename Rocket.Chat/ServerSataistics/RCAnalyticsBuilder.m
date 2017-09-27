//
//  RCAnalyticsBuilder.m
//  Rocket.Chat
//
//  Created by Alexander Bugara on 9/25/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

#import "RCAnalyticsBuilder.h"
#import "Analytics.h"
#import "SALAnalytics.h"
#import <UIKit/UIKit.h>

static NSString *const SALAnalyticsMoneVersion = @"2";
static NSString *const SALAnalyticsBuilderDeviceTokenKey = @"deviceToken";
static NSString *const SALAnalyticsBuilderMoreKey = @"more";
static NSString *const SALAnalyticsBuilderOfflineKey = @"offline";
static NSString *const SALAnalyticsBuilderProUserKey = @"sapu";
static NSString *const SALAnalyticsBuilderIDFAKey = @"IDFA";
static NSString *const SALAnalyticsBuilderPortfoliosCountKey = @"portfolios";
static NSString *const SALAnalyticsBuilderTimeStampKey = @"ts";

@implementation RCAnalyticsBuilder

+ (NSData *)analyticsDataFromPageView:(Analytics *)analytics
{
    NSParameterAssert(analytics);
    
    NSAssert(analytics.typeValue == SALAnalyticsTypePageView, @"analyticsDataFromPageView can generate NSData only for Analytics object with type SALAnalyticsTypePageView");
    
    NSAssert(analytics.parameters, @"Analytics object must have parameters");
    
    NSDictionary *parameters = [NSJSONSerialization JSONObjectWithData:[analytics.parameters dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    
    NSAssert(parameters[SALAnalyticsURLCompleteKey], @"Page view must have a SALAnalyticsURLCompleteKey key");
    
    NSMutableArray *rawData = [NSMutableArray arrayWithCapacity:26];
    NSString *url = parameters[SALAnalyticsURLCompleteKey];
    NSString *deviceToken = parameters[SALAnalyticsDeviceTokenKey];
    NSString *email = parameters[SALAnalyticsUserEmailKey] ? : @"";
    NSString *userId = parameters[SALAnalyticsUserIdKey] ? : @"";
    
    [rawData addObject:SALAnalyticsMoneVersion]; //Version
    [rawData addObject:[[SALAnalytics sharedManager] moneType]]; //Mone Type
    
    [rawData addObject:parameters[SALAnalyticsUniqueStringKey]]; //page_key
    [rawData addObject:parameters[SALAnalyticsLastTrackKey]]; //referrer_key
    [rawData addObject:parameters[SALAnalyticsLastReferrerKey]]; //referrer
    
    [rawData addObject:url]; //url
    [rawData addObject:parameters[@"url_params"] ? : @""]; //url_params - add emtpy string if doesn't exist
    [rawData addObject:[[SALAnalytics sharedManager] deviceMachineCookie]]; //machine_cookie
    [rawData addObject:[[SALAnalytics sharedManager] sessionKey]]; //session_cookie
    [rawData addObject:userId ? : @""]; //user_id
    [rawData addObject:@""]; //user_nick
    [rawData addObject:email]; //user_email
    [rawData addObject:@""]; //user_vocation
    [rawData addObject:@""]; //author_slug
    [rawData addObject:@""]; //user_mywebsite_url
    [rawData addObject:@""]; //gigya_notified_login
    [rawData addObject:@""]; //user_gigya_settings
    [rawData addObject:[NSString stringWithFormat:@"{%@}", parameters[SALAnalyticsPortfoliosSlugsKey]]]; //user_watchlist_slugs
    [rawData addObject:@"{}"]; //user_non_watchlist_slugs
    [rawData addObject:@"{}"]; //user_watchlist_authors
    [rawData addObject:@"{}"]; //user_following_users
    [rawData addObject:[NSString stringWithFormat:@"{%@}", parameters[SALAnalyticsSlugsKey] ? : @""]]; //object_symbols
    [rawData addObject:parameters[SALAnalyticsSectorsKey] ? : @"{}"]; //sector
    [rawData addObject:parameters[SALAnalyticsThemesKey] ? : @"{}"]; //object_themes
    [rawData addObject:parameters[SALAnalyticsAuthorsKey] ? : @"{}"]; //object_authors
    
    //other array
    NSMutableArray *otherArray = [NSMutableArray arrayWithCapacity:9];
    
    [otherArray addObject:[NSString stringWithFormat:@"%@=%@", SALAnalyticsBuilderTimeStampKey, parameters[SALAnalyticsTimestampKey]]];
    
    
    
    [otherArray addObject:[NSString stringWithFormat:@"%@=%@", SALAnalyticsBuilderOfflineKey, analytics.offline]];
    [otherArray addObject:[NSString stringWithFormat:@"%@=%@", SALAnalyticsBuilderPortfoliosCountKey, parameters[SALAnalyticsPortfoliosCountsKey]]];
    [otherArray addObject:[NSString stringWithFormat:@"%@=%@", SALAnalyticsBuilderProUserKey, parameters[SALAnalyticsProUserCodeKey]]];
    [otherArray addObject:[NSString stringWithFormat:@"%@=%@",@"orientation", UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])? @"landscape" : @"portrait"]];
    
    if(deviceToken) {
        [otherArray addObject:[NSString stringWithFormat:@"%@=%@", SALAnalyticsBuilderDeviceTokenKey,  deviceToken]];
    }
    
    [rawData addObject:[otherArray componentsJoinedByString:@"; "]];
    
    NSString *joinedString = [rawData componentsJoinedByString:@";;;"];
    NSString *rawString = [NSString stringWithFormat:@"mone=%@", joinedString];
    
    return [rawString dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSData *)_analyticsDataFromPageView:(NSDictionary *)parameters
{
    NSParameterAssert(parameters);
    
    NSAssert(parameters[SALAnalyticsURLCompleteKey], @"Page view must have a SALAnalyticsURLCompleteKey key");
    
    NSMutableArray *rawData = [NSMutableArray arrayWithCapacity:26];
    NSString *url = parameters[SALAnalyticsURLCompleteKey];
    NSString *deviceToken = parameters[SALAnalyticsDeviceTokenKey];
    NSString *email = parameters[SALAnalyticsUserEmailKey] ? : @"";
    NSString *userId = parameters[SALAnalyticsUserIdKey] ? : @"";
    
    [rawData addObject:SALAnalyticsMoneVersion]; //Version
    [rawData addObject:[[SALAnalytics sharedManager] moneType]]; //Mone Type
    
    [rawData addObject:parameters[SALAnalyticsUniqueStringKey]]; //page_key
    [rawData addObject:parameters[SALAnalyticsLastTrackKey]]; //referrer_key
    [rawData addObject:parameters[SALAnalyticsLastReferrerKey]]; //referrer
    
    [rawData addObject:url]; //url
    [rawData addObject:parameters[@"url_params"] ? : @""]; //url_params - add emtpy string if doesn't exist
    [rawData addObject:[[SALAnalytics sharedManager] deviceMachineCookie]]; //machine_cookie
    [rawData addObject:[[SALAnalytics sharedManager] sessionKey]]; //session_cookie
    [rawData addObject:userId ? : @""]; //user_id
    [rawData addObject:@""]; //user_nick
    [rawData addObject:email]; //user_email
    [rawData addObject:@""]; //user_vocation
    [rawData addObject:@""]; //author_slug
    [rawData addObject:@""]; //user_mywebsite_url
    [rawData addObject:@""]; //gigya_notified_login
    [rawData addObject:@""]; //user_gigya_settings
    [rawData addObject:[NSString stringWithFormat:@"{%@}", parameters[SALAnalyticsPortfoliosSlugsKey]]]; //user_watchlist_slugs
    [rawData addObject:@"{}"]; //user_non_watchlist_slugs
    [rawData addObject:@"{}"]; //user_watchlist_authors
    [rawData addObject:@"{}"]; //user_following_users
    [rawData addObject:[NSString stringWithFormat:@"{%@}", parameters[SALAnalyticsSlugsKey] ? : @""]]; //object_symbols
    [rawData addObject:parameters[SALAnalyticsSectorsKey] ? : @"{}"]; //sector
    [rawData addObject:parameters[SALAnalyticsThemesKey] ? : @"{}"]; //object_themes
    [rawData addObject:parameters[SALAnalyticsAuthorsKey] ? : @"{}"]; //object_authors
    
    //other array
    NSMutableArray *otherArray = [NSMutableArray arrayWithCapacity:9];
    
    [otherArray addObject:[NSString stringWithFormat:@"%@=%@", SALAnalyticsBuilderTimeStampKey, parameters[SALAnalyticsTimestampKey]]];
    
    [otherArray addObject:[NSString stringWithFormat:@"%@=%@", SALAnalyticsBuilderPortfoliosCountKey, parameters[SALAnalyticsPortfoliosCountsKey]]];
    [otherArray addObject:[NSString stringWithFormat:@"%@=%@", SALAnalyticsBuilderProUserKey, parameters[SALAnalyticsProUserCodeKey]]];
    [otherArray addObject:[NSString stringWithFormat:@"%@=%@",@"orientation", UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])? @"landscape" : @"portrait"]];
    
    if(deviceToken) {
        [otherArray addObject:[NSString stringWithFormat:@"%@=%@", SALAnalyticsBuilderDeviceTokenKey,  deviceToken]];
    }
    
    [rawData addObject:[otherArray componentsJoinedByString:@"; "]];
    
    NSString *joinedString = [rawData componentsJoinedByString:@";;;"];
    NSString *rawString = [NSString stringWithFormat:@"mone=%@", joinedString];
    
    return [rawString dataUsingEncoding:NSUTF8StringEncoding];
}

+ (NSDictionary *)analyticsDictionaryFromEvent:(Analytics *)analytics;
{
    NSParameterAssert(analytics);
    
    NSAssert(analytics.typeValue == SALAnalyticsTypeEvent, @"analyticsDataFromEvent can generate NSData only for Analytics object with type SALAnalyticsTypeEvent");
    
    NSAssert(analytics.parameters, @"Analytics object must have parameters");
    
    NSDictionary *parameters = parameters = [NSJSONSerialization JSONObjectWithData:[analytics.parameters dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    
    NSMutableDictionary *additionalDataDictionary = [NSMutableDictionary dictionary];
    
    if (analytics.offlineValue || parameters[SALAnalyticsAdditionalParametersKey]) {
        if (analytics.offlineValue) {
            additionalDataDictionary[@"offline"] = @(YES);
        }
        
        if (parameters[SALAnalyticsAdditionalParametersKey]) {
            [additionalDataDictionary addEntriesFromDictionary:parameters[SALAnalyticsAdditionalParametersKey]];
        }
    }
    
    NSString *dataFieldString = [additionalDataDictionary count] == 0 ? @"{}" : [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:additionalDataDictionary options:kNilOptions error:nil] encoding:NSUTF8StringEncoding];
    
    NSDictionary *dictionaryToReturn = @{@"version": SALAnalyticsMoneVersion,
                                         @"key": parameters[SALAnalyticsLastTrackKey],
                                         @"type": [[SALAnalytics sharedManager] moneType],
                                         @"source": parameters[SALAnalyticsSourceKey],
                                         @"action": parameters[SALAnalyticsEventKey],
                                         @"data": dataFieldString,
                                         };
    
    return dictionaryToReturn;
}

+ (NSDictionary *)_analyticsDictionaryFromEvent:(NSDictionary *)parameters
{
    NSParameterAssert(parameters);
    
    NSMutableDictionary *additionalDataDictionary = [NSMutableDictionary dictionary];
    
    
    if (parameters[SALAnalyticsAdditionalParametersKey]) {
        [additionalDataDictionary addEntriesFromDictionary:parameters[SALAnalyticsAdditionalParametersKey]];
    }
    
    NSString *dataFieldString = [additionalDataDictionary count] == 0 ? @"{}" : [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:additionalDataDictionary options:kNilOptions error:nil] encoding:NSUTF8StringEncoding];
    
    NSDictionary *dictionaryToReturn = @{@"version": SALAnalyticsMoneVersion,
                                         @"key": parameters[SALAnalyticsLastTrackKey],
                                         @"type": [[SALAnalytics sharedManager] moneType],
                                         @"source": parameters[SALAnalyticsSourceKey],
                                         @"action": parameters[SALAnalyticsEventKey],
                                         @"data": dataFieldString,
                                         };
    
    return dictionaryToReturn;
}

@end
