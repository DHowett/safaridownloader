//
//  Resources.m
//  AttachmentSaver
//
//  Created by Youssef Francis on 7/30/09.
//  Copyright 2009 Brancipater Software. All rights reserved.
//

#import "Resources.h"
#define SUPPORT_BUNDLE_PATH @"/Library/Application Support/AttachmentSaver"

@implementation Resources

+ (void)initialize {
  if (self == [Resources class]) {
    resourceBundle = [[NSBundle alloc] initWithPath:SUPPORT_BUNDLE_PATH];
  } 
}

+ (UIImage *)iconForFolder {
  NSString* iconPath = [resourceBundle pathForResource:@"folder" 
                                                ofType:@"png" 
                                           inDirectory:@"FileIcons"];
  return [UIImage imageWithContentsOfFile:iconPath];
}

+ (UIImage *)iconForExtension:(NSString *)extension {
  NSString *iconPath = nil;
  if(extension && [extension length] > 0) 
    iconPath = [resourceBundle pathForResource:[extension lowercaseString]
                                        ofType:@"png" 
                                   inDirectory:@"FileIcons"];
  if(!iconPath) 
    iconPath = [resourceBundle pathForResource:@"unknownfile" 
                                        ofType:@"png"];
  return [UIImage imageWithContentsOfFile:iconPath];
}

@end
