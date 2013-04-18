//
//  FaceCell.h
//  FaceRecognition
//
//  Created by ricky cancro on 4/9/13.
//
//

#import <UIKit/UIKit.h>
@class NSManagedObjectID;

@interface FaceCell : UICollectionViewCell
@property (nonatomic, copy) void (^imageTappedBlock)();
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UILabel *label;
@property (nonatomic, strong) NSManagedObjectID *managedObjectID;

//- (IBAction)imageTapped:(id)sender;
@end
