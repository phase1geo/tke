## Example

The following example code is taken right from the Tcl syntax file (data/syntax/Tcl.syntax).  It can give you an idea about how to create your own syntax file.  Feel free to also take a look at any of the other language syntax files in the directory as example code.  It is important to note that if a syntax highlight class is not needed, it does not not need to specified in the syntax file.

	filepatterns
	{*.tcl *.msg}
	
	vimsyntax
	{tcl}
	
	matchcharsallowed
	{curly square paren double}
	
	tabsallowed
	{0}
	
	casesensitive
	{1}
	
	indent
	{\{}
	  
	unindent
	{\}}
	
	icomment {{#}}
	
	lcomments {{^[ \t]*#} {;#}}
	
	strings {{"}}
	
	keywords
	{
	  after append apply array auto_execok auto_import auto_load auto_mkindex 
	  auto_mkindex_old auto_qualify auto_reset bgerror binary break catch cd chan clock 
	  close concat continue dde dict else elseif encoding eof error eval exec exit expr 
	  fblocked fconfigure fcopy file fileevent filename flush for foreach format gets glob global 
	  history http if incr info interp join lappend lassign lindex linsert list llength load lrange 
	  lrepeat lreplace levers lsearch lset lsort mathfunc mathop memory msgcat namespace 
	  open package parray pid pkg::create pkg_mkIndex platform platform::shell puts pwd 
	  read refchan regexp registry regsub rename return scan seek set socket source split 
	  string subst switch tcl_endOfWord tcl_findLibrary tcl_startOfNextWord 
	  tcl_startOfPreviousWord tcl_wordBreakAfter tcl_wordBreakBefore tcltest tell time tm 
	  trace unknown unload unset update uplevel upvar variable vwait while bind bindtags
	}
	
	symbols
	{
	  HighlightClass proc syntax::get_prefixed_symbol
	}
	
	numbers
	{
	  HighlightClassForRegexp {\m([0-9]+|[0-9]+\.[0-9]*|0x[0-9a-fA-F]+} {}
	}
	
	punctuation
	{
	  HighlightClassForRegexp {[][\{\}]} {}
	}
	
	miscellaneous1
	{
	  HighlightClass {
	ctext button label text frame toplevel scrollbar checkbutton canvas
	listbox menu menubar menubutton radiobutton scale entry message
	tk_chooseDirectory tk_getSaveFile tk_getOpenFile tk_chooseColor tk_optionMenu
	ttk::button ttk::checkbutton ttk::combobox ttk::entry ttk::frame ttk::label
	ttk::labelframe ttk::menubutton ttk::notebook ttk::panedwindow
	ttk::progressbar ttk::radiobutton ttk::scale ttk::scrollbar ttk::separator
	ttk::sizegrip ttk::treeview
	  } {}
	}
	
	miscellaneous2 {
	  HighlightClass {
	-text -command -yscrollcommand -xscrollcommand -background -foreground -fg
	-bg -highlightbackground -y -x -highlightcolor -relief -width -height -wrap
	-font -fill -side -outline -style -insertwidth  -textvariable -activebackground
	-activeforeground -insertbackground -anchor -orient -troughcolor -nonewline
	-expand -type -message -title -offset -in -after -yscroll -xscroll -forward
	-regexp -count -exact -padx -ipadx -filetypes -all -from -to -label -value
	-variable -regexp -backwards -forwards -bd -pady -ipady -state -row -column
	-cursor -highlightcolors -linemap -menu -tearoff -displayof -cursor -underline
	-tags -tag -weight -sticky -rowspan -columnspan
	  } {}
	}
	
	miscellaneous3 {
	  HighlightClassForRegexp {\m(\.[a-zA-Z0-9\_\-]+)+} {}
	  HighlightClassWithOnlyCharStart \$ {}
	}

Essentially this file is specifying the following about the Tcl language:

1. Any file that ends with .tcl or .msg should be parsed as a Tcl file.
2. If a Vim modeline is found with syntax=tcl, use this syntax highlighting information.
3. Auto-match curly brackets ( \{\} ), square brackets ( [] ), parenthesis ( () ) and double-quotes ( “” ).
4. Tab characters should not be used for indentation.
5. Use case sensitive matching for parsing purposes.
6. Whenever an open curly bracket is found, increase the indentation level, and whenever a closing curly bracket is found, decrease the indentation level.
7. Insert line comments with the HASH (#) character.
8. All comments start with the HASH (#) character.
9. All strings start and end with the QUOTE (“) character.
10. Apply keyword coloring to the list of keywords (ex., “after”, “bindtags”, “uplevel”, etc.)
11. Whenever a “proc” keyword is found, use the name of the proc as a searchable symbol in the file.
12. Highlight any integer values as numbers.
13. Highlight the ], [, \{, \}  characters as punctuation
14. There are no precompiler syntax to be colored.
15. Highlight Tk keywords in a different color than Tcl keywords.
16. Highlight Tcl/Tk option values in a different color than normal Tcl keywords.
17. Highlight Tk window pathnames in the miscellaneous3 color.
18. Highlight variables in the miscellaneous3 color.