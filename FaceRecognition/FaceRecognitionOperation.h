//
//  FaceRecognitionOperation.h
//  FaceRecognition
//
//  Created by ricky cancro on 4/19/13.
//
//

#import <Foundation/Foundation.h>

typedef void (^FaceRecognitionUIStart)();
typedef void (^FaceRecognitionStart)(NSManagedObjectContext *context);

typedef void (^FaceRecognitionUIProgress)(int photoCount, int totalPhotos);
typedef void (^FaceRecognitionProgress)(NSManagedObjectContext *context);

typedef void (^FaceRecognitionUICompletion)(NSDictionary *predictions);
typedef void (^FaceRecognitionCompletion)(NSManagedObjectContext *context);

extern const double kDefaultConfidenceThreshold;

@interface FaceRecognitionOperation : NSOperation

@property (nonatomic, copy) FaceRecognitionStart startupBgBlock;
@property (nonatomic, copy) FaceRecognitionUIStart startupUIBlock;

@property (nonatomic, copy) FaceRecognitionProgress progressBgBlock;
@property (nonatomic, copy) FaceRecognitionUIProgress progressUIBlock;

@property (nonatomic, copy) FaceRecognitionUICompletion completionUIBlock;
// don't use the built in completion block so we can make sure this runs on a bg thread
@property (nonatomic, copy) FaceRecognitionCompletion completionBgBlock;

@property (nonatomic, assign) double threshold;

@end
