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
                [definition injectProperty:@selector(login) with:TyphoonConfig(@"login")];
                [definition injectProperty:@selector(password) with:TyphoonConfig(@"password")];
                [definition injectProperty:@selector(interactor) with:[AuthInteractor new]];
                [definition injectProperty:@selector(stateMachine) with:[self stateMachine]];
            }];
}

- (id)config {
    return [TyphoonDefinition withConfigName:@"Configuration.plist"];
}

- (AuthStateMachine *)stateMachine {
    return [TyphoonDefinition
            withClass:[AuthStateMachine class]
            configuration:^(TyphoonDefinition *definition) {
                
                FirstLoadingState *firstLoadingState = [self firstLoadingState];
                [definition injectProperty:@selector(rootState) with:firstLoadingState];
                [definition injectProperty:@selector(currentState) with:firstLoadingState];
            }];
}

- (FirstLoadingState *)firstLoadingState {
    return [TyphoonDefinition
            withClass:[FirstLoadingState class]
            configuration:^(TyphoonDefinition *definition) {
                [definition useInitializer:@selector(initWithAuthViewController:)
                                parameters:^(TyphoonMethod *initializer) {
                                    [initializer injectParameterWith:[self connectServerViewController]];
                                }];
                [definition injectProperty:@selector(nextSuccess) with:[self showChatState]];
                [definition injectProperty:@selector(nextFailure) with:[self showLoginState]];
            }];
}

- (ShowLoginState *)showLoginState {
    return [TyphoonDefinition
            withClass:[ShowLoginState class]
            configuration:^(TyphoonDefinition *definition) {
                [definition useInitializer:@selector(initWithAuthViewController:)
                                parameters:^(TyphoonMethod *initializer) {
                                    [initializer injectParameterWith:[self connectServerViewController]];
                                    [definition injectProperty:@selector(nextSuccess) with:[self loginInProgressState]];
                                    [definition injectProperty:@selector(logEventManager) with:[self logEventManager]];
                                    [definition injectProperty:@selector(logEvent) with:[self showLoginPageEvent]];
                                }];
            }];
}

- (ShowChatState *)showChatState {
    return [TyphoonDefinition
            withClass:[ShowChatState class]
            configuration:^(TyphoonDefinition *definition) {
                [definition useInitializer:@selector(initWithAuthViewController:)
                                parameters:^(TyphoonMethod *initializer) {
                                    [initializer injectParameterWith:[self connectServerViewController]];
                                }];
            }];
}

- (LoginInProgressState *)loginInProgressState {
    return [TyphoonDefinition
            withClass:[LoginInProgressState class]
            configuration:^(TyphoonDefinition *definition) {
                [definition useInitializer:@selector(initWithAuthViewController:)
                                parameters:^(TyphoonMethod *initializer) {
                                    [initializer injectParameterWith:[self connectServerViewController]];
                                }];
                [definition injectProperty:@selector(nextSuccess) with:[self loginSuccessState]];
                [definition injectProperty:@selector(nextFailure) with:[self loginFailureState]];
            }];
}

- (LoginSuccessState *)loginSuccessState {
    return [TyphoonDefinition
            withClass:[LoginSuccessState class]
            configuration:^(TyphoonDefinition *definition) {
                [definition useInitializer:@selector(initWithAuthViewController:)
                                parameters:^(TyphoonMethod *initializer) {
                                    [initializer injectParameterWith:[self connectServerViewController]];
                                }];
                [definition injectProperty:@selector(logEventManager) with:[self logEventManager]];
            }];
}

- (LogEventManager *)logEventManager {
    return [TyphoonDefinition
            withClass:[LogEventManager class]
            configuration:^(TyphoonDefinition *definition) {
                [definition setScope:TyphoonScopeSingleton];
            }];
}

- (LogEvent *)showLoginPageEvent {
    return [TyphoonDefinition
            withClass:[LogEvent class]
            configuration:^(TyphoonDefinition *definition) {
                [definition injectProperty:@selector(url) with:@"/roadblock"];
            }];
}

- (ChatViewController *)chatViewController {
    return [TyphoonDefinition
            withClass:[ChatViewController class]
            configuration:^(TyphoonDefinition *definition) {
                [definition injectProperty:@selector(logEventManager) with:[self logEventManager]];
            }];
}

- (LoginFailureState *)loginFailureState {
    return [TyphoonDefinition
            withClass:[LoginFailureState class]
            configuration:^(TyphoonDefinition *definition) {
                [definition useInitializer:@selector(initWithAuthViewController:)
                                parameters:^(TyphoonMethod *initializer) {
                                    [initializer injectParameterWith:[self connectServerViewController]];
                                }];

                [definition injectProperty:@selector(nextSuccess) with:[self showLoginState]];
                [definition injectProperty:@selector(nextFailure) with:[self showLoginState]];
            }];
}
@end
