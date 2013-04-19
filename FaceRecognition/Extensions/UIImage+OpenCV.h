//
//  UIImage+OpenCV.h
//  FaceRecognition
//
//  Created by ricky cancro on 4/19/13.
//
//

#import <Foundation/Foundation.h>
#import <opencv2/highgui/cap_ios.h>

@interface UIImage(OpenCV)
- (cv::Mat)asGrayScaleCVMat;
@end
