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
#import <math.h>

@interface singleGraphVC () {
    
    IOSTimeFunctions* TF;
    HMdataStore* DB;
}
@property (weak, nonatomic) IBOutlet LinePlotView *plot;
@property (nonatomic,strong) NSString* fieldName;

- (IBAction)pinchAction:(UIPinchGestureRecognizer *)sender;
- (IBAction)panAction:(UIPanGestureRecognizer *)sender;

@end

@implementation singleGraphVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.secs = [NSNumber numberWithFloat:86400.0];
    
    //init variables
    TF = [[IOSTimeFunctions alloc] init];
    DB = [HMdataStore defaultStore];
    
    //start sending orientation notifications
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    //redraw the view on rotation rather then scale
    self.view.contentMode = UIViewContentModeRedraw;
}


-(void)viewWillAppear:(BOOL)animated {
  
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged)    name:UIDeviceOrientationDidChangeNotification  object:nil];
    
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


-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (IBAction)pinchAction:(UIPinchGestureRecognizer *)sender {
    
    //determine if the pinch is along the x or y axis
    //we ignore pinchs that are diagonal
    PinchAxis pa = pinchGestureRecognizerAxis(sender);
    if (pa == PinchAxisHorizontal) {
        
        //adjust the time scale
        NSLog(@"x pinch %f",sender.scale);
        double os = [self.secs doubleValue];
        double ns = os/sender.scale;
        double dt = (ns-os);
        self.secs = [NSNumber numberWithDouble:ns];
        
        //adjust the xmin and xmax
        double xmax = self.plot.xMax;
        double xmin = self.plot.xMin;
        [self.plot setXMaxValue:xmax+(dt/2)];
        [self.plot setXMinValue:xmin-(dt/2)];
        
    } else if (pa == PinchAxisVertical) {
        //adjust the y scale
        
        //adjust the maximum and minimum value
        double ymax = self.plot.yMax;
        double ymin = self.plot.yMin;
        NSLog(@"y pinch %f %f %f",sender.scale,ymax,ymin);
        ymax /= sender.scale;
        if (ymin != 0) {
            //only scale the max
            ymin *= sender.scale;
        }
        if (ymax>ymin) {
            [self.plot setYMaxValue:ymax];
            [self.plot setYMinValue:ymin];
        } else {
            [self.plot setYMaxValue:ymin];
            [self.plot setYMinValue:ymax];
            
        }
    }
    //redraw the plot
    [self updatePlot];
    [self.plot setNeedsDisplay];
    
    //reset the scale back to 1.0 so we can get cumalative
    [sender setScale:1.0];
    

}

- (IBAction)panAction:(UIPanGestureRecognizer *)sender {
    CGPoint p = [sender translationInView:self.view];
    float fx = fabsf((float) p.x);
    float fy = fabsf((float) p.y);
    if (fx>10 || fy>10 ) {
        if (fx>fy) {
            NSLog(@"x pan action %f %f",p.x,p.y);
            float xmax = self.plot.xMax;
            float xmin = self.plot.xMin;
            float xrange = fabsf(xmax-xmin);
            float pc = p.x / self.plot.frame.size.width;
            xmax -=  xrange*pc;
            xmin -=  xrange*pc;
            [self.plot setXMaxValue:xmax];
            [self.plot setXMinValue:xmin];
            
        } else {
            NSLog(@"y pan action %f %f",p.x,p.y);
            float ymax = self.plot.yMax;
            float ymin = self.plot.yMin;
            float yrange = fabsf(ymax-ymin);
            float pc = p.y / self.plot.frame.size.height;
            ymax +=  yrange*pc;
            ymin +=  yrange*pc;
            [self.plot setYMaxValue:ymax];
            [self.plot setYMinValue:ymin];
            
        }
        [self updatePlot];
        [self.plot setNeedsDisplay];
        [sender setTranslation:CGPointZero inView:self.view];
    }
}

PinchAxis pinchGestureRecognizerAxis(UIPinchGestureRecognizer *r) {
    if (r.numberOfTouches == 2) {
        UIView *view = r.view;
        CGPoint touch0 = [r locationOfTouch:0 inView:view];
        CGPoint touch1 = [r locationOfTouch:1 inView:view];
        float arg = (touch1.y - touch0.y) / (touch1.x - touch0.x);
        CGFloat tangent = fabsf(arg);
        return
        tangent <= 0.2679491924f ? PinchAxisHorizontal // 15 degrees
        : tangent >= 3.7320508076f ? PinchAxisVertical   // 75 degrees
        : PinchAxisNone;
        
    } else {
        return PinchAxisNone;
    }
}


-(void)orientationChanged {
    NSLog(@"orientation changed");
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    switch (orientation)
    {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
        {
            //load the portrait view
        }
            
            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
        {
            //load the landscape view
        }
            break;
        case UIInterfaceOrientationUnknown:break;
    }
    
    [self updatePlot];
    [self.plot setNeedsDisplay];
}


-(void)updatePlot {
    HMData* d = [DB getLatestHMData];
    NSTimeInterval ls = d.secs;
    double secs = [self.secs doubleValue];
    
    //check to see if we have custom x bounds
    NSArray* yv;
    NSArray* xv;
    if (self.plot.customXMaxLimits || self.plot.customXMinLimits) {
        //extract the data in defined interval from [begin to end]
        yv = [DB getFieldAsString:self.fieldName
                          fromSec:self.plot.xMin
                            toSec:self.plot.xMax];
        xv = [DB getFieldAsString:@"secs"
                          fromSec:self.plot.xMin
                            toSec:self.plot.xMax];
        
    } else {
        //extract the data in interval since last value
        yv = [DB getFieldAsString:self.fieldName sinceSec:ls-secs];
        xv = [DB getFieldAsString:@"secs" sinceSec:ls-secs];
        
    }
    
    
    self.plot.xVals = xv;
    self.plot.yVals = yv;
    self.plot.backgroundColor = [UIColor lightGrayColor];
    self.plot.showYAxisValues = TRUE;
    
    if (xv.count >0) {
        //plot the values in the margin
        self.plot.leftSideMargin = 30;
        self.plot.topMargin = 10;
        self.plot.bottomMargin = 20;
        self.plot.rightSideMargin = 50;
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
