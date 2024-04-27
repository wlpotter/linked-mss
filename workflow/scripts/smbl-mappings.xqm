xquery version "3.1";
(:
: Module Name: Syriac Manuscripts in the British Library Mappings
: Module Version: 1.0
: Copyright: GNU General Public License v3.0
: Proprietary XQuery Extensions Used: None
: XQuery Specification: 08 April 2014
: Module Overview: This module contains mappings between Controlled Vocabulary
:                  terms used in the Syriac Manuscripts in the British Library
:                  dataset and URIs for the Linked Manuscripts knowledge graph
:)

module namespace smblmap="http://wlpotter.github.io/ns/smblmap";

(:
: Found in `/TEI/teiHeader/fileDesc/sourceDesc/msDesc//msIdentifier/collection`
: Range of http://erlangen-crm.org/current/P46i_forms_part_of
:)
declare variable $smblmap:collections :=
  map {
     "Additional": "https://wlpotter.github.io/ontologies/manuscripts#British_Library_Additional_Collection",
     "Additional Manuscripts": "https://wlpotter.github.io/ontologies/manuscripts#British_Library_Additional_Collection",
     "Egerton": "https://wlpotter.github.io/ontologies/manuscripts#Egerton_Collection",
     "Oriental Manuscripts": "https://wlpotter.github.io/ontologies/manuscripts#British_Library_Oriental_Collection",
     "Sloane": "https://wlpotter.github.io/ontologies/manuscripts#Sloane_Collection"
  };

(:
Found in `/TEI/teiHeader/fileDesc/sourceDesc/msDesc//msIdentifier/repository`
Range of https://wlpotter.github.io/ontologies/manuscripts#collection_location
:)
declare variable $smblmap:repositories :=
  map {
    "British Library": "https://wlpotter.github.io/ontologies/manuscripts#Repository_British_Library"
  };

(:
Found in `/TEI/teiHeader/fileDesc/sourceDesc/msDesc//msIdentifier/repository`
Range of https://wlpotter.github.io/ontologies/manuscripts#holding_institution
:)
declare variable $smblmap:holding-institutions :=
  map {
    "British Library": "https://wlpotter.github.io/ontologies/manuscripts#Organization_British_Library"
  };

(:
Found in `/TEI/teiHeader/fileDesc/sourceDesc/msDesc//msIdentifier/settlement` and `/TEI/teiHeader/fileDesc/sourceDesc/msDesc//msIdentifier/country`
Range of http://erlangen-crm.org/current/P89_falls_within
:)
declare variable $smblmap:places :=
  map {
    "London": "http://syriaca.org/place/701",
    "United Kingdom": "http://syriaca.org/place/700"
  };

(:
Found in `/TEI/teiHeader/fileDesc/sourceDesc/msDesc//physDesc/objectDesc/@form`
Range of https://wlpotter.github.io/ontologies/manuscripts#has_form
:)
declare variable $smblmap:forms :=
  map {
    "codex": "https://wlpotter.github.io/ontologies/manuscripts#Codex",
    "leaf": "https://wlpotter.github.io/ontologies/manuscripts#Leaf",
    "other": (),
    "unspecified": ()
  };

(:
Found in `/TEI/teiHeader/fileDesc/sourceDesc/msDesc//physDesc/objectDesc/supportDesc/@material`
Range of https://wlpotter.github.io/ontologies/manuscripts#has_support
:)
declare variable $smblmap:supports :=
  map {
    "chart": "https://wlpotter.github.io/ontologies/manuscripts#Chart",
    "mixed": (
      "https://wlpotter.github.io/ontologies/manuscripts#Chart",
      "https://wlpotter.github.io/ontologies/manuscripts#Perg"
    ),
    "paper": "https://wlpotter.github.io/ontologies/manuscripts#Chart",
    "perg": "https://wlpotter.github.io/ontologies/manuscripts#Perg",
    "unknown": ()
  };

(:
Found in `/TEI/teiHeader/fileDesc/sourceDesc/msDesc//physDesc/objectDesc/supportDesc/extent/measure/@unit`
Range of http://erlangen-crm.org/current/P91_has_unit
:)
declare variable $smblmap:extent-units :=
  map {
    "leaf": "https://wlpotter.github.io/ontologies/manuscripts#Folio"
  };
  
