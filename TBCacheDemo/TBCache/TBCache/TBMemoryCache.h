//
//  TBMemoryCache.h
//  TBCache
//
//  Created by DangGu on 15/8/4.
//  Copyright (c) 2015年 Teambition. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TBMemoryCache,TBDiskCache;
typedef void (^TBMemoryCacheBlock) (TBMemoryCache *cache);
typedef void (^TBMemoryCacheObjectBlock) (TBMemoryCache *cache, NSString *key, id object);

@interface TBMemoryCache : NSObject

@property (nonatomic, assign, readonly) NSUInteger      cacheCount;

@property (nonatomic, assign) NSTimeInterval            expiredTime;

+ (TBMemoryCache *)sharedCache;

- (void)objectForKey:(NSString *)key completion:(TBMemoryCacheObjectBlock)completion;
- (void)setObject:(id)object forKey:(NSString *)key completion:(TBMemoryCacheObjectBlock)completion;
- (void)removeAllCacheObjects:(TBMemoryCacheBlock)block;
- (void)transferMemoryCacheToDiskCache:(TBDiskCache *)diskCache andClearMemoryCache:(BOOL)clear;

@end
