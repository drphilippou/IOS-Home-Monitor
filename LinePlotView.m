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

-(id)initWithFrame:(CGRect)f Data:(NSArray*)data {
    self = [super initWithFrame:f];
    _xVals = [[NSArray alloc] initWithArray:data copyItems:true];
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
    [self drawLines];
    [self drawGrid];
}


-(void)drawLines {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //get the bounds
    CGRect f = self.frame;
    float w = f.size.width;
    float h = f.size.height;
    unsigned long n = _xVals.count;
    
    double range = _xMax - _xMin;
    
    double dx = w/(1.0*(n-1));
    double x = 0;
    double v = [[_xVals firstObject] doubleValue];
    double p = 1.0 - (v - _xMin)/range;
    int y = p * h;
    
    CGContextSetStrokeColorWithColor(context, [[UIColor redColor] CGColor]);
    CGContextSetLineWidth(context, 1.0);
    CGContextMoveToPoint(context, x, y);
    
    for (int i=1 ; i< _xVals.count ; i++) {
        NSString* vs = _xVals[i];
        x += dx;
        if ([vs isKindOfClass:[NSString class]]) {
            v = [vs doubleValue];
            p = 1.0 - (v - _xMin)/range;
            y = p * h;
            CGContextAddLineToPoint(context, x, y);
            
        }
    }
    CGContextDrawPath(context, kCGPathStroke);
    
    

    
}

-(void)setXMaxAndXMin {
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

-(void)drawGrid {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //get the bounds
    CGRect f = self.frame;
    float w = f.size.width;
    float h = f.size.height;
    
    CGContextSetStrokeColorWithColor(context, [[UIColor blackColor] CGColor]);
    CGFloat dash[] = {0.0, 2.0};
    CGContextSetLineDash(context, 0.0, dash, 2);
    CGContextSetLineWidth(context, 0.5);
    
    for (float hh = 0 ; hh< h ; hh+= h/3.0) {
        CGContextMoveToPoint(context, 0, hh);
        CGContextAddLineToPoint(context, w, hh);
        CGContextDrawPath(context, kCGPathStroke);
    }
}


@end
