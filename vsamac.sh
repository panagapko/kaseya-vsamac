# Kaseya macOS Agent Script
# Created by Chris Panagapko - chris@panagapko.com

# *********************IMPORTANT*************************
# Set VSA Server URL below without the trailing slash.
# Example:
# vsaserver="https://vsa.yourdomain.com"
# *******************************************************
vsaserver=""
# *******************************************************

#!/bin/zsh
# Check for root
if [ "$EUID" -ne 0 ]
  then echo "Please re-run as root."
  exit
fi
clear

# Main Script
echo '\033[1;36m  ██    ██ ███████  █████ '  
echo '  ██    ██ ██      ██   ██ '
echo '  ██    ██ ███████ ███████ '
echo '   ██  ██       ██ ██   ██ '
echo '    ████   ███████ ██   ██ '
echo '\033[0m---------------------------'                                                                                               
echo 'macOS VSA Agent Maintenance'
echo 'Created by Chris Panagapko'
echo '---------------------------'
echo '1. Uninstall existing agent'
echo '2. Download and install agent by ID'
echo '3. Exit'
echo ' '
read -p 'Please choose an option: ' option

case $option in
    1)
        clear
        echo '\033[1;33mRemoving VSA agent. This may generate some errors which can usually be ignored.\033[0m'
        # Remove Kaseya agent
        echo "Killing KUsrTsk..." 
        killall KUsrTsk
        echo "Stopping com.kaseya.agentmon.plist and com.kaseya.endpoint.plist." 
        launchctl unload /Library/LaunchDaemons/com.kaseya.agentmon.plist 
        launchctl unload /Library/LaunchDaemons/com.kaseya.endpoint.plist
        echo "Waiting for launch daemons to unload..." 
        sleep 3
        echo "Removing Kaseya Endpoint." 
        /Library/Kaseya/Endpoint/KaseyaEndpoint --uninstallAll & ep_pid=$!
        echo "Waiting for Kaseya Endpoint removal to complete..." 
        sleep 30 
        echo "Killing Kaseya Endpoint process."
        kill $ep_pid 
        echo " "
        echo "\033[1;33mCleaning up remaining files and folders...\033[0m"
        echo "Cleaning /Library and /Applications."
        rm -rf /Library/Logs/com.kaseya
        rm -rf /Library/Kaseya
        rm -rf /Applications/KUsrTsk.app
        rm -rf /Library/Preferences/kaseyad.*
        rm -rf /Library/Preferences/Network/com.kaseya.AgentMon.plist
        rm -rf /Library/LaunchDaemons/com.kaseya.agentmon.plist
        rm -rf /Library/LaunchDaemons/com.kaseya.endpoint.plist
        rm -rf /Library/LaunchAgents/com.kaseya.kusrtsk.plist
        rm -rf /Library/LaunchAgents/com.kaseya.uninstall.plist
        rm -rf /Library/LaunchAgents/com.kaseya.update.plist
        echo "Removing /Library/Application Support/com.kaseya." 
        rm -rf "/Library/Application Support/com.kaseya"
        echo "Removing Kaseya files from /var/tmp."
        rm -rf /var/tmp/com.kaseya.AgentMon
        rm -rf /var/tmp/kas
        rm -rf /var/tmp/kstopmsg.txt
        rm -rf /var/tmp/kperfmon.txt
        rm -rf /var/tmp/KASetup.log
        rm -rf /var/tmp/lastChk.txt
        rm -rf /var/tmp/.pkg
        rm -rf /var/tmp/.pkg.zip
        rm -rf /var/tmp/.mpkg
        rm -rf /var/tmp/.mpkg.zip
        rm -rf /var/tmp/kmaconfigup
        rm -rf /var/tmp/kmapkgprompt
        rm -rf /var/tmp/kmaupdater
        rm -rf /var/tmp/com.kaseya.update.plist 
        rm -rf /var/tmp/.exe
        rm -rf /var/tmp/kpid 
        rm -rf /var/tmp/.tif 
        rm -rf /var/tmp/com.kaseya
        rm -rf /var/tmp/kasmbios.txt
        rm -rf /var/tmp/updatekini
        echo "Removing Kaseya files from /Library/Receipts."
        rm -rf /Library/Receipts/agentmon.pkg
        rm -rf /Library/Receipts/agentmonctl.pkg 
        rm -rf /Library/Receipts/agentmonprefs.pkg 
        rm -rf /Library/Receipts/kusrtsk.pkg 
        rm -rf /Library/Receipts/kusrtask.pkg 
        rm -rf /Library/Receipts/klagent.pkg 
        rm -rf /Library/Receipts/kclirelay.pkg 
        rm -rf /Library/Receipts/ksrvrelay.pkg 
        rm -rf /Library/Receipts/kmastartup.pkg
        echo '\033[1;32mAgent removal process completed!'
        echo '\033[0m '
        read -n 1 -r -s -p $'Press any key to continue...\n'
        exit 1
        ;;
    2)
        # Check for rosetta
        clear
        echo 'Checking for Rosetta...'
        arch=$(/usr/bin/arch)
        if [ $arch = "arm64" ]; then
            if /usr/bin/pgrep oahd >/dev/null 2>&1; then
                echo 'Rosetta is installed and running.'
            else
                echo 'Rosetta seems to be missing. Try installing it first using the following command:'
                echo ' '
                echo 'softwareupdate --install-rosetta'
                exit 1
            fi
        else
            echo 'This appears to be an Intel mac. Rosetta not required.'
        fi
        # Check to see if the VSA Server variable is defined
        if [ -z "$vsaserver" ]; then
            echo ' '
            echo '\033[1;31mVSA Server variable not defined. You can set this by editing the variable at the top of this script.\033[0m'
            read -p 'Enter VSA server (eg. https://vsa.mydomain.com) without trailing slash: ' vsaserver
        else
            echo 'VSA Server variable is defined.'
        fi

        echo '\033[1;36m '
        echo '-------------------------------------------------------------------------------'
        echo 'INSTRUCTIONS:'
        echo '1. go to Agent > Packages > Manage Packages'
        echo '2. Build a macOS agent package for your client if you have not done so already.'
        echo '3. Click on the name of the agent package.'
        echo '4. You will see id=xxxxxx in the download link. Take note of that number.'
        echo '-------------------------------------------------------------------------------'
        echo '\033[0m '
        read -p 'Enter agent ID from VSA download link: ' agentid
        clear
        echo '\033[1;32mDownloading Agent Installer...\033[0m'
        mkdir -p /var/tmp/AgentInstall
        cd /var/tmp/AgentInstall
        # Download the agent from VSA
        curl "$vsaserver/api/v2.0/AssetManagement/asset/download-agent-package?packageid=$agentid" -o "KcsSetup.zip"
        unzip "KcsSetup.zip"
        chmod 755 ./Agent/KcsSetup.app/Contents/MacOS/KcsSetup
        # Install the agent
        echo '\033[1;32mInstalling VSA Agent...\033[0m'
        ./Agent/KcsSetup.app/Contents/MacOS/KcsSetup
        rm -rf /var/tmp/AgentInstall
        echo '\033[1;32mAgent installation process completed!'
        echo '\033[0m '
        read -n 1 -r -s -p $'Press any key to continue...\n'
        exit 1
        ;;
    3)
        clear
        exit 1
        ;;
    *)
        clear
        exit 1
        ;;
esac