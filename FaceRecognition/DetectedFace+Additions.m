//
//  Face+Additions.m
//  FaceRecognition
//
//  Created by ricky cancro on 4/9/13.
//
//

#import "DetectedFace+Additions.h"
#import "Photo.h"

@implementation DetectedFace(Additions)

- (void)setRect:(CGRect)r
{
    self.x = [NSNumber numberWithFloat:r.origin.x];
    self.y = [NSNumber numberWithFloat:r.origin.y];
    self.width = [NSNumber numberWithFloat:r.size.width];
    self.height = [NSNumber numberWithFloat:r.size.height];
}

- (CGRect)faceRect
{
    return CGRectMake([self.x floatValue], [self.y floatValue], [self.width floatValue], [self.height floatValue]);
}


- (UIImage *)faceFromImage
{
    UIImage *image = [UIImage imageNamed:self.photo.imagePath];
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], [self faceRect]);
    image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return image;
}

- (UIImage *)faceFromImageOfSize:(CGSize)sz
{
    UIImage *image = [self faceFromImage];
    UIGraphicsBeginImageContextWithOptions(sz, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, sz.width, sz.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
