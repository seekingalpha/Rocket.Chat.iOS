//
//  RCPageKey.h
//  Rocket.Chat
//
//  Created by Alexander Bugara on 9/18/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCPageKey : NSObject
+ (NSString *)generateUniqueString;
@end
