/*!
 \file     request.cc
 \author   Trevor Williams  (phase1geo@gmail.com)
 \date     11/8/2017
*/

#include "request.h"

using namespace std;
using namespace Tcl;

object request::execute(
  model & inst,
  bool  & update_needed
) const {

  switch( _command ) {
    case REQUEST_ADDTYPE    :
      inst.add_type( _args );
      break;
    case REQUEST_INSERT     :
      inst.insert( _args );
      break;
    case REQUEST_INSERTLIST :
      inst.insertlist( _args );
      break;
    case REQUEST_DELETE     :
      return( inst.remove( _args ) );
      break;
    case REQUEST_REPLACE    :
      return( inst.replace( _args ) );
      break;
    case REQUEST_UPDATE     :
      if( inst.update( _args ) ) {
        update_needed = true;
        return( (object)true );
      }
      return( (object)false );
      break;
    case REQUEST_SHOWSERIAL :
      return( (object)inst.show_serial() );
      break;
    case REQUEST_SHOWTREE   :
      return( (object)inst.show_tree() );
      break;
    case REQUEST_MISMATCHED :
      return( inst.get_mismatched() );
      break;
    case REQUEST_MATCHINDEX :
      return( inst.get_match_char( _args ) );
      break;
    case REQUEST_DEPTH :
      return( (object)inst.get_depth( _args ) );
      break;
    case REQUEST_RENDERCONTEXTS :
      return( inst.render_contexts( _args ) );
      break;
    case REQUEST_ISESCAPED :
      return( (object)inst.is_escaped( _args ) );
      break;
    case REQUEST_ISINDEX :
      return( (object)inst.is_index( _args ) );
      break;
    case REQUEST_GETCOMMENTMARKERS :
      return( inst.get_comment_markers( _args ) );
      break;
    case REQUEST_RANGE :
      return( inst.get_range( _args ) );
      break;
    case REQUEST_RENDERLINEMAP :
      return( inst.render_linemap( _args ) );
      break;
    case REQUEST_SETMARKER :
      inst.set_marker( _args );
      break;
    case REQUEST_GETMARKERNAME :
      return( inst.get_marker_name( _args ) );
      break;
    case REQUEST_GETMARKERLINE :
      return( inst.get_marker_line( _args ) );
      break;
    case REQUEST_GUTTERCREATE :
      inst.gutter_create( _args );
      break;
    case REQUEST_GUTTERDESTROY :
      inst.gutter_destroy( _args );
      break;
    case REQUEST_GUTTERHIDE :
      return( (object)inst.gutter_hide( _args ) );
      break;
    case REQUEST_GUTTERDELETE :
      inst.gutter_delete( _args );
      break;
    case REQUEST_GUTTERSET :
      inst.gutter_set( _args );
      break;
    case REQUEST_GUTTERUNSET :
      inst.gutter_unset( _args );
      break;
    case REQUEST_GUTTERGET :
      return( inst.gutter_get( _args ) );
      break;
    case REQUEST_GUTTERCGET :
      return( inst.gutter_cget( _args ) );
      break;
    case REQUEST_GUTTERCONFIGURE :
      return( inst.gutter_configure( _args ) );
      break;
    case REQUEST_GUTTERNAMES :
      return( inst.gutter_names() );
      break;
    case REQUEST_UNDO :
      return( inst.undo() );
      break;
    case REQUEST_REDO :
      return( inst.redo() );
      break;
    case REQUEST_UNDOABLE :
      return( inst.undoable() );
      break;
    case REQUEST_REDOABLE :
      return( inst.redoable() );
      break;
    case REQUEST_UNDOSEPARATOR :
      inst.undo_separator();
      break;
    case REQUEST_UNDORESET :
      inst.undo_reset();
      break;
    case REQUEST_AUTOSEPARATE :
      inst.auto_separate( _args );
      break;
    case REQUEST_CURSORHIST :
      return( inst.cursor_history() );
      break;
    case REQUEST_FOLDDELETE :
      return( inst.fold_delete( _args ) );
      break;
    case REQUEST_FOLDDELETERANGE :
      return( inst.fold_delete_range( _args ) );
      break;
    case REQUEST_FOLDOPEN :
      return( inst.fold_open( _args ) );
      break;
    case REQUEST_FOLDOPENRANGE :
      return( inst.fold_open_range( _args ) );
      break;
    case REQUEST_FOLDSHOWLINE :
      return( inst.fold_show_line( _args ) );
      break;
    case REQUEST_FOLDCLOSE :
      return( inst.fold_close( _args ) );
      break;
    case REQUEST_FOLDCLOSERANGE :
      return( inst.fold_close_range( _args ) );
      break;
    case REQUEST_FOLDFIND :
      return( inst.fold_find( _args ) );
      break;
    case REQUEST_FOLDINDENTUPDATE :
      inst.fold_indent_update();
      break;
    case REQUEST_FOLDSYNTAXUPDATE :
      inst.fold_syntax_update();
      break;
    case REQUEST_FIRSTCHAR :
      return( inst.get_firstchar( _args ) );
      break;
    case REQUEST_INDENTLINESTART :
      return( inst.indent_line_start( _args ) );
      break;
    case REQUEST_INDENTPREVIOUS :
      return( inst.indent_get_previous( _args ) );
      break;
    case REQUEST_INDENTBACKSPACE :
      return( inst.indent_backspace( _args ) );
      break;
    case REQUEST_INDENTNEWLINE :
      return( inst.indent_newline( _args ) );
      break;
    case REQUEST_INDENTCHECKUNINDENT :
      return( inst.indent_check_unindent( _args ) );
      break;
    case REQUEST_INDENTFORMAT :
      return( inst.indent_format( _args ) );
      break;
    default :
      throw runtime_error( "Unknown command" );
      break;
  }

  return( (object)0 );

}

