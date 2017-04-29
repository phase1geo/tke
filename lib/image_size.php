<?php
list($width, $height, $type, $attr) = getimagesize( $argv[1] );
echo "$width $height";
?>
