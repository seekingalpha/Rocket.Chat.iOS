//
//  SALAnalytics.m
//  SeekingAlpha
//
//  Created by Natan Rolnik on 4/16/14.
//  Copyright (c) 2014 Seeking Alpha. All rights reserved.
//

#import "SALAnalytics.h"
#import "RCAnalyticsBuilder.h"
#import "Analytics.h"
#import <UIKit/UIKit.h>

#define ARC4RANDOM_MAX 0x100000000

static const NSTimeInterval SALAnalyticsTimerFireTimeInterval = 10.0;

static NSString *const SALAnalyticsGlobalEventSource = @"global_event";

@interface SALAnalytics ()

@property (nonatomic, strong) NSTimer *fireAnalyticsTimer;
@property (nonatomic, strong) NSArray *allAnalytics;
@end

@implementation SALAnalytics

+ (instancetype)sharedManager
{
    static SALAnalytics *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    
    return _sharedManager;
}

- (instancetype)init
{
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startSession) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [self startSession];
    
    return self;
}

- (NSDictionary *)savedParameters
{
    NSDictionary *params = [self.parametersStack copy];
    
    self.parametersStack = @{};
    
    return params;
}

+ (void)trackPageView:(NSString *)pageView
{
    [self trackPageView:pageView source:nil];
}

+ (void)trackAnalysisPageView:(NSString *)pageView
{
    NSParameterAssert(pageView);
    
    [self trackPageView:pageView source:nil parameters:[[SALAnalytics sharedManager] savedParameters]];
}

+ (void)trackPageView:(NSString *)pageView source:(NSString *)source
{
    [self trackPageView:pageView source:source parameters:nil];
}

+ (void)trackPageView:(NSString *)pageView source:(NSString *)source parameters:(NSDictionary *)parameters
{
    NSParameterAssert(pageView);
    
    [Analytics createPageView:pageView source:source parameters:parameters];
}

+ (void)trackEvent:(NSString *)event
{
    [self trackEvent:event source:nil];
}

+ (void)trackEvent:(NSString *)event source:(NSString *)source
{
    [self trackEvent:event source:source parameters:nil];
}

+ (void)trackEvent:(NSString *)event source:(NSString *)source parameters:(NSDictionary *)parameters
{
    NSParameterAssert(event);
    
    NSString *sourceToSend = source ? : SALAnalyticsGlobalEventSource;
    [Analytics createEvent:event source:sourceToSend parameters:parameters];
}

- (void)enableTimer
{
    if (![self.fireAnalyticsTimer isValid]) {
        self.fireAnalyticsTimer = [NSTimer scheduledTimerWithTimeInterval:SALAnalyticsTimerFireTimeInterval target:self selector:@selector(sendAnalyticsToServer) userInfo:nil repeats:YES];
    }
}

- (void)disableTimer
{
    if ([self.fireAnalyticsTimer isValid]) {
        [self.fireAnalyticsTimer invalidate];
        self.fireAnalyticsTimer = nil;
    }
}

- (void)sendAnalyticsToServer
{
    return;
    
    if (![self isNetworkAvailable]) {
        return;
    }
    
    [self disableTimer];
    
    [Analytics allAnalyticsWithCompletion:^(NSArray *allAnalyticsReceived) {

#ifdef DEBUG

        NSUInteger analyticsCount = [allAnalyticsReceived count];
        if (analyticsCount == 0) {
            NSLog(@"No analytics to send");
        }
        else {
            NSLog(@"Will send %lu analytics", (unsigned long)analyticsCount);
        }
        
#endif
        
        self.allAnalytics = allAnalyticsReceived;

        for (Analytics *analytics in self.allAnalytics) {
            [analytics send];
        }
    }];
}

- (void)applicationDidEnterBackgroundNotification:(NSNotification *)notification
{
    [self sendAnalyticsToServer];
}

- (void)startSession
{
    self.sessionKey = [SALAnalytics generateUniqueString];
    
    if (!self.lastTrackKey) {
        self.lastTrackKey = [SALAnalytics generateUniqueString];
    }
    
    if (!self.lastReferrer) {
        self.lastReferrer = @"";
    }

    if (!self.deviceMachineCookie) {
        NSString * identifierForVendor = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        identifierForVendor = [identifierForVendor stringByReplacingOccurrencesOfString:@"-" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, identifierForVendor.length)];
        
        self.deviceMachineCookie = identifierForVendor;
    }

    if (!self.moneType) {
        NSString *deviceName = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? @"iphone" : @"ipad";
        
#ifdef DEBUG
        deviceName = [deviceName stringByAppendingString:@"_dev"];
#elif ADHOC
        deviceName = [deviceName stringByAppendingString:@"_beta"];
#endif
        
        self.moneType = deviceName;
    }
}

+ (NSString *)generateUniqueString
{
    return [self base36FromTimeStamp:(floor([[NSDate date] timeIntervalSince1970])*1000 +  floorf(((double)arc4random() / ARC4RANDOM_MAX) * 1000.0f))];
}

+ (NSString *)base36FromTimeStamp:(double)value
{
	NSString *base36 = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	
	NSString *returnValue = @"";
	NSString *g = @"0";
	
	int i = 0;
	do {
		int x ;
		if (i == 0)
		{
			x = fmod(value, [base36 length] );
		}
		else {
			x = fmod([g doubleValue], [base36 length]);
		}
		
		NSString *y = [[NSString alloc] initWithFormat:@"%c", [base36 characterAtIndex:x]];
        returnValue = [y stringByAppendingString:returnValue];
        
        value = value / 36;
        i++;
        g = [[NSString alloc] initWithFormat:@"%0.0f", value - 0.5];
    } while ([g intValue] != 0);
    
    return returnValue;
}
- (BOOL)isNetworkAvailable
{
    CFNetDiagnosticRef dReference;
    dReference = CFNetDiagnosticCreateWithURL (NULL, (__bridge CFURLRef)[NSURL URLWithString:@"www.apple.com"]);
    
    CFNetDiagnosticStatus status;
    status = CFNetDiagnosticCopyNetworkStatusPassively (dReference, NULL);
    
    CFRelease (dReference);
    
    if ( status == kCFNetDiagnosticConnectionUp )
    {
        NSLog (@"Connection is Available");
        return YES;
    }
    else
    {
        NSLog (@"Connection is down");
        return NO;
    }
}
@end