(:
Found in `/TEI/teiHeader/fileDesc/sourceDesc/msDesc//msContents/textLang/@mainLang`
Found as part of `/TEI/teiHeader/fileDesc/sourceDesc/msDesc//physDesc/handDesc/handNote/@script` (substring-before '-')
Range of http://erlangen-crm.org/current/P72_has_language (for contents) or https://wlpotter.github.io/ontologies/manuscripts#employs_language (for Hands)
:)
declare variable $smblmap:languages :=
  map {
    "ar": "https://glottolog.org/resource/languoid/id/arab1395",
    "ar-Syrc": "https://glottolog.org/resource/languoid/id/arab1395",
    "cop": "https://glottolog.org/resource/languoid/id/copt1239",
    "fr": "https://glottolog.org/resource/languoid/id/stan1290",
    "grc": "https://glottolog.org/resource/languoid/id/anci1242",
    "he": "https://glottolog.org/resource/languoid/id/hebr1246",
    "hy": "https://glottolog.org/resource/languoid/id/east2768",
    "la": "https://glottolog.org/resource/languoid/id/lati1261",
    "mixed": (),
    "qhy-x-cpas": "https://glottolog.org/resource/languoid/id/chri1239",
    "syr": "https://glottolog.org/resource/languoid/id/clas1252",
    "syr-Syre": "https://glottolog.org/resource/languoid/id/clas1252",
    "syr-Syrj": "https://glottolog.org/resource/languoid/id/clas1252",
    "syr-Syrn": "https://glottolog.org/resource/languoid/id/clas1252",
    "syr-x-syrm": "https://glottolog.org/resource/languoid/id/clas1252",
    "syr-x-syrp": "https://glottolog.org/resource/languoid/id/chri1239",
    "unknown": (),
    "xcl": "https://glottolog.org/resource/languoid/id/clas1249"
  };
  
(:
Found as part of `/TEI/teiHeader/fileDesc/sourceDesc/msDesc//physDesc/handDesc/handNote/@script` (substring-after '-')
Range of https://wlpotter.github.io/ontologies/manuscripts#employs_script
:)
declare variable $smblmap:scripts :=
  map {
    "ar": "https://wlpotter.github.io/ontologies/manuscripts#Unspecified_Arabic_script",
    "ar-Syrc": "https://wlpotter.github.io/ontologies/manuscripts#Arabic_Garshuni_script",
    "cop": "https://wlpotter.github.io/ontologies/manuscripts#Unspecified_Coptic_script",
    "fr": "https://wlpotter.github.io/ontologies/manuscripts#Unspecified_French_script",
    "grc": "https://wlpotter.github.io/ontologies/manuscripts#Unspecified_Greek_script",
    "he": "https://wlpotter.github.io/ontologies/manuscripts#Unspecified_Hebrew_script",
    "hy": "https://wlpotter.github.io/ontologies/manuscripts#Unspecified_Armenian_script",
    "la": "https://wlpotter.github.io/ontologies/manuscripts#Unspecified_Latin_script",
    "mixed": (),
    "qhy-x-cpas": "https://wlpotter.github.io/ontologies/manuscripts#Christian_Palestinian_Aramaic_script",
    "syr": "https://wlpotter.github.io/ontologies/manuscripts#Unspecified_Syriac_Script",
    "syr-Syre": "https://wlpotter.github.io/ontologies/manuscripts#Estrangela",
    "syr-Syrj": "https://wlpotter.github.io/ontologies/manuscripts#West_Syriac_Script",
    "syr-Syrn": "https://wlpotter.github.io/ontologies/manuscripts#East_Syriac_Script",
    "syr-x-syrm": "https://wlpotter.github.io/ontologies/manuscripts#Melkite_Syriac_script",
    "syr-x-syrp": "https://wlpotter.github.io/ontologies/manuscripts#Christian_Palestinian_Aramaic_script",
    "unknown": (),
    "xcl": "https://wlpotter.github.io/ontologies/manuscripts#Unspecified_Armenian_script"
  };

(:
Found as part of `/TEI/teiHeader/fileDesc/sourceDesc/msDesc//history/origin/origDate/@calendar` or `/TEI/teiHeader/fileDesc/sourceDesc//msDesc/history/origin/origDate/@datingMethod`
Range of https://wlpotter.github.io/ontologies/manuscripts#has_dating_method
:)
declare variable $smblmap:dating-methods :=
  map {
    "Gregorian": "https://wlpotter.github.io/ontologies/manuscripts#Gregorian",
    "gregorian": "https://wlpotter.github.io/ontologies/manuscripts#Gregorian",
    "Hijri-qamari": "https://wlpotter.github.io/ontologies/manuscripts#Hijri-Qamari",
    "Seleucid": "https://wlpotter.github.io/ontologies/manuscripts#Seleucid",
    "#Seleucid": "https://wlpotter.github.io/ontologies/manuscripts#Seleucid"
  };
