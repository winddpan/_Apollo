//
//  Core.m
//  _Apollo
//
//  Created by PAN on 2021/8/10.
//

#import "Core.h"
#import <objc/runtime.h>
#import <mach-o/dyld.h>

void _loadReplacement(id self, SEL cmd)
{
    NSString *key = NSStringFromClass([self class]);
    NSString *image = [[[Core shared] imageMap] valueForKey:key];
    if (image != nil) {
        NSString *log = [NSString stringWithFormat:@"%@ - %@", [self class], image];
        [[[Core shared] logs] addObject:log];
    }
}


@implementation Core

+ (id)shared {
    static Core *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
        shared.logs = [NSMutableArray new];
        shared.imageMap = [NSMutableDictionary new];
    });
    return shared;
}

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [Core protectDylibImageLoad];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[Core shared] setImageMap:nil];
        });
    });
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
                [[[Core shared] imageMap] setValue:imageName forKey:NSStringFromClass(clz)];
                [self protectClassLoad:clz];
            }
            free(classes);
        }
    }
}

+ (void)protectClassLoad:(Class)clz {
    if ([clz respondsToSelector:@selector(load)]) {
        Method originalMethod = class_getClassMethod(clz, @selector(load));
        const char *types = method_getTypeEncoding(originalMethod);
        class_addMethod(clz, NSSelectorFromString(@"loadReplacement"), (IMP)_loadReplacement, types);
        Method swizzledMethod = class_getInstanceMethod(clz, NSSelectorFromString(@"loadReplacement"));
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@end
