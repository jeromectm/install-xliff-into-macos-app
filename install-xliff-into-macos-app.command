#!/bin/bash

# # install-xliff-into-macos-app
# This shell script installs a localized .xliff file to a macOS .app
# application.
# 
# This allows a localizer to test the .xliff file without the need to send
# it to the developer, import it to Xcode, rebuild and export the app, and
# send it back to the localizer.
# 
# - the script, the .xliff file, and a copy of the .app file should be
# placed in the same folder (with no other .xliff or .app file).
# 
# - the .xliff file name should be the language identifier (e.g.
# "en.xliff", "fr.xliff", "de.xliff"…). The language specified in the
# "target-language" tag of the xliff file is ignored.
# 
# - no .strings file should exist in the same folder as this script file
# 
# - other localized files (e.g. .html, .pdf, .rtf, .tiff…) should be
# placed in an "src" folder, in the same folder as the script. The "src"
# folder can contain one or multiple .lproj folders having same name as
# the .xliff file, and located in various subfolder. The "src" folder of
# an Xcode generated .xcloc can be used as is, once translated.
# 
# Note that the application's signature will be invalidated, as the
# application will be modified. You should normally be able to run it
# locally (assuming you have run it at least once before), however if you
# send it to someone else by email, or by internet download, the Finder
# will say the app is damaged. To fix this, the person you send the app to
# will have to clear the quarantine flag by typing the following command
# line in a Terminal.app window:
# 
# `xattr -cr {path/to/app}`
# 
# (replace {path/to/app} by the actual path of the modified app file; you
# can drag and drop it from the Finder to the Terminal window to "paste"
# its path)
# 
# © 2022-2023 Jérôme Seydoux - https://github.com/jeromectm

# change directory to the directory containing this shell file
cd "${0%/*}"

