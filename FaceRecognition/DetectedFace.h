//
//  DetectedFace.h
//  FaceRecognition
//
//  Created by ricky cancro on 4/9/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Person, Photo;

@interface DetectedFace : NSManagedObject

@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSNumber * width;
@property (nonatomic, retain) NSNumber * x;
@property (nonatomic, retain) NSNumber * y;
@property (nonatomic, retain) Person *person;
@property (nonatomic, retain) Photo *photo;

@end
