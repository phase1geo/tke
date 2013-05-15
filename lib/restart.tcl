#!wish8.5

# Name:    restart.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/14/2013
# Brief:   Restarts tke.

# Send a signal to the exist application (if it exists) to exit
catch { send tke.tcl handle_signal }

# Start a new tke session with the given arguments
exec {*}$argv &

# Exit
exit
