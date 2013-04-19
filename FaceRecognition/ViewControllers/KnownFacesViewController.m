//
//  KnownFacesViewController.m
//  FaceRecognition
//
//  Created by ricky cancro on 4/9/13.
//
//

#import "KnownFacesViewController.h"
#import "PhotoManager.h"
#import "AppDelegate.h"
#import "FaceCell.h"
#import "Person.h"
#import "DetectedFace+Additions.h"
#import "Photo.h"
#import "PersonViewController.h"
#import "NSManagedObjectContext+Fetch.h"
#import "FaceDetector.h"
#import "MBProgressHUD.h"

#import "FaceDetectionOperation.h"

@interface KnownFacesViewController ()
@property (nonatomic, strong) NSArray *knownPeople;
@end

@implementation KnownFacesViewController

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
    
    __block MBProgressHUD *hud = nil;
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.name = @"faceDetection";
    FaceDetectionOperation *faceDetectionOp = [[FaceDetectionOperation alloc] init];
    faceDetectionOp.progressUIBlock = ^(int photoCount, int totalPhotos) {
        
        if (!hud)
        {
            hud = [[MBProgressHUD alloc] initWithView:self.tabBarController.view];
            hud.mode = MBProgressHUDModeDeterminate;
            hud.labelText = @"Looking for faces";
            hud.removeFromSuperViewOnHide = YES;
            [self.tabBarController.view addSubview:hud];
            [hud show:YES];
        }
        hud.progress = (float)photoCount/(float)totalPhotos;
    };
    
    faceDetectionOp.completionUIBlock = ^{
        [hud hide:YES];
    };
    [queue addOperation:faceDetectionOp];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadData];
}

- (void)reloadData
{
    self.knownPeople = [[PhotoManager sharedInstance] knownPeople:[AppDelegate appDelegate].managedObjectContext];
    [self.collectionView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"PushToPerson"] && [sender isKindOfClass:[FaceCell class]])
    {
        FaceCell * cell = (FaceCell *)sender;
        PersonViewController *vc = [segue destinationViewController];
        vc.personId = cell.managedObjectID;
    }
}

- (IBAction)forgetFaces:(id)sender
{
    NSManagedObjectContext *context = [AppDelegate appDelegate].managedObjectContext;
    NSSet *faces = [context fetchObjectsForEntityName:@"DetectedFace" withPredicate:[NSPredicate predicateWithFormat:@"self.person != 0"]];
    for (DetectedFace *f in [faces allObjects])
    {
        f.person = nil;
    }
    [context save:nil];
    
    [self reloadData];
    
}

#pragma mark -
#pragma mark UICollectionViewDataSource

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.knownPeople count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FaceCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"faceCell" forIndexPath:indexPath];
    
    NSManagedObjectContext *context = [AppDelegate appDelegate].managedObjectContext;
    Person *person = (Person *)[context objectWithID:[self.knownPeople objectAtIndex:indexPath.row]];
    DetectedFace *face = [[person.faces allObjects] objectAtIndex:0];
    
    myCell.imageView.image = [face faceFromImage];

    myCell.managedObjectID = [person objectID];
    
    return myCell;
}
@end
