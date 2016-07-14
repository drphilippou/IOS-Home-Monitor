//
//  dataStore.m
//  HomeMonitor
//
//  Created by Paul Philippou on 6/23/16.
//  Copyright © 2016 IntelligentOhanaSolutions. All rights reserved.
//

#import "HMdataStore.h"



@interface HMdataStore() {
    NSPersistentStoreCoordinator *psc;
}

@property (nonatomic,strong) NSManagedObjectContext *context;
@property (nonatomic,strong) NSManagedObjectModel *model;



@end



@implementation HMdataStore
@synthesize context;
@synthesize model;
//@synthesize HMDataArray;




#pragma mark init

+ (HMdataStore *)defaultStore {
    static HMdataStore *defaultStore = nil;
    if(!defaultStore)
        defaultStore = [[super allocWithZone:nil] init];
    
    return defaultStore;
}






#pragma mark - load database
- (id)init {
    NSLog(@"DS dataStore Init Start");
    self = [super init];
    if(self) {
        [self loadDatabase];
    }
    
    NSLog(@"DS dataStore Init Done");
    return self;
}




-(BOOL)loadDatabase {
    NSLog(@"DS loadDatabase Start");
    
    //create the address for the database in the documents directory
    NSArray* docDirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* docDir = [docDirs objectAtIndex:0];
    NSString* DBPath = [docDir stringByAppendingPathComponent:@"HMstore5.data"];
    NSURL* storeURL = [NSURL fileURLWithPath:DBPath];
    
    //create the model and the coordinator
    model = [NSManagedObjectModel mergedModelFromBundles:nil];
    psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    //add the persistent Store
    NSError *error=nil;
    [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error];
    
    //create the managed object context
    context = [[NSManagedObjectContext alloc] init];
    [context setPersistentStoreCoordinator:psc];
    
    //The managed object context can manage undo, but we dont need it
    [context setUndoManager:nil];
    
    //report any errors
    if (error) {
        //[NSException raise:@"Open failed" format:@"Reason: %@",[error localizedDescription]];
        //add an alert to handle this
        if (error.code == 134100) {
            NSLog(@"Installed Database is inconsistent with the Model");
            return false;
        }
    }
    
    NSLog(@"DS loadDatabase Done");
    return true;
}





-(BOOL)saveDatabase {
    NSLog(@"OBRDS Saving Database");
    NSError *err=nil;
    BOOL successful = [context save:&err];
    
    if (!successful) {
        NSLog(@"Error Saving:%@",[err localizedDescription]);
    }
    return successful;
}




-(HMData*)getHMDataAtSecs1970:(NSTimeInterval)sec {
    NSArray* dr = [self HMDataArray];
    for (HMData* d in dr) {
        if (sec == d.secs) {
            return d;
        }
    }
    return nil;
}


-(HMData*)createHMData {
    HMData* d;
    
    //insert a new entry into the database
    d = [NSEntityDescription insertNewObjectForEntityForName:@"HMData" inManagedObjectContext:context];
    [self.HMDataArray addObject:d];
    //[self saveDatabase];
    
    return d;
}


-(HMMetadata*)HMMetadataVal {
    if (!_HMMetadataVal) {
        //create the request
        NSEntityDescription *e = [[model entitiesByName] objectForKey:@"HMMetadata"];
        NSFetchRequest *rq = [[NSFetchRequest alloc] init];
        [rq setEntity:e];
        [rq setReturnsObjectsAsFaults:false];
        
        //retrieve the data
        NSArray* res;
        res = [context executeFetchRequest:rq error:nil];
        
        //stroe the date in the output array
        if (res.count>0) {
            _HMMetadataVal = [res firstObject];
        } else {
            _HMMetadataVal = [NSEntityDescription insertNewObjectForEntityForName:@"HMMetadata" inManagedObjectContext:context];
            _HMMetadataVal.version = @"1.0";
            _HMMetadataVal.lastEntrySecs = 0;
        }
    }
    return _HMMetadataVal;
}


-(HMData*)getLatestHMData {
    
    //create the request
    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"HMData"];
    NSFetchRequest *rq = [[NSFetchRequest alloc] init];
    [rq setEntity:e];
    [rq setFetchLimit:3];
    [rq setReturnsObjectsAsFaults:false];
    
    //grab the data in time order
    NSSortDescriptor *sd = [NSSortDescriptor
                            sortDescriptorWithKey:@"secs"
                            ascending:NO];
    [rq setSortDescriptors:[NSArray arrayWithObject:sd]];
    
    
    //retrieve the data
    NSArray* res;
    res = [context executeFetchRequest:rq error:nil];
    
    //stroe the date in the output array
    if (res.count>0) {
        HMData* v = [res firstObject];
        return v;
    } else {
        return nil;
    }
}



-(NSArray*)getHMDataSinceSecs1970:(NSTimeInterval)sec {
    
    //create the request
    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"HMData"];
    NSFetchRequest *rq = [[NSFetchRequest alloc] init];
    [rq setEntity:e];
    [rq setReturnsObjectsAsFaults:false];
    
    //grab the data in time order
    NSSortDescriptor *sd = [NSSortDescriptor
                            sortDescriptorWithKey:@"secs"
                            ascending:YES];
    [rq setSortDescriptors:[NSArray arrayWithObject:sd]];
    
    //set the predicate
    NSPredicate *p = [NSPredicate predicateWithFormat:@"( secs.timeIntervalSince1970 > %f)",sec];
    [rq setPredicate:p];
    
    
    //retrieve the data
    NSArray* res;
    res = [context executeFetchRequest:rq error:nil];
    return res;
}


-(NSArray*)getFieldAsString:(NSString *)s sinceSec:(NSTimeInterval)t {
    NSArray* d = [self getHMDataSinceSecs1970:t];
    NSMutableArray* entries = [d valueForKey:s];
    
    //populate the different formats into strings
    NSMutableArray* out = [[NSMutableArray alloc] init];
    for (int i=0 ; i< entries.count; i++)  {
        if ([entries[i] isKindOfClass:[NSDate class]]) {
            NSTimeInterval ts = [entries[i] timeIntervalSinceReferenceDate];
            NSString* s = [NSString stringWithFormat:@"%lf",ts];
            [out addObject:s];
        } else if ([entries[i] isKindOfClass:[NSString class]]) {
            NSString* s = [entries[i] copy];
            [out addObject:s];
        } else {
           NSString* s = [entries[i] stringValue];
            [out addObject:s];
        }
    }
    return out;
}



-(NSMutableArray*)HMDataArray {
    
    if (!_HMDataArray) {
        
        //create the request
        NSEntityDescription *e = [[model entitiesByName] objectForKey:@"HMData"];
        NSFetchRequest *rq = [[NSFetchRequest alloc] init];
        NSSortDescriptor *sd = [NSSortDescriptor
                                sortDescriptorWithKey:@"secs"
                                ascending:YES];
        [rq setEntity:e];
        [rq setSortDescriptors:[NSArray arrayWithObject:sd]];

        
        //retrieve the data
        NSArray* res;
        res = [context executeFetchRequest:rq error:nil];
        
        //stroe the date in the output array
        if (res.count>0) {
            _HMDataArray = [[NSMutableArray alloc] initWithArray:res];
        }
    }
    return _HMDataArray;
}





@end
