INCS    = -I/usr/include/tcl8.6 -I/usr/include/boost
DLLOPTS = -Wl,--out-implib=libmodel.dll.a -Wl,--export-all-symbols -Wl,--enable-auto-import -Wl,--no-whole-archive -L/usr/lib/x86_64-linux-gnu -ltcl8.6

all: model.so

model.so : model.h model.cc
	g++ model.cc cpptcl/cpptcl.cc -g -fPIC -std=gnu++11 -shared -o model.so -I/usr/include/tcl8.6 -I/usr/include/boost

model.dll : model.h model.cc
	g++ model.cc cpptcl/cpptcl.cc -g -shared -o model.dll -I/usr/include/tcl8.6 -I/usr/include/boost $(DLLOPTS)

model.dylib : model.h model.cc
	g++ model.cc cpptcl/cpptcl.cc -g -fPIC -dynamiclib -o model.dylib -I/usr/include/tcl8.6 -I/usr/include/boost -L/usr/lib/x86_64-linux-gnu -ltcl8.6

