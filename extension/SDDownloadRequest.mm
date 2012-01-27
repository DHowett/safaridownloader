#import "SDDownloadRequest.h"
#import <objc/runtime.h>

static const NSString *const kSDMAssociatedDownloadRequestKey = @"kSDMAssociatedDownloadRequestKey";

@implementation SDDownloadRequest
@synthesize urlRequest = _urlRequest, filename = _filename, mimeType = _mimeType, webFrame = _webFrame;

+ (SDDownloadRequest *)pendingRequestForContext:(id)context {
	return objc_getAssociatedObject(context, kSDMAssociatedDownloadRequestKey);
}

- (id)initWithURLRequest:(NSURLRequest *)request filename:(NSString *)filename mimeType:(NSString *)mimeType webFrame:(WebFrame *)webFrame context:(id)context {
	if((self = [super init]) != nil) {
		self.urlRequest = request;
		self.filename = filename;
		self.mimeType = mimeType;
		self.webFrame = webFrame;
		_context = context;
	} return self;
}

- (void)dealloc {
	[_urlRequest release];
	[_filename release];
	[_mimeType release];
	[_webFrame release];
	[super dealloc];
}

- (void)attachToContext {
	objc_setAssociatedObject(_context, kSDMAssociatedDownloadRequestKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)detachFromContext {
	objc_setAssociatedObject(_context, kSDMAssociatedDownloadRequestKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)matchesURLRequest:(NSURLRequest *)request {
	return [self.urlRequest isEqual:request];
}
@end
