//
//  LinePlotView.m
//  HomeMonitor
//
//  Created by Paul Philippou on 7/5/16.
//  Copyright © 2016 IntelligentOhanaSolutions. All rights reserved.
//

#import "LinePlotView.h"
#import "IOSTimeFunctions.h"

@interface LinePlotView()  {
    IOSTimeFunctions* TF;
}

@property (nonatomic,strong) NSMutableDictionary* yLabels;
@property (nonatomic,strong) NSMutableArray* marginSubviews;
@property (nonatomic,strong) NSMutableArray* xAxisLabelSubviews;
@property (nonatomic,strong) NSMutableArray* yAxisLabelSubviews;
@property (nonatomic,strong) NSMutableArray* finalYValues;
@property (nonatomic,strong) UIView* plotCanvas;

@end


@implementation LinePlotView

-(NSMutableDictionary*) yLabels {
    if (!_yLabels) {
        _yLabels = [[NSMutableDictionary alloc] init];
    }
    return _yLabels;
}

-(NSMutableArray*) marginSubviews {
    if (!_marginSubviews) {
        _marginSubviews = [[NSMutableArray alloc] init];
    }
    return _marginSubviews;
}

-(NSMutableArray*)finalYValues {
    if (!_finalYValues) {
        _finalYValues = [[NSMutableArray alloc] init];
    }
    return _finalYValues;
}


-(NSMutableArray*) yAxisLabelSubviews {
    if (!_yAxisLabelSubviews) {
        _yAxisLabelSubviews = [[NSMutableArray alloc] init];
    }
    return _yAxisLabelSubviews;
}

-(NSMutableArray*) xAxisLabelSubviews {
    if (!_xAxisLabelSubviews) {
        _xAxisLabelSubviews = [[NSMutableArray alloc] init];
    }
    return _xAxisLabelSubviews;
}


-(NSArray*)xVals {
    if (!_xVals) {
        _xVals = [[NSArray alloc] init];
    }
    return _xVals;
}
-(NSArray*)yVals {
    if (!_yVals) {
        _yVals = [[NSArray alloc] init];
    }
    return _yVals;
}
-(NSArray*)y2Vals {
    if (!_y2Vals) {
        _y2Vals = [[NSArray alloc] init];
    }
    return _y2Vals;
}

-(void)setYMinValue:(double)yMin {
    _yMin = yMin;
    self.customYMinLimits = true;
}

-(void)setYMaxValue:(double)y {
    _yMax = y;
    self.customYMaxLimits = true;
}

-(void)setXMinValue:(double)xMin {
    _xMin = xMin;
    self.customXMinLimits = true;
}

-(void)setXMaxValue:(double)x {
    _xMax = x;
    self.customXMaxLimits = true;
}


-(int)xpt:(float) px {
    int w = self.frame.size.width;
    float offset = 0.0;
    
    //reduce the width
    w -= self.leftSideMargin;
    w -= self.rightSideMargin;
    
    //shift the origin
    offset += self.leftSideMargin;
    
    return ((px * w) + offset);
}


-(int)ypt:(float) py {
    int h = self.frame.size.height;
    float offset = 0.0;
    
    //reduce the width
    h -= self.topMargin;
    h -= self.bottomMargin;
    
    //shift the origin
    offset += self.topMargin;
    
    return ((py * h) + offset);
}


//this is called when it is created programatically
-(id)initWithFrame:(CGRect)f Data:(NSArray*)data {
    self = [super initWithFrame:f];
    _yVals = [[NSArray alloc] initWithArray:data copyItems:true];
    [self baseClassInit];
    return self;
}

//this is called when it is created via a storyboard
- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self baseClassInit];
    }
    return self;
}

- (void)baseClassInit {
    //create a subview to hold the plot canvas
    //this is used so I can limit the graph lines from overflowing onto the labels
    //during pan events
    self.plotCanvas = nil;
    
    TF = [[IOSTimeFunctions alloc] init];
}


