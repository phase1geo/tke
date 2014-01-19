#===============================================================
# Main tokensearch package module
#
# Copyright (c) 2011-2012  Trevor Williams (phase1geo@gmail.com)
#===============================================================

package provide tokensearch 1.2

source [file join [tokensearch::DIR] common tokenframe.tcl]

namespace eval tokensearch {

  array set token_index      {}
  array set active_token     {}
  array set options          {}
  array set dont_tokenize    {}
  array set old_focus        {}
  array set old_grab         {}
  array set dropdown_token   {}
  array set images           {}
  array set pressed_token    {}
  array set token_count      {}
  array set token_shapes     {}
  array set categoryopt_vars {}
  array set edit_info        {}
  array set dont_deselect    {}
  array set state            {}
  array set tags             {}

  array set text_options {
    -background          1
    -bg                  1
    -borderwidth         1
    -bd                  1
    -exportselection     1
    -font                1
    -foreground          1
    -fg                  1
    -highlightbackground 1
    -highlightcolor      1
    -highlightthickness  1
    -insertbackground    1
    -insertborderwidth   1
    -insertofftime       1
    -insertontime        1
    -insertwidth         1
    -padx                1
    -pady                1
    -relief              1
    -selectbackground    1
    -selectborderwidth   1
    -selectforeground    1
    -setgrid             1
    -state               1
    -takefocus           1
    -xscrollcommand      1
    -yscrollcommand      1
    -autoseparators      1
  }
  
  array set widget_options {
    -autoseparators         {autoSeparators         AutoSeparators}
    -background             {background             Background}
    -bg                     -background
    -borderwidth            {borderWidth            BorderWidth}
    -bd                     -borderwidth
    -categories             {categories             Categories}
    -categorybd             {categoryBorderWidth    CategoryBorderWidth}
    -categorybg             {categoryBackground     CategoryBackground}
    -categorycursor         {categoryCursor         Cursor}
    -categoryfont           {categoryFont           CategoryFont}
    -categoryopts           {categoryOpts           CategoryOpts}
    -categoryrelief         {categoryRelief         CategoryRelief}
    -dropdownheight         {dropDownHeight         DropDownHeight}
    -dropdownmaxheight      {dropDownMaxHeight      DropDownMaxHeight}
    -exportselection        {exportSelection        ExportSelection}
    -font                   {font                   Font}
    -foreground             {foreground             Foreground}
    -fg                     -foreground
    -height                 {height                 Height}
    -highlightbackground    {highlightBackground    HighlightBackground}
    -highlightcolor         {highlightColor         HighlightColor}
    -highlightthickness     {highlightThickness     HighlightThickness}
    -historyvar             {historyVar             HistoryVar}
    -insertbackground       {insertBackground       InsertBackground}
    -insertborderwidth      {insertBorderWidth      InsertBorderWidth}
    -insertofftime          {insertOffTime          InsertOffTime}
    -insertontime           {insertOnTime           InsertOnTime}
    -insertwidth            {insertWidth            InsertWidth}
    -matchcase              {matchCase              MatchCase}
    -matchmode              {matchMode              MatchMode}
    -padx                   {padX                   Pad}
    -pady                   {padY                   Pad}
    -relief                 {relief                 Relief}
    -selectbackground       {selectBackground       Background}
    -selectborderwidth      {selectBorderWidth      BorderWidth}
    -selectforeground       {selectForeground       Foreground}
    -setgrid                {setGrid                SetGrid}
    -state                  {state                  State}
    -takefocus              {takeFocus              TakeFocus}
    -tokenbg                {tokenBackground        TokenBackground}
    -tokenbordercolor       {tokenBorderColor       TokenBorderColor}
    -tokenfg                {tokenForeground        TokenForeground}
    -tokenselectbg          {tokenSelectBackground  TokenSelectBackground}
    -tokenselectbordercolor {tokenSelectBorderColor TokenSelectBorderColor}
    -tokenselectfg          {tokenSelectForeground  TokenSelectForeground}
    -tokenshape             {tokenShape             TokenShape}
    -tokenvar               {tokenVar               TokenVar}
    -watermark              {watermark              Watermark}
    -watermarkforeground    {watermarkForeground    Foreground}
    -width                  {width                  Width}
    -wrap                   {wrap                   Wrap}
    -xscrollcommand         {xScrollCommand         ScrollCommand}
    -yscrollcommand         {yScrollCommand         ScrollCommand}
  }

  variable img_arrow
  variable img_blank

  set img_arrow [image create photo -data "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"]
  set img_blank [image create photo -data "R0lGODlhBwAHAIAAAP///wAAACH5BAkKAAEAIf8 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"]

  ###########################################################################
  # Main procedure which creates the given window and initializes it.
  proc tokensearch {w args} {

    variable token_index
    variable options
    variable dont_tokenize
    variable dont_deselect
    variable active_token
    variable pressed_token
    variable token_count
    variable widget_options
    variable dropdown_token
    variable state
    variable tags

    # Create the widget frame
    frame $w -class TokenSearch -takefocus 0
    
    # Initially, we pack the frame with an entry widget
    text $w.txt -highlightthickness 0 -relief flat -bg white -spacing1 2 -spacing2 2 -spacing3 2 -takefocus 1
    
    # Pack the text widget
    pack $w.txt -side left -fill both -expand yes
    
    # Create the category menu
    menu $w.mnu -tearoff 0

    # Create the popup window that might be used by this widget
    toplevel  $w.top
    listbox   $w.top.list -selectmode browse -background white -yscrollcommand "$w.top.vsb set" -exportselection 0 -borderwidth 0 -cursor top_left_arrow
    ttk::scrollbar $w.top.vsb -command "$w.top.list yview"

    pack $w.top.list -side left -fill both -expand y

    # Handle the popup
    wm overrideredirect $w.top 1
    wm transient        $w.top [winfo toplevel $w]
    wm group            $w.top [winfo parent $w]
    wm withdraw         $w.top

    # Initialize default options
    if {[array size token_index] == 0} {
      foreach opt [array names widget_options] {
        if {![catch "$w.txt configure $opt" rc]} {
          if {[llength $widget_options($opt)] != 1} {
            if {$opt eq "-wrap"} {
              set default_value 0
            } elseif {$opt eq "-height"} {
              set default_value 1
            } elseif {$opt eq "-background"} {
              set default_value "white"
            } elseif {$opt eq "-relief"} {
              set default_value "ridge"
            } else {
              set default_value [lindex $rc 4]
            }
            option add *TokenSearch.[lindex $rc 1] $default_value widgetDefault
          }
        }
      }
      option add *TokenSearch.tokenForeground        [list "white"     "black"]      widgetDefault
      option add *TokenSearch.tokenBackground        [list "dark blue" "light blue"] widgetDefault
      option add *TokenSearch.tokenBorderColor       [list "dark blue" "light blue"] widgetDefault
      option add *TokenSearch.tokenSelectForeground  "white"                         widgetDefault
      option add *TokenSearch.tokenSelectBackground  "blue"                          widgetDefault
      option add *TokenSearch.tokenSelectBorderColor "blue"                          widgetDefault
      option add *TokenSearch.dropDownHeight         0                               widgetDefault
      option add *TokenSearch.dropDownMaxHeight      5                               widgetDefault
      option add *TokenSearch.matchMode              glob                            widgetDefault
      option add *TokenSearch.matchCase              0                               widgetDefault
      option add *TokenSearch.historyVar             ""                              widgetDefault
      option add *TokenSearch.tokenVar               ""                              widgetDefault
      option add *TokenSearch.tokenShape             pill                            widgetDefault
      option add *TokenSearch.dropDownFormatString   "%s"                            widgetDefault
      option add *TokenSearch.categories             [list {Categories Name}]        widgetDefault
      option add *TokenSearch.categoryBackground     white                           widgetDefault
      option add *TokenSearch.categoryRelief         groove                          widgetDefault
      option add *TokenSearch.categoryBorderWidth    1                               widgetDefault
      option add *TokenSearch.categoryFont           [font create -size 8]           widgetDefault
      option add *TokenSearch.categoryCursor         ""                              widgetDefault
      option add *TokenSearch.watermark              ""                              widgetDefault
      option add *TokenSearch.watermarkForeground    "light gray"                    widgetDefault
    }
 
    # Initialize variables
    set token_index($w)    0
    set active_token($w)   ""
    set dont_tokenize($w)  0
    set dropdown_token($w) ""
    set pressed_token($w)  ""
    set token_count($w)    0
    set dont_deselect($w)  0
    set state($w)          "unknown"
    set tags($w,entry)     "entry$w"
    set tags($w,list)      "list$w"

    # Initialize the options array
    foreach opt [array names widget_options] {
      set options($w,$opt) [option get $w [lindex $widget_options($opt) 0] [lindex $widget_options($opt) 1]]
    }
    
    # Set the bindtags for the text and listbox widgets
    bindtags $w.txt      [linsert [bindtags $w.txt]      1 $tags($w,entry) TokenSearchEntry]
    bindtags $w.top.list [linsert [bindtags $w.top.list] 1 $tags($w,list)  TokenSearchList]

    # Setup bindings
    if {[llength [bind TokenSearchEntry]] == 0} {
    
      bind $w <FocusIn>                     {
        tokensearch::focus_in %W
      }
      bind TokenSearchEntry <FocusOut>      {
        set tokensearch::dont_tokenize([winfo parent %W]) 0
        tokensearch::tokenize [winfo parent %W]
      }
      bind TokenSearchEntry <Return>        {
        tokensearch::key_return [winfo parent %W]
        break
      }
      bind TokenSearchEntry <Tab>           {
        tokensearch::focus_next [winfo parent %W]
        break
      }
      bind TokenSearchEntry <Left>          {
        tokensearch::key_left_right [winfo parent %W] left
        if {[tokensearch::handle_text_movement [winfo parent %W]]} {
          break
        }
      }
      bind TokenSearchEntry <Right>         {
        tokensearch::key_left_right [winfo parent %W] right
        if {[tokensearch::handle_text_movement [winfo parent %W]]} {
          break
        }
      }
      bind TokenSearchEntry <Down>          {
        tokensearch::key_down [winfo parent %W]
        if {[tokensearch::handle_text_movement [winfo parent %W]]} {
          break
        }
      }
      bind TokenSearchEntry <Up>            {
        tokensearch::key_up [winfo parent %W]
        if {[tokensearch::handle_text_movement [winfo parent %W]]} {
          break
        }
      }
      bind TokenSearchEntry <Escape>        {
        tokensearch::close_dropdown [winfo parent %W]
      }
      bind TokenSearchEntry <Button-1>      {
        tokensearch::close_dropdown [winfo parent %W]
        if {[tokensearch::handle_text_movement [winfo parent %W]]} {
          break
        }
      }
      bind TokenSearchEntry <B1-Motion>     {
        if {[tokensearch::handle_text_movement [winfo parent %W]]} {
          break
        }
      }
      bind TokenSearchEntry <B1-Leave>      {
        if {[tokensearch::handle_text_movement [winfo parent %W]]} {
          break
        }
      }
      bind TokenSearchEntry <Any-KeyPress>  {
        tokensearch::keypress [winfo parent %W]
      }
      bind TokenSearchList  <Motion>        {
        tokensearch::motion_dropdown [winfo parent [winfo parent %W]] %x %y
      }
      bind TokenSearchList  <Button-1>      {
        tokensearch::key_return [winfo parent [winfo parent %W]]
        focus [winfo parent [winfo parent %W]].txt
      }
      bind TokenSearchEntry <<Modified>>    {
        tokensearch::modified [winfo parent %W]
      }
      bind TokenSearchEntry <<Selection>>   {
        tokensearch::handle_selection_change [winfo parent %W]
      }
      bind TokenSearchEntry <<PasteSelection>> {
        if {[tokensearch::paste_selection [winfo parent %W]]} {
          break
        }
      }
      bind TokenSearchEntry <Destroy>       {
        tokensearch::handle_destroy [winfo parent %W]
      }
      if {[tk windowingsystem] eq "aqua"} {
        bind TokenSearchEntry <Command-x> {
          tokensearch::handle_cut [winfo parent %W]
          break
        }
        bind TokenSearchEntry <Command-c> {
          tokensearch::handle_copy [winfo parent %W]
          break
        }
        bind TokenSearchEntry <Command-v> {
          tokensearch::handle_paste [winfo parent %W]
          break
        }
      } else {
        bind TokenSearchEntry <Control-x> {
          tokensearch::handle_cut [winfo parent %W]
          break
        }
        bind TokenSearchEntry <Control-c> {
          tokensearch::handle_copy [winfo parent %W]
          break
        }
        bind TokenSearchEntry <Control-v> {
          tokensearch::handle_paste [winfo parent %W]
          break
        }
      }

    }
    
    # Configure the widget
    eval "configure 1 $w $args"

    # Rename and alias the tokensearch window
    rename ::$w $w
    interp alias {} ::$w {} tokensearch::widget_cmd $w

    return $w

  }

