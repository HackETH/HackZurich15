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
@property (weak, nonatomic) IBOutlet UIButton *upArrowButton;
@property (weak, nonatomic) IBOutlet UIButton *downArrowButton;

@property AVAudioPlayer *snareAudioPlayer;
@property AudioSamplePlayer *samplePlayer;
@property dispatch_queue_t metronomeQueue;
@property NSDate *circleStartDate;
@property (weak, nonatomic) IBOutlet UIButton *mainButton;
@property double refreshInterval;
@property double roundTime;
@property int bpm;
@property int nBars;
@property BOOL beenHere;
@property NSTimer *intervalTimer;
@property (weak, nonatomic) IBOutlet UIButton *circle0;
@property (weak, nonatomic) IBOutlet UIButton *circle1;
@property (weak, nonatomic) IBOutlet UIButton *circle2;
@property (weak, nonatomic) IBOutlet UIButton *circle3;
@property (weak, nonatomic) IBOutlet UIButton *circle4;
@property (weak, nonatomic) IBOutlet UIButton *circle5;
@property (weak, nonatomic) IBOutlet UILabel *bpmLabel;
@property NSTimer *circleTimer;


@end

// Constants

#define numberOfTypes ((int) 6)
#define maxNumberOfBars (int)8
#define maxNumberOfHitsPerBar (int)256
#define bpmStep ((int)10)

// End

CMMotionManager *motionManager;
bool spinning;
double x_prev;
double y_prev;
double z_prev;
BOOL firstWait;
BOOL recording;
int currentType = 0;
int currentHit = 0;
BOOL looper[numberOfTypes][(int)(maxNumberOfBars*maxNumberOfHitsPerBar)];



@implementation ViewController

-(void)setBpmAndUpdateTimer:(int) bpmVal{
    self.bpm = bpmVal;
    if (spinning) {
        [self updateSpinning];
    }
    [self.intervalTimer invalidate];
    self.intervalTimer = [NSTimer scheduledTimerWithTimeInterval:self.refreshInterval target:self selector:@selector(getValues:) userInfo:nil repeats:YES];
    
}
-(double)roundTime{
    return 60*(self.nBars*4)/self.bpm;
}
-(void)setRoundTime:(double)roundTime{
    ;
}

-(double)refreshInterval{
    return (double)(1.0/((double)(self.bpm)/60.0/4.0))/(double)maxNumberOfHitsPerBar;
}
-(void)setRefreshInterval:(double)refreshInterval
{
    ;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.bpm = 80;
    self.nBars = 2;
    _metronomeQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    spinning = false;
    self.bpmLabel.text = [NSString stringWithFormat:@"%d", self.bpm];
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
    self.intervalTimer= [NSTimer scheduledTimerWithTimeInterval:self.refreshInterval target:self selector:@selector(getValues:) userInfo:nil repeats:YES];

    
    
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(setValues:) userInfo:nil repeats:NO];
    
    motionManager = [[CMMotionManager alloc] init];
    
    motionManager.accelerometerUpdateInterval = self.refreshInterval;  // 20 Hz
    [motionManager startAccelerometerUpdates];
    
   
    
    // Do any additional setup after loading the view, typically from a nib.
    [[AudioSamplePlayer sharedInstance] preloadAudioSample:@"Sound0"];
    [[AudioSamplePlayer sharedInstance] preloadAudioSample:@"Sound1"];
    [[AudioSamplePlayer sharedInstance] preloadAudioSample:@"Sound2"];
    [[AudioSamplePlayer sharedInstance] preloadAudioSample:@"Sound3"];
    [[AudioSamplePlayer sharedInstance] preloadAudioSample:@"Sound4"];
    [[AudioSamplePlayer sharedInstance] preloadAudioSample:@"Sound5"];
    
    
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
        // Free Memory?
    }];
}


