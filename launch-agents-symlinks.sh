#!/usr/bin/env zsh

for e in ~/Library/Mobile\ Documents/com~apple~CloudDocs/LaunchAgents/*; do
    f=$( basename "${e}" )
	launchctl unload "${HOME}/Library/LaunchAgents/${f}" > /dev/null 2>&1
	ln -sf "${e}" "${HOME}"/Library/LaunchAgents
	launchctl load "${HOME}/Library/LaunchAgents/${f}"
done

launchctl list | grep steve
