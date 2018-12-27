//
//  NovaPersistentMap.m
//  Nova
//
//  Created by Yubo Qin on 12/26/18.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import "NovaPersistentMap.h"
#import <pthread/pthread.h>
#import <sys/mman.h>
#import <sys/stat.h>

static NSMutableDictionary<NSString *, NovaPersistentMap *> *g_instanceDict;
static pthread_mutex_t g_instanceLock;
static int pageSize;

@implementation NovaPersistentMap {
    int m_fd;
    char *m_ptr;
    size_t m_size;
    size_t m_dataSize;
    NSString *m_mapId;
    NSString *m_path;
    pthread_mutex_t m_lock;
    NSMutableDictionary<NSString *, id> *m_dict;
}

+ (void)initialize {
    if (self == [NovaPersistentMap class]) {
        g_instanceDict = [NSMutableDictionary dictionary];
        pageSize = getpagesize();
        pthread_mutex_init(&g_instanceLock, NULL);
    }
}

- (instancetype)initWithId:(NSString *)mapId {
    self = [super init];
    if (self) {
        m_fd = 0;
        m_mapId = mapId;
        NSString *dirPath = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject]
                             stringByAppendingPathComponent:@"nova.persistentMap"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
            if (![[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil]) {
                return nil;
            }
        }
        m_path = [dirPath stringByAppendingPathComponent:mapId];
        if (![[NSFileManager defaultManager] fileExistsAtPath:m_path]) {
            [[NSFileManager defaultManager] createFileAtPath:m_path contents:nil attributes:nil];
        }
        if (![self loadFromFile]) {
            return nil;
        }
        
        pthread_mutex_init(&m_lock, NULL);
    }
    return self;
}

+ (instancetype)defaultMap {
    return [NovaPersistentMap persistentMapWithId:@"default.nova.persistentMap"];
}

+ (instancetype)persistentMapWithId:(NSString *)mapId {
    pthread_mutex_lock(&g_instanceLock);
    NovaPersistentMap *map = [g_instanceDict objectForKey:mapId];
    if (map == nil) {
        map = [[NovaPersistentMap alloc] initWithId:mapId];
        g_instanceDict[mapId] = map;
    }
    pthread_mutex_unlock(&g_instanceLock);
    return map;
}

- (void)dealloc {
    pthread_mutex_lock(&g_instanceLock);
    pthread_mutex_lock(&m_lock);
    
    if (m_ptr != NULL && m_ptr != MAP_FAILED) {
        munmap(m_ptr, m_size);
        m_ptr = NULL;
    }
    
    if (m_fd >= 0) {
        close(m_fd);
        m_fd = -1;
    }
    
    pthread_mutex_unlock(&m_lock);
    
    [g_instanceDict removeObjectForKey:m_mapId];
    
    pthread_mutex_unlock(&g_instanceLock);
}

#pragma mark - Helper functions

- (BOOL)loadFromFile {
    m_fd = open(m_path.UTF8String, O_RDWR, S_IRWXU);
    if (m_fd < 0) {
        return NO;
    }
    
    m_size = 0;
    struct stat st = {};
    if (fstat(m_fd, &st) != -1) {
        m_size = (size_t)st.st_size;
    }
    
    if (m_size < pageSize || (m_size % pageSize != 0)) {
        m_size = ((m_size / pageSize) + 1) * pageSize;
        if (ftruncate(m_fd, m_size) != 0) {
            m_size = (size_t)st.st_size;
            return NO;
        }
    }
    
    m_ptr = (char *)mmap(NULL, m_size, PROT_READ | PROT_WRITE, MAP_SHARED, m_fd, 0);
    if (m_ptr == MAP_FAILED) {
        return NO;
    }
    
    NSData *lengthBuffer = [NSData dataWithBytesNoCopy:m_ptr length:sizeof(uint64_t) freeWhenDone:NO];
    uint64_t actualLength = 0;
    [lengthBuffer getBytes:&actualLength length:sizeof(uint64_t)];
    m_dataSize = actualLength;
    NSData *inputBuffer = [NSData dataWithBytesNoCopy:m_ptr + sizeof(uint64_t) length:actualLength freeWhenDone:NO];
    
    m_dict = [self decodeDictionaryWithData:inputBuffer];
    
    if (m_dict == nil) {
        m_dict = [NSMutableDictionary dictionary];
    }
    
    [self fullWriteback];
    
    return YES;
}

