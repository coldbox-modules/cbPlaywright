component {

    property name="progressBarGeneric" inject="progressBarGeneric";

	function run() {
		print.line( "Cleaning current lib directory..." ).toConsole();
		if ( directoryExists( "../lib" ) ) {
			directoryDelete( "../lib", true );
		}

		print.line( "Downloading the latest jars for Playwright..." ).toConsole();
		command( "run" ).params( "mvn dependency:copy-dependencies -DoutputDirectory=lib" ).run();

		var bundleFile = directoryList( "lib/" ).filter( ( fileName ) => {
			return fileName contains "driver-bundle";
		} );
		if ( bundleFile.isEmpty() ) {
			return error( "No driver-bundle found in the downloaded jars!" );
		}
		bundleFile = bundleFile[ 1 ];

		print.line( "Removing the drivers. These are provided by commandbox-cbplaywright..." ).toConsole();
		fileDelete( bundleFile );

		print.greenLine( 'Download and extraction complete!' ).toConsole();
	}

}
