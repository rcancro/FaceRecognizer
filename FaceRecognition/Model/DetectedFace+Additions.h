//
//  Face+Additions.h
//  FaceRecognition
//
//  Created by ricky cancro on 4/9/13.
//
//

#import "DetectedFace.h"

@interface DetectedFace(Additions)

- (void)setRect:(CGRect)r;
- (CGRect)faceRect;

- (UIImage *)faceFromImage;
- (UIImage *)faceFromImageOfSize:(CGSize)sz;
@end