  ###########################################################################
  # This procedure is called when the widget is destroyed.
  proc handle_destroy {w} {

    variable images
    variable token_index
    variable active_token
    variable dont_tokenize
    variable dropdown_token
    variable pressed_token
    variable token_count
    variable dont_deselect
    variable state
    variable tags

    # Delete the images
    foreach {key value} [array get images $w,*] {
      image delete $value
    }
    
    # Delete the image array
    array unset images $w,*

    # Unset used variables
    unset token_index($w)
    unset active_token($w)
    unset dont_tokenize($w)
    unset dropdown_token($w)
    unset pressed_token($w)
    unset token_count($w)
    unset dont_deselect($w)
    unset state($w)
    unset tags($w,entry)
    unset tags($w,list)

  }

  ###########################################################################
  # Handles a FocusIn event on the top-level frame.
  proc focus_in {w} {

    variable state
    
    # If the widget is disabled, don't continue
    if {$state($w) eq "disabled"} {
      return
    }
    
    # Set the focus to the text field
    focus $w.txt

  }

  ###########################################################################
  # Changes focus to the next window after w.
  proc focus_next {w} {

    # Change the focus
    focus [tk_focusNext $w.txt]

  }

  ###########################################################################
  # This procedure is called when the text widget is modified.
  proc modified {w} {

    variable token_count
    variable options
    variable state
    
    if {[$w.txt edit modified]} {

      set last_value [$w.txt get {insert - 1 chars} insert]
      
      if {($last_value eq "\n") || ($last_value eq "\t")} {
        $w.txt delete {insert - 1 chars} insert
        handle_state $w 1
      }

      # Reset the modified flag
      $w.txt edit modified false

      # Generate the TokenSearchModified event if our token count has changed
      set tokens [llength [$w.txt window names]]
      if {$token_count($w) != $tokens} {
        set token_count($w) $tokens
        if {$options($w,-tokenvar) ne ""} {
          upvar #0 $options($w,-tokenvar) var
          set var [get_tokens $w]
        }
        event generate $w <<TokenSearchModified>>
      }

    }

  }

  ###########################################################################
  # If the selection of the text box changes, make sure that any selected
  # tokens are updated appropriately.
  proc handle_selection_change {w} {
    
    # Don't allow the selection to contain tokens
    foreach token [$w.txt window names] {
      if {[lsearch [$w.txt tag names $token] sel] != -1} {
        $w.txt tag remove sel $token
      }
    }
    
  }

  ###########################################################################
  # This procedure is called whenever the user performs a paste selection event
  # on the widget.
  proc paste_selection {w} {
    
    if {[catch "tk::GetSelection $w PRIMARY"]} {
      return 1
    } else {
      handle_state $w 1      
    }
    
    return 0
    
  }
  
  ###########################################################################
  # Validation command.
  proc validate {w str} {

    variable options

    if {$str eq ","} {
      return 0
    } elseif {$options($w,-validatecommand) ne ""} {
      return [eval $options($w,-validatecommand) $str]
    } else {
      return 1
    }

  }

  ###########################################################################
  # Handles a left or right arrow key event.
  proc key_left_right {w dir {token ""}} {
  
    variable options
    variable active_token
    
    if {$token eq ""} {
    
      # Don't do anything if the current insertion cursor is the beginning or end
      if {(([$w.txt index insert] ne "1.0") || ($dir eq "right")) && \
          (([$w.txt index insert] ne [$w.txt index end]) || ($dir eq "left"))} {
    
        # Get the current insertion index
        if {$dir eq "left"} {
          set index [$w.txt index "insert - 1 chars"]
        } else {
          set index [$w.txt index insert]
        }
      
        # If a token exists at the given index, select it.
        foreach token [$w.txt window names] {
          if {[$w.txt index $token] eq $index} {
            reverse_token $w $token
            set active_token($w) $index
            focus $token
            return
          }
        }
        
      }
      
    } else {
    
      # Clear the active token
      set active_token($w) ""
      
      # Deselect the token
      reverse_token $w $token
      
      # Close the dropdown listbox if it is opened
      close_dropdown $w
      
      # If the direction was a positive direction, increase the insertion cursor by one character
      if {($dir eq "right") && ([$w.txt index $token] eq [$w.txt index insert])} {
        $w.txt mark set insert "insert + 1 chars"
      }
      
      # Get the text entry field the focus
      focus $w.txt
      
    }
    
  }

  ###########################################################################
  # This procedure is invoked when the user hits the down key when the text
  # has the focus.
  proc key_down {w {token ""}} {

    if {[winfo ismapped $w.top]} {
      tk::ListboxUpDown $w.top.list 1
      return -code break
    } elseif {$token ne ""} {
      display_category_menu $w $token
    }

  }
  
  ###########################################################################
  # This procedure is invoked when the user hits the shift-down key combination
  # when the token has the focus.  This invokes the history drop-down.
  proc key_shift_down {w token} {
  
    # Dislay the dropdown item list
    display_dropdown_items $w $token
    
  }

  ###########################################################################
  # This procedure is invoked when the user hits the up key when the text
  # has the focus.
  proc key_up {w {token ""}} {

    if {[winfo ismapped $w.top]} {
      tk::ListboxUpDown $w.top.list -1
      return -code break
    } elseif {$token ne ""} {
      close_dropdown $w
    }

  }

  ###########################################################################
  # This procedure is invoked when the user hits the return key when the
  # text has the focus.
  proc key_return {w {token ""}} {

    variable dropdown_token
    variable options
    variable dont_tokenize

    # Allow the tokenization to occur
    set dont_tokenize($w) 0

    # If the dropdown window is shown, get the currently selected text and insert it into the textbox.
    if {[winfo ismapped $w.top]} {

      # Get the currently selected value
      set value [$w.top.list get [$w.top.list curselection]]

      # Figure out the position of the first character of text
      set curr_index 1.0
      set end_index  [$w.txt index end]
      while {($curr_index != $end_index) && ([$w.txt get $curr_index] eq "")} {
        set curr_index [$w.txt index "$curr_index + 1 chars"]
      }

      # If the result is associated with a token, change the token text
      if {$dropdown_token($w) ne ""} {
        $dropdown_token($w).val.l1 configure -text $value
        redraw_token $w $dropdown_token($w) 1
        if {$options($w,-tokenvar) ne ""} {
          upvar #0 $options($w,-tokenvar) var
          set var [get_tokens $w]
        }
        event generate $w <<TokenSearchModified>>

      # Otherwise, remove the current text and replace it with the given value
      } else {
        $w.txt delete $curr_index "$curr_index + [expr [string length $value] + 1] chars"
        $w.txt insert $curr_index $value
        tokenize $w
      }

      # Close the dropbox
      close_dropdown $w

    # If this return was hit for a token, detokenize the current token to make it editable
    } elseif {$token ne ""} {
    
      detokenize $w $token
      
    } else {

      # Tokenize the text
      tokenize $w

    }

  }

