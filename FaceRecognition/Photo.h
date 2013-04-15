//
//  Photo.h
//  FaceRecognition
//
//  Created by ricky cancro on 4/10/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DetectedFace;

@interface Photo : NSManagedObject

@property (nonatomic, retain) NSString * imagePath;
@property (nonatomic, retain) NSNumber * faceDetectionRun;
@property (nonatomic, retain) NSSet *faces;
@end

@interface Photo (CoreDataGeneratedAccessors)

- (void)addFacesObject:(DetectedFace *)value;
- (void)removeFacesObject:(DetectedFace *)value;
- (void)addFaces:(NSSet *)values;
- (void)removeFaces:(NSSet *)values;

@end
