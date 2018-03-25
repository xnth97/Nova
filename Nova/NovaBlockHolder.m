//
//  NovaBlockHolder.m
//  Nova
//
//  Created by Yubo Qin on 2018/2/3.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import "NovaBlockHolder.h"

@interface NovaBlockHolder ()

@property (copy, nonatomic, readonly) dispatch_block_t block;

@end

@implementation NovaBlockHolder

+ (id)blockHolderWithBlock:(dispatch_block_t)block {
    NovaBlockHolder *instance = [[self alloc] initWithBlock:block];
    return instance;
}

- (id)initWithBlock:(dispatch_block_t)block {
    self = [super init];
    if (self) {
        _block = block;
    }
    return self;
}

- (void)invoke {
    self.block();
}

@end
