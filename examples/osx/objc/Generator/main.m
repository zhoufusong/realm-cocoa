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
#import <Foundation/Foundation.h>
#import <Realm/Realm.h>
@interface Strings : RLMObject
@property NSString  *value;
@end
@implementation Strings
@end
int main(int argc, const char * argv[])
{
    @autoreleasepool {
        RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
        config.path = [[[config.path stringByDeletingLastPathComponent]
                        stringByAppendingPathComponent:@"strings"]
                       stringByAppendingPathExtension:@"realm"];
        [RLMRealmConfiguration setDefaultConfiguration:config];
        NSLog(@"path: %@", config.path);

        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        // Danish
        NSLog(@"Hello Kenneth and Leonardo");
        Strings *danish = [[Strings alloc] init];
        danish.value = @"Blåbærgrød";
        [realm addObject:danish];
        [realm commitWriteTransaction];
        
    }
}