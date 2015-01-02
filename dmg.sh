#!/bin/sh

# Initialize variables
release_dir=$1
source=${release_dir}/MacOSX/Tke.app
title="TKE"
size=`expr $2 + 500`
backgroundImage=background.png
finalDMGName=${release_dir}.dmg

# Create the DMG as a read/write image
hdiutil create -srcfolder "${source}" -volname "${title}" -fs HFS+ \
  -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${size}k pack.temp.dmg

# Mount the image
device=$(hdiutil attach -readwrite -noverify -noautoopen "pack.temp.dmg" | \
         egrep '^/dev/' | sed 1q | awk '{print $1}')

# Store the background image in the .background directory
chmod -Rf go-w /Volumes/"${title}"
mkdir /Volumes/"${title}"/.background
cp ${release_dir}/MacOSX/image/${backgroundImage} /Volumes/"${title}"/.background

# Run Applescript
echo '
   tell application "Finder"
     tell disk "'${title}'"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {400, 100, 885, 430}
           set theViewOptions to the icon view options of container window
           set arrangement of theViewOptions to not arranged
           set icon size of theViewOptions to 72
           set background picture of theViewOptions to file ".background:'${backgroundImage}'"
           make new alias file at container window to POSIX file "/Applications" with properties {name:"Applications"}
           set position of item "'${applicationName}'" of container window to {100, 100}
           set position of item "Applications" of container window to {375, 100}
           update without registering applications
           delay 5
           close
     end tell
   end tell
' | osascript

# Finalize the DMG
chmod -Rf go-w /Volumes/"${title}"
sync
sync
hdiutil detach ${device}
hdiutil convert "/pack.temp.dmg" -format UDZO -imagekey zlib-level=9 -o "${finalDMGName}"
rm -f /pack.temp.dmg
