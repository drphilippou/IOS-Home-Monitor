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
    NSTimer* checkForUpdatesTimer;

}
@property (strong,nonatomic) NSMutableDictionary* data;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *currPVLabel;
@property (weak, nonatomic) IBOutlet UILabel *dailyPVLabel;
@property (weak, nonatomic) IBOutlet UILabel *pvPredLabel;
@property (weak, nonatomic) IBOutlet UILabel *pvSurplus;
@property (weak, nonatomic) IBOutlet UILabel *homePowerLabel;
@property (weak, nonatomic) IBOutlet UILabel *zoeRoomHumidityLabel;
@property (weak, nonatomic) IBOutlet UILabel *keliiRoomHumidityLabel;
@property (weak, nonatomic) IBOutlet UILabel *dehumdifierEnergyLabel;



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
    checkForUpdatesTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(checkForUpdates) userInfo:nil repeats:YES];
    
    
    //test
    
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
    DM.newDataAvailable = true;
}


-(void)checkForUpdates {
    if (DM.newDataAvailable) {
        
        //grab the latest data
        HMData* d = [DB getLatestHMData];
        self.timeLabel.text = d.time ;
        self.dateLabel.text = d.date;
        self.currPVLabel.text = [NSString stringWithFormat:  @"Current PV Power %d wh",d.currPVPower];
        self.dailyPVLabel.text = [NSString stringWithFormat:  @"PV Daily Total %d wh",d.pvEnergyToday];
        self.pvPredLabel.text = [NSString stringWithFormat:@"PV Pred %d wh",d.pvPred];
        self.pvSurplus.text = [NSString stringWithFormat:@"PV Surplus %5.1f",d.pvSurplus];
        self.homePowerLabel.text = [NSString stringWithFormat:@"Home Power Use: %5.0f watts",d.homePower];
        self.zoeRoomHumidityLabel.text = [NSString stringWithFormat:@"Zoe Room Humidity: %d ",d.zoeRoomHumidity];
        self.keliiRoomHumidityLabel.text = [NSString stringWithFormat:@"Kelii Room Humidity: %d",d.keliiRoomHumidity];
        self.dehumdifierEnergyLabel.text = [NSString stringWithFormat:@"Dehumidifier Energy:%d wh",d.dehumidEnergy];
        
        DM.newDataAvailable = false;
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




@end
