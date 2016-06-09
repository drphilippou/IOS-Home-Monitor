//
//  ViewController.m
//  HomeMonitor
//
//  Created by Paul Philippou on 6/7/16.
//  Copyright (c) 2016 IntelligentOhanaSolutions. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
 
    NSTimer* accessWebsiteTimer;
}
@property (strong,nonatomic) NSMutableDictionary* data;


@end





@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //test the version control
    
    //start the timers
    if (accessWebsiteTimer==nil) {
        accessWebsiteTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(accessWebsite) userInfo:nil repeats:YES];
    }
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)accessWebsite
{
    NSLog(@"accessing the website");
}

@end
