//
//  HMDownloadManager.m
//  HomeMonitor
//
//  Created by Paul Philippou on 6/21/16.
//  Copyright © 2016 IntelligentOhanaSolutions. All rights reserved.
//

#import "HMDownloadManager.h"
#import "IOSTimeFunctions.h"
#import "HMdataStore.h"

@interface HMDownloadManager ()
{
    IOSTimeFunctions* TF;
    HMdataStore* DB;
    NSURLConnection* webConnection;
    NSString* requestedFilename;
    NSString* receivedFilename;
    NSMutableData* webData;
    NSTimer* downloadHistoryTimer;
    NSTimer* downloadLatestTimer;
    
    
}
@end




@implementation HMDownloadManager

-(id) init {
    self = [super init];
    
    //allocate the local varaiables
    requestedFilename = @"";
    receivedFilename = @"";
    TF = [[IOSTimeFunctions alloc] init];
    DB = [[HMdataStore alloc] init];
    self.newDataAvailable = false;
    return self;
}


-(void)startDownloadingHistory {
    self.downloadingHistory = true;
    if (!downloadHistoryTimer) {
        downloadHistoryTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(requestHistoryStart) userInfo:nil repeats:YES];
    }
    [self requestHistoryStart];

}

-(void)startDownloadingLatest {
    NSLog(@"starting to download the latest values");
    self.downloadingLatest = true;
    if (!downloadLatestTimer) {
        downloadLatestTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(requestLatestStart) userInfo:nil repeats:YES];
    }
    [self requestLatestStart];

}


-(void)requestHistoryStart {
    
    //check to see if we are already downloading a file
    if (!webConnection) {
        
        //compute the current dateStr
        NSTimeInterval now = [TF currentTimeSec];
        int cyear = [TF year:now];
        int cmonth = [TF month:now];
        int cdate = cyear*100+cmonth;
        NSString *dateStr = [NSString stringWithFormat:@"%d.json",cdate];

        //check if we are current
        if ([dateStr isEqualToString:requestedFilename]) {
            //we have requested the last History file
            // now stop the process
            self.downloadingHistory = false;
            [downloadHistoryTimer invalidate];
            downloadHistoryTimer = nil;
            NSLog(@"we are caught up... stopping process");
            
            //start the incremental update
            [self startDownloadingLatest];
        } else {
            
            if ([requestedFilename isEqualToString:@""] ||
                [requestedFilename isEqualToString:@"CurrentHour.json"]) {
                int year = 2016;
                int month = 4;
                if ([DB HMMetadataVal].lastEntrySecs >0) {
                    year = [TF year:DB.HMMetadataVal.lastEntrySecs];
                    month = [TF month:DB.HMMetadataVal.lastEntrySecs];
                }
                int date = year *100 + month;
                
                
                
                //first file requested is the same month as the last data record
                requestedFilename = [NSString stringWithFormat:@"%d.json",date];
            } else {
                //not the first file requested
                //increment the month from the last file requested
                long r = [requestedFilename integerValue];
                long y = r/100;
                long m = r-y*100;
                m++;
                if (m==13) {
                    y++;
                    m=1;
                }
                long date = y*100+m;
                requestedFilename = [NSString stringWithFormat:@"%ld.json",date];
                
            }
            NSLog(@"Requested Filename %@",requestedFilename);
            NSString* urlStr = [NSString stringWithFormat:@"http://ios-hawaii.org/%@",requestedFilename];
            
            //NSURL *url = [NSURL URLWithString:@"http://ios-hawaii.org/20166.json"];
            NSURL *url = [NSURL URLWithString:urlStr];
            [self accessWebsite:url];
        }
    } else {
        NSLog(@"we are already downloading a file");
    }
}


-(void)requestLatestStart {
    
    //check to see if we are already downloading a file
    if (!webConnection) {
        
        requestedFilename = @"CurrentHour.json";
        NSLog(@"Requested Filename %@",requestedFilename);
        NSString* urlStr = [NSString stringWithFormat:@"http://ios-hawaii.org/currentHour.json"];
        
        NSURL *url = [NSURL URLWithString:urlStr];
        [self accessWebsite:url];
        
    } else {
        NSLog(@"DL we are already downloading a file");
    }
}


