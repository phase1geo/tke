proc get_info {args} {

  puts "args: $args"

  array set values {
    a 0
    b 1
    c 2
    d 3
  }

  foreach type $args {
    upvar $type t
    set t $values($type)
  }

}

proc get_proxy {args} {

  foreach type $args {
    upvar $type t
    get_info $type
    set t [set $type]
  }

}

get_info a
puts "a: $a"

get_info b
puts "b: $b"

get_info a c
puts "a: $a, c: $c"

get_proxy d
puts "d: $d"
