//
//  LinePlotView.m
//  HomeMonitor
//
//  Created by Paul Philippou on 7/5/16.
//  Copyright © 2016 IntelligentOhanaSolutions. All rights reserved.
//

#import "LinePlotView.h"

@interface LinePlotView() 

@property (nonatomic,strong) NSMutableDictionary* yLabels;
@property (nonatomic,strong) NSMutableArray* marginSubviews;
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
    [self drawValueLabels];
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
    }
    CGContextDrawPath(context, kCGPathStroke);
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

    for (int i=1 ; i< yv.count ; i++) {
        NSString* vs = yv[i];
        px += pdx;
        x  = [self xpt:px];
        if ([vs isKindOfClass:[NSString class]]) {
            v = [vs doubleValue];
            py = 1.0 - (v - _yMin)/rangey;
            y = [self ypt:py]; //p * h;
            CGContextAddLineToPoint(context, x, y);
            
        }
    }
    CGContextDrawPath(context, kCGPathStroke);
    
}


-(void)drawLines {
    
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

-(void)drawGrid {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (self.gridYIncrement != 0) {
        CGContextSetStrokeColorWithColor(context, [[UIColor blackColor] CGColor]);
        CGFloat dash[] = {0.0, 2.0};
        CGContextSetLineDash(context, 0.0, dash, 2);
        CGContextSetLineWidth(context, 0.5);
        
        double rangey = _yMax - _yMin;
        
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
                NSString* vStr =[NSString stringWithFormat:@"%f",v];
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
                NSString* vStr =[NSString stringWithFormat:@"%f",v];
                NSString* yStr =[NSString stringWithFormat:@"%f",y];
                [self.yLabels setObject:vStr forKey:yStr];
            }
        }
        
        
        
    }
}


@end
