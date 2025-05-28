<cfscript>

	function beforeAll() {
		try {
			super.beforeAll();
		} catch ( any e ) {
			// lucee
			if ( ( e.message contains "has no private function with name [beforeAll]" ) ) {
				// do nothing
			// adobe
			} else if ( ( e.message contains "The beforeAll method was not found." ) ) {
				// do nothing
			} else if ( ( e.message contains "The method beforeAll does not exist." ) ) {
				// do nothing
			} else {
				rethrow;
			}
		}

		variables.javaSystem = createObject( "java", "java.lang.System" );
		variables.javaPaths = createObject( "java", "java.nio.file.Paths" );

		variables.playwrightVersion = fileRead( expandPath( "/cbPlaywright/playwright.version" ) );

		var driverDir = variables.javaSystem.getEnv( "CBPLAYWRIGHT_DRIVER_DIR" );
		var userHome = variables.javaSystem.getProperty( "user.home" );
		var fileSeparator = variables.javaSystem.getProperty( "file.separator" );
		if ( isNull( driverDir ) ) {
			driverDir = userHome & fileSeparator & ".CommandBox" & fileSeparator & "cfml" & fileSeparator & "modules" & fileSeparator & "commandbox-cbplaywright" & fileSeparator & "driver";
		}
		if ( right( driverDir, 1 ) != "/" ) {
			driverDir &= "/";
		}
		if ( !directoryExists( driverDir ) ) {
			throw( message = "Driver directory does not exist: [#driverDir#]", detail = "You may need to install this particular driver version using commandbox-cbplaywright." );
		}
		var driverVersion = deserializeJSON( fileRead( driverDir & "package/package.json" ) ).version;
		if ( variables.playwrightVersion != driverVersion ) {
			throw( message = "Incompatible driver version. cbPlaywright is using [#variables.playwrightVersion#] while the driver is using [#driverVersion#].  Please update one or the other. Hint: CommandBox users can run `cbplaywright driver install #variables.playwrightVersion# --force`" );
		}
		variables.javaSystem.setProperty( "playwright.cli.dir", driverDir );

		var playwrightOptions = createObject( "java", "com.microsoft.playwright.Playwright$CreateOptions" ).init();
		variables.playwright = createObject( "java", "com.microsoft.playwright.impl.PlaywrightImpl" ).create( playwrightOptions );
	}

	function afterAll() {
		if ( structKeyExists( variables, "playwright" ) ) {
			try {
				variables.playwright.close();
				structDelete( variables, "playwright" );
			} catch ( any e ) {
				writeDump( var = e );
			}
		}

		try {
			super.afterAll();
		} catch ( any e ) {
			// lucee
			if ( ( e.message contains "has no private function with name [afterAll]" ) ) {
				// do nothing
			// adobe
			} else if ( ( e.message contains "The afterAll method was not found." ) ) {
				// do nothing
			} else if ( ( e.message contains "The method afterAll does not exist." ) ) {
				// do nothing
			} else {
				rethrow;
			}
		}
	}

	public string function route() {
		var baseURL = ( CGI.HTTPS == "on" ? "https://" : "http://" ) & CGI.HTTP_HOST & "/";

		var pathSegments = [];
		for ( var currentKey in arguments ){
			arrayAppend( pathSegments, stripSurroundingSlashes( arguments[ currentKey ] ) );
		}

		return baseURL & pathSegments.filter( ( segment ) => len( segment ) > 0 ).toList( "/" );
	}

	public string function stripLeadingSlash( required string str ) {
		if ( len( arguments.str ) <= 0 ) {
			return arguments.str;
		}

		if ( arguments.str == "/" ) {
			return "";
		}

		if ( left( str, 1 ) == "/" ) {
			return mid( arguments.str, 2, len( arguments.str ) - 1 );
		}

		return arguments.str;
	}

	public string function stripTrailingSlash( required string str ) {
		if ( len( arguments.str ) <= 0 ) {
			return arguments.str;
		}

		if ( arguments.str == "/" ) {
			return "";
		}

		if ( right( str, 1 ) == "/" ) {
			return left( arguments.str, len( arguments.str ) - 1 );
		}

		return arguments.str;
	}

	public string function stripSurroundingSlashes( required string str ) {
		return stripLeadingSlash( stripTrailingSlash( arguments.str ) );
	}

	public any function regex( required string pattern, any flags = [] ) {
		param variables.javaPattern = createObject( "java", "java.util.regex.Pattern" );

		if ( !isArray( arguments.flags ) ) {
			arguments.flags = listToArray( arguments.flags, "" );
		}

		var flagBitMask = javacast( "null", "" );
		for ( var flag in arguments.flags ) {
			switch( flag ) {
				case "i": {
					flagBitMask = isNull( flagBitMask ) ?
						variables.javaPattern.CASE_INSENSITIVE :
						bitOr( flagBitMask, variables.javaPattern.CASE_INSENSITIVE );
					break;
				}
				case "m": {
					flagBitMask = isNull( flagBitMask ) ?
						variables.javaPattern.MULTILINE :
						bitOr( flagBitMask, variables.javaPattern.MULTILINE );
					break;
				}
				case "s": {
					flagBitMask = isNull( flagBitMask ) ?
						variables.javaPattern.DOTALL :
						bitOr( flagBitMask, variables.javaPattern.DOTALL );
					break;
				}
				case "u": {
					flagBitMask = isNull( flagBitMask ) ?
						variables.javaPattern.UNICODE_CASE :
						bitOr( flagBitMask, variables.javaPattern.UNICODE_CASE );
					break;
				}
				default: {
					throw( "Unsupported regex flag: [#flag#]" );
				}
			}
		}

		return isNull( flagBitMask ) ?
			variables.javaPattern.compile( arguments.pattern ) :
			variables.javaPattern.compile( arguments.pattern, flagBitMask );
	}

	public any function navigate( required any page, required string path ) {
		var navigateOptions = createObject( "java", "com.microsoft.playwright.Page$NavigateOptions" );
		return arguments.page.navigate( javacast( "string", arguments.path ), navigateOptions );
	}

	public any function locateElement( required any page, required string selector ) {
		var options = createObject( "java", "com.microsoft.playwright.Page$LocatorOptions" ).init();
		return arguments.page.locator( arguments.selector, options );
	}

	public any function getByRole(
		required any page,
		required any role,
		struct options = {},
		boolean checked,
		boolean disabled,
		boolean exact,
		boolean expanded,
		boolean includeHidden,
		numeric level,
		string name,
		boolean pressed,
		boolean selected
	) {
		var getByRoleOptions = createObject( "java", "com.microsoft.playwright.Page$GetByRoleOptions" ).init();
		if ( structKeyExists( arguments.options, "checked" ) ) {
			getByRoleOptions.setChecked( javacast( "boolean", arguments.options.checked ) );
		}
		if ( structKeyExists( arguments.options, "disabled" ) ) {
			getByRoleOptions.setDisabled( javacast( "boolean", arguments.options.disabled ) );
		}
		if ( structKeyExists( arguments.options, "exact" ) ) {
			getByRoleOptions.setExact( javacast( "boolean", arguments.options.exact ) );
		}
		if ( structKeyExists( arguments.options, "expanded" ) ) {
			getByRoleOptions.setExpanded( javacast( "boolean", arguments.options.expanded ) );
		}
		if ( structKeyExists( arguments.options, "includeHidden" ) ) {
			getByRoleOptions.setIncludeHidden( javacast( "boolean", arguments.options.includeHidden ) );
		}
		if ( structKeyExists( arguments.options, "level" ) ) {
			getByRoleOptions.setLevel( javacast( "int", arguments.options.level ) );
		}
		if ( structKeyExists( arguments.options, "name" ) ) {
			getByRoleOptions.setName( javacast( "string", arguments.options.name ) );
		}
		if ( structKeyExists( arguments.options, "pressed" ) ) {
			getByRoleOptions.setPressed( javacast( "boolean", arguments.options.pressed ) );
		}
		if ( structKeyExists( arguments.options, "selected" ) ) {
			getByRoleOptions.setSelected( javacast( "boolean", arguments.options.selected ) );
		}

		return arguments.page.getByRole(
			createObject( "java", "com.microsoft.playwright.options.AriaRole" )[ ucase( arguments.role ) ],
			getByRoleOptions
		);
	}

	public any function getByLabel( required any page, required any text, boolean exact = false ) {
		var options = createObject( "java", "com.microsoft.playwright.Page$GetByLabelOptions" ).init();
		options.setExact( javacast( "boolean", arguments.exact ) );
		return page.getByLabel( arguments.text, options );
	}

	public any function click( required any element ) {
		var options = createObject( "java", "com.microsoft.playwright.Locator$ClickOptions" ).init();
		return arguments.element.click( options );
	}

	public any function check( required any element, struct options = {} ) {
		var checkOptions = createObject( "java", "com.microsoft.playwright.Locator$CheckOptions" ).init();
		if ( structKeyExists( arguments.options, "force" ) ) {
			checkOptions.setForce( javacast( "boolean", arguments.options.force ) );
		}
		if ( structKeyExists( arguments.options, "noWaitAfter" ) ) {
			checkOptions.setNoWaitAfter( javacast( "boolean", arguments.options.noWaitAfter ) );
		}
		if ( structKeyExists( arguments.options, "position" ) ) {
			checkOptions.setPosition( javacast( "double", arguments.options.position.x ), javacast( "double", arguments.options.position.y ) );
		}
		if ( structKeyExists( arguments.options, "timeout" ) ) {
			checkOptions.setTimeout( javacast( "double", arguments.options.timeout ) );
		}
		if ( structKeyExists( arguments.options, "trial" ) ) {
			checkOptions.setTrial( javacast( "boolean", arguments.options.trial ) );
		}
		return arguments.element.check( checkOptions );
	}

	public any function fill( required any element, required string value ) {
		var options = createObject( "java", "com.microsoft.playwright.Locator$FillOptions" ).init();
		return arguments.element.fill( arguments.value, options );
	}

	public any function press( required any element, required string key ) {
		var options = createObject( "java", "com.microsoft.playwright.Locator$PressOptions" ).init();
		return arguments.element.press( arguments.key, options );
	}

	public any function launchBrowser( required any browserType, boolean headless = true ) {
		var browserLaunchOptions = createObject( "java", "com.microsoft.playwright.BrowserType$LaunchOptions" ).init();
		browserLaunchOptions.setHeadless( javacast( "boolean", arguments.headless ) );
		return arguments.browserType.launch( browserLaunchOptions );
	}

	public any function launchInteractiveBrowser( required any browserType ) {
		return launchBrowser( browserType = arguments.browserType, headless = false );
	}

	public any function screenshotPage( required any page, required string path, struct options = {} ) {
		arguments.options[ "path" ] = arguments.path;
		var screenshotOptions = createObject( "java", "com.microsoft.playwright.Page$ScreenshotOptions" ).init();
		for ( var optionName in arguments.options ) {
			var optionValue = arguments.options[ optionName ];
			switch ( optionName ) {
				case "clip":
					screenshotOptions.setClip(
						javacast( "double", optionValue.x ),
						javacast( "double", optionValue.y ),
						javacast( "double", optionValue.width ),
						javacast( "double", optionValue.height )
					);
					break;

				case "fullPage":
					screenshotOptions.setFullPage( javacast( "boolean", optionValue ) );
					break;

				case "omitBackground":
					screenshotOptions.setOmitBackground( javacast( "boolean", optionValue ) );
					break;

				case "path":
					screenshotOptions.setPath( toPath( optionValue ) );
					break;

				case "quality":
					screenshotOptions.setQuality( javacast( "int", optionValue ) );
					break;

				case "timeout":
					screenshotOptions.setTimeout( javacast( "double", optionValue ) );
					break;

				case "type":
					if ( optionValue == "png" ) {
						screenshotOptions.setType( createObject( "java", "com.microsoft.playwright.options.ScreenshotType" ).PNG );
					} else if ( optionValue == "jpeg" ) {
						screenshotOptions.setType( createObject( "java", "com.microsoft.playwright.options.ScreenshotType" ).JPEG );
					}
					break;
			}
		}

		page.screenshot( screenshotOptions );
		return arguments.page;
	}

	public any function traceContext(
		required any context,
		required string path,
		required function callback,
		struct startOptions = {},
		struct stopOptions = {}
	) {
		param arguments.startOptions.screenshots = true;
		param arguments.startOptions.snapshots = true;
		arguments.startOptions.sources = false;
		arguments.context.tracing().start( generateStartOptions( arguments.startOptions ) );

		try {
			arguments.callback( arguments.context );
		} catch ( any e ) {
			rethrow;
		} finally {
			arguments.stopOptions.path = arguments.path;
			arguments.context.tracing().stop( generateStopOptions( arguments.stopOptions ) );
		}
	}

	public any function waitForPopup( required any page, function callback ) {
		if ( isNull( arguments.callback ) ) {
			arguments.callback = function() {};
		}
		var runnable = createDynamicProxy( new Runnable( arguments.callback ), [ "java.lang.Runnable" ] );
		return arguments.page.waitForPopup( runnable );
	}

	public any function waitForNavigation( required any page, function callback ) {
		if ( isNull( arguments.callback ) ) {
			arguments.callback = function() {};
		}
		var runnable = createDynamicProxy( new Runnable( arguments.callback ), [ "java.lang.Runnable" ] );
		var options = createObject( "java", "com.microsoft.playwright.Page$WaitForNavigationOptions" ).init();
		return arguments.page.waitForNavigation( options, runnable );
	}

	public any function waitForLoadState( required any page ) {
		var loadState = createObject( "java", "com.microsoft.playwright.options.LoadState" ).LOAD;
		var options = createObject( "java", "com.microsoft.playwright.Page$WaitForLoadStateOptions" ).init();
		return arguments.page.waitForLoadState( loadState, options );
	}

	public any function waitForUrl( required any page, required string url, numeric timeout ) {
		var options = createObject( "java", "com.microsoft.playwright.Page$WaitForURLOptions" ).init();
		if ( !isNull( arguments.timeout ) ) {
			options.setTimeout( javacast( "double", arguments.timeout ) );
		}
		return arguments.page.waitForUrl( arguments.url, options );
	}

	private any function generateStartOptions( required struct options ) {
		var startOptions = createObject( "java", "com.microsoft.playwright.Tracing$StartOptions" ).init();
		for ( var optionName in arguments.options ) {
			var optionValue = arguments.options[ optionName ];
			switch ( optionName ) {
				case "screenshots":
					startOptions.setScreenshots( javacast( "boolean", optionValue ) );
					break;

				case "snapshots":
					startOptions.setSnapshots( javacast( "boolean", optionValue ) );
					break;

				case "sources":
					startOptions.setSources( javacast( "boolean", optionValue ) );
					break;

				case "title":
					startOptions.setTitle( javacast( "string", optionValue ) );
					break;

				case "name":
					startOptions.setName( javacast( "string", optionValue ) );
					break;
			}
		}
		return startOptions;
	}

	private any function generateStopOptions( required struct options ) {
		var stopOptions = createObject( "java", "com.microsoft.playwright.Tracing$StopOptions" ).init();
		for ( var optionName in arguments.options ) {
			var optionValue = arguments.options[ optionName ];
			switch ( optionName ) {
				case "path":
					stopOptions.setPath( toPath( optionValue ) );
					break;
			}
		}
		return stopOptions;
	}

	public any function newContext(
		required any browser,
		struct options = {}
	) {
		return arguments.browser.newContext( generateNewContextOptions( arguments.options ) );
	}

	public any function storeStorageState(
		required any context,
		required string path
	) {
		return arguments.context.storageState(
			createObject( "java", "com.microsoft.playwright.BrowserContext$StorageStateOptions" )
				.init()
				.setPath( toPath( arguments.path ) )
		);
	}

	public any function newRecordedContextForBrowser(
		required any browser,
		required string directory,
		required function callback,
		struct options = {}
	) {
		arguments.options.recordVideoDir = arguments.directory;
		var context = arguments.browser.newContext( generateNewContextOptions( arguments.options ) );
		try {
			arguments.callback( context );
		} catch ( any e ) {
			rethrow;
		} finally {
			context.close();
		}
		return arguments.browser;
	}

	private any function generateNewContextOptions( required struct options ) {
		var newContextOptions = createObject( "java", "com.microsoft.playwright.Browser$NewContextOptions" ).init();
		for ( var optionName in arguments.options ) {
			var optionValue = arguments.options[ optionName ];
			switch ( optionName ) {
				case "recordVideoDir":
					newContextOptions.setRecordVideoDir( toPath( optionValue ) );
					break;

				case "recordVideoSize":
					newContextOptions.setRecordVideoSize(
						javacast( "int", optionValue.width ),
						javacast( "int", optionValue.height )
					);
					break;

				case "storageStatePath":
					newContextOptions.setStorageStatePath( toPath( optionValue ) );
					break;
			}
		}
		return newContextOptions;
	}

	private any function toPath( required string path ) {
		return variables.javaPaths.get( javacast( "String", expandPath( arguments.path ) ), javacast( "String[]", [] ) );
	}

	private string function platformDir() {
		var name = lCase( variables.javaSystem.getProperty( "os.name" ) );
		var arch = lCase( variables.javaSystem.getProperty( "os.arch" ) );

		if ( name contains "windows" ) {
		  return "win32_x64";
		}

		if ( name contains "linux" ) {
			if ( arch == "aarch64" ) {
				return "linux-arm64";
			} else {
				return "linux";
			}
		}
		if ( name contains "mac os x" ) {
			return "mac";
		}
		throw( "Unexpected os.name value: " & name );
	}

</cfscript>
