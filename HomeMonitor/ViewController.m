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
- (IBAction)reloadHistoryPressed:(id)sender;
- (IBAction)timeSliderChanged:(id)sender;
- (IBAction)timeSliderEditDone:(id)sender;
- (IBAction)GraphTypeChanged:(id)sender;


@property (strong,nonatomic) NSMutableDictionary* data;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet LinePlotView *lpv;
@property (weak, nonatomic) IBOutlet UIButton *reloadHistoryButton;
@property (weak, nonatomic) IBOutlet UISlider *TimeSlider;
@property (weak, nonatomic) IBOutlet UISegmentedControl *GraphType;

@property (weak, nonatomic) IBOutlet UIButton *ZoeHumidityButton;
@property (weak, nonatomic) IBOutlet UIButton *KeliiHumidityButton;
@property (weak, nonatomic) IBOutlet UIButton *HomePowerButton;
@property (weak, nonatomic) IBOutlet UIButton *ZoeDehumidPowerButton;
@property (weak, nonatomic) IBOutlet UIButton *KeliiDehumidPowerButton;
@property (weak, nonatomic) IBOutlet UIButton *PVSurplusButton;
@property (weak, nonatomic) IBOutlet UIButton *currPVButton;
@property (weak, nonatomic) IBOutlet UIButton *dailyPVButton;
@property (weak, nonatomic) IBOutlet UIButton *predPVButton;
@property (weak, nonatomic) IBOutlet UIButton *homeEnergyButton;
@property (weak, nonatomic) IBOutlet UIButton *dehumidEnergyButton;



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
    checkForUpdatesTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                            target:self
                                                          selector:@selector(checkForUpdates)
                                                          userInfo:nil
                                                           repeats:YES];
    
}

-(void)checkLastUpdatePeriod {
    NSLog(@"check last update period");
    
    //check if we need to load any File History?
    NSTimeInterval now = [TF currentTimeSec];
    NSTimeInterval lastRxSecs = DB.HMMetadataVal.lastEntrySecs;
    NSLog(@"last RX time= %@",[TF localTimehhmmssa:lastRxSecs]);
    
    double esecs = now-lastRxSecs;
    if (esecs>3000) {
        //start downloading history
        [DM startDownloadingHistory];
    } else {
        NSLog(@"we are recent... not starting auto update");
    }
    DM.newDataAvailable = true;
    
}




-(void)viewDidAppear:(BOOL)animated {
    NSLog(@"view did appear");
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(checkLastUpdatePeriod)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    //check to see if we are recent
    [self checkLastUpdatePeriod];
    
    //download the latest
    [DM startDownloadingLatest];
    
    DM.newDataAvailable = true;
    
}

-(void )viewWillDisappear:(BOOL)animated {
    NSLog(@"view will disappear");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(UIColor*)getHumidityColor:(int) value withColDef:(NSDictionary*)colorDef{
    
    
    for (UIColor* color in colorDef) {
        NSValue* dvalue = [colorDef objectForKey:color];
        NSRange range = [dvalue rangeValue];
        if ( value >= range.location && value <= range.location+range.length-1 ) {
            return color;
        }
    }
    return [UIColor lightGrayColor];
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"singleGraph"]) {
        if ([segue.destinationViewController isKindOfClass:[singleGraphVC class]]) {
            singleGraphVC* sgvc = (singleGraphVC*) segue.destinationViewController;
            UIButton* b = (UIButton*) sender;
            sgvc.buttonTitle = b.currentTitle;
        }
    }
}


