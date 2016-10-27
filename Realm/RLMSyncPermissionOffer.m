////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#import "RLMSyncPermissionOffer.h"

#import "RLMRealm.h"
#import "RLMRealmConfiguration+Sync.h"
#import "RLMSyncConfiguration.h"
#import "RLMSyncUser.h"

@interface RLMSyncPermissionOffer ()

@property (readwrite) NSString *token;

@end

@implementation RLMSyncPermissionOffer

+ (instancetype)permissionOfferForRealm:(RLMRealm *)realm
                              expiresAt:(nullable NSDate *)expiresAt
                                   read:(BOOL)mayRead
                                  write:(BOOL)mayWrite
                                 manage:(BOOL)mayManage {
    NSURL *realmURL = realm.configuration.syncConfiguration.realmURL;

    RLMSyncPermissionOffer *permissionOffer = [RLMSyncPermissionOffer new];

    permissionOffer.realmUrl = realmURL.absoluteString;

    permissionOffer.mayRead = mayRead;
    permissionOffer.mayWrite = mayWrite;
    permissionOffer.mayManage = mayManage;

    permissionOffer.expiresAt = expiresAt;

    return permissionOffer;
}

+ (NSArray<NSString *> *)requiredProperties {
    return [[super requiredProperties]
            arrayByAddingObjectsFromArray:@[@"token", @"realmUrl"]];
}

+ (NSArray<NSString *> *)indexedProperties {
    return [[super indexedProperties] arrayByAddingObject:@"token"];
}

+ (NSDictionary *)defaultPropertyValues {
    NSMutableDictionary *defaultPropertyValues = [[super defaultPropertyValues] mutableCopy];
    defaultPropertyValues[@"token"] = @"";
    defaultPropertyValues[@"realmUrl"] = @"";
    return defaultPropertyValues.copy;
}

@end
