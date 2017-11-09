all: model.so

model.so : model.h model.cc
	g++ model.cc cpptcl/cpptcl.cc -g -fPIC -shared -o model.so -I/usr/include/tcl8.6 -I/usr/include/boost

clean :
	rm -rf model.so
