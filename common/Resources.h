#import "../extension/DownloaderCommon.h"
@interface SDResources : NSObject
+ (NSBundle *)supportBundle;
+ (NSBundle *)imageBundle;
+ (UIImage *)imageNamed:(NSString *)name;
+ (UIImage *)iconForFolder;
+ (UIImage *)iconForExtension:(NSString *)extension;
@end
