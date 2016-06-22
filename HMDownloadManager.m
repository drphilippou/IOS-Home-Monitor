//
//  HMDownloadManager.m
//  HomeMonitor
//
//  Created by Paul Philippou on 6/21/16.
//  Copyright © 2016 IntelligentOhanaSolutions. All rights reserved.
//

#import "HMDownloadManager.h"
#import "IOSTimeFunctions.h"

@interface HMDownloadManager ()
{
    IOSTimeFunctions* TF;
    NSURLConnection* webConnection;
    NSString* requestedFilename;
    NSString* receivedFilename;
    NSMutableData* webData;
    NSTimer* downloadHistoryTimer;

    
}
@end




@implementation HMDownloadManager

-(id) init {
    self = [super init];
    
    //allocate the local varaiables
    requestedFilename = @"";
    receivedFilename = @"";
    TF = [[IOSTimeFunctions alloc] init];
    return self;
}


-(void)startDownloadingHistory {
    self.downloadingHistory = true;
    if (!downloadHistoryTimer) {
        downloadHistoryTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(requestHistoryStart) userInfo:nil repeats:YES];
    }
    [self requestHistoryStart];

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
        } else {
            
            if ([requestedFilename isEqualToString:@""]) {
                int year = 2016;
                int month = 4;
                if (self.lastRxSec >0) {
                    year = [TF year:self.lastRxSec];
                    month = [TF month:self.lastRxSec];
                }
                int date = year *100 + month;
                
                
                
                //first file requested is the same month as the last data record
                requestedFilename = [NSString stringWithFormat:@"%d.json",date];
            } else {
                //not the first file requested
                //increment the month from the last file requested
                int r = [requestedFilename integerValue];
                int y = r/100;
                int m = r-y*100;
                m++;
                if (m==13) {
                    y++;
                    m=1;
                }
                int date = y*100+m;
                requestedFilename = [NSString stringWithFormat:@"%d.json",date];
                
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

-(void)accessWebsite:(NSURL*)url
{
    NSLog(@"accessing the website");
    
    //set the start time
    //updateWebTime = [self currentTimeSec];
    
    //start the asynchronous transfer
    webData = [[NSMutableData alloc] init];
    NSURLRequest *req = [NSURLRequest requestWithURL:url
                                         cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                     timeoutInterval:120];
    webConnection = [[NSURLConnection alloc] initWithRequest:req
                                                    delegate:self
                                            startImmediately:YES];
    
    
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    NSLog(@"received response");
    
    //get the etag
    NSString* eTag = nil;
    NSDictionary* d;
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    if ([response respondsToSelector:@selector(allHeaderFields)]) {
        d = [httpResponse allHeaderFields];
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
}


- (void)connectionDidFinishLoading:(NSURLConnection *)conn {
    NSLog(@"did finish loading");
    
    //convert back to a dictionary
    NSDictionary *rxJSON = [NSJSONSerialization JSONObjectWithData:webData options:0 error:nil];
    
    //shut down the web connection
    webConnection = nil;
    
    //parse
    NSLog(@"Parsing the rx %lu entries",(unsigned long)rxJSON.count);
    for (NSString* k in rxJSON) {
        //NSLog(@"%@",k);
        NSDictionary* d = rxJSON[k];
        //NSLog(@"%@",d.description);
        long secs = [[d objectForKey:@"secs"] longLongValue];
        //NSLog(@"%@",[TF localDateYYYYMMDD:secs]);
        //NSLog(@"%@",[TF localTimehhmmssa:secs]);
        //NSLog(@"year %d month %d",[TF year:secs],[TF month:secs]);
        if (secs >self.lastRxSec) {
            self.lastRxSec = secs;
        }
    }
    
    
    
    webData = nil;
}



@end
