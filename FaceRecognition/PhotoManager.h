//
//  PhotoManager.h
//  FaceRecognition
//
//  Created by ricky cancro on 4/9/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface PhotoManager : NSObject
+ (PhotoManager *)sharedInstance;
- (NSArray *)knownPeople:(NSManagedObjectContext *)context;

- (NSArray *)unknownFaces:(NSManagedObjectContext *)context;
- (NSArray *)photosForPerson:(NSManagedObjectID *)personId context:(NSManagedObjectContext *)context;
@end
