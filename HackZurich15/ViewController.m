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
#define NOISE_THRESHOLD 0.02
#define MAX_A -0.05
#define FADE_SCALE 1
#define PMAX_LIMIT 3
#define WINDOW_SIZE 8
#define THRESHOLD_SPACING 0.04

struct PointD {
    double x;
    double y;
};
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *upArrowButton;
@property (weak, nonatomic) IBOutlet UIButton *downArrowButton;
@property (weak, nonatomic) IBOutlet UIImageView *clockImage;

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
@property CAShapeLayer *selectedLayer;
@property int recordStartHit;
@property BOOL wantsToRecord;
@property NSOperationQueue *queue;
@property CMMotionManager *motionManager;
@property BOOL wantsAlready;
@end

// Constants

#define numberOfTypes ((int) 6)
#define maxNumberOfBars (int)2
#define maxNumberOfHitsPerBar (int)1024
//#define gridHelperGridSize (int)1
#define bpmStep ((int)10)

// End

bool isRecording;
double x_prev;
double y_prev;
double z_prev;
BOOL firstWait;
int currentType = 0;
int currentHit = 0;
BOOL looper[numberOfTypes][(int)(maxNumberOfBars*maxNumberOfHitsPerBar)];
int state, x, waveStartPos;
struct PointD p1;
double a, threshold;
double v[WINDOW_SIZE];


@implementation ViewController

/* GETTER AND SETTER */

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

/* INITIALIZATION */

- (void)viewDidLoad {
    // FUNCTION CALLS
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
    
    // INIT DATA
    self.bpm = 120;
    self.nBars = 2;
    isRecording = false;
    _motionManager = [[CMMotionManager alloc] init];
        
    _motionManager.accelerometerUpdateInterval = 0.01;  // 20 Hz
    [_motionManager startAccelerometerUpdates];
    _metronomeQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(setValues:) userInfo:nil repeats:NO];
    
    // INIT AUDIO
    [[AudioSamplePlayer sharedInstance] preloadAudioSample:@"tick"];
    [[AudioSamplePlayer sharedInstance] preloadAudioSample:@"Sound0"];
    [[AudioSamplePlayer sharedInstance] preloadAudioSample:@"Sound1"];
    [[AudioSamplePlayer sharedInstance] preloadAudioSample:@"Sound2"];
    [[AudioSamplePlayer sharedInstance] preloadAudioSample:@"Sound3"];
    [[AudioSamplePlayer sharedInstance] preloadAudioSample:@"Sound4"];
    [[AudioSamplePlayer sharedInstance] preloadAudioSample:@"Sound5"];
    
    // INIT UI
    

    self.bpmLabel.text = [NSString stringWithFormat:@"%d", self.bpm];
    self.circle5.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 0.5);
    self.circle1.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 0.5);
    self.circle2.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 0.5);
    self.circle3.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 0.5);
    self.circle4.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.5, 0.5);
    firstWait = false;
    self.intervalTimer= [NSTimer scheduledTimerWithTimeInterval:self.refreshInterval target:self selector:@selector(getValues:) userInfo:nil repeats:YES];
    self.queue         = [[NSOperationQueue  alloc] init];
    _motionManager.accelerometerUpdateInterval = self.refreshInterval;  // 20 Hz

    [self.motionManager startAccelerometerUpdatesToQueue:self.queue withHandler:
          ^(CMAccelerometerData *data, NSError  *error) {
                processAccelerometer(&state, ++x, data.acceleration.z + 1, &threshold, &a, &waveStartPos, v, &p1, self);
                 }];
    

    
    [self startSpinningWith:(0.0f)];
}
-(void)viewDidAppear:(BOOL)animated{
    _selectedLayer = [CAShapeLayer layer];
    [_selectedLayer setPath:[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(2, 2, self.mainButton.frame.size.width-4, self.mainButton.frame.size.height-4)] CGPath]];
    [self.mainButton.layer addSublayer:_selectedLayer];
    [self.selectedLayer setOpacity:0];
    [_selectedLayer setFillColor:[UIColor whiteColor].CGColor];
}
-(void)setBpmAndUpdateTimer:(int) bpmVal{
    self.bpm = bpmVal;
    if (isRecording) {
        //[self updateSpinning];
    }
    [self.intervalTimer invalidate];
    self.intervalTimer = [NSTimer scheduledTimerWithTimeInterval:self.refreshInterval target:self selector:@selector(getValues:) userInfo:nil repeats:YES];
    
}