if (( $(find .  -maxdepth 1 -name "*.xliff" | wc -l) == 1 )); then
	xliffFile="$(ls -1d *.xliff)"
	xliffBasename="${xliffFile%.*}"
	targetLanguange="$(perl -0ne 'm/target-language="([^"]*)"/m; print $1' "$xliffFile")"
	if [[ "$targetLanguange" != "$xliffBasename" ]]; then
		echo "Warning: ignoring the target-language attribute “${targetLanguange}”; using the filename “${xliffBasename}” instead as the language identifier."
		targetLanguange="$xliffBasename"
	fi

	if (( $(find .  -maxdepth 1 -name "*.app" | wc -l) == 1 )); then
		appName="$(ls -1d *.app)"

		if (( $(find .  -maxdepth 1 -name "*.strings" | wc -l) == 0 )); then
			rm -f "${targetLanguange}.strings"* *'.strings'

#			# the following code is fast, but won't process correctly some characters, espicailly straight quotes
#	 		split -p '<file original' "${targetLanguange}.xliff" "${targetLanguange}.strings"
#	 
#	 		rm -f "${targetLanguange}.stringsaa"
#	 		for f in "${targetLanguange}.strings"*; do
#	 			relPath="$(perl -0ne 'm/<file original="([^"]*)/m; print $1' "$f")"
#	 			filename="$(basename "$relPath")"
#	 			mv "$f" "$filename"
#	 			if [[ $filename == *.xib ]]; then
#	 				mv "$filename" "${filename%.*}.strings"
#	 			fi
#	 			filename="${filename%.*}.strings"
#	 			perl -i -0ne 'm/.*<body>(.*)<\/body>.*/s; print $1' "$filename"
#	 			perl -i -0pe 's/&#10;/\\n/gsm' "$filename"
#	 			perl -i -0pe 's/^\s*<trans-unit id="(.*?)" xml:space[^>]*>\s*<source>.*?<\/source>\s*<target>(.*?)<\/target>.*?<\/trans-unit>/"\1" = "\2";/gsm' "$filename"
#	 			perl -i -0pe 's/\n([^"])/\\n\1/gm' "$filename"
#	 			perl -i -0pe 's/\n([^"])/\\n\1/gm' "$filename"
#	 		done


			# the following code is slow, but should decode and encode correctly any character
			for ((fileIdx=1; fileIdx>=1; fileIdx++)); do
				fileElement="$(cat "$xliffFile" \
					| perl -pe 's/<xliff .*?>/<xliff>/' \
					| xmllint --xpath "//xliff/file[${fileIdx}]" - 2< /dev/null)"
				if [[ -z "$fileElement" ]]; then
					break
				fi
				fileRelativePath="$(echo "$fileElement" \
					| xmllint --xpath "string(//file/@original)" -)"
	 			filename="$(basename "$fileRelativePath")"
				if [[ "$filename" == *.xib ]]; then
					filename="${filename%.*}.strings"
				fi
				echo -n "Processing ${filename} ..."
				for ((stringIdx=1; stringIdx>=1; stringIdx++)); do
					stringElement="$(echo "$fileElement" \
						| xmllint --xpath "//file/body/trans-unit[${stringIdx}]" - 2< /dev/null)"
					if [[ -z "$stringElement" ]]; then
						break
					fi
					stringID="$(echo "$stringElement" \
						| xmllint --xpath "string(//trans-unit/@id)" -)"
					stringID="$(echo -n "$stringID" \
						| perl -pe 's/\\/\\\\/g;s/\n/\\n/g;s/"/\\"/g')"
					stringTarget="$(echo "$stringElement" \
						| xmllint --xpath "//trans-unit/target/text()" - 2< /dev/null)"
					stringTarget="$(echo -n "$stringTarget" \
						| perl -C -MHTML::Entities -pe 'decode_entities($_);s/\\/\\\\/g;s/\n/\\n/g;s/"/\\"/g')"
					echo "\"${stringID}\" = \"${stringTarget}\";" >> "${filename}"
				done
				echo " $(( ${stringIdx} -1 )) strings done"
			done


#			# alternate implementation, wich is not faster
#	 		fileElements="$(cat "$xliffFile" \
#	 			| perl -pe 's/<xliff .*?>/<xliff>/' \
#	 			| xmllint --xpath "//xliff/file" - 2< /dev/null \
#	 			| perl -pe 's/<\/file><file /<\/file>•<file /g')"
#	 		old_IFS="$IFS"
#	 		IFS='•'
#	 		set -- $fileElements
#	 		IFS="$old_IFS"
#	 		for fileElement; do
#	 			fileRelativePath="$(echo "$fileElement" \
#	 				| xmllint --xpath "string(//file/@original)" -)"
#	  			filename="$(basename "$fileRelativePath")"
#	 			if [[ "$filename" == *.xib ]]; then
#	 				filename="${filename%.*}.strings"
#	 			fi
#	 			echo -n "Processing ${filename} ..."
#	 
#	 			stringElements="$(echo "$fileElement" \
#	 				| xmllint --xpath "//file/body/trans-unit" - 2< /dev/null \
#	 				| perl -pe 's/<\/trans-unit><trans-unit/<\/trans-unit>•<trans-unit/g')"
#	 			old_IFS="$IFS"
#	 			IFS='•'
#	 			set -- $stringElements
#	 			IFS="$old_IFS"
#	 			for stringElement; do
#	 				stringID="$(echo "$stringElement" \
#	 					| xmllint --xpath "string(//trans-unit/@id)" -)"
#	 				stringTarget="$(echo "$stringElement" \
#	 					| xmllint --xpath "//trans-unit/target/text()" - 2< /dev/null \
#	 					| perl -C -MHTML::Entities -pe 'decode_entities($_);')"
#	 				stringID="$(echo -n "$stringID" | perl -pe 's/\\/\\\\/g')"
#	 				stringID="$(echo -n "$stringID" | perl -pe 's/\n/\\n/g')"
#	 				stringID="$(echo -n "$stringID" | perl -pe 's/"/\\"/g')"
#	 				stringTarget="$(echo -n "$stringTarget" | perl -pe 's/\\/\\\\/g')"
#	 				stringTarget="$(echo -n "$stringTarget" | perl -pe 's/\n/\\n/g')"
#	 				stringTarget="$(echo -n "$stringTarget" | perl -pe 's/"/\\"/g')"
#	 				echo "\"${stringID}\" = \"${stringTarget}\";" >> "${filename}"
#	 			done
#	 
#	 			echo "done"
#	 		done


			mkdir -p "${appName}/Contents/Resources/${targetLanguange}.lproj"
			rm -f "${appName}/Contents/Resources/${targetLanguange}.lproj/"*.strings
			mv *.strings "${appName}/Contents/Resources/${targetLanguange}.lproj/"
		
			if [[ -d "src" ]]; then
				otherResources="$(find "src" -path '*/'"${xliffBasename}"'.lproj/*')"
				if [[ -n "$otherResources" ]]; then
					for resource in $otherResources; do
						cp -a "$resource" "${appName}/Contents/Resources/${xliffBasename}.lproj/"
					done
				fi
			fi
		else
			echo "Please make sure that no .strings file exist in ${0%/*}"
		fi
	else
		echo "Please make sure that 1 (and only 1) .app file exists in ${0%/*}"
	fi
else
	echo "Please make sure that 1 (and only 1) .xliff file exists in ${0%/*}"
fi