  ###########################################################################
  # This procedure is called whenever the escape key is pressed when a token
  # has the focus.  This will cause the dropdown listbox to be closed if
  # it is currently opened.
  proc key_escape {w token} {
  
    # Just close the dropdown listbox
    close_dropdown $w
    
  }

  ###########################################################################
  # This procedure is called whenever the user presses a key in the text box.
  proc keypress {w} {
  
    # Update the current state
    handle_state $w 1

    after idle [list tokensearch::handle_entry_key $w]

    # Clear the listbox selection so that it's obvious what will happen if the user
    # presses return.
    $w.top.list see 0
    $w.top.list selection clear 0 end
    $w.top.list selection anchor 0
    $w.top.list activate 0

  }

  ###########################################################################
  # Populates and shows the listbox with the matching values.  If there are no
  # matching values, the listbox is closed.
  proc handle_entry_key {w} {

    variable options
    variable dont_tokenize
    
    # Handle the current state
    handle_state $w 1

    # Make sure that we don't tokenize
    set dont_tokenize($w) 1

    # Get rid of any whitespace from around the value
    set value [string trim [$w.txt get 1.0 end]]

    # Clear the listbox
    $w.top.list delete 0 end

    # Populate the listbox with matching values
    if {$value ne ""} {
      if {$options($w,-historyvar) ne ""} {
        upvar #0 $options($w,-historyvar) history
        set cmdargs [list]
        switch $options($w,-matchmode) {
          glob {
            lappend cmdargs "-glob"
            set matchval "*$value*"
          }
          regexp {
            lappend cmdargs "-regexp"
            set matchval ".*$value.*"
          }
          default {
            lappend cmdargs "-glob"
            set matchval "*$value*"
          }
        }
        if {!$options($w,-matchcase)} {
          lappend cmdargs "-nocase"
        }
        lappend cmdargs "-all" "-inline"
        foreach value [eval "lsearch $cmdargs {$history} {$matchval}"] {
          $w.top.list insert end $value
        }
      }
    }

    # If the listbox is not empty, show it
    if {[$w.top.list size] > 0} {
      open_dropdown $w
      $w.top.list activate 0
      $w.top.list selection set 0

    } else {
      close_dropdown $w
    }

  }

  ###########################################################################
  # Handles any sort of movement of the insertion cursor or selection within
  # the text widget.
  proc handle_text_movement {w} {
  
    variable state
    
    # If we are empty, always set the insertion cursor to 1.0
    if {$state($w) eq "empty"} {
      $w.txt mark set insert 1.0
      $w.txt tag remove sel 1.0 end
      focus $w.txt
      return 1
    }
    
    return 0
    
  }
  
  ###########################################################################
  # Handles a Control-x binding on the given widget.
  proc handle_cut {w} {

    if {[focus] eq $w} {
      set select [$w.txt tag ranges sel]
      if {[llength $select] == 0} {
        clipboard clear
        clipboard append [$w.txt get 1.0 end]
        # TBD - Need to delete only text
        eval "$w.txt delete 1.0 end"
        handle_state $w 1
      } else {
        clipboard clear
        clipboard append [eval "$w.txt get $select"]
        eval "$w.txt delete $select"
        handle_state $w 1
      }
    } else {
      clipboard clear
      clipboard append [[focus].l1 cget -text]
      eval "tokendelete $w $select"
    }

  }

  ###########################################################################
  # Handles a Control-c binding on the given widget.
  proc handle_copy {w} {
  
    if {[focus] eq $w} {
      set select [$w.txt tag ranges sel]
      if {[llength $select] == 0} {
        clipboard clear
        clipboard append [$w.txt get 1.0 end]
      } else {
        clipboard clear
        clipboard append [eval "$w.txt get $select"]
      }
    } else {
      clipboard clear
      clipboard append [[focus].l1 cget -text]
    }
  
  }
  
  ###########################################################################
  # Handles a Control-v binding on the given widget.
  proc handle_paste {w} {
  
    # Handle the current state
    handle_state $w 1
  
    # Insert the clipboard text
    $w.txt insert insert [clipboard get]

    # Close the drop-down listbox
    close_dropdown $w

  }

  ###########################################################################
  # Redraws the given token.
  proc redraw_token {w token resize} {

    variable options
    variable images
    variable token_shapes

    # Get the border color from the token
    set cat_usebc [$token.cat.l2.top cget -bg]
    set val_usebc [$token.val.l2.top cget -bg]
    set txt_bg    [$w.txt cget -background]

    # Figure out the width and height of the token text label
    if {$resize} {
      update idletasks
    }
    set l1_cat_width [winfo reqwidth  $token.cat.l1]
    set l1_val_width [winfo reqwidth  $token.val.l1]
    set l1_height    [winfo reqheight $token.cat.l1]
    
    # Get the needed shapes
    set shape_left  [lindex $token_shapes($token) 0]
    set shape_right [lindex $token_shapes($token) end]
       
    # Create the token images, if necessary
    if {![info exists images($w,left,$l1_height,$cat_usebc,$txt_bg,$shape_left)]} {
      set images($w,left,$l1_height,$cat_usebc,$txt_bg,$shape_left) [image create bitmap -data [eval "tokenframe::create_left $shape_left $l1_height"] -maskdata [eval "tokenframe::create_left_mask $shape_left $l1_height"] -foreground $cat_usebc -background $txt_bg]
    }
    if {![info exists images($w,cat_edge,$cat_usebc)]} {
      set images($w,cat_edge,$cat_usebc) [image create bitmap -data "#define edge_width 7\n#define edge_height 2\nstatic char edge_bits\[\] = {\n0x7f, 0x7f};" -foreground $cat_usebc]
    }
    if {![info exists images($w,val_edge,$val_usebc)]} {
      set images($w,val_edge,$val_usebc) [image create bitmap -data "#define edge_width 7\n#define edge_height 2\nstatic char edge_bits\[\] = {\n0x7f, 0x7f};" -foreground $val_usebc]
    }
    if {![info exists images($w,cat_middle,$l1_cat_width,$l1_height,$cat_usebc)]} {
      set images($w,cat_middle,$l1_cat_width,$l1_height,$cat_usebc) [image create bitmap -data [tokenframe::create_middle $l1_cat_width $l1_height] -foreground $cat_usebc]
    }
    if {![info exists images($w,val_middle,$l1_val_width,$l1_height,$val_usebc)]} {
      set images($w,val_middle,$l1_val_width,$l1_height,$val_usebc) [image create bitmap -data [tokenframe::create_middle $l1_val_width $l1_height] -foreground $val_usebc]
    }
    if {![info exists images($w,$l1_height,$val_usebc,$txt_bg,$shape_right)]} {
      set images($w,right,$l1_height,$val_usebc,$txt_bg,$shape_right) [image create bitmap -data [eval "tokenframe::create_right $shape_right $l1_height"] -maskdata [eval "tokenframe::create_right_mask $shape_right $l1_height"] -foreground $val_usebc -background $txt_bg]
    }

    # Configure the label images
    $token.ll         configure -padx 0 -pady 0 -compound center -image $images($w,left,$l1_height,$cat_usebc,$txt_bg,$shape_left)
    $token.cat.l1     configure -padx 0 -pady 0 -compound center -image $images($w,cat_middle,$l1_cat_width,$l1_height,$cat_usebc)
    $token.cat.l2.top configure -padx 0 -pady 0 -compound center -image $images($w,cat_edge,$cat_usebc)
    $token.cat.l2.bot configure -padx 0 -pady 0 -compound center -image $images($w,cat_edge,$cat_usebc)
    $token.val.l1     configure -padx 0 -pady 0 -compound center -image $images($w,val_middle,$l1_val_width,$l1_height,$val_usebc)
    $token.val.l2.top configure -padx 0 -pady 0 -compound center -image $images($w,val_edge,$val_usebc)
    $token.val.l2.bot configure -padx 0 -pady 0 -compound center -image $images($w,val_edge,$val_usebc)
    $token.lr         configure -padx 0 -pady 0 -compound center -image $images($w,right,$l1_height,$val_usebc,$txt_bg,$shape_right)

  }

  ###########################################################################
  # Reverses the color scheme of the given token.
  proc reverse_token {w token} {

    # Get the current colors
    set a_cat_bg [$token.cat.l1 cget -bg]
    set a_cat_fg [$token.cat.l1 cget -fg]
    set a_cat_bc [$token.cat.l2.top cget -bg]
    set b_cat_bg [$token.cat.l2.top cget -fg]
    set b_cat_fg [$token.cat.l2.mid cget -fg]
    set b_cat_bc [$token.cat.l2.bot cget -fg]
    
    set a_val_bg [$token.val.l1 cget -bg]
    set a_val_fg [$token.val.l1 cget -fg]
    set a_val_bc [$token.val.l2.top cget -bg]
    set b_val_bg [$token.val.l2.top cget -fg]
    set b_val_fg [$token.val.l2.mid cget -fg]
    set b_val_bc [$token.val.l2.bot cget -fg]

    # Reverse the color schemes
    $token.ll         configure -bg $b_cat_bg
    $token.cat        configure -bg $b_cat_bg
    $token.cat.l1     configure -bg $b_cat_bg -fg $b_cat_fg
    $token.cat.l2.top configure -bg $b_cat_bc -fg $a_cat_bg
    $token.cat.l2.mid configure -bg $b_cat_bg -fg $a_cat_fg
    $token.cat.l2.bot configure -bg $b_cat_bc -fg $a_cat_bc
    $token.val        configure -bg $b_val_bg
    $token.val.l1     configure -bg $b_val_bg -fg $b_val_fg
    $token.val.l2.top configure -bg $b_val_bc -fg $a_val_bg
    $token.val.l2.mid configure -bg $b_val_bg -fg $a_val_fg
    $token.val.l2.bot configure -bg $b_val_bc -fg $a_val_bc
    $token.lr         configure -bg $b_val_bg

    # Redraw the token
    redraw_token $w $token 0

  }

