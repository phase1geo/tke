# Preferences

Preferences allow you to customize your experience with TKE by modifying various behaviors and/or appearances within the tool. TKE preferences are handled by four types of files:

1. Base preference file (located in the TKE installation directory — in data/preferences.tkedat)
2. User preference file (located at \~/.tke/preferences.tkedat)
3. User language preference files (loaded in the \~/.tke directory)
4. Session files (preference data is stored inside the session file itself)

The preferences files are read and handled at two event times: when TKE is started and when the user preference file is written/saved. If the user preference file does not exist, the base preference file is copied and to the user’s \~/.tke directory and the resulting file is read and its values used.
If the user preference file already exists, its modification timestamp is compared to the timestamp of the base preference file — if the base file is newer than the user preference file, the base preference file is read in, the user preference file values are used in place of the base preference file and the resulting content is written back out to the user preference file. This makes sure that the user’s preference file is always up-to-date with the preferences currently available in the tool. If the user preference file’s modification time is the same as or newer than the base preference file, the user preference contents are used to configure the tool.

When a file is being edited that contains a previously created language preference file, that set of preferences override the user preference values for all tabs that use the given language.

If a session is currently being used, the preferences associated with the session will be used instead of the user preference file. If file with a saved language preference file is being edited within the session, the language preferences within the session will override the session preference file.