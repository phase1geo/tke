#ifndef __LINEMAP_COL_H__
#define __LINEMAP_COL_H__

/*!
 \file     linemap_col.h
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/15/2017
 \brief    Contains class for handling a single gutter.
*/

#include <vector>
#include <map>
#include <iostream>

#include "cpptcl.h"
#include "linemap_colopts.h"

/*!
 Stores information for a single gutter column.
*/
class linemap_col {

  private:

    std::string                            _name;    /*!< Name of gutter */
    bool                                   _hidden;  /*!< Set to true if the gutter column should be hidden from view */
    std::map<std::string,linemap_colopts*> _opts;    /*!< Named symbol options */

  public:

    /*! Default constructor */
    linemap_col(
      const Tcl::object & name,
      const Tcl::object & opts
    );

    /*! Destructor */
    ~linemap_col();

    /*! \return Returns the name of the column */
    const std::string & name() const { return( _name ); }
    
    /*! \return Returns the list of symbols in the gutter */
    void symbols( std::vector<std::string> & syms ) const;

    /*! Set the hidden state of the given column */
    void hidden( bool value ) { _hidden = value; }

    /*! \return Returns the hidden state of the column */
    bool hidden() const { return( _hidden ); }

    /*! \return Returns the pointer to the colopts structure for the given value */
    const linemap_colopts* get_value( const std::string & value ) const;
    
    /*! Clears the given value from the list */
    void clear_value( const std::string & value );
    
    /*! \return Returns the value of the option for the given symbol */
    Tcl::object cget(
      const std::string & sym,
      const std::string & opt
    ) const;

    /*! Sets the symbol option to the given value */
    Tcl::object configure(
      const std::string & sym,
      const Tcl::object & opts
    );

};

#endif

