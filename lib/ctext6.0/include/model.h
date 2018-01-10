#ifndef __MODEL_H__
#define __MODEL_H__

/*!
 \file    model.h
 \author  Trevor Williams  (phase1geo@gmail.com)
 \date    11/8/2017
 \brief   Contains functions for storing, updating and retrieving information
          for the marker modeller.
*/

#include <vector>
#include <string>
#include <map>
#include <iostream>

#include "cpptcl.h"
#include "types.h"
#include "serial.h"
#include "tree.h"
#include "linemap.h"
#include "undo_manager.h"

/*!
 Main modelling class that the Tcl core will interact with.
*/
class model {

  private:

    types        _types;        /*!< Type information */
    serial       _serial;       /*!< Serial list structure */
    tree         _tree;         /*!< Tree structure */
    linemap      _linemap;      /*!< Line map structure */
    undo_manager _undo_buffer;  /*!< Undo buffer */
    std::string  _win;          /*!< Name of this model */
    bool         _edited;       /*!< Set to false until after the model is changed */

    /*!
     Converts the given object to a vector of text indices.
    */
    void object_to_ranges(
      const Tcl::object   & obj,
      std::vector<tindex> & vec
    );

    /*!
     Adds the given tag index to the list.
    */
    void add_tag_index(
      Tcl::interpreter                  & i,
      std::map<std::string,Tcl::object> & ranges,
      const std::string                 & tag,
      const std::string                 & index
    );

  public:

    /*! Default constructor */
    model( const std::string & win ) : _win( win ), _edited( false ) {}

    /*! Destructor */
    ~model() {}

    /*! Clears the model contents */
    void clear();

    /*! Adds a single type information to this model */
    void add_type(
      const Tcl::object & data
    ) {
      Tcl::interpreter interp( data.get_interp(), false );
      _types.add( data.at( interp, 0 ).get<std::string>( interp ),
                  data.at( interp, 1 ).get<std::string>( interp ),
                  data.at( interp, 2 ).get<int>( interp ),
                  data.at( interp, 3 ).get<int>( interp ),
                  data.at( interp, 4 ).get<int>( interp ),
                  data.at( interp, 5 ).get<int>( interp ),
                  data.at( interp, 6 ).get<int>( interp ) );
    }

    /*! Called when text is going to be inserted.  Adjusts the indices accordingly. */
    void insert(
      const Tcl::object & ranges,
      const Tcl::object & str,
      const Tcl::object & cursor
    ) {
      std::vector<tindex> vec;
      object_to_ranges( ranges, vec );
      _serial.insert( vec );
      _linemap.insert( vec );
      if( _edited ) {
        _undo_buffer.add_insertion( vec, str, cursor );
      }
      _edited = true;
    }

    /*! Called when text is going to be inserted.  Adjusts the indices accordingly. */
    void insertlist(
      const Tcl::object & ranges,
      const Tcl::object & strs,
      const Tcl::object & cursor
    ) {
      std::vector<tindex> vec;
      object_to_ranges( ranges, vec );
      _serial.insert( vec );
      _linemap.insert( vec );
      if( _edited ) {
        _undo_buffer.add_insertion_list( vec, strs, cursor );
      }
      _edited = true;
    }

    /*! Called when text is going to be deleted.  Adjusts the indices accordingly. */
    Tcl::object remove(
      const Tcl::object & ranges,
      const Tcl::object & strs,
      const Tcl::object & cursor
    ) {
      std::vector<tindex> vec;
      Tcl::object         result;
      object_to_ranges( ranges, vec );
      _serial.remove( vec );
      result = _linemap.remove( vec );
      if( _edited ) {
        _undo_buffer.add_deletion( vec, strs, cursor );
      }
      _edited = true;
      return( result );
    }

    /*! Called when text is going to be replaced.  Adjusts the indices accordingly. */
    Tcl::object replace(
      const Tcl::object & ranges,
      const Tcl::object & dstrs,
      const Tcl::object & istrs,
      const Tcl::object & cursor
    ) {
      std::vector<tindex> vec;
      Tcl::object         result;
      object_to_ranges( ranges, vec );
      _serial.replace( vec );
      result = _linemap.replace( vec );
      if( _edited ) {
        _undo_buffer.add_replacement( vec, dstrs, istrs, cursor );
      }
      _edited = true;
      return( result );
    }

