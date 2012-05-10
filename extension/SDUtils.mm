#import "SDUtils.h"
#import "SDResources.h"
@implementation SDUtils
+ (NSString *)formatSize:(double)size {
	if(size < 1024.) return [NSString stringWithFormat:SDLocalizedString(@"%.1lf B"), size];
	size /= 1024.;
	if(size < 1024.) return [NSString stringWithFormat:SDLocalizedString(@"%.1lf KB"), size];
	size /= 1024.;
	return [NSString stringWithFormat:SDLocalizedString(@"%.1lf MB"), size];
}
@end
