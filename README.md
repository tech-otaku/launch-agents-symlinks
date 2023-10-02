# launch-agents-symlinks

## Important

As of macOS Sonoma 14.0, on system startup and login `launchd` appears to ignore symbolic links that point to centrally-stored property list files. Using `launchctl`, this script can still explicitly load property list files using the symbolic links to them it creates, but they are not re-loaded by `launchd` on system startup and login.

#### For macOS Sonoma 14.0
By default, the script will now *copy* the centrally-stored property list files to the target directory instead of creating symbolic links to them.

#### For macOS Ventura 13.0 and Earlier
Use the `-l` option to continue to create symbolic links in the target directory as before.


## Purpose

Create symbolic links locally to `launchd` property list files stored centrally in the cloud. 

## Usage 

`./launch-agents-symlinks.sh -h`

`./launch-agents-symlinks.sh [-a] [-l] -s "/full/path/to/source/directory" -t "/full/path/to/target/directory"`

## Example

`./launch-agents-symlinks.sh -a -s "$HOME/Library/Mobile Documents/com~apple~CloudDocs/LaunchAgents" -t "$HOME/Library/LaunchAgents"`

## Background

`launchd` scans specific directories for property list (*.plist*) files to load. A brief, but informative overview of `launchd` can be found [here](https://www.launchd.info/). 

A *.plist* file used by more than one machine needs to be duplicated on each machine. Managing duplicate copies of *.plist* files can prove cumbersome and time consuming. To make them easier to maintain, *.plist* files can be stored in a single central location accessible to all machines. The downside to this approach is *.plist* files stored outside of a few specific directories will be ignored by `launchd`.

One answer is to create symbolic links to these centrally-stored *.plist* files in the appropriate local directory on each machine.

## Script Functionality
The script does the following:

For all centrally-stored property list files:

- using the symbolic link in the local directory (if it exists), the property list file is *unloaded* by `launchctl` 
- the symbolic link is deleted from the local directory

For centrally-stored property list files with no `Disabled` key or a `Disabled` key set to `false`: 

- a new symbolic link is created in the local directory
- using the symbolic link, the property list file is *loaded* by `launchctl` 

For all symbolic links in the local directory:

- broken symbolic links - those that no longer point to an existing centrally-stored property list file - are deleted from the local directory


## Intended Limitations

The following directories scanned by `launchd` for property list files are currently excluded. The script will not create symbolic links in these locations:

`/Library/LaunchDaemons` 

`/System/Library/LaunchAgents`

`/System/Library/LaunchDaemons`

