#include "cpptcl.h"
#include <string>

#include "model.h"

using namespace std;
using namespace Tcl;

// this is a factory function
Person * makePerson(string const &name)
{
     return new Person(name);
}

// this is a sink function
void killPerson(Person *p)
{
     delete p;
}

CPPTCL_MODULE(model, i) {

  // note that the Person class is exposed without any constructor
  i.class_<Person>("tree", no_init)
    .def("update", &tree::update)
    .def("getName", &Person::getName);

  i.def("makePerson", makePerson, factory("Person"));
  i.def("killPerson", killPerson, sink(1));

}

