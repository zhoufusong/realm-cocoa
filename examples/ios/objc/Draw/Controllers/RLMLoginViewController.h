//
//  RLMLoginViewController.h
//  RealmExamples
//
//  Created by Tim Oliver on 11/28/16.
//  Copyright © 2016 Realm. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RLMLoginViewController : UITableViewController

@property (nonatomic, assign) BOOL loading;
@property (nonatomic, copy) void (^connectButtonTapped)(void);

@property (nonatomic, readonly) NSString *hostName;
@property (nonatomic, readonly) NSString *userName;
@property (nonatomic, readonly) NSString *password;

@end
