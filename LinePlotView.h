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
@property (nonatomic)CGContextRef ctx;
@property (nonatomic,copy) NSArray* xVals;
@property (nonatomic)double xMin;
@property (nonatomic)double xMax;

-(id)initWithFrame:(CGRect)f Data:(NSArray*)data;
//-(void)drawLine;


@end
