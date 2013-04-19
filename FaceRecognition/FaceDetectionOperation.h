//
//  FaceDetectionOperation.h
//  FaceRecognition
//
//  Created by ricky cancro on 4/19/13.
//
//

#import <Foundation/Foundation.h>

typedef void (^FaceDetectionStart)(NSManagedObjectContext *context);
typedef void (^FaceDetectionProgress)(int photoCount, int totalPhotos);

@interface FaceDetectionOperation : NSOperation
@property (nonatomic, copy) FaceDetectionProgress progressUIBlock;
@property (nonatomic, copy) FaceDetectionStart startupBlock;

@end
