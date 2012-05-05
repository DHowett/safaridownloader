#import "../extension/DownloaderCommon.h"
#define SDLocalizedString(key) NSLocalizedStringWithDefaultValue((key), nil, [SDResources supportBundle], (key), @"")
@class SDFileType;
@interface SDResources : NSObject
+ (NSBundle *)supportBundle;
+ (NSBundle *)imageBundle;
+ (UIImage *)imageNamed:(NSString *)name;
+ (UIImage *)iconForFolder;
+ (UIImage *)iconForFileType:(SDFileType *)fileType;
@end
