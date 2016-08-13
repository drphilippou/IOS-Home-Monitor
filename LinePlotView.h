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
@property (nonatomic)CGContextRef ctx;
@property (nonatomic,copy) NSArray* xVals;
@property (nonatomic,copy) NSArray* yVals;
@property (nonatomic,copy) NSArray* y2Vals;  //not used yet
@property (nonatomic)double xMin;
@property (nonatomic)double xMax;
@property (nonatomic)double yMin;
@property (nonatomic)double yMax;

//add margins for labels and titles
@property (nonatomic)int leftSideMargin;
@property (nonatomic)int rightSideMargin;
@property (nonatomic)int topMargin;
@property (nonatomic)int bottomMargin;

//report the values
@property (nonatomic) BOOL showValues;
@property (nonatomic) BOOL autoLabelYValues;
@property (nonatomic,strong) NSMutableDictionary* marginValues;

@property (nonatomic) BOOL showYAxisValues;



-(id)initWithFrame:(CGRect)f Data:(NSArray*)data;
-(void)setYMinValue:(double)yMin;
-(void)setYMaxValue:(double)yMax;
-(void)setXMinValue:(double)xMin;
-(void)setXMaxValue:(double)xMax;
@property (nonatomic)BOOL customXMaxLimits;
@property (nonatomic)BOOL customXMinLimits;
@property (nonatomic)BOOL customYMinLimits;
@property (nonatomic)BOOL customYMaxLimits;
-(void)reset;

//-(void)drawLine;


@end
