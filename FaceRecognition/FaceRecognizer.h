//
//  FaceRecognizer.h
//  FaceRecognition
//
//  Created by ricky cancro on 4/19/13.
//
//

#import <Foundation/Foundation.h>

@interface FaceRecognizer : NSObject

+ (FaceRecognizer *)sharedInstance;

- (BOOL)trainRecognizer:(NSDictionary *)labelsAndImages;
- (NSDictionary *)predictionForImage:(UIImage *)face;

@end
