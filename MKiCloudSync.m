//
//  MKiCloudSync.m
//  iCloud1
//
//  Created by Mugunth Kumar on 20/11/11.
//  Copyright (c) 2011 Steinlogic. All rights reserved.

//  As a side note on using this code, you might consider giving some credit to me by
//	1) linking my website from your app's website 
//	2) or crediting me inside the app's credits page 
//	3) or a tweet mentioning @mugunthkumar
//	4) A paypal donation to mugunth.kumar@gmail.com
//
//  A note on redistribution
//	if you are re-publishing after editing, please retain the above copyright notices


#import "MKiCloudSync.h"

@implementation MKiCloudSync

+(void) updateToiCloud:(NSNotification*) notificationObject {
    
#ifdef DEBUG
    NSLog(@"Updating to iCloud");
#endif
    
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        [[NSUbiquitousKeyValueStore defaultStore] setObject:obj forKey:key];
    }];
    
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

+(void) updateFromiCloud:(NSNotification*) notificationObject {
    
#ifdef DEBUG
    NSLog(@"Updating from iCloud");
#endif
  
    NSUbiquitousKeyValueStore *iCloudStore = [NSUbiquitousKeyValueStore defaultStore];
    NSDictionary *dict = [iCloudStore dictionaryRepresentation];
    
    // prevent NSUserDefaultsDidChangeNotification from being posted while we update from iCloud
    
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:NSUserDefaultsDidChangeNotification 
                                                  object:nil];

    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        [[NSUserDefaults standardUserDefaults] setObject:obj forKey:key];
    }];

    [[NSUserDefaults standardUserDefaults] synchronize];

    // enable NSUserDefaultsDidChangeNotification notifications again

    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(updateToiCloud:) 
                                                 name:NSUserDefaultsDidChangeNotification                                                    object:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMKiCloudSyncNotification object:nil];
}

+(void) start {
    
    if(NSClassFromString(@"NSUbiquitousKeyValueStore")) { // is iOS 5?
        
        if([NSUbiquitousKeyValueStore defaultStore]) {  // is iCloud enabled
            
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(updateFromiCloud:) 
                                                         name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification 
                                                       object:nil];
            
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(updateToiCloud:) 
                                                         name:NSUserDefaultsDidChangeNotification                                                    object:nil];
#ifdef DEBUG
        } else {
            NSLog(@"iCloud not enabled");          
#endif
        }
    }
#ifdef DEBUG
    else {
        NSLog(@"Not an iOS 5 device");        
    }
#endif
}

+ (void) dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification 
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:NSUserDefaultsDidChangeNotification 
                                                  object:nil];
}
@end
