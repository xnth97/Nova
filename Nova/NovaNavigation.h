//
//  NovaNavigator.h
//  Nova
//
//  Created by Yubo Qin on 2018/1/31.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface NovaNavigation : NSObject <WKScriptMessageHandler>

+ (instancetype)sharedInstance;

@end
