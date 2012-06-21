#define SDLocalizedString(key) NSLocalizedStringWithDefaultValue((key), nil, [SDResources supportBundle], (key), @"")
#define SDLocalizedStringInTable(key, table) NSLocalizedStringWithDefaultValue((key), table, [SDResources supportBundle], (key), @"")
@class SDFileType;
@interface SDResources : NSObject
+ (NSBundle *)supportBundle;
+ (NSBundle *)imageBundle;
+ (UIImage *)imageNamed:(NSString *)name;
+ (UIImage *)iconForFolder;
+ (UIImage *)iconForFileType:(SDFileType *)fileType;
@end
