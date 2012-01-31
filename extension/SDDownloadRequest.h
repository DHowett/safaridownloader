@class WebFrame;

@interface SDDownloadRequest : NSObject {
	NSURLRequest *_urlRequest;
	NSString *_filename;
	NSString *_mimeType;
	WebFrame *_webFrame;
	id _context;
}
@property (nonatomic, retain) NSURLRequest *urlRequest;
@property (nonatomic, retain) NSString *filename;
@property (nonatomic, retain) NSString *mimeType;
@property (nonatomic, retain) WebFrame *webFrame;
@property (nonatomic, assign) BOOL supportsViewing;
+ (SDDownloadRequest *)pendingRequestForContext:(id)context;
- (id)initWithURLRequest:(NSURLRequest *)request filename:(NSString *)filename mimeType:(NSString *)mimeType webFrame:(WebFrame *)webFrame context:(id)context;
- (void)attachToContext;
- (void)detachFromContext;
- (BOOL)matchesURLRequest:(NSURLRequest *)request;
@end
