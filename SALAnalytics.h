//
//  SALAnalytics.h
//  SeekingAlpha
//
//  Created by Natan Rolnik on 4/16/14.
//  Copyright (c) 2014 Seeking Alpha. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString  *const _Nonnull SALAnalyticsAskedForPushNotifications = @"SALAnalyticsAskedForPushNotifications";
static NSString *const _Nonnull SALAnalyticsReceivedPushNotificationsToken = @"SALAnalyticsReceivedPushNotificationsToken";

@class Analysis;

@protocol SALAnalyticsProtocol <NSObject>

@optional

- (NSString * _Nonnull)pageViewName;

- (NSString * _Nonnull)eventSource;

- (void)sendPageView;

@end

@interface SALAnalytics : NSObject

+ (instancetype _Nullable)sharedManager;

+ (NSString * _Nonnull)generateUniqueString;

+ (void)trackPageView:(NSString * _Nonnull)pageView;

+ (void)trackAnalysisPageView:(NSString * _Nonnull)pageView;

+ (void)trackPageView:(NSString * _Nonnull)pageView source:(NSString * _Nullable)source;

+ (void)trackPageView:(NSString * _Nonnull)pageView source:(NSString * _Nullable)source parameters:(NSDictionary * _Nullable)parameters;

+ (void)trackEvent:(NSString * _Nullable)event;

+ (void)trackEvent:(NSString * _Nullable)event source:(NSString * _Nullable)eventSource;

+ (void)trackEvent:(NSString * _Nullable)event source:(NSString * _Nullable)eventSource parameters:(NSDictionary * _Nullable)parameters;

- (NSDictionary * _Nonnull)savedParameters;

@property (nonatomic, strong) NSString * _Nonnull moneType;

@property (nonatomic, strong) NSString * _Nonnull deviceMachineCookie;

@property (nonatomic, strong) NSString * _Nonnull sessionKey;

@property (nonatomic, strong) NSString * _Nonnull lastTrackKey;

@property (nonatomic, strong) NSString * _Nonnull lastReferrer;

@property (nonnull, copy) NSDictionary *parametersStack;

@end
