//
//  KBOpenglView.m
//  KBOpenGLES
//
//  Created by chengshenggen on 6/21/16.
//  Copyright © 2016 feng. All rights reserved.
//

#import "KBOpenglView.h"
#import <GLKit/GLKit.h>
#import "GLProgram.h"

@interface KBOpenglView (){
    GLProgram *displayProgram;
    
    EAGLContext *context;
    GLint displayPositionAttribute, displayTextureCoordinateAttribute;
    GLint displayInputTextureUniform;
    GLint transformUniform;
    GLint modelUniform,viewUniform,projUniform;
    GLint centerUniform,aspectRatioUniform,fsUniform,fxUniform;

    GLuint displayRenderbuffer, displayFramebuffer;
    
    CGSize sizeInPixels;
    
    CGSize pixelsWideSize;
    
    GLuint VBO, VAO, EBO;
    GLuint VBO_1, VAO_1, EBO_1;

    GLKVector3 cameraPos,cameraFront,cameraUp;
}

@end

@implementation KBOpenglView

#pragma mark Initialization and teardown

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

-(id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit{
    // Set scaling to account for Retina display
    if ([self respondsToSelector:@selector(setContentScaleFactor:)])
    {
        self.contentScaleFactor = [[UIScreen mainScreen] scale];
    }
    
    self.opaque = YES;
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:context];
    
    displayProgram = [[GLProgram alloc] initWithVertexShaderFilename:@"Vertex3_0" fragmentShaderFilename:@"Frag3_0"];
    if (!displayProgram.initialized)
    {
        [displayProgram addAttribute:@"position"];
        [displayProgram addAttribute:@"inputTextureCoordinate"];
        
        if (![displayProgram link])
        {
            NSString *progLog = [displayProgram programLog];
            NSLog(@"Program link log: %@", progLog);
            NSString *fragLog = [displayProgram fragmentShaderLog];
            NSLog(@"Fragment shader compile log: %@", fragLog);
            NSString *vertLog = [displayProgram vertexShaderLog];
            NSLog(@"Vertex shader compile log: %@", vertLog);
            displayProgram = nil;
            NSAssert(NO, @"Filter shader link failed");
        }
    }
    
    displayPositionAttribute = [displayProgram attributeIndex:@"position"];
    displayTextureCoordinateAttribute = [displayProgram attributeIndex:@"inputTextureCoordinate"];
    displayInputTextureUniform = [displayProgram uniformIndex:@"inputImageTexture"];
    
    modelUniform = [displayProgram uniformIndex:@"model"];
    viewUniform = [displayProgram uniformIndex:@"view"];
    projUniform = [displayProgram uniformIndex:@"projection"];

    centerUniform = [displayProgram uniformIndex:@"center"];
    aspectRatioUniform = [displayProgram uniformIndex:@"aspectRatio"];
    fsUniform = [displayProgram uniformIndex:@"fs"];
    fxUniform = [displayProgram uniformIndex:@"fx"];


    [displayProgram use];
    
    

    // Set up vertex data (and buffer(s)) and attribute pointers
    static GLfloat vertices[] = {
        // Positions          // Colors           // Texture Coords
        0.5f,  0.5f, 0.0f,   1.0f, 0.0f, 0.0f,   1.0f, 1.0f, // Top Right
        0.5f, -0.5f, 0.0f,   0.0f, 1.0f, 0.0f,   1.0f, 0.0f, // Bottom Right
        -0.5f, -0.5f, 0.0f,   0.0f, 0.0f, 1.0f,   0.0f, 0.0f, // Bottom Left
        -0.5f,  0.5f, 0.0f,   1.0f, 1.0f, 0.0f,   0.0f, 1.0f  // Top Left
    };
    static GLuint indices[] = {  // Note that we start from 0!
        0, 1, 3, // First Triangle
        1, 2, 3  // Second Triangle
    };
    
    glGenVertexArraysOES (1, &VAO);
    glGenBuffers(1, &VBO);
    glGenBuffers(1, &EBO);
    
    glBindVertexArrayOES(VAO);
    
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    // Position attribute
    glVertexAttribPointer(displayPositionAttribute, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), (GLvoid*)0);
    glEnableVertexAttribArray(displayPositionAttribute);
    glVertexAttribPointer(displayTextureCoordinateAttribute, 2, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), (GLvoid*)(6 * sizeof(GLfloat)));
    glEnableVertexAttribArray(displayTextureCoordinateAttribute);
    glBindVertexArrayOES(0);
    
    
    glUniform1i(displayInputTextureUniform, 4);
    
    static GLfloat vertices_1[] = {
        // Positions          // Colors           // Texture Coords
        0.5f,  0.5f, 0.0f,   1.0f, 0.0f, 0.0f,   1.0f, 1.0f, // Top Right
        0.5f, -0.5f, 0.0f,   0.0f, 1.0f, 0.0f,   1.0f, 0.0f, // Bottom Right
        -0.5f, -0.5f, 0.0f,   0.0f, 0.0f, 1.0f,   0.0f, 0.0f, // Bottom Left
        -0.5f,  0.5f, 0.0f,   1.0f, 1.0f, 0.0f,   0.0f, 1.0f  // Top Left
    };


    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // The frame buffer needs to be trashed and re-created when the view size changes.
    if (!CGSizeEqualToSize(self.bounds.size, CGSizeZero)) {
        [self destroyDisplayFramebuffer];
        [self createDisplayFramebuffer];
        
    }
}