  ###########################################################################
  # Creates a token and inserts it into the textbox.
  proc create_token {w index fg bg bordercolor selectfg selectbg selectbordercolor value} {

    variable options
    variable token_index
    variable img_blank
    variable token_shapes
    
    # Get the first category in the categories list
    set category [lindex $options($w,-categories) 0 1 0]

    # Add the token (store the "store" colors and the select background color in unused slots)
    set token [frame $w.txt.f$token_index($w) -relief flat]
    set catf  [frame $token.cat -bg [lindex $bg 0]]
    set valf  [frame $token.val -bg [lindex $bg end]]
    
    label $token.ll    -bd 0 -bg [lindex $bg 0] -fg [lindex $selectbg 0]
    label $catf.l1     -bd 0 -text $category -fg [lindex $fg 0] -bg [lindex $bg 0] -font [$w.txt cget -font]
    frame $catf.l2     -bg [lindex $bg 0]
    label $catf.l2.top -bd 0 -bg [lindex $bordercolor 0] -fg [lindex $selectbg 0]
    label $catf.l2.mid -bd 0 -bg [lindex $bg 0] -fg [lindex $selectfg 0] -image $img_blank
    label $catf.l2.bot -bd 0 -bg [lindex $bordercolor 0] -fg [lindex $selectbordercolor 0]
    label $valf.l1     -bd 0 -text $value -fg [lindex $fg end] -bg [lindex $bg end] -font [$w.txt cget -font]
    frame $valf.l2     -bg [lindex $bg end]
    label $valf.l2.top -bd 0 -bg [lindex $bordercolor end] -fg [lindex $selectbg end]
    label $valf.l2.mid -bd 0 -bg [lindex $bg end] -fg [lindex $selectfg end] -image $img_blank
    label $valf.l2.bot -bd 0 -bg [lindex $bordercolor end] -fg [lindex $selectbordercolor end]
    label $token.lr    -bd 0 -bg [lindex $bg end] -fg [lindex $selectbg end]

    set token_shapes($token) $options($w,-tokenshape)

    # Create the token frames
    redraw_token $w $token 1

    # Pack the labels
    pack $catf.l2.top -anchor n
    pack $catf.l2.mid -fill y -expand yes
    pack $catf.l2.bot -anchor s
    
    pack $catf.l1 -side left -padx 2
    pack $catf.l2 -side left -padx 2
    
    pack $valf.l2.top -anchor n
    pack $valf.l2.mid -fill y -expand yes
    pack $valf.l2.bot -anchor s
    
    pack $valf.l1 -side left -padx 2
    pack $valf.l2 -side left -padx 2

    pack $token.ll -side left
    pack $catf     -side left
    pack $valf     -side left -fill both
    pack $token.lr -side left
    
    $w.txt window create $index -window $token -padx 2

    # Add bindings to the new token
    bind $token       <FocusOut>        "tokensearch::deselect_token $w $token"
    bind $catf.l1     <ButtonPress-1>   "tokensearch::handle_token_press $w $token %x %y"
    bind $catf.l1     <Motion>          "tokensearch::handle_token_drag $w %x %y"
    bind $catf.l1     <ButtonRelease-1> "tokensearch::handle_token_release $w $token %x %y"
    bind $catf.l2.mid <Button-1>        "tokensearch::handle_cat_arrow_click $w $token %x %y"
    bind $valf.l1     <ButtonPress-1>   "tokensearch::handle_token_press $w $token %x %y"
    bind $valf.l1     <Motion>          "tokensearch::handle_token_drag $w %x %y"
    bind $valf.l1     <ButtonRelease-1> "tokensearch::handle_token_release $w $token %x %y"
    bind $valf.l2.mid <Button-1>        "tokensearch::handle_val_arrow_click $w $token %x %y"
    bind $catf        <Enter>           "tokensearch::handle_category_enter $w $token"
    bind $valf        <Enter>           "tokensearch::handle_value_enter $w $token"
    bind $token       <Enter>           "tokensearch::handle_token_enter $w $token"
    bind $catf        <Leave>           "tokensearch::handle_category_leave $w $token"
    bind $valf        <Leave>           "tokensearch::handle_value_leave $w $token"
    bind $token       <BackSpace>       "tokensearch::delete_token $w $token"
    bind $token       <Left>            "tokensearch::key_left_right $w left $token"
    bind $token       <Right>           "tokensearch::key_left_right $w right $token"
    bind $token       <Down>            "tokensearch::key_down $w $token"
    bind $token       <Shift-Down>      "tokensearch::key_shift_down $w $token"
    bind $token       <Up>              "tokensearch::key_up $w $token"
    bind $token       <Return>          "tokensearch::key_return $w $token"
    bind $token       <Escape>          "tokensearch::key_escape $w $token"
    if {[tk windowingsystem] eq "aqua"} {
      bind $token <Command-x> "tokensearch::handle_cut $w"
      bind $token <Command-c> "tokensearch::handle_copy $w"
    } else {
      bind $token <Control-x> "tokensearch::handle_cut $w"
      bind $token <Control-c> "tokensearch::handle_copy $w"
    }

    incr token_index($w)

    return $token

  }

  ###########################################################################
  # Returns the text window position given an index.
  proc index_to_position {w index} {

    set indices [list]
    foreach token [$w.txt window names] {
      lappend indices [$w.txt index $token]
    }

    return [lindex [lsort -real $indices] $index]

  }

  ###########################################################################
  # Returns the name of the token at the given index.
  proc index_to_token {w index} {
  
    set indices [list]
    foreach token [$w.txt window names] {
      lappend indices [list [$w.txt index $token] $token]
    }
    
    return [lindex [lsort -real -index 0 $indices] $index 1]
  
  }
  
  ###########################################################################
  # Returns true if the given token is currently selected; otherwise, returns
  # false.
  proc is_selected {token} {

    if {([$token.ll cget -fg] eq [$token.cat.l1 cget -bg]) && ([$token.lr cget -fg] eq [$token.val.l1 cget -bg])} {
      return 1
    } else {
      return 0
    }

  }

  ###########################################################################
  # Creates a token out of the given text, deletes the text.
  proc tokenize {w} {

    variable token_index
    variable options
    variable dont_tokenize
    variable img_blank
    variable edit_info
    variable categoryopt_vars
    variable state
    
    if {$dont_tokenize($w)} {
      set dont_tokenize($w) 0
      return
    }
    
    # If our current state is empty, be done
    if {$state($w) eq "empty"} {
      return
    }

    # Get the current string in the entry field
    set token_str [string trim [$w.txt get 1.0 end]]

    # Figure out the position of the first character of text
    set curr_index 1.0
    set end_index  [$w.txt index end]
    while {($curr_index != $end_index) && ([$w.txt get $curr_index] eq "")} {
      set curr_index [$w.txt index "$curr_index + 1 chars"]
    }

    # Create and add the token and add the token string to the history variable
    if {$token_str ne ""} {
      set token [create_token $w $curr_index $options($w,-tokenfg) $options($w,-tokenbg) $options($w,-tokenbordercolor) \
                              $options($w,-tokenselectfg) $options($w,-tokenselectbg) $options($w,-tokenselectbordercolor) $token_str]
      if {$options($w,-historyvar) ne ""} {
        upvar #0 $options($w,-historyvar) historyvar
        if {[lsearch $historyvar $token_str] == -1} {
          lappend historyvar $token_str
        }
      }
    } else {
      set token ""
    }
    
    # If we have edited this token, clear our recent buffer and populate the new 
    # token with the previous information.
    if {[info exists edit_info($w)]} {
    
      if {$token ne ""} {

        # Set the category
        $token.cat.l1 configure -text [lindex $edit_info($w) 0]

        # Set the category options
        set optnum 0
        foreach opt [lrange $edit_info($w) 1 end] {
          set categoryopt_vars($w,$token,$optnum) $opt
          incr optnum
        }

      }

      # Clear the edit information
      unset edit_info($w)

    } else {

      if {$token ne ""} {

        # Create the categoryopt_vars for the given token
        set optnum 0
        foreach categoryopt $options($w,-categoryopts) {
          set categoryopt_vars($w,$token,$optnum) [lindex $categoryopt 2]
          incr optnum
        }

      }

    }

    # Clear the text field
    $w.txt delete "$curr_index + 1 chars" "$curr_index + [expr [string length $token_str] + 1] chars"

    # Make sure that the insertion cursor is visible
    $w.txt see 1.0
    update
    $w.txt see insert

    # Finally, close the dropdown window if it is currently opened
    close_dropdown $w

    return $token

  }

  ###########################################################################
  # Deletes the token and replaces it with the original text.
  proc detokenize {w token} {

    variable dont_tokenize
    variable active_token
    variable edit_info
    variable categoryopt_vars

    # Save the category and category options information to the edit_info array
    set edit_info($w) [list [$token.cat.l1 cget -text]]
    set optnum        0
    while {[info exists categoryopt_vars($w,$token,$optnum)]} {
      lappend edit_info($w) $categoryopt_vars($w,$token,$optnum)
      array unset categoryopt_vars($w,$token,$optnum)
      incr optnum
    }

    # Change the focus to the textbox prior to deleting the token to avoid
    # having the token be tokenized immediately
    focus $w.txt
    
    # Get some information from the token (position and text)
    set token_pos  [$w.txt index $token]
    set token_text [$token.val.l1 cget -text]

    # Delete the token
    $w.txt delete $token

    # Insert the label text
    $w.txt insert $token_pos $token_text

    # Set the selection to the inserted text
    $w.txt tag add sel $token_pos "$token_pos + [string length $token_text] chars"

    # Set the insertion cursor to the end of the text
    $w.txt mark set insert "$token_pos + [string length $token_text] chars"

    # Make sure that we don't tokenize this string
    set dont_tokenize($w) 1
    
    # Clear the active token
    set active_token($w) ""

  }

