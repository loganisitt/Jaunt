//
//  ViewController.m
//  Copyright (c) 2014 loganisitt. All rights reserved.
//

#import "ViewController.h"

#import "WMGaugeView.h"

#define BREAK_SPEED 95
#define MIN_SPEED 100
#define MAX_SPEED 179

@implementation NSObject (Blocks)

- (void)performBlock:(void (^)())block
{
    block();
}

- (void)performBlock:(void (^)())block afterDelay:(NSTimeInterval)delay
{
    void (^block_)() = [block copy]; // autorelease this if you're not using ARC
    [self performSelector:@selector(performBlock:) withObject:block_ afterDelay:delay];
}

@end

@interface ViewController () {
    BOOL _tracking;
    CGPoint firstPoint;
}

@property (strong, nonatomic) IBOutlet WMGaugeView *gaugeView;
@property (strong, nonatomic) IBOutlet UILabel *gaugeLabel;

@property (weak, nonatomic) IBOutlet UIButton *breakButton;
@property (weak, nonatomic) IBOutlet UILabel *averageSpeedLabel;
@property (weak, nonatomic) IBOutlet UILabel *topSpeedLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.follower = [Follower new];
    self.follower.delegate = self;

    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:255.0/255.0 green:104.0/255.0 blue:97.0/255.0 alpha:255.0/255.0];

    _gaugeView.style = [WMGaugeViewStyleFlatThin new];
    _gaugeView.maxValue = 80.0;
    _gaugeView.scaleDivisions = 8;
    _gaugeView.scaleSubdivisions = 5;
    _gaugeView.scaleStartAngle = 30;
    _gaugeView.scaleEndAngle = 280;
    _gaugeView.showScaleShadow = NO;
    _gaugeView.scaleFont = [UIFont fontWithName:@"AvenirNext-UltraLight" size:0.065];
    _gaugeView.scalesubdivisionsAligment = WMGaugeViewSubdivisionsAlignmentCenter;
    _gaugeView.scaleSubdivisionsWidth = 0.002;
    _gaugeView.scaleSubdivisionsLength = 0.04;
    _gaugeView.scaleDivisionsWidth = 0.007;
    _gaugeView.scaleDivisionsLength = 0.07;

    bleShield = [[BLE alloc] init];
    [bleShield controlSetup];
    bleShield.delegate = self;

    [self.breakButton setTitle:@"Break" forState:UIControlStateNormal];
    [self.breakButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.breakButton.backgroundColor = [UIColor redColor];
    self.breakButton.layer.cornerRadius = 50.0;

    [self.breakButton addTarget:self
                         action:@selector(softBreak)
               forControlEvents:UIControlEventTouchUpInside];

    self.navigationItem.hidesBackButton = NO;
    
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    [self navigationItem].rightBarButtonItem = barButton;

    UIBarButtonItem *connectButton = [[UIBarButtonItem alloc] initWithTitle:@"Connect" style:UIBarButtonItemStyleDone target:self action:@selector(BLEShieldScan:)];

    connectButton.tintColor = [UIColor whiteColor];

    self.navigationItem.leftBarButtonItem = connectButton;
    
    speedValue = BREAK_SPEED;

    [self.view addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                            action:@selector(dragging:)]];
}

- (void)softBreak {

    float softBreakDelay = 2.0 / (speedValue - 100);
    if (softBreakDelay >= 2.0) {
        [self updateSpeed:@(MIN_SPEED)];
        [self hardBreak];
    } else {
        [self performBlock:^{
            [self updateSpeed:@(--speedValue)];
            [self softBreak];
        } afterDelay:softBreakDelay];
    }
}

- (void)hardBreak {

    speedValue = BREAK_SPEED;

    NSString *s = [NSString stringWithFormat:@"%i", speedValue];
    NSData *d = [s dataUsingEncoding:NSUTF8StringEncoding];

    if (bleShield.activePeripheral.state == CBPeripheralStateConnected) {
        [bleShield write:d];
    }

}