- (void) startSpinningWith:(float) offset {
    //self.upArrowButton.enabled = NO;
    //self.downArrowButton.enabled = NO;
        CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        animation.fromValue = [NSNumber numberWithFloat:0.0f+offset];
        animation.toValue = [NSNumber numberWithFloat: 2*M_PI];
        animation.duration = self.roundTime*(1 - offset/(2*M_PI));
        
        [self.mainButton.layer addAnimation:animation forKey:@"SpinAnimation"];
        self.circleTimer = [NSTimer scheduledTimerWithTimeInterval:self.roundTime*(1 - offset/(2*M_PI)) target:self selector:@selector(stopSpinning:) userInfo:nil repeats:NO];
    
}

//UNUSED
-(void)updateSpinningWithHit:(double)hit{
    float currentOffset = (double)currentHit*2.0f*M_PI/((double)maxNumberOfHitsPerBar*(double)self.nBars);
    isRecording = false;
    [self.circleTimer invalidate];
    [self.mainButton.layer removeAllAnimations];
    [self startSpinningWith:currentOffset];
}

- (void) stopSpinning:(NSTimer *) timer {
    if (isRecording)
    {
        isRecording = false;
        self.upArrowButton.enabled = YES;
        self.downArrowButton.enabled =YES;
        currentType++;
        if (currentType>=numberOfTypes) {
            currentType = 0;
        }
        [self animateButtons:currentType];
        [self.mainButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Button%d",currentType]]forState:UIControlStateNormal];
    
        [self.upArrowButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Plus%d",currentType]]forState:UIControlStateNormal];
    
        [self.downArrowButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Minus%d",currentType]]forState:UIControlStateNormal];
        
        [self doneRecordingAnimation];
    }
}

/* LOGIC (RECORDING) */

- (void)recordSound {
    /*int gridRest = currentHit%gridHelperGridSize; // Ungenauigkeit beim Treffen des Grids
    int gridPos = (currentHit-gridRest)/gridHelperGridSize; // Position of beat in a grid
    
    if (gridRest < gridHelperGridSize/2) // if in lower half of grid
        gridPos--; // set to ealier beat
    if (gridPos < 0) // if negative
        gridPos = (self.nBars*maxNumberOfHitsPerBar)/gridHelperGridSize; // set to last beat
    
    NSLog(@"Hit with %d at %d/%d set to grid %d/%d", currentType, currentHit, maxNumberOfHitsPerBar*self.nBars, gridPos, (self.nBars*maxNumberOfHitsPerBar)/gridHelperGridSize);*/
    
    looper[currentType][currentHit-2] = true;
}

-(void) getValues:(NSTimer *) timer {
    // INCREASE COUNTER
    if (currentHit<maxNumberOfHitsPerBar*self.nBars) {
        currentHit++;
    }
    else {
        currentHit=0;
    }
    
    // IF AT START POSITION
    if (currentHit == 0 && self.wantsToRecord)
    {
        isRecording = true;
        self.wantsToRecord = false;
        [self isRecordingAnimation];
    }
    if (currentHit == 0)
    {
        [self startSpinningWith:(0.0f)];
    }
    
    // METRONOME
    if ((currentHit*4)%maxNumberOfHitsPerBar==0) {
        //[self updateSpinning];
    }
    if(currentHit% maxNumberOfHitsPerBar==0){
        [self playFirstMetro];
    }else if (currentHit*4%maxNumberOfHitsPerBar==0){
        [self playMetro];
    }
    
    // PLAY SOUND
    for (int x=0;x<numberOfTypes;x++) {
        if (looper[x][currentHit]) {
            [self playSound:x];
        }
    }
}

-(void) deleteTrack:(int)num {
    for (int x=0;x<(int)(maxNumberOfBars*maxNumberOfHitsPerBar);x++) {
        looper[num][x] = false;
    }
}

/* UI */
- (void) onPeak: (double) amplitude{
    [self performSelectorOnMainThread:@selector(buttonpress:) withObject:self waitUntilDone:NO];
}
- (IBAction)buttonpress:(id)sender {
    
    if (!isRecording)
    {
        if (self.wantsToRecord && maxNumberOfHitsPerBar*self.nBars-currentHit < maxNumberOfHitsPerBar/64) // If close to start of recording
            [self recordSound];
        self.wantsToRecord = true;
        [self wantsToRecordAnimation];
    }
    else
    {
        [self playSound:currentType];

        [self recordSound];
    }
}

- (IBAction)bpmUp:(id)sender {
    if (!isRecording) {
        [self setBpmAndUpdateTimer:self.bpm+bpmStep];
        [self.bpmLabel setText:[NSString stringWithFormat:@"%d",self.bpm]];
    }
    
}
- (IBAction)bpmDown:(id)sender {
    if (!isRecording) {
        [self setBpmAndUpdateTimer:self.bpm-bpmStep];
        [self.bpmLabel setText:[NSString stringWithFormat:@"%d",self.bpm]];
    }
    
}

/* PLAYING SOUND */

- (void)playSound:(int) soundType {
    [self pulse:soundType];
    dispatch_async(_metronomeQueue, ^{
        [[AudioSamplePlayer sharedInstance] playAudioSample:[NSString stringWithFormat:@"Sound%d",soundType]];
        
    });
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


/* ANIMATION */


-(void) setValues:(NSTimer *) timer { // WAS FÜR EIN NAME DUDE
    x_prev = _motionManager.accelerometerData.acceleration.x;
    y_prev = _motionManager.accelerometerData.acceleration.y;
    z_prev = _motionManager.accelerometerData.acceleration.z;
    firstWait = true;
}
//RECORDING
- (void)wantsToRecordAnimation {
    self.downArrowButton.enabled = NO;
    self.upArrowButton.enabled = NO;
    NSLog(@"yo");
    [_selectedLayer setOpacity:0.4];
    if (!self.wantsAlready) {
        self.wantsAlready = YES;
        double howfar = (double)currentHit/(double)(maxNumberOfHitsPerBar*self.nBars);
        NSLog(@"howfar: %db",currentHit);
        NSLog(@"%fb",(double)(maxNumberOfHitsPerBar*self.nBars-currentHit)*(double)(15*maxNumberOfHitsPerBar)/(double)self.bpm);
        self.mainButton.transform = CGAffineTransformMakeScale(howfar, howfar);
        [UIView animateWithDuration:(double)(maxNumberOfHitsPerBar*self.nBars-currentHit)*(double)(60*4)/(double)(self.bpm*maxNumberOfHitsPerBar) animations:^{
            self.mainButton.transform = CGAffineTransformMakeScale(1, 1);
        }
                         completion:^(BOOL finished){
        }];
    }
    
}
- (void)doneRecordingAnimation {
    self.downArrowButton.enabled = YES;
    self.upArrowButton.enabled = YES;

    [UIView animateWithDuration:0.5 delay:0 options:nil  animations:^{
        [_selectedLayer setOpacity:0];
    } completion:^(BOOL finished) {
        
        //code for completion
    }];
}
- (void)isRecordingAnimation {
    
    self.downArrowButton.enabled = NO;
    self.upArrowButton.enabled = NO;
    
    [UIView animateWithDuration:0.5 delay:0 options:nil  animations:^{
        [_selectedLayer setOpacity:0.8];

    } completion:^(BOOL finished) {
        //code for completion
    }];
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

- (IBAction)circlePress0:(id)sender {
    if (!isRecording)
    {
    [self animateButtons:0];
    currentType = 0;
    [self deleteTrack:0];
    [self.mainButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Button%d",0]]forState:UIControlStateNormal];
    
    [self.upArrowButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Plus%d",0]]forState:UIControlStateNormal];
    
    [self.downArrowButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Minus%d",0]]forState:UIControlStateNormal];
    }

}
- (IBAction)circlePress1:(id)sender {
    if (!isRecording)
    {
   [self animateButtons:1];
    currentType = 1;
    [self deleteTrack:1];
    [self.mainButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Button%d",1]]forState:UIControlStateNormal];
    
    [self.upArrowButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Plus%d",1]]forState:UIControlStateNormal];
    
    [self.downArrowButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Minus%d",1]]forState:UIControlStateNormal];
    }
}
- (IBAction)circlePress2:(id)sender {
    if (!isRecording)
    {
    [self animateButtons:2];
    currentType = 2;
    [self deleteTrack:2];
    [self.mainButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Button%d",2]]forState:UIControlStateNormal];
    
    [self.upArrowButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Plus%d",2]]forState:UIControlStateNormal];
    
    [self.downArrowButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Minus%d",2]]forState:UIControlStateNormal];
    }
}
- (IBAction)circlePress3:(id)sender {
    if (!isRecording)
    {
    [self animateButtons:3];
    currentType = 3;
    [self deleteTrack:3];
    [self.mainButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Button%d",3]]forState:UIControlStateNormal];
    
    [self.upArrowButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Plus%d",3]]forState:UIControlStateNormal];
    
    [self.downArrowButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Minus%d",3]]forState:UIControlStateNormal];
    }
}
- (IBAction)circlePress4:(id)sender {
    if (!isRecording)
    {
    [self animateButtons:4];
    currentType = 4;
    [self deleteTrack:4];
    [self.mainButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Button%d",4]]forState:UIControlStateNormal];
    
    [self.upArrowButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Plus%d",4]]forState:UIControlStateNormal];
    
    [self.downArrowButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Minus%d",4]]forState:UIControlStateNormal];
    }
}
- (IBAction)circlePress5:(id)sender {
    if (!isRecording)
    {
    [self animateButtons:5];
    currentType = 5;
    [self deleteTrack:5];
    [self.mainButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Button%d",5]]forState:UIControlStateNormal];
    
    [self.upArrowButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Plus%d",5]]forState:UIControlStateNormal];
    
    [self.downArrowButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"Minus%d",5]]forState:UIControlStateNormal];
    }
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
//accele

struct PointD findPeak(double v[], int end) {
        // Find maximum
        double max = 0;
        int maxI = 0;
        
        for (int i = 0; i <= end; i++) {
                if (fabs(v[i]) > fabs(max)) {
                        max = v[i];
                        maxI = i;
                    }
            }
        
        struct PointD ret;
        ret.x = maxI;
        ret.y = max;
        
        // If possible, fit parabola to find better maximum
        if (maxI > 0 && maxI < end) {
                // Prepare LSE to determine parabola from three points
                int x1 = maxI - 1,
                    x2 = maxI,
                    x3 = maxI + 1;
                
                double y1 = v[x1],
                       y2 = v[x2],
                       y3 = v[x3];
                
                // Solve LSE
                double a = -(x1*y2 - x2*y1 - x1*y3 + x3*y1 + x2*y3 - x3*y2)/((x1 - x2)*(x1*x2 - x1*x3 - x2*x3 + x3*x3)),
                       b = (x1*x1*y2 - x2*x2*y1 - x1*x1*y3 + x3*x3*y1 + x2*x2*y3 - x3*x3*y2)/((x1 - x2)*(x1*x2 - x1*x3 - x2*x3 + x3*x3)),
                       c = -(- y3*x1*x1*x2 + y2*x1*x1*x3 + y3*x1*x2*x2 - y2*x1*x3*x3 - y1*x2*x2*x3 + y1*x2*x3*x3)/((x1 - x2)*(x1*x2 - x1*x3 - x2*x3 + x3*x3));
                
                // Find maximum of parabola with first derivative
                double pmaxX = - b / (2 * a);
                double pmax = a * pmaxX * pmaxX + b * pmaxX + c;
        
                // Limit maximum from parabola to a multiple of regular maximum
                pmax = splitSign(pmax) * MIN(fabs(pmax), PMAX_LIMIT * fabs(max));
                
                
                // If parabola maximum exists, is near the peak we analyze and higher than the regular maximum, use it
                if (!isnan(pmax) &&
                                !isinf(pmax) &&
                                fabs(pmax) > fabs(max) &&
                                splitSign(pmax) == splitSign(max) &&
                                pmaxX >= 0 && pmaxX < end)
                    {
                            ret.x = pmaxX;
                            ret.y = pmax;
                        }
            }
        
        return ret;
        
}

// Sign function that doesn't return zero
int splitSign(double x) {
        if (x >= 0.) return 1;
        else return -1;
}

void processAccelerometer(int *state, int x, double y, double *threshold, double *a, int *waveStartPos, double v[WINDOW_SIZE], struct PointD *p1, id me) {
        double prevY = v[MAX(MIN(x - *waveStartPos - 1, WINDOW_SIZE - 1), 0)];
        
        switch (*state) {
                    case 0: // READY
                        // Calculate threshold function
                        *threshold = MAX(fabs(p1->y) * (double)exp((*a) * (double)(x - p1->x)) + THRESHOLD_SPACING, NOISE_THRESHOLD);
                        // if (p1->x != 0) NSLog(@"p1y: %.3f p1x: %f a: %.4f x: %d", p1->y, p1->x, *a, x);
                        
                        // Trigger peak when threshold is surpassed
                        if (fabs(y) > (*threshold)) {
                                // Report peak
                                [me onPeak: fabs(y)];

                                *waveStartPos = x;
                                v[0] = y;
                                *state = 1; // PEAK
                            }
                        break;
                    case 1: // PEAK
                        // Record data
                        if (x - *waveStartPos < WINDOW_SIZE) {
                                v[x - *waveStartPos] = y;
                            }
                        
                        // Wait for peak to pass
                        if (splitSign(y) != splitSign(prevY)) {
                                // Determine actual peak value
                                *p1 = findPeak(v, MIN(x - *waveStartPos, WINDOW_SIZE - 1));
                                p1->x += *waveStartPos;
                                
                                NSLog(@"Peak detected (x = %d  t = %.4f)", x, *threshold);
                
                                *waveStartPos = x;
                                v[0] = y;
                                *state = 2; // REVERB1
                            }
                        break;
                    case 2: // REVERB1
                        // Record data
                        if (x - *waveStartPos < WINDOW_SIZE) {
                                v[x - *waveStartPos] = y;
                            }
                        
                        // Wait for first reverb to pass
                        if (splitSign(y) != splitSign(prevY)) {
                                // Determine actual peak value
                                struct PointD r1 = findPeak(v, MIN(x - *waveStartPos, WINDOW_SIZE - 1));
                                
                                if (r1.y > p1->y) {
                                        *p1 = r1;
                                        p1->x += *waveStartPos;
                                    }
                                                                
                                
                                *waveStartPos = x;
                                v[0] = y;
                                *state = 3; // REVERB2
                            }
                        break;
                    case 3: // REVERB2
                        // Record data
                        if (x - *waveStartPos < WINDOW_SIZE) {
                                v[x - *waveStartPos] = y;
                            }
                        
                        // Wait for second reverb to pass
                        if (splitSign(y) != splitSign(prevY)) {
                                // Determine actual reverb value
                                struct PointD p2 = findPeak(v, MIN(x - *waveStartPos, WINDOW_SIZE - 1));
                                p2.x += *waveStartPos;
                                
                                // Calculate threshold function
                                *a = MIN(log(fabs(p2.y / p1->y)) / (p2.x - p1->x) / (double)FADE_SCALE, (double)MAX_A);
                                if (isinf(*a)) *a = MAX_A;
                                
                                //NSLog(@"p1->x = %.f  p1->y = % 06.3f  p2.x = %.f  p2.y = % 06.4f  a = % 06.3f", p1->x, p1->y, p2.x, p2.y, *a);
                                
                                *state = 0; // READY
                            }
                        break;
            }
        
        //NSLog(@"% 05.3f % 05.3f", y, *threshold);
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
