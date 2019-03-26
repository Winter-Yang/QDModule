//
//  QDModule.m
//  QuFenQiShop
//
//  Created by 杨雯德 on 16/9/13.
//  Copyright © 2016年 QuFenQi. All rights reserved.
//

#import "QDModule.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <UIKit/UIKit.h>
#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#import <UserNotifications/UserNotifications.h>
#endif
#define ADD_SELECTOR_PREFIX(__SELECTOR__) @selector(ytxmodule_##__SELECTOR__)

#define SWIZZLE_DELEGATE_METHOD(__SELECTORSTRING__) \
Swizzle([delegate class], @selector(__SELECTORSTRING__), class_getClassMethod([QDModule class], ADD_SELECTOR_PREFIX(__SELECTORSTRING__))); \

#define APPDELEGATE_METHOD_MSG_SEND(__SELECTOR__, __ARG1__, __ARG2__) \
for (Class cls in QDModuleClasses) { \
if ([cls respondsToSelector:__SELECTOR__]) { \
[cls performSelector:__SELECTOR__ withObject:__ARG1__ withObject:__ARG2__]; \
} \
} \
\

#define SELECTOR_IS_EQUAL(__SELECTOR1__, __SELECTOR2__) \
Method m1 = class_getClassMethod([QDModule class], __SELECTOR1__); \
IMP imp1 = method_getImplementation(m1); \
Method m2 = class_getInstanceMethod([self class], __SELECTOR2__); \
IMP imp2 = method_getImplementation(m2); \

#define DEF_APPDELEGATE_METHOD_CONTAIN_RESULT(__ARG1__, __ARG2__) \
BOOL result = YES; \
SEL ytx_selector;\
NSString * selectString = NSStringFromSelector(_cmd);\
if ([selectString containsString:@"ytxmodule_"]) {\
ytx_selector = NSSelectorFromString(selectString);\
}else{\
ytx_selector = NSSelectorFromString([NSString stringWithFormat:@"ytxmodule_%@", NSStringFromSelector(_cmd)]); \
}\
SELECTOR_IS_EQUAL(ytx_selector, _cmd) \
if (imp1 != imp2) { \
result = !![self performSelector:ytx_selector withObject:__ARG1__ withObject:__ARG2__]; \
} \
APPDELEGATE_METHOD_MSG_SEND(_cmd, __ARG1__, __ARG2__); \
return result; \

#define DEF_APPDELEGATE_METHOD(__ARG1__, __ARG2__) \
SEL ytx_selector;\
NSString * selectString = NSStringFromSelector(_cmd);\
if ([selectString containsString:@"ytxmodule_"]) {\
ytx_selector = NSSelectorFromString(selectString);\
}else{\
ytx_selector = NSSelectorFromString([NSString stringWithFormat:@"ytxmodule_%@", NSStringFromSelector(_cmd)]); \
}\
SELECTOR_IS_EQUAL(ytx_selector, _cmd) \
if (imp1 != imp2) { \
[self performSelector:ytx_selector withObject:__ARG1__ withObject:__ARG2__]; \
} \
APPDELEGATE_METHOD_MSG_SEND(_cmd, __ARG1__, __ARG2__); \

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"


