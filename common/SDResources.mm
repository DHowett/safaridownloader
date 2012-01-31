#import "SDResources.h"
#import "SDFileType.h"

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

+ (UIImage *)iconForFileType:(SDFileType *)fileType {
	NSString *primaryMIME = [fileType.primaryMIMEType stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
	UIImage *icon = [self imageNamed:[NSString stringWithFormat:@"Icons/%@.png", primaryMIME]];
	if(!icon) {
		NSString *genericType = [fileType.genericType stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
		icon = [self imageNamed:[NSString stringWithFormat:@"Icons/%@.png", genericType]];
	}
	return icon;

}

@end
