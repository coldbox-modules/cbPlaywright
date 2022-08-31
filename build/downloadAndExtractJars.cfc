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

		print.line( "Unzipping the drivers..." ).toConsole();
		cfzip( action = "unzip", file = bundleFile, destination = "../lib/driver-bundle" );
		directoryCopy( "../lib/driver-bundle/driver", "../lib/driver", true );
		directoryDelete( "../lib/driver-bundle", true );
		fileDelete( bundleFile );

		print.line( "Setting the correct permissions for the driver files..." ).toConsole();
		var files = directoryList( "../lib/driver", true );
		var fileCount = files.len();
		progressBarGeneric.update( percent = 0 );
		files.each( ( fileName, i ) => {
			fileSetAccessMode( fileName, "777" );
			progressBarGeneric.update( percent = ( i / fileCount ) * 100 );
		} );


		print.greenLine( 'Download and extraction complete!' ).toConsole();
	}

}
