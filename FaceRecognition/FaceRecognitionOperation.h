//
//  FaceRecognitionOperation.h
//  FaceRecognition
//
//  Created by ricky cancro on 4/19/13.
//
//

#import <Foundation/Foundation.h>

typedef void (^FaceRecognitionStart)(NSManagedObjectContext *context);
typedef void (^FaceRecognitionProgress)(int photoCount, int totalPhotos);
typedef void (^FaceRecognitionCompletion)(NSDictionary *predictions);

@interface FaceRecognitionOperation : NSOperation

@property (nonatomic, copy) FaceRecognitionStart startupBlock;
@property (nonatomic, copy) FaceRecognitionProgress progressUIBlock;
@property (nonatomic, copy) FaceRecognitionCompletion completionUIBlock;

@end
