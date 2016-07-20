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
#import "LinePlotView.h"

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

//@property (strong, nonatomic) LinePlotView* lpv;
@property (weak, nonatomic) IBOutlet LinePlotView *lpv;
- (IBAction)reloadHistoryPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *reloadHistoryButton;
- (IBAction)timeSliderChanged:(id)sender;
@property (weak, nonatomic) IBOutlet UISlider *TimeSlider;
- (IBAction)timeSliderEditDone:(id)sender;
- (IBAction)GraphTypeChanged:(id)sender;
@property (weak, nonatomic) IBOutlet UISegmentedControl *GraphType;



@end





@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //test the version control
    
    //init variables

    TF = [[IOSTimeFunctions alloc] init];
    DM = [[HMDownloadManager alloc] init];
    DB = [HMdataStore defaultStore];
    checkForUpdatesTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(checkForUpdates) userInfo:nil repeats:YES];
    
    
    //do we need to load any File History?
    NSTimeInterval now = [TF currentTimeSec];
    NSTimeInterval lastRxSecs = DB.HMMetadataVal.lastEntrySecs;
    NSLog(@"last RX time= %@",[TF localTimehhmmssa:lastRxSecs]);
    //if ((now - lastRxSecs)>3000) {
        //start downloading history
        [DM startDownloadingLatest];
        [DM startDownloadingHistory];
    //} else {
        //start the incremental download
      //  [DM startDownloadingLatest];
        //[DM startDownloadingHistory];
    //}
    DM.newDataAvailable = true;
    
    //set the graphics
    //self.reloadHistoryButton.backgroundColor = [UIColor lightGrayColor];
    
    //test graph
    //CGRect r = CGRectMake(10, 500, 350, 150);
    //self.lpv = [[LinePlotView alloc] initWithFrame:r ];
    //[self.view addSubview:self.lpv];
    
}




-(void)checkForUpdates {
    if (DM.downloading) {
        [self.reloadHistoryButton setTitle:DM.activityStr forState:UIControlStateNormal];
    } else {
        [self.reloadHistoryButton setTitle:@"Reload History" forState:UIControlStateNormal];
    }
    
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
        
        //test getting data
        //NSTimeInterval s = d.secs;
        
        //update the graph
        if (!DM.parsing) {
            NSLog(@"updating graph");
            
            
            //NSArray* yv = [DB getFieldAsString:@"pvSurplus" sinceSec:s-86400];
            self.lpv.topMargin = 40;
            self.lpv.bottomMargin = 10;
            self.lpv.leftSideMargin = 40;
            self.lpv.rightSideMargin = 10;
            if (self.GraphType.selectedSegmentIndex ==0) {
                [self plotZoeVsKeliiHumidity:self.TimeSlider.value];
            } else if (self.GraphType.selectedSegmentIndex ==1) {
                [self plotHomeEnergyVsPVPower:self.TimeSlider.value];
            } else {
                [self plotSurplus:self.TimeSlider.value];
            }
        }

    }
}

-(void)plotSurplus:(int)secs {
    HMData* d = [DB getLatestHMData];
    NSTimeInterval ls = d.secs;
    
    self.lpv.gridYIncrement = 10;
    
    //extract the data
    NSArray* yv = [DB getFieldAsString:@"pvSurplus" sinceSec:ls-secs];
    NSArray* xv = [DB getFieldAsString:@"secs" sinceSec:ls-secs];
    
    self.lpv.xVals = xv;
    self.lpv.yVals = yv;
    self.lpv.backgroundColor = [UIColor lightGrayColor];
    [self.lpv setNeedsDisplay];
}

-(void)plotZoeVsKeliiHumidity:(int) secs {
    HMData* d = [DB getLatestHMData];
    NSTimeInterval ls = d.secs;
    
    self.lpv.gridYIncrement = 1;
    
    //extract the data
    NSArray* yv = [DB getFieldAsString:@"ZoeRoomHumidity" sinceSec:ls-secs];
    NSArray* y2v = [DB getFieldAsString:@"KeliiRoomHumidity" sinceSec:ls-secs];
    NSArray* xv = [DB getFieldAsString:@"secs" sinceSec:ls-secs];
    
    self.lpv.xVals = xv;
    self.lpv.yVals = yv;
    self.lpv.y2Vals = y2v;
    self.lpv.backgroundColor = [UIColor lightGrayColor];
    [self.lpv setNeedsDisplay];
}

-(void)plotHomeEnergyVsPVPower:(int)secs {
    HMData* d = [DB getLatestHMData];
    NSTimeInterval ls = d.secs;
    
    [self.lpv setYMaxValue:8000];
    [self.lpv setYMinValue:0];
    self.lpv.gridYIncrement = 1000;
    
    //extract the data
    NSArray* yv = [DB getFieldAsString:@"homePower" sinceSec:ls-secs];
    NSArray* xv = [DB getFieldAsString:@"secs" sinceSec:ls-secs];
    NSArray* y2v = [DB getFieldAsString:@"currPVPower" sinceSec:ls-secs];
    
    self.lpv.xVals = xv;
    self.lpv.yVals = yv;
    self.lpv.y2Vals = y2v;
    self.lpv.backgroundColor = [UIColor lightGrayColor];
    [self.lpv setNeedsDisplay];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    DB.HMDataArray = nil;
    // Dispose of any resources that can be recreated.
}




- (IBAction)reloadHistoryPressed:(id)sender {
    [DM startDownloadingHistory];
}
- (IBAction)timeSliderChanged:(id)sender {
    DM.newDataAvailable = true;
}
- (IBAction)timeSliderEditDone:(id)sender {
    //DM.newDataAvailable = true;
}

- (IBAction)GraphTypeChanged:(id)sender {
    [self.lpv reset];
    DM.newDataAvailable = true;
}
@end
