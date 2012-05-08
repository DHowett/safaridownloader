#import <Foundation/Foundation.h>

@interface SDConcurrentOperation : NSOperation <NSCoding> {
	BOOL _executing;
	BOOL _finished;
	BOOL _cancelled;
}
@property (nonatomic, assign, getter = isExecuting) BOOL executing;
@property (nonatomic, assign, getter = isFinished) BOOL finished;
@property (nonatomic, assign, getter = isCancelled) BOOL cancelled;
- (void)complete;
@end
