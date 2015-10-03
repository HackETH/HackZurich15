//
//  ViewController.m
//  HackZurich15
//
//  Created by Samuel Mueller on 03.10.15.
//  Copyright © 2015 HACKETH. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AudioSamplePlayer.h"
#import <CoreMotion/CoreMotion.h>
@interface ViewController ()
@property AVAudioPlayer *snareAudioPlayer;
@property AudioSamplePlayer *samplePlayer;
@property dispatch_queue_t metronomeQueue;

@property (weak, nonatomic) IBOutlet UIButton *mainButton;
@property (weak, nonatomic) IBOutlet UIButton *circle0;
@property (weak, nonatomic) IBOutlet UIButton *circle1;
@property (weak, nonatomic) IBOutlet UIButton *circle2;
@property (weak, nonatomic) IBOutlet UIButton *circle3;
@property (weak, nonatomic) IBOutlet UIButton *circle4;
@property (weak, nonatomic) IBOutlet UIButton *circle5;
@property (weak, nonatomic) IBOutlet UILabel *bpmLabel;



@end

// Constants

#define numberOfTypes ((int) 5)
#define roundTime ((double) 10.0)
#define refreshInterval ((double) 0.01)

// End

CMMotionManager *motionManager;
bool spinning;
double x_prev;
double y_prev;
double z_prev;
BOOL firstWait;
BOOL recording;
int currentType = 0;
int currentBar = 0;
BOOL looper[numberOfTypes][(int)(roundTime/refreshInterval)];



@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _metronomeQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    spinning = false;
    /*
    NSURL *soundURL = [[NSBundle mainBundle] URLForResource:@"snare"
                                              withExtension:@"wav"];
    self.snareAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:nil];
    [self.snareAudioPlayer setVolume:0.0];
    [self.snareAudioPlayer play];
    [self.snareAudioPlayer setVolume:1.0];*/
    self.circle5.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 0.5);
    self.circle1.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 0.5);
    self.circle2.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 0.5);
    self.circle3.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 0.5);
    self.circle4.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 0.5);
    
    
    
    firstWait = false;
    recording = false;
    [NSTimer scheduledTimerWithTimeInterval:refreshInterval target:self selector:@selector(getValues:) userInfo:nil repeats:YES];

    
    
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(setValues:) userInfo:nil repeats:NO];
    
    motionManager = [[CMMotionManager alloc] init];
    
    motionManager.accelerometerUpdateInterval = refreshInterval;  // 20 Hz
    [motionManager startAccelerometerUpdates];
    
   
    
    // Do any additional setup after loading the view, typically from a nib.
    [[AudioSamplePlayer sharedInstance] preloadAudioSample:@"snares"];
    
}

- (void)pulse:(int)num {
    UIImageView *ring =[[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2-116,self.view.frame.size.height/2-116,232,232)];
    ring.image=[UIImage imageNamed:[NSString stringWithFormat:@"Ring%d",num]];
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
    currentType++;
    [self animateButtons:currentType];
    [self.mainButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Button%d",currentType]]forState:UIControlStateNormal];
}
- (IBAction)buttonpress:(id)sender {
    [self startSpinning];
    [self recordSound];
    [self playSound:currentType];
}

- (void)playSound:(int) soundType {
    [self pulse:soundType];
    dispatch_async(_metronomeQueue, ^{
        [[AudioSamplePlayer sharedInstance] playAudioSample:@"snares"];

    });
}

- (void)recordSound {
    looper[currentType][currentBar] = true;
    
}

- (void)deleteLastTrack {
    
    if (spinning) {
        
    }
    else {
        currentBar--;
        for (int x=0;x<(int)roundTime/refreshInterval;x++) {
            looper[x][currentBar]=false;
        }
    }
    
   
}



-(void) getValues:(NSTimer *) timer {
    if (currentBar<roundTime/refreshInterval) {
        currentBar++;
    }
    else {
        currentBar=0;
    }
    
    for (int x=0;x<numberOfTypes;x++) {
        if (looper[x][currentBar]) {
            [self playSound:x];
        }
    }
    
    
    
//    if (firstWait && fabs(motionManager.accelerometerData.acceleration.z-z_prev)>0.03) {
//        [self startSpinning];
//        [self pulse];
//        
//    }
    
   
    
    
}
-(void) setValues:(NSTimer *) timer {
    x_prev = motionManager.accelerometerData.acceleration.x;
    y_prev = motionManager.accelerometerData.acceleration.y;
    z_prev = motionManager.accelerometerData.acceleration.z;
    firstWait = true;
    
    
}

- (IBAction)bpmUp:(id)sender {
}
- (IBAction)bpmDown:(id)sender {
}


-(void) deleteTrack:(int)num {
    for (int x=0;x<(int)roundTime/refreshInterval;x++) {
        looper[num][x] = false;
    }
}
- (IBAction)circlePress0:(id)sender {
    [self animateButtons:0];
    currentType = 0;
    [self deleteTrack:0];
    [self.mainButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Button%d",0]]forState:UIControlStateNormal];
}
- (IBAction)circlePress1:(id)sender {
   [self animateButtons:1];
    currentType = 1;
    [self deleteTrack:1];
    [self.mainButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Button%d",1]]forState:UIControlStateNormal];
}
- (IBAction)circlePress2:(id)sender {
    [self animateButtons:2];
    currentType = 2;
    [self deleteTrack:2];
    [self.mainButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Button%d",2]]forState:UIControlStateNormal];
}
- (IBAction)circlePress3:(id)sender {
    [self animateButtons:3];
    currentType = 3;
    [self deleteTrack:3];
    [self.mainButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Button%d",3]]forState:UIControlStateNormal];
}
- (IBAction)circlePress4:(id)sender {
    [self animateButtons:4];
    currentType = 4;
    [self deleteTrack:4];
    [self.mainButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Button%d",4]]forState:UIControlStateNormal];
}
- (IBAction)circlePress5:(id)sender {
    [self animateButtons:5];
    currentType = 5;
    [self deleteTrack:5];
    [self.mainButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Button%d",5]]forState:UIControlStateNormal];
}

- (void)animateButtons:(int)num {
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.4 initialSpringVelocity:0.7  options:nil  animations:^{
        if (num!=0) {
            self.circle0.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 0.5);
        }
        else {
            self.circle0.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
        }
        if (num!=1) {
            self.circle1.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 0.5);
        }
        else {
            self.circle1.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
        }
        if (num!=2) {
            self.circle2.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 0.5);
        }
        else {
            self.circle2.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
        }
        if (num!=3) {
            self.circle3.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 0.5);
        }
        else {
            self.circle3.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
        }
        if (num!=4) {
            self.circle4.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 0.5);
        }
        else {
            self.circle4.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
        }
        if (num!=5) {
            self.circle5.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 0.5);
        }
        else {
            self.circle5.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
        }
       
    } completion:^(BOOL finished) {
        
        //code for completion
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




@end
