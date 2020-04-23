# libMAList
This library will provide you an alphabetical list of all installed apps on macOS. libMAList works by parsing the LaunchPad database and creating an array of `MALApp` objects that contain an apps name, bundle id, icon, and path. 

## How to

```
@interface MALApp : NSObject
@property (readonly, strong, nonatomic) NSString *title;
@property (readonly, strong, nonatomic) NSString *bundleId;
@property (readonly, strong, nonatomic) NSImage *icon;
@property (readonly, strong, nonatomic) NSURL *path;
@end

@interface MAList : NSObject
+ (instancetype)sharedInstance;
+ (NSMutableArray<MALApp*>*)apps;
- (void)refresh;
@end

...

NSArray *allApps = [MAList apps];
for(MALApp *app in allApps)
  NSLog(@"%@", app.title);

...

/* Suspect a new app has been installed? Running a daemon and want to refresh periodically? */
[[MAList sharedInstance] refresh];

*allApps = [MAList apps];
for(MALApp *app in allApps)
  NSLog(@"%@", app.title);
```
