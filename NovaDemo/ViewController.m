//
//  ViewController.m
//  Nova
//
//  Created by Yubo Qin on 2018/1/31.
//  Copyright © 2018年 Yubo Qin. All rights reserved.
//

#import "ViewController.h"
#import "DemoViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Nova Demo";
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showContainerWithSender:(NSObject *)sender {
    DemoViewController *vc = [[DemoViewController alloc] init];
    [self.navigationController showViewController:vc sender:nil];
}


@end