void Swizzle(Class class, SEL originalSelector, Method swizzledMethod)
{
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    SEL swizzledSelector = method_getName(swizzledMethod);
    
    BOOL didAddMethod =
    class_addMethod(class,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod && originalMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
    class_addMethod(class,
                    swizzledSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
}
@implementation UIApplication (YTXModule)
- (void)module_setDelegate:(id<UIApplicationDelegate>) delegate
{
    
    static dispatch_once_t delegateOnceToken;
    dispatch_once(&delegateOnceToken, ^{
        SWIZZLE_DELEGATE_METHOD(applicationDidFinishLaunching:);
        SWIZZLE_DELEGATE_METHOD(application: willFinishLaunchingWithOptions:);
        SWIZZLE_DELEGATE_METHOD(application: didFinishLaunchingWithOptions:);
        SWIZZLE_DELEGATE_METHOD(applicationDidBecomeActive:)
        SWIZZLE_DELEGATE_METHOD(applicationWillResignActive:)
        SWIZZLE_DELEGATE_METHOD(applicationDidReceiveMemoryWarning:)
        SWIZZLE_DELEGATE_METHOD(applicationWillTerminate:)
        SWIZZLE_DELEGATE_METHOD(applicationSignificantTimeChange:);
        SWIZZLE_DELEGATE_METHOD(application: didRegisterForRemoteNotificationsWithDeviceToken:)
        SWIZZLE_DELEGATE_METHOD(application: didFailToRegisterForRemoteNotificationsWithError:)
        SWIZZLE_DELEGATE_METHOD(applicationShouldRequestHealthAuthorization:)
        SWIZZLE_DELEGATE_METHOD(applicationDidEnterBackground:)
        SWIZZLE_DELEGATE_METHOD(applicationWillEnterForeground:)
        SWIZZLE_DELEGATE_METHOD(applicationProtectedDataWillBecomeUnavailable:)
        SWIZZLE_DELEGATE_METHOD(applicationProtectedDataDidBecomeAvailable:)
        SWIZZLE_DELEGATE_METHOD(application: openURL: options:)
        SWIZZLE_DELEGATE_METHOD(application: openURL: sourceApplication: annotation:)
        SWIZZLE_DELEGATE_METHOD(application: didReceiveRemoteNotification:)
        SWIZZLE_DELEGATE_METHOD(application: didReceiveLocalNotification:)
        SWIZZLE_DELEGATE_METHOD(application: didReceiveRemoteNotification: fetchCompletionHandler:)
        SWIZZLE_DELEGATE_METHOD(userNotificationCenter: didReceiveNotificationResponse: withCompletionHandler:)
        SWIZZLE_DELEGATE_METHOD(userNotificationCenter: willPresentNotification: withCompletionHandler:)
        
    });
    [self module_setDelegate:delegate];
}
@end


static NSMutableArray<Class> *QDModuleClasses;

@interface QDModule()
@property (nonatomic) NSMutableDictionary *routes;
@end

@implementation QDModule

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Swizzle([UIApplication class], @selector(setDelegate:), class_getInstanceMethod([UIApplication class], @selector(module_setDelegate:)));
    });
}
+ (void)registerAppDelegateModule:(Class) moduleClass
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        QDModuleClasses = [NSMutableArray new];
    });
    [QDModuleClasses addObject:moduleClass];
    objc_setAssociatedObject(moduleClass, &YTXModuleClassIsRegistered,
                             @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
BOOL YTXModuleClassIsRegistered(Class cls)
{
    return [objc_getAssociatedObject(cls, &YTXModuleClassIsRegistered) ?: @YES boolValue];
}
+ (void) detectRouterModule:(Class) moduleClass
{
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(object_getClass(moduleClass), &methodCount);
    
    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];
        NSString * methodName = NSStringFromSelector(method_getName(method));
        if ([methodName hasPrefix:@"__YTXModuleRouterRegisterURL_"]) {
            [moduleClass performSelector:method_getName(method)]; \
        }
    }
    
    free(methods);
}

#pragma mark - AppDelegate

+ (void)ytxmodule_applicationDidFinishLaunching:(UIApplication *)application
{
    DEF_APPDELEGATE_METHOD(application, NULL);
}
+ (BOOL)ytxmodule_application:(UIApplication *)application willFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions
{
    DEF_APPDELEGATE_METHOD_CONTAIN_RESULT(application, launchOptions);
}
+ (BOOL)ytxmodule_application:(UIApplication *)application didFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions
{
    DEF_APPDELEGATE_METHOD_CONTAIN_RESULT(application, launchOptions);
}
+ (void)ytxmodule_applicationDidBecomeActive:(UIApplication *)application
{
    DEF_APPDELEGATE_METHOD(application, NULL);
}
+ (void)ytxmodule_applicationWillResignActive:(UIApplication *)application
{
    DEF_APPDELEGATE_METHOD(application, NULL);
}
+ (void)ytxmodule_applicationDidReceiveMemoryWarning:(UIApplication *)application;
{
    DEF_APPDELEGATE_METHOD(application, NULL);
}
+ (void)ytxmodule_applicationWillTerminate:(UIApplication *)application
{
    DEF_APPDELEGATE_METHOD(application, NULL);
}
+ (void)ytxmodule_applicationSignificantTimeChange:(UIApplication *)application;
{
    DEF_APPDELEGATE_METHOD(application, NULL);
}
+ (void)ytxmodule_application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken NS_AVAILABLE_IOS(3_0)
{
    DEF_APPDELEGATE_METHOD(application, deviceToken);
}
+ (void)ytxmodule_application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error NS_AVAILABLE_IOS(3_0)
{
    DEF_APPDELEGATE_METHOD(application, error);
}
+ (void)ytxmodule_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo NS_AVAILABLE_IOS(3_0)
{
    DEF_APPDELEGATE_METHOD(application, userInfo);
}
+ (void)ytxmodule_application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    DEF_APPDELEGATE_METHOD(application, notification);
}
+ (void)ytxmodule_applicationShouldRequestHealthAuthorization:(UIApplication *)application NS_AVAILABLE_IOS(9_0)
{
    DEF_APPDELEGATE_METHOD(application, NULL);
}
+ (void)ytxmodule_applicationDidEnterBackground:(UIApplication *)application NS_AVAILABLE_IOS(4_0)
{
    DEF_APPDELEGATE_METHOD(application, NULL);
}
+ (void)ytxmodule_applicationWillEnterForeground:(UIApplication *)application NS_AVAILABLE_IOS(4_0)
{
    DEF_APPDELEGATE_METHOD(application, NULL);
}
+ (void)ytxmodule_applicationProtectedDataWillBecomeUnavailable:(UIApplication *)application NS_AVAILABLE_IOS(4_0)
{
    DEF_APPDELEGATE_METHOD(application, NULL);
}
+ (void)ytxmodule_applicationProtectedDataDidBecomeAvailable:(UIApplication *)application    NS_AVAILABLE_IOS(4_0)
{
    DEF_APPDELEGATE_METHOD(application, NULL);
}