-(void)reset {
    self.customXMaxLimits = false;
    self.customXMinLimits = false;
    self.customYMaxLimits = false;
    self.customYMinLimits = false;
    self.xVals = nil;
    self.yVals = nil;
    self.y2Vals = nil;
    self.marginValues = nil;
    self.showValues = false;
    self.yLabels = nil;
}


- (void)drawRect:(CGRect)rect {
    
    //delete old labels
    [self.plotCanvas removeFromSuperview];
    for (UIView* sv in self.marginSubviews) {
        [sv removeFromSuperview];
    }
    [self.marginSubviews removeAllObjects];
    
    
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    self.ctx = context;
    
    //get the bounds
    CGRect f = self.frame;
    float w = f.size.width;
    float h = f.size.height;
    
    if (w<10 || h<10) {
        return;
    }
    
    //draw the layers in the right order
    //[self createPlotCanvas];
    [self setXMaxAndXMin];
    [self setYMaxAndYMin];
    [self drawLines];
    [self drawAxis];
    [self drawGrid];
    [self drawXGrid];
    [self drawValueLabels];
    [self drawYAxisValues];
}


-(void)createPlotCanvas {
    CGRect pcf = CGRectMake([self xpt:0.0],
                           [self ypt:0.0],
                           [self xpt:1.0] - [self xpt:0.0],
                           [self ypt:1.0] - [self ypt:0.0]);
    UIView* pcv = [[UIView alloc] initWithFrame:pcf];
    pcv.backgroundColor = [UIColor greenColor];
    self.plotCanvas = pcv;
    [self addSubview:pcv];
}


-(void) drawAxis {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, [[UIColor blackColor] CGColor]);
    CGContextSetLineWidth(context,2);
    
    double rangey = _yMax - _yMin;
    double rangex = _xMax - _xMin;
    
    double vy = 0;
    double vx = 0;
    if (_xMin >0) vx = _xMin;
    if (_yMin >0) vy = _yMin;
    
    double px = (vx - _xMin)/rangex;
    double py = 1.0 - (vy - _yMin)/rangey;
    
    //determine the coordinates of the axis
    double x = [self xpt:px];
    double y = [self ypt:py];
    
    //draw x axis
    CGContextMoveToPoint(context,   x,[self ypt:0]);
    CGContextAddLineToPoint(context,x,[self ypt:1]);
    
    //draw y axis
    CGContextMoveToPoint(context,   [self xpt:0],y);
    CGContextAddLineToPoint(context,[self xpt:1],y);
    CGContextDrawPath(context, kCGPathStroke);
}


-(void)drawValueLabels {
    
    self.autoLabelYValues = TRUE;

    if (self.autoLabelYValues) {
        for (NSDictionary* d in self.finalYValues) {
            
            
            //format the text
            double value = [d[@"value"] doubleValue];
            NSString* s;
            if (floor(value) == value) {
                s = [NSString stringWithFormat:@"%d", (int) value];
            } else {
                s = [NSString stringWithFormat:@"%.1f",value];
            }
                
            
            double h =20;
            
            UILabel* l = [[UILabel alloc] initWithFrame:CGRectMake([self xpt:1.0]+2,
                                                                   [d[@"posint"] intValue]- h/2,
                                                                   self.rightSideMargin,h)];
            l.adjustsFontSizeToFitWidth = true;
            l.textColor = d[@"color"];
            l.text = s;
            [self addSubview:l];
            [self.marginSubviews addObject:l];
        }
        
    } else {
        
        if (self.showValues && self.rightSideMargin >5) {
            for (NSString* key in self.marginValues) {
                NSDictionary* entry = [self.marginValues objectForKey:key];
                double p = [entry[@"position"] doubleValue];
                double x = [self xpt:1.0];
                double y = [self ypt:p];
                int h = [entry[@"height"] intValue];
                
                
                UILabel* l = [[UILabel alloc] initWithFrame:CGRectMake(x, y, self.rightSideMargin, h)];
                l.adjustsFontSizeToFitWidth = true;
                l.textColor = entry[@"color"];
                l.text = entry[@"value"];
                [self addSubview:l];
                [self.marginSubviews addObject:l];
                
            }
        }
    }
}

