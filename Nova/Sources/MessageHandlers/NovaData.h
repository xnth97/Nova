//
//  NovaData.h
//  Nova
//
//  Data message handler, which provides basic data persistence capabiity for Nova.
//  Handles 'data' messages.
//
//  Created by Yubo Qin on 2018/3/24.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

#import "NovaRootViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NovaData : NSObject <WKScriptMessageHandler>

@property (weak, nullable, nonatomic) NovaRootViewController *selfController;

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
