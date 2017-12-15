MAKEFLAGS = -j4

DLLOPTS = -Wl,--out-implib=libmodel.dll.a -Wl,--export-all-symbols -Wl,--enable-auto-import -Wl,--no-whole-archive -LC:/Tcl/lib -ltcl86

$(info $(findstring $(MAKECMDGOALS),../model.dll))

ifneq ($(findstring $(MAKECMDGOALS),../model.dll),)
CPPFLAGS = -Ic:/Tcl/include/tcl8.6 -Ic:/Boost/include/boost-1_65_1 -I../include -I../cpptcl -std=gnu++11 -g -fPIC -MD
CXX      = c:/MinGW/bin/g++
else
CPPFLAGS = -I/usr/include/tcl8.6 -I/usr/include/boost -I../include -I../cpptcl -std=gnu++11 -g -fPIC -MD
endif

SRCS = ../cpptcl/cpptcl.cc \
       linemap.cc \
       linemap_col.cc \
       linemap_colopts.cc \
       linemap_row.cc \
       mailbox.cc \
       model.cc \
       position.cc \
       request.cc \
       serial.cc \
       serial_item.cc \
       side.cc \
       tindex.cc \
       tnode.cc \
       tree.cc \
       undo_buffer.cc \
       undo_change.cc \
       undo_group.cc \
       undo_manager.cc

DEPS = $(SRCS:.cc=.d)
OBJS = $(SRCS:.cc=.o)

all: ../model.so

../model.so : $(OBJS)
	$(CXX) $(OBJS) -g -fPIC -std=gnu++11 -shared -o ../model.so -I/usr/include/tcl8.6 -I/usr/include/boost

../model.dll : $(OBJS)
	$(CXX) $(OBJS) -g -std=gnu++11 -shared -o ../model.dll -Ic:/Tcl/include/tcl8.6 -Ic:/Boost/include/boost-1_65_1 $(DLLOPTS)

../model.dylib : $(OBJS)
	$(CXX) $(OBJS) -g -fPIC -dynamiclib -o ../model.dylib -I/usr/include/tcl8.6 -I/usr/include/boost -L/usr/lib/x86_64-linux-gnu -ltcl8.6

-include $(DEPS)

clean :
	rm -rf *.o *.d
