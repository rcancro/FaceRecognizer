//
//  FaceDetector.h
//  FaceRecognition
//
//  Created by Michael Peterson on 2012-11-16.
//
//

#import <Foundation/Foundation.h>

@class NSManagedObjectID;


@interface FaceDetector : NSObject

+ (FaceDetector *)sharedInstance;
- (NSArray *)findFacesInImage:(UIImage *)image;

@end