-(void) drawYAxisValues {
    
    //delete old labels
    NSLog(@"views count %lu",(unsigned long)self.yAxisLabelSubviews.count);
    for (UILabel* sv in self.yAxisLabelSubviews) {
        [sv removeFromSuperview];
    }
    [self.yAxisLabelSubviews removeAllObjects];
    
    
    if (self.showYAxisValues) {
        for (NSString* key in self.yLabels) {
            NSString* entry = [self.yLabels objectForKey:key];
            
            double x = 0;
            double y = [key doubleValue] - 10;

            int h = 20;
            
            
            UILabel* l = [[UILabel alloc] initWithFrame:CGRectMake(x, y, self.leftSideMargin-5, h)];
            l.adjustsFontSizeToFitWidth = true;
            l.textColor = [UIColor blackColor];
            l.text = entry;
            [self addSubview:l];
            [[self yAxisLabelSubviews] addObject:l];
        }
    }
}

-(void)scatterPlotXV:(NSArray*)xv YV:(NSArray*) yv Color:(UIColor*)color {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    double rangex = _xMax - _xMin;
    double rangey = _yMax - _yMin;
    
    CGContextSetStrokeColorWithColor(context, [color CGColor]);
    CGContextSetLineWidth(context, 1.0);
    
    //scatter plot
    NSString* vsx = [xv firstObject];
    NSString* vsy = [yv firstObject];
    double vx = [vsx doubleValue];
    double vy = [vsy doubleValue];
    
    double px = (vx - _xMin)/rangex;
    double py = 1.0 - (vy - _yMin)/rangey;
    
    double x = [self xpt:px];
    double y = [self ypt:py];
    CGContextMoveToPoint(context, x,y);
    
    //record the final value so we know where to hang the value labels
    int finalYPos = (int) y;
    double finalYVal = vy;
    
    for (unsigned long i= 1 ; i<yv.count ; i++) {
        vsx = xv[i];
        vsy = yv[i];
        vx = [vsx doubleValue];
        vy = [vsy doubleValue];
        
        px = (vx - _xMin)/rangex;
        py = 1.0 - (vy - _yMin)/rangey;
        
        x = [self xpt:px];
        y = [self ypt:py];
        CGContextAddLineToPoint(context, x, y);
        finalYPos = (int) y;
        finalYVal = vy;
        
        
    }
    CGContextDrawPath(context, kCGPathStroke);
    
    //add an entry so we can label the final value automatically
    [self.finalYValues addObject:@{@"posint":[NSNumber numberWithInteger:finalYPos],
                                   @"color":color,
                                   @"value":[NSNumber numberWithDouble:finalYVal]}];
    
}

-(void)linePlot:(NSArray*)yv Color:(UIColor*)color {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    unsigned long n = yv.count;
    double rangey = _yMax - _yMin;
    
    //set the starting point
    //double dx = w/(1.0*(n-1));
    double pdx = 1.0/(1.0*(n-1));
    double v = [[yv firstObject] doubleValue];
    
    double px = 0;
    double py = 1.0 - (v - _yMin)/rangey;

    int x = [self xpt:px]; //0;
    int y = [self ypt:py]; //p * h;
    CGContextSetStrokeColorWithColor(context, [color CGColor]);
    CGContextSetLineWidth(context, 1.0);
    CGContextMoveToPoint(context, x, y);
    
    //record the final value so we know where to hang the value labels
    int finalYPos = y;
    double finalYVal = v;
    
    for (int i=1 ; i< yv.count ; i++) {
        NSString* vs = yv[i];
        px += pdx;
        x  = [self xpt:px];
        if ([vs isKindOfClass:[NSString class]]) {
            v = [vs doubleValue];
            py = 1.0 - (v - _yMin)/rangey;
            y = [self ypt:py]; //p * h;
            CGContextAddLineToPoint(context, x, y);
    
            finalYPos = y;
            finalYVal = v;
            
        }
    }
    CGContextDrawPath(context, kCGPathStroke);
    [self.finalYValues addObject:@{@"posint":[NSNumber numberWithInteger:finalYPos],
                                   @"color":color,
                                   @"value":[NSNumber numberWithDouble:finalYVal]}];

}


