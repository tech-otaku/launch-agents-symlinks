#!/usr/bin/env bash

# AUTHOR:   Steve Ward [steve at tech-otaku dot com]
# URL:      https://github.com/tech-otaku/launch-agents-symlinks.git
# README:   https://github.com/tech-otaku/launch-agents-symlinks/blob/master/README.md



# # # # # # # # # # # # # # # # 
# VARIABLES
#

# AUTO = If set, process all property list files in the source directory without prompting for user interaction.
# SYMLINKS = If set, create symbolic links to the property list files instead of copying the originals.
# SOURCE = The source directory containing property list files. 
# TARGET = The directory in which to create symbolic links. Limited to those defined in the $VALID and ultimately $INCLUDED arrays.
# VALID = An array of valid target directories.
# INCLUDED = A subset of the $VALID array containing only those valid target directories in which to create symbolic links.
# INVALID = If set, the target directory is invalid and symbolic links cannot be created in it. 
# EXCLUDED = If set, the target directory is valid, BUT symbolic links cannot currently be created in it.
# STATE = If set to 'disabled', the property list's disabled key is set to true.
# LOAD = Response to interactive prompt.

    VALID=("$HOME/Library/LaunchAgents" "/Library/LaunchAgents" "/Library/LaunchDaemons" "/System/Library/LaunchAgents" "/System/Library/LaunchDaemons")
    INCLUDED=("$HOME/Library/LaunchAgents" "/Library/LaunchAgents")



# # # # # # # # # # # # # # # # 
# FUNCTION DECLARATIONS
#

# Function to display usage help
    function usage {
        cat << EOF
                    
    Syntax: 
    ./$(basename $0) -h
    ./$(basename $0) [-a] [-l] -s SOURCE -t TARGET

    Options:
    -a              Auto mode. Do not prompt for user interaction.
    -h              This help message.
    -l              Create symbolic links to property list files instead of copying originals.
    -s SOURCE       Source directory. Full path to directory containing property list files.
    -t TARGET       Target directory. Full path to directory to copy property list files to.

    Example: ./$(basename $0) -a -s "\$HOME/Library/Mobile Documents/com~apple~CloudDocs/LaunchAgents" -t "\$HOME/Library/LaunchAgents"
    
EOF
    }



# # # # # # # # # # # # # # # # 
# COMMAND-LINE OPTIONS
#

# Exit with error if no command line options given
    if [[ ! $@ =~ ^\-.+ ]]; then
        printf "\nERROR: * * * No options given. * * *\n"
        usage
        exit 1
    fi

# Prevent an option that expects an argument, taking the next option as an argument if its argument is omitted (i.e. -s -t /full/path/to/target/directory)
    while getopts ':ahls:t:' opt; do
        if [[ $OPTARG =~ ^\-.? ]]; then
            printf "\nERROR: * * * '%s' is not valid argument for option '-%s'\n" $OPTARG $opt
            usage
            exit 1
        fi
    done

# Reset OPTIND so getopts can be called a second time
    OPTIND=1        

# Process command line options
    while getopts ':ahls:t:' opt; do
        case $opt in
            a) 
                AUTO=true 
                ;;
            h)
                usage
                exit 0
                ;;
            l) 
                SYMLINKS=true 
                ;;
            s) 
                SOURCE=$OPTARG 
                ;;
            t) 
                TARGET=$OPTARG 
                ;;
            :) 
                printf "\nERROR: * * * Argument missing from '-%s' option * * *\n" $OPTARG
                usage
                exit 1
                ;;
            ?) 
                printf "\nERROR: * * * invalid option: '-%s'\n * * * " $OPTARG
                usage
                exit 1
                ;;
        esac
    done



# # # # # # # # # # # # # # # # 
# USAGE CHECKS
#

# Source directory not specified
    if [ -z "$SOURCE" ]; then
        printf "\nERROR: * * * Source directory not specified. * * *\n"
        usage
        exit 1
    fi

# Source directory doesn't exist
    if [ ! -d  "$SOURCE" ]; then
        printf "\nERROR: * * * Source directory '%s' doesn't exist. * * *\n" "$SOURCE"
        usage
        exit 1
    fi

# Target directory not specified
    if [ -z "$TARGET" ]; then
        printf "\nERROR: * * * Target directory not specified. * * *\n"
        usage
        exit 1
    fi

# Target directory doesn't exist
    if [ ! -d  "$TARGET" ]; then
        printf "\nERROR: * * * Target directory '%s' doesn't exist. * * *\n" "$TARGET"
        usage
        exit 1
    fi

# Target directory not scanned by launchd
    INVALID=true
    for i in "${VALID[@]}"; do 
#        echo "$i"
        if [ "$TARGET" == "$i" ]; then   # target directory scanned by launchd
            unset INVALID       
            break
        fi
    done

    if [ ! -z $INVALID ]; then
        printf "\nERROR: * * * Target directory '%s' is not scanned by launchd. * * *\n" "$TARGET" 
        usage
        exit 1
    fi

# Target directory scanned by launchd, but currently excluded by script
    EXCLUDE=true
    for i in "${INCLUDED[@]}"; do 
#        echo "$i"
        if [ "$TARGET" == "$i" ]; then   # target directory included bt script
            unset EXCLUDE       
            break
        fi
    done

    if [ ! -z $EXCLUDE ]; then
        printf "\nERROR: * * * Target directory '%s' is currently excluded. * * *\n" "$TARGET" 
        usage
        exit 1
    fi



# Loop through the property list files in the source directory
    for e in "$SOURCE"/*.plist; do

    # Get the name of the property list file
        f=$( basename "$e" )

    # Check if a copy (-f) of the source or symbolic link (-L) to the source exists in the target
        if [ -f "$TARGET/$f" ] || [ -L "$TARGET/$f" ]; then
        # Unload the job
            launchctl unload "$TARGET/$f" > /dev/null 2>&1
        # Delete the the copy or symbolic link
            rm -f "$TARGET/$f"
        fi

        STATE=""
        # Does 'Disabled' key exist...?
        if [ $(/usr/libexec/PlistBuddy -c "Print :Disabled" "$e" 2>/dev/null) ]; then
            # ...yes, is value of 'Disabled' key 'true'?
            if [[ $(/usr/libexec/PlistBuddy -c "Print :Disabled" "$e") == "true" ]]; then
                # ...yes, set STATE to "Disabled"
                STATE="disabled"
            fi
        fi

        if [[ $STATE != "disabled" ]]; then
            
            if [ -z $AUTO ]; then
                read -p "Load $f (Y/n)? " LOAD
            else
                LOAD=Y
            fi

            if [[ $LOAD =~ [A-Z] && $LOAD == "Y" ]]; then
                if [ -z $SYMLINKS ]; then
                    cp -p "$e" "$TARGET"
                else
                    ln -sf "$e" "$TARGET"
                fi
                launchctl load "$TARGET/$f" 
                printf "> > > > %s has been loaded.\n" "$f"
            fi
        fi
    done

# Remove orphaned symbolic links
    for e in "$TARGET"/*.plist; do
        if [ -L "$e" ]; then
            if [ ! -f "$(readlink $e)" ]; then
                rm -f "$e"
            fi
        fi
    done