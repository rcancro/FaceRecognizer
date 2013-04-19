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
#import "UIImage+OpenCV.h"

#define USE_OPENCV_FACE_DETECTION 1

#if USE_OPENCV_FACE_DETECTION
NSString * const kFaceCascadeFilename = @"haarcascade_frontalface_alt2";
const int kHaarOptions =  0;
static cv::CascadeClassifier _faceCascade;
#endif

@interface FaceDetectionOperation()

#if !USE_OPENCV_FACE_DETECTION
@property (nonatomic, strong) CIDetector *faceDetector;
#endif

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
                
        if (self.startupBlock)
        {
            self.startupBlock(self.context);
        }
        
        // get all photos that do not have faces
        NSSet *allPhotos = [self.context fetchObjectsForEntityName:@"Photo" withPredicate:nil];
        
        if ([allPhotos count] == 0)
        {
            // need to populate the DB
            NSString *bundleRoot = [[NSBundle mainBundle] bundlePath];
            NSFileManager *fm = [NSFileManager defaultManager];
            NSArray *dirContents = [fm contentsOfDirectoryAtPath:bundleRoot error:nil];
            NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.jpg'"];
            NSArray *images = [dirContents filteredArrayUsingPredicate:fltr];
            
            for (NSString *str in images)
            {
                Photo *photoObject = (Photo *)[NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:self.context];
                photoObject.imagePath = str;
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
                
                NSArray *rects = [self findFacesInImage:photo];
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
                [self.context save:nil];
                
                photoIndex++;
                NSLog(@"%d of %d found: %d faces", photoIndex, totalPhotos, [faces count]);
                if (self.progressUIBlock)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.progressUIBlock(photoIndex, totalPhotos);
                    });
                }
            }
        }
    }
}

- (NSArray *)findFacesInImage:(UIImage *)image
{
    
#if USE_OPENCV_FACE_DETECTION
    cv::Mat imageMat = [image asGrayScaleCVMat];
    std::vector<cv::Rect> faces;
    _faceCascade.detectMultiScale(imageMat, faces, 1.1, 2, kHaarOptions, cv::Size(100, 100));
    
    NSMutableArray *facesArray = [NSMutableArray array];
    for (std::vector<cv::Rect>::iterator i = faces.begin(); i != faces.end(); i++)
    {
        CGRect r = {static_cast<CGFloat>(i->x), static_cast<CGFloat>(i->y), static_cast<CGFloat>(i->width), static_cast<CGFloat>(i->height)};
        [facesArray addObject:[NSValue valueWithCGRect:r]];
    }
    return facesArray;
#else
    if (!self.faceDetector)
    {
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:CIDetectorAccuracyHigh, CIDetectorAccuracy, [NSNumber numberWithFloat:.2],CIDetectorMinFeatureSize,nil];
        self.faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:options];
    }
    
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    NSArray *features = [self.faceDetector featuresInImage:ciImage];
    NSMutableArray *rects = [NSMutableArray array];
    for (CIFeature *feature in features)
    {
        CGRect r = feature.bounds;
        r.origin.y = image.size.height - (r.origin.y + r.size.height);
        [rects addObject:[NSValue valueWithCGRect:r]];
    }
    return rects;
#endif
}

@end
