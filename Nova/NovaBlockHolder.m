//
//  NovaBlockHolder.m
//  Nova
//
//  Created by Yubo Qin on 2018/2/3.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import "NovaBlockHolder.h"

@interface NovaBlockHolder ()

@property (strong, nonatomic) dispatch_block_t block;

@end

@implementation NovaBlockHolder

+ (id)blockHolderWithBlock:(dispatch_block_t)block {
    NovaBlockHolder *instance = [[self alloc] init];
    instance.block = block;
    return instance;
}

- (void)invoke {
    self.block();
}

@end
