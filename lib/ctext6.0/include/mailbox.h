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
#include <thread>

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
      bool                result,
      bool                tree
    );

  public:

    /*! Default constructor */
    mailbox(
      const std::string & win
    ) : _model( win ), _update_needed( false ), _thread_active( false ) {}

    /*! Destructor */
    ~mailbox();

    /*! Execute items from the requests queue */
    void execute();

    /*! \return Returns the last calculated result */
    Tcl::object & result() {
      if( _th.joinable() ) { _th.join(); }
      return( _result );
    }

    /*! Handles a text insertion */
    void insert(
      const Tcl::object & ranges,
      const Tcl::object & str,
      const Tcl::object & cursor
    );

    /*! Handles a text deletion */
    void remove(
      const Tcl::object & ranges,
      const Tcl::object & strs,
      const Tcl::object & cursor
    );

    /*! Handles a text replacement */
    void replace(
      const Tcl::object & ranges,
      const Tcl::object & dstrs,
      const Tcl::object & istr,
      const Tcl::object & cursor
    );

    /*! Updates model information */
    Tcl::object update(
      const Tcl::object & linestart,
      const Tcl::object & lineend,
      const Tcl::object & elements
    );

    Tcl::object show_serial();

    Tcl::object show_tree();

    Tcl::object get_mismatched();

    /*!
     \return Returns the text index of the character that matches
             the character at the given text index
    */
    Tcl::object get_match_char(
      const Tcl::object & ti
    );

    /*! \return Returns the tree depth of the given type */
    Tcl::object get_depth(
      const Tcl::object & index,
      const Tcl::object & type
    );

    /*! \return Returns true if the given text index is escaped */
    Tcl::object is_escaped(
      const Tcl::object & ti
    );

    /*! \return Returns true if the given text index contains the given type */
    Tcl::object is_index(
      const Tcl::object & type,
      const Tcl::object & ti
    );

    Tcl::object render_contexts(
      const Tcl::object & linestart,
      const Tcl::object & lineend,
      const Tcl::object & tags
    );

    Tcl::object render_linemap(
      const Tcl::object & first_row,
      const Tcl::object & last_row
    );

    void set_marker(
      const Tcl::object & row,
      const Tcl::object & name
    );

    Tcl::object get_marker(
      const Tcl::object & row
    );

    void gutter_create(
      const Tcl::object & name,
      const Tcl::object & values
    );

    void gutter_destroy(
      const Tcl::object & name
    );

    Tcl::object gutter_hide(
      const Tcl::object & name,
      const Tcl::object & value
    );

    void gutter_delete(
      const Tcl::object & name,
      const Tcl::object & syms
    );

    void gutter_set(
      const Tcl::object & name,
      const Tcl::object & values
    );

    void gutter_unset(
      const Tcl::object & name_obj,
      const Tcl::object & first_obj,
      const Tcl::object & last_obj
    );

    Tcl::object gutter_get(
      const Tcl::object & name,
      const Tcl::object & value
    );

    Tcl::object gutter_cget(
      const Tcl::object & name,
      const Tcl::object & sym,
      const Tcl::object & opt
    );

    Tcl::object gutter_configure(
      const Tcl::object & name,
      const Tcl::object & sym,
      const Tcl::object & opts
    );

    Tcl::object gutter_names();

    Tcl::object undo();

    Tcl::object redo();

    Tcl::object undoable();

    Tcl::object redoable();

    void undo_separator();

    void undo_reset();

    /*! Sets the auto-separate feature to the given boolean value */
    void auto_separate(
      const Tcl::object & value
    );

    Tcl::object cursor_history();

    /*!
     \return Returns the line number containing the first line that the indent
     marker is a part of.
    */
    Tcl::object indent_line_start(
      Tcl::object indent_index
    );

};

#endif
