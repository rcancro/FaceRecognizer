//
//  Person.h
//  FaceRecognition
//
//  Created by ricky cancro on 4/10/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DetectedFace;

@interface Person : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *faces;
@end

@interface Person (CoreDataGeneratedAccessors)

- (void)addFacesObject:(DetectedFace *)value;
- (void)removeFacesObject:(DetectedFace *)value;
- (void)addFaces:(NSSet *)values;
- (void)removeFaces:(NSSet *)values;

@end