  ###########################################################################
  # Removes a token from the entry field.
  proc delete_token {w token} {

    variable options
    variable active_token

    set last_pos ""

    foreach token [$w.txt window names] {
      if {[$token.cat.l1 cget -bg] eq $options($w,-tokenselectbg)} {
        set last_pos [$w.txt index $token]
        $w.txt delete $token
        handle_state $w 1
      }
    }

    # Set the insertion cursor to the end
    if {$last_pos ne ""} {
      $w.txt mark set insert $last_pos
    }
    
    # Clear the active token
    set active_token($w) ""

    # Set the focus back to the entry
    focus $w.txt

  }

  ###########################################################################
  # This procedure is called when the text token receives the focus.  It
  # deselects any currently selected tokens.
  proc deselect_token {w token} {

    variable options
    variable img_blank
    variable active_token
    variable dont_deselect
    
    # If we are disabled, do nothing
    if {$options($w,-state) eq "disabled"} {
      return
    }

    if {$dont_deselect($w) == 0} {
    
      # If we are selected, reverse the token
      if {[is_selected $token]} {
        reverse_token $w $token
      }
    
      # Clear the active token
      set active_token($w) ""

    } else {
    
      set dont_deselect($w) 0
    
    }
    
    # Clear the arrow image
    $token.cat.l2.mid configure -image $img_blank
    $token.val.l2.mid configure -image $img_blank

  }

  ###########################################################################
  # This procedure is called whenever a token is left-pressed.  It allows a 
  # drag and drop option to move the token.
  proc handle_token_press {w token x y} {

    variable pressed_token
    variable options
    variable dont_tokenize

    # If we are disabled, do nothing
    if {$options($w,-state) eq "disabled"} {
      return
    }

    # Save the pressed token
    set pressed_token($w) [list $token $x]

    # Close the dropdown list if it is opened
    close_dropdown $w

    # If there is anything that needs to be tokenized, do it now
    set dont_tokenize($w) 0
    tokenize $w

  }

  ###########################################################################
  # This procedure is called whenever a token is moved.
  proc handle_token_drag {w x y} {

    variable pressed_token

    if {$pressed_token($w) ne ""} {

      # Make sure that the text widget has the focus
      focus $w.txt

      # Change the cursor to a hand
      [lindex $pressed_token($w) 0] configure -cursor left_side

      set index [$w.txt index @[expr [winfo x [lindex $pressed_token($w) 0]] + $x + 8],$y]

      # Get the current location and set the insertion cursor
      if {$x < [lindex $pressed_token($w) 1]} {
        $w.txt mark set insert $index
      } else {
        $w.txt mark set insert "$index + 1 chars"
      }

    }

  }

  ###########################################################################
  # This procedure is called whenever a token is left-clicked.  It changes
  # the state of the token.
  proc handle_token_release {w token x y} {

    variable options
    variable pressed_token
    variable active_token

    # If we are disabled, stop now.
    if {$options($w,-state) eq "disabled"} {
      return
    }

    set start_index [$w.txt index $token]
    set end_index   [$w.txt index @[expr [winfo x [lindex $pressed_token($w) 0]] + $x + 8],$y]

    # If the token was not moved, treat the click as a selection/detokenization
    if {$start_index == $end_index} {

      # If the token is currently selected, detokenize the selection
      if {$active_token($w) == [$w.txt index $token]} {
        
        detokenize $w $token
        
        # Clear the pressed token
        set pressed_token($w) ""
        
        return
        
      } else {
        
        # Reverse the color scheme
        reverse_token $w $token

        # Set the active token
        set active_token($w) [$w.txt index $token]

        # Make sure that the current token keeps the focus
        focus $token
        
        # Generate the TokenSearchSelected event
        event generate $w <<TokenSearchSelected>>
        
      }

    # Otherwise, the token has been dragged to a new position -- delete it and recreate it in the new position
    } else {

      # Move the window to the new position
      if {$x < [lindex $pressed_token($w) 1]} {
        $w.txt window create $end_index -window $token -padx 2
      } else {
        $w.txt window create "$end_index + 1 chars" -window $token -padx 2
      }

      # Delete the previous position if the starting position is less than the ending position
      if {$start_index < $end_index} {
        $w.txt delete $start_index
      }

      # Update the tokenvar variable, if it has been set
      if {$options($w,-tokenvar) ne ""} {
        upvar #0 $options($w,-tokenvar) var
        set var [get_tokens $w]
      }

      # Generate a TokenSearchModified event
      event generate $w <<TokenSearchModified>>

    }

    # Change cursor on pressed token to arrow
    [lindex $pressed_token($w) 0] configure -cursor top_left_arrow

    # Clear the pressed token
    set pressed_token($w) ""

  }

  ###########################################################################
  # Displays the popup menu for the given token.
  proc display_category_menu {w token} {
  
    variable options
    variable dont_deselect
    
    # Clear the menu
    $w.mnu delete 0 end
    
    # Populate the menu with the given categories
    foreach category $options($w,-categories) {
      $w.mnu insert end command -label [lindex $category 0] -state disabled
      foreach value [lindex $category 1] {
        $w.mnu insert end command -label "   $value" -command "$token.cat.l1 configure -text [list $value]; focus -force $token; event generate $w <<TokenSearchModified>>"
      }
    }
    
    # Add the category options
    if {[llength $options($w,-categoryopts)] > 0} {
      $w.mnu insert end command -label "Category Options" -state disabled
      set optnum    0
      set last_type ""
      foreach categoryopt $options($w,-categoryopts) {
        if {[llength $categoryopt] != 3} {
          return -code error "Incorrect number of values specified in -categoryopt ($category).  Must be {type {value(s)} default_value}" 
        }
        if {[lindex $categoryopt 0] eq "checkbutton"} {
          if {$last_type eq "radiobutton"} {
            $w.mnu insert end separator
          }
          $w.mnu insert end checkbutton -label "   [lindex $categoryopt 1]" -variable tokensearch::categoryopt_vars($w,$token,$optnum) -command "focus -force $token; event generate $w <<TokenSearchModified>>"
        } elseif {[lindex $categoryopt 0] eq "radiobutton"} {
          $w.mnu insert end separator
          foreach item [lindex $categoryopt 1] {
            $w.mnu insert end radiobutton -label "   $item" -variable tokensearch::categoryopt_vars($w,$token,$optnum) -value $item -command "focus -force $token; event generate $w <<TokenSearchModified>>"
          }
        } else {
          return -code error "Illegal -categoryopts option type ([lindex $categoryopt 0])"
        }
        set last_type [lindex $categoryopt 0]
        incr optnum
      }
    }
    
    # Specify that we should not perform a focusout deselection
    set dont_deselect($w) 1
    
    # Display the popup menu
    tk_popup $w.mnu [winfo rootx $token.cat.l1] [expr [winfo rooty $token.cat.l1] + [winfo reqheight $token.cat.l1]]
    
  }
  
  ###########################################################################
  # This procedure is called whenever an arrow token is left-clicked.  It changes
  # the state of the token.
  proc handle_cat_arrow_click {w token x y} {

    variable active_token
    variable options
    variable img_blank

    # If we are disabled, stop now.
    if {$options($w,-state) eq "disabled"} {
      return
    }

    if {[$token.cat.l2.mid cget -image] eq $img_blank} {
      handle_token_press   $w $token $x $y
      handle_token_release $w $token $x $y
    } else {
      display_category_menu $w $token
    }

  }

  ###########################################################################
  # Populates the dropdown listbox with the items from the -historyvar list
  # and displays the listbox.
  proc display_dropdown_items {w token} {
  
    variable options
    
    if {[info exists options($w,-historyvar)] && ($options($w,-historyvar) ne "")} {
    
      upvar #0 $options($w,-historyvar) history
    
      # Remove all of the items from the dropdown list
      $w.top.list delete 0 end
    
      # Populate the dropdown list with the list of items from historyvar
      eval "$w.top.list insert end $history"
    
      # Activate and select the first item in the list
      $w.top.list activate 0
      $w.top.list selection set 0
    
      # Show the dropdown list
      open_dropdown $w $token
      
    }
      
  }

  ###########################################################################
  # This procedure is called whenever an arrow token in the value portion of
  # the token is left-clicked.  It pops down a search history drop-down listbox.
  proc handle_val_arrow_click {w token x y} {
  
    variable active_token
    variable options
    variable img_blank
    
    # If we are disabled, stop now.
    if {$options($w,-state) eq "disabled"} {
      return
    }
    
    if {[$token.val.l2.mid cget -image] eq $img_blank} {
      handle_token_press   $w $token $x $y
      handle_token_release $w $token $x $y
    } else {
      display_dropdown_items $w $token
    }
    
  }
  
  ###########################################################################
  # This procedirue is called when the cursor enters a token area.
  proc handle_token_enter {w token} {

    variable options
    variable img_arrow

    # If we are disabled, do nothing
    if {$options($w,-state) eq "disabled"} {
      return
    }

    # Change the cursor
    $token configure -cursor top_left_arrow

  }
  
  ###########################################################################
  # This procedure is called when the cursor enters the category portion of
  # a token area.
  proc handle_category_enter {w token} {
    
    variable options
    variable img_arrow
    
    # If we are disabled, do nothing
    if {$options($w,-state) eq "disabled"} {
      return
    }
    
    # Draw an arrow if we have categories
    if {[llength $options($w,-categories)] > 0} {
      $token.cat.l2.mid configure -image $img_arrow
    }
    
  }
  
  ###########################################################################
  # This procedure is called when the cursor enters the value portion of a
  # token area.
  proc handle_value_enter {w token} {
    
    variable options
    variable img_arrow
    
    # If we are disabled, do nothing
    if {$options($w,-state) eq "disabled"} {
      return
    }
    
    # Draw an arrow if we have history
    if {$options($w,-historyvar) ne ""} {
      upvar #0 $options($w,-historyvar) history
      if {[llength $history] > 0} {
        $token.val.l2.mid configure -image $img_arrow
      }
    }
    
  }

  ###########################################################################
  # This procedure is called when the cursor leaves the category portion of
  # a token.
  proc handle_category_leave {w token} {

    variable options
    variable img_arrow
    variable img_blank

    # If we are disabled, do nothing
    if {$options($w,-state) eq "disabled"} {
      return
    }

    if {([$token.cat.l2.mid cget -image] eq $img_arrow) && ([$token.cat.l2.mid cget -bg] eq [lindex $options($w,-tokenbg) 0])} {
      $token.cat.l2.mid configure -image $img_blank
    }

  }
  
