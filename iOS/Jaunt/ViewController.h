//
//  ViewController.h
//  Copyright (c) 2014 loganisitt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLE.h"

@interface ViewController : UIViewController <BLEDelegate> {
    
    int speedValue;
    
    BLE *bleShield;
    UIActivityIndicatorView *activityIndicator;
}

@end
