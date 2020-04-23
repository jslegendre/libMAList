//
//  MAList.h
//  MAList
//
//  Created by j on 4/22/20.
//  Copyright © 2020 Jeremy Legendre. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

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