-(void)drawLines {
    
    //erase any of the final values
    [self.finalYValues removeAllObjects];
    
    if (self.xVals.count < self.yVals.count) {
        //line plot
        if (self.y2Vals.count==0) {
            [self linePlot:self.yVals Color:[UIColor redColor]];
        } else {
            [self linePlot:self.yVals Color:[UIColor redColor]];
            [self linePlot:self.y2Vals Color:[UIColor blueColor]];
        }

    } else {
        //scatter plot
        if (self.y2Vals.count == 0) {
            [self scatterPlotXV:self.xVals
                             YV:self.yVals
                          Color:[UIColor redColor]];
        } else {
            [self scatterPlotXV:self.xVals
                             YV:self.yVals
                          Color:[UIColor redColor]];
            [self scatterPlotXV:self.xVals
                             YV:self.y2Vals
                          Color:[UIColor blueColor]];
            
        }
    }
}


-(void)setXMaxAndXMin {
    if (self.xVals.count >0 ) {
        
        if (!self.customXMinLimits)
            self.xMin = [[self.xVals firstObject] floatValue];
        if (!self.customXMaxLimits)
            self.xMax = [[self.xVals firstObject] floatValue];
        
        for (NSString* vs in _xVals) {
            if ([vs isKindOfClass:[NSString class]]) {
                double v = [vs doubleValue];
                if (v<self.xMin && !self.customXMinLimits) self.xMin = v;
                if (v>self.xMax && !self.customXMaxLimits) self.xMax = v;
            }
        }
    } else {
        if (!self.customXMinLimits) self.xMin = 0;
        if (!self.customXMaxLimits) self.xMax = 1.0;
    }
}



-(void)setYMaxAndYMin {
    if (self.yVals.count >0 ) {
        
        if (!self.customYMinLimits)
            self.yMin = [[self.yVals firstObject] floatValue];
        if (!self.customYMaxLimits)
            self.yMax = [[self.yVals firstObject] floatValue];
        
        for (NSString* vs in _yVals) {
            if ([vs isKindOfClass:[NSString class]]) {
                double v = [vs doubleValue];
                if (v<self.yMin && !self.customYMinLimits) self.yMin = v;
                if (v>self.yMax && !self.customYMaxLimits) self.yMax = v;
            }
        }
        //if there are two plots then set the bounds for both
        if (self.y2Vals.count>0) {
            for (NSString* vs in _y2Vals) {
                if ([vs isKindOfClass:[NSString class]]) {
                    double v = [vs doubleValue];
                    if (v<self.yMin && !self.customYMinLimits) self.yMin = v;
                    if (v>self.yMax && !self.customYMaxLimits) self.yMax = v;
                }
            }
        }
        
    } else {
        if (!self.customYMinLimits) self.yMin = 0;
        if (!self.customYMaxLimits) self.yMax = 1.0;
    }
    
}


