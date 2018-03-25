//
//  NovaUI.h
//  Nova
//
//  UI message handler of Nova. Handles 'ui' messages.
//
//  Created by Yubo Qin on 2018/2/1.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface NovaUI : NSObject <WKScriptMessageHandler>

+ (instancetype)sharedInstance;

@end
