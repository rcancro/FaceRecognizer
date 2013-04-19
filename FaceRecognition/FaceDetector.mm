//
//  FaceDetector.mm
//  FaceRecognition
//
//  Created by Michael Peterson on 2012-11-16.
//
//

#import "FaceDetector.h"
#import "NSManagedObjectContext+Fetch.h"
#import "Photo.h"
#import "DetectedFace+Additions.h"
#import "AppDelegate.h"
#import "Person.h"
#import "UIImage+OpenCV.h"


#define USE_OPENCV_FACE_DETECTION 0

#if USE_OPENCV_FACE_DETECTION
NSString * const kFaceCascadeFilename = @"haarcascade_frontalface_alt2";
const int kHaarOptions =  0;
static cv::CascadeClassifier _faceCascade;
#endif


@interface FaceDetector()
@property (nonatomic, strong) NSMutableDictionary *people;
@property (nonatomic, strong) NSMutableDictionary *objectIdLookup;

#if !USE_OPENCV_FACE_DETECTION
@property (nonatomic, strong) CIDetector *faceDetector;
#endif

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
#if USE_OPENCV_FACE_DETECTION
        NSString *faceCascadePath = [[NSBundle mainBundle] pathForResource:kFaceCascadeFilename ofType:@"xml"];
        _faceCascade.load([faceCascadePath UTF8String]);
#endif
    }
    
    return self;
}

//
//- (BOOL)trainRecognizer
//{
//    BOOL trained = NO;
//    std::vector<cv::Mat> images;
//    std::vector<int> labels;
//    
//    int faceIndex = 0;
//    self.objectIdLookup = [NSMutableDictionary dictionary];
//    
//    
//    NSManagedObjectContext *context = [AppDelegate appDelegate].managedObjectContext;
//    NSSet *allFaces = [context fetchObjectsForEntityName:@"DetectedFace" withPredicate:[NSPredicate predicateWithFormat:@"person != nil"]];
//    for (DetectedFace *f in allFaces)
//    {
//        NSString *key = [[[f.person objectID] URIRepresentation] absoluteString];
//        if (![self.objectIdLookup objectForKey:key])
//        {
//            NSString *value = [NSString stringWithFormat:@"%d", faceIndex];
//            if (!key || !value)
//            {
//                int i=0;
//                i++;
//            }
//            [self.objectIdLookup setValue:value forKey:key];
//            faceIndex++;
//        }
//        // get the photo of the face
//        UIImage *image = [f faceFromImageOfSize:faceSize];
//        cv::Mat faceData = [OpenCVData cvMatFromUIImage:image];
//
//        
//        images.push_back(faceData);
//        int label = [[self.objectIdLookup objectForKey:key] integerValue];
//        labels.push_back(label);
//    }
//    
//    if (images.size() > 1)
//    {
//        trained = YES;
//        recognizer->train(images, labels);
//    }
//    
//    return trained;
//}
//
//- (NSDictionary *)predictFace:(NSManagedObjectID *)faceId
//{
//    NSManagedObjectContext *context = [AppDelegate appDelegate].managedObjectContext;
//    DetectedFace *faceObject = (DetectedFace *)[context objectWithID:faceId];
//    UIImage *face = [faceObject faceFromImageOfSize:faceSize];
//    
//    int predictedLabel = -1;
//    double confidence = 0.0;
//    cv::Mat faceData = [OpenCVData cvMatFromUIImage:face];
//
//    recognizer->predict(faceData, predictedLabel, confidence);
//    
//    NSManagedObjectID *personId = nil;
//    if (predictedLabel != -1)
//    {
//        for (NSString *key in [self.objectIdLookup allKeys])
//        {
//            if ([[self.objectIdLookup objectForKey:key] integerValue] == predictedLabel)
//            {
//                personId = [[AppDelegate appDelegate].persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:key]];
//                break;
//            }
//        }
//    }
//    
//    if (personId)
//    {
//        return [NSDictionary dictionaryWithObjectsAndKeys:personId, @"personId", [NSNumber numberWithDouble:confidence], @"confidence", nil];
//    }
//    return nil;
//}


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
