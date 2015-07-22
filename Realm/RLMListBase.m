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

#import "RLMListBase.h"
#import <Realm/RLMArray.h>
#import <Realm/RLMCollection.h>

@interface RLMListBase ()<RLMCollection>

@end

@implementation RLMListBase

@dynamic count, objectClassName, realm;

- (instancetype)initWithArray:(RLMArray *)array {
    if (self) {
        __rlmArray = array;
    }
    return self;
}

- (void)forwardInvocation:(nonnull NSInvocation *)invocation {
    [invocation invokeWithTarget:__rlmArray];
}

- (nullable NSMethodSignature *)methodSignatureForSelector:(nonnull SEL)sel {
    return [__rlmArray methodSignatureForSelector:sel];
}

- (id)forwardingTargetForSelector:(__unused SEL)aSelector
{
    return __rlmArray;
}

@end
