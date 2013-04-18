//
//  FaceDetector.mm
//  FaceRecognition
//
//  Created by Michael Peterson on 2012-11-16.
//
//

#import "FaceDetector.h"
#import "OpenCVData.h"
#import "NSManagedObjectContext+Fetch.h"
#import "Photo.h"
#import "DetectedFace+Additions.h"
#import "AppDelegate.h"
#import "Person.h"


NSString * const kFaceCascadeFilename = @"haarcascade_frontalface_alt2";
cv::Ptr<cv::FaceRecognizer> recognizer;
CGSize faceSize = CGSizeMake(100, 100);

const int kHaarOptions =  0;

static cv::CascadeClassifier _faceCascade;


@interface FaceDetector()
@property (nonatomic, strong) NSMutableDictionary *people;
@property (nonatomic, strong) CIDetector *faceDetector;
@property (nonatomic, strong) NSMutableDictionary *objectIdLookup;
@end

@implementation FaceDetector

+ (FaceDetector *)sharedInstance
{
    static dispatch_once_t once;
    static FaceDetector *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        recognizer = cv::createEigenFaceRecognizer(80, 7000);
    }
    
    return self;
}

- (BOOL)trainRecognizer
{
    BOOL trained = NO;
    std::vector<cv::Mat> images;
    std::vector<int> labels;
    
    int faceIndex = 0;
    self.objectIdLookup = [NSMutableDictionary dictionary];
    
    
    NSManagedObjectContext *context = [AppDelegate appDelegate].managedObjectContext;
    NSSet *allFaces = [context fetchObjectsForEntityName:@"DetectedFace" withPredicate:[NSPredicate predicateWithFormat:@"person != nil"]];
    for (DetectedFace *f in allFaces)
    {
        NSString *key = [[[f.person objectID] URIRepresentation] absoluteString];
        if (![self.objectIdLookup objectForKey:key])
        {
            NSString *value = [NSString stringWithFormat:@"%d", faceIndex];
            if (!key || !value)
            {
                int i=0;
                i++;
            }
            [self.objectIdLookup setValue:value forKey:key];
            faceIndex++;
        }
        // get the photo of the face
        UIImage *image = [f faceFromImageOfSize:faceSize];
        cv::Mat faceData = [OpenCVData cvMatFromUIImage:image];

        
        images.push_back(faceData);
        int label = [[self.objectIdLookup objectForKey:key] integerValue];
        labels.push_back(label);
    }
    
    if (images.size() > 1)
    {
        trained = YES;
        recognizer->train(images, labels);
    }
    
    return trained;
}

- (NSDictionary *)predictFace:(NSManagedObjectID *)faceId
{
    NSManagedObjectContext *context = [AppDelegate appDelegate].managedObjectContext;
    DetectedFace *faceObject = (DetectedFace *)[context objectWithID:faceId];
    UIImage *face = [faceObject faceFromImageOfSize:faceSize];
    
    int predictedLabel = -1;
    double confidence = 0.0;
    cv::Mat faceData = [OpenCVData cvMatFromUIImage:face];

    recognizer->predict(faceData, predictedLabel, confidence);
    
    NSManagedObjectID *personId = nil;
    if (predictedLabel != -1)
    {
        for (NSString *key in [self.objectIdLookup allKeys])
        {
            if ([[self.objectIdLookup objectForKey:key] integerValue] == predictedLabel)
            {
                personId = [[AppDelegate appDelegate].persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:key]];
                break;
            }
        }
    }
    
    if (personId)
    {
        return [NSDictionary dictionaryWithObjectsAndKeys:personId, @"personId", [NSNumber numberWithDouble:confidence], @"confidence", nil];
    }
    return nil;
}


- (void)startLookingForFaces:(FaceDetectionProgress)progressBlock completionBlock:(FaceDetectionCompletion)completionBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        NSManagedObjectContext *context = [[AppDelegate appDelegate] managedObjectContext];
        // get all photos that do not have faces
        NSSet *allPhotos = [context fetchObjectsForEntityName:@"Photo" withPredicate:nil];
        
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
                Photo *photoObject = (Photo *)[NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:context];
                photoObject.imagePath = str;
            }
            [context save:nil];
        }
        
        NSSet *newPhotos = [context fetchObjectsForEntityName:@"Photo" withPredicate:[NSPredicate predicateWithFormat:@"faceDetectionRun = 0"]];
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
                    DetectedFace *faceObject = (DetectedFace *)[NSEntityDescription insertNewObjectForEntityForName:@"DetectedFace" inManagedObjectContext:context];
                    [faceObject setRect:[v CGRectValue]];
                    faceObject.photo = p;
                    [faces addObject:faceObject];
                    
                }
                
                p.faceDetectionRun = [NSNumber numberWithBool:YES];
                p.faces = faces;
                [context save:nil];
                
                photoIndex++;
                NSLog(@"%d of %d found: %d faces", photoIndex, totalPhotos, [faces count]);
                if (progressBlock)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        progressBlock(photoIndex, totalPhotos);
                    });
                }
            }
        }
        
        if (completionBlock)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock();
            });
        }
        
    });
}

- (NSArray *)findFacesInImage:(UIImage *)image
{
    
#if 1
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

#else
    cv::Mat imageMat = [OpenCVData cvMatFromUIImage:image];
    std::vector<cv::Rect> faces;
    _faceCascade.detectMultiScale(imageMat, faces, 1.1, 2, kHaarOptions, cv::Size(100, 100));
    
    NSMutableArray *facesArray = [NSMutableArray array];
    for (std::vector<cv::Rect>::iterator i = faces.begin(); i != faces.end(); i++)
    {
        CGRect r = [OpenCVData faceToCGRect:*i];
        [facesArray addObject:[NSValue valueWithCGRect:r]];
    }
    return facesArray;
#endif
}

- (NSDictionary *)recognizePeopleFromImage:(UIImage *)image inRects:(NSArray *)rects
{
    return nil;
}


@end
