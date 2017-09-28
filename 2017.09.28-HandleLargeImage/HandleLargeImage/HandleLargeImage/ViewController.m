//
//  ViewController.m
//  HandleLargeImage
//
//  Created by zhiming9 on 2017/9/28.
//  Copyright © 2017年 zhiming9. All rights reserved.
//

#import "ViewController.h"

static  NSString *kImageName = @"large_leaves_70mp.jpg";
#define kDestImageSizeMB 60.0f;
#define kSourceImageTileSizeMB 20.0f;
#define bytesPerMB 1048576.0f //1024*1024
#define bytesPerPixel 4.0f
#define pixelsPerMB ( bytesPerMB / bytesPerPixel ) // 262144 pixels, for 4 bytes per pixel.
#define destTotalPixels kDestImageSizeMB * pixelsPerMB
#define tileTotalPixels kSourceImageTileSizeMB * pixelsPerMB
#define destSeemOverlap 2.0f // the numbers of pixels to overlap the seems where tiles meet.

@interface ViewController ()
{
    UIImage *sourceImage;//原图
    CGSize sourceResolution;//原图尺寸大小
    float sourceTotalPixels;//像素点
    float sourceTotalMB;//原图 未压缩  在内存里的大小   一个像素 4个字节  单位 MB
    float imageScale;// the ratio of the size of the input image to the output image.
    CGSize destResolution;
    CGContextRef destContext;
    CGRect sourceTile;
    // sub rect of the output image that is proportionate to the
    // size of the sourceTile.
    CGRect destTile;
    float sourceSeemOverlap;
    UIImage* destImage;
    UIImageView *progressView;
}
@property (strong) UIImage* destImage;
@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    progressView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:progressView];
    [NSThread detachNewThreadSelector:@selector(downsize:) toTarget:self withObject:nil];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark handle Large Image
//  https://developer.apple.com/library/content/samplecode/LargeImageDownsizing/Introduction/Intro.html
-(void)downsize:(id)arg {
    @autoreleasepool {
        sourceImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:kImageName ofType:nil]];
        if (sourceImage) {
            NSLog(@"No image");
        }
        sourceResolution.width = CGImageGetWidth(sourceImage.CGImage);
        sourceResolution.height = CGImageGetHeight(sourceImage.CGImage);
        sourceTotalPixels = sourceResolution.width * sourceResolution.height;
        sourceTotalMB = sourceTotalPixels * 4 / (1024*1024);//一个像素4个字节  除以1024*1024
        imageScale = 1024.0f*1024.0f / 4.0f * 60.f / sourceTotalPixels;
        // use the image scale to calcualte the output image width, height
        destResolution.width = (int)( sourceResolution.width * imageScale );
        destResolution.height = (int)( sourceResolution.height * imageScale );
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        int bytesPerRow = 4.0f * destResolution.width;
        void* destBitmapData = malloc( bytesPerRow * destResolution.height );
        if( destBitmapData == NULL ) NSLog(@"failed to allocate space for the output image!");
        destContext = CGBitmapContextCreate( destBitmapData, destResolution.width, destResolution.height, 8, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast );
        if( destContext == NULL ) {
            free( destBitmapData );
            NSLog(@"failed to create the output bitmap context!");
        }
        CGColorSpaceRelease( colorSpace );
        CGContextTranslateCTM( destContext, 0.0f, destResolution.height );
        CGContextScaleCTM( destContext, 1.0f, -1.0f );
        sourceTile.size.width = sourceResolution.width;
        sourceTile.size.height =  262144*20.f / sourceTile.size.width ;
        NSLog(@"source tile size: %f x %f",sourceTile.size.width, sourceTile.size.height);
        sourceTile.origin.x = 0.0f;
        destTile.size.width = destResolution.width;
        destTile.size.height = sourceTile.size.height * imageScale;
        destTile.origin.x = 0.0f;
        NSLog(@"dest tile size: %f x %f",destTile.size.width, destTile.size.height);
        // the source seem overlap is proportionate to the destination seem overlap.
        // this is the amount of pixels to overlap each tile as we assemble the ouput image.
        sourceSeemOverlap = (int)( ( destSeemOverlap / destResolution.height ) * sourceResolution.height );
        NSLog(@"dest seem overlap: %f, source seem overlap: %f",destSeemOverlap, sourceSeemOverlap);
        CGImageRef sourceTileImageRef;
        // calculate the number of read/write opertions required to assemble the
        // output image.
        int iterations = (int)( sourceResolution.height / sourceTile.size.height );
        // if tile height doesn't divide the image height evenly, add another iteration
        // to account for the remaining pixels.
        int remainder = (int)sourceResolution.height % (int)sourceTile.size.height;
        if( remainder ) iterations++;
        // add seem overlaps to the tiles, but save the original tile height for y coordinate calculations.
        float sourceTileHeightMinusOverlap = sourceTile.size.height;
        sourceTile.size.height += sourceSeemOverlap;
        destTile.size.height += destSeemOverlap;
        NSLog(@"beginning downsize. iterations: %d, tile height: %f, remainder height: %d", iterations, sourceTile.size.height,remainder );
        for( int y = 0; y < iterations; ++y ) {
            // create an autorelease pool to catch calls to -autorelease made within the downsize loop.
            @autoreleasepool {
                NSLog(@"iteration %d of %d",y+1,iterations);
                sourceTile.origin.y = y * sourceTileHeightMinusOverlap + sourceSeemOverlap;
                destTile.origin.y = ( destResolution.height ) - ( ( y + 1 ) * sourceTileHeightMinusOverlap * imageScale + destSeemOverlap );

                sourceTileImageRef = CGImageCreateWithImageInRect( sourceImage.CGImage, sourceTile );
                if( y == iterations - 1 && remainder ) {
                    float dify = destTile.size.height;
                    destTile.size.height = CGImageGetHeight( sourceTileImageRef ) * imageScale;
                    dify -= destTile.size.height;
                    destTile.origin.y += dify;
                }
                CGContextDrawImage( destContext, destTile, sourceTileImageRef );
                CGImageRelease( sourceTileImageRef );
            }
            // we reallocate the source image after the pool is drained since UIImage -imageNamed
            // returns us an autoreleased object.
            if( y < iterations - 1 ) {
                sourceImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:kImageName ofType:nil]];
                [self performSelectorOnMainThread:@selector(updateScrollView:) withObject:nil waitUntilDone:YES];
            }
        }
        NSLog(@"downsize complete.");
//        [self performSelectorOnMainThread:@selector(initializeScrollView:) withObject:nil waitUntilDone:YES];
        // free the context since its job is done. destImageRef retains the pixel data now.
        CGContextRelease( destContext );
    }
}

-(void)createImageFromContext {
    // create a CGImage from the offscreen image context
    CGImageRef destImageRef = CGBitmapContextCreateImage( destContext );
    if( destImageRef == NULL ) NSLog(@"destImageRef is null.");
    // wrap a UIImage around the CGImage
    self.destImage = [UIImage imageWithCGImage:destImageRef scale:1.0f orientation:UIImageOrientationDownMirrored];
    // release ownership of the CGImage, since destImage retains ownership of the object now.
    CGImageRelease( destImageRef );
    if( destImage == nil ) NSLog(@"destImage is nil.");
}

-(void)updateScrollView:(id)arg {
    [self createImageFromContext];
    // display the output image on the screen.
    progressView.image = destImage;
}




@end
