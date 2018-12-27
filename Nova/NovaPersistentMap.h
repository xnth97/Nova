//
//  NovaPersistentMap.h
//  Nova
//
//  Created by Yubo Qin on 12/26/18.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NovaPersistentMap<__covariant KeyType, __covariant ObjectType> : NSObject<NSFastEnumeration>

+ (instancetype)defaultMap;
+ (instancetype)persistentMapWithId:(NSString *)mapId;

- (void)setObject:(ObjectType)object forKey:(KeyType)key;
- (void)removeObjectForKey:(KeyType)key;
- (ObjectType)objectForKey:(KeyType)key;

- (NSArray<KeyType> *)allKeys;

- (void)removeAllObjects;

- (ObjectType)objectForKeyedSubscript:(KeyType)key;
- (void)setObject:(ObjectType)obj forKeyedSubscript:(KeyType)key;

@end

NS_ASSUME_NONNULL_END
