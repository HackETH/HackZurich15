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
@property (weak, nonatomic) IBOutlet UIButton *mainButton;


@end

bool spinning;
double roundTime = 10.0;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    spinning = false;
    NSURL *soundURL = [[NSBundle mainBundle] URLForResource:@"snare"
                                              withExtension:@"wav"];
    self.snareAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:nil];
    [self.snareAudioPlayer setVolume:0.0];
    [self.snareAudioPlayer play];
    
    
   
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)pulse {
    UIImageView *ring =[[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-116,self.view.frame.size.height/2-116,232,232)];
    ring.image=[UIImage imageNamed:@"Ring"];
    [self.view addSubview:ring];
    [UIView animateWithDuration:1.0 delay:0 options:UIViewAnimationOptionCurveLinear  animations:^{
        [ring setFrame:CGRectMake(self.view.frame.size.width/2-250,self.view.frame.size.height/2-250,500,500)];
        //code with animation
    } completion:^(BOOL finished) {
        //code for completion
    }];
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveLinear  animations:^{
        ring.alpha = 0.0;
        
        //code with animation
    } completion:^(BOOL finished) {
        //code for completion
    }];
}

- (void) startSpinning {
    if (!spinning) {
        CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        animation.fromValue = [NSNumber numberWithFloat:0.0f];
        animation.toValue = [NSNumber numberWithFloat: 2*M_PI];
        animation.duration = roundTime;
        [self.mainButton.layer addAnimation:animation forKey:@"SpinAnimation"];
        spinning = true;
        [NSTimer scheduledTimerWithTimeInterval:roundTime target:self selector:@selector(stopSpinning:) userInfo:nil repeats:NO];
    }
    
}
- (void) stopSpinning:(NSTimer *) timer {
    spinning = false;
}
- (IBAction)buttonpress:(id)sender {
    [self startSpinning];
    [self pulse];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
