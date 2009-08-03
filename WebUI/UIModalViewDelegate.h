/**
 * This header is generated by class-dump-z 0.1-11p.
 * class-dump-z is Copyright (C) 2009 by KennyTM~, licensed under GPLv3.
 */

#import "NSObject.h"


@protocol UIModalViewDelegate <NSObject>
@optional
-(void)modalView:(id)view clickedButtonAtIndex:(int)index;
-(void)modalViewCancel:(id)cancel;
-(void)willPresentModalView:(id)view;
-(void)didPresentModalView:(id)view;
-(void)modalView:(id)view willDismissWithButtonIndex:(int)buttonIndex;
-(void)modalView:(id)view didDismissWithButtonIndex:(int)buttonIndex;
@end