-(void)drawXGrid {
    for (UIView* uiv in self.xAxisLabelSubviews) {
        [uiv removeFromSuperview];
    }
    [self.xAxisLabelSubviews removeAllObjects];
    
        CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (self.gridYIncrement != 0) {
        CGContextSetStrokeColorWithColor(context, [[UIColor blackColor] CGColor]);
        CGFloat dash[] = {0.0, 2.0};
        CGContextSetLineDash(context, 0.0, dash, 2);
        CGContextSetLineWidth(context, 0.5);
        
        NSArray* timeLimits = @[[NSNumber numberWithDouble:60.0],
                                [NSNumber numberWithDouble:300.0],
                                [NSNumber numberWithDouble:600.0],
                                [NSNumber numberWithDouble:15.0*60.0],
                                [NSNumber numberWithDouble:3600.0],
                                [NSNumber numberWithDouble:2.0*3600.0],
                                [NSNumber numberWithDouble:4.0*3600.0],
                                [NSNumber numberWithDouble:6.0*3600.0],
                                [NSNumber numberWithDouble:12.0*3600.0],
                                [NSNumber numberWithDouble:86400.0],
                                [NSNumber numberWithDouble:2.0*86400.0],
                                [NSNumber numberWithDouble:4.0*86400.0],
                                [NSNumber numberWithDouble:7.0*86400.0]];
        
        
        NSArray* timeFormats = @[@"HH:mm", @"HH:mm", @"HH:mm",@"HH:mm", @"ha", @"ha",   @"ha",   @"ha",   @"ha",   @"MM/dd",   @"MM/dd",   @"MM/dd",   @"MM/dd"];
        
        
        double rangex = _xMax - _xMin;
        
        //determine the number of grids at each time scale
        NSMutableArray* numGrids = [[NSMutableArray alloc] init];
        for (NSNumber *tl in timeLimits) {
            double ng = rangex/[tl doubleValue];
            [numGrids addObject:[NSNumber numberWithDouble:ng]];
        }
        
        //determine the optimal time scale
        int indx = 0;
        for (NSNumber* ng in numGrids) {
            if ([ng doubleValue] <8 ) {
                indx = (int) [numGrids indexOfObject:ng];
                break;
            }
        }
        double gridXIncrement = [timeLimits[indx] doubleValue];
        NSLog(@"best index %d with ng %f",indx,[numGrids[indx] doubleValue]);
    
        //get an epoch date for starting the increment
        NSDateFormatter *parsingFormatter = [NSDateFormatter new];
        [parsingFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZ"];
        NSDate *date = [parsingFormatter dateFromString:@"2016-01-01T00:00:00-10:00"];
        NSTimeInterval startTimeJanFirst = [date timeIntervalSince1970];
        
        
        NSLog(@"final grid increment = %f", gridXIncrement);
        for (double v=startTimeJanFirst ; v<self.xMax;  v += gridXIncrement) {
            if (v>self.xMin) {
                double p = (v - _xMin)/rangex;
                double x = [self xpt:p];
                double ymin = [self ypt:0];
                double ymax = [self ypt:1];
                CGContextMoveToPoint(context, x, ymin);
                CGContextAddLineToPoint(context, x, ymax);
                CGContextDrawPath(context, kCGPathStroke);
                
                NSDate *epochNSDate = [[NSDate alloc] initWithTimeIntervalSince1970:v];
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                //[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
                NSString* dst = [timeFormats objectAtIndex:indx];
                [dateFormatter setDateFormat:dst];
                NSTimeZone* TZ = [NSTimeZone timeZoneWithName:@"HST"];
                [dateFormatter setTimeZone:TZ];
                NSString* datestr =[dateFormatter stringFromDate:epochNSDate];
                NSLog (@"Epoch time %f equates to %@", v, datestr );

                
                
                //double x = 0;
                //double y = [key doubleValue] - 10;
                
                int h = 20;
                
                
                UILabel* l = [[UILabel alloc] initWithFrame:CGRectMake(x-15, ymax, 30, self.bottomMargin)];
                l.adjustsFontSizeToFitWidth = true;
                l.textColor = [UIColor blackColor];
                l.text = datestr;
                [self addSubview:l];
                [self.xAxisLabelSubviews addObject:l];

//                //reord the values for labels
//                NSString* vStr;
//                if (floor(v)==v) {
//                    vStr = [NSString stringWithFormat:@"%d",(int) v];
//                } else {
//                    vStr = [NSString stringWithFormat:@"%.1f", v];
//                }
//                NSString* yStr =[NSString stringWithFormat:@"%f",y];
//                [self.yLabels setObject:vStr forKey:yStr];
            }
        }
    }
}

-(void)drawGrid {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (self.gridYIncrement != 0) {
        CGContextSetStrokeColorWithColor(context, [[UIColor blackColor] CGColor]);
        CGFloat dash[] = {0.0, 2.0};
        CGContextSetLineDash(context, 0.0, dash, 2);
        CGContextSetLineWidth(context, 0.5);
        
        double rangey = _yMax - _yMin;
        int exponent = (int) log10(rangey);       // See comment below.
        double magnitude = pow(10, exponent);
        //NSLog(@"original values r=%f e=%d m=%d",rangey,exponent,magnitude);
        
        double ng = rangey/magnitude;
        double multi = 1;
        //NSLog(@"original ngrids = %f", ng);
        if (ng < 4 ) {
            ng  = rangey/(magnitude/2);
            multi = 2;
            //NSLog(@"   -multi %f ngrids = %f",multi, ng);
            if (ng <4 ) {
                ng = rangey/(magnitude/4);
                multi = 4;
                //NSLog(@"   -multi %f ngrids = %f",multi, ng);
                if (ng <4 ) {
                    ng = rangey/(magnitude/5);
                    multi = 5;
                    //NSLog(@"   -multi %f ngrids = %f",multi, ng);
                }
            }
        } else if ( ng>8 ){
            ng  = rangey/(magnitude*2);
            multi = 1.0/2.0;
            //NSLog(@"   +multi %f ngrids = %f",multi, ng);
            if (ng >8 ) {
                ng = rangey/(magnitude*4);
                multi = 1.0/4.0;
                //NSLog(@"   +multi %f ngrids = %f",multi, ng);
                if (ng >8 ) {
                    ng = rangey/(magnitude*5);
                    multi = 1.0/5.0;
                    //NSLog(@"   +multi %f ngrids = %f",multi, ng);
                }
            }
        }
        self.gridYIncrement = magnitude/multi;
        if (self.gridYIncrement == 0 ) {
            NSLog(@"error grid y increment was %f",self.gridYIncrement);
            self.gridYIncrement = 1.0;
        }
        
        [self.yLabels removeAllObjects];
        for (double v=0 ; v<self.yMax;  v += self.gridYIncrement) {
            if (v>self.yMin) {
                double p = 1.0 - (v - _yMin)/rangey;
                double y = [self ypt:p];
                double xmin = [self xpt:0];
                double xmax = [self xpt:1];
                CGContextMoveToPoint(context, xmin, y);
                CGContextAddLineToPoint(context, xmax, y);
                CGContextDrawPath(context, kCGPathStroke);
                
                //reord the values for labels
                NSString* vStr;
                if (floor(v)==v) {
                    vStr = [NSString stringWithFormat:@"%d",(int) v];
                } else {
                    vStr = [NSString stringWithFormat:@"%.1f", v];
                }
                NSString* yStr =[NSString stringWithFormat:@"%f",y];
                [self.yLabels setObject:vStr forKey:yStr];
            }
        }
        for (double v=0 ; v>self.yMin;  v -= self.gridYIncrement) {
            if (v<self.yMax) {
                double p = 1.0 - (v - _yMin)/rangey;
                double y = [self ypt:p];
                double xmin = [self xpt:0];
                double xmax = [self xpt:1];
                CGContextMoveToPoint(context, xmin, y);
                CGContextAddLineToPoint(context, xmax, y);
                CGContextDrawPath(context, kCGPathStroke);
                
                //reord the values for labels
                NSString* vStr;
                if (floor(v)==v) {
                    vStr = [NSString stringWithFormat:@"%d",(int) v];
                } else {
                    vStr = [NSString stringWithFormat:@"%.1f", v];
                }
                NSString* yStr =[NSString stringWithFormat:@"%f",y];
                [self.yLabels setObject:vStr forKey:yStr];
            }
        }
        
        
        
    }
}


@end
