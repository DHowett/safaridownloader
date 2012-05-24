#import "SDUtils.h"
#import "SDResources.h"
@implementation SDUtils
+ (NSString *)formatSize:(double)size {
	if(size < 1024.) return [NSString stringWithFormat:SDLocalizedString(@"SIZE_BYTES"), size];
	size /= 1024.;
	if(size < 1024.) return [NSString stringWithFormat:SDLocalizedString(@"SIZE_KILOBYTES"), size];
	size /= 1024.;
	return [NSString stringWithFormat:SDLocalizedString(@"SIZE_MEGABYTES"), size];
}
@end
