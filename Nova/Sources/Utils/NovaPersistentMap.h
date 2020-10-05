//
//  NovaPersistentMap.h
//  Nova
//
//  A utility class that works as NSDictionary but implements data persistence
//  using mmap and NSKeyedArchiver/Unarchiver.
//
//  Created by Yubo Qin on 12/26/18.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NovaPersistentMap<__covariant KeyType, __covariant ObjectType> : NSObject<NSFastEnumeration>

+ (instancetype)defaultMap;
+ (instancetype)persistentMapWithId:(NSString *)mapId;

- (void)setObject:(nullable ObjectType)object forKey:(KeyType)key;
- (void)removeObjectForKey:(KeyType)key;
- (nullable ObjectType)objectForKey:(KeyType)key;

- (NSArray<KeyType> *)allKeys;

- (void)removeAllObjects;

- (nullable ObjectType)objectForKeyedSubscript:(KeyType)key;
- (void)setObject:(nullable ObjectType)obj forKeyedSubscript:(KeyType)key;

@end

NS_ASSUME_NONNULL_END