- (void) startSpinningWith:(float) offset {
    self.upArrowButton.enabled = NO;
    self.downArrowButton.enabled = NO;
    if (!spinning) {
        
        CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        animation.fromValue = [NSNumber numberWithFloat:0.0f+offset];
        animation.toValue = [NSNumber numberWithFloat: 2*M_PI];
        animation.duration = self.roundTime*(1 - offset/(2*M_PI));
        
        [self.mainButton.layer addAnimation:animation forKey:@"SpinAnimation"];
        spinning = true;
        self.circleTimer = [NSTimer scheduledTimerWithTimeInterval:self.roundTime*(1 - offset/(2*M_PI)) target:self selector:@selector(stopSpinning:) userInfo:nil repeats:NO];
    }
    
}

-(void)updateSpinning{
    float currentOffset = (double)currentHit*2.0f*M_PI/((double)maxNumberOfHitsPerBar*(double)self.nBars);
    NSLog(@"%d",currentHit);
    spinning = false;
    [self.circleTimer invalidate];
    [self.mainButton.layer removeAllAnimations];
    [self startSpinningWith:currentOffset];
}

- (void) stopSpinning:(NSTimer *) timer {
    spinning = false;
    self.upArrowButton.enabled = YES;
    self.downArrowButton.enabled =YES;
    currentType++;
    [self animateButtons:currentType];
    [self.mainButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Button%d",currentType]]forState:UIControlStateNormal];
}

- (IBAction)buttonpress:(id)sender {
    [self startSpinningWith:0.0f];
    [self playSound:currentType];
    [self recordSound];
}

- (void)playSound:(int) soundType {
    [self pulse:soundType];
    dispatch_async(_metronomeQueue, ^{
        [[AudioSamplePlayer sharedInstance] playAudioSample:[NSString stringWithFormat:@"Sound%d",soundType]];

    });
}

- (void)recordSound {
    looper[currentType][currentHit] = true;
    
}

- (void)deleteLastTrack {
    
    if (spinning) {
        
    }
    else {
        currentHit--;
        for (int x=0;x<self.roundTime/self.refreshInterval;x++) {
            looper[x][currentHit]=false;
        }
    }
    
   
}



-(void) getValues:(NSTimer *) timer {
    NSLog(@"%d",currentHit);
    if(currentHit% maxNumberOfHitsPerBar==0){
        [self playFirstMetro];
    }else if (currentHit*4%maxNumberOfHitsPerBar==0){
        [self playMetro];
    }
    if (currentHit<maxNumberOfHitsPerBar*self.nBars) {
        currentHit++;
    }
    else {
        currentHit=0;
    }
    for (int x=0;x<numberOfTypes;x++) {
        if (looper[x][currentHit]) {
            [self playSound:x];
        }
    }
    
    
    
//    if (firstWait && fabs(motionManager.accelerometerData.acceleration.z-z_prev)>0.03) {
//        [self startSpinning];
//        [self pulse];
//        
//    }
}
-(void)playMetro{
    dispatch_async(self.metronomeQueue, ^{
        [[AudioSamplePlayer sharedInstance] playAudioSample:@"tick" gain:0.8f pitch:0.5f];

    });
}
-(void)playFirstMetro{
    dispatch_async(self.metronomeQueue, ^{
        [[AudioSamplePlayer sharedInstance] playAudioSample:@"tick" gain:1.0f pitch:1.0f];
    });
}

-(void) setValues:(NSTimer *) timer {
    x_prev = motionManager.accelerometerData.acceleration.x;
    y_prev = motionManager.accelerometerData.acceleration.y;
    z_prev = motionManager.accelerometerData.acceleration.z;
    firstWait = true;
    
    
}

- (IBAction)bpmUp:(id)sender {
    if (!spinning) {
        [self setBpmAndUpdateTimer:self.bpm+bpmStep];
        [self.bpmLabel setText:[NSString stringWithFormat:@"%d",self.bpm]];
    }
    
}
- (IBAction)bpmDown:(id)sender {
    if (!spinning) {
        [self setBpmAndUpdateTimer:self.bpm-bpmStep];
        [self.bpmLabel setText:[NSString stringWithFormat:@"%d",self.bpm]];
    }
    
}


-(void) deleteTrack:(int)num {
    for (int x=0;x<(int)self.roundTime/self.refreshInterval;x++) {
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
