#!/bin/bash

# # install-xliff-into-macos-app
# This shell script installs a localized .xliff or .xcloc file to a
# macOS .app application.
#
# This allows a localizer to test the .xliff or .xcloc file without the
# need to send it to the developer, import it to Xcode, rebuild and
# export the app, and send it back to the localizer.
#
# - the script, the .xliff or .xcloc file, the optional "src" folder,
# and a copy of the .app file should be placed in the same folder (with
# no other .xliff, .xcloc or .app file in this folder).
#
# - the .xliff or .xcloc file name should be the language identifier
# (e.g. "en.xliff", "fr.xliff", "de.xliff"…). The language specified in
# the "target-language" tag of the xliff file is ignored.
#
# - other localized resource files (e.g. .html, .pdf, .rtf, .png…)
# should be placed in an "src" folder, in the same folder as the .xliff
# file (or should be included inside the .xcloc file package). The "src"
# folder can contain one or multiple .lproj folders having same name as
# the .xliff file, and located in various subfolder.
#
# Note that the application's signature will be invalidated, as the
# application will be modified. You should normally be able to run it
# locally (assuming you have run it at least once before), however if
# you send it to someone else by email, or by internet download, the
# Finder will say the app is damaged. To fix this, the person you send
# the app to will have to clear the quarantine flag by typing the
# following command line in a Terminal.app window:
#
# `xattr -cr {path/to/app}`
#
# (replace {path/to/app} by the actual path of the modified app file;
# you can drag and drop it from the Finder to the Terminal window to
# "paste" its path)
#
# © 2022-2023 Jérôme Seydoux - https://github.com/jeromectm

# change directory to the directory containing this shell file
cd "${0%/*}"

if (( $(find .  -maxdepth 1 -name "*.xliff" | wc -l) == 1 )); then
	xliffFile="$(ls -1d *.xliff)"
	xliffBasename="${xliffFile%.*}"
	srcPath="src"
elif (( $(find .  -maxdepth 1 -name "*.xcloc" | wc -l) == 1 )); then
	xclocFile="$(ls -1d *.xcloc)"
	xliffBasename="${xclocFile%.*}"
	xliffFile="${xclocFile}/Localized Contents/${xliffBasename}.xliff"
	srcPath="${xclocFile}/src"
fi


if [[ -f "$xliffFile" ]]; then
	targetLanguange="$(perl -0ne 'm/target-language="([^"]*)"/m; print $1' "$xliffFile")"
	if [[ "$targetLanguange" != "$xliffBasename" ]]; then
		echo "Warning: ignoring the target-language attribute “${targetLanguange}”; using the filename “${xliffBasename}” instead as the language identifier."
		targetLanguange="$xliffBasename"
	fi

	if (( $(find .  -maxdepth 1 -name "*.app" | wc -l) == 1 )); then
		appName="$(ls -1d *.app)"

		if (( $(find .  -maxdepth 1 -name "*.strings" | wc -l) == 0 )); then
#			rm -f "${targetLanguange}.strings"* *'.strings'

			lprojPath="${appName}/Contents/Resources/${targetLanguange}.lproj"
			rm -Rf "$lprojPath"
			mkdir -p "$lprojPath"

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
					echo "\"${stringID}\" = \"${stringTarget}\";" >> "${lprojPath}/${filename}"
				done
				echo " $(( ${stringIdx} -1 )) strings done"
			done

			if [[ -d "${srcPath}" ]]; then
				otherResources="$(find "${srcPath}" -path '*/'"${xliffBasename}"'.lproj/*')"
				if [[ -n "$otherResources" ]]; then
					echo -n "Copying resource files from ${srcPath} ..."
					rsrcIdx=0
					for resource in $otherResources; do
						cp -a "$resource" "${appName}/Contents/Resources/${xliffBasename}.lproj/"
						((rsrcIdx++))
					done
					echo " $(( ${rsrcIdx} )) resource files copied"
				fi
			fi
		else
			echo "Please make sure that no .strings file exist in ${0%/*}"
		fi
	else
		echo "Please make sure that 1 (and only 1) .app file exists in ${0%/*}"
	fi
else
	echo "Please make sure that 1 (and only 1) .xliff or .xcloc file exists in ${0%/*}"
fi
