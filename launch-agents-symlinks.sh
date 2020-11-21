#!/usr/bin/env bash

for e in ~/Library/Mobile\ Documents/com~apple~CloudDocs/LaunchAgents/*; do

    f=$( basename "${e}" )

    if [ -L "${HOME}/Library/LaunchAgents/${f}" ]; then
        launchctl unload "${HOME}/Library/LaunchAgents/${f}" > /dev/null 2>&1
        rm -f "${HOME}/Library/LaunchAgents/${f}"
    fi

    STATE=""
    # Does 'Disabled' key exist...?
    if [ $(/usr/libexec/PlistBuddy -c "Print :Disabled" "${e}" 2>/dev/null) ]; then
    	# ...yes, is value of 'Disabled' key 'true'?
    	if [[ $(/usr/libexec/PlistBuddy -c "Print :Disabled" "${e}") == "true" ]]; then
    		# ...yes, set STATE to "Disabled"
			STATE="disabled"
		fi
	fi

    if [[ $STATE != "disabled" ]]; then
        ln -sf "${e}" "${HOME}"/Library/LaunchAgents
        launchctl load "${HOME}/Library/LaunchAgents/${f}"
    fi
done

launchctl list | grep steve
