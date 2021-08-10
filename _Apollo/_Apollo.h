//
//  Apollo.h
//  Apollo
//
//  Created by PAN on 2021/8/10.
//

#import <Foundation/Foundation.h>

//! Project version number for Apollo.
FOUNDATION_EXPORT double ApolloVersionNumber;

//! Project version string for Apollo.
FOUNDATION_EXPORT const unsigned char ApolloVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Apollo/PublicHeader.h>


@interface _Apollo : NSObject

+ (nonnull NSArray<NSString *> *)getLoadProtectionLogs;
@end