  ###########################################################################
  # This procedure is called when the cursor leaves the value portion of a
  # token.
  proc handle_value_leave {w token} {
    
    variable options
    variable img_arrow
    variable img_blank
    
    # If we are disabled, do nothing
    if {$options($w,-state) eq "disabled"} {
      return
    }
    
    if {([$token.val.l2.mid cget -image] eq $img_arrow) && ([$token.val.l2.mid cget -bg] eq [lindex $options($w,-tokenbg) end])} {
      $token.val.l2.mid configure -image $img_blank
    }
    
  }

  ###########################################################################
  # Calculates the geometry of the given window.
  proc compute_geometry {w} {

    variable options

    if {($options($w,-dropdownheight) == 0) && ($options($w,-dropdownmaxheight) != 0)} {
      set nitems [$w.top.list size]
      if {$nitems > $options($w,-dropdownmaxheight)} {
        $w.top.list configure -height $options($w,-dropdownmaxheight)
      } else {
        $w.top.list configure -height 0
      }
      update idletasks
    }

    # Compute the height and width of the dropdown list
    set bd     [$w.top cget -borderwidth]
    set height [expr [winfo reqheight $w.top] + $bd + $bd]
    set width  [winfo width $w]

    # Figure out where to place it on the screen
    set screen_width  [winfo screenwidth $w]
    set screen_height [winfo screenheight $w]
    set rootx         [winfo rootx $w]
    set rooty         [winfo rooty $w]
    set vrootx        [winfo vrootx $w]
    set vrooty        [winfo vrooty $w]

    set x [expr $rootx + $vrootx]
    set y [expr $rooty + $vrooty + [winfo reqheight $w] + 1]
    set bottom_edge [expr $y + $height]

    # If it extends beyond our screen, trim the list and add a scrollbar
    if {$bottom_edge >= $screen_height} {
      set y [expr ($rooty - $height - 1) + $vrooty]
      if {$y < 0} {
        if {$rooty > [expr $screen_height / 2]} {
          set y      1
          set height [expr $rooty - 1 - $y]
        } else {
          set y      [expr $rooty + $vrooty + [winfo reqheight $w] + 1]
          set height [expr $screen_height - $y]
        }
        handle_scrollbar $w crop
      }
    }

    if {$y < 0} {
      set y 0
      set height $screen_height
    }

    set geometry [format "=%dx%d+%d+%d" $width $height $x $y]

    return $geometry

  }

  ###########################################################################
  # Hides/Displays the scrollbar in the dropdown listbox.
  proc handle_scrollbar {w {action "unknown"}} {

    variable options

    if {$options($w,-dropdownheight) == 0} {
      set hlimit $options($w,-dropdownmaxheight)
    } else {
      set hlimit $options($w,-dropdownheight)
    }

    switch $action {
      "grow" {
        if {($hlimit > 0) && ([$w.top.list size] > $hlimit)} {
          pack forget $w.top.list
          pack $w.top.vsb  -side right -fill y    -expand n
          pack $w.top.list -side left  -fill both -expand y
        }
      }
      "shrink" {
        if {($hlimit > 0) && ([$w.top.list size] <= $hlimit)} {
          pack forget $w.top.vsb
        }
      }
      "crop" {
        pack forget $w.top.list
        pack $w.top.vsb  -side right -fill y    -expand n
        pack $w.top.list -side left  -fill both -expand y
      }
      default {
        if {($hlimit > 0) && ([$w.top.list size] > $hlimit)} {
          pack forget $w.top.list
          pack $w.top.vsb  -side right -fill y    -expand n
          pack $w.top.list -side left  -fill both -expand y
        } else {
          pack forget $w.top.vsb
        }
      }
    }

    return ""

  }

  ###########################################################################
  # This procedure is invoked by various events and displays the dropdown
  # listbox containing a list of selectable values.
  proc open_dropdown {w {token ""}} {

    variable options
    variable old_focus
    variable old_grab
    variable dropdown_token

    # If the user has not provided any values to display, skip opening the window
    if {$options($w,-historyvar) ne ""} {
      upvar #0 $options($w,-historyvar) historyvar
      if {[llength $historyvar] == 0} {
        return 0
      }
    }

    # Update the scrollbar appropriately
    handle_scrollbar $w

    # Compute the geometry of the window to pop up, set it, and force the window manager to
    # take notice
    set geometry [compute_geometry $w]
    wm geometry $w.top $geometry
    update idletasks

    # If we are already open, stop
    if {[winfo ismapped $w.top]} {
      return 0
    }

    # Set the reason
    set dropdown_token($w) $token

    # Save the current focus
    set old_focus($w) [focus]

    # Make the list pop up
    wm deiconify $w.top
    update idletasks
    raise $w.top

    # Force the focus so we can handle keypress events for traversal
    if {$token eq ""} {
      focus -force $w.txt
    } else {
      focus -force $token
    }

    # Save the current grab state
    set status "none"
    set grab [grab current $w]
    if {$grab != ""} {
      set status [grab status $grab]
    }
    set old_grab($w) [list $grab $status]
    unset grab status

    grab -global $w

    # Fake the listbox into thinking it has focus.
    event generate $w.top.list <B1-Enter>

    return 1

  }

  ###########################################################################
  # This procedure is invoked when the user hits the Escape key or makes a
  # a listbox selection.  It removes the dropdown listbox and returns the focus
  # to the text box.
  proc close_dropdown {w} {

    variable old_focus
    variable old_grab
    variable dropdown_token

    # If the window is already unmapped, stop
    if {![winfo ismapped $w.top]} {
      return 0
    }

    catch { focus $old_focus($w) } result
    catch { grab release $w }
    catch {
      set status [lindex $old_grab($w) 1]
      if {$status eq "global"} {
        grab -global [lindex $old_grab($w) 0]
      } elseif {$status eq "local"} {
        grab [lindex $old_grab($w) 0]
      }
      unset status
    }

    # Clear the reason
    set dropdown_token($w) ""

    # Hide the listbox
    wm withdraw $w.top

    # Magic Tcl stuff (see tk.tcl in the distribution lib directory)
    tk::CancelRepeat

    return 1

  }

  ###########################################################################
  # This is called whenever the cursor moves over the listbox.
  proc motion_dropdown {w x y} {

    # Set the cursor
    $w.top.list configure -cursor ""

    # Clear the selections
    $w.top.list selection clear 0 end

    # Set the selection to the current index
    $w.top.list selection set @$x,$y

  }

  ###########################################################################
  # Returns a sorted list of all of the token values.
  proc get_tokens {w} {

    variable categoryopt_vars

    set tokens  [list]
    set indices [list]

    foreach token [$w.txt window names] {
      lappend indices [list [$w.txt index $token] $token]
    }

    foreach index [lsort -real -index 0 $indices] {
      set values [list [[lindex $index 1].cat.l1 cget -text] [[lindex $index 1].val.l1 cget -text]]
      set optnum 0
      while {[info exists categoryopt_vars($w,[lindex $index 1],$optnum)]} {
        lappend values $categoryopt_vars($w,[lindex $index 1],$optnum)
        incr optnum
      }
      lappend tokens $values
    }

    return $tokens

  }

  ###########################################################################
  # Handles the current state of the widget (empty/non-empty) and handles
  # any watermark display (or removal of the display).
  proc handle_state {w keyed} {
  
    variable state
    variable options
    
    # If we are in the empty state
    if {$state($w) eq "empty"} {
    
      $w.txt delete 1.0 end
      
      if {$keyed} {
        set state($w) "non-empty"
        $w.txt configure -foreground $options($w,-foreground)
      } else {
        $w.txt configure -foreground $options($w,-watermarkforeground)
        $w.txt insert end $options($w,-watermark)
        $w.txt mark set insert 1.0
      }
    
    # Otherwise, we are in the not-empty state
    } elseif {$state($w) eq "non-empty"} {
    
      # If the widget is empty, set the state to empty and fill it with the
      # empty string.
      if {([string trim [$w.txt get 1.0 end]] eq "") && ([llength [$w.txt window names]] == 0)} {
        set state($w) "empty"
        $w.txt configure -foreground $options($w,-watermarkforeground)
        $w.txt insert end $options($w,-watermark)
        $w.txt mark set insert 1.0
      }
      
    }
  
  }
  
  ###########################################################################
  # Converts an entry index to a text index.
  proc entry_to_text_index {w index} {

    set offset ""
    if {[regexp {(.+)\s*\-\s*(\d+)$} $index -> index offset]} {
      set offset " - $offset chars"
    }

    if {[string is integer $index]} {
      return "1.$index$offset"
    } elseif {$index eq "anchor"} {
      return -code error "Illegal tokensearch index ($index)"
    } elseif {$index eq "end"} {
      return "1.end$offset"
    } elseif {$index eq "insert"} {
      return "[$w.txt index insert]$offset"
    } elseif {$index eq "sel.first"} {
      return "[lindex [$w.txt tag ranges sel] 0]$offset"
    } elseif {$index eq "sel.last"} {
      return "[lindex [$w.txt tag ranges sel] 1]$offset"
    } else {
      return -code error "Illegal tokensearch index ($index)"
    }

  }

