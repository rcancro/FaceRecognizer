//
//  PersonViewController.h
//  FaceRecognition
//
//  Created by ricky cancro on 4/11/13.
//
//

#import <UIKit/UIKit.h>
@class NSManagedObjectID;

@interface PersonViewController : UICollectionViewController
@property (nonatomic, strong) NSManagedObjectID *personId;
@end
