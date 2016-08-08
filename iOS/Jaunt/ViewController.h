//
//  ViewController.h
//  Copyright (c) 2014 loganisitt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLE.h"
#import "Follower.h"

@interface NSObject (Blocks)

- (void)performBlock:(void (^)())block afterDelay:(NSTimeInterval)delay;

@end

@interface ViewController : UIViewController <BLEDelegate, FollowerDelegate> {
    
    int speedValue;
    
    BLE *bleShield;
    UIActivityIndicatorView *activityIndicator;
}

@property (nonatomic, strong) Follower *follower;

@end
