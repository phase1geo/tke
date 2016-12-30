## Connection Editor

The connection editor pane is displayed when adding a new connection or editing an existing connection.  The following is a depiction of this pane.

![][image-1]

The “Type” field allows you to specify the protocol to use to connect to the remote server.  At present you can connect via FTP, SFTP or WebDAV (if your system supports it — see the installation chapter for details).

The “Group” menu contains the list of created connection groups.  Use this to select which group the connection should be associated with.

The “Name” field is what you will refer to the connection as.  The combination of the group and name fields must be unique within the TKE session, so you can name the connection anything that you would like.  The field is required.

The “Server” field is either the URL server name or the TCP/IP identification of the server to connect to.  This field is required.

The “Username” field is the name of the user to use for logging into the server.  This field is required.

The “Password” field is the password to use along with the username for logging into the server.  This field is optional to specify in the connection.  If a password is entered here, opening the connection will not prompt for a password.  If a password is not specified, opening the connection will prompt for the password.  It is important to note that if a password is entered, it is saved in an encrypted manner such that it is not immediately readable; however, it can be decoded with the proper tools, which is even more important to know if the remote connection file is stored on a service such as Dropbox or iCloud Drive.

The “Port” field specifies the server port that where the connection request will be sent to.  The port value will automatically be set to the standard number whenever the “Type” field is changed; however, if the the server uses a different port, you can change that value in this field.  This field is required.

The “Remote Directory” field specifies the initial directory that will be displayed after successfully connecting to the server.  This field is optional.  If not specified, the server will automatically choose the directory to display.

Once all required fields contain a value, you can use the “Test” button to check if the settings allow a successful connection or not.  The pass or fail status will be displayed in a popup window.  If you get a passing test status, click on the “Create”/“Update” button in the editor to save the connection settings and return the view to the main remote file dialog window.  Click on the “Cancel” button to skip saving the settings changes and return to the main remote file dialog window.

[image-1]:	assets/DraggedImage.png