-(void)dragging:(UIPanGestureRecognizer *)gesture {

    if (gesture.state == UIGestureRecognizerStateBegan) {
        firstPoint = [gesture locationInView:gesture.view];
    }

    CGPoint newCoord = [gesture locationInView:gesture.view];

    float dY = firstPoint.y - newCoord.y;

    float height = gesture.view.frame.size.height;

    float percentage = dY / height;

    [self updateSpeed:@((1 + percentage) * speedValue)];

    if (gesture.state == UIGestureRecognizerStateEnded) {
        speedValue = MAX(100, MIN((1 + percentage) * speedValue, 179));
    }
}

-(void) connectionTimer:(NSTimer *)timer {
    if(bleShield.peripherals.count > 0) {
        [bleShield connectPeripheral:[bleShield.peripherals objectAtIndex:0]];
    } else {
        [activityIndicator stopAnimating];
        self.navigationItem.leftBarButtonItem.enabled = YES;
    }
}

- (IBAction)BLEShieldScan:(id)sender
{
    if (bleShield.activePeripheral)
        if(bleShield.activePeripheral.state == CBPeripheralStateConnected)
        {
            [[bleShield CM] cancelPeripheralConnection:[bleShield activePeripheral]];
            return;
        }
    
    if (bleShield.peripherals)
        bleShield.peripherals = nil;
    
    [bleShield findBLEPeripherals:3];
    
    [NSTimer scheduledTimerWithTimeInterval:(float)3.0 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
    
    [activityIndicator startAnimating];
    self.navigationItem.leftBarButtonItem.enabled = NO;
}

- (void)updateSpeed:(NSNumber *)speed {

    int actualSpeed = MAX(MIN_SPEED, MIN(speed.intValue, MAX_SPEED));

    NSString *s = [NSString stringWithFormat:@"%i", actualSpeed];
    NSData *d = [s dataUsingEncoding:NSUTF8StringEncoding];

    if (bleShield.activePeripheral.state == CBPeripheralStateConnected) {
        [bleShield write:d];
    }

    __weak ViewController *weakSelf = self;
    [_gaugeView setValue:actualSpeed % MIN_SPEED
                animated:YES
                duration:0
              completion:^(BOOL finished) {
                  weakSelf.gaugeLabel.text = [NSString stringWithFormat:@"%.0fjps", weakSelf.gaugeView.value];
              }];
}

#pragma mark - BLEDelegate

-(void) bleDidReceiveData:(unsigned char *)data length:(int)length {
    // TODO: Add Alert

//    NSData *d = [NSData dataWithBytes:data length:length];
//    NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
}

NSTimer *rssiTimer;

-(void) readRSSITimer:(NSTimer *)timer {
    [bleShield readRSSI];
}

- (void) bleDidDisconnect {

    // TODO: Add alert
    [self.follower endRouteTracking];
    [self.navigationItem.leftBarButtonItem setTitle:@"Connect"];
    [activityIndicator stopAnimating];
    self.navigationItem.leftBarButtonItem.enabled = YES;

    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}

-(void) bleDidConnect {
    // TODO: Add Alert

    [self.follower beginRouteTracking];
    [activityIndicator stopAnimating];
    self.navigationItem.leftBarButtonItem.enabled = YES;
    [self.navigationItem.leftBarButtonItem setTitle:@"Disconnect"];

    [self updateSpeed:@(speedValue)];
}

#pragma mark - Follower

- (void)followerDidUpdate:(Follower *)follower {

    self.topSpeedLabel.text = [NSString stringWithFormat:@"%.1f mph", [follower topSpeedWithUnit:SpeedUnitMilesPerHour]];
    self.averageSpeedLabel.text = [NSString stringWithFormat:@"%.1f mph", [follower averageSpeedWithUnit:SpeedUnitMilesPerHour]];
}

@end
