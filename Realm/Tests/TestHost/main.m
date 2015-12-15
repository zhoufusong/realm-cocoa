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

static NSMutableArray *queue() {
    static NSMutableArray *a;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        a = [NSMutableArray new];
    });
    return a;
}

static void pushToken(id token) {
    NSMutableArray *q = queue();
    @synchronized(q) {
        if (q.count == 0)
            [q addObject:token];
        else
            [q insertObject:token atIndex:arc4random_uniform((uint32_t)q.count)];
    }
}

static bool popToken() {
    NSMutableArray *q = queue();
    @synchronized(q) {
        if (q.count) {
            [q removeLastObject];
            return true;
        }
    }
    return false;
}

static void doStuff() {
    __block int calls = 0;
    __block void (^block)(RLMResults *, NSError *);
    NSMutableArray *queries = [NSMutableArray new];
    block = ^(__unused RLMResults *results, __unused NSError *error) {
        ++calls;
        if (calls < 100) {
            for (int i = 0; i < 3; ++i) {
                uint32_t idx = arc4random_uniform(10);
                if (idx >= queries.count) {
                    [queries addObject:[IntObject allObjects]];
                    pushToken([queries.lastObject addNotificationBlock:block]);
                }
                else {
                    pushToken([queries[idx] addNotificationBlock:block]);
                }
            }
        }
        else {
            block = nil;
        }

        createObject(calls);

        if (!popToken()) {
            CFRunLoopStop(CFRunLoopGetCurrent());
        }
    };

    [queries addObject:[IntObject allObjects]];
    pushToken([queries.lastObject addNotificationBlock:block]);
}

static void *wrapper(void *ctx) {
    @autoreleasepool {
        CFRunLoopPerformBlock(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, ^{
            doStuff();
        });
        CFRunLoopRun();
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
            NSLog(@"%d", i);
            if (i >= count)
                pthread_join(threads[i - count], 0);
            if (i < count * 2)
                pthread_create(&threads[i], 0, &wrapper, 0);
        }
        return 0;
    }
}
