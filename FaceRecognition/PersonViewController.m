//
//  PersonViewController.m
//  FaceRecognition
//
//  Created by ricky cancro on 4/11/13.
//
//

#import "PersonViewController.h"
#import "PhotoManager.h"
#import "Photo.h"
#import "NSManagedObjectContext+Fetch.h"
#import "FaceCell.h"
#import "Person.h"
#import "AppDelegate.h"
#import "PhotoViewController.h"

@interface PersonViewController ()
@property (nonatomic, strong) NSArray *personPhotos;
@end

@implementation PersonViewController

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
    Person *person = (Person *)[context objectWithID:self.personId];
    self.personPhotos = [[PhotoManager sharedInstance] photosForPerson:self.personId context:context];
    self.title = person.name;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"PushToPhoto"] && [sender isKindOfClass:[FaceCell class]])
    {
        FaceCell *cell = (FaceCell *)sender;
        PhotoViewController *vc = [segue destinationViewController];
        vc.photoId = cell.managedObjectID;
        vc.title = self.title;
    }
}

#pragma mark -
#pragma mark UICollectionViewDataSource

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.personPhotos count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FaceCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"faceCell" forIndexPath:indexPath];
    
    NSManagedObjectContext *context = [AppDelegate appDelegate].managedObjectContext;
    Photo *p = (Photo *)[context objectWithID:[self.personPhotos objectAtIndex:indexPath.row]];
    
    UIImage *image = [UIImage imageNamed:p.imagePath];
    myCell.imageView.image = image;
    myCell.managedObjectID = [p objectID];
    
    return myCell;
}

@end
