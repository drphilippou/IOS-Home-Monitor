//
//  HMDownloadManager.h
//  HomeMonitor
//
//  Created by Paul Philippou on 6/21/16.
//  Copyright © 2016 IntelligentOhanaSolutions. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HMDownloadManager : NSObject

@property(nonatomic) BOOL downloadingHistory;
@property(nonatomic) NSTimeInterval lastRxSec;


-(id)init;
-(void)startDownloadingHistory;
    

@end
