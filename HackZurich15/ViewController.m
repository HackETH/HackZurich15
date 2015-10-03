//
//  ViewController.m
//  HackZurich15
//
//  Created by Samuel Mueller on 03.10.15.
//  Copyright © 2015 HACKETH. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
@interface ViewController ()
@property AVAudioPlayer *snareAudioPlayer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSURL *soundURL = [[NSBundle mainBundle] URLForResource:@"snare"
                                              withExtension:@"wav"];
    self.snareAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:nil];
    [self.snareAudioPlayer setVolume:0.0];
    [self.snareAudioPlayer play];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
