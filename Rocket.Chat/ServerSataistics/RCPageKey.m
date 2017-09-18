//
//  RCPageKey.m
//  Rocket.Chat
//
//  Created by Alexander Bugara on 9/18/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

#import "RCPageKey.h"

#define ARC4RANDOM_MAX 0x100000000

@implementation RCPageKey
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

@end
