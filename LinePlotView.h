//
//  LinePlotView.h
//  HomeMonitor
//
//  Created by Paul Philippou on 7/5/16.
//  Copyright © 2016 IntelligentOhanaSolutions. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LinePlotView : UIView

@property (nonatomic)BOOL useGrid;
@property (nonatomic)double gridYIncrement;
@property (nonatomic)BOOL customXLimits;
@property (nonatomic)BOOL customYMinLimits;
@property (nonatomic)BOOL customYMaxLimits;
@property (nonatomic)CGContextRef ctx;
@property (nonatomic,copy) NSArray* xVals;
@property (nonatomic,copy) NSArray* yVals;
@property (nonatomic,copy) NSArray* y2Vals;  //not used yet
@property (nonatomic)double xMin;
@property (nonatomic)double xMax;
@property (nonatomic)double yMin;
@property (nonatomic)double yMax;

-(id)initWithFrame:(CGRect)f Data:(NSArray*)data;
-(void)setYMinValue:(double)yMin;
-(void)setYMaxValue:(double)yMax;

//-(void)drawLine;


@end
