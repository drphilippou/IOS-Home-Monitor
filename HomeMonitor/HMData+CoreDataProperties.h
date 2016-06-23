//
//  HMData+CoreDataProperties.h
//  HomeMonitor
//
//  Created by Paul Philippou on 6/23/16.
//  Copyright © 2016 IntelligentOhanaSolutions. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "HMData.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMData (CoreDataProperties)

@property (nonatomic) int32_t currPVPower;
@property (nonatomic) int32_t keliiRoomHumidity;
@property (nonatomic) float pvSurplus;
@property (nonatomic) int32_t zoeRoomHumidity;
@property (nonatomic) int32_t dehumidEnergy;
@property (nonatomic) int32_t pvPred;
@property (nonatomic) int32_t pvEnergyToday;
@property (nonatomic) float zoeDehumidPower;
@property (nullable, nonatomic, retain) NSString *time;
@property (nonatomic) float homeEnergy;
@property (nonatomic) float keliiDehumidPower;
@property (nonatomic) float homePower;
@property (nonatomic) float shiller;
@property (nonatomic) NSTimeInterval secs;
@property (nullable, nonatomic, retain) NSString *date;

@end

NS_ASSUME_NONNULL_END
