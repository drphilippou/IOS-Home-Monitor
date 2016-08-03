//
//  singleGraphVC.h
//  HomeMonitor
//
//  Created by Paul Philippou on 7/29/16.
//  Copyright © 2016 IntelligentOhanaSolutions. All rights reserved.
//

typedef enum {
    PinchAxisNone,
    PinchAxisHorizontal,
    PinchAxisVertical
} PinchAxis;


#import <UIKit/UIKit.h>

@interface singleGraphVC : UIViewController
@property (nonatomic,copy) NSString* buttonTitle;
@property (nonatomic,strong) NSNumber* secs;

@end
