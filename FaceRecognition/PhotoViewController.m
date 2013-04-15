//
//  PhotoViewController.m
//  FaceRecognition
//
//  Created by ricky cancro on 4/11/13.
//
//

#import "PhotoViewController.h"
#import "Photo.h"
#import "AppDelegate.h"

@interface PhotoViewController ()

@end

@implementation PhotoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSManagedObjectContext *context = [AppDelegate appDelegate].managedObjectContext;
    Photo *p = (Photo *)[context objectWithID:self.photoId];
    self.imageView.image = [UIImage imageNamed:p.imagePath];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
