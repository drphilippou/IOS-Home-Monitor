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
    NSMutableData* webData;
    long lastRxSec;
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
    
    
    //start the timers
    if (accessWebsiteTimer==nil) {
        accessWebsiteTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(accessWebsite) userInfo:nil repeats:YES];
    }
    
    //download the first instance
    [self accessWebsite];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)accessWebsite
{
    NSLog(@"accessing the website");
    
//    if (webConnection != nil) {
//        NSTimeInterval now = [self currentTimeSec];
//        NSTimeInterval elapsed = now - updateWebTime;
//        NSLog(@"OBRDS Update Vehicle Start... UPdate in progress %f",elapsed);
//        
//        if (elapsed>30) {
//            NSLog(@"Update Vehicle timed out restarting");
//            vehicleConnection = nil;
//            vehicleData = nil;
//        }
//        return;
//    }

    //determine how much history we need
    
    
    
    //set the URL
    //NSURL *url = [NSURL URLWithString:@"http://OBRuser:OBRUserPassword@ios-hawaii.com/OBRroot/allvehicles.json"];
    NSURL *url = [NSURL URLWithString:@"http://ios-hawaii.org/20165.json"];
    
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
    NSLog(@"received data len:%lu", (unsigned long)webData.length);
}


- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error {
    
    NSLog(@"failed with error");
    webConnection = nil;
    webData = nil;
}


- (void)connectionDidFinishLoading:(NSURLConnection *)conn {
    NSLog(@"did finish loading");
    webConnection = nil;
    //[self updateVehiclesEnd:vehicleData];
    
    NSDictionary *rxJSON = [NSJSONSerialization JSONObjectWithData:webData options:0 error:nil];
    

    for (NSString* k in rxJSON) {
        NSLog(@"%@",k);
        NSDictionary* d = rxJSON[k];
        NSLog(@"%@",d.description);
        long secs = [[d objectForKey:@"secs"] longLongValue];
        NSLog(@"%@",[TF localDateYYYYMMDD:secs]);
        NSLog(@"%@",[TF localTimehhmmssa:secs]);
        NSLog(@"year %d month %d",[TF year:secs],[TF month:secs]);
        if (secs >lastRxSec) {
            lastRxSec = secs;
        }
    }
 
    
    
    webData = nil;
}




@end
