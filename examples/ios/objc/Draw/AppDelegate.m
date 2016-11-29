////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "AppDelegate.h"
#import <Realm/Realm.h>
#import "DrawView.h"
#import "Constants.h"
#import "RLMLoginViewController.h"

@interface AppDelegate ()

@property (nonatomic, strong) RLMLoginViewController *controller;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    application.applicationSupportsShakeToEdit = YES;
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    
    // Setup Global Error Handler
    [RLMSyncManager sharedManager].errorHandler = ^(NSError *error, RLMSyncSession *session) {
        NSLog(@"A global error has occurred! %@", error);
    };
    
//    if ([RLMSyncUser currentUser]) {
//        NSURL *syncURL = [NSURL URLWithString:[NSString stringWithFormat:@"realm://%@:9080/~/Draw", kIPAddress]];
//        RLMSyncConfiguration *syncConfig = [[RLMSyncConfiguration alloc] initWithUser:[RLMSyncUser currentUser] realmURL:syncURL];
//        RLMRealmConfiguration *defaultConfig = [RLMRealmConfiguration defaultConfiguration];
//        defaultConfig.syncConfiguration = syncConfig;
//        [RLMRealmConfiguration setDefaultConfiguration:defaultConfig];
//        self.window.rootViewController = [[UIViewController alloc] init];
//        self.window.rootViewController.view = [DrawView new];
//    }
//    else {
        //[self logIn];
        self.controller = [[RLMLoginViewController alloc] init];
        
        __weak typeof(self) weakSelf = self;
        self.controller.connectButtonTapped = ^{
            weakSelf.controller.loading = YES;
            [weakSelf logInWithAddress:weakSelf.controller.hostName username:weakSelf.controller.userName password:weakSelf.controller.password];
        };
        
        self.window.rootViewController = self.controller;
        
    //}

    [self.window makeKeyAndVisible];
    return YES;
}

- (void)logInWithAddress:(NSString *)address username:(NSString *)userName password:(NSString *)password
{
    // The base server path
    // Set to connect to local or online host
    NSURL *authURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:9080", address]];
    
    // Creating a debug credential since this demo is just using the generated access token
    // produced when running the Realm Object Server via the `start-object-server.command`
    RLMSyncCredentials *credential = [RLMSyncCredentials credentialsWithUsername:userName
                                                                        password:password
                                                                        register:NO];
    
    // Log the user in (async, the Realm will start syncing once the user is logged in automatically)
    [RLMSyncUser logInWithCredentials:credential
                        authServerURL:authURL
                         onCompletion:^(RLMSyncUser *user, NSError *error) {
                             if (error) {
                                 UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Login Failed" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                                 [alertController addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil]];
                                 [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
                                 self.controller.loading = NO;
                             }
                             else { // Logged in setup the default Realm
                                    // The Realm virtual path on the server.
                                    // The `~` represents the Realm user ID. Since the user ID is not known until you
                                    // log in, the ~ is used as short-hand to represent this.
                                 NSURL *syncURL = [NSURL URLWithString:[NSString stringWithFormat:@"realm://%@:9080/~/Draw", self.controller.hostName]];
                                 RLMSyncConfiguration *syncConfig = [[RLMSyncConfiguration alloc] initWithUser:user realmURL:syncURL];
                                 RLMRealmConfiguration *defaultConfig = [RLMRealmConfiguration defaultConfiguration];
                                 defaultConfig.syncConfiguration = syncConfig;
                                 [RLMRealmConfiguration setDefaultConfiguration:defaultConfig];
                                 
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     self.window.rootViewController = [[UIViewController alloc] init];
                                     
                                     UIView *drawView = [DrawView new];
                                     drawView.frame = self.window.rootViewController.view.bounds;
                                     self.window.rootViewController.view = drawView;
                                     self.controller = nil;
                                 });
                             }
                         }];
}

@end
