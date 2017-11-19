INCS    = -I/usr/include/tcl8.6 -I/usr/include/boost
DLLOPTS = -Wl,--out-implib=libmodel.dll.a -Wl,--export-all-symbols -Wl,--enable-auto-import -Wl,--no-whole-archive -L/usr/lib/x86_64-linux-gnu -ltcl8.6

INCS = model.h \
       linemap.h \
       undo.h \
       utils.h

SRCS = model.cc \
       linemap.cc \
       undo.cc

all: model.so

model.so : $(INCS) $(SRCS)
	g++ $(SRCS) cpptcl/cpptcl.cc -g -fPIC -std=gnu++11 -shared -o model.so -I/usr/include/tcl8.6 -I/usr/include/boost

model.dll : $(INCS) $(SRCS)
	g++ $(SRCS) cpptcl/cpptcl.cc -g -std=gnu++11 -shared -o model.dll -I/usr/include/tcl8.6 -I/usr/include/boost $(DLLOPTS)

model.dylib : $(INCS) $(SRCS)
	g++ $(SRCS) cpptcl/cpptcl.cc -g -fPIC -dynamiclib -o model.dylib -I/usr/include/tcl8.6 -I/usr/include/boost -L/usr/lib/x86_64-linux-gnu -ltcl8.6

