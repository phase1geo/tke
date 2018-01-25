#ifndef __MAILBOX_H__
#define __MAILBOX_H__

/*!
 \file    mailbox.h
 \author  Trevor Williams  (phase1geo@gmail.com)
 \date    11/8/2017
 \brief   Contains code for communicating with the ctext model.
*/

#include <queue>
#include <string>
#include <iostream>
#include <iomanip>

#if defined(__MINGW32__) || defined(__MINGW64__)
#include "mingw.thread.h"
#else
#include <thread>
#endif

#include "cpptcl.h"
#include "model.h"
#include "types.h"
#include "request.h"

/*!
 Class for communicating to the model thread using a FIFO.
*/
class mailbox {

  private:

    model                _model;          /*!< Model instance to use */
    std::queue<request*> _requests;       /*!< FIFO of requests */
    std::thread          _th;             /*!< Active thread */
    Tcl::object          _result;         /*!< Stores the last returned result */
    bool                 _update_needed;  /*!< Set to true when a tree update is eventually needed */
    bool                 _thread_active;  /*!< Set to true while the thread is checking queue status */

    /*! Adds the specified request to the mailbox queue */
    void add_request(
      int                 command,
      const Tcl::object & args,
      int                 type,
      bool                tree
    );

  public:

    /*! Default constructor */
    mailbox(
      const std::string & win
    ) : _model( win ), _update_needed( false ), _thread_active( false ) {}

    /*! Destructor */
    ~mailbox();

    /*! Clears the entire mailbox */
    void clear();

    /*! Adds type information to the types list */
    void add_type( const Tcl::object & data ) {
      add_request( REQUEST_ADDTYPE, data, REQUEST_TYPE_UPDATE, false );
    }

    /*! Execute items from the requests queue */
    void execute();

    /*! \return Returns the last calculated result */
    Tcl::object & result() {
      if( _th.joinable() ) { _th.join(); }
      return( _result );
    }

    /*! Handles a text insertion */
    void insert(
      const Tcl::object & args
    ) {
      add_request( REQUEST_INSERT, args, REQUEST_TYPE_UPDATE, false );
    }

    /*! Handles a text list insertion */
    void insertlist(
      const Tcl::object & args
    ) {
      add_request( REQUEST_INSERTLIST, args, REQUEST_TYPE_UPDATE, false );
    }

