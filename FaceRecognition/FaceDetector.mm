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
CGSize faceSize = CGSizeMake(200, 200);

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

- (NSString *)recognizerPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"recognizer"];
}

- (id)init
{
    self = [super init];
    if (self)
    {
        NSString *faceCascadePath = [[NSBundle mainBundle] pathForResource:kFaceCascadeFilename ofType:@"xml"];
        
        if (!_faceCascade.load([faceCascadePath UTF8String]))
        {
            NSLog(@"Could not load face cascade: %@", faceCascadePath);
        }
        
        recognizer = cv::createEigenFaceRecognizer();
    }
    
    return self;
}

- (void)trainRecognizer
{
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
            [self.objectIdLookup setValue:value forKey:key];
            faceIndex++;
        }
        // get the photo of the face
        UIImage *image = [f faceFromImageOfSize:faceSize];
        cv::Mat faceData = [OpenCVData cvMatFromUIImage:image];

        
        images.push_back(faceData);
        int label = [[self.objectIdLookup objectForKey:key] integerValue];
        labels.push_back(label);
        NSLog(@"image: %@ label: %d", f.photo.imagePath, label);
    }
    
    if (images.size() > 1)
    {
        recognizer->train(images, labels);

//        std::string path([[self recognizerPath] UTF8String]);
//        recognizer->save(path);
    }
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
    NSLog(@"label: %d", predictedLabel);
    
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
    
    NSDictionary *ret = [NSDictionary dictionaryWithObjectsAndKeys:personId, @"personId", [NSNumber numberWithDouble:confidence], @"confidence", nil];
    return ret;
}


- (void)startLookingForFaces:(FaceDetectionProgress)progressBlock completionBlock:(FaceDetectionCompletion)completionBlock managedObjectContext:(NSManagedObjectContext *)context
{
    // get all photos that do not have faces
    NSSet *allPhotos = [context fetchObjectsForEntityName:@"Photo" withPredicate:[NSPredicate predicateWithFormat:@"faceDetectionRun = 0"]];
    NSInteger totalPhotos = [allPhotos count];
    NSInteger photoIndex = 0;
    
    if (progressBlock)
        progressBlock(photoIndex, totalPhotos);
    
    
    
    for (Photo *p in allPhotos)
    {
        
        NSArray *rects = [[FaceDetector sharedInstance] findFacesInImage:[UIImage imageNamed:p.imagePath]];
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
            progressBlock(photoIndex, totalPhotos);
    }
    
    if (progressBlock)
        progressBlock(totalPhotos, totalPhotos);
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
