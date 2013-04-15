//
//  AppDelegate.m
//  FaceRecognition
//
//  Created by Michael Peterson on 2012-11-15.
//
//

#import "AppDelegate.h"
#import <CoreData/CoreData.h>
#import "Photo.h"
#import "NSManagedObjectContext+Fetch.h"
#import "FaceDetector.h"

@interface AppDelegate()
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSString *persistentStorePath;
@end

@implementation AppDelegate
@synthesize managedObjectContext;
@synthesize persistentStoreCoordinator;
@synthesize persistentStorePath;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backgroundSave:) name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
    
    [self populateCoreData];
    [[FaceDetector sharedInstance] startLookingForFaces:^(int photoCount, int totalPhotos) {
        //NSLog(@"%d of %d", photoCount, totalPhotos);
    }  completionBlock:nil managedObjectContext:[self managedObjectContext]];
    [[FaceDetector sharedInstance] trainRecognizer];
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)backgroundSave:(NSNotification *)n
{
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(backgroundSave:) withObject:n waitUntilDone:YES];
        return;
    }
    
    [[self managedObjectContext] mergeChangesFromContextDidSaveNotification:n];
}

- (NSString *)persistentStorePath
{
    if (persistentStorePath == nil)
    {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths lastObject];
        self.persistentStorePath = [documentsDirectory stringByAppendingPathComponent:@"photoModel.sqlite"];
    }
    return persistentStorePath;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (persistentStoreCoordinator == nil)
    {
        NSURL *storeUrl = [NSURL fileURLWithPath:self.persistentStorePath];
        self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[NSManagedObjectModel mergedModelFromBundles:nil]];
        NSError *error = nil;
        NSPersistentStore *persistentStore = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error];
        NSAssert3(persistentStore != nil, @"Unhandled error adding persistent store in %s at line %d: %@", __FUNCTION__, __LINE__, [error localizedDescription]);
    }
    return persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext
{
    
    NSThread * thisThread = [NSThread currentThread];
    if (thisThread == [NSThread mainThread])
    {
        //Main thread just return default context
        if (managedObjectContext == nil)
        {
            managedObjectContext = [[NSManagedObjectContext alloc] init];
            [managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
        }
        return managedObjectContext;
    }
    else
    {
        NSManagedObjectContext * threadManagedObjectContext = [[thisThread threadDictionary] objectForKey:@"context"];
        if (threadManagedObjectContext == nil)
        {
            threadManagedObjectContext = [[NSManagedObjectContext alloc] init];
            [threadManagedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
            [[thisThread threadDictionary] setObject:threadManagedObjectContext forKey:@"context"];
        }
        return threadManagedObjectContext;
    }
}

+ (AppDelegate *)appDelegate
{
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)populateCoreData
{
    NSSet *allPhotos = [[[AppDelegate appDelegate] managedObjectContext] fetchObjectsForEntityName:@"Photo"withPredicate:nil];
    NSManagedObjectContext *context = [[AppDelegate appDelegate] managedObjectContext];
    
    if ([allPhotos count] == 0)
    {
        NSString *bundleRoot = [[NSBundle mainBundle] bundlePath];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSArray *dirContents = [fm contentsOfDirectoryAtPath:bundleRoot error:nil];
        NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.JPG' or self ENDSWITH '.PNG'"];
        NSArray *images = [dirContents filteredArrayUsingPredicate:fltr];
        
        for (NSString *str in images)
        {
            Photo *photoObject = (Photo *)[NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:context];
            photoObject.imagePath = str;
            [context save:nil];
        }
    }
    
}

@end
