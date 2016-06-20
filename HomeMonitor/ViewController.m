//
//  ViewController.m
//  HomeMonitor
//
//  Created by Paul Philippou on 6/7/16.
//  Copyright (c) 2016 IntelligentOhanaSolutions. All rights reserved.
//

#import "ViewController.h"
#import "IOSTimeFunctions.h"

@interface ViewController ()
{

    NSTimer* accessWebsiteTimer;
    NSURLConnection* webConnection;
    BOOL downloadingHistory;
    NSString* requestedFilename;
    NSString* receivedFilename;
    NSMutableData* webData;
    NSTimeInterval lastRxSec;
    IOSTimeFunctions* TF;

}
@property (strong,nonatomic) NSMutableDictionary* data;



@end





@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //test the version control
    
    //init variables
    lastRxSec = 0;
    TF = [[IOSTimeFunctions alloc] init];
    downloadingHistory = FALSE;
    requestedFilename = @"";
    receivedFilename = @"";
    
    
    //do we need to load any File History?
    NSTimeInterval now = [TF currentTimeSec];
    if ((now - lastRxSec)>60*60*24) {
        //start downloading history
        downloadingHistory = TRUE;
        
        //start the timers to download history
        if (accessWebsiteTimer==nil) {
            accessWebsiteTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(requestHistoryStart) userInfo:nil repeats:YES];
        }
    }
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(void)requestHistoryStart {
    
    //check to see if we are already downloading a file
    if (!webConnection) {
        //calculate the next needed history file
        NSTimeInterval now = [TF currentTimeSec];
        int cyear = [TF year:now];
        int cmonth = [TF month:now];
        int year = 2014;
        int month = 4;
        if (lastRxSec >0) {
            year = [TF year:lastRxSec];
            month = [TF month:lastRxSec];
        }
        
        //check if we are current
        int cdate = cyear*100+cmonth;
        int date = year*100 + month;
        if (cdate == date) {
            NSLog(@"we are caught up");
        } else {
            
            if ([requestedFilename isEqualToString:@""]) {
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
                date = y*100+m;
                requestedFilename = [NSString stringWithFormat:@"%d.json",date];
                
            }
        NSLog(@"Requested Filename %@",requestedFilename);
            
        NSURL *url = [NSURL URLWithString:@"http://ios-hawaii.org/20166.json"];
        [self accessWebsite:url];
        }
    } else {
        NSLog(@"we are already downloading a file");
    }
    
}

-(void)accessWebsite:(NSURL*)url
{
    NSLog(@"accessing the website");
    

//    
//    //load the past history if needed
//    NSTimeInterval elapsed = now - lastRxSec;
//    if (elapsed > 60*60*24) {
//        //past 24 hours, need to load history
//        int m = month;
//        int y = year;
//        while (m!=cmonth || y!=cyear) {
//            NSLog(@"file = %d%d",y,m);
//            m++;
//            if (m==13) {
//                m=1;
//                y++;
//            }
//        }
//    }
    
    
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


#pragma mark - Access Data Connection
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
    NSLog(@"Parsing the rx");
    for (NSString* k in rxJSON) {
        //NSLog(@"%@",k);
        NSDictionary* d = rxJSON[k];
        //NSLog(@"%@",d.description);
        long secs = [[d objectForKey:@"secs"] longLongValue];
        //NSLog(@"%@",[TF localDateYYYYMMDD:secs]);
        //NSLog(@"%@",[TF localTimehhmmssa:secs]);
        //NSLog(@"year %d month %d",[TF year:secs],[TF month:secs]);
        if (secs >lastRxSec) {
            lastRxSec = secs;
        }
    }
 
    
    
    webData = nil;
}




@end
