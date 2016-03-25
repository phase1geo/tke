# Plugin namespace
namespace eval lorem {

  variable paras [list 1 2 3]
  variable ipsum {
    {Lorem ipsum dolor sit amet, consectetur adipiscing elit. Teneo, inquit, finem illi videri nihil dolere. Hoc est non modo cor non habere, sed ne palatum quidem. At certe gravius. Quoniam, si dis placet, ab Epicuro loqui discimus. Duo Reges: constructio interrete. Ille incendat? Quae similitudo in genere etiam humano apparet. Et ille ridens: Video, inquit, quid agas; Isto modo, ne si avia quidem eius nata non esset. Ait enim se, si uratur, Quam hoc suave! dicturum.}
    {Qui autem de summo bono dissentit de tota philosophiae ratione dissentit. Itaque rursus eadem ratione, qua sum paulo ante usus, haerebitis. Atqui haec patefactio quasi rerum opertarum, cum quid quidque sit aperitur, definitio est. Multa sunt dicta ab antiquis de contemnendis ac despiciendis rebus humanis; Ego vero volo in virtute vim esse quam maximam; Nec hoc ille non vidit, sed verborum magnificentia est et gloria delectatus. Qui-vere falsone, quaerere mittimus-dicitur oculis se privasse; Qua tu etiam inprudens utebare non numquam. Estne, quaeso, inquam, sitienti in bibendo voluptas? Bona autem corporis huic sunt, quod posterius posui, similiora.}
    {Sullae consulatum? Sed haec quidem liberius ab eo dicuntur et saepius. Bonum integritas corporis: misera debilitas. Aliter enim nosmet ipsos nosse non possumus. Facete M. Nam si amitti vita beata potest, beata esse non potest.}
    {An dolor longissimus quisque miserrimus, voluptatem non optabiliorem diuturnitas facit? Quae contraria sunt his, malane? Cur post Tarentum ad Archytam? Nemo igitur esse beatus potest. Indicant pueri, in quibus ut in speculis natura cernitur. Certe non potest. Nam aliquando posse recte fieri dicunt nulla expectata nec quaesita voluptate. Non dolere, inquam, istud quam vim habeat postea videro; Itaque in rebus minime obscuris non multus est apud eos disserendi labor. Nunc ita separantur, ut disiuncta sint, quo nihil potest esse perversius.}
    {Tum Piso: Quoniam igitur aliquid omnes, quid Lucius noster? Quod autem principium officii quaerunt, melius quam Pyrrho; Commoda autem et incommoda in eo genere sunt, quae praeposita et reiecta diximus; Quodcumque in mentem incideret, et quodcumque tamquam occurreret. Quid censes in Latino fore? Habes, inquam, Cato, formam eorum, de quibus loquor, philosophorum.}
    {Nondum autem explanatum satis, erat, quid maxime natura vellet. Velut ego nunc moveor. Egone non intellego, quid sit don Graece, Latine voluptas? Satis est ad hoc responsum. Ipse Epicurus fortasse redderet, ut [redacted]tus Peducaeus, [redacted]. Haec quo modo conveniant, non sane intellego. Quod idem cum vestri faciant, non satis magnam tribuunt inventoribus gratiam. Haec para/doca illi, nos admirabilia dicamus.}
    {Ad eos igitur converte te, quaeso. Cur iustitia laudatur? Erat enim Polemonis. Quodsi ipsam honestatem undique pertectam atque absolutam. Si verbum sequimur, primum longius verbum praepositum quam bonum. Tum Torquatus: Prorsus, inquit, assentior; Sit enim idem caecus, debilis.}
    {Hoc ne statuam quidem dicturam pater aiebat, si loqui posset. Pisone in eo gymnasio, quod Ptolomaeum vocatur, unaque nobiscum Q. Si sapiens, ne tum quidem miser, cum ab Oroete, praetore Darei, in crucem actus est. Nunc haec primum fortasse audientis servire debemus. Honesta oratio, Socratica, Platonis etiam. Expectoque quid ad id, quod quaerebam, respondeas. Haec et tu ita posuisti, et verba vestra sunt. Cur post Tarentum ad Archytam? Quid ei reliquisti, nisi te, quoquo modo loqueretur, intellegere, quid diceret?}
    {In quibus doctissimi illi veteres inesse quiddam caeleste et divinum putaverunt. Quae hic rei publicae vulnera inponebat, eadem ille sanabat. De vacuitate doloris eadem sententia erit. Quamquam haec quidem praeposita recte et reiecta dicere licebit.}
    {Roges enim Aristonem, bonane ei videantur haec: vacuitas doloris, divitiae, valitudo; Duo enim genera quae erant, fecit tria. Eam si varietatem diceres, intellegerem, ut etiam non dicente te intellego; Non autem hoc: igitur ne illud quidem. Quae in controversiam veniunt, de iis, si placet, disseramus. Stulti autem malorum memoria torquentur, sapientes bona praeterita grata recordatione renovata delectant.}
  }

  proc add_list {mnu} {

    variable paras

    foreach para $paras {
      set str [expr {($para > 1) ? "Paragraphs" : "Paragraph"}]
      $mnu add command -label "Insert $para $str" -command [list lorem::insert_paras $para]
    }

    $mnu add separator
    $mnu add command -label "Insert Custom Paragraphs" -command [list lorem::insert_custom]

  }

  proc condition_text {str width} {

    if {$width ne ""} {

      set new_str ""

      while {([string length $str] > $width) && (([set endpos [string last " " $str $width]] != -1) || ([set endpos [string first " " $str]] != -1))} {
        append new_str "[string range $str 0 $endpos]\n"
        set str [string range $str $endpos+1 end]
      }

      append new_str $str

      return $new_str

    }

    return $str

  }

  proc insert_paras {num} {

    variable ipsum

    # Get the current text widget
    set txt [api::file::get_info [api::file::current_file_index] txt]

    # Get the warning width
    set warn_width [$txt cget -warnwidth]

    while {$num > 0} {
      for {set i 0} {$i < [expr min($num,10)]} {incr i} {
        lappend pars [condition_text [lindex $ipsum $i] $warn_width]
      }
      incr num -10
    }

    $txt insert insert [join $pars "\n\n"]

  }

  proc insert_custom {} {

    variable paras

    # Get the paragraph count from the user
    if {[api::get_user_input "Paragraphs:" num] && [string is integer $num] && ([lsearch $paras $num] == -1)} {
      lappend paras $num
      set paras [lsort -integer $paras]
      insert_paras $num
    }

  }

  proc on_save {index} {

    variable paras

    api::plugin::save_variable $index "paras" $paras

  }

  proc on_restore {index} {

    variable paras

    set paras [api::plugin::load_variable $index "paras"]

  }

}

# Register all plugin actions
api::register lorem {
  {menu cascade {Ipsum Lorem} lorem::add_list}
  {on_reload lorem::on_save lorem::on_restore}
}
