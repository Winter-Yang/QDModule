//
//  QDModule.h
//  QuFenQiShop
//
//  Created by 杨雯德 on 16/9/13.
//  Copyright © 2016年 QuFenQi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#define QDMODULE_EXTERN() \
+ (void)load \
{ \
[QDModule registerAppDelegateModule:self]; \
[QDModule detectRouterModule:self]; \
if ([self respondsToSelector:@selector(__QDmodule_load)]) { \
[self performSelector:@selector(__QDmodule_load)]; \
} \
} \
+ (void)__QDmodule_load \

@interface QDModule : NSObject

+ (void) registerAppDelegateModule:(id) moduleClass;
+ (void) detectRouterModule:(id) moduleClass;
@end
