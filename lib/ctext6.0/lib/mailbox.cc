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
  bool           result,
  bool           tree
) {

  /* Create the request and add it to the fifo */
  _requests.push( new request( command, args, result, tree ) );

  /* If the processing thread is currently running, start it now */
  if( !_th.joinable() || !_thread_active ) {
    if( _th.joinable() ) {
      _th.join();
    }
    _thread_active = true;
    _th = thread( mailbox_execute, std::ref( *this ) );
  }

}

void mailbox::execute() {

  bool pause = false;
  int  count = 0;

  do {

    /* Service pending requests */
    while( !_requests.empty() && !pause ) {
      if( _update_needed && _requests.front()->tree() ) {
        _model.update_tree();
        _update_needed = false;
      }
      _result = _requests.front()->execute( _model, _update_needed );
      pause   = _requests.front()->result();
      delete _requests.front();
      _requests.pop();
      count++;
    }

    /* Update the tree if we need to and we were not paused */
    if( !pause && _update_needed ) {
      _model.update_tree();
    }

  } while( (_thread_active = (!_requests.empty() && !pause)) );

}

void mailbox::insert(
  const object & ranges,
  const object & str,
  const object & cursor
) {

  interpreter i( ranges.get_interp(), false );
  object      args;

  args.append( i, ranges );
  args.append( i, str );
  args.append( i, cursor );

  add_request( REQUEST_INSERT, args, false, false );

}

void mailbox::insertlist(
  const object & ranges,
  const object & strs,
  const object & cursor
) {

  interpreter i( ranges.get_interp(), false );
  object      args;

  args.append( i, ranges );
  args.append( i, strs );
  args.append( i, cursor );

  add_request( REQUEST_INSERTLIST, args, false, false );

}

object mailbox::remove(
  const object & ranges,
  const object & strs,
  const object & cursor
) {

  interpreter i( ranges.get_interp(), false );
  object      args;

  args.append( i, ranges );
  args.append( i, strs );
  args.append( i, cursor );

  add_request( REQUEST_DELETE, args, true, false );

  return( result() );

}

object mailbox::replace(
  const object & ranges,
  const object & dstrs,
  const object & istr,
  const object & cursor
) {

  interpreter i( ranges.get_interp(), false );
  object      args;

  args.append( i, ranges );
  args.append( i, dstrs );
  args.append( i, istr );
  args.append( i, cursor );

  add_request( REQUEST_REPLACE, args, true, false );

  return( result() );

}

object mailbox::update(
  const object & linestart,
  const object & lineend,
  const object & elements
) {

  interpreter i( linestart.get_interp(), false );
  object      args;

  args.append( i, linestart );
  args.append( i, lineend );
  args.append( i, elements );

  add_request( REQUEST_UPDATE, args, false, false );

  return( result() );

}

object mailbox::show_serial() {

  object none;

  add_request( REQUEST_SHOWSERIAL, none, true, false );

  return( result() );

}

object mailbox::show_tree() {

  object none;

  add_request( REQUEST_SHOWTREE, none, true, true );

  return( result() );

}

object mailbox::get_mismatched() {

  object none;

  add_request( REQUEST_MISMATCHED, none, true, true );

  return( result() );

}

object mailbox::get_match_char(
  const object & ti
) {

  add_request( REQUEST_MATCHINDEX, ti, true, true );

  return( result() );

}

object mailbox::get_depth(
  const object & ti,
  const object & type
) {

  interpreter i( ti.get_interp(), false );
  object      args;

  args.append( i, ti );
  args.append( i, type );

  add_request( REQUEST_DEPTH, args, true, true );

  return( result() );

}

object mailbox::is_escaped(
  const object & ti
) {

  add_request( REQUEST_ISESCAPED, ti, true, false );

  return( result() );

}

object mailbox::is_index(
  const object & type,
  const object & ti
) {

  interpreter i( type.get_interp(), false );
  object      args;

  args.append( i, type );
  args.append( i, ti );

  add_request( REQUEST_ISINDEX, args, true, false );

  return( result() );

}

object mailbox::get_comment_markers(
  const object & ranges
) {

  add_request( REQUEST_GETCOMMENTMARKERS, ranges, true, false );

  return( result() );

}

