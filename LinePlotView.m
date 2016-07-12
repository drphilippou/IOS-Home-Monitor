//
//  LinePlotView.m
//  HomeMonitor
//
//  Created by Paul Philippou on 7/5/16.
//  Copyright © 2016 IntelligentOhanaSolutions. All rights reserved.
//

#import "LinePlotView.h"

@implementation LinePlotView

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


-(id)initWithFrame:(CGRect)f Data:(NSArray*)data {
    self = [super initWithFrame:f];
    _yVals = [[NSArray alloc] initWithArray:data copyItems:true];
    return self;
}


- (void)drawRect:(CGRect)rect {
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
    
    
    CGContextSetStrokeColorWithColor(context, [[UIColor blackColor] CGColor]);
    CGContextSetLineWidth(context, 2.0);
    CGContextMoveToPoint(context, 1.0, 0.0);
    CGContextAddLineToPoint(context, 1.0, h-1);
    CGContextAddLineToPoint(context, w, h-1);
    CGContextDrawPath(context, kCGPathStroke);
    
    
    [self setXMaxAndXMin];
    [self setYMaxAndYMin];
    [self drawLines];
    [self drawGrid];
}


-(void)drawLines {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //get the bounds
    CGRect f = self.frame;
    float w = f.size.width;
    float h = f.size.height;
    unsigned long n = _yVals.count;
    
    double rangex = _xMax - _xMin;
    double rangey = _yMax - _yMin;
    
    double dx = w/(1.0*(n-1));
    double x = 0;
    double v = [[_yVals firstObject] doubleValue];
    double p = 1.0 - (v - _yMin)/rangey;
    int y = p * h;
    
    CGContextSetStrokeColorWithColor(context, [[UIColor redColor] CGColor]);
    CGContextSetLineWidth(context, 1.0);
    
    if (self.xVals.count < self.yVals.count) {
        //line plot
        CGContextMoveToPoint(context, x, y);
        for (int i=1 ; i< _yVals.count ; i++) {
            NSString* vs = _yVals[i];
            x += dx;
            if ([vs isKindOfClass:[NSString class]]) {
                v = [vs doubleValue];
                p = 1.0 - (v - _yMin)/rangey;
                y = p * h;
                CGContextAddLineToPoint(context, x, y);
                
            }
        }

    } else {
        //scatter plot
        NSString* vsx = [_xVals firstObject];
        NSString* vsy = [_yVals firstObject];
        double vx = [vsx doubleValue];
        double vy = [vsy doubleValue];
        
        double px = (vx - _xMin)/rangex;
        double py = 1.0 - (vy - _yMin)/rangey;
        
        double x = px*w;
        double y = py*h;
        CGContextMoveToPoint(context, x,y);
        for (unsigned long i= 1 ; i<self.yVals.count ; i++) {
            vsx = _xVals[i];
            vsy = _yVals[i];
            vx = [vsx doubleValue];
            vy = [vsy doubleValue];
            
            px = (vx - _xMin)/rangex;
            py = 1.0 - (vy - _yMin)/rangey;
            
            x = px*w;
            y = py*h;
            CGContextAddLineToPoint(context, x, y);
        }
    }
    CGContextDrawPath(context, kCGPathStroke);
    
    

    
}

-(void)setXMaxAndXMin {
    if (!self.customXLimits) {
        if (self.xVals.count >0 ) {
            self.xMin = [[self.xVals firstObject] floatValue];
            self.xMax = [[self.xVals firstObject] floatValue];
            for (NSString* vs in _xVals) {
                if ([vs isKindOfClass:[NSString class]]) {
                    double v = [vs doubleValue];
                    if (v<self.xMin) self.xMin = v;
                    if (v>self.xMax) self.xMax = v;
                }
            }
        } else {
            self.xMin = 0;
            self.xMax = 1.0;
        }
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
    
    //get the bounds
    CGRect f = self.frame;
    float w = f.size.width;
    float h = f.size.height;
    
    if (self.gridYIncrement != 0) {
        CGContextSetStrokeColorWithColor(context, [[UIColor blackColor] CGColor]);
        CGFloat dash[] = {0.0, 2.0};
        CGContextSetLineDash(context, 0.0, dash, 2);
        CGContextSetLineWidth(context, 0.5);
        
        
        //double rangex = _xMax - _xMin;
        double rangey = _yMax - _yMin;
        
        for (double v=0 ; v<self.yMax;  v += self.gridYIncrement) {
            double p = 1.0 - (v - _yMin)/rangey;
            double y = p * h;
            CGContextMoveToPoint(context, 0, y);
            CGContextAddLineToPoint(context, w, y);
            CGContextDrawPath(context, kCGPathStroke);
            
        }
    }
    
    
    //        double p = 1.0 - (v - _yMin)/rangey;
    //    int y = p * h;
//    
//    CGContextSetStrokeColorWithColor(context, [[UIColor redColor] CGColor]);
//    CGContextSetLineWidth(context, 1.0);
//    
//    if (self.xVals.count < self.yVals.count) {
//        //line plot
//        CGContextMoveToPoint(context, x, y);
//        for (int i=1 ; i< _yVals.count ; i++) {
//            NSString* vs = _yVals[i];
//            x += dx;
//            if ([vs isKindOfClass:[NSString class]]) {
//                v = [vs doubleValue];
//                CGContextAddLineToPoint(context, x, y);
//                
//            }
//        }
//        
//    
//    for (float hh = 0 ; hh< h ; hh+= h/3.0) {
//    }
//    }
}


@end
