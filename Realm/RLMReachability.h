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

#import <Foundation/Foundation.h>

#import <SystemConfiguration/SystemConfiguration.h>

/// What sort of reachability status exists.
typedef enum : NSUInteger {
    /// No reachability.
    RLMReachabilityStatusNone,
    /// Reachability through Wi-Fi or other local network connection.
    RLMReachabilityStatusWAN,
    /// Reachability through a cellular network.
    RLMReachabilityStatusCellular,
} RLMReachabilityStatus;

NS_ASSUME_NONNULL_BEGIN

@interface RLMReachability : NSObject

@property (nonatomic, readonly) RLMReachabilityStatus currentStatus;

@property (nullable, nonatomic, readonly) NSString *hostName;

- (instancetype)initWithHostName:(NSString *)hostName;

- (instancetype)initWithAddress:(nullable const struct sockaddr *)hostAddress;

- (BOOL)start;
- (void)stop;

/**
 Register a listener. The callback will be passed in the hostname, if the listener
 was configured with one, or nil if not. The return value is a token that can be
 used to unregister the callback later
 */
- (NSInteger)registerCallback:(void(^)(NSString * _Nullable))callback;

- (void)unregisterCallback:(NSInteger)token;

@end

NS_ASSUME_NONNULL_END
