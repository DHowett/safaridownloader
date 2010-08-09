#include <substrate.h>
@class MyAuthenticationView;
static Class $MyAuthenticationView;

static void $_ungrouped$MyAuthenticationView$setSavedChallenge$(id self, SEL _cmd, id savedChallenge) {
	[MSHookIvar<id>(self, "savedChallenge") release];
	MSHookIvar<id>(self, "savedChallenge") = [savedChallenge retain];
}

static void (*__ungrouped$MyAuthenticationView$_logIn)(id, SEL);static void $_ungrouped$MyAuthenticationView$_logIn(id self, SEL _cmd) {  
	if (!MSHookIvar<NSURLAuthenticationChallenge *>(self, "_challenge")) {
		MSHookIvar<NSURLAuthenticationChallenge *>(self, "_challenge") = MSHookIvar<id>(self, "savedChallenge");
	}
	// MS Supercall closure (not too pretty, but effective.)
	__ungrouped$MyAuthenticationView$_logIn(self, _cmd);
}


static void $_ungrouped$MyAuthenticationView$didShowBrowserPanel(id self, SEL _cmd) {  
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
		$MyAuthenticationView = objc_allocateClassPair(objc_getClass("AuthenticationView"), "MyAuthenticationView", 0);
		class_addIvar($MyAuthenticationView, "savedChallenge", sizeof(id), 0, @encode(id));
		objc_registerClassPair($MyAuthenticationView);
		Class $$MyAuthenticationView = $MyAuthenticationView;
		class_addMethod($$MyAuthenticationView, @selector(setSavedChallenge:), (IMP)&$_ungrouped$MyAuthenticationView$setSavedChallenge$, "v@:@");
		MSHookMessageEx($$MyAuthenticationView, @selector(_logIn), (IMP)&$_ungrouped$MyAuthenticationView$_logIn, (IMP*)&__ungrouped$MyAuthenticationView$_logIn);
		class_addMethod($$MyAuthenticationView, @selector(didShowBrowserPanel), (IMP)&$_ungrouped$MyAuthenticationView$didShowBrowserPanel, "v@:");
	}
}

// vim:ft=objc
