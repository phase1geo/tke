#ifndef __LINEMAP_COLOPTS_H__
#define __LINEMAP_COLOPTS_H__

/*!
 \file     linemap_colopts.h
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/15/2017
 \brief    Contains class which stores column (gutter) options.
*/

#include <string>
#include <map>
#include <iostream>

#include "cpptcl.h"

/*!
 Stores the gutter column options.
*/
class linemap_colopts {

  private:

    std::string                       _symbol;
    std::string                       _color;
    std::map<std::string,std::string> _bindings;

  public:

    /*! Default constructor */
    linemap_colopts() : _symbol( "" ), _color( "" ) {}

    /*! Constructor */
    linemap_colopts( Tcl::object opts );

    /*! Destructor */
    ~linemap_colopts() {}

    /*! Configures the structure with the given options */
    void configure( Tcl::object opts );

    /*! \return Returns a Tcl list containing all of the option value pairs */
    Tcl::object configure() const;

    /*! \return Returns the stored value for the given option name */
    Tcl::object cget( const std::string & opt ) const;

    /*! \return Returns a rendered version of this instance */
    Tcl::object render( Tcl::interpreter & interp ) const;

    /*! \return Returns the stored symbol value */
    const std::string & symbol() const { return( _symbol ); }

};

#endif

