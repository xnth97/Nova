//
//  NovaBlockHolder.h
//  Nova
//
//  A tool class that is used to hold a block so we can dynamically invoke methods that need
//  to fill target:selector: things.
//
//  Created by Yubo Qin on 2018/2/3.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NovaBlockHolder : NSObject

/**
 Initialize a block holder instance.

 @param block given block
 @return block holder instance
 */
+ (id)blockHolderWithBlock:(dispatch_block_t)block;

/**
 For `selector:` part to invoke. Simply calls the block it holds.
 */
- (void)invoke;

@end
