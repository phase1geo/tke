# Sessions

As mentioned in various sections in this guide, TKE has support for named sessions.  A session is simply defined as a single TKE window with the following attributes:

- Window geometry and location on the screen
- Fullscreen and zoomed status of the window
- Current working directory
- Command launcher position
- Set of opened directories in the sidebar
- Set of opened files, including information about their pane location, tab location, tab state (i.e., locked, readonly, buffer, language, indent mode, etc.), cursor and yview position
- Markers
- Difference view information including version system and first and second version values
- Global preferences
- Language-specific preferences
- Find, Find/Replace and Find in Files saved search input

Using sessions, you can quickly and efficiently create multiple named sessions and switch between them as the complete saved state of the session is remembered.  This means no fiddling with session setups when working on more than one project or area of a project.  Less friction with environments means more focus on the work.

By default, TKE will start in an unnamed session; however, at any time the user can save the current setup of TKE (whether in a named or unnamed session) as a new named session using the “Sessions / Save As…” option.  This will display an input field at the bottom of the window, allowing the user to specify a name to call the session.  Named sessions are persistent on disk, meaning that they will remain available for switching/opening after TKE has been quit and restarted.

Once the session has been saved under a given name, the title bar of the window will include the name of the session.  A named session can be modified and resaved using the “Sessions / Save Current” menu option.

If you want to exit a given session, at any time you can use the “Sessions / Close Current” menu option.  This will revert the current session back to the last state of the unnamed session.

If you are working in either a named or unnamed session and wish to change the current window to a different session setup, use “Sessions / Switch To” menu option, select one of the available named sessions.  Doing so will change the current window to display the last saved state of the named session.

If you are in a Windows or Linux environment, you can open a new window using a given named session using the “Sessions / Open” menu option and select a previously saved name session.

Finally, if you are done using a named session and would like to remove it from disk, simply select the “Sessions / Delete” menu option and select the named session to delete.  After selecting the “Yes” option, the named session will be permanently removed.

If you are using TKE from the command-line, you can start TKE in a named session by using the ‘-s’ command-line option.  The value passed to ‘-s’ is a name of a session.