//
//  UnknownFacesViewController.m
//  FaceRecognition
//
//  Created by ricky cancro on 4/9/13.
//
//

#import "UnknownFacesViewController.h"
#import "PhotoManager.h"
#import "FaceCell.h"
#import "AppDelegate.h"
#import "DetectedFace+Additions.h"
#import "UIAlertView+MKBlockAdditions.h"
#import "Photo.h"
#import "NSManagedObjectContext+Fetch.h"
#import "Person.h"
#import "FaceDetector.h"
#import "MBProgressHUD.h"
#import "FaceDetectionOperation.h"

@interface UnknownFacesViewController ()<UICollectionViewDataSource, UICollectionViewDelegate>
@property (nonatomic, strong) NSMutableArray *unknownFaces;
@property (nonatomic, strong) NSMutableDictionary *guesses;
@end

@implementation UnknownFacesViewController

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.unknownFaces = [NSMutableArray arrayWithArray:[[PhotoManager sharedInstance] unknownFaces:[AppDelegate appDelegate].managedObjectContext]];
    [self.collectionView reloadData];
}

#pragma mark -
#pragma mark UICollectionViewDataSource

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.unknownFaces count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FaceCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"faceCell" forIndexPath:indexPath];
    NSManagedObjectContext *context = [AppDelegate appDelegate].managedObjectContext;
    DetectedFace *face = (DetectedFace *)[context objectWithID:[self.unknownFaces objectAtIndex:indexPath.row]];
    
    myCell.imageView.image = [face faceFromImage];
    
    NSString *key = [[[face objectID] URIRepresentation] absoluteString];
    if ([[self.guesses objectForKey:key] count])
    {
        NSDictionary *data = [self.guesses objectForKey:key];
        Person *person = (Person *)[context objectWithID:[data objectForKey:@"personId"]];
        myCell.label.text = [NSString stringWithFormat:@"%@ - %f", person.name, [[data objectForKey:@"confidence"] doubleValue]];
    }
 
    return myCell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    UIAlertView * av = [UIAlertView createAlertViewWithTitle:@"" message:@"Who is this?" cancelButtonTitle:@"Cancel" otherButtonTitles:[NSArray arrayWithObjects:@"OK", @"Not a Face", nil] onDismiss:^(int buttonIndex, UIAlertView *alertView) {
        
        NSManagedObjectContext *context = [AppDelegate appDelegate].managedObjectContext;
        DetectedFace *face = (DetectedFace *)[context objectWithID:[self.unknownFaces objectAtIndex:indexPath.row]];
        if (buttonIndex == 0)
        {
            // look for the person
            NSSet *people = [context fetchObjectsForEntityName:@"Person" withPredicate:[NSPredicate predicateWithFormat:@"name = %@", [alertView textFieldAtIndex:0].text]];
            Person *person = nil;
            
            // if person doesn't exist, create
            if ([people count] == 0)
            {
                person = (Person *)[NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:context];
                person.name = [alertView textFieldAtIndex:0].text;
            }
            else
            {
                person = [people anyObject];
            }
            
            // add person to detectedFace
            face.person = person;
            
            NSMutableSet *s = [NSMutableSet setWithSet:person.faces];
            [s addObject:face];
            person.faces = s;
        }
        else if (buttonIndex == 1)
        {
            // remove this detected face object
            [context deleteObject:face];
            [context save:nil];
        }
        
        [context save:nil];
        int index = [self.unknownFaces indexOfObject:[face objectID]];
        [self.unknownFaces removeObject:[face objectID]];
        
        // remove this cell
        [self.collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]]];
        
    } onCancel:^{
    }];
    
    av.alertViewStyle = UIAlertViewStylePlainTextInput;
    [av show];
}

- (IBAction)rescan:(id)sender
{
    __block MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    hud.mode = MBProgressHUDModeDeterminate;
    hud.labelText = @"Reseting Database";
    hud.removeFromSuperViewOnHide = YES;
    [self.navigationController.view addSubview:hud];
    [hud show:YES];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.name = @"faceDetection";
    FaceDetectionOperation *faceDetectionOp = [[FaceDetectionOperation alloc] init];
    faceDetectionOp.progressUIBlock = ^(int photoCount, int totalPhotos) {
        
        hud.labelText = @"Finding Faces";
        hud.progress = (float)photoCount/(float)totalPhotos;
    };
    
    faceDetectionOp.completionBlock = ^{
        [hud hide:YES];
    };
    
    faceDetectionOp.startupBlock = ^(NSManagedObjectContext *context){
        NSSet *detectedFaces = [context fetchObjectsForEntityName:@"DetectedFace" withPredicate:nil];
        for (DetectedFace *face in detectedFaces)
        {
            [context deleteObject:face];
        }
        [context save:nil];
        
        NSSet *people = [context fetchObjectsForEntityName:@"Person" withPredicate:nil];
        for (Person *p in people)
        {
            [context deleteObject:p];
        }
        [context save:nil];
        
        NSSet *allPhotos = [context fetchObjectsForEntityName:@"Photo" withPredicate:nil];
        for (Photo *p in allPhotos)
        {
            p.faceDetectionRun = [NSNumber numberWithBool:NO];
        }
        [context save:nil];
    };
    
    [queue addOperation:faceDetectionOp];
    
}

@end
