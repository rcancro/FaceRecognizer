//
//  FaceDetector.h
//  FaceRecognition
//
//  Created by Michael Peterson on 2012-11-16.
//
//

#import <Foundation/Foundation.h>
#import <opencv2/highgui/cap_ios.h>
#import <opencv2/contrib/contrib.hpp>

@class NSManagedObjectID;

typedef void (^FaceDetectionProgress)(int photoCount, int totalPhotos);
typedef void (^FaceDetectionCompletion)();

@interface FaceDetector : NSObject
{
}

+ (FaceDetector *)sharedInstance;

- (NSArray *)findFacesInImage:(UIImage *)image;
- (void)startLookingForFaces:(FaceDetectionProgress)progressBlock completionBlock:(FaceDetectionCompletion)completionBlock;
- (BOOL)trainRecognizer;

- (NSDictionary *)predictFace:(NSManagedObjectID *)faceId;

@end
