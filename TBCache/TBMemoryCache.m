//
//  TBMemoryCache.m
//  TBCache
//
//  Created by DangGu on 15/8/4.
//  Copyright (c) 2015年 Teambition. All rights reserved.
//


#define kTBMemoryCachePrefix @"com.teambition.TBMemoryCache"

#import "TBMemoryCache.h"
#import "TBDiskCache.h"

@interface TBMemoryCache()

@property (nonatomic, strong) NSMutableDictionary *cacheDictionary;
@property (nonatomic, strong) NSMutableDictionary *cacheDate;
@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, assign, readwrite) NSUInteger cacheCount;

@end

@implementation TBMemoryCache

#pragma mark - life cycle
+ (TBMemoryCache *)sharedCache {
    
    static TBMemoryCache *sharedCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCache = [[TBMemoryCache alloc] init];
    });
    return sharedCache;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _cacheDictionary = [[NSMutableDictionary alloc] init];
        _cacheDate = [[NSMutableDictionary alloc] init];
        _queue = dispatch_queue_create([kTBMemoryCachePrefix UTF8String], DISPATCH_QUEUE_CONCURRENT);
        _expiredTime = 0.0;
    }
    return self;
}

#pragma mark - private method
- (void)removeAllCacheObjects:(TBMemoryCacheBlock)block {
    @synchronized(self){
        [_cacheDictionary removeAllObjects];
        [_cacheDate removeAllObjects];
    }
    __weak TBMemoryCache *weakSelf = self;
    dispatch_async(_queue, ^{
        TBMemoryCache *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (block) {
            block(strongSelf);
        }
    });
}

- (BOOL)isExpiredForKey:(NSString *)key {
    if (_expiredTime == 0.0) {
        return NO;
    }
    
    NSDate *creatAt = [_cacheDate objectForKey:key];
    NSTimeInterval interval = [creatAt timeIntervalSinceNow];
    if ((-interval) > _expiredTime) {
        return YES;
    } else {
        return NO;
    }
}

- (void)enumertateCacheUsingBlock:(void (^) (NSString *key, id object, BOOL *stop))block completion:(TBMemoryCacheBlock)completion{
    if (!block) {
        return;
    }
    __weak TBMemoryCache *weakSelf = self;
    dispatch_async(_queue, ^{
        TBMemoryCache *strongSelf = weakSelf;
        [_cacheDictionary enumerateKeysAndObjectsUsingBlock:block];
        completion(strongSelf);
    });
}

#pragma mark - public method
- (void)objectForKey:(NSString *)key completion:(TBMemoryCacheObjectBlock)completion {
    if (!key || !completion) {
        return;
    }
    NSDate *now = [NSDate date];
    id object = nil;
    
    if ([self isExpiredForKey:key]) {
        object = nil;
        [self removeObjectForKey:key completion:nil];
    } else {
        object = [_cacheDictionary objectForKey:key];
        @synchronized(self){
            [_cacheDate setObject:now forKey:key];
        }
    }

    __weak TBMemoryCache *weakSelf = self;
    dispatch_async(_queue, ^{
        TBMemoryCache *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        completion(strongSelf, key, object);
    });

}

- (void)setObject:(id)object forKey:(NSString *)key completion:(TBMemoryCacheObjectBlock)completion {
    if (!object || !key) {
        return;
    }
    NSDate *now = [NSDate date];
    @synchronized(self){
        [_cacheDictionary setObject:object forKey:key];
        [_cacheDate setObject:now forKey:key];
    }
    
    if (completion) {
        __weak TBMemoryCache *weakSelf = self;
        dispatch_async(_queue, ^{
            TBMemoryCache *strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            completion(strongSelf, key, object);
        });
    }
}

- (void)removeObjectForKey:(NSString *)key completion:(TBMemoryCacheBlock)completion{
    if (!key) {
        return;
    }
    @synchronized(self) {
        [_cacheDictionary removeObjectForKey:key];
        [_cacheDate removeObjectForKey:key];
    }
    if (completion) {
        __weak TBMemoryCache *weakSelf = self;
        dispatch_async(_queue, ^{
            TBMemoryCache *strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            completion(strongSelf);
        });
    }
    
}

- (void)transferMemoryCacheToDiskCache:(TBDiskCache *)diskCache andClearMemoryCache:(BOOL)clear{
    [self enumertateCacheUsingBlock:^(NSString *key, id object, BOOL *stop) {
        if (object) {
            [diskCache setObject:object forKey:key completion:nil];
        }
    } completion:^(TBMemoryCache *cache) {
        if (clear) {
            [self removeAllCacheObjects:nil];
        }
    }];
}

#pragma mark - setters and getters

- (NSUInteger)cacheCount {
    return _cacheDictionary.count;
}


@end
