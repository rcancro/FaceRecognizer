//
//  FaceCell.m
//  FaceRecognition
//
//  Created by ricky cancro on 4/9/13.
//
//

#import "FaceCell.h"

@implementation FaceCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
    }
    return self;
}

- (void)prepareForReuse
{
    self.label.text = @"";
}

//- (void)awakeFromNib
//{
//    self.imageView.userInteractionEnabled = YES;
//    [self.imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)]];
//}

//- (IBAction)imageTapped:(id)sender
//{
//    if (self.imageTappedBlock)
//        self.imageTappedBlock();
//}


@end
