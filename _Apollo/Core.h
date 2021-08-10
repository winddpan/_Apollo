//
//  Core.h
//  _Apollo
//
//  Created by PAN on 2021/8/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Core : NSObject
+ (id)shared;

@property (nonatomic, strong, nullable) NSMutableDictionary *imageMap;
@property (nonatomic, strong, nonnull) NSMutableArray<NSString *> *logs;
@end

NS_ASSUME_NONNULL_END
