//
//  FaceDetectionOperation.m
//  FaceRecognition
//
//  Created by ricky cancro on 4/19/13.
//
//

#import "FaceDetectionOperation.h"
#import "AppDelegate.h"
#import "NSManagedObjectContext+Fetch.h"
#import "Photo.h"
#import "DetectedFace+Additions.h"
#import <opencv2/highgui/cap_ios.h>
#import <opencv2/contrib/contrib.hpp>
#import "FaceDetector.h"

@interface FaceDetectionOperation()
@property (nonatomic, strong) NSManagedObjectContext *context;
@end

@implementation FaceDetectionOperation

- (void)main
{
    @autoreleasepool
    {
        self.context = [[NSManagedObjectContext alloc] init];
        [self.context setPersistentStoreCoordinator:[AppDelegate appDelegate].persistentStoreCoordinator];
        [self.context setMergePolicy: NSMergeByPropertyObjectTrumpMergePolicy];
                
        if (self.startupBgBlock)
        {
            self.startupBgBlock(self.context);
        }
        
        if (self.startupUIBlock)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.startupUIBlock();
            });
        }
        
        // get all photos that do not have faces
        NSSet *allPhotos = [self.context fetchObjectsForEntityName:@"Photo" withPredicate:nil];
        
        if ([allPhotos count] == 0)
        {
            // need to populate the DB
            NSString *bundleRoot = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Faces"];
            NSFileManager *fm = [NSFileManager defaultManager];
            NSArray *dirContents = [fm contentsOfDirectoryAtPath:bundleRoot error:nil];
            NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.jpg'"];
            NSArray *images = [dirContents filteredArrayUsingPredicate:fltr];
            
            for (NSString *str in images)
            {
                Photo *photoObject = (Photo *)[NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:self.context];
                photoObject.imagePath = [@"Faces" stringByAppendingPathComponent:str];
            }
            [self.context save:nil];
        }
        
        NSSet *newPhotos = [self.context fetchObjectsForEntityName:@"Photo" withPredicate:[NSPredicate predicateWithFormat:@"faceDetectionRun = 0"]];
        NSInteger totalPhotos = [newPhotos count];
        NSInteger photoIndex = 0;
        
        for (Photo *p in newPhotos)
        {
            
            @autoreleasepool {
                NSString *path = [[NSBundle mainBundle] pathForResource:p.imagePath ofType:nil];
                UIImage *photo = [[UIImage alloc] initWithContentsOfFile:path];
                
                NSArray *rects = [[FaceDetector sharedInstance] findFacesInImage:photo];
                NSMutableSet *faces = [NSMutableSet set];
                for (NSValue *v in rects)
                {
                    DetectedFace *faceObject = (DetectedFace *)[NSEntityDescription insertNewObjectForEntityForName:@"DetectedFace" inManagedObjectContext:self.context];
                    [faceObject setRect:[v CGRectValue]];
                    faceObject.photo = p;
                    [faces addObject:faceObject];
                    
                }
                
                p.faceDetectionRun = [NSNumber numberWithBool:YES];
                p.faces = faces;
                
                if (photoIndex % 50 == 0)
                {
                    [self.context save:nil];
                }
                
                photoIndex++;
                NSLog(@"%d of %d found: %d faces", photoIndex, totalPhotos, [faces count]);
                
                if (self.progressBgBlock)
                {
                    self.progressBgBlock(self.context);
                }
                
                if (self.progressUIBlock)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.progressUIBlock(photoIndex, totalPhotos);
                    });
                }
            }
        }
        
        if (self.completionBgBlock)
        {
            self.completionBgBlock(self.context);
        }
        
        if (self.completionUIBlock)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.completionUIBlock();
            });
        }
    }
}


@end
