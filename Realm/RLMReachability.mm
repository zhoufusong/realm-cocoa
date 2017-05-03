////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

#import "RLMReachability.h"

#import "sync/impl/apple/system_configuration.hpp"

#import <realm/util/cf_ptr.hpp>

using namespace realm;
using namespace realm::util;
using CFReachabilityPtr = CFPtr<SCNetworkReachabilityRef>;

typedef void(^RLMReachabilityCallback)(NSString *);

@interface RLMReachability () {
    CFReachabilityPtr _reachabilityPtr;
    dispatch_queue_t _queue;
    RLMReachabilityStatus _previousStatus;
    NSInteger _currentToken;
}

@property (nonatomic, readwrite) NSString *hostName;
@property (nonatomic) NSMutableDictionary<NSNumber *, RLMReachabilityCallback> *callbacks;

- (void)statusChanged;
@end

namespace {

RLMReachabilityStatus status_for_flags(SCNetworkReachabilityFlags flags)
{
    if (flags & kSCNetworkReachabilityFlagsReachable) {
        return RLMReachabilityStatusNone;
    }
    if (flags & kSCNetworkReachabilityFlagsConnectionRequired) {
        if (!(flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)
            || (flags & kSCNetworkReachabilityFlagsInterventionRequired)) {
            return RLMReachabilityStatusNone;
        }
    }
    RLMReachabilityStatus status = RLMReachabilityStatusWAN;
#if TARGET_OS_IPHONE
    if (flags & kSCNetworkReachabilityFlagsIsWWAN)
        status = RLMReachabilityStatusCellular;
#endif
    return status;
}

FOUNDATION_EXTERN void reachability_callback(SCNetworkReachabilityRef, SCNetworkReachabilityFlags, void*);
FOUNDATION_EXTERN void reachability_callback(SCNetworkReachabilityRef, SCNetworkReachabilityFlags, void* info)
{
    [(__bridge RLMReachability *)info statusChanged];
}

}

@implementation RLMReachability

- (void)_sharedInit {
    self.callbacks = [NSMutableDictionary dictionary];
    NSString *name = [NSString stringWithFormat:@"io.realm.sync.reachability-cocoa.%@", [[NSUUID UUID] UUIDString]];
    _queue = dispatch_queue_create([name UTF8String], DISPATCH_QUEUE_SERIAL);
}

- (instancetype)initWithHostName:(NSString *)hostName {
    auto& sc = _impl::SystemConfiguration::shared();
    if (self = [super init]) {
        self.hostName = hostName;
        _reachabilityPtr = CFReachabilityPtr(sc.network_reachability_create_with_name(NULL, [hostName UTF8String]));
        if (!_reachabilityPtr) {
            return nil;
        }
        [self _sharedInit];
    }
    return self;
}

- (instancetype)initWithAddress:(const struct sockaddr *)hostAddress {
    auto& sc = _impl::SystemConfiguration::shared();
    if (self = [super init]) {
        if (!hostAddress) {
            sockaddr zeroAddress{};
            zeroAddress.sa_len = sizeof(zeroAddress);
            zeroAddress.sa_family = AF_INET;
            hostAddress = &zeroAddress;
        }
        _reachabilityPtr = CFReachabilityPtr(sc.network_reachability_create_with_address(NULL, hostAddress));
        if (!_reachabilityPtr) {
            return nil;
        }
        [self _sharedInit];
    }
    return self;
}

- (RLMReachabilityStatus)currentStatus {
    SCNetworkReachabilityFlags flags;
    auto& sc = _impl::SystemConfiguration::shared();
    if (sc.network_reachability_get_flags(_reachabilityPtr.get(), &flags)) {
        return status_for_flags(flags);
    }
    return RLMReachabilityStatusNone;
}

- (void)statusChanged {
    RLMReachabilityStatus current = self.currentStatus;
    if (current != _previousStatus) {
        for (void(^callback)(NSString *) in self.callbacks) {
            callback(self.hostName);
        }
        _previousStatus = current;
    }
}

- (BOOL)start {
    _previousStatus = self.currentStatus;

    SCNetworkReachabilityContext context{0, (__bridge void *)self, nullptr, nullptr, nullptr};
    auto& sc = _impl::SystemConfiguration::shared();

    if (!sc.network_reachability_set_callback(_reachabilityPtr.get(), &reachability_callback, &context)) {
        return NO;
    }
    if (!sc.network_reachability_set_dispatch_queue(_reachabilityPtr.get(), (__bridge void *)_queue)) {
        return NO;
    }
    return YES;
}

- (void)stop {
    auto& sc = _impl::SystemConfiguration::shared();
    sc.network_reachability_set_dispatch_queue(_reachabilityPtr.get(), nullptr);
    sc.network_reachability_set_callback(_reachabilityPtr.get(), nullptr, nullptr);
    dispatch_sync(_queue, ^{});
}

- (NSInteger)registerCallback:(void(^)(NSString * _Nullable))callback {
    NSInteger token = ++_currentToken;
    self.callbacks[@(token)] = callback;
    return token;
}

- (void)unregisterCallback:(NSInteger)token {
    [self.callbacks removeObjectForKey:@(token)];
}

@end
