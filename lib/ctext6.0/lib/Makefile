DLLOPTS = -Wl,--out-implib=libmodel.dll.a -Wl,--export-all-symbols -Wl,--enable-auto-import -Wl,--no-whole-archive -L/usr/lib/x86_64-linux-gnu -ltcl8.6
CPPFLAGS = -I/usr/include/tcl8.6 -I/usr/include/boost -I../include -I../cpptcl -std=gnu++11 -fPIC

SRCS = cpptcl.cc \
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

OBJS = $(SRCS:.cc=.o)

all: ../model.so

../model.so : $(OBJS)
	g++ $(OBJS) -g -fPIC -std=gnu++11 -shared -o ../model.so -I/usr/include/tcl8.6 -I/usr/include/boost

../model.dll : $(OBJS)
	g++ $(OBJS) -g -std=gnu++11 -shared -o ../model.dll -I/usr/include/tcl8.6 -I/usr/include/boost $(DLLOPTS)

../model.dylib : $(OBJS)
	g++ $(OBJS) -g -fPIC -dynamiclib -o ../model.dylib -I/usr/include/tcl8.6 -I/usr/include/boost -L/usr/lib/x86_64-linux-gnu -ltcl8.6

clean :
	rm -rf $(OBJS)
