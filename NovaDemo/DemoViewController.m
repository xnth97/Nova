//
//  DemoViewController.m
//  Nova
//
//  Created by Yubo Qin on 2018/1/31.
//  Copyright © 2018年 Yubo Qin. All rights reserved.
//

#import "DemoViewController.h"

@interface DemoViewController ()<NovaRootViewControllerDelegate>

@end

@implementation DemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Bootstrap Demo";
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
