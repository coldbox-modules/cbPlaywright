component extends="cbPlaywright.models.PlaywrightTestCase" {

	function run() {
		describe( "smoke test", () => {
			it( "can visit google and record screenshots and videos and a trace", function() {
				if ( directoryExists( expandPath( "/tests/results" ) ) ) {
					directoryDelete( expandPath( "/tests/results" ), true );
				}
				directoryCreate( expandPath( "/tests/results" ) );

				var browser = launchInteractiveBrowser( variables.playwright.chromium() );
				newRecordedContextForBrowser(
					browser,
					"/tests/results/videos",
					function( context ) {
						traceContext(
							context,
							"/tests/results/trace.zip",
							function() {
								var page = context.newPage();
								navigate( page, "https://duckduckgo.com" );
								waitForLoadState( page );
								expect( page.title() ).toInclude( "DuckDuckGo" );
								var searchBox = locateElement( page, '[name="q"]' );
								click( searchBox );
								fill( searchBox, "playwright" );
								press( searchBox, "Enter" );
								expect( page.url() ).toInclude( "q=playwright" );
								click(
									getByRole( page, "link", {
										"name": "Fast and reliable end-to-end testing for modern web apps | Playwright",
										"exact": true
									} )
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