+ (void)ytxmodule_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    SEL ytx_selector = NSSelectorFromString([NSString stringWithFormat:@"ytxmodule_%@", NSStringFromSelector(_cmd)]);
    SELECTOR_IS_EQUAL(ytx_selector, _cmd)
    BOOL (*typed_msgSend)(id, SEL, id, id, id) = (void *)objc_msgSend;
    for (Class cls in QDModuleClasses) {
        if ([cls respondsToSelector:_cmd]) {
            typed_msgSend(cls, _cmd, application, userInfo, completionHandler);
        }
    }
    
}

#ifdef NSFoundationVersionNumber_iOS_9_x_Max

+(void)ytxmodule_userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotificationResponse *)response withCompletionHandler:(void(^)())completionHandler{
    SEL ytx_selector = NSSelectorFromString([NSString stringWithFormat:@"ytxmodule_%@", NSStringFromSelector(_cmd)]);
    SELECTOR_IS_EQUAL(ytx_selector, _cmd)
    BOOL (*typed_msgSend)(id, SEL, id, id, id) = (void *)objc_msgSend;
    for (Class cls in QDModuleClasses) {
        if ([cls respondsToSelector:_cmd]) {
            typed_msgSend(cls, _cmd, center, response, completionHandler);
        }
    }
}

+ (void)ytxmodule_userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)())completionHandler
{
    SEL ytx_selector = NSSelectorFromString([NSString stringWithFormat:@"ytxmodule_%@", NSStringFromSelector(_cmd)]);
    SELECTOR_IS_EQUAL(ytx_selector, _cmd)
    BOOL (*typed_msgSend)(id, SEL, id, id, id) = (void *)objc_msgSend;
    for (Class cls in QDModuleClasses) {
        if ([cls respondsToSelector:_cmd]) {
            typed_msgSend(cls, _cmd, center, response, completionHandler);
        }
    }
}

#endif


+ (BOOL)ytxmodule_application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options NS_AVAILABLE_IOS(9_0); // no equiv. notification. return NO if the application can't open for some reaso
{
    
    BOOL result = YES;
    SEL ytx_selector = NSSelectorFromString([NSString stringWithFormat:@"ytxmodule_%@", NSStringFromSelector(_cmd)]);
    SELECTOR_IS_EQUAL(ytx_selector, _cmd)
    if (imp1 != imp2) {
        result = ((BOOL (*)(id, SEL, id, id, id))(void *)objc_msgSend)(self, ytx_selector, app, url, options);
    }
    BOOL (*typed_msgSend)(id, SEL, id, id, id) = (void *)objc_msgSend;
    for (Class cls in QDModuleClasses) {
        if ([cls respondsToSelector:_cmd]) {
            typed_msgSend(cls, _cmd, app, url, options);
        }
    }
    return result;
}

+ (BOOL)ytxmodule_application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(id)annotation NS_AVAILABLE_IOS(9_0) __TVOS_PROHIBITED;
{
    BOOL result = YES;
    SEL ytx_selector = NSSelectorFromString([NSString stringWithFormat:@"ytxmodule_%@", NSStringFromSelector(_cmd)]);
    SELECTOR_IS_EQUAL(ytx_selector, _cmd)
    if (imp1 != imp2) {
        result = ((BOOL (*)(id, SEL, id, id, id, id))(void *)objc_msgSend)(self, ytx_selector, application, url, sourceApplication, annotation);
    }
    BOOL (*typed_msgSend)(id, SEL, id, id, id, id) = (void *)objc_msgSend;
    for (Class cls in QDModuleClasses) {
        if ([cls respondsToSelector:_cmd]) {
            typed_msgSend(cls, _cmd, application, url, sourceApplication, annotation);
        }
    }
    return result;
}
#pragma clang diagnostic pop

#pragma clang diagnostic pop

@end