-(void)accessWebsite:(NSURL*)url
{
    NSLog(@"accessing the website");
    
    //set the start time
    //updateWebTime = [self currentTimeSec];
    
    //report that we are downloading
    self.downloading = TRUE;
    self.activityStr = [NSString stringWithFormat:@"Downloading %@",requestedFilename];
    
    //start the asynchronous transfer
    webData = [[NSMutableData alloc] init];
    NSURLRequest *req = [NSURLRequest requestWithURL:url
                                         cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                     timeoutInterval:120];
    webConnection = [[NSURLConnection alloc] initWithRequest:req
                                                    delegate:self
                                            startImmediately:YES];
    
    
}

//do not let the application cache any data
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    NSLog(@"received response");
    
    //get the etag
    NSString* eTag = nil;
    NSDictionary* d;
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    if ([response respondsToSelector:@selector(allHeaderFields)]) {
        d = [httpResponse allHeaderFields];
        //NSLog(@"response=%@",d);
        eTag = d[@"Etag"];
    }

    //    if (eTag != nil && [eTag isEqualToString:lastVehicleEtag]) {
    //        [connection cancel];
    //        vehicleConnection = nil;
    //        vehicleData = nil;
    //        NSLog(@"OBRDS Server sending stale file... aborting connection");
    //    } else {
    //        lastVehicleEtag = [eTag copy];
    //    }
}
- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)d {
    
    [webData appendData:d];
    //NSLog(@"received data len:%lu", (unsigned long)webData.length);
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error {
    
    NSLog(@"failed with error");
    webConnection = nil;
    webData = nil;
    self.downloading = false;
}


- (void)connectionDidFinishLoading:(NSURLConnection *)conn {
    NSLog(@"did finish loading");
    
    //convert back to a dictionary
    NSDictionary *rxJSON = [NSJSONSerialization JSONObjectWithData:webData options:0 error:nil];
    
    //shut down the web connection
    webConnection = nil;
    self.downloading = false;
    
    
    //parse
    NSLog(@"Parsing the rx %lu entries",(unsigned long)rxJSON.count);
    
    int numAdded = 0;
    for (NSString* k in rxJSON) {
        
        NSDictionary* d = rxJSON[k];
        
        float secs = [[d objectForKey:@"secs"] floatValue];
        //NSLog(@"rx key,date = %ld, %@",(long)secs,[d objectForKey:@"time"]);
        if (![DB getHMDataAtSecs1970:secs]) {
            
            //create a new entry
            numAdded++;
            HMData* da = [DB createHMData];
            da.pvSurplus = [[d objectForKey:@"Surplus"] floatValue];
            da.currPVPower = [[d objectForKey:@"PVCurPow"] intValue];
            da.keliiRoomHumidity = [[d objectForKey:@"KRH"] intValue];
            da.zoeRoomHumidity = [[d objectForKey:@"ZRH"] intValue];
            da.dehumidEnergy = [[d objectForKey:@"DehumidEnergy"] intValue  ];
            da.pvPred =[[d objectForKey:@"PVPred"] intValue  ];
            da.pvEnergyToday = [[d objectForKey:@"PVEngyToday"] intValue  ];
            da.zoeDehumidPower = [[d objectForKey:@"ZDP"] floatValue  ];
            da.time = [[d objectForKey:@"time"] copy];
            da.homeEnergy = [[d objectForKey:@"HomeEnergy"] integerValue  ];
            da.keliiDehumidPower = [[d objectForKey:@"KDP"] floatValue  ];
            da.homePower = [[d objectForKey:@"HomePower"] floatValue  ];
            da.shiller = [[d objectForKey:@"Shiller"] floatValue  ];
            da.secs = [[d objectForKey:@"secs"] floatValue  ];
            da.date = [[d objectForKey:@"date"] copy];;
            
            //let the other classes know we have entered new data
            self.newDataAvailable = true;
        }
        if (secs > [DB HMMetadataVal].lastEntrySecs) {
            [DB HMMetadataVal].lastEntrySecs = secs;
        }
    }
    NSLog(@"%d database entries added",numAdded);
    [DB saveDatabase];
    
    
    
    webData = nil;
}



@end
