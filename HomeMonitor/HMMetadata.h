//
//  HMMetadata.h
//  HomeMonitor
//
//  Created by Paul Philippou on 6/24/16.
//  Copyright (c) 2016 IntelligentOhanaSolutions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface HMMetadata : NSManagedObject

@property (nonatomic, retain) NSString * version;
@property (nonatomic) NSTimeInterval lastEntrySecs;

@end