-(void)updateButton:(UIButton*)Button Title:(NSString*)title Value:(NSNumber*)value ColorDef:(NSDictionary*)colorDef{
    
    [Button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [Button setTitle:title forState:UIControlStateNormal];
    Button.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    CFNumberType numberType = CFNumberGetType((CFNumberRef)value);
    if (numberType == kCFNumberSInt32Type) {
        Button.backgroundColor = [self getHumidityColor:[value intValue] withColDef:colorDef];
    }
    
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
        
        // define the colors
        NSDictionary* humidityColors = @{[UIColor greenColor]:[NSValue valueWithRange:NSMakeRange(1, 74)],
                                         [UIColor yellowColor]:[NSValue valueWithRange:NSMakeRange(75, 1)],
                                         [UIColor redColor]:[NSValue valueWithRange:NSMakeRange(76, 100)]};
        
        NSDictionary* homePowerColors = @{[UIColor greenColor]:[NSValue valueWithRange:NSMakeRange(1, 4000)],
                                          [UIColor yellowColor]:[NSValue valueWithRange:NSMakeRange(4001, 20000)]};
        
        NSDictionary* dehumidPowerColors = @{[UIColor lightGrayColor]:[NSValue valueWithRange:NSMakeRange(0, 1)],
                                             [UIColor yellowColor]:[NSValue valueWithRange:NSMakeRange(1, 100)],
                                             [UIColor greenColor]:[NSValue valueWithRange:NSMakeRange(100, 2000)]};
        
        NSDictionary* green = @{[UIColor greenColor]:[NSValue valueWithRange:NSMakeRange(0, 200000)]};
        
        

        
        
        //update buttons
        [self updateButton:self.ZoeHumidityButton
                     Title:[NSString stringWithFormat:@"%d\nZoe\n(RH)",d.zoeRoomHumidity]
                     Value:[NSNumber numberWithInt:d.zoeRoomHumidity]
                  ColorDef:humidityColors];
        
        [self updateButton:self.KeliiHumidityButton
                     Title:[NSString stringWithFormat:@"%d\nKelii\n(RH)",d.keliiRoomHumidity]
                     Value:[NSNumber numberWithInt:d.keliiRoomHumidity]
                  ColorDef:humidityColors];
        
        int zdp = (int) d.zoeDehumidPower;
        [self updateButton:self.ZoeDehumidPowerButton
                     Title:[NSString stringWithFormat:@"%d\nZDP\n(watts)",zdp]
                     Value:[NSNumber numberWithInt:zdp]
                  ColorDef:dehumidPowerColors];
        
        int kdp = (int) d.keliiDehumidPower;
        [self updateButton:self.KeliiDehumidPowerButton
                     Title:[NSString stringWithFormat:@"%d\nKDP\n(watts)",kdp]
                     Value:[NSNumber numberWithInt:kdp]
                  ColorDef:dehumidPowerColors];
        
        int hp =  (int) d.homePower;
        [self updateButton:self.HomePowerButton
                     Title:[NSString stringWithFormat:@"%d\nHome\n(watts)",hp]
                     Value:[NSNumber numberWithInt:hp]
                  ColorDef:homePowerColors];
        
        float he = d.homeEnergy;
        [self updateButton:self.homeEnergyButton
                     Title:[NSString stringWithFormat:@"%2.1f\nHome\n(kwh)",he]
                     Value:[NSNumber numberWithInt:he]
                  ColorDef:green];
        
        float surplus = d.pvSurplus;
        [self updateButton:self.PVSurplusButton
                     Title:[NSString stringWithFormat:@"%4.1f\nSurplus\n(kwh)",surplus]
                     Value:[NSNumber numberWithInt:surplus]
                  ColorDef:green];;
        
        int de = (int) d.dehumidEnergy;
        [self updateButton:self.dehumidEnergyButton
                     Title:[NSString stringWithFormat:@"%d\nDehumid\n(wh)",de]
                     Value:[NSNumber numberWithInt:de]
                  ColorDef:green];
        
        int cp = (int) d.currPVPower;
        [self updateButton:self.currPVButton
                     Title:[NSString stringWithFormat:@"%d\nCurr PV\n(watts)",cp]
                     Value:[NSNumber numberWithInt:cp]
                  ColorDef:@{[UIColor yellowColor]:[NSValue valueWithRange:NSMakeRange(1, 2000)],
                             [UIColor greenColor]:[NSValue valueWithRange:NSMakeRange(2001, 20000)]}];
        
        int dp = (int) d.pvEnergyToday;
        [self updateButton:self.dailyPVButton
                     Title:[NSString stringWithFormat:@"%d\nDaily PV\n(wh)",dp]
                     Value:[NSNumber numberWithInt:dp]
                  ColorDef:@{[UIColor yellowColor]:[NSValue valueWithRange:NSMakeRange(1, 20000)],
                             [UIColor greenColor]:[NSValue valueWithRange:NSMakeRange(20001, 100000)]}];
        
        int ppv = (int) d.pvPred;
        [self updateButton:self.predPVButton
                     Title:[NSString stringWithFormat:@"%d\nPred\n(wh)",ppv]
                     Value:[NSNumber numberWithInt:ppv]
                  ColorDef:@{[UIColor yellowColor]:[NSValue valueWithRange:NSMakeRange(1, 20000)],
                             [UIColor greenColor]:[NSValue valueWithRange:NSMakeRange(20001, 100000)]}];
        
        
        
        DM.newDataAvailable = false;
        
        
        //update the graph
        if (!DM.parsing) {
            NSLog(@"updating graph");
            
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
    self.lpv.showValues = true;
    
    
    //plot the values in the margin
    self.lpv.rightSideMargin = 50;
    NSMutableDictionary* mv = [[NSMutableDictionary alloc] init];
    [mv setObject:@{@"value":[yv lastObject],
                    @"position":@"0",
                    @"height":[NSNumber numberWithInt:30],
                    @"color":[UIColor redColor]} forKey:@"top"];
    self.lpv.marginValues = mv;
    
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
    
    if (xv.count >0) {
        //plot the values in the margin
        self.lpv.rightSideMargin = 40;
        self.lpv.showValues = true;
        NSMutableDictionary* mv = [[NSMutableDictionary alloc] init];
        [mv setObject:@{@"value":[yv lastObject],
                        @"position":@"0.0",
                        @"height":[NSNumber numberWithInt:70],
                        @"color":[UIColor redColor]} forKey:@"top"];
        
        [mv setObject:@{@"value":[y2v lastObject],
                        @"position":@"0.25",
                        @"height":[NSNumber numberWithInt:70],
                        @"color":[UIColor blueColor]} forKey:@"mid"];
        self.lpv.marginValues = mv;
        
        [self.lpv setNeedsDisplay];
    }
}

-(void)plotHomeEnergyVsPVPower:(int)secs {
    HMData* d = [DB getLatestHMData];
    NSTimeInterval ls = d.secs;
    
    //[self.lpv setYMaxValue:8000];
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
    
    //plot the values in the margin
    self.lpv.rightSideMargin = 40;
    self.lpv.showValues = true;
    NSMutableDictionary* mv = [[NSMutableDictionary alloc] init];
    [mv setObject:@{@"value":[yv lastObject],
                    @"position":@"0.0",
                    @"height":[NSNumber numberWithInt:20],
                    @"color":[UIColor redColor]} forKey:@"top"];
    
    [mv setObject:@{@"value":[y2v lastObject],
                    @"position":@"0.25",
                    @"height":[NSNumber numberWithInt:20],
                    @"color":[UIColor blueColor]} forKey:@"mid"];
    self.lpv.marginValues = mv;
    
    
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
