//
//  FaceRecognitionOperation.m
//  FaceRecognition
//
//  Created by ricky cancro on 4/19/13.
//
//

#import "FaceRecognitionOperation.h"
#import "AppDelegate.h"
#import "NSManagedObjectContext+Fetch.h"
#import "DetectedFace+Additions.h"
#import "Person.h"
#import "Photo.h"
#import "PhotoManager.h"
#import "FaceRecognizer.h"
#import <opencv2/contrib/contrib.hpp>
#import <opencv2/highgui/cap_ios.h>

static const double kConfidenceThreshold = 3200.0;

@interface FaceRecognitionOperation()
@property (nonatomic, strong) NSMutableDictionary *people;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) NSMutableDictionary *predictions;
@end

@implementation FaceRecognitionOperation

- (void)main
{
    @autoreleasepool
    {
        CGSize faceSize = CGSizeMake(100, 100);
        self.context = [[NSManagedObjectContext alloc] init];
        [self.context setPersistentStoreCoordinator:[AppDelegate appDelegate].persistentStoreCoordinator];
        [self.context setMergePolicy: NSMergeByPropertyObjectTrumpMergePolicy];
        if (self.startupBgBlock)
        {
            self.startupBgBlock(self.context);
        }
        
        if (self.startupUIBlock)
        {
            self.startupUIBlock();
        }
        
        NSMutableDictionary *trainingData = [NSMutableDictionary dictionary];
        NSSet *allFaces = [self.context fetchObjectsForEntityName:@"DetectedFace" withPredicate:[NSPredicate predicateWithFormat:@"person != nil"]];
        for (DetectedFace *f in allFaces)
        {
            NSString *key = f.person.name;
            UIImage *image = [f faceFromImageOfSize:faceSize];
            
            NSMutableArray *images = [trainingData objectForKey:key];
            if (!images)
            {
                images = [NSMutableArray array];
                [trainingData setObject:images forKey:key];
            }
            [images addObject:image];
        }
        
        
        if ([[FaceRecognizer sharedInstance] trainRecognizer:trainingData])
        {
            self.predictions = [NSMutableDictionary dictionary];
            NSArray *unknownFaces = [[PhotoManager sharedInstance] unknownFaces:self.context];
            int totalFaces = [unknownFaces count];
            int index = 0;
            
            for (NSManagedObjectID *faceId in unknownFaces)
            {
                DetectedFace *face = (DetectedFace *)[self.context objectWithID:faceId];
                
                NSDictionary *d = [[FaceRecognizer sharedInstance] predictionForImage:[face faceFromImageOfSize:faceSize]];
                if (d && [[d objectForKey:@"confidence"] doubleValue] < kConfidenceThreshold)
                {
                    NSString *name = [d objectForKey:@"label"];
                    Person *p = (Person *)[self.context fetchObjectForEntityName:@"Person" withPredicate:[NSPredicate predicateWithFormat:@"name = %@", name]];
                    
                    NSString *faceIdStr = [[faceId URIRepresentation] absoluteString];
                    NSMutableArray *array = [self.predictions objectForKey:p.name];
                    if (!array)
                    {
                        array = [NSMutableArray array];
                    }
                    [array addObject:faceIdStr];
                    [self.predictions setObject:array forKey:p.name];
                }
                
                if (self.progressBgBlock)
                {
                    self.progressBgBlock(self.context);
                }
                
                if (self.progressUIBlock)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.progressUIBlock(index, totalFaces);
                    });
                }
                index++;
            }
        }
        
        if (self.completionBgBlock)
        {
            self.completionBgBlock(self.context);
        }
        
        if (self.completionUIBlock)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.completionUIBlock(self.predictions);
            });
        }
    }
}

@end
