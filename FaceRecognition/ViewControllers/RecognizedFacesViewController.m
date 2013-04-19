//
//  RecognizedFacesViewController.m
//  FaceRecognition
//
//  Created by ricky cancro on 4/15/13.
//
//

#import "RecognizedFacesViewController.h"
#import "PhotoManager.h"
#import "AppDelegate.h"
#import "FaceDetector.h"
#import "DetectedFace+Additions.h"
#import "NSManagedObjectContext+Fetch.h"
#import "MBProgressHUD.h"
#import "Person.h"
#import "FaceCell.h"
#import "UIAlertView+MKBlockAdditions.h"
#import "RecognizedFaceHeader.h"
#import "FaceRecognitionOperation.h"

@interface RecognizedFacesViewController ()
@property (nonatomic, strong) NSMutableDictionary *guesses;
@property (nonatomic, strong) NSArray *sortedKeys;
@property (nonatomic, assign) double threshold;
@end

@implementation RecognizedFacesViewController

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
    self.threshold = kDefaultConfidenceThreshold;
    [self guess:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark UICollectionViewDataSource

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return [[self.guesses allKeys] count];
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSString *key = [self.sortedKeys objectAtIndex:section];
    return [[self.guesses objectForKey:key] count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = [self.sortedKeys objectAtIndex:indexPath.section];
    NSArray *faces = [self.guesses objectForKey:key];
    NSString *faceIdStr = [faces objectAtIndex:indexPath.row];
    
    FaceCell *myCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"faceCell" forIndexPath:indexPath];
    NSManagedObjectContext *context = [AppDelegate appDelegate].managedObjectContext;
    NSManagedObjectID *faceId = [[AppDelegate appDelegate].persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:faceIdStr]];
    
    DetectedFace *face = (DetectedFace *)[context objectWithID:faceId];
    myCell.imageView.image = [face faceFromImage];
    
    return myCell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = [self.sortedKeys objectAtIndex:indexPath.section];
    NSMutableArray *faces = [self.guesses objectForKey:key];
    NSString *faceIdStr = [faces objectAtIndex:indexPath.row];
    NSManagedObjectID *faceId = [[AppDelegate appDelegate].persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:faceIdStr]];
    
    [UIAlertView alertViewWithTitle:@""
                            message:[NSString stringWithFormat:@"Is this %@?", key]
                  cancelButtonTitle:@"No"
                  otherButtonTitles:[NSArray arrayWithObjects:@"Yes", nil]
                          onDismiss:^(int buttonIndex, UIAlertView *alertView) {
                              
                              NSManagedObjectContext *context = [AppDelegate appDelegate].managedObjectContext;
                              
                              DetectedFace *face = (DetectedFace *)[[AppDelegate appDelegate].managedObjectContext objectWithID:faceId];
                              Person *person = [context fetchObjectForEntityName:@"Person" withPredicate:[NSPredicate predicateWithFormat:@"name = %@", key]];
                              face.person = person;
                              
                              [context save:nil];
                              int index = [faces indexOfObject:faceIdStr];
                              [faces removeObject:faceIdStr];
                              
                              int section = [self.sortedKeys indexOfObject:key];
                              
                              // remove this cell
                              [self.collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:section]]];
                              
                          } onCancel:^{
                              UIAlertView *av = [UIAlertView createAlertViewWithTitle:@"" message:@"Who is this?" cancelButtonTitle:@"Cancel" otherButtonTitles:[NSArray arrayWithObject:@"OK"] onDismiss:^(int buttonIndex, UIAlertView *alertView) {
                                  // look for the person
                                  NSManagedObjectContext *context = [AppDelegate appDelegate].managedObjectContext;
                                  DetectedFace *face = (DetectedFace *)[[AppDelegate appDelegate].managedObjectContext objectWithID:faceId];
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
                                  
                                  NSError *err = nil;
                                  if (![context save:&err])
                                  {
                                      NSLog(@"save failed %@", [err localizedDescription]);
                                  }
                                  
                                  int index = [faces indexOfObject:faceIdStr];
                                  [faces removeObject:faceIdStr];
                                  int section = [self.sortedKeys indexOfObject:key];
                                  if ([faces count] == 0)
                                  {
                                      [self.guesses removeObjectForKey:key];
                                      self.sortedKeys = [[self.guesses allKeys] sortedArrayUsingSelector:@selector(compare:)];
                                      [self.collectionView deleteSections:[NSIndexSet indexSetWithIndex:section]];
                                  }
                                  else
                                  {
                                      // remove this cell
                                      [self.collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:section]]];
                                  }
                                  
                              } onCancel:^{
                              }];
                              
                              av.alertViewStyle = UIAlertViewStylePlainTextInput;
                              [av show];
                          }];
    
}

- (UICollectionReusableView *)collectionView: (UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    RecognizedFaceHeader *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"RecognizedFaceHeader" forIndexPath:indexPath];
    headerView.titleLabel.text = [self.sortedKeys objectAtIndex:indexPath.section];
    return headerView;
}

#pragma mark - actions

- (IBAction)guess:(id)sender
{
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.tabBarController.view];
    hud.mode = MBProgressHUDModeDeterminate;
    hud.labelText = @"Finding Matches";
    hud.removeFromSuperViewOnHide = YES;
    [self.tabBarController.view addSubview:hud];
    [hud show:YES];
    
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.name = @"FaceRecognition";
    
    FaceRecognitionOperation *op = [[FaceRecognitionOperation alloc] init];
    op.progressUIBlock = ^(int currentFace, int totalFaces) {
        hud.progress = (float)currentFace/(float)totalFaces;
    };
    
    op.completionUIBlock = ^(NSDictionary *predictions) {
        [hud hide:YES];
        self.guesses = [NSMutableDictionary dictionaryWithDictionary:predictions];
        self.sortedKeys = [[self.guesses allKeys] sortedArrayUsingSelector:@selector(compare:)];
        [self.collectionView reloadData];
    };
    op.threshold = self.threshold;
    
    [queue addOperation:op];
}

- (IBAction)changeThreshold:(id)sender
{
    UIAlertView *av = [UIAlertView createAlertViewWithTitle:@"" message:@"Confidence 1-100" cancelButtonTitle:@"Cancel" otherButtonTitles:[NSArray arrayWithObject:@"OK"] onDismiss:^(int buttonIndex, UIAlertView *alertView) {
        NSString *input = [alertView textFieldAtIndex:0].text;
        int scaledConf = [input integerValue];
        if (scaledConf > 0 && scaledConf <= 100)
        {
            // we'll say 7,000 confidence is baiscally 0.
            float percentage = (float)scaledConf/100.0;
            self.threshold = 7000.0 - (7000.0 * percentage);
            
            [self performSelectorOnMainThread:@selector(guess:) withObject:nil waitUntilDone:NO];
        }
    } onCancel:^{
    }];
    
    av.alertViewStyle = UIAlertViewStylePlainTextInput;
    [av show];
}

@end
