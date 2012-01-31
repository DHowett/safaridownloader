#import "../extension/DownloaderCommon.h"
@class SDFileType;
@interface SDResources : NSObject
+ (NSBundle *)supportBundle;
+ (NSBundle *)imageBundle;
+ (UIImage *)imageNamed:(NSString *)name;
+ (UIImage *)iconForFolder;
+ (UIImage *)iconForFileType:(SDFileType *)fileType;
@end