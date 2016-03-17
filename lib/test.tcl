source emmet_css.tcl

set values {
  {m10}        {margin: 10px;}
  {m10p20e30x} {margin: 10% 20em 30ex;}
  {m1.5}       {margin: 1.5em;}
  {m1.5ex}     {margin: 1.5ex;}
  {m10foo}     {margin: 10foo;}
  {w100p}      {width: 100%;}
  {c#3}        {color: #333333;}
  {c#e0}       {color: #e0e0e0;}
  {c#fc0}      {color: #ffcc00;}
  {bd5#0}      {border: 5px #000000;}
  {lh2}        {line-height: 2;}
  {fw400}      {font-weight: 400;}
  {p!+m10e!}
{padding: !important;
margin: 10em !important;}
}

foreach {str expect} $values {
  
  puts "---------"
  puts "Expanding $str\n"
  
  set actual [emmet_css::parse $str]
  
  puts "$actual\n"
  
  if {$actual ne $expect} {
    puts "ERROR:  Unexpected expansion"
    puts "Actual:  $actual"
    puts "Expect:  $expect"
    exit 1
  }
}
