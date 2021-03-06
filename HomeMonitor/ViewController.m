//
//  ViewController.m
//  HomeMonitor
//
//  Created by Paul Philippou on 6/7/16.
//  Copyright (c) 2016 IntelligentOhanaSolutions. All rights reserved.
//

#import "ViewController.h"
#import "IOSTimeFunctions.h"
#import "HMDownloadManager.h"
#import "HMdataStore.h"

@interface ViewController ()
{


    IOSTimeFunctions* TF;
    HMDownloadManager* DM;
    HMdataStore* DB;

}
@property (strong,nonatomic) NSMutableDictionary* data;



@end





@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //test the version control
    
    //init variables

    TF = [[IOSTimeFunctions alloc] init];
    DM = [[HMDownloadManager alloc] init];
    DB = [[HMdataStore alloc] init];
    
    
    //do we need to load any File History?
    NSTimeInterval now = [TF currentTimeSec];
    NSTimeInterval lastRxSecs = DB.HMMetadataVal.lastEntrySecs;
    NSLog(@"last RX SECs= %f",lastRxSecs);
    if ((now - lastRxSecs)>3000) {
        //start downloading history
        [DM startDownloadingHistory];
    } else {
        //start the incremental download
        [DM startDownloadingLatest];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




@end
