//
//  AppDelegate.h
//  FaceRecognition
//
//  Created by Michael Peterson on 2012-11-15.
//
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
+ (AppDelegate *)appDelegate;
- (void)populateCoreData;

@end
