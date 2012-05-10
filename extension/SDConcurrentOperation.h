#import <Foundation/Foundation.h>

@interface SDConcurrentOperation : NSOperation <NSCoding> {
	BOOL _executing;
	BOOL _finished;
}
@property (nonatomic, assign, getter = isExecuting) BOOL executing;
@property (nonatomic, assign, getter = isFinished) BOOL finished;
- (void)complete;
@end