object mailbox::render_contexts(
  const object & linestart,
  const object & lineend,
  const object & tags
) {

  interpreter i( linestart.get_interp(), false );
  object      args;

  args.append( i, linestart );
  args.append( i, lineend );
  args.append( i, tags );

  add_request( REQUEST_RENDERCONTEXTS, args, true, false );

  return( result() );

}

object mailbox::render_linemap(
  const object & first_row,
  const object & last_row
) {

  interpreter i( first_row.get_interp(), false );
  object      args;

  args.append( i, first_row );
  args.append( i, last_row );

  add_request( REQUEST_RENDERLINEMAP, args, true, false );

  return( result() );

}

void mailbox::set_marker(
  const object & row,
  const object & name
) {

  interpreter i( row.get_interp(), false );
  object      args;

  args.append( i, row );
  args.append( i, name );

  add_request( REQUEST_SETMARKER, args, false, false );

}

object mailbox::get_marker_name(
  const object & row
) {

  add_request( REQUEST_GETMARKERNAME, row, true, false );

  return( result() );

}

object mailbox::get_marker_line(
  const object & name
) {

  add_request( REQUEST_GETMARKERLINE, name, true, false );

  return( result() );

}

void mailbox::gutter_create(
  const object & name,
  const object & opts
) {

  interpreter i( name.get_interp(), false );
  object      args;

  args.append( i, name );
  args.append( i, opts );

  add_request( REQUEST_GUTTERCREATE, args, false, false );

}

void mailbox::gutter_destroy(
  const object & name
) {

  add_request( REQUEST_GUTTERDESTROY, name, false, false );

}

object mailbox::gutter_hide(
  const object & name,
  const object & value
) {

  interpreter i( name.get_interp(), false );
  object      args;

  args.append( i, name );
  args.append( i, value );

  add_request( REQUEST_GUTTERHIDE, args, true, false );

  return( result() );

}

void mailbox::gutter_delete(
  const object & name,
  const object & syms
) {

  interpreter i( name.get_interp(), false );
  object      args;

  args.append( i, name );
  args.append( i, syms );

  add_request( REQUEST_GUTTERDELETE, args, false, false );

}

void mailbox::gutter_set(
  const object & name,
  const object & values
) {

  interpreter i( name.get_interp(), false );
  object      args;

  args.append( i, name );
  args.append( i, values );

  add_request( REQUEST_GUTTERSET, args, false, false );

}

void mailbox::gutter_unset(
  const object & name,
  const object & first,
  const object & last
) {

  interpreter i( name.get_interp(), false );
  object      args;

  args.append( i, name );
  args.append( i, first );
  args.append( i, last );

  add_request( REQUEST_GUTTERUNSET, args, false, false );

}

object mailbox::gutter_get(
  const object & name,
  const object & value
) {

  interpreter i( name.get_interp(), false );
  string      val = value.get<string>( i );
  object      args;

  args.append( i, name );
  args.append( i, value );

  if( val == "" ) {
    args.append( i, (object)false );
  } else {
    string cmd = "string is int " + val;
    args.append( i, i.eval( cmd ) );
  }

  add_request( REQUEST_GUTTERGET, args, true, false );

  return( result() );

}

object mailbox::gutter_cget(
  const object & name,
  const object & sym,
  const object & opt
) {

  interpreter i( name.get_interp(), false );
  object      args;

  args.append( i, name );
  args.append( i, sym );
  args.append( i, opt );

  add_request( REQUEST_GUTTERCGET, args, true, false );

  return( result() );

}

object mailbox::gutter_configure(
  const object & name,
  const object & sym,
  const object & opts
) {

  interpreter i( name.get_interp(), false );
  object      args;

  args.append( i, name );
  args.append( i, sym );
  args.append( i, opts );

  add_request( REQUEST_GUTTERCONFIGURE, args, true, false );

  return( result() );

}

object mailbox::gutter_names() {

  object args;

  add_request( REQUEST_GUTTERNAMES, args, true, false );

  return( result() );

}

object mailbox::undo() {

  object args;

  add_request( REQUEST_UNDO, args, true, false );

  return( result() );

}

object mailbox::redo() {

  object args;

  add_request( REQUEST_REDO, args, true, false );

  return( result() );

}

object mailbox::undoable() {

  object args;

  add_request( REQUEST_UNDOABLE, args, true, false );

