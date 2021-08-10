//
//  Core.h
//  Apollo
//
//  Created by PAN on 2021/8/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Apollo : NSObject

+ (void)onPorectedLog:(void(^)(NSArray<NSString *> *))block;
@end

NS_ASSUME_NONNULL_END
