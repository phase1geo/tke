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
                  data.at( interp, 1 ).get<std::string>( interp ) );
    }

    /*! Called when text is going to be inserted.  Adjusts the indices accordingly. */
    void insert(
      const Tcl::object & args
    ) {
      Tcl::interpreter    interp( args.get_interp(), false );
      std::vector<tindex> vec;
      object_to_ranges( args.at( interp, 0 ), vec );
      _serial.insert( vec );
      _linemap.insert( vec );
      if( _edited ) {
        _undo_buffer.add_insertion( vec, args.at( interp, 1 ), args.at( interp, 2 ) );
      }
      _edited = true;
    }

    /*! Called when text is going to be inserted.  Adjusts the indices accordingly. */
    void insertlist(
      const Tcl::object & args
    ) {
      Tcl::interpreter    interp( args.get_interp(), false );
      std::vector<tindex> vec;
      object_to_ranges( args.at( interp, 0 ), vec );
      _serial.insert( vec );
      _linemap.insert( vec );
      if( _edited ) {
        _undo_buffer.add_insertion_list( vec, args.at( interp, 1 ), args.at( interp, 2 ) );
      }
      _edited = true;
    }

    /*! Called when text is going to be deleted.  Adjusts the indices accordingly. */
    Tcl::object remove(
      const Tcl::object & args
    ) {
      Tcl::interpreter    interp( args.get_interp(), false );
      std::vector<tindex> vec;
      Tcl::object         result;
      object_to_ranges( args.at( interp, 0 ), vec );
      _serial.remove( vec );
      result = _linemap.remove( vec );
      if( _edited ) {
        _undo_buffer.add_deletion( vec, args.at( interp, 1 ), args.at( interp, 2 ) );
      }
      _edited = true;
      return( result );
    }

    /*! Called when text is going to be replaced.  Adjusts the indices accordingly. */
    Tcl::object replace(
      const Tcl::object & args
    ) {
      Tcl::interpreter    interp( args.get_interp(), false );
      std::vector<tindex> vec;
      Tcl::object         result;
      object_to_ranges( args.at( interp, 0 ), vec );
      _serial.replace( vec );
      result = _linemap.replace( vec );
      if( _edited ) {
        _undo_buffer.add_replacement( vec, args.at( interp, 1 ), args.at( interp, 2 ), args.at( interp, 3 ) );
      }
      _edited = true;
      return( result );
    }

    /*! Updates the model with the given tag information */
    bool update(
      const Tcl::object & args
    );

    /*! Update the tree with the contents of the serial list */
    void update_tree() {
      _tree.update( _serial, _types );
      _tree.add_folds( _linemap, _types );
    }

    /*! \return Returns a human-readable representation of the stored serial list */
    std::string show_serial() const { return( _serial.show( _types ) ); }

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
      const Tcl::object & args
    );

    /*!
     Handles rendering all of the contexts in the given list as well
     as what is stored in the model.
    */
    Tcl::object render_contexts(
      const Tcl::object & args
    );

    /*! \return Returns true if the given text index is immediately preceded by an escape */
    bool is_escaped(
      const Tcl::object & ti
    ) const;

    /*! \return Returns true if the given text index contains the given type */
    Tcl::object is_index(
      const Tcl::object & args
    ) const;

    /*! \return Returns comment marker positions in a Tcl list */
    Tcl::object get_comment_markers(
      const Tcl::object & ranges
    ) const {
      return( _serial.get_comment_markers( ranges, _types ) );
    }

    /*! \return Returns a list of ranges that match the input criteria */
    Tcl::object get_range(
      const Tcl::object & args
    ) const {
      Tcl::interpreter i( args.get_interp(), false );
      return( _serial.get_range( args.at( i, 0 ), args.at( i, 1 ), args.at( i, 2 ), args.at( i, 3 ), args.at( i, 4 ), _types ) );
    }

    /*!
     Handles rendering the currently viewable linemap.
    */
    Tcl::object render_linemap(
      const Tcl::object & args
    ) const {
      Tcl::interpreter i( args.get_interp(), false );
      return( _linemap.render( args.at( i, 0 ), args.at( i, 1 ) ) );
    }

    /*! Adds a marker to the linemap with the given name for the given line */
    void set_marker(
      const Tcl::object & args
    ) {
      Tcl::interpreter i( args.get_interp(), false );
      _linemap.set_marker( args.at( i, 0 ), args.at( i, 1 ) );
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
      const Tcl::object & args
    ) {
      Tcl::interpreter interp( args.get_interp(), false );
      _linemap.create( args.at( interp, 0 ), args.at( interp, 1 ) );
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
      const Tcl::object & args
    ) {
      Tcl::interpreter interp( args.get_interp(), false );
      return( _linemap.hide( args.at( interp, 0 ), args.at( interp, 1 ) ) );
    }

    /*! Deletes one or more symbols from the given buffer */
    void gutter_delete(
      const Tcl::object & args
    ) {
      Tcl::interpreter interp( args.get_interp(), false );
      _linemap.delete_symbols( args.at( interp, 0 ), args.at( interp, 1 ) );
    }

    /*! Sets rows for a given gutter column to the specified values */
    void gutter_set(
      const Tcl::object & args
    ) {
      Tcl::interpreter interp( args.get_interp(), false );
      _linemap.set( args.at( interp, 0 ), args.at( interp, 1 ) );
    }

    /*!
     Unsets a specific row (if last is the empty string) or a range of
     rows.
    */
    void gutter_unset(
      const Tcl::object & args
    ) {
      Tcl::interpreter interp( args.get_interp(), false );
      _linemap.unset( args.at( interp, 0 ), args.at( interp, 1 ), args.at( interp, 2 ) );
    }

    /*! \return Returns the gutter line information */
    Tcl::object gutter_get(
      const Tcl::object & args
    ) const {
      Tcl::interpreter interp( args.get_interp(), false );
      return( _linemap.get( args.at( interp, 0 ), args.at( interp, 1 ), args.at( interp, 2 ) ) );
    }

    /*! \return Returns the value of the gutter symbol option */
    Tcl::object gutter_cget(
      const Tcl::object & args
    ) const {
      Tcl::interpreter interp( args.get_interp(), false );
      return( _linemap.cget( args.at( interp, 0 ), args.at( interp, 1 ), args.at( interp, 2 ) ) );
    }

    /*!
     Configures one or more gutter symbol options or returns the
     current values
    */
    Tcl::object gutter_configure(
      const Tcl::object & args
    ) {
      Tcl::interpreter interp( args.get_interp(), false );
      return( _linemap.configure( args.at( interp, 0 ), args.at( interp, 1 ), args.at( interp, 2 ) ) );
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
      const Tcl::object & args
    ) {
      Tcl::interpreter interp( args.get_interp(), false );
      return( _linemap.fold_delete( args.at( interp, 0 ), args.at( interp, 1 ) ) );
    }

    Tcl::object fold_delete_range(
      const Tcl::object & args
    ) {
      Tcl::interpreter interp( args.get_interp(), false );
      return( _linemap.fold_delete_range( args.at( interp, 0 ), args.at( interp, 1 ) ) );
    }

    /*!
     Opens all folds to the given depth, starting at the given startline.

     \return Returns the list of ranges to un-elide.
    */
    Tcl::object fold_open(
      const Tcl::object & args
    ) {
      Tcl::interpreter interp( args.get_interp(), false );
      return( _linemap.fold_open( args.at( interp, 0 ), args.at( interp, 1 ) ) );
    }

    Tcl::object fold_open_range(
      const Tcl::object & args
    ) {
      Tcl::interpreter interp( args.get_interp(), false );
      return( _linemap.fold_open_range( args.at( interp, 0 ), args.at( interp, 1 ), args.at( interp, 2 ) ) );
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
      const Tcl::object & args
    ) {
      Tcl::interpreter interp( args.get_interp(), false );
      return( _linemap.fold_close( args.at( interp, 0 ), args.at( interp, 1 ) ) );
    }

    Tcl::object fold_close_range(
      const Tcl::object & args
    ) {
      Tcl::interpreter interp( args.get_interp(), false );
      return( _linemap.fold_close_range( args.at( interp, 0 ), args.at( interp, 1 ), args.at( interp, 2 ) ) );
    }

    Tcl::object fold_find(
      const Tcl::object & args
    ) {
      Tcl::interpreter interp( args.get_interp(), false );
      return( _linemap.fold_find( args.at( interp, 0 ), args.at( interp, 1 ), args.at( interp, 2 ) ) );
    }

    void fold_indent_update() {
      std::vector<tindex> firstchars;
      _serial.get_all_firstchars( firstchars, _types );
      _linemap.fold_indent_update( firstchars );
    }

    /*! Update the linemap with the fold information based on syntax */
    void fold_syntax_update() {
      _tree.add_folds( _linemap, _types );
    }

    /*! Returns the index of the first non-whitespace character found on the line containing index */
    Tcl::object get_firstchar(
      const Tcl::object & index
    ) const {
      return( _serial.get_firstchar( index, _types ) );
    }

    /*! \return Returns the the starting line containing the given indent marker */
    Tcl::object indent_line_start(
      const Tcl::object & indent_index
    ) const;

    /*! \return Returns the number of spaces found before the previous, non-empty line */
    Tcl::object indent_get_previous(
      const Tcl::object & index
    ) const {
      return( _serial.indent_get_previous( index, _types ) );
    }

    /*! \return Returns the number of spaces that exist prior to the given index. */
    Tcl::object indent_backspace(
      const Tcl::object & index
    ) const {
      return( _serial.indent_backspace( index, _types ) );
    }

    /*! \return Returns the number of characters to insert/delete at the beginning of the line. */
    Tcl::object indent_newline(
      const Tcl::object & args
    ) const {
      Tcl::interpreter interp( args.get_interp(), false );
      return( _serial.indent_newline( args.at( interp, 0 ), args.at( interp, 1 ), _types ) );
    }

    /*! \return Returns information used to handle an unindent */
    Tcl::object indent_check_unindent(
      const Tcl::object & args
    ) const {
      Tcl::interpreter interp( args.get_interp(), false );
      return( _serial.indent_check_unindent( args.at( interp, 0 ), args.at( interp, 1 ), _types ) );
    }

    /*! \return Returns a list used by the indent formatting code */
    Tcl::object indent_format(
      const Tcl::object & args
    ) const {
      Tcl::interpreter interp( args.get_interp(), false );
      return( _serial.indent_format( args.at( interp, 0 ), args.at( interp, 1 ), args.at( interp, 2 ), _types ) );
    }

};

#endif

