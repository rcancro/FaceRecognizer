//
//  FaceDetectionOperation.h
//  FaceRecognition
//
//  Created by ricky cancro on 4/19/13.
//
//

#import <Foundation/Foundation.h>

//typedef void (^FaceDetectionStart)(NSManagedObjectContext *context);
//typedef void (^FaceDetectionProgress)(int photoCount, int totalPhotos);

typedef void (^FaceDetectionUIStart)();
typedef void (^FaceDetectionStart)(NSManagedObjectContext *context);

typedef void (^FaceDetectionUIProgress)(int photoCount, int totalPhotos);
typedef void (^FaceDetectionProgress)(NSManagedObjectContext *context);

typedef void (^FaceDetectionUICompletion)();
typedef void (^FaceDetectionCompletion)(NSManagedObjectContext *context);


@interface FaceDetectionOperation : NSOperation

@property (nonatomic, copy) FaceDetectionUIStart startupUIBlock;
@property (nonatomic, copy) FaceDetectionStart startupBgBlock;

@property (nonatomic, copy) FaceDetectionUIProgress progressUIBlock;
@property (nonatomic, copy) FaceDetectionProgress progressBgBlock;

@property (nonatomic, copy) FaceDetectionUICompletion completionUIBlock;
@property (nonatomic, copy) FaceDetectionCompletion completionBgBlock;

@end
