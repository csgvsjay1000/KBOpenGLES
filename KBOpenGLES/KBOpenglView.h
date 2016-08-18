//
//  KBOpenglView.h
//  KBOpenGLES
//
//  Created by chengshenggen on 6/21/16.
//  Copyright © 2016 feng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>

@interface KBOpenglView : UIView

@property(nonatomic,strong) CMAttitude *referenceAttitude;
@property(nonatomic,strong) CMMotionManager *motionManager;

-(GLuint)rendImage:(UIImage *)image;

- (void)newFrameReadyAtTime:(GLuint)texture text2:(GLuint)texture2;

-(void)refreshFrame;

@end