  return( result() );

}

object mailbox::redoable() {

  object args;

  add_request( REQUEST_REDOABLE, args, true, false );

  return( result() );

}

void mailbox::undo_separator() {

  object args;

  add_request( REQUEST_UNDOSEPARATOR, args, false, false );

}

void mailbox::undo_reset() {

  object args;

  add_request( REQUEST_UNDORESET, args, false, false );

}

void mailbox::auto_separate(
  const Tcl::object & value
) {

  add_request( REQUEST_AUTOSEPARATE, value, false, false );

}

object mailbox::cursor_history() {

  object args;

  add_request( REQUEST_CURSORHIST, args, true, false );

  return( result() );

}

object mailbox::fold_delete(
  object line,
  object depth
) {

  interpreter i( line.get_interp(), false );
  object      args;

  args.append( i, line );
  args.append( i, depth );

  add_request( REQUEST_FOLDDELETE, args, true, false );

  return( result() );

}

object mailbox::fold_delete_range(
  object startline,
  object endline
) {

  interpreter i( startline.get_interp(), false );
  object      args;

  args.append( i, startline );
  args.append( i, endline );

  add_request( REQUEST_FOLDDELETERANGE, args, true, false );

  return( result() );

}

object mailbox::fold_open(
  object startline,
  object depth
) {

  interpreter i( startline.get_interp(), false );
  object      args;

  args.append( i, startline );
  args.append( i, depth );

  add_request( REQUEST_FOLDOPEN, args, true, false );

  return( result() );

}

object mailbox::fold_open_range(
  object startline,
  object endline,
  object depth
) {

  interpreter i( startline.get_interp(), false );
  object      args;

  args.append( i, startline );
  args.append( i, endline );
  args.append( i, depth );

  add_request( REQUEST_FOLDOPENRANGE, args, true, false );

  return( result() );

}

object mailbox::fold_show_line(
  object line
) {

  add_request( REQUEST_FOLDSHOWLINE, line, true, false );

  return( result() );

}

object mailbox::fold_close(
  object startline,
  object depth
) {

  interpreter i( startline.get_interp(), false );
  object      args;

  args.append( i, startline );
  args.append( i, depth );

  add_request( REQUEST_FOLDCLOSE, args, true, false );

  return( result() );

}

object mailbox::fold_close_range(
  object startline,
  object endline,
  object depth
) {

  interpreter i( startline.get_interp(), false );
  object      args;

  args.append( i, startline );
  args.append( i, endline );
  args.append( i, depth );

  add_request( REQUEST_FOLDCLOSERANGE, args, true, false );

  return( result() );

}

object mailbox::fold_find(
  object startline,
  object dir,
  object num
) {

  interpreter i( startline.get_interp(), false );
  object      args;

  args.append( i, startline );
  args.append( i, dir );
  args.append( i, num );

  add_request( REQUEST_FOLDFIND, args, true, false );

  return( result() );

}

void mailbox::fold_indent_update(
  object ranges
) {

  add_request( REQUEST_FOLDINDENTUPDATE, ranges, false, false );

}

void mailbox::fold_syntax_update() {

  object args;

  add_request( REQUEST_FOLDSYNTAXUPDATE, args, false, true );

}

object mailbox::indent_line_start(
  object indent_index
) {

  add_request( REQUEST_INDENTLINESTART, indent_index, true, true );

  return( result() );

}

object mailbox::indent_check_unindent(
  object first_ti,
  object curr_ti
) {

  interpreter i( first_ti.get_interp(), false );
  object      args;

  args.append( i, first_ti );
  args.append( i, curr_ti );

  add_request( REQUEST_INDENTCHECKUNINDENT, args, true, false );

  return( result() );

}

/* -------------------------------------------------------------- */

CPPTCL_MODULE(Model, i) {

  /* Define the model class */
  i.class_<mailbox>("model", init<const string &>())
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
    .def( "indentlinestart",     &mailbox::indent_line_start )
    .def( "indentprevious",      &mailbox::indent_get_previous )
    .def( "indentbackspace",     &mailbox::indent_backspace )
    .def( "indentnewline",       &mailbox::indent_newline )
    .def( "indentcheckunindent", &mailbox::indent_check_unindent )
    .def( "indentformat",        &mailbox::indent_format );

}
