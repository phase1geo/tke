//
// Copyright (C) 2004-2006, Maciej Sobczak
//
// Permission to copy, use, modify, sell and distribute this software
// is granted provided this copyright notice appears in all copies.
// This software is provided "as is" without express or implied
// warranty, and with no claim as to its suitability for any purpose.
//

#include "../cpptcl.h"
#include <iostream>

using namespace Tcl;


int funv1(int, object const &o)
{
     interpreter i(o.get_interp(), false);
     return o.length(i);
}

int funv2(int a, int b, object const &o)
{
     assert(a == 1);
     assert(b == 2);

     interpreter i(o.get_interp(), false);
     assert(o.get<int>(i) == 3);

     return o.length(i);
}

int funv3(int a, int b, object const &o)
{
     assert(a == 1);
     assert(b == 2);

     interpreter i(o.get_interp(), false);
     assert(o.length(i) == 3);
     assert(o.at(i, 0).get<int>(i) == 3);
     assert(o.at(i, 1).get<int>(i) == 4);
     assert(o.at(i, 2).get<int>(i) == 5);

     return o.length(i);
}

class C
{
public:
     C() {}

     C(int, object const &o)
     {
          interpreter i(o.get_interp(), false);
          len_ = o.length(i);
     }

     int getLen() const { return len_; }

     int len(int, object const &o)
     {
          interpreter i(o.get_interp(), false);
          return o.length(i);
     }

     int lenc(int, object const &o) const
     {
          interpreter i(o.get_interp(), false);
          return o.length(i);
     }

private:
     int len_;
};

void test1()
{
     interpreter i;
     std::stringstream ss("set i 5\nset i");

     int ret = i.eval(ss);
     assert(ret == 5);
}

void test2()
{
     interpreter i;
     i.def("fun1", funv1);
     i.def("fun1v", funv1, variadic());

     int ret = i.eval("fun1 1 2 3 4");
     assert(ret == 1);

     try
     {
          i.eval("fun1 1");
          assert(false);
     }
     catch (tcl_error const &e)
     {
          assert(e.what() == std::string("Too few arguments."));
     }

     ret = i.eval("fun1v 1 2 3 4");
     assert(ret == 3);

     ret = i.eval("fun1v 1");
     assert(ret == 0);

     i.def("fun2", funv2);
     ret = i.eval("fun2 1 2 3 4 5");
     assert(ret == 1);

     i.def("fun3", funv3, variadic());
     ret = i.eval("fun3 1 2 3 4 5");
     assert(ret == 3);


     i.class_<C>("C", init<int, object const &>())
          .def("len", &C::getLen);

     ret = i.eval(
          "set obj [C 1 2 3 4]\n"
          "set len [$obj len]\n"
          "$obj -delete\n"
          "set len"
     );
     assert(ret == 1);

     i.class_<C>("Cv", init<int, object const &>(), variadic())
          .def("len", &C::getLen);

     ret = i.eval(
          "set obj [Cv 1 2 3 4]\n"
          "set len [$obj len]\n"
          "$obj -delete\n"
          "set len"
     );
     assert(ret == 3);

     ret = i.eval(
          "set obj [Cv 1]\n"
          "set len [$obj len]\n"
          "$obj -delete\n"
          "set len"
     );
     assert(ret == 0);

     i.class_<C>("C2")
          .def("len", &C::len)
          .def("lenv", &C::len, variadic())
          .def("lenc", &C::len)
          .def("lencv", &C::len, variadic());

     i.eval("set obj [C2]");

     ret = i.eval("$obj len 1 2 3 4");
     assert(ret == 1);

     ret = i.eval("$obj lenv 1 2 3 4");
     assert(ret == 3);

     ret = i.eval("$obj lenv 1");
     assert(ret == 0);

     ret = i.eval("$obj lenc 1 2 3 4");
     assert(ret == 1);

     ret = i.eval("$obj lencv 1 2 3 4");
     assert(ret == 3);

     i.eval("$obj -delete");
}

int main()
{
     try
     {
          test1();
          test2();
     }
     catch (std::exception const &e)
     {
          std::cerr << "Error: " << e.what() << '\n';
     }
}
