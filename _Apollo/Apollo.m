//
//  Core.m
//  Apollo
//
//  Created by PAN on 2021/8/10.
//

#import "Apollo.h"
#import <objc/runtime.h>
#import <mach-o/dyld.h>

@interface Apollo ()
@property (nonatomic, copy) void (^logBlock)(NSArray<NSString *> *);
@end

@implementation Apollo

+ (id)shared {
    static Apollo *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

+ (void)onPorectedLog:(void (^)(NSArray<NSString *> *))block {
    [[Apollo shared] setLogBlock:block];
}

+ (void)load {
    [Apollo protectDylibImageLoad];
}

+ (void)protectDylibImageLoad {
    NSString *mainBundlePath = [NSBundle mainBundle].bundlePath;
    uint32_t c = _dyld_image_count();
    for(uint32_t i = 0; i < c; ++i) {
        const char *image_name = _dyld_get_image_name(i);
        NSString *imageName = [NSString stringWithFormat:@"%s", image_name];
        if ([imageName hasPrefix:mainBundlePath] && [[imageName lowercaseString] hasSuffix:@".dylib"]) {
            unsigned int classCount;
            const char **classes;
            classes = objc_copyClassNamesForImage(image_name, &classCount);
            for (int i = 0; i < classCount; i++) {
                Class clz = objc_getClass(classes[i]);
                [self protectClassLoad:clz];
            }
            free(classes);
        }
    }
}

+ (void)protectClassLoad:(Class)clz {
    if ([clz respondsToSelector:@selector(load)]) {
        Method originalMethod = class_getClassMethod(clz, @selector(load));
        Method swizzledMethod = class_getClassMethod(Apollo.class, @selector(loadReplacement));
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
    if ([clz respondsToSelector:@selector(initialize)]) {
        Method originalMethod = class_getClassMethod(clz, @selector(initialize));
        Method swizzledMethod = class_getClassMethod(Apollo.class, @selector(loadReplacement));
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

+ (void)loadReplacement {
    if ([[Apollo shared] logBlock] != nil) {
        [[Apollo shared] logBlock]([NSThread callStackSymbols]);
    }
}

@end
