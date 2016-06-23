//
//  HMdataStore.h
//  HomeMonitor
//
//  Created by Paul Philippou on 6/23/16.
//  Copyright © 2016 IntelligentOhanaSolutions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>
#import "HMDAta.h"

@interface HMdataStore : NSObject <UIAlertViewDelegate>



+(HMdataStore *)defaultStore;
-(BOOL)loadDatabase;
-(BOOL)saveDatabase;
//-(void)deleteObject:(NSManagedObject*) ob;

-(HMData*)createHMData;
-(NSMutableArray*)getHMData;




@end