-(void)refreshFrame{
    // The frame buffer needs to be trashed and re-created when the view size changes.
    if (!CGSizeEqualToSize(self.bounds.size, CGSizeZero)) {
        [self destroyDisplayFramebuffer];
        [self createDisplayFramebuffer];
    }
}


#pragma mark Managing the display FBOs

- (void)createDisplayFramebuffer{
    [EAGLContext setCurrentContext:context];
    
    glGenFramebuffers(1, &displayFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, displayFramebuffer);
    
    glGenRenderbuffers(1, &displayRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, displayRenderbuffer);
    
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    GLint backingWidth, backingHeight;
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    sizeInPixels.width = (CGFloat)backingWidth;
    sizeInPixels.height = (CGFloat)backingHeight;
    if ( (backingWidth == 0) || (backingHeight == 0) )
    {
        [self destroyDisplayFramebuffer];
        return;
    }
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, displayRenderbuffer);
    
    __unused GLuint framebufferCreationStatus = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSAssert(framebufferCreationStatus == GL_FRAMEBUFFER_COMPLETE, @"Failure with display framebuffer generation for display of size: %f, %f", self.bounds.size.width, self.bounds.size.height);
    
}

- (void)destroyDisplayFramebuffer;
{
    [EAGLContext setCurrentContext:context];
    
    if (displayFramebuffer)
    {
        glDeleteFramebuffers(1, &displayFramebuffer);
        displayFramebuffer = 0;
    }
    
    if (displayRenderbuffer)
    {
        glDeleteRenderbuffers(1, &displayRenderbuffer);
        displayRenderbuffer = 0;
    }
}

- (void)presentFramebuffer{
    [EAGLContext setCurrentContext:context];
    glBindRenderbuffer(GL_RENDERBUFFER, displayRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark GPUInput protocol

- (void)newFrameReadyAtTime:(GLuint)texture text2:(GLuint)texture2{
    
    [EAGLContext setCurrentContext:context];
    
    glBindFramebuffer(GL_FRAMEBUFFER, displayFramebuffer);
    
    glViewport(0, 0, sizeInPixels.width, sizeInPixels.height);
    
    glClearColor(0 , 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT );
    
    glActiveTexture(GL_TEXTURE4);
    
    
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);	// Set texture wrapping to GL_REPEAT (usually basic wrapping method)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    CMDeviceMotion *d = _motionManager.deviceMotion;
    CMAttitude *attitude = d.attitude;
    double cYaw = attitude.yaw;
    double cRoll = attitude.roll;
    
    GLKMatrix4 model = GLKMatrix4Identity;
    model = GLKMatrix4RotateZ(model, GLKMathDegreesToRadians(180));
    model = GLKMatrix4RotateX(model, GLKMathDegreesToRadians(20));
    
    model = GLKMatrix4RotateZ(model, cYaw);

    model = GLKMatrix4Translate(model, 0, 0.3, 0);

    GLKMatrix4 viewM = GLKMatrix4Identity;
    
    GLKMatrix4 projection = GLKMatrix4Identity;
    projection = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45), sizeInPixels.width/sizeInPixels.height, 0.1, 100);

    
    
    

    
    float degress_x = GLKMathRadiansToDegrees(cRoll); //对Y轴旋转
    float degress_y = GLKMathRadiansToDegrees(cYaw);  //对x轴旋转
    
    GLKVector2 center;
    center.x = 0.5;
    center.y = 0.5;
    glUniform2fv(centerUniform, 1, center.v);
    glUniform1f(aspectRatioUniform, pixelsWideSize.width/pixelsWideSize.height);
    glUniform1f(fsUniform, cRoll);
    glUniform1f(fxUniform, cYaw);

//    GLKVector3 front;
//    front.x = cos(cYaw)*cos(cRoll);
//    front.y = sin(cYaw)*sin(cRoll);
//    front.z = -1;
//    
//    
//    
//    cameraFront = GLKVector3Normalize(front);
    cameraPos = GLKVector3Make(-0, -1, cRoll);
    cameraFront = GLKVector3Make(0, 1, -cRoll);

