#import "SDConcurrentOperation.h"

@interface SDConcurrentOperation ()
- (void)main_;
@end


@implementation SDConcurrentOperation
@synthesize executing = _executing, finished = _finished;
- (BOOL)isConcurrent { return YES; }

- (BOOL)isExecuting { return _executing; }
- (BOOL)isFinished { return _finished; }
- (BOOL)isCancelled { return _cancelled; }

- (void)setExecuting:(BOOL)executing {
	[self willChangeValueForKey:@"isExecuting"];
	_executing = executing;
	[self didChangeValueForKey:@"isExecuting"];
}

- (void)setFinished:(BOOL)finished {
	[self willChangeValueForKey:@"isFinished"];
	_finished = finished;
	[self didChangeValueForKey:@"isFinished"];
}

- (void)setCancelled:(BOOL)cancelled {
	[self willChangeValueForKey:@"isCancelled"];
	_cancelled = cancelled;
	[self didChangeValueForKey:@"isCancelled"];
}

- (void)start {
	if(self.cancelled) {
		self.finished = YES;
		return;
	}
	self.executing = YES;
	[NSThread detachNewThreadSelector:@selector(main_) toTarget:self withObject:nil];
}

- (void)main_ {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self main];
	[pool drain];
}

- (void)complete {
	self.executing = NO;
	self.finished = YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super init];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	return;
}
@end
