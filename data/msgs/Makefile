.PHONEY : updateall update

ifeq ($(OS),Windows_NT)
TCLSH = tclsh86
else
TCLSH = tclsh8.6
endif

updateall :
	$(TCLSH) update.tcl -- -a

update :
	$(TCLSH) update.tcl
