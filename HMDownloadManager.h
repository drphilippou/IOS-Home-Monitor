//
//  HMDownloadManager.h
//  HomeMonitor
//
//  Created by Paul Philippou on 6/21/16.
//  Copyright © 2016 IntelligentOhanaSolutions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMMetadata.h"

@interface HMDownloadManager : NSObject

@property(nonatomic) BOOL downloadingHistory;
@property(nonatomic) BOOL downloadingLatest;
@property(nonatomic) BOOL newDataAvailable;
@property(nonatomic) BOOL downloading;
@property(nonatomic,strong) NSString* activityStr;


-(id)init;
-(void)startDownloadingHistory;
-(void)startDownloadingLatest;
    

@end