  ###########################################################################
  # Handles all commands.
  proc widget_cmd {w args} {
    
    if {[llength $args] == 0} {
      return -code error "tokensearch widget called without a command"
    }

    set cmd  [lindex $args 0]
    set opts [lrange $args 1 end]

    switch $cmd {
      configure      { eval "tokensearch::configure 0 $w $opts" }
      cget           { return [eval "tokensearch::cget $w $opts"] }
      entrytag       { return [eval "tokensearch::entrytag $w"] }
      listtag        { return [eval "tokensearch::listtag $w"] }
      tokenindex     { return [eval "tokensearch::tokenindex $w $opts"] }
      tokenselection { eval "tokensearch::tokenselection $w $opts" }
      tokenget       { return [eval "tokensearch::get_tokens $w"] }
      tokenconfigure { eval "tokensearch::tokenconfigure $w $opts" }
      tokencget      { return [eval "tokensearch::tokencget $w $opts" }
      tokeninsert    { eval "tokensearch::tokeninsert $w $opts" }
      tokendelete    { eval "tokensearch::tokendelete $w $opts" }
      tokenedit      { eval "tokensearch::tokenedit $w $opts" }
      entryget       { return [$w.txt get 1.0 end] }
      insert         { eval "tokensearch::insert $w $opts" }
      delete         { eval "tokensearch::delete $w $opts" }
      get            { return [eval "tokensearch::get $w $opts"] }
      icursor        { eval "tokensearch::icursor $w $opts" }
      index          { return [eval "tokensearch::index $w $opts"] }
      default        { eval "$w.txt $cmd $opts" }
    }

  }

  ###########################################################################
  # USER COMMANDS
  ###########################################################################

  ###########################################################################
  # Main configuration routine.
  proc configure {initialize w args} {

    variable options
    variable text_options
    variable widget_options
    variable state
    
    if {([llength $args] == 0) && !$initialize} {
      
      set results [list]
      
      foreach opt [lsort [array names widget_options]] {
        if {[llength $widget_options($opt)] == 2} {
          set opt_name    [lindex $widget_options($opt) 0]
          set opt_class   [lindex $widget_options($opt) 1]
          set opt_default [option get $w $opt_name $opt_class]
          if {[info exists text_options($opt)]} {
            lappend results [list $opt $opt_name $opt_class $opt_default [$w.txt cget $opt]]
          } elseif {[info exists options($w,$opt)]} {
            lappend results [list $opt $opt_name $opt_class $opt_default $options($w,$opt)]
          } else {
            lappend results [list $opt $opt_name $opt_class $opt_default ""]
          }
        }
      }
      
      return $results
      
    } elseif {([llength $args] == 1) && !$initialize} {
      
      set opt [lindex $args 0]
      
      if {[info exists widget_options($opt)]} {
        if {[llength $widget_options($opt)] == 1} {
          set opt [lindex $widget_options($opt) 0]
        }
        set opt_name    [lindex $widget_options($opt) 0]
        set opt_class   [lindex $widget_options($opt) 1]
        set opt_default [option get $w $opt_name $opt_class]
        if {[info exists text_options($opt)]} {
          return [list $opt $opt_name $opt_class $opt_default [$w.txt cget $opt]]
        } elseif {[info exists options($w,$opt)]} {
          return [list $opt $opt_name $opt_class $opt_default $options($w,$opt)]
        } else {
          return [list $opt $opt_name $opt_class $opt_default ""]
        }
      }
      
      return -code error "TokenSearch configuration option [lindex $args 0] does not exist"
      
    } else {

      # Save the original contents
      array set orig_options [array get options]

      # Parse the arguments
      foreach {name value} $args {
        if {[info exists text_options($name)]} {
          $w.txt configure $name $value
        } elseif {[info exists options($w,$name)]} {
          set options($w,$name) $value
        } else {
          return -code error "Illegal option given to the tokensearch configure command ($name)"
        }
      }

      # Update the GUI widgets
      # $w.txt configure -fg $options($w,-foreground) -bg $options($w,-background) -relief $options($w,-relief) -state $options($w,-state)
      if {$options($w,-width) ne ""} {
        $w.txt configure -width $options($w,-width)
      }
      if {$options($w,-height) ne ""} {
        $w.txt configure -height $options($w,-height)
      }
      $w.mnu configure -bg $options($w,-categorybg) -bd $options($w,-categorybd) -relief $options($w,-categoryrelief) -font $options($w,-categoryfont) -cursor $options($w,-categorycursor)

      if {[string is boolean $options($w,-wrap)]} {
        if {$options($w,-wrap)} {
          $w.txt configure -wrap word
        } else {
          $w.txt configure -wrap none
        }
      } else {
        set options($w,-wrap) $orig_options($w,-wrap)
        return -code error "Value for -wrap option is not a boolean value ($options($w,-wrap))"
      }

      # If the textbox is empty, configure it for the watermark
      if {$options($w,-watermark) ne ""} {
        set state($w) "empty"
      }
      handle_state $w 0
      
      if {($orig_options($w,-dropdownheight) ne $options($w,-dropdownheight)) || \
          ($orig_options($w,-dropdownmaxheight) ne $options($w,-dropdownmaxheight))} {
        handle_scrollbar $w
      }
    
      # Update the tokens, if necessary
      if {($orig_options($w,-tokenbg)        ne $options($w,-tokenbg))        || ($orig_options($w,-tokenfg)         ne $options($w,-tokenfg)) || \
          ($orig_options($w,-tokenselectbg)  ne $options($w,-tokenselectbg))  || ($orig_options($w,-tokenselectfg)   ne $options($w,-tokenselectfg)) || \
          ($orig_options($w,-tokenshape)     ne $options($w,-tokenshape))} {      
        set token_num [llength [$w.txt window names]]
        for {set i 0} {$i < $token_num} {incr i} {
          tokenconfigure $w $i -bg $options($w,-tokenbg) -fg $options($w,-tokenfg) \
                               -selectbg $options($w,-tokenselectbg) -selectfg $options($w,-tokenselectfg) \
                               -shape $options($w,-tokenshape)
        }
      }
      
    }

  }

  ###########################################################################
  # Gets configuration option value(s).
  proc cget {w args} {

    variable options
    variable text_options

    if {[llength $args] != 1} {
      return -code error "Incorrect number of parameters given to the tokensearch cget command"
    }

    if {[info exists text_options([lindex $args 0])]} {
      return [$w.txt cget [lindex $args 0]]
    } elseif {[info exists options($w,[lindex $args 0])]} {
      return $options($w,[lindex $args 0])
    } else {
      return -code error "Illegal option given to the tokensearch cget command ([lindex $args 0])"
    }

  }
  
  ###########################################################################
  # Returns the name of the entry bind tag to use for the specified widget.
  proc entrytag {w} {
  
    variable tags
    
    if {[info exists tags($w,entry)]} {
      return $tags($w,entry)
    } else {
      return -code error "Bad widget pathname given to the entrytag command ($w)"
    }
    
  }
  
  ###########################################################################
  # Returns the name of the list bind tag to use for the specified widget.
  proc listtag {w} {
  
    variable tags
    
    if {[info exists tags($w,entry)]} {
      return $tags($w,list)
    } else {
      return -code error "Bad widget pathname given to the listtag command ($w)"
    }
    
  }

  ###########################################################################
  # Configures the token located at the given index.
  proc tokenconfigure {w args} {

    variable token_shapes
    
    if {[expr [llength $args] % 2] == 0} {
      return -code error "Incorrect number of parameters given to the tokenconfigure command"
    }

    set index [index_to_position $w [lindex $args 0]]

    # Retrieve the current token pathname
    set token [$w.txt window cget $index -window]

    # Figure out if the current token is selected or not
    set selected [is_selected $token]

    set redraw 0
    set resize 0

    foreach {option value} [lrange $args 1 end] {
      switch $option {
        -bg -
        -background {
          if {$selected} {
            $token.cat.l2.top configure -fg [lindex $value 0]
            $token.val.l2.top configure -fg [lindex $value end]
          } else {
            $token.ll         configure -bg [lindex $value 0]
            $token.cat.l1     configure -bg [lindex $value 0]
            $token.cat.l2     configure -bg [lindex $value 0]
            $token.cat.l2.mid configure -bg [lindex $value 0]
            $token.val.l1     configure -bg [lindex $value end]
            $token.val.l2     configure -bg [lindex $value end]
            $token.val.l2.mid configure -bg [lindex $value end]
            $token.lr         configure -bg [lindex $value end]
            set redraw 1
          }
        }
        -fg -
        -foreground {
          if {$selected} {
            $token.cat.l2.mid configure -fg [lindex $value 0]
            $token.val.l2.mid configure -fg [lindex $value end]
          } else {
            $token.cat.l1 configure -fg [lindex $value 0]
            $token.val.l1 configure -fg [lindex $value end]
            set redraw 1
          }
        }
        -bordercolor {
          if {$selected} {
            $token.cat.l2.bot configure -fg [lindex $value 0]
            $token.val.l2.bot configure -fg [lindex $value end]
          } else {
            $token.cat.l2.top configure -bg [lindex $value 0]
            $token.cat.l2.bot configure -bg [lindex $value 0]
            $token.val.l2.top configure -bg [lindex $value end]
            $token.val.l2.bot configure -bg [lindex $value end]
            set redraw 1
          }
        }
        -shape {
          if {([llength $value] < 0) || ([llength $value] > 2)} {
            return -code error "ERROR:  Token -shape list must be contain either 1 or 2 values"
          }
          foreach val $value {
            switch $value {
              pill   -
              tag    -
              square -
              eased  -
              ticket {}
              default {
                return -code error "ERROR:  Token -shape is an unsupported value (pill, tag, square, eased, ticket)"
              }
            }
            set token_shapes($token) $value
            set redraw 1
          }
        }
        -selectbg -
        -selectbackground {
          if {$selected} {
            $token.ll         configure -bg [lindex $value 0]
            $token.cat.l1     configure -bg [lindex $value 0]
            $token.cat.l2     configure -bg [lindex $value 0]
            $token.cat.l2.mid configure -bg [lindex $value 0]
            $token.val.l1     configure -bg [lindex $value end]
            $token.val.l2     configure -bg [lindex $value end]
            $token.val.l2.mid configure -bg [lindex $value end]
            $token.lr         configure -bg [lindex $value end]
            set redraw 1
          } else {
            $token.cat.l2.top configure -fg [lindex $value 0]
            $token.val.l2.top configure -fg [lindex $value end]
          }
        }
        -selectfg -
        -selectforeground {
          if {$selected} {
            $token.cat.l1 configure -fg [lindex $value 0]
            $token.val.l1 configure -fg [lindex $value end]
            set redraw 1
          } else {
            $token.cat.l2.mid configure -fg [lindex $value 0]
            $token.val.l2.mid configure -fg [lindex $value end]
          }
        }
        -selectbordercolor {
          if {$selected} {
            $token.cat.l2.top configure -bg [lindex $value 0]
            $token.cat.l2.bot configure -bg [lindex $value 0]
            $token.val.l2.top configure -bg [lindex $value end]
            $token.val.l2.bot configure -bg [lindex $value end]
            set redraw 1
          } else {
            $token.cat.l2.bot configure -fg [lindex $value 0]
            $token.val.l2.bot configure -fg [lindex $value end]
          }
        }
        -categoryindex {
          $token.cat.l1 configure -text [lindex $options($w,-categories) $value]
          set redraw 1
          set resize 1
        }
        -value {
          $token.val.l1 configure -text $value
          set redraw 1
          set resize 1
        }
        default {
          return -code error "Illegal option to the tokenconfigure option ($option)"
        }
      }
    }

    # If we need to redraw the token, do it now
    if {$redraw} {
      redraw_token $w $token $resize
    }

  }

  ###########################################################################
  # Gets the configuration information located at the given index.
  proc tokencget {w args} {

    variable token_shapes
    
    if {[llength $args] != 2} {
      return -code error "Incorrect number of options given to the tokencget command"
    }

    # Get the token index
    set index [index_to_position $w [lindex $args 0]]

    # Get the token
    set token [$w.txt window cget $index -window]

    # Figure out if the token is currently selected
    set selected [is_selected $token]

    # Do an option lookup
    switch [lindex $args 1] {
      -bg -
      -background {
        if {$selected} {
          return [list [$token.cat.l2.top cget -fg] [$token.val.l2.top cget -fg]]
        } else {
          return [list [$token.cat.l1 cget -bg] [$token.val.l1 cget -bg]]
        }
      }
      -fg -
      -foreground {
        if {$selected} {
          return [list [$token.cat.l2.mid cget -fg] [$token.val.l2.mid cget -fg]]
        } else {
          return [list [$token.cat.l1 cget -fg] [$token.val.l1 cget -fg]]
        }
      }
      -bordercolor {
        if {$selected} {
          return [list [$token.cat.l2.bot cget -fg] [$token.val.l2.bot cget -fg]]
        } else {
          return [list [$token.cat.l2.top cget -bg] [$token.val.l2.top cget -bg]]
        }
      }
      -shape {
        return $token_shapes($token)
      }
      -selectbg -
      -selectbackground {
        if {$selected} {
          return [list [$token.cat.l1 cget -bg] [$token.val.l1 cget -bg]]
        } else {
          return [list [$token.cat.l2.top cget -fg] [$token.val.l2.top cget -fg]]
        }
      }
      -selectfg -
      -selectforeground {
        if {$selected} {
          return [list [$token.cat.l1 cget -fg] [$token.val.l1 cget -fg]]
        } else {
          return [list [$token.cat.l2.mid cget -fg] [$token.val.l2.mid cget -fg]]
        }
      }
      -selectbordercolor {
        if {$selected} {
          return [list [$token.cat.l2.top cget -bg] [$token.val.l2.top cget -bg]]
        } else {
          return [list [$token.cat.l2.bot cget -fg] [$token.val.l2.bot cget -fg]]
        }
      }
      -categoryindex {
        return [lsearch $options($w,-categories) [$token.cat.l1 cget -text]]
      }
      -value {
        return [$token.val.l1 cget -text]
      }
      default {
        return -code error "Illegal option to the tokencget option ([lindex $args 1])"
      }

    }

  }

  ###########################################################################
  # Returns the numerical index of the specified index.
  proc tokenindex {w args} {

    variable active_token

    if {[llength $args] != 1} {
      return -code error "Illegal options to the tokenindex command"
    } else {
      set index [lindex $args 0]
      if {$index eq "active"} {
        if {$active_token($w) eq ""} {
          return -1
        } else {
          return $active_token($w)
        }
      } else {
        return [lindex [$w.txt window names] $index]
      }
    }

  }

  ###########################################################################
  # Handles the tokenselection command.
  proc tokenselection {w args} {

    variable active_token
    variable options

    if {[llength $args] == 0} {

      return -code error "Incorrect number of options to the tokenselection command"

    } else {

      switch [lindex $args 0] {
        get {
        }
        clear {
          set start_index [index_to_position $w [lindex $args 1]]
          set end_index   [index_to_position $w [lindex $args 2]]
          set index       $start_index
          foreach token [lrange [$w.txt window names] $start_index $end_index] {
            $token configure -fg $options($w,-tokenfg) -bg $options($w,-tokenbg)
            incr start_index
          }
          set active_token($w) ""
        }
        set {
          set start_index [index_to_position $w [lindex $args 1]]
          set end_index   [index_to_position $w [lindex $args 2]]
          set index       $start_index
          foreach token [lrange [$w.txt window names] $start_index $end_index] {
            $token configure -fg $options($w,-tokenselectfg) -bg $options($w,-tokenselectbg)
            incr index
          }
          set active_token($w) $start_index
        }
        default {
          return -code error "Illegal token selection command ([lindex $args 0])"
        }
      }

    }

  }

  ###########################################################################
  # Handles the token insertion command.
  proc tokeninsert {w args} {

    variable options
    variable dont_tokenize
    variable categoryopt_vars

    if {[llength $args] != 2} {
      return -code error "Incorrect number of options to the tokeninsert command"
    }

    set index [index_to_position $w [lindex $args 0]]

    if {$index eq ""} {
      set index [$w.txt index "1.[lindex $args 0]"]
    }
    
    # Make sure that all inserted text is tokenized
    set dont_tokenize($w) 0

    # Create the tokens (we do this for performance purposes)
    foreach value [lreverse [lindex $args 1]] {
    
      # Handle the current state
      handle_state $w 1

      # Insert the text into the widget
      $w.txt insert $index [lindex $value 1]

      # Turn the text into a token
      if {[set token [tokenize $w]] ne ""} {

        # Set the category
        $token.cat.l1 configure -text [lindex $value 0]

        # Set the category options
        set optnum 0
        foreach opt [lrange $value 2 end] {
          set categoryopt_vars($w,$token,$optnum) $opt
          incr optnum
        }

      }

    }

  }

  ###########################################################################
  # Deletes one or more tokens from the text widget.
  proc tokendelete {w args} {

    if {([llength $args] == 0) || ([llength $args] > 2)} {
      return -code error "Incorrect number of options to the tokendelete command"
    }

    # If the user wants to delete a single item, do so
    if {[llength $args] == 1} {
      set index [index_to_position $w [lindex $args 0]]
      if {$index ne ""} {
        $w.txt delete $index
        handle_state $w 1
      }

    # Otherwise, delete a range of items
    } else {
      set sindex [index_to_position $w [lindex $args 0]]
      set eindex [index_to_position $w [lindex $args 1]]
      if {$sindex ne ""} {
        if {$eindex eq ""} {
          $w.txt delete $sindex
        } else {
          $w.txt delete $sindex "$eindex + 1 chars"
        }
        handle_state $w 1
      }
    }

  }
  
  ###########################################################################
  # Detokenizes the given token to make it editable.
  proc tokenedit {w args} {
  
    if {[llength $args] != 1} {
      return -code error "Incorrect number of options to the tokenedit command"
    }
    
    # Detokenize the given index
    if {[set token [index_to_token $w [lindex $args 0]]] ne ""} {
      detokenize $w $token
    }
    
  }

  ###########################################################################
  # Overrides the text insert command to handle watermarks.
  proc insert {w args} {
  
    if {([llength $args] != 1) && ([llength $args] != 2)} {
      return -code error "tokensearch::insert called with wrong arguments"
    }

    # If the user has inserted a non-empty string of data, make sure the state
    # is handled properly.
    if {[lindex $args 1] ne ""} {
      handle_state $w 1
    } else {
      handle_state $w 0
    }
  
    return [eval "$w.txt insert [entry_to_text_index $w [lindex $args 0]] [lindex $args 1]"]
    
  }
  
  ###########################################################################
  # Converts tokenentry delete command to a text delete command.
  proc delete {w args} {

    variable state

    if {[llength $args] == 1} {
      if {$state($w) ne "empty"} {
        $w.txt delete [entry_to_text_index $w [lindex $args 0]]
        handle_state $w 0
      }
    } elseif {[llength $args] == 2} {
      if {$state($w) ne "empty"} {
        $w.txt delete [entry_to_text_index $w [lindex $args 0]] \
                      [entry_to_text_index $w [lindex $args 1]]
        handle_state $w 0
      }
    } else {
      return -code error "tokensearch::delete called with wrong arguments"
    }

  }

  ###########################################################################
  # Converts tokensearch get command to a text get command.
  proc get {w args} {

    variable state

    if {[llength $args] != 0} {
      return -code error "tokensearch::get called with wrong arguments"
    }

    if {$state($w) eq "empty"} {
      return ""
    } else {
      return [$w.txt get 1.0 1.end]
    }

  }

  ###########################################################################
  # Converts tokensearch icursor command to a text insertion cursor call.
  proc icursor {w args} {

    variable state

    if {[llength $args] != 1} {
      return -code error "tokensearch::icursor called with wrong arguments"
    }
    
    if {$state($w) eq "empty"} {
      return [$w.txt mark set insert 1.0]
    } else {
      return [eval "$w.txt mark set insert [entry_to_text_index $w [lindex $args 0]]"]
    }

  }

  ###########################################################################
  # Converts tokensearch index command to a text index command call.
  proc index {w args} {

    variable state

    if {[llength $args] != 1} {
      return -code error "tokensearch::index called with wrong arguments"
    }

    if {$state($w) eq "empty"} {
      return 0
    } else {
      return [lindex [split [$w.txt index [entry_to_text_index $w [lindex $args 0]]] .] 1]
    }

  }

  namespace export *

}
