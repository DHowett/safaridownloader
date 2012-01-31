#import "UIKitExtra/UIWebDocumentView.h"
#import "UIKitExtra/UIWebViewWebViewDelegate.h"

#import "SDMVersioning.h"
#import "SDMCommonClasses.h"
/* {{{ struct interaction on 5.0+ */
struct _interaction_ios5 {
	NSTimer *timer;
	CGPoint location;
	BOOL isBlocked;
	BOOL isCancelled;
	BOOL isOnWebThread;
	BOOL isDisplayingHighlight;
	BOOL attemptedClick;
	CGPoint lastPanTranslation;
	DOMNode *element;
	id delegate;
	UIActionSheet *interactionSheet;
	NSArray *elementActions;
	BOOL allowsImageSheet;
	BOOL allowsDataDetectorsSheet;
	BOOL allowsLinkSheet;
	BOOL acceptsFirstResponder;
} _interaction;
/* }}} */
void _init_interaction() {
}
