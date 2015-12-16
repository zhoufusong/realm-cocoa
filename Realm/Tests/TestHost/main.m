//
//  main.m
//  TestHost
//
//  Created by Thomas Goyne on 8/6/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import <TargetConditionals.h>
#import <XCTest/XCTest.h>

#if TARGET_OS_TV || TARGET_OS_WATCH

// tvOS and watchOS don't support testing at this time.
int main(int argc, const char *argv[]) {
}

#elif TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation AppDelegate
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}

#else

#import <Cocoa/Cocoa.h>

#import "RLMTestCase.h"

@interface DynamicTests : RLMTestCase
@end


int main(int argc, const char *argv[]) {
    @autoreleasepool {
        XCTestSuite *suite = [XCTestSuite defaultTestSuite];
//        XCTestSuite *suite = [XCTestSuite testSuiteForTestCaseClass:[DynamicTests class]];
        [suite run];
        return 0;
//        return NSApplicationMain(argc, argv);
    }
}

#endif
