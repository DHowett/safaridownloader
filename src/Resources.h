//
//  Resources.h
//  AttachmentSaver
//
//  Created by Youssef Francis on 7/30/09.
//  Copyright 2009 Brancipater Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Resources : NSObject
NSBundle* resourceBundle;
+ (UIImage *)iconForFolder;
+ (UIImage *)iconForExtension:(NSString *)extension;
@end
