//
//  Core.m
//  _Apollo
//
//  Created by PAN on 2021/8/10.
//

#import "Core.h"
#import <objc/runtime.h>
#import <dlfcn.h>
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

static uintptr_t firstCmdAfterHeader(const struct mach_header* const header) {
    switch(header->magic) {
        case MH_MAGIC:
        case MH_CIGAM:
            return (uintptr_t)(header + 1);
        case MH_MAGIC_64:
        case MH_CIGAM_64:
            return (uintptr_t)(((struct mach_header_64*)header) + 1);
        default:
            return 0;
    }
}

/* Verify that address + offset + length is within bounds. */
static const void *macho_offset (const void *address, size_t offset) {
    void *result = ((uint8_t *) address) + offset;
    return result;
}

static const char *fullfilPath(const char* path) {
    NSString *mainBundlePath = [NSBundle mainBundle].bundlePath;
    if (strstr(path, "@executable_path")) {
        NSString *n = [[NSString stringWithFormat:@"%s", path] stringByReplacingOccurrencesOfString:@"@executable_path" withString:mainBundlePath];
        return [n UTF8String];
    }
    if (strstr(path, "@rpath")) {
        NSString *r = [NSString stringWithFormat:@"%@/Frameworks", mainBundlePath];
        NSString *n = [[NSString stringWithFormat:@"%s", path] stringByReplacingOccurrencesOfString:@"@rpath" withString:r];
        return [n UTF8String];
    }
    if (strstr(path, "@loader_path")) {
        NSString *n = [[NSString stringWithFormat:@"%s", path] stringByReplacingOccurrencesOfString:@"@loader_path" withString:mainBundlePath];
        return [n UTF8String];
    }
    return NULL;;
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
        if ([Core detectedIfProtect]) {
            [Core go];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[Core shared] setImageMap:nil];
            });
        }
    });
}


+ (void)go {
    NSString *mainBundlePath = [NSBundle mainBundle].bundlePath;
    const struct mach_header* header = _dyld_get_image_header(0);
    if (header == NULL) {
        return;
    }
    uintptr_t cmdPtr = firstCmdAfterHeader(header);
    if (cmdPtr == 0) {
        return;
    }
    bool after_signature = false;
    for(uint32_t iCmd = 0; iCmd < header->ncmds; iCmd++) {
        struct load_command* lc = (struct load_command*)cmdPtr;
        cmdPtr += lc->cmdsize;
        if (lc->cmd == LC_CODE_SIGNATURE) {
            after_signature = true;
        }
        if (after_signature) {
            if (lc->cmd == LC_LOAD_DYLIB || lc->cmd == LC_LOAD_WEAK_DYLIB) {
                struct dylib_command *dylib_cmd = (struct dylib_command *)lc;
                size_t namelen = lc->cmdsize - sizeof(struct dylib_command);
                const void *nameptr = macho_offset(dylib_cmd, sizeof(struct dylib_command));
                if (nameptr == NULL) continue;
                char *name = malloc(namelen);
                strlcpy(name, nameptr, namelen);
                name = fullfilPath(name);
                if (name) {
                    [self protectImageName:name];
                }
            }
        }
    }
}

+ (void)protectImageName:(const char *)image_name {
    unsigned int classCount;
    const char **classes;
    classes = objc_copyClassNamesForImage(image_name, &classCount);
    for (int i = 0; i < classCount; i++) {
        Class clz = objc_getClass(classes[i]);
        [[[Core shared] imageMap] setValue:[NSString stringWithFormat:@"%s", image_name] forKey:NSStringFromClass(clz)];
        [self protectClassLoad:clz];
    }
    free(classes);
    
    NSLog(@"LC_LOAD_DYLIB %s %d", image_name, classCount);
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

// 保护几率 (0% ... 100%)
+ (BOOL)detectedIfProtect {
    NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
    float proectPercent = [[infoPlist objectForKey:@"ApolloPercent"] floatValue];
    if (proectPercent <= 0) {
        proectPercent = 0;
    } else if (proectPercent > 1) {
        proectPercent = 1;
    }
    NSInteger random = [[NSUserDefaults standardUserDefaults] integerForKey:@"ApolloRandom"];
    if (random <= 0) {
        random = arc4random() % 100;
        [[NSUserDefaults standardUserDefaults] setInteger:random forKey:@"ApolloRandom"];
    }
    return random < (int)(proectPercent * 100);
}

@end
