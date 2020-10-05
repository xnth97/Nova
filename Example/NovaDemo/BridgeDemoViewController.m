//
//  BridgeDemoViewController.m
//  Nova
//
//  Created by Yubo Qin on 2018/4/25.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import "BridgeDemoViewController.h"

@interface BridgeDemoViewController ()

@end

@implementation BridgeDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Bridge";
    self.url = @"bridge.html";
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Objective-C native method
- (NSDictionary *)getSystemInfo:(NSString *)additional {
    NSString *os = [[NSProcessInfo processInfo] operatingSystemVersionString];
    NSString *cpu = [NSString stringWithFormat:@"%lu", (unsigned long)[[NSProcessInfo processInfo] processorCount]];
    NSString *mem = [NSString stringWithFormat:@"%llu", [[NSProcessInfo processInfo] physicalMemory]];
    return @{@"os": os,
             @"cpu": cpu,
             @"mem": mem,
             @"additional": additional};
}

@end
