//
//  NovaData.h
//  Nova
//
//  Created by Yubo Qin on 2018/3/24.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface NovaData : NSObject <WKScriptMessageHandler>

+ (instancetype)sharedInstance;

@end
