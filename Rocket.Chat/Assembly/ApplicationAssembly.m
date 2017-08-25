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

- (AuthViewController *)connectServerViewController {
    return [TyphoonDefinition
            withClass:[AuthViewController class]
            configuration:^(TyphoonDefinition *definition) {
                [definition injectProperty:@selector(serverURL) with:TyphoonConfig(@"serverURL")];
                //[definition injectProperty:@selector(login) with:TyphoonConfig(@"login")];
                //[definition injectProperty:@selector(password) with:TyphoonConfig(@"password")];
                [definition injectProperty:@selector(interactor) with:[AuthInteractor new]];
                [definition injectProperty:@selector(stateMachine) with:[AuthStateMachine new]];
            }];
}

- (id)config {
    return [TyphoonDefinition withConfigName:@"Configuration.plist"];
}

@end
