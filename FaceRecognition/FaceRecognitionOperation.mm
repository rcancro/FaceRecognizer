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
#import "UIImage+OpenCV.h"
#import <opencv2/contrib/contrib.hpp>
#import <opencv2/highgui/cap_ios.h>

static CGSize faceSize = CGSizeMake(100, 100);
static const double kConfidenceThreshold = 3200.0;
cv::Ptr<cv::FaceRecognizer> recognizer;

@interface FaceRecognitionOperation()
@property (nonatomic, strong) NSMutableDictionary *people;
@property (nonatomic, strong) CIDetector *faceDetector;
@property (nonatomic, strong) NSMutableDictionary *objectIdLookup;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) NSMutableDictionary *predictions;
@end

@implementation FaceRecognitionOperation

- (void)main
{
    @autoreleasepool
    {
        
        recognizer = cv::createEigenFaceRecognizer(80, 7000);
        self.context = [[NSManagedObjectContext alloc] init];
        [self.context setPersistentStoreCoordinator:[AppDelegate appDelegate].persistentStoreCoordinator];
        [self.context setMergePolicy: NSMergeByPropertyObjectTrumpMergePolicy];
        if (self.startupBlock)
        {
            self.startupBlock(self.context);
        }
        
        if ([self trainRecognizer])
        {
            self.predictions = [NSMutableDictionary dictionary];
            NSArray *unknownFaces = [[PhotoManager sharedInstance] unknownFaces:self.context];
            int totalFaces = [unknownFaces count];
            int index = 0;
            
            for (NSManagedObjectID *faceId in unknownFaces)
            {
                DetectedFace *face = (DetectedFace *)[self.context objectWithID:faceId];
                
                NSDictionary *d = [self predictFace:[face objectID]];
                if (d && [[d objectForKey:@"confidence"] doubleValue] < kConfidenceThreshold)
                {
                    NSManagedObjectID *personId = [d objectForKey:@"personId"];
                    Person *p = (Person *)[self.context objectWithID:personId];
                    
                    NSString *faceIdStr = [[faceId URIRepresentation] absoluteString];
                    NSMutableArray *array = [self.predictions objectForKey:p.name];
                    if (!array)
                    {
                        array = [NSMutableArray array];
                    }
                    [array addObject:faceIdStr];
                    [self.predictions setObject:array forKey:p.name];
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
        
        if (self.completionUIBlock)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.completionUIBlock(self.predictions);
            });
        }
    }
}

- (BOOL)trainRecognizer
{
    BOOL trained = NO;
    std::vector<cv::Mat> images;
    std::vector<int> labels;
    
    int faceIndex = 0;
    self.objectIdLookup = [NSMutableDictionary dictionary];
    
    
    NSSet *allFaces = [self.context fetchObjectsForEntityName:@"DetectedFace" withPredicate:[NSPredicate predicateWithFormat:@"person != nil"]];
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
        cv::Mat faceData = [image asGrayScaleCVMat];
        
        
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
    DetectedFace *faceObject = (DetectedFace *)[self.context objectWithID:faceId];
    UIImage *face = [faceObject faceFromImageOfSize:faceSize];
    
    int predictedLabel = -1;
    double confidence = 0.0;
    cv::Mat faceData = [face asGrayScaleCVMat];
    
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

@end