    /*! Updates the model with the given tag information */
    bool update(
      const Tcl::object & linestart,
      const Tcl::object & lineend,
      const Tcl::object & elements
    );

    /*! Update the tree with the contents of the serial list */
    void update_tree() {
      _tree.update( _serial, _types );
      _tree.add_folds( _linemap, _types );
    }

    /*! \return Returns a human-readable representation of the stored serial list */
    std::string show_serial() const { return( _serial.show() ); }

    /*! \return Returns a graphical representation of the stored tree */
    std::string show_tree() const { return( _tree.tree_string() ); }

    /*! \return Returns the list of mismatched indices */
    Tcl::object get_mismatched() const;

    /*!
     \return Returns the character range of the matching char if found; otherwise,
             outputs the empty string.
    */
    Tcl::object get_match_char(
      const Tcl::object & ti
    );

    /*! \return Returns the depth of the given item in the tree */
    int get_depth(
      const Tcl::object & index,
      const Tcl::object & type
    );

    /*!
     Handles rendering all of the contexts in the given list as well
     as what is stored in the model.
    */
    Tcl::object render_contexts(
      const Tcl::object & linestart,
      const Tcl::object & lineend,
      const Tcl::object & tags
    );

    /*! \return Returns true if the given text index is immediately preceded by an escape */
    bool is_escaped(
      const Tcl::object & ti
    ) const;

    /*! \return Returns true if the given text index contains the given type */
    bool is_index(
      const Tcl::object & type,
      const Tcl::object & ti
    ) const;

    /*! \return Returns comment marker positions in a Tcl list */
    Tcl::object get_comment_markers(
      const Tcl::object & ranges
    ) const {
      return( _serial.get_comment_markers( ranges, _types ) );
    }

    /*!
     Handles rendering the currently viewable linemap.
    */
    Tcl::object render_linemap(
      const Tcl::object & first_row,
      const Tcl::object & last_row
    ) const {
      return( _linemap.render( first_row, last_row ) );
    }

    /*! Adds a marker to the linemap with the given name for the given line */
    void set_marker(
      const Tcl::object & row,
      const Tcl::object & name
    ) {
      _linemap.set_marker( row, name );
    }

    /*! \return Returns the name of the marker stored at the given row */
    Tcl::object get_marker_name(
      const Tcl::object & row
    ) const {
      return( _linemap.get_marker_name( row ) );
    }

    /*! \return Returns the line containing the marker with the given name */
    Tcl::object get_marker_line(
      const Tcl::object & name
    ) const {
      return( _linemap.get_marker_line( name ) );
    }

    /*! Creates a new gutter column in the linemap gutter */
    void gutter_create(
      const Tcl::object & name,
      const Tcl::object & values
    ) {
      _linemap.create( name, values );
    }

    /*! Destroys the given gutter item */
    void gutter_destroy(
      const Tcl::object & name
    ) {
      _linemap.destroy( name );
    }

    /*!
     Causes a gutter to be hidden/shown or returns the current hidden state
     of the gutter.
    */
    bool gutter_hide(
      const Tcl::object & name,
      const Tcl::object & value
    ) {
      return( _linemap.hide( name, value ) );
    }

    /*! Deletes one or more symbols from the given buffer */
    void gutter_delete(
      const Tcl::object & name,
      const Tcl::object & syms
    ) {
      _linemap.delete_symbols( name, syms );
    }

    /*! Sets rows for a given gutter column to the specified values */
    void gutter_set(
      const Tcl::object & name,
      const Tcl::object & values
    ) {
      _linemap.set( name, values );
    }

    /*!
     Unsets a specific row (if last is the empty string) or a range of
     rows.
    */
    void gutter_unset(
      const Tcl::object & name,
      const Tcl::object & first,
      const Tcl::object & last
    ) {
      _linemap.unset( name, first, last );
    }

    /*! \return Returns the gutter line information */
    Tcl::object gutter_get(
      const Tcl::object & name,
      const Tcl::object & value,
      const Tcl::object & valueisint
    ) const {
      return( _linemap.get( name, value, valueisint ) );
    }

    /*! \return Returns the value of the gutter symbol option */
    Tcl::object gutter_cget(
      const Tcl::object & name,
      const Tcl::object & sym,
      const Tcl::object & opt
    ) const {
      return( _linemap.cget( name, sym, opt ) );
    }

