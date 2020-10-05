//
//  NovaBlockHolder.m
//  Nova
//
//  Created by Yubo Qin on 2018/2/3.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import "NovaBlockHolder.h"

@interface NovaBlockHolder ()

@property (copy, nonatomic, nonnull, readonly) dispatch_block_t block;

@end

@implementation NovaBlockHolder

+ (nonnull instancetype)blockHolderWithBlock:(nonnull dispatch_block_t)block {
    NovaBlockHolder *instance = [[NovaBlockHolder alloc] initWithBlock:block];
    return instance;
}

- (nonnull instancetype)initWithBlock:(nonnull dispatch_block_t)block {
    self = [super init];
    if (self) {
        _block = block;
    }
    return self;
}

- (void)invoke {
    if (self.block) {
        self.block();
    }
}

@end
