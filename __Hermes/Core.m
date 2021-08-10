//
//  Core.m
//  Hermes
//
//  Created by PAN on 2021/8/10.
//

#import "Core.h"
#import <objc/runtime.h>
#import <mach-o/dyld.h>

@implementation Core

+ (void)load {
    [Core protectDylibImageLoad];
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
        Method swizzledMethod = class_getClassMethod(Core.class, @selector(loadReplacement));
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

+ (void)loadReplacement {}

@end
