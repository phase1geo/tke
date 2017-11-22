/*!
 \file     undo_buffer.cc
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/17/2017
*/

#include "undo_buffer.h"

using namespace std;
using namespace Tcl;

object undo_buffer::cursor_history() const {

  object result;

  for( vector<undo_group*>::const_reverse_iterator it=rbegin(); it!=rend(); it++ ) {
    (*it)->cursor_history( result );
  }

  return( result );

}

