//
//  FaceRecognizer.m
//  FaceRecognition
//
//  Created by ricky cancro on 4/19/13.
//
//

#import "FaceRecognizer.h"
#import <opencv2/contrib/contrib.hpp>
#import <opencv2/highgui/cap_ios.h>
#import "UIImage+OpenCV.h"

static cv::Ptr<cv::FaceRecognizer> recognizer;

@interface FaceRecognizer()
@property (nonatomic, strong) NSMutableDictionary *labelLookup;
@end

@implementation FaceRecognizer

+ (FaceRecognizer *)sharedInstance
{
    static dispatch_once_t once;
    static FaceRecognizer *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    if (self = [super init])
    {
        recognizer = cv::createEigenFaceRecognizer();
    }
    return self;
}


- (BOOL)trainRecognizer:(NSDictionary *)labelsAndImages;
{
    BOOL trained = NO;
    std::vector<cv::Mat> images;
    std::vector<int> labels;
    
    int faceIndex = 0;
    self.labelLookup = [NSMutableDictionary dictionary];
    
    for (NSString *label in [labelsAndImages allKeys])
    {
        if (![self.labelLookup objectForKey:label])
        {
            NSString *value = [NSString stringWithFormat:@"%d", faceIndex];
            [self.labelLookup setValue:value forKey:label];
            faceIndex++;
        }
        
        int labelKey = [[self.labelLookup objectForKey:label] integerValue];
        NSArray *faceImages = [labelsAndImages objectForKey:label];
        for (UIImage *image in faceImages)
        {
            cv::Mat faceData = [image asGrayScaleCVMat];
            images.push_back(faceData);
            labels.push_back(labelKey);
        }
    }
    
    if (images.size() > 1)
    {
        trained = YES;
        recognizer->train(images, labels);
    }
    
    return trained;
}

- (NSDictionary *)predictionForImage:(UIImage *)face
{
    int predictedLabel = -1;
    double confidence = 0.0;
    cv::Mat faceData = [face asGrayScaleCVMat];
    
    recognizer->predict(faceData, predictedLabel, confidence);
    
    NSString *label = nil;
    //NSLog(@"face detected! label: %d confidence: %f", predictedLabel, confidence);
    if (predictedLabel != -1)
    {
        for (NSString *key in [self.labelLookup allKeys])
        {
            if ([[self.labelLookup objectForKey:key] integerValue] == predictedLabel)
            {
                label = key;
                break;
            }
        }
    }
    
    if (label)
    {
        return [NSDictionary dictionaryWithObjectsAndKeys:label, @"label", [NSNumber numberWithDouble:confidence], @"confidence", nil];
    }
    
    return nil;
}


@end
