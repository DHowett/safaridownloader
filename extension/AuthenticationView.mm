#include <substrate.h>
#include <objc/message.h>
@class MyAuthenticationView;
@class AuthenticationView; 

#include "SDMCommonClasses.h"
Class SDM$MyAuthenticationView;

static Class _logos_class$_ungrouped$MyAuthenticationView,
	     _logos_metaclass$_ungrouped$MyAuthenticationView;
static Class _logos_superclass$_ungrouped$MyAuthenticationView;
static void (*_logos_orig$_ungrouped$MyAuthenticationView$_logIn)(MyAuthenticationView*, SEL);
static Class _logos_static_class$MyAuthenticationView; 

static void _logos_method$_ungrouped$MyAuthenticationView$setSavedChallenge$(MyAuthenticationView* self, SEL _cmd, id savedChallenge) {
	[MSHookIvar<id>(self, "savedChallenge") release];
	MSHookIvar<id>(self, "savedChallenge") = [savedChallenge retain];
}

static void _logos_super$_ungrouped$MyAuthenticationView$_logIn(MyAuthenticationView* self, SEL _cmd) {
	return ((void (*)(MyAuthenticationView*, SEL))class_getMethodImplementation(_logos_superclass$_ungrouped$MyAuthenticationView, @selector(_logIn)))(self, _cmd);
}
static void _logos_method$_ungrouped$MyAuthenticationView$_logIn(MyAuthenticationView* self, SEL _cmd) {  
	if (!MSHookIvar<NSURLAuthenticationChallenge *>(self, "_challenge")) {
		MSHookIvar<NSURLAuthenticationChallenge *>(self, "_challenge") = MSHookIvar<id>(self, "savedChallenge");
	}
	_logos_orig$_ungrouped$MyAuthenticationView$_logIn(self, _cmd);
}

static void _logos_method$_ungrouped$MyAuthenticationView$didShowBrowserPanel(MyAuthenticationView* self, SEL _cmd) {  
	UINavigationBar* navBar = MSHookIvar<UINavigationBar *>(self, "_navigationBar");

	UINavigationItem* navItem = [[UINavigationItem alloc] initWithTitle:@"Secure Website"];
	[navItem setPrompt:@"This download requires authentication"];
	UIBarButtonItem* loginItem = [[UIBarButtonItem alloc] initWithTitle:@"Log In" style:UIBarButtonItemStyleDone target:self action:@selector(_logIn)];
	UIBarButtonItem* cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(_cancel)];
	navItem.rightBarButtonItem = loginItem;
	navItem.leftBarButtonItem = cancelItem;
	[navBar popNavigationItemAnimated:NO];
	[navBar pushNavigationItem:navItem animated:NO];
}

static __attribute__((constructor)) void _avInit() {
	if(objc_getClass("AuthenticationView") != nil) {
		_logos_class$_ungrouped$MyAuthenticationView = objc_allocateClassPair(objc_getClass("AuthenticationView"), "MyAuthenticationView", 0);
		_logos_metaclass$_ungrouped$MyAuthenticationView = object_getClass(_logos_class$_ungrouped$MyAuthenticationView);
		_logos_superclass$_ungrouped$MyAuthenticationView = class_getSuperclass(_logos_class$_ungrouped$MyAuthenticationView);
		class_addIvar(_logos_class$_ungrouped$MyAuthenticationView, "savedChallenge", sizeof(id), 0, @encode(id));
		{
			Class _class = _logos_class$_ungrouped$MyAuthenticationView;
			Method _method = class_getInstanceMethod(_class, @selector(_logIn));
			if (_method) {
				_logos_orig$_ungrouped$MyAuthenticationView$_logIn = _logos_super$_ungrouped$MyAuthenticationView$_logIn;
				if (!class_addMethod(_class, @selector(_logIn), (IMP)&_logos_method$_ungrouped$MyAuthenticationView$_logIn, method_getTypeEncoding(_method))) {
					_logos_orig$_ungrouped$MyAuthenticationView$_logIn = (void (*)(MyAuthenticationView*, SEL))method_getImplementation(_method);
					_logos_orig$_ungrouped$MyAuthenticationView$_logIn = (void (*)(MyAuthenticationView*, SEL))method_setImplementation(_method, (IMP)&_logos_method$_ungrouped$MyAuthenticationView$_logIn);
				}
			}
		}
		class_addMethod(_logos_class$_ungrouped$MyAuthenticationView, @selector(setSavedChallenge:), (IMP)&_logos_method$_ungrouped$MyAuthenticationView$setSavedChallenge$, "v@:@");
		class_addMethod(_logos_class$_ungrouped$MyAuthenticationView, @selector(didShowBrowserPanel), (IMP)&_logos_method$_ungrouped$MyAuthenticationView$didShowBrowserPanel, "v@:");
		objc_registerClassPair(_logos_class$_ungrouped$MyAuthenticationView);
		_logos_static_class$MyAuthenticationView = _logos_class$_ungrouped$MyAuthenticationView;
		SDM$MyAuthenticationView = _logos_static_class$MyAuthenticationView;
	}
}
