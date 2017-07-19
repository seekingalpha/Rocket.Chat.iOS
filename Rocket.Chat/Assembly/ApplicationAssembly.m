//
//  ApplicationAssembly.m
//  Rocket.Chat
//
//  Created by Alexander Bugara on 7/19/17.
//  Copyright © 2017 Rocket.Chat. All rights reserved.
//

#import "ApplicationAssembly.h"
#import "Rocket_Chat-Swift.h"

@implementation ApplicationAssembly

- (ConnectServerViewController *)connectServerViewController {
    return [TyphoonDefinition
            withClass:[ConnectServerViewController class]
            configuration:^(TyphoonDefinition *definition) {
                //[definition injectProperty:@selector(<#selector#>) with:TyphoonConfig(@"serverURL")]
            }];
}

- (id)config {
    return [TyphoonDefinition withConfigName:@"Configuration.plist"];
}

@end