//    cameraPos = GLKVector3Make(-cYaw, -1, 1);
//    cameraFront = GLKVector3Make(cYaw, 1, -1);
    
    float a = 1,b = 1,c;
    
    GLKVector3 temp = GLKVector3Make(1, 0, 0);
    
    cameraUp = GLKVector3CrossProduct(temp, cameraFront);
    
    GLKVector3 cameraTarget = GLKVector3Add(cameraPos, cameraFront);
    
    
    viewM = GLKMatrix4MakeLookAt(cameraPos.x, cameraPos.y, cameraPos.z, cameraTarget.x, cameraTarget.y, cameraTarget.z, cameraUp.x, cameraUp.y, cameraUp.z);
    
    glUniformMatrix4fv(modelUniform, 1, GL_FALSE, model.m);
    glUniformMatrix4fv(viewUniform, 1, GL_FALSE, viewM.m);
    glUniformMatrix4fv(projUniform, 1, GL_FALSE, projection.m);

    glBindVertexArrayOES(VAO);
    glDrawElements(GL_TRIANGLE_STRIP, 6, GL_UNSIGNED_INT, 0);
    glBindVertexArrayOES(0);
    
    
    glBindVertexArrayOES(VAO);
    
    glBindTexture(GL_TEXTURE_2D, texture2);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);	// Set texture wrapping to GL_REPEAT (usually basic wrapping method)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    model = GLKMatrix4Identity;
    model = GLKMatrix4RotateZ(model, GLKMathDegreesToRadians(180));
    model = GLKMatrix4Translate(model, 0, -0.3-(cRoll/10.0), 0);
    model = GLKMatrix4RotateX(model, GLKMathDegreesToRadians(-25));

    viewM = GLKMatrix4Identity;
    
    projection = GLKMatrix4Identity;
    
    cameraPos = GLKVector3Make(0, 0, 2.0+cRoll*3);
    cameraFront = GLKVector3Make(0, 0, -(2.0+cRoll*3));
    
    temp = GLKVector3Make(1, 0, 0);
    
    cameraUp = GLKVector3CrossProduct(temp, cameraFront);
    
    cameraTarget = GLKVector3Add(cameraPos, cameraFront);
    
    
    viewM = GLKMatrix4MakeLookAt(cameraPos.x, cameraPos.y, cameraPos.z, cameraTarget.x, cameraTarget.y, cameraTarget.z, cameraUp.x, cameraUp.y, cameraUp.z);
    
    projection = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45), sizeInPixels.width/sizeInPixels.height, 0.1, 100);
    
    glUniformMatrix4fv(modelUniform, 1, GL_FALSE, model.m);
    glUniformMatrix4fv(viewUniform, 1, GL_FALSE, viewM.m);
    glUniformMatrix4fv(projUniform, 1, GL_FALSE, projection.m);
    
    glDrawElements(GL_TRIANGLE_STRIP, 6, GL_UNSIGNED_INT, 0);
    glBindVertexArrayOES(0);
    
    
    [self presentFramebuffer];
    
}

-(GLuint)rendImage:(UIImage *)image{
    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glActiveTexture(GL_TEXTURE0);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);	// Set texture wrapping to GL_REPEAT (usually basic wrapping method)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    
    void *bitmapData;
    size_t pixelsWide;
    size_t pixelsHigh;
    [[self class] loadImageWithName:image bitmapData_p:&bitmapData pixelsWide:&pixelsWide pixelsHigh:&pixelsHigh];
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)pixelsWide, (int)pixelsHigh, 0, GL_RGBA, GL_UNSIGNED_BYTE, bitmapData);
    free(bitmapData);
    bitmapData = NULL;
    glBindTexture(GL_TEXTURE_2D, 0);
    pixelsWideSize = CGSizeMake(pixelsWide, pixelsHigh);
    return texture;
}

#pragma mark - private methods
+(void)loadImageWithName:(UIImage *)image1 bitmapData_p:(void **)bitmapData pixelsWide:(size_t *)pixelsWide_p pixelsHigh:(size_t *)pixelsHigh_p{
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"1234" ofType:@"jpg"];
////
//    UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
    
    CGImageRef cgimg = image1.CGImage;
    
    CGContextRef bitmapContext = NULL;
    size_t pixelsWide;
    size_t pixelsHigh;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    pixelsWide = CGImageGetWidth(cgimg);
    pixelsHigh = CGImageGetHeight(cgimg);
    
    CGSize pixelSizeToUseForTexture;
    CGFloat powerClosestToWidth = ceil(log2(pixelsWide));
    CGFloat powerClosestToHeight = ceil(log2(pixelsHigh));
    
    pixelSizeToUseForTexture = CGSizeMake(pow(2.0, powerClosestToWidth), pow(2.0, powerClosestToHeight));
    pixelsWide = pixelSizeToUseForTexture.width;
    pixelsHigh = pixelSizeToUseForTexture.height;
    
    size_t bitsPerComponent_t = CGImageGetBitsPerComponent(cgimg);
    *bitmapData = malloc(pixelsWide*pixelsHigh*4);
    bitmapContext = CGBitmapContextCreate(*bitmapData, pixelsWide, pixelsHigh, bitsPerComponent_t, pixelsWide*4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(bitmapContext, CGRectMake(0, 0, pixelsWide, pixelsHigh), cgimg);
    
    CGContextRelease(bitmapContext);
    
    *pixelsHigh_p = pixelsHigh;
    *pixelsWide_p = pixelsWide;
}



@end
