/*
 */
%subclass MyAuthenticationView: AuthenticationView
%addivar(id savedChallenge);
%new(v@:@)
- (void)setSavedChallenge:(id)savedChallenge {
	[%ivar(savedChallenge) release];
	%ivar(savedChallenge) = [savedChallenge retain];
}

- (void)_logIn {  
	if (!%ivar(NSURLAuthenticationChallenge *_challenge)) {
		%ivar(NSURLAuthenticationChallenge *_challenge) = %ivar(savedChallenge);
	}
	%orig;
}

%new(v@:)
- (void)didShowBrowserPanel {  
	UINavigationBar* navBar = %ivar(UINavigationBar *_navigationBar);

	UINavigationItem* navItem = [[UINavigationItem alloc] initWithTitle:@"Secure Website"];
	[navItem setPrompt:@"This download requires authentication"];
	UIBarButtonItem* loginItem = [[UIBarButtonItem alloc] initWithTitle:@"Log In" style:UIBarButtonItemStyleDone target:self action:@selector(_logIn)];
	UIBarButtonItem* cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(_cancel)];
	navItem.rightBarButtonItem = loginItem;
	navItem.leftBarButtonItem = cancelItem;
	[navBar popNavigationItemAnimated:NO];
	[navBar pushNavigationItem:navItem animated:NO];
}

%end

static __attribute__((constructor)) void _avInit() {
	if(objc_getClass("AuthenticationView") != nil) {
		%init;
	}
}
