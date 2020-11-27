//
//  MAList.m
//  MAList
//
//  Created by j on 4/22/20.
//  Copyright © 2020 Jeremy Legendre. All rights reserved.
//

#import "MAList.h"
#import <AppKit/NSImage.h>

@interface MAList ()
@property sqlite3 *db;
@property (strong, nonatomic) NSMutableArray<MALApp*>* apps;
@end

@interface MALApp ()
@property (readonly, strong, nonatomic) NSNumber *itemId;
@property (readonly, strong, nonatomic) NSNumber *type;

- (instancetype)initWithSqlStatement:(sqlite3_stmt*)stmt;
@end

@implementation MAList

- (NSString*)getDbPath {
    char icon_cache_path[1024];
    confstr(_CS_DARWIN_USER_DIR, icon_cache_path, 1024);
    strcat(icon_cache_path, "com.apple.dock.launchpad/db/db");
    return [NSString stringWithUTF8String:icon_cache_path];
}

- (BOOL)createAppList {
    
    int err;
    err = sqlite3_open_v2([[self getDbPath] UTF8String], &_db, 6, NULL);
    if(err != SQLITE_OK)
        return NO;
    
    char *sql = "SELECT items.rowid AS id, items.type, \
        apps.title AS app_title, bundleid AS bundle_id, \
        image_cache.image_data AS image_data, \
        length(image_cache.image_data) AS image_length, \
        apps.bookmark AS bookmark\
        FROM items \
        LEFT JOIN apps ON apps.item_id = items.rowid \
        LEFT JOIN image_cache ON image_cache.item_id = items.rowid\
        WHERE items.uuid NOT IN ('ROOTPAGE', 'HOLDINGPAGE', \
        'ROOTPAGE_DB', 'HOLDINGPAGE_DB', \
        'ROOTPAGE_VERS', 'HOLDINGPAGE_VERS') \
        AND app_title NOT NULL \
        ORDER BY items.parent_id, items.ordering;";
    
    sqlite3_stmt *stmt = NULL;
    err = sqlite3_prepare_v2(_db, sql, -1, &stmt, 0);
    if (err != SQLITE_OK) {
        NSLog(@"Error preparing statement");
        return NO;
    }
    
    err = sqlite3_step(stmt);
    if (err != SQLITE_ROW && err != SQLITE_DONE) {
        NSLog(@"Error on first step, %i", err);
    }
    
    while (err != SQLITE_DONE) {
        MALApp *app = [[MALApp alloc] initWithSqlStatement:stmt];
        if(app != NULL)
            [_apps addObject:app];
        err = sqlite3_step(stmt);
    }
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
    _apps = [[_apps sortedArrayUsingDescriptors:@[sort]] mutableCopy];
    
    return YES;
}

- (void)refresh {
    _apps = [[NSMutableArray alloc] init];
    [self createAppList];
}

- (MAList*)init {
    if (self = [super init]) {
        _apps = [[NSMutableArray alloc] init];
        if (![self createAppList])
            return nil;
    }
    return self;
}

+ (NSMutableArray<MALApp*>*)apps {
    MAList *maList = [self sharedInstance];
    return [maList apps];
}

+ (instancetype)sharedInstance {
    static MAList *maList = nil;
    @synchronized(self) {
        if (!maList) {
            maList = [[self alloc] init];
        }
    }
    return maList;
}

@end

@implementation MALApp
- (instancetype)initWithSqlStatement:(sqlite3_stmt*)stmt {
    if (self = [super init]) {
        _itemId = [NSNumber numberWithInt:sqlite3_column_int(stmt, 0)];
        _type = [NSNumber numberWithInt:sqlite3_column_int(stmt, 1)];
        _title = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmt, 2)];
        _bundleId = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmt, 3)];
        const void *image_bytes = sqlite3_column_blob(stmt, 4);
        int img_size = sqlite3_column_int(stmt, 5);
        
        _icon = [[NSImage alloc] initWithData:[NSData dataWithBytes:image_bytes length:img_size]];
        if(_icon == NULL) {
            _icon = [[NSWorkspace sharedWorkspace] iconForFileType: NSFileTypeForHFSTypeCode(kGenericApplicationIcon)];
            [_icon setSize:NSMakeSize(144.0,144.0)];
        }
        
        const void *bookmark_data = sqlite3_column_blob(stmt, 6);
        BOOL bookmarkIsStale = NO;
        NSError* theError = nil;
        _path = [NSURL URLByResolvingBookmarkData:[NSData dataWithBytes:bookmark_data length:1024]
                                                       options:NSURLBookmarkResolutionWithoutUI
                                                 relativeToURL:nil
                                           bookmarkDataIsStale:&bookmarkIsStale
                                                         error:&theError];
        
        if (bookmarkIsStale || (theError != nil)) {
            _path = nil;
        }
    }
    
    return self;
}

@end
