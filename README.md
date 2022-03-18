# install-xliff-into-macos-app
Shell script to test a localized xliff file on a macOS app, without the need to send it to the developer, import it to Xcode, rebuild and export the app, and send it back to the localizer.

- the script, the .xliff file, and a copy of the .app file should be placed in the same folder (with no other .xliff or .app file).

- the .xliff file name should be the language identifier (e.g. "en.xliff", "fr.xliff", "de.xliff"…). The language specified in the "target-language" tag of the xliff file is ignored.

- other localized files (e.g. .html, .pdf, .rtf, .tiff…) should be installed manually to the destination .lproj folder

Note that the application's signature will be invalidated, as the application will be modified. You should normally be able to run it locally (assuming you have run it at least once before), however if you send it to someone else by email, or by internet download, the Finder will say the app is damaged. To fix this, the person you send the app to will have to clear the quarantine flag by typing the following command line in a Terminal.app window:

`xattr -cr {path/to/app}`

(replace {path/to/app} by the actual path of the modified app file; you can drag and drop it from the Finder to the Terminal window to "paste" its path)
