lappend auto_path ".."

package require embed_tke

pack [embed_tke::embed_tke .edit] -fill both -expand yes
