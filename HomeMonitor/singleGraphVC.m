//
//  singleGraphVC.m
//  HomeMonitor
//
//  Created by Paul Philippou on 7/29/16.
//  Copyright © 2016 IntelligentOhanaSolutions. All rights reserved.
//

#import "singleGraphVC.h"
#import "LinePlotView.h"
#import "HMDataStore.h"
#import "IOSTimeFunctions.h"

@interface singleGraphVC () {
    
    IOSTimeFunctions* TF;
    HMdataStore* DB;
}
@property (weak, nonatomic) IBOutlet LinePlotView *plot;
@property (nonatomic,strong) NSString* fieldName;

@end

@implementation singleGraphVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //init variables
    TF = [[IOSTimeFunctions alloc] init];
    DB = [HMdataStore defaultStore];
}


-(void)viewWillAppear:(BOOL)animated {
    
    //define the plot basics
    self.plot.gridYIncrement = 1;
    
    
    //get the data
    if ([self.buttonTitle containsString:@"Zoe\n(RH)"]) {
        //this is zoe room humidity
        self.fieldName = @"ZoeRoomHumidity";
    } else if ([self.buttonTitle containsString:@"Kelii\n(RH)"]) {
        self.fieldName = @"keliiRoomHumidity";
        
    } else if ([self.buttonTitle containsString:@"ZDP"]) {
        self.fieldName = @"zoeDehumidPower";
        self.plot.gridYIncrement = 100;
        
    } else if ([self.buttonTitle containsString:@"KDP"]) {
        //this is home energy
        self.fieldName = @"keliiDehumidPower";
        self.plot.gridYIncrement = 100;
        
        
        
    } else if ([self.buttonTitle containsString:@"Home\n(watts)"]) {
        self.fieldName = @"homePower";
        self.plot.gridYIncrement = 1000;
        
    } else if ([self.buttonTitle containsString:@"Home\n(kwh)"]) {
        //this is home energy
        self.fieldName = @"homeEnergy";
        self.plot.gridYIncrement = 1000;
        
        
    } else if ([self.buttonTitle containsString:@"Surplus"]) {
        self.fieldName = @"pvSurplus";
        self.plot.gridYIncrement = 10;
        

    } else if ([self.buttonTitle containsString:@"Dehumid"]) {
        self.fieldName = @"dehumidEnergy";
        self.plot.gridYIncrement = 100;
        
        
        
        
        
    } else if ([self.buttonTitle containsString:@"Curr PV"]) {
        self.fieldName = @"currPVPower";
        self.plot.gridYIncrement = 1000;
        
    } else if ([self.buttonTitle containsString:@"Daily PV"]) {
        self.fieldName = @"pvEnergyToday";
        self.plot.gridYIncrement = 5000;
        
        
    } else if ([self.buttonTitle containsString:@"Pred"]) {
        self.fieldName = @"pvPred";
        self.plot.gridYIncrement = 5000;
        
    }
    
}


-(void)viewDidAppear:(BOOL)animated {
    [self updatePlot];
}

-(void)updatePlot {
    HMData* d = [DB getLatestHMData];
    NSTimeInterval ls = d.secs;
    double secs = 86400;
    
    
    //extract the data
    NSArray* yv = [DB getFieldAsString:self.fieldName sinceSec:ls-secs];
    NSArray* xv = [DB getFieldAsString:@"secs" sinceSec:ls-secs];
    
    self.plot.xVals = xv;
    self.plot.yVals = yv;
    self.plot.backgroundColor = [UIColor lightGrayColor];
    
    if (xv.count >0) {
        //plot the values in the margin
        self.plot.leftSideMargin = 20;
        self.plot.topMargin = 10;
        self.plot.bottomMargin = 10;
        self.plot.rightSideMargin = 40;
        self.plot.showValues = true;
        NSMutableDictionary* mv = [[NSMutableDictionary alloc] init];
        [mv setObject:@{@"value":[yv lastObject],
                        @"position":@"0.0",
                        @"height":[NSNumber numberWithInt:70],
                        @"color":[UIColor redColor]} forKey:@"top"];
        
        self.plot.marginValues = mv;
        
        [self.plot setNeedsDisplay];
    }
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