    /*! Handles a text deletion */
    Tcl::object remove(
      const Tcl::object & args
    ) {
      add_request( REQUEST_DELETE, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    /*! Handles a text replacement */
    Tcl::object replace(
      const Tcl::object & args
    ) {
      add_request( REQUEST_REPLACE, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    /*! Updates model information */
    Tcl::object update(
      const Tcl::object & args
    ) {
      add_request( REQUEST_UPDATE, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    Tcl::object show_serial() {
      Tcl::object none;
      add_request( REQUEST_SHOWSERIAL, none, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    Tcl::object show_tree() {
      Tcl::object none;
      add_request( REQUEST_SHOWTREE, none, REQUEST_TYPE_RETURN, true );
      return( result() );
    }

    Tcl::object get_mismatched() {
      Tcl::object none;
      add_request( REQUEST_MISMATCHED, none, REQUEST_TYPE_RETURN, true );
      return( result() );
    }

    /*!
     \return Returns the text index of the character that matches
             the character at the given text index
    */
    Tcl::object get_match_char(
      const Tcl::object & ti
    ) {
      add_request( REQUEST_MATCHINDEX, ti, REQUEST_TYPE_RETURN, true );
      return( result() );
    }

    /*! \return Returns the tree depth of the given type */
    Tcl::object get_depth(
      const Tcl::object & args
    ) {
      add_request( REQUEST_DEPTH, args, REQUEST_TYPE_RETURN, true );
      return( result() );
    }

    /*! \return Returns true if the given text index is escaped */
    Tcl::object is_escaped(
      const Tcl::object & ti
    ) {
      add_request( REQUEST_ISESCAPED, ti, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    /*! \return Returns true if the given text index contains the given type */
    Tcl::object is_index(
      const Tcl::object & args
    ) {
      add_request( REQUEST_ISINDEX, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    /*! \return Returns a Tcl list containing the indices of all comment markers in the specified ranges */
    Tcl::object get_comment_markers(
      const Tcl::object & ranges
    ) {
      add_request( REQUEST_GETCOMMENTMARKERS, ranges, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    Tcl::object get_range(
      const Tcl::object & args
    ) {
      add_request( REQUEST_RANGE, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    Tcl::object render_contexts(
      const Tcl::object & args
    ) {
      add_request( REQUEST_RENDERCONTEXTS, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    Tcl::object render_linemap(
      const Tcl::object & args
    ) {
      add_request( REQUEST_RENDERLINEMAP, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    void set_marker(
      const Tcl::object & args
    ) {
      add_request( REQUEST_SETMARKER, args, REQUEST_TYPE_UPDATE, false );
    }

    Tcl::object get_marker_name(
      const Tcl::object & row
    ) {
      add_request( REQUEST_GETMARKERNAME, row, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    Tcl::object get_marker_line(
      const Tcl::object & name
    ) {
      add_request( REQUEST_GETMARKERLINE, name, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    void gutter_create(
      const Tcl::object & args
    ) {
      add_request( REQUEST_GUTTERCREATE, args, REQUEST_TYPE_UPDATE, false );
    }

    void gutter_destroy(
      const Tcl::object & name
    ) {
      add_request( REQUEST_GUTTERDESTROY, name, REQUEST_TYPE_UPDATE, false );
    }

    Tcl::object gutter_hide(
      const Tcl::object & args
    ) {
      add_request( REQUEST_GUTTERHIDE, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    void gutter_delete(
      const Tcl::object & args
    ) {
      add_request( REQUEST_GUTTERDELETE, args, REQUEST_TYPE_UPDATE, false );
    }

    void gutter_set(
      const Tcl::object & args
    ) {
      add_request( REQUEST_GUTTERSET, args, REQUEST_TYPE_UPDATE, false );
    }

    void gutter_unset(
      const Tcl::object & args
    ) {
      add_request( REQUEST_GUTTERUNSET, args, REQUEST_TYPE_UPDATE, false );
    }

    Tcl::object gutter_get(
      const Tcl::object & args
    ) {
      add_request( REQUEST_GUTTERGET, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    Tcl::object gutter_cget(
      const Tcl::object & args
    ) {
      add_request( REQUEST_GUTTERCGET, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    Tcl::object gutter_configure(
      const Tcl::object & args
    ) {
      add_request( REQUEST_GUTTERCONFIGURE, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    Tcl::object gutter_names() {
      Tcl::object args;
      add_request( REQUEST_GUTTERNAMES, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    Tcl::object undo() {
      Tcl::object args;
      add_request( REQUEST_UNDO, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    Tcl::object redo() {
      Tcl::object args;
      add_request( REQUEST_REDO, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    Tcl::object undoable() {
      Tcl::object args;
      add_request( REQUEST_UNDOABLE, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    Tcl::object redoable() {
      Tcl::object args;
      add_request( REQUEST_REDOABLE, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    void undo_separator() {
      Tcl::object args;
      add_request( REQUEST_UNDOSEPARATOR, args, REQUEST_TYPE_UPDATE, false );
    }

    void undo_reset() {
      Tcl::object args;
      add_request( REQUEST_UNDORESET, args, REQUEST_TYPE_UPDATE, false );
    }

    /*! Sets the auto-separate feature to the given boolean value */
    void auto_separate(
      const Tcl::object & value
    ) {
      add_request( REQUEST_AUTOSEPARATE, value, REQUEST_TYPE_UPDATE, false );
    }

    Tcl::object cursor_history() {
      Tcl::object args;
      add_request( REQUEST_CURSORHIST, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    Tcl::object fold_delete(
      Tcl::object args
    ) {
      add_request( REQUEST_FOLDDELETE, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    Tcl::object fold_delete_range(
      Tcl::object args
    ) {
      add_request( REQUEST_FOLDDELETERANGE, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    Tcl::object fold_open(
      Tcl::object args
    ) {
      add_request( REQUEST_FOLDOPEN, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    Tcl::object fold_open_range(
      Tcl::object args
    ) {
      add_request( REQUEST_FOLDOPENRANGE, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    Tcl::object fold_show_line(
      Tcl::object line
    ) {
      add_request( REQUEST_FOLDSHOWLINE, line, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    Tcl::object fold_close(
      Tcl::object args
    ) {
      add_request( REQUEST_FOLDCLOSE, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    Tcl::object fold_close_range(
      Tcl::object args
    ) {
      add_request( REQUEST_FOLDCLOSERANGE, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    Tcl::object fold_find(
      Tcl::object args
    ) {
      add_request( REQUEST_FOLDFIND, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    void fold_indent_update() {
      Tcl::object args;
      add_request( REQUEST_FOLDINDENTUPDATE, args, REQUEST_TYPE_UPDATE, false );
    }

    void fold_syntax_update() {
      Tcl::object args;
      add_request( REQUEST_FOLDSYNTAXUPDATE, args, REQUEST_TYPE_UPDATE, true );
    }

    Tcl::object get_firstchar(
      Tcl::object index
    ) {
      add_request( REQUEST_FIRSTCHAR, index, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    /*!
     \return Returns the line number containing the first line that the indent
     marker is a part of.
    */
    Tcl::object indent_line_start(
      Tcl::object indent_index
    ) {
      add_request( REQUEST_INDENTLINESTART, indent_index, REQUEST_TYPE_RETURN, true );
      return( result() );
    }

    /*! \return Returns the number of spaces found before the previous, non-empty line */
    Tcl::object indent_get_previous(
      Tcl::object index
    ) {
      add_request( REQUEST_INDENTPREVIOUS, index, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    /*! \return Returns the number of spaces that precede the given index */
    Tcl::object indent_backspace(
      Tcl::object index
    ) {
      add_request( REQUEST_INDENTBACKSPACE, index, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    /*! \return Returns number of characters to insert/delete at beginning of line. */
    Tcl::object indent_newline(
      Tcl::object args
    ) {
      add_request( REQUEST_INDENTNEWLINE, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    /*! \return Returns information used to handle unindentations */
    Tcl::object indent_check_unindent(
      Tcl::object args
    ) {
      add_request( REQUEST_INDENTCHECKUNINDENT, args, REQUEST_TYPE_RETURN, false );
      return( result() );
    }

    /*! \returns Returns a list used for indentation formatting. */
    Tcl::object indent_format(
      Tcl::object args
    ) {
      add_request( REQUEST_INDENTFORMAT, args, REQUEST_TYPE_RETURN, true );
      return( result() );
    }

};

#endif
