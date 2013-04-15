//
//  PhotoManager.m
//  FaceRecognition
//
//  Created by ricky cancro on 4/9/13.
//
//

#import "PhotoManager.h"
#import "NSManagedObjectContext+Fetch.h"
#import "DetectedFace+Additions.h"
#import "Person.h"
#import "Photo.h"

@interface PhotoManager()
@end

@implementation PhotoManager

+ (PhotoManager *)sharedInstance
{
    static dispatch_once_t once;
    static PhotoManager *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (NSArray *)unknownFaces:(NSManagedObjectContext *)context
{
    NSSet *faces = [context fetchObjectsForEntityName:@"DetectedFace" withPredicate:[NSPredicate predicateWithFormat:@"person == nil"]];
    NSMutableArray *objectIds = [NSMutableArray arrayWithCapacity:[faces count]];
    for (DetectedFace *face in faces)
    {
        [objectIds addObject:[face objectID]];
    }
    return objectIds;
}

- (NSArray *)knownPeople:(NSManagedObjectContext *)context
{
    NSSet *people = [context fetchObjectsForEntityName:@"Person" withPredicate:nil];
    NSMutableArray *objectIds = [NSMutableArray arrayWithCapacity:[people count]];
    for (Person *p in people)
    {
        [objectIds addObject:[p objectID]];
    }
    return objectIds;
}

- (NSArray *)photosForPerson:(NSManagedObjectID *)personId context:(NSManagedObjectContext *)context
{
    NSSet *photos = [context fetchObjectsForEntityName:@"Photo" withPredicate:[NSPredicate predicateWithFormat:@"ANY self.faces.person = %@", personId]];
    NSMutableArray *objectIds = [NSMutableArray arrayWithCapacity:[photos count]];
    for (Photo *p in photos)
    {
        [objectIds addObject:[p objectID]];
    }
    return objectIds;
}


@end
