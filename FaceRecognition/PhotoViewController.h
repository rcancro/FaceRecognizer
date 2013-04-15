//
//  PhotoViewController.h
//  FaceRecognition
//
//  Created by ricky cancro on 4/11/13.
//
//

#import <UIKit/UIKit.h>
@class NSManagedObjectID;

@interface PhotoViewController : UIViewController
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) NSManagedObjectID *photoId;
@end
