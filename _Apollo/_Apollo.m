//
//  _Apollo.m
//  _Apollo
//
//  Created by PAN on 2021/8/10.
//

#import <Foundation/Foundation.h>
#import "_Apollo.h"
#import "Core.h"

@implementation _Apollo

+ (nonnull NSArray<NSString *> *)getLoadProtectionLogs {
    return [[Core shared] logs];
}

@end