- (BOOL)expandMmapSizeWithRequiredSize:(uint64_t)size {
    uint64_t requiredSize = size;
    if (size < pageSize || (size % pageSize != 0)) {
        requiredSize = ((size / pageSize) + 1) * pageSize;
    }
    uint64_t expandToSize = fmax(requiredSize, m_size * 2);
    munmap(m_ptr, m_size);
    
    if (ftruncate(m_fd, expandToSize) != 0) {
        return NO;
    }
    m_size = expandToSize;
    
    m_ptr = (char *)mmap(NULL, m_size, PROT_READ | PROT_WRITE, MAP_SHARED, m_fd, 0);
    if (m_ptr == MAP_FAILED || m_ptr == NULL) {
        return NO;
    }
    
    return YES;
}

- (void)appendObject:(id)obj withKey:(id)key {
    NSArray *kvArray = @[key, obj];
    NSData *kvData = [NSKeyedArchiver archivedDataWithRootObject:kvArray];
    uint32_t kvLength = (uint32_t)kvData.length;
    
    uint64_t requiredSize = m_dataSize + kvLength + sizeof(uint32_t);
    if (requiredSize >= m_size) {
        if (![self expandMmapSizeWithRequiredSize:requiredSize]) {
            return;
        }
    }
    memcpy(m_ptr + sizeof(uint64_t) + m_dataSize, &kvLength, sizeof(uint32_t));
    memcpy(m_ptr + sizeof(uint64_t) + m_dataSize + sizeof(uint32_t), kvData.bytes, kvData.length);
    memcpy(m_ptr, &requiredSize, sizeof(uint64_t));
    m_dataSize = requiredSize;
}

- (NSMutableDictionary *)decodeDictionaryWithData:(NSData *)data {
    if (data.length <= 0) {
        return nil;
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    char *ptr = (char *)[data bytes];
    NSUInteger length = 0;
    while (length < data.length) {
        uint32_t *kvLength = (uint32_t *)ptr;
        ptr += sizeof(uint32_t);
        length += sizeof(uint32_t);
        
        NSData *kvBuffer = [NSData dataWithBytesNoCopy:ptr length:*kvLength freeWhenDone:NO];
        NSArray *kvArray = [NSKeyedUnarchiver unarchiveObjectWithData:kvBuffer];
        if (kvArray == nil || ![kvArray isKindOfClass:[NSArray class]] || kvArray.count < 2) {
            break;
        }
        id key = kvArray[0];
        id value = kvArray[1];
        [dict setObject:value forKey:key];
        
        ptr += *kvLength;
        length += *kvLength;
    }
    
    return dict;
}

- (void)fullWriteback {
    NSMutableData *data = [NSMutableData data];
    for (id key in m_dict) {
        id value = m_dict[key];
        NSArray *kvArray = @[key, value];
        NSData *kvData = [NSKeyedArchiver archivedDataWithRootObject:kvArray];
        uint32_t kvLength = (uint32_t)kvData.length;
        [data appendBytes:&kvLength length:sizeof(uint32_t)];
        [data appendData:kvData];
    }
    
    uint64_t dataLength = (uint64_t)data.length;
    if (dataLength + sizeof(uint64_t) >= m_size) {
        if (![self expandMmapSizeWithRequiredSize:dataLength + sizeof(uint64_t)]) {
            return;
        }
    }
    memcpy(m_ptr, &dataLength, sizeof(uint64_t));
    memcpy(m_ptr + sizeof(uint64_t), data.bytes, dataLength);
    m_dataSize = dataLength;
}

#pragma mark - Public APIs

- (void)setObject:(id)object forKey:(id)key {
    if (object == nil) {
        [self removeObjectForKey:key];
        return;
    }
    
    pthread_mutex_lock(&m_lock);
    if (![m_dict[key] isEqual:object]) {
        m_dict[key] = object;
        [self appendObject:object withKey:key];
    }
    pthread_mutex_unlock(&m_lock);
}

- (void)removeObjectForKey:(id)key {
    pthread_mutex_lock(&m_lock);
    [m_dict removeObjectForKey:key];
    [self fullWriteback];
    pthread_mutex_unlock(&m_lock);
}

- (id)objectForKey:(id)key {
    pthread_mutex_lock(&m_lock);
    id result = nil;
    if (m_dict[key] != nil) {
        result = m_dict[key];
    }
    pthread_mutex_unlock(&m_lock);
    return result;
}

- (void)removeAllObjects {
    pthread_mutex_lock(&m_lock);
    [m_dict removeAllObjects];
    [self fullWriteback];
    pthread_mutex_unlock(&m_lock);
}

- (NSArray<NSString *> *)allKeys {
    pthread_mutex_lock(&m_lock);
    NSArray *result = [m_dict allKeys];
    pthread_mutex_unlock(&m_lock);
    return result;
}

- (id)objectForKeyedSubscript:(id)key {
    return [self objectForKey:key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id)key {
    [self setObject:obj forKey:key];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id  _Nullable __unsafe_unretained [])buffer count:(NSUInteger)len {
    return [m_dict countByEnumeratingWithState:state objects:buffer count:len];
}

@end
