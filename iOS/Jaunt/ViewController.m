//
//  ViewController.m
//  Copyright (c) 2014 loganisitt. All rights reserved.
//

#import "ViewController.h"

#import "WMGaugeView.h"

#define RGBA(r,g,b,a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a/255.0]

#define NEUTRAL_SPEED 95.0

@interface ViewController () {
    CGPoint firstPoint;
}

@property (strong, nonatomic) IBOutlet WMGaugeView *gaugeView;
@property (strong, nonatomic) IBOutlet UILabel *gaugeLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

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
    
    self.navigationItem.hidesBackButton = NO;
    
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    [self navigationItem].rightBarButtonItem = barButton;
    
    speedValue = 95;

    [self.view addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragging:)]];
}

-(void)dragging:(UIPanGestureRecognizer *)gesture {

    if (gesture.state == UIGestureRecognizerStateBegan) {
        firstPoint = [gesture locationInView:gesture.view];
    }

    CGPoint newCoord = [gesture locationInView:gesture.view];

    float dY = firstPoint.y - newCoord.y;

    float height = gesture.view.frame.size.height;

    float percentage = dY / height;

    [self updateSpeed:(1 + percentage) * speedValue];

    if (gesture.state == UIGestureRecognizerStateEnded) {
        speedValue = MAX(100, MIN((1 + percentage) * speedValue, 179));
    }
}

-(void)gaugeUpdateTimer:(NSTimer *)timer {

    __weak ViewController *weakSelf = self;
    [_gaugeView setValue:rand()%(int)_gaugeView.maxValue
                animated:YES
                duration:1.6
              completion:^(BOOL finished) {
                  weakSelf.gaugeLabel.text = [NSString stringWithFormat:@"%.0f JPS", weakSelf.gaugeView.value];
              }];
}

-(void) connectionTimer:(NSTimer *)timer
{
    if(bleShield.peripherals.count > 0)
    {
        [bleShield connectPeripheral:[bleShield.peripherals objectAtIndex:0]];
    }
    else
    {
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

-(void) bleDidReceiveData:(unsigned char *)data length:(int)length {
    NSData *d = [NSData dataWithBytes:data length:length];
    NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    NSLog(@"%@", s);
}

NSTimer *rssiTimer;

-(void) readRSSITimer:(NSTimer *)timer
{
    [bleShield readRSSI];
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void) bleDidDisconnect {

    // TODO: Add alert

    [self.navigationItem.leftBarButtonItem setTitle:@"Connect"];
    [activityIndicator stopAnimating];
    self.navigationItem.leftBarButtonItem.enabled = YES;
    
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];

    speedValue = NEUTRAL_SPEED;
}

-(void) bleDidConnect
{
    [activityIndicator stopAnimating];
    self.navigationItem.leftBarButtonItem.enabled = YES;
    [self.navigationItem.leftBarButtonItem setTitle:@"Disconnect"];

    [self updateSpeed:speedValue];
    
    NSLog(@"bleDidConnect");
}

- (void)updateSpeed:(int)speed {

    int actualSpeed = MAX(100, MIN(speed, 179));

    NSString *s = [NSString stringWithFormat:@"%i", actualSpeed];
    NSData *d = [s dataUsingEncoding:NSUTF8StringEncoding];

    if (bleShield.activePeripheral.state == CBPeripheralStateConnected) {
        [bleShield write:d];
    }

    __weak ViewController *weakSelf = self;
    [_gaugeView setValue:actualSpeed % 100
                animated:YES
                duration:0
              completion:^(BOOL finished) {
                  weakSelf.gaugeLabel.text = [NSString stringWithFormat:@"%.0f JPS", weakSelf.gaugeView.value];
              }];

    NSLog(@"Speed Value: %d", actualSpeed);
}

@end
