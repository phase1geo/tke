/*!
 \file     mailbox.cc
 \author   Trevor Williams  (phase1geo@gmail.com)
 \date     11/8/2017
*/

#include "mailbox.h"
#include "serial.h"
#include "request.h"

using namespace std;
using namespace Tcl;

static void mailbox_execute(
  mailbox & mbox
) {

  mbox.execute();

}

mailbox::~mailbox() {

  /* Wait for the thread to complete */
  if( _th.joinable() ) {
    _th.join();
  }

}

void mailbox::clear() {

  /* Wait for the thread to complete */
  if( _th.joinable() ) {
    _th.join();
  }

  /* Clear the model */
  _model.clear();

}

void mailbox::add_request(
  int            command,
  const object & args,
  int            type,
  bool           tree
) {

  /*
   If the request FIFO is empty, we don't require an update, the thread is not active and we need a return
   value, execute it without starting a thread
  */
  if( (type == REQUEST_TYPE_RETURN) && (!tree || !_update_needed) && _requests.empty() && !_thread_active ) {

    /* Create the request */
    request req( command, args, type, tree );

    /* Execute the request */
    _result = req.execute( _model, _update_needed );

  /* Otherwise, start the thread */
  } else {

    /* Create the request and add it to the fifo */
    _requests.push( new request( command, args, type, tree ) );

    /* If the processing thread is currently not running, start it now */
    if( !_th.joinable() || !_thread_active ) {
      if( _th.joinable() ) {
        _th.join();
      }
      _thread_active = true;
      _th = GENERIC_THREAD( mailbox_execute, std::ref( *this ) );
    }

  }

}

void mailbox::add_request(
  int            command,
  const object & args,
  const string & callback,
  const object & user_data,
  bool           tree
) {
  
  request*  req = new request( command, args, callback, tree );
  response* rsp = new response( callback, req->rsp_data(), user_data );

  /* Create the request and response and add it to their respective FIFOs */
  _requests.push( req );
  _responses.push( rsp );

  /* If the processing thread is currently not running, start it now */
  if( !_th.joinable() || !_thread_active ) {
    if( _th.joinable() ) {
      _th.join();
    }
    _thread_active = true;
    _th = GENERIC_THREAD( mailbox_execute, std::ref( *this ) );
  }

}

object mailbox::get_callback() {

  object retval;

  if( !_responses.empty() ) {
    retval = _responses.front()->get();
    delete _responses.front();
    _responses.pop();
  }

  return( retval );

}

void mailbox::execute() {

  bool pause = false;

  do {

    /* Service pending requests */
    while( !_requests.empty() && !pause ) {
      if( _update_needed && _requests.front()->tree() ) {
        _model.update_tree();
        _update_needed = false;
      }
      _result = _requests.front()->execute( _model, _update_needed );
      switch( _requests.front()->type() ) {
        case REQUEST_TYPE_RETURN   :  pause = true;  break;
        case REQUEST_TYPE_CALLBACK :  _requests.front()->rsp_data().set_value( _result );  break;
      }
      delete _requests.front();
      _requests.pop();
    }

    /* Update the tree if we need to and we were not paused */
    if( !pause && _update_needed ) {
      _model.update_tree();
    }

  } while( (_thread_active = (!_requests.empty() && !pause)) );

}

/* -------------------------------------------------------------- */

CPPTCL_MODULE(Model, i) {

  /* Define the model class */
  i.class_<mailbox>("model", init<const string &, const string &>())
    .def( "getcallback",         &mailbox::get_callback )
    .def( "clear",               &mailbox::clear )
    .def( "addtype",             &mailbox::add_type )
    .def( "insert",              &mailbox::insert )
    .def( "insertlist",          &mailbox::insertlist )
    .def( "delete",              &mailbox::remove )
    .def( "replace",             &mailbox::replace )
    .def( "update",              &mailbox::update )
    .def( "showserial",          &mailbox::show_serial )
    .def( "showtree",            &mailbox::show_tree )
    .def( "mismatched",          &mailbox::get_mismatched )
    .def( "matchindex",          &mailbox::get_match_char )
    .def( "depth",               &mailbox::get_depth )
    .def( "rendercontexts",      &mailbox::render_contexts )
    .def( "isescaped",           &mailbox::is_escaped )
    .def( "isindex",             &mailbox::is_index )
    .def( "getcommentmarkers",   &mailbox::get_comment_markers )
    .def( "range",               &mailbox::get_range )
    .def( "renderlinemap",       &mailbox::render_linemap )
    .def( "setmarker",           &mailbox::set_marker )
    .def( "getmarkername",       &mailbox::get_marker_name )
    .def( "getmarkerline",       &mailbox::get_marker_line )
    .def( "guttercreate",        &mailbox::gutter_create )
    .def( "gutterdestroy",       &mailbox::gutter_destroy )
    .def( "gutterhide",          &mailbox::gutter_hide )
    .def( "gutterdelete",        &mailbox::gutter_delete )
    .def( "gutterset",           &mailbox::gutter_set )
    .def( "gutterunset",         &mailbox::gutter_unset )
    .def( "gutterget",           &mailbox::gutter_get )
    .def( "guttercget",          &mailbox::gutter_cget )
    .def( "gutterconfigure",     &mailbox::gutter_configure )
    .def( "gutternames",         &mailbox::gutter_names )
    .def( "undo",                &mailbox::undo )
    .def( "redo",                &mailbox::redo )
    .def( "undoable",            &mailbox::undoable )
    .def( "redoable",            &mailbox::redoable )
    .def( "undoseparator",       &mailbox::undo_separator )
    .def( "cursorhistory",       &mailbox::cursor_history )
    .def( "undoreset",           &mailbox::undo_reset )
    .def( "autoseparate",        &mailbox::auto_separate )
    .def( "folddelete",          &mailbox::fold_delete )
    .def( "folddeleterange",     &mailbox::fold_delete_range )
    .def( "foldopen",            &mailbox::fold_open )
    .def( "foldopenrange",       &mailbox::fold_open_range )
    .def( "foldshowline",        &mailbox::fold_show_line )
    .def( "foldclose",           &mailbox::fold_close )
    .def( "foldcloserange",      &mailbox::fold_close_range )
    .def( "foldfind",            &mailbox::fold_find )
    .def( "foldindentupdate",    &mailbox::fold_indent_update )
    .def( "foldsyntaxupdate",    &mailbox::fold_syntax_update )
    .def( "firstchar",           &mailbox::get_firstchar )
    .def( "indentlinestart",     &mailbox::indent_line_start )
    .def( "indentprevious",      &mailbox::indent_get_previous )
    .def( "indentbackspace",     &mailbox::indent_backspace )
    .def( "indentnewline",       &mailbox::indent_newline )
    .def( "indentcheckunindent", &mailbox::indent_check_unindent )
    .def( "indentformat",        &mailbox::indent_format );

}
