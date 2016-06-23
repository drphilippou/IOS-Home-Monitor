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
    NSString* DBPath = [docDir stringByAppendingPathComponent:@"HMstore2.data"];
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







-(HMData*)createHMData {
    HMData* d;
    
    //insert a new entry into the database
    d = [NSEntityDescription insertNewObjectForEntityForName:@"HMData" inManagedObjectContext:context];
    return d;
}



-(NSMutableArray*)getHMData {
    
    //create an array to hold the data
    NSMutableArray* out = [[NSMutableArray alloc] init];
    
    //create the request
    NSEntityDescription *e = [[model entitiesByName] objectForKey:@"HMData"];
    NSFetchRequest *rq = [[NSFetchRequest alloc] init];
    [rq setEntity:e];
    //[rq setReturnsObjectsAsFaults:false];
    
    //retrieve the data
    NSArray* res;
    res = [context executeFetchRequest:rq error:nil];
    
    //stroe the date in the output array
    if (res.count>0) {
        out = [[NSMutableArray alloc] initWithArray:res];
    }
    return out;
}





@end
