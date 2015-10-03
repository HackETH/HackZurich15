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
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property AVAudioPlayer *snareAudioPlayer;
@property AudioSamplePlayer *samplePlayer;
@property dispatch_queue_t metronomeQueue;
@property NSDate *circleStartDate;
@property (weak, nonatomic) IBOutlet UIButton *mainButton;
@property double refreshInterval;
@property double roundTime;
@property int bpm;
@property int nBars;
@property NSTimer *intervalTimer;
@end

// Constants

#define numberOfTypes ((int) 5)
#define maxNumberOfBars 8
#define maxNumberOfHitsPerBar 128

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
    [self updateSpinning];
    [self.intervalTimer invalidate];
    self.intervalTimer = [NSTimer timerWithTimeInterval:self.refreshInterval target:self selector:@selector(getValues:) userInfo:nil repeats:YES];
    
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
    self.pickerView.dataSource = self;
    self.pickerView.delegate = self;
    _metronomeQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    spinning = false;
    /*
    NSURL *soundURL = [[NSBundle mainBundle] URLForResource:@"snare"
                                              withExtension:@"wav"];
    self.snareAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:nil];
    [self.snareAudioPlayer setVolume:0.0];
    [self.snareAudioPlayer play];
    [self.snareAudioPlayer setVolume:1.0];*/
    
    
    
    
    firstWait = false;
    recording = false;
    self.intervalTimer= [NSTimer scheduledTimerWithTimeInterval:self.refreshInterval target:self selector:@selector(getValues:) userInfo:nil repeats:YES];

    
    
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(setValues:) userInfo:nil repeats:NO];
    
    motionManager = [[CMMotionManager alloc] init];
    
    motionManager.accelerometerUpdateInterval = self.refreshInterval;  // 20 Hz
    [motionManager startAccelerometerUpdates];
    
   
    
    // Do any additional setup after loading the view, typically from a nib.
    [[AudioSamplePlayer sharedInstance] preloadAudioSample:@"snares"];
    
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
        // Free Memory?
    }];
}


- (void) startSpinningWith:(float) offset {
    if (!spinning) {
        
        CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        animation.fromValue = [NSNumber numberWithFloat:0.0f+offset];
        animation.toValue = [NSNumber numberWithFloat: 2*M_PI];
        animation.duration = self.roundTime;
        
        [self.mainButton.layer addAnimation:animation forKey:@"SpinAnimation"];
        spinning = true;
        [NSTimer scheduledTimerWithTimeInterval:self.roundTime target:self selector:@selector(stopSpinning:) userInfo:nil repeats:NO];
    }
    
}
-(void)updateSpinning{
    float currentOffset = (double)currentHit*2.0f*M_PI/((double)maxNumberOfHitsPerBar*(double)self.nBars);
    NSLog(@"%d",currentHit);
    spinning = false;
    [self.mainButton.layer removeAllAnimations];
    [self startSpinningWith:currentOffset];
}
- (void) stopSpinning:(NSTimer *) timer {
    spinning = false;
    currentType++;
}
- (IBAction)buttonpress:(id)sender {
    [self startSpinningWith:0.0f];
    [self pulse];
    [self recordSound];
    [self playSound:currentType];
}

- (void)playSound:(int) soundType {
    [self pulse];
    dispatch_async(_metronomeQueue, ^{
        [[AudioSamplePlayer sharedInstance] playAudioSample:@"snares"];

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
-(void) setValues:(NSTimer *) timer {
    x_prev = motionManager.accelerometerData.acceleration.x;
    y_prev = motionManager.accelerometerData.acceleration.y;
    z_prev = motionManager.accelerometerData.acceleration.z;
    firstWait = true;
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
