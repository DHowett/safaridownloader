#import "Resources.h"

@interface UIImage (iPhonePrivate)
+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle;
@end

static NSBundle *_supportBundle;
static NSBundle *_imageBundle;

@implementation SDResources

+ (void)initialize {
	_supportBundle = [[NSBundle alloc] initWithPath:SUPPORT_BUNDLE_PATH];
	_imageBundle = [[NSBundle alloc] initWithPath:[_supportBundle pathForResource:@"Images" ofType:@"bundle"]];
}

+ (NSBundle *)supportBundle { return _supportBundle; }
+ (NSBundle *)imageBundle { return _imageBundle; }

+ (UIImage *)imageNamed:(NSString *)name {
	return [UIImage imageNamed:name inBundle:_imageBundle];
}

+ (UIImage *)iconForFolder {
	return [self imageNamed:@"Icons/folder.png"];
}

+ (UIImage *)iconForExtension:(NSString *)extension {
	return [self imageNamed:[NSString stringWithFormat:@"Icons/%@.png", ([extension length] > 0 ? [extension lowercaseString] : @"unknown")]];
}

@end
