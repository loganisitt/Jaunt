//
//  ViewController.h
//  Jaunt
//
//  Created by Logan Isitt on 7/30/14.
//  Copyright (c) 2014 loganisitt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLE.h"

@interface ViewController : UIViewController <BLEDelegate>
{
    int speedValue;
    
    BLE *bleShield;
    UIActivityIndicatorView *activityIndicator;
}

@property (weak, nonatomic) IBOutlet UISlider *speedControl;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;

@end
