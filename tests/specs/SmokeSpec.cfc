component extends="cbPlaywright.models.PlaywrightTestCase" {

	function run() {
		describe( "smoke test", () => {
			it( "can visit google and record screenshots and videos and a trace", function() {
				if ( directoryExists( expandPath( "/tests/results" ) ) ) {
					directoryDelete( expandPath( "/tests/results" ), true );
				}
				directoryCreate( expandPath( "/tests/results" ) );

				var browser = launchBrowser( variables.playwright.chromium() );
				newRecordedContextForBrowser(
					browser,
					"/tests/results/videos",
					function( context ) {
						traceContext(
							context,
							"/tests/results/trace.zip",
							function() {
								var page = context.newPage();
								navigate( page, "https://google.com" );
								waitForLoadState( page );
								expect( page.title() ).toBe( "Google" );
								var searchBox = locateElement( page, '[aria-label="Search"]' );
								click( searchBox );
								fill( searchBox, "playwright" );
								press( searchBox, "Enter" );
								expect( page.url() ).toInclude( "https://www.google.com/search?q=playwright" );
								click(
									locateElement(
										page,
										"text=Playwright: Fast and reliable end-to-end testing for modern ..."
									)
								);
								waitForUrl( page, "https://playwright.dev/" );
								screenshotPage( page, "/tests/results/playwright.png" );
							}
						);
					}
				);

				expect( fileExists( expandPath( "/tests/results/trace.zip" ) ) ).toBeTrue( "trace.zip should have been created" );
				expect( fileExists( expandPath( "/tests/results/playwright.png" ) ) ).toBeTrue( "playwright.png should have been created" );
				expect( directoryExists( expandPath( "/tests/results/videos" ) ) ).toBeTrue( "videos directory should have been created" );
			} );
		} );
	}

}
