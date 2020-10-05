//
//  DemoViewController.m
//  Nova
//
//  Created by Yubo Qin on 2018/1/31.
//  Copyright © 2018 Yubo Qin. All rights reserved.
//

#import "DemoViewController.h"

@interface DemoViewController ()<NovaRootViewControllerDelegate>

@end

@implementation DemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Nova Demo";
    self.url = @"demo.html";
    self.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - NovaDelegate

- (void)didFinishNavigation {
    NSLog(@"Load finished.");
}

@end
