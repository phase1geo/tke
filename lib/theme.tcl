namespace eval theme {

  array set fields {
    type  0
    value 1
  }

  variable category_titles [list \
    syntax            [msgcat::mc "Syntax Colors"] \
    ttk_style         [msgcat::mc "ttk Widget Colors"] \
    menus             [msgcat::mc "Menu Options"] \
    tabs              [msgcat::mc "Tab Options"] \
    text_scrollbar    [msgcat::mc "Text Scrollbar Options"] \
    sidebar           [msgcat::mc "Sidebar Options"] \
    sidebar_scrollbar [msgcat::mc "Sidebar Scrollbar Options"] \
    images            [msgcat::mc "Images"] \
  ]

  array set orig_data {
    ttk_style,disabledfg          {color {}}
    ttk_style,frame               {color {}}
    ttk_style,lightframe          {color {}}
    ttk_style,window              {color {}}
    ttk_style,dark                {color {}}
    ttk_style,darker              {color {}}
    ttk_style,darkest             {color {}}
    ttk_style,lighter             {color {}}
    ttk_style,lightest            {color {}}
    ttk_style,selectbg            {color {}}
    ttk_style,selectfg            {color {}}
    menus,-background             {color {}}
    menus,-foreground             {color {}}
    menus,-relief                 {{relief {raised sunken flat ridge solid groove}} {}}
    tabs,-background              {color {}}
    tabs,-foreground              {color {}}
    tabs,-activebackground        {color {}}
    tabs,-inactivebackground      {color {}}
    tabs,-relief                  {{relief {flat raised}} {}}
    text_scrollbar,-background    {color {}}
    text_scrollbar,-foreground    {color {}}
    text_scrollbar,-thickness     {{number {5 20}} {}}
    syntax,background             {color {}}
    syntax,border_highlight       {color {}}
    syntax,comments               {color {}}
    syntax,cursor                 {color {}}
    syntax,difference_add         {color {}}
    syntax,difference_sub         {color {}}
    syntax,foreground             {color {}}
    syntax,highlighter            {color {}}
    syntax,keywords               {color {}}
    syntax,line_number            {color {}}
    syntax,meta                   {color {}}
    syntax,miscellaneous1         {color {}}
    syntax,miscellaneous2         {color {}}
    syntax,miscellaneous3         {color {}}
    syntax,numbers                {color {}}
    syntax,precompile             {color {}}
    syntax,punctuation            {color {}}
    syntax,select_background      {color {}}
    syntax,select_foreground      {color {}}
    syntax,strings                {color {}}
    syntax,warning_width          {color {}}
    sidebar,-foreground           {color {}}
    sidebar,-background           {color {}}
    sidebar,-selectbackground     {color {}}
    sidebar,-selectforeground     {color {}}
    sidebar,-highlightbackground  {color {}}
    sidebar,-highlightcolor       {color {}}
    sidebar,-treestyle            {treestyle {}}
    sidebar_scrollbar,-background {color {}}
    sidebar_scrollbar,-foreground {color {}}
    sidebar_scrollbar,-thickness  {{number {5 20}} {}}
    images,sidebar_open           {image {}}
  }

}