    /*!
     Configures one or more gutter symbol options or returns the
     current values
    */
    Tcl::object gutter_configure(
      const Tcl::object & name,
      const Tcl::object & sym,
      const Tcl::object & opts
    ) {
      return( _linemap.configure( name, sym, opts ) );
    }

    /*! \return Returns a Tcl list of all stored gutter names */
    Tcl::object gutter_names() const {
      return( _linemap.names() );
    }

    /*! \return Returns commands to execute an undo operation */
    Tcl::object undo() {
      return( _undo_buffer.undo( _serial, _linemap ) );
    }

    /*! \return Returns commands to execute a redo operation */
    Tcl::object redo() {
      return( _undo_buffer.redo( _serial, _linemap ) );
    }

    /*! \return Returns true if an undo operation is possible */
    Tcl::object undoable() const {
      return( _undo_buffer.undoable() );
    }

    /*! \return Returns true if a redo operation is possible */
    Tcl::object redoable() const {
      return( _undo_buffer.redoable() );
    }

    /*! Adds an undo separator if you can be made. */
    void undo_separator() {
      _undo_buffer.add_separator();
    }

    /*! Resets the undo buffer */
    void undo_reset() {
      _undo_buffer.reset();
    }

    /*! Sets the auto-separate feature to the specified value */
    void auto_separate( const Tcl::object & value ) {
      _undo_buffer.auto_separate( value );
    }

    /*! \return Returns the full cursor history from the undo buffer */
    Tcl::object cursor_history() const {
      return( _undo_buffer.cursor_history() );
    }

    /*!
     Deletes the fold specified at the given line.

     \return Returns the text range to close the fold indicator.
    */
    Tcl::object fold_delete(
      const Tcl::object & line,
      const Tcl::object & depth
    ) {
      return( _linemap.fold_delete( line, depth ) );
    }

    Tcl::object fold_delete_range(
      const Tcl::object & startline,
      const Tcl::object & endline
    ) {
      return( _linemap.fold_delete_range( startline, endline ) );
    }

    /*!
     Opens all folds to the given depth, starting at the given startline.

     \return Returns the list of ranges to un-elide.
    */
    Tcl::object fold_open(
      const Tcl::object & startline,
      const Tcl::object & depth
    ) {
      return( _linemap.fold_open( startline, depth ) );
    }

    Tcl::object fold_open_range(
      const Tcl::object & startline,
      const Tcl::object & endline,
      const Tcl::object & depth
    ) {
      return( _linemap.fold_open_range( startline, endline, depth ) );
    }

    Tcl::object fold_show_line(
      const Tcl::object & line
    ) {
      return( _linemap.fold_show_line( line ) );
    }

    /*!
     Closes all folds to the given depth, starting at the given startline.

     \return Returns the list of ranges to elide.
    */
    Tcl::object fold_close(
      const Tcl::object & startline,
      const Tcl::object & depth
    ) {
      return( _linemap.fold_close( startline, depth ) );
    }

    Tcl::object fold_close_range(
      const Tcl::object & startline,
      const Tcl::object & endline,
      const Tcl::object & depth
    ) {
      return( _linemap.fold_close_range( startline, endline, depth ) );
    }

    Tcl::object fold_find(
      const Tcl::object & startline,
      const Tcl::object & dir,
      const Tcl::object & num
    ) {
      return( _linemap.fold_find( startline, dir, num ) );
    }

    void fold_indent_update(
      const Tcl::object & ranges
    ) {
      _linemap.fold_indent_update( ranges );
    }

    /*! Update the linemap with the fold information based on syntax */
    void fold_syntax_update() {
      _tree.add_folds( _linemap, _types );
    }

    /*! \return Returns the the starting line containing the given indent marker */
    Tcl::object indent_line_start(
      const Tcl::object & indent_index
    ) const;

    /*! \return Returns the number of characters to insert/delete at the beginning of the line. */
    Tcl::object indent_newline(
      const Tcl::object & prev_ti,
      const Tcl::object & first_ti,
      const Tcl::object & indent_space,
      const Tcl::object & shift_width
    ) const {
      return( _serial.indent_newline( prev_ti, first_ti, indent_space, shift_width, _types ) );
    }

    /*! \return Returns information used to handle an unindent */
    Tcl::object indent_check_unindent(
      const Tcl::object & first_ti,
      const Tcl::object & curr_ti
    ) const {
      return( _serial.indent_check_unindent( first_ti, curr_ti, _types ) );
    }

};

#endif

