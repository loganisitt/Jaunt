//
//  ViewController.m
//  Jaunt
//
//  Created by Logan Isitt on 7/30/14.
//  Copyright (c) 2014 loganisitt. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    bleShield = [[BLE alloc] init];
    [bleShield controlSetup];
    bleShield.delegate = self;
    
    self.navigationItem.hidesBackButton = NO;
    
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    [self navigationItem].rightBarButtonItem = barButton;
    
    speedValue = 95;
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

-(void) bleDidReceiveData:(unsigned char *)data length:(int)length
{
    NSLog(@"%s", __PRETTY_FUNCTION__);

    NSData *d = [NSData dataWithBytes:data length:length];
    NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    NSLog(@"%@", s);
    //    NSNumber *form = [NSNumber numberWithBool:YES];
    
    //    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:s, TEXT_STR, form, FORM, nil];
}

NSTimer *rssiTimer;

-(void) readRSSITimer:(NSTimer *)timer
{
    [bleShield readRSSI];
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void) bleDidDisconnect
{
    NSLog(@"bleDidDisconnect");
    
    [self.navigationItem.leftBarButtonItem setTitle:@"Connect"];
    [activityIndicator stopAnimating];
    self.navigationItem.leftBarButtonItem.enabled = YES;
    
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}

-(void) bleDidConnect
{
    [activityIndicator stopAnimating];
    self.navigationItem.leftBarButtonItem.enabled = YES;
    [self.navigationItem.leftBarButtonItem setTitle:@"Disconnect"];
    
    NSLog(@"bleDidConnect");
    [self.speedControl setValue:speedValue];
    [self speedChanged:self.speedControl];
}

- (IBAction)speedChanged:(id)sender {
    int newSpeed = [(UISlider *) sender value];
    
    if (newSpeed < 100 && newSpeed > 90) {
        NSString *s = [NSString stringWithFormat:@"%i", 95];
        NSData *d = [s dataUsingEncoding:NSUTF8StringEncoding];
        
        if (bleShield.activePeripheral.state == CBPeripheralStateConnected) {
            [bleShield write:d];
        }
        
        [self.speedLabel setText:s];
    }
    else {
        NSString *s = [NSString stringWithFormat:@"%i", newSpeed];
        NSData *d = [s dataUsingEncoding:NSUTF8StringEncoding];
        
        if (bleShield.activePeripheral.state == CBPeripheralStateConnected) {
            [bleShield write:d];
        }
        
        [self.speedLabel setText:s];
    }
}

@end