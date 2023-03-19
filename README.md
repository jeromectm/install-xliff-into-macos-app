# install-xliff-into-macos-app
This shell script installs a localized .xliff file to a macOS .app application.

This allows a localizer to test the .xliff file without the need to send it to the developer, import it to Xcode, rebuild and export the app, and send it back to the localizer.

- the script, the .xliff file, and a copy of the .app file should be placed in the same folder (with no other .xliff or .app file).

- the .xliff file name should be the language identifier (e.g. "en.xliff", "fr.xliff", "de.xliff"…). The language specified in the "target-language" tag of the xliff file is ignored.

- no .strings file should exist in the same folder as this script file

- other localized files (e.g. .html, .pdf, .rtf, .tiff…) should be placed in an "src" folder, in the same folder as the script. The "src" folder can contain one or multiple .lproj folders having same name as the .xliff file, and located in various subfolder. The "src" folder of an Xcode generated .xcloc can be used as is, once translated.

Note that the application's signature will be invalidated, as the application will be modified. You should normally be able to run it locally (assuming you have run it at least once before), however if you send it to someone else by email, or by internet download, the Finder will say the app is damaged. To fix this, the person you send the app to will have to clear the quarantine flag by typing the following command line in a Terminal.app window:

`xattr -cr {path/to/app}`

(replace {path/to/app} by the actual path of the modified app file; you can drag and drop it from the Finder to the Terminal window to "paste" its path)

© 2022-2023 Jérôme Seydoux - https://github.com/jeromectm
