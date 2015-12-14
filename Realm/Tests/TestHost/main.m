//
//  main.m
//  TestHost
//
//  Created by Thomas Goyne on 8/6/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import <TargetConditionals.h>
#import <libkern/OSAtomic.h>
#import <CoreFoundation/CFRunLoop.h>
#import <Realm/Realm.h>
#import <pthread.h>

@interface IntObject : RLMObject
@property (nonatomic) int intCol;
@end
@implementation IntObject
@end

static void createObject(int value) {
    @autoreleasepool {
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm transactionWithBlock:^{
            [IntObject createInDefaultRealmWithValue:@[@(value)]];
        }];
    }
}

static void doStuff() {
    __block int calls = 0;
    __block NSMutableSet *waiting = [NSMutableSet new];
    void (^block)(RLMResults *, NSError *) = ^(RLMResults *results, __unused NSError *error) {
//        NSLog(@"%d: call waiting[%p]", (int)pthread_mach_thread_np(pthread_self()), (__bridge void *)waiting);
        ++calls;
        [waiting removeObject:results];
        if (waiting.count == 0) {
//            NSLog(@"%d: stopping[%p]", (int)pthread_mach_thread_np(pthread_self()), (void *)CFRunLoopGetCurrent());
            CFRunLoopStop(CFRunLoopGetCurrent());
        }
    };

    RLMResults *results[5];
    id tokens[10];

    // Create five queries with notifications and wait for initial results
    for (int i = 0; i < 5; ++i) {
        results[i] = [IntObject allObjects];
        tokens[i] = [results[i] addNotificationBlock:block];
        [waiting addObject:results[i]];
    }
//    NSLog(@"%d: waiting[%p]", (int)pthread_mach_thread_np(pthread_self()), (__bridge void *)waiting);
//    NSLog(@"%d: running[%p]", (int)pthread_mach_thread_np(pthread_self()), (void *)CFRunLoopGetCurrent());
//    while (calls < 5)
        CFRunLoopRun();
//    NSLog(@"%d: assertion", (int)pthread_mach_thread_np(pthread_self()));
    if (calls < 5)
        return;
    assert(calls >= 5);
//    NSLog(@"%d: queries created", (int)pthread_mach_thread_np(pthread_self()));

    // Add another block to each query, wait for them
    for (int i = 5; i < 10; ++i) {
        tokens[i] = [results[i - 5] addNotificationBlock:block];
        [waiting addObject:results[i - 5]];
    }
    CFRunLoopRun();
    assert(calls >= 10);
//    NSLog(@"%d: blocks added", (int)pthread_mach_thread_np(pthread_self()));

    // We're done adding queries so we no longer need to track which ones
    // exactly have been notified, as they're all notified in one runloop
    // task
    waiting = nil;

    for (int i = 0; i < 10; ++i) {
        createObject(i);

        // Remove a random token
        int idx = arc4random_uniform(10 - i) + i;
        [tokens[idx] stop];
        tokens[idx] = tokens[i];

        // Wait for all remaining ones to get a notification
        if (i < 9) {
            CFRunLoopRun();
        }
//        NSLog(@"%d: removed %d/10", (int)pthread_mach_thread_np(pthread_self()), i + 1);
    }
}

static void *wrapper(void *ctx) {
    CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(NULL, kCFRunLoopAllActivities, YES, 0,
                                                                       ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
                                                                           NSString *str;
#define ACTIVITY(s) case kCFRunLoop##s: str = @#s; break
                                                                           switch (activity) {
                                                                               ACTIVITY(Entry);
                                                                               ACTIVITY(BeforeTimers);
                                                                               ACTIVITY(BeforeSources);
                                                                               ACTIVITY(BeforeWaiting);
                                                                               ACTIVITY(AfterWaiting);
                                                                               ACTIVITY(Exit);
                                                                               default: str = @((int)activity).stringValue;
                                                                           }
                                                                           NSLog(@"%d: observer[%@]", (int)pthread_mach_thread_np(pthread_self()), str);
                                                                       });
//    CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, kCFRunLoopCommonModes);

    @autoreleasepool {
        doStuff();
    }
    return ctx;
}

int main(int argc, char *argv[]) {
    @autoreleasepool {
        static const int count = 100;
        pthread_t threads[count * 2];
        @autoreleasepool {
            [RLMRealm defaultRealm];
        }

        for (int i = 0; i < count * 3; ++i) {
            if (i >= count)
                pthread_join(threads[i - count], 0);
            if (i < count * 2)
                pthread_create(&threads[i], 0, &wrapper, 0);
        }
        return 0;
    }
}
