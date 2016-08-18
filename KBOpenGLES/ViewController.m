//
//  ViewController.m
//  KBOpenGLES
//
//  Created by feng on 16/6/15.
//  Copyright © 2016年 feng. All rights reserved.
//

#import "ViewController.h"
#import "KBOpenglView.h"


@interface ViewController (){
    KBOpenglView *glView;
    KBOpenglView *glView2;
    CADisplayLink *displayLink;
    GLuint texture;
    GLuint texture2;
    
    
    GLuint texture3;
    GLuint texture4;
}

@property(nonatomic,strong) CMAttitude *referenceAttitude;
@property(nonatomic,strong) CMMotionManager *motionManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    glView2 = [[KBOpenglView alloc] initWithFrame:CGRectZero];

    [self.view addSubview:glView2];

    texture2 = [glView2 rendImage:[UIImage imageNamed:@"1234.jpg"]];
    texture4 = [glView2 rendImage:[UIImage imageNamed:@"1234.jpg"]];

    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkPresent)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    displayLink.paused = YES;
    displayLink.frameInterval = 2;
    glView = [[KBOpenglView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:glView];
    texture = [glView rendImage:[UIImage imageNamed:@"1234.jpg"]];
    
    texture3 = [glView rendImage:[UIImage imageNamed:@"1234.jpg"]];


    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskLandscape;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    [self startDeviceMotion];
    
    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.view.frame.size.height;
    
    glView.frame = CGRectMake(0, 0, width / 2 - 1, height);
    glView2.frame = CGRectMake(width / 2 + 2, 0, width / 2 - 1, height);

    [glView refreshFrame];
    [glView2 refreshFrame];

    displayLink.paused = NO;

    
}

-(void)displayLinkPresent{
    [glView newFrameReadyAtTime:texture text2:texture3];
    [glView2 newFrameReadyAtTime:texture2 text2:texture4];

}

#pragma mark - private methods
- (void)startDeviceMotion {
    
    _motionManager = [[CMMotionManager alloc] init];
    _referenceAttitude = nil;
    _motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;
    _motionManager.gyroUpdateInterval = 1.0f / 60;
    _motionManager.showsDeviceMovementDisplay = YES;
    
    [_motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical];
    
    _referenceAttitude = _motionManager.deviceMotion.attitude; // Maybe nil actually. reset it
    
    glView.motionManager = _motionManager;
    glView.referenceAttitude = _referenceAttitude;

    glView2.motionManager = _motionManager;
    glView2.referenceAttitude = _referenceAttitude;
}

-(void)stopDeviceMotion{
    [_motionManager stopDeviceMotionUpdates];
    _referenceAttitude = nil;
}

@end
