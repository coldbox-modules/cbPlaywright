# cbPlaywright

## CFML integration with TestBox and Playwright to run tests in actual browsers

### Dependencies

Testbox v4+

> ColdBox is **not** required.

### Installation

1. Add Java Jars to `tests/Application.cfc`

```
this.javaSettings = {
	loadPaths: directoryList(
		rootPath &  "modules/cbPlaywright/lib",
		true,
		"array",
		"*jar"
	),
	loadColdFusionClassPath: true,
	reloadOnChange: false
};
```

2. Make sure you have a mapping to `cbPlaywright` as well.

```
this.mappings[ "/cbPlaywright" ] = rootPath & "/modules/cbPlaywright";
```

> Note: You can't use the mapping in the `javaSettings` since they are both in the psuedo-constructor.

3. (OPTIONAL) If you have installed CommandBox or commandbox-cbplaywright in a non-standard location, set the `CBPLAYWRIGHT_DRIVER_DIR`
environment variable to the correct location of the Playwright driver.

### Playwright CLI

To interact with the Playwright CLI, use `commandbox-cbplaywright:

```sh
playwright-cli
# or
playwright
```

You can see the documentation for the [Playwright Java CLI here](https://playwright.dev/java/docs/cli).

### Installing Test browsers

To use Playwright, first you must install one or more test browsers.
Refer to the Playwright docs on [Browsers](https://playwright.dev/java/docs/browsers#installing-browsers)
for more information.

Examples:

```sh
box playwright install chromium
box playwright install firefox
box playwright install webkit
box playwright install msedge
```

### Usage

To use cbPlaywright, create a test spec that extends either `cbPlaywright.models.PlaywrightTestCase`
or `cbPlaywright.models.ColdBoxPlaywrightTestCase`. What's the difference between these two?
`PlaywrightTestCase` extends `testbox.system.BaseSpec` while
`ColdBoxPlaywrightTestCase` extends `coldbox.system.testing.BaseTestCase`.
Basically, if you need to access your ColdBox app in your Playwright test, use `ColdBoxPlaywrightTestCase`.

> NOTE: ColdBox is **not** required to use cbPlaywright. The only dependency is TestBox.

```cfc
component extends="cbPlaywright.models.PlaywrightTestCase" {
	// ...
}
```

A `PlaywrightTestCase` CFC automatically creates a `variables.playwright` instance in the `beforeAll` method.

> If you have a `beforeAll` on your test case, make sure to call `super.beforeAll()`. Otherwise, you will
> not have access to the `variables.playwright` instance.

This `playwright` variable is an instance of the Java `Playwright` class. From this variable you can
create browsers to start running your tests.

```cfc
component extends="cbPlaywright.models.PlaywrightTestCase" {

	function run() {
		describe( "home page", () => {
			it( "can visit the home page", () => {
				var browser = variables.playwright.firefox().launch();
				var page = browser.newPage();
				navigate( page, "http://" & CGI.HTTP_HOST );
				waitForLoadState( page );
				expect( page.title() ).toBe( "Welcome to my site!" );
			} );
		} );
	}

}
```

All of the methods above are called on the Java objects provided by the Playwright Java SDK.
When using cbPlaywright, you will often reference the [Playwright Java SDK documentation](https://playwright.dev/java/docs/intro).

### Helper Functions

cbPlaywright provides helper functions to make interacting with the Java SDK easier.

> You can find all of these helper functions inside `cbPlaywright.models.PlaywrightMixins`

#### route

Builds up a URL string to the currently running server. It can take any amount of arguments and will
intelligently combine them into a path prepended with the current `CGI.HTTP_HOST`.

| Name  | Type   | Required | Default | Description                                                                                                                                                                      |
| ----- | ------ | -------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| paths | string | false    | null    | This is a variadic parameter. Any number of strings can be passed as separate arguments. They will all be combined into one URL path prepended with the current `CGI.HTTP_HOST`. |

Example:

```cfc
route( "/users", userId, "edit" );
// http://127.0.0.1:51423/users/42/edit
```

#### navigate

Navigates a [Page](https://playwright.dev/java/docs/api/class-page) to a URL.

| Name | Type | Required | Default | Description |
| ----- | ------ | -------- | ------- | |
| page | com.microsoft.playwright.Page | true | | A Playwright page to navigate. |
| path | string | true | | The path to navigate to. |

Example:

```cfc
var browser = launchBrowser( variables.playwright.webkit() );
var page = browser.newPage();
navigate( page, route( "/" ) );
expect( page.title() ).toBe( "My Site" );
```

#### locateElement

Finds an [ElementHandle](https://playwright.dev/java/docs/api/class-elementhandle) in the
given [Page](https://playwright.dev/java/docs/api/class-page) by selector.

| Name | Type | Required | Default | Description |
| ----- | ------ | -------- | ------- | |
| page | com.microsoft.playwright.Page | true | | A Playwright page in which to find the selector. |
| selector | string | true | | A selector to use when resolving DOM element. |

Example:

```cfc
var browser = launchBrowser( variables.playwright.chromium() );
var page = browser.newPage();
navigate( page, "https://google.com" );
waitForLoadState( page );
expect( page.title() ).toBe( "Google" );
var searchBox = locateElement( page, '[aria-label="Search"]' );
```

#### click

Clicks an [ElementHandle](https://playwright.dev/java/docs/api/class-elementhandle).

| Name | Type | Required | Default | Description |
| ----- | ------ | -------- | ------- | |
| element | com.microsoft.playwright.ElementHandle | true | | A Playwright ElementHandle. You usually retrieve this from a `locateElement` call. |

Example:

```cfc
var browser = launchBrowser( variables.playwright.chromium() );
var page = browser.newPage();
navigate( page, "https://google.com" );
waitForLoadState( page );
expect( page.title() ).toBe( "Google" );
var searchBox = locateElement( page, '[aria-label="Search"]' );
click( searchBox );
```

#### fill

Fills an [ElementHandle](https://playwright.dev/java/docs/api/class-elementhandle) with the given value.

| Name | Type | Required | Default | Description |
| ----- | ------ | -------- | ------- | |
| element | com.microsoft.playwright.ElementHandle | true | | A Playwright ElementHandle. You usually retrieve this from a `locateElement` call. |
| value | string | true | | The value to fill. |

Example:

```cfc
var browser = launchBrowser( variables.playwright.chromium() );
var page = browser.newPage();
navigate( page, "https://google.com" );
waitForLoadState( page );
expect( page.title() ).toBe( "Google" );
var searchBox = locateElement( page, '[aria-label="Search"]' );
click( searchBox );
fill( searchBox, "playwright" );
```

#### press

Presses a given key on an [ElementHandle](https://playwright.dev/java/docs/api/class-elementhandle).

| Name | Type | Required | Default | Description |
| ----- | ------ | -------- | ------- | |
| element | com.microsoft.playwright.ElementHandle | true | | A Playwright ElementHandle. You usually retrieve this from a `locateElement` call. |
| key | string | true | | The key to press. |

Example:

```cfc
var browser = launchBrowser( variables.playwright.chromium() );
var page = browser.newPage();
navigate( page, "https://google.com" );
waitForLoadState( page );
expect( page.title() ).toBe( "Google" );
var searchBox = locateElement( page, '[aria-label="Search"]' );
click( searchBox );
fill( searchBox, "playwright" );
press( searchBox, "Enter" );
```

#### launchBrowser

Launches a Browser from a Playwright [BrowserType](https://playwright.dev/java/docs/api/class-browsertype) instance. Returns a Playwright [Browser](https://playwright.dev/java/docs/api/class-browser) instance.

| Name        | Type                                 | Required | Default | Description                                                                          |
| ----------- | ------------------------------------ | -------- | ------- | ------------------------------------------------------------------------------------ |
| browserType | com.microsoft.playwright.BrowserType | true     |         | A Playwright BrowserType to launch.                                                  |
| headless    | boolean                              | false    | `true`  | Flag to launch the browser in headless mode. Only interactive browser can be paused. |

Example:

```cfc
var browser = launchBrowser( variables.playwright.firefox() );
```

#### launchInteractiveBrowser

Launches an interactive Browser from a Playwright [BrowserType](https://playwright.dev/java/docs/api/class-browsertype) instance. An interactive Browser is one that is not running in headless mode. Returns a Playwright [Browser](https://playwright.dev/java/docs/api/class-browser) instance.

| Name        | Type                                 | Required | Default | Description                         |
| ----------- | ------------------------------------ | -------- | ------- | ----------------------------------- |
| browserType | com.microsoft.playwright.BrowserType | true     |         | A Playwright BrowserType to launch. |

Example:

```cfc
var browser = launchInteractiveBrowser( variables.playwright.msedge() );
```

#### screenshotPage

Captures a screenshot from a [Page](https://playwright.dev/java/docs/api/class-page) instance.
Returns the same Page instance.

| Name    | Type                          | Required | Default | Description                                     |
| ------- | ----------------------------- | -------- | ------- | ----------------------------------------------- |
| page    | com.microsoft.playwright.Page | true     |         | A Playwright Page to capture as a screenshot.   |
| path    | string                        | true     |         | The path to save the screenshot.                |
| options | struct                        | false    | `{}`    | Additional options to customize the screenshot. |

Additional options are as follows:

```cfc
{
	// set a region to capture for the screenshot
	"clip": {
		"x": 100,
		"y": 100,
		"width": 100,
		"height": 100
	}
	// captures the full scrollable page instead of the currently visible viewport
	"fullPage": true,
	// Hides default white background and allows capturing screenshots with transparency. Defaults to false.
	"omitBackground": true,
	// The quality of the image, between 0-100. Not applicable to `png` images.
	"quality": 75,
	// Maximum time in milliseconds to capture the screenshot. Defaults to 30 seconds. Pass 0 to disable.
	"timeout": 5 * 1000,
	// The screenshot type, "png" or "jpeg". Defaults to "png".
	"type": "jpeg"
}
```

Example:

```cfc
var browser = launchBrowser( variables.playwright.webkit() );
var page = browser.newPage();
page.navigate( route( "/" ) );
screenshotPage( page, "/tests/results/homePage.png", { "type": "jpeg" } );
```

#### newRecordedContextForBrowser

Creates a new recorded [BrowserContext](https://playwright.dev/java/docs/api/class-browsercontext)
from a Playwright [Browser](https://playwright.dev/java/docs/api/class-browser).
A recorded context saves one or more videos of all the actions taken by the context. The context is created
and provided to you via a callback. If any additional pages or popups are created, the context will save a
video for each of them.

Returns the passed in Browser instance.

| Name      | Type                             | Required | Default | Description                                                                                                                              |
| --------- | -------------------------------- | -------- | ------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| browser   | com.microsoft.playwright.Browser | true     |         | A Playwright Browser from which to create a recorded BrowserContext.                                                                     |
| directory | string                           | true     |         | The path to a directory to save any generated videos.                                                                                    |
| callback  | function                         | true     |         | A callback that receives the recorded context. All actions to be recorded should be called on this context variable inside the callback. |
| options   | struct                           | false    | `{}`    | Additional options to customize the recordings.                                                                                          |

Additional options are as follows:

```cfc
{
	// Dimensions of the recorded videos. If not specified the size will be equal to viewport
	// scaled down to fit into 800x800. If viewport is not configured explicitly the video size
	// defaults to 800x450. Actual picture of each page will be scaled down if necessary
	// to fit the specified size.
	"recordVideoSize": {
		"height": 1280,
		"width": 720
	}
}
```

Example:

```cfc
var browser = launchBrowser( variables.playwright.chromium() );
newRecordedContextForBrowser( browser, "/tests/results/videos", function( context ) {
	var page = context.newPage();
	page.navigate( route( "/" ) );
	screenshotPage( page, "/tests/results/homePage.png" );
	expect( page.title() ).toBe( "Welcome to Coldbox!" );
	page.locator( "text=About" ).click();
	page.locator( "text=Official Site" ).click();
	expect( page.url() ).toBe( "https://coldbox.org/" );
	page.waitForLoadState();
	screenshotPage( page, "/tests/results/coldboxPage.png" );
} );
```

#### traceContext

Sets up a Playwright [BrowserContext](https://playwright.dev/java/docs/api/class-browsercontext) to allow tracing. Tracing creates a zip archive that can be replayed either locally or on https://trace.playwright.dev/.

| Name         | Type                                    | Required | Default | Description                                                                                                                                        |
| ------------ | --------------------------------------- | -------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| context      | com.microsoft.playwright.BrowserContext | true     |         | A Playwright BrowserContext to capture a trace.                                                                                                    |
| path         | string                                  | true     |         | The path to save the trace.                                                                                                                        |
| callback     | function                                | true     |         | A callback to run additional Playwright methods. Any methods called on the passed in `context` inside this callback will be recorded in the trace. |
| startOptions | struct                                  | false    | `{}`    | Additional start options to customize the trace.                                                                                                   |

Additional startOptions are as follows:

```cfc
{
	// Whether to capture screenshots during tracing. Screenshots are used to build a timeline preview.
	// Defaults to `true`.
	"screenshots": false
	// If this option is true tracing will capture DOM snapshot on every action record network activity.
	// Defaults to `true`.
	"snapshots": false,
	// Whether to include source files for trace actions.
	// List of the directories with source code for the application must be provided via
	// `PLAYWRIGHT_JAVA_SRC` environment variable.
	// (The paths should be separated by ';' on Windows and by ':' on other platforms.)
	// Defaults to `false`.
	"sources": true,
	// Trace name to be shown in the Trace Viewer.
	"title": "My Home Page"
}
```

Example:

```cfc
var browser = launchBrowser( variables.playwright.firefox() );
var context = browser.newContext();
traceContext( context, "/tests/results/trace.zip", function() {
	var page = browser.newPage();
	page.navigate( route( "/" ) );
	screenshotPage( page, "/tests/results/homePage.png" );
} );
```

#### waitForPopup

Waits for a popup to load after running the actions inside the callback,
then returns the new popup [Page](https://playwright.dev/java/docs/api/class-page).
This action will fail if the navigation does not happen after 30 seconds.

> Popups include any new pages opened by browser interactions (like `<a href="www.google.com" target="_blank">Google</a>`)

| Name     | Type                          | Required | Default | Description                                                                         |
| -------- | ----------------------------- | -------- | ------- | ----------------------------------------------------------------------------------- |
| page     | com.microsoft.playwright.Page | true     |         | A Playwright Page that will launch a popup.                                         |
| callback | function                      | true     |         | A callback containing Playwright actions that will end with launching a popup page. |

Example:

```cfc
var browser = launchBrowser( variables.playwright.chromium() );
var page = browser.newPage();
page.navigate( "https://coldbox.org/" );
page.waitForLoadState();
screenshotPage( page, "/tests/results/coldboxPage.png" );
var popup = waitForPopup( page, function() {
	page.locator( 'a:has-text("CFCASTS")' ).click();
} );
expect( popup.url() ).toBe( "https://cfcasts.com/" );
```

#### waitForNavigation

Waits for a navigation event to finish after running the actions inside the callback.
This action will fail if the navigation does not happen after 30 seconds.

| Name     | Type                          | Required | Default | Description                                                                                 |
| -------- | ----------------------------- | -------- | ------- | ------------------------------------------------------------------------------------------- |
| page     | com.microsoft.playwright.Page | true     |         | A Playwright Page that will perform a navigation action.                                    |
| callback | function                      | true     |         | A callback containing Playwright actions that will end with performing a navigation action. |

Example:

```cfc
var browser = launchBrowser( variables.playwright.chromium() );
var page = browser.newPage();
page.navigate( "https://cfcasts.com/" );
expect( page.url() ).toBe( "https://cfcasts.com/" );
var searchField = page.locator( '[placeholder="Search (Ctrl + K)"]' ).first();
searchField.click();
searchField.fill( "commandbox" );
waitForNavigation( page, function() {
	searchField.press( "Enter" );
} )
expect( page.url() ).toBe( "https://cfcasts.com/browse?q=commandbox" );
screenshotPage( page, "/tests/results/cfcastsPage.png" );
```

#### waitForLoadState

Waits for the LOAD event from the DOM before continuing.
This action will fail if the LOAD event is not fired before 30 seconds.

| Name | Type                          | Required | Default | Description                    |
| ---- | ----------------------------- | -------- | ------- | ------------------------------ |
| page | com.microsoft.playwright.Page | true     |         | A Playwright Page to wait for. |

Example:

```cfc
var browser = launchBrowser( variables.playwright.chromium() );
var page = browser.newPage();
navigate( page, "https://google.com" );
waitForLoadState( page );
expect( page.title() ).toBe( "Google" );
```

#### waitForUrl

Waits for the browser's url to be the given string.
This action will fail if the url does not become the given string before 30 seconds.

| Name | Type                          | Required | Default | Description                    |
| ---- | ----------------------------- | -------- | ------- | ------------------------------ |
| page | com.microsoft.playwright.Page | true     |         | A Playwright Page to wait for. |

Example:

```cfc
var browser = launchBrowser( variables.playwright.chromium() );
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
```

### Running a Codegen Session

Codgen is a way to interact with a browser and record the actions to copy to your test.
You can do this from the Playwright Java CLI.

```sh
java -cp "modules/cbPlaywright/lib/*" -Dplaywright.cli.dir="lib/driver/linux/" com.microsoft.playwright.CLI codegen {YOUR_SITE_HERE}
```

> Make sure to copy the code out before closing any windows. You will need to massage some
> of the generated Java code to fit CFML, specifically anything with arrow functions.
