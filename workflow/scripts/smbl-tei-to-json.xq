xquery version "3.1";

declare default element namespace "http://www.tei-c.org/ns/1.0";

import module namespace functx="http://www.functx.com" at "functx.xqm";
import module namespace smblmap="http://wlpotter.github.io/ns/smblmap" at "smbl-mappings.xqm";



declare variable $file-path external;
(: for local testing, set as /home/arren/Documents/GitHub/britishLibrary-data/data/tei/103.xml :)
declare variable $in-file := doc($file-path);

(: Global variable for the manuscript-object-level URI :)
declare variable $ms-id := $in-file//msDesc/msIdentifier/idno[@type="URI"]/text();

(: Global variables for the URIs used in the @type JSON-LD keys :)
declare variable $ms-obj-type-uri := "https://wlpotter.github.io/ontologies/manuscripts#ManuscriptObject";

declare variable $cod-unit-type-uri := "https://wlpotter.github.io/ontologies/manuscripts#CodicologicalUnit";

(:~
: Taks a tei:msPart, or tei:msDesc that does not have an msPart
: Takes a string giving the part identifier, should be a URI
: Returns a JSON map containing information relevant to that part
: TODO EXAMPLE MAP
:  :)
declare function local:create-part-map($part as node(), $partId as xs:string)
as item() {
  let $type := array {
    $part/head/listRelation[@type="Wright-BL-Taxonomy"]/relation[@ref="http://purl.org/dc/terms/type"]/@passive/string()
}
  let $label := $part/msIdentifier/altIdentifier/idno[@type="BL-Shelfmark-display"]/text()
  let $idnos := local:create-idnos-map($part/msIdentifier, ("BL-Shelfmark", "Wright-BL-Roman"))

  let $extent := $part/physDesc/objectDesc/supportDesc/extent/measure[@type="composition"]
  let $extentType := $extent/@unit/string()
  let $extentType := if($extentType) then $smblmap:extent-units($extentType) else ()

  let $extent := map {
    "type": $extentType,
    "label": $extent/text(),
    "quantity": $extent/@quantity/string()
  }
  
  let $support := $part/physDesc/objectDesc/supportDesc/@material/string()
  let $support := if($support) then $smblmap:supports($support) else $support
  
  let $physDescNote := $part/physDesc/p//text() => string-join(" ") => normalize-space()
  
  let $origin := $part/history/origin
  
  let $origDate :=
    array {
      for $date in $origin/origDate
      let $calendar := $date/@*[name() = "calendar" or name() = "datingMethod"]/string()
      let $calendar := if($calendar) then $smblmap:dating-methods($calendar) else $calendar
      
      (: handle the inconsistency of how data is encoded here, e.g. notBefore, notBefore-custom, from, when, when-custom :)
      (: when and when-custom included as notBefore, i.e. the start date, with no trailing date :)
      let $start := $date/@*[contains(name(), "notBefore") or name() = "from" or contains(name(), "when")]/string()
      let $end := $date/@*[contains(name(), "notAfter") or name() = "to"]/string()
      let $label := $date//text() => string-join(" ") => normalize-space()
      return map {
        "calendar": $calendar,
        "start": $start,
        "end": $end,
        "label": $label
      }
    }
  
  let $origPlace := map {
    "@id": $origin/origPlace/@ref/string(),
    "label": $origin/origPlace//text() => string-join(" ") => normalize-space()
  }
  
  let $creation :=
    map {
      "origDate": $origDate,
      "origPlace": $origPlace
    }
  
  let $hands :=
  array {
    for $hand in $part/physDesc/handDesc/handNote
    let $handId := $ms-id||"#"||$hand/@xml:id/string()
    let $scope := $hand/@scope/string()
    let $writingInfo := $hand/@script/string()
    (: lookup the writing info in the script and language mapping tables :)
    let $language := if($writingInfo) then $smblmap:languages($writingInfo) else $writingInfo
    let $script := if($writingInfo) then $smblmap:scripts($writingInfo) else $writingInfo
    let $note := $hand//text() => string-join(" ") => normalize-space()
    return map {
      "@id": $handId,
      "scope": $scope,
      "language": $language,
      "script": $script,
      "note": $note
    }
}

  let $contentLang := $part/msContents/textLang/@mainLang/string()
  let $contentLang := if($contentLang) then $smblmap:languages($contentLang) else $contentLang
  
  let $contents := array {
    for $item at $i in $part/msContents/msItem
    return local:create-msItem-map($item, $contentLang, $i - 1, $i + 1)
  }
  let $additions := array {
    for $add in $part/physDesc/additions/list/item
    return local:create-addition-map($add)
  }
  
  (: Return a map of the part and its sub-objects :)
  return map {
    "@id": $partId,
    "label": $label,
    "idno": $idnos,
    "dcterms:type": $type,
    "extent": $extent,
    "support": $support,
    "note": $physDescNote,
    "creation": $creation,
    "hands": $hands,
    "contents": $contents,
    "additions": $additions
  }
};

declare function local:create-msItem-map($item as node(), $contentLang as xs:string?, $prevSibIndex as xs:integer, $nextSibIndex as xs:integer)
as item() {
  let $itemId := $ms-id||"#"||$item/@xml:id/string()
  (: get the URIs for the preceding and following sibling items, if they exist :)
  let $prevSiblingUri := if($prevSibIndex > 0) then $ms-id||"#"||$item/../msItem[$prevSibIndex]/@xml:id/string() else ()
  let $nextSiblingUri := if($nextSibIndex <= count($item/../msItem)) then $ms-id||"#"||$item/../msItem[$nextSibIndex]/@xml:id/string() else ()
  
  let $locus := local:create-array-of-locus-maps($item/locus)
  
  let $authors := array {
    for $auth in $item/author
    return map {
      "ref": $auth/@ref/string(),
      "role": $smblmap:creator-roles("author"),
      "name": $auth//text() => string-join(" ") => normalize-space()
    }
  }
  let $editors := array {
    for $ed in $item/editor
    return map {
      "ref": $ed/@ref/string(),
      "role": if($ed/@role/string() !="") then $smblmap:creator-roles($ed/@role/string()) else $smblmap:creator-roles("editor"),
      "name": $ed//text() => string-join(" ") => normalize-space()
    }
  }
  
  let $workRef := array {distinct-values($item/title/@ref/string())}
  let $title := $item/title//text() => string-join(" ") => normalize-space()
  
  let $excerpts := array {
    for $ex in $item/*[functx:is-value-in-sequence(name(), ("rubric", "incipit", "quote", "explicit", "finalRubric"))]
    return map {
      "locus": local:create-array-of-locus-maps($ex/locus),
      "type": $smblmap:excerpt-types($ex/name()),
      "transcription": $ex/text() => string-join(" ") => normalize-space() (: TODO: this data is messy since some sub-elements may have content that should be included, but some, such as note, might not. For now simply taking the immediate child text and joining together. :)
    }
  }
  
  let $notes := array {
    for $n in $item/note
    (: TODO: handle multi-line paragraphs? :)
    return $n//text() => string-join(" ") => normalize-space()
  }
  
  return map {
    "@id": $itemId,
    "language": $contentLang,
    "locus": $locus,
    "creator": array:join(($authors, $editors)),
    "embodies": $workRef,
    "title": $title,
    "excerpts": $excerpts,
    "notes": $notes,
    "prev_item": $prevSiblingUri,
    "next_item": $nextSiblingUri,
    "child_contents": array {
      for $sub at $i in $item/msItem
      return local:create-msItem-map($sub, $contentLang, $i - 1, $i + 1)
    }
  }
};

declare function local:create-addition-map($addition as node())
as item() {
  (: TODO: colophon and doxology possible sub-types from tei:label :)
  let $addId := $ms-id||"#"||$addition/@xml:id
  let $locus := local:create-array-of-locus-maps($addition/locus)
  (: TODO: item/p could also be an excerpt of the quote type if it contains a tei:quote, but there is some mess here... For now just dumping into a string...:)
  let $notes := array {
    for $n in $addition/p
    return $n//text() => string-join(" ") => normalize-space()
  }
  return map {
    "@id": $addId,
    "locus": $locus,
    "notes": $notes
  }
};

declare function local:create-array-of-locus-maps($locusElements as node()*)
as item()?
{
  (: if no locus element was passed, return an empty array; otherwise process each locus into a map :)
  if(not($locusElements)) then
    array {}
  else
    array {
      for $loc in $locusElements
      let $from := $loc/@from/string()
      let $to := $loc/@to/string()
      let $label := $loc//text() => string-join(" ") => normalize-space()
      return map {
        "from": $from,
        "to": $to,
        "label": $label
      }
    } 
};

declare function local:create-idnos-map($msIdentifier as node(), $idnoTypes as xs:string*)
as item()
{
  let $idnoMaps :=
    for $idno in $msIdentifier//idno
    (: look only at idnos that are included in the $idnoTypes sequence :)
    where functx:is-value-in-sequence($idno/@type/string(), $idnoTypes)
    return map {
      "name": $smblmap:idno-types($idno/@type/string()),
      "value": $idno/text()
    }
    return array {$idnoMaps}
};

declare function local:create-collection-map($msIdentifier as node())
as item()
{
  let $collection := $msIdentifier/collection/text()
  let $collection := if($collection) then $smblmap:collections($collection) else $collection
  let $repository := $msIdentifier/repository/text()
  let $repository := if($repository) then $smblmap:repositories($repository) else $repository
  let $holdingInstitution := if($repository) then $smblmap:holding-institutions($repository) else $repository
  let $settlement := $msIdentifier/settlement/text()
  let $settlement := if($settlement) then $smblmap:places($settlement) else $settlement
  let $country := $msIdentifier/country/text()
  let $country := if($country) then $smblmap:places($country) else $country
  return map {
    "@id": $collection,
    "holdingInstitution": $holdingInstitution,
    "repository": map {
      "@id": $repository,
      "settlement": map {
        "@id": $settlement,
        "country": $country
      }
    }
  }
};

(: ################### :)

(: MS Object Level :)


(: get the URI for the manuscript :)
let $msIdentifier := $in-file//msDesc/msIdentifier
(: use the display shelfmark as an rdfs:label :)
let $label := $msIdentifier/altIdentifier/idno[@type="BL-Shelfmark-display"]/text()

let $idnos := local:create-idnos-map($msIdentifier, ("BL-Shelfmark", "Wright-BL-Roman"))

(: Collection, repository, settlement, and country are all mapped to individuals via a URI :)
let $collectionInfo := local:create-collection-map($msIdentifier)

(: form value either in the main msDesc or an msPart, in the latter case get all distinct values :)
let $forms :=
  if(not($in-file//msDesc/msPart)) then
    $in-file//msDesc/physDesc/objectDesc/@form/string()
  else 
    for $part in $in-file//msDesc/msPart
    return $part/physDesc/objectDesc/@form/string()
let $forms := distinct-values($forms)

(: map each distinct form value to a URI in the ontology, and store these as an array :)
let $forms := 
  array {
    for $f in $forms
    return $smblmap:forms($f)
  }

(: ################### :)
(: Parts :)

let $parts := 
  if(not($in-file//msDesc/msPart)) then
    (: create the part using the msDesc as the context node. Construct the id for the part :)
    array {local:create-part-map($in-file//msDesc, $ms-id||"#Part1")}
  else
    array {
      for $part in $in-file//msDesc/msPart
    (: create a part map for each of the parts, using its part-specific URI :)
    return local:create-part-map($part, $part/msIdentifier/idno[@type="URI"]/text())
    }
    
(: ################### :)
(: Provenance Info :)

let $teiDocUri := $in-file//publicationStmt/idno[@type="URI"]/text()
let $creators := array {
  for $creator in $in-file//titleStmt/editor[@role="creator"]
  return $creator/@ref/string()
}
(:
TODO: partOf association for the named graph or collection-level info??
- need collection-level for the SMBL collection as a whole
- need dataset-level for the JSON-LD, maybe several -- one for each project-source and one for the full knowledge graph?
:)
let $resps :=
  array {
    for $resp in $in-file//titleStmt/respStmt
    let $respNames := 
      for $name in $resp/name
      return string-join($name//text(), " ") => normalize-space()
    let $respString := $resp/resp/text()||" "||string-join($respNames, ", ")
    return map {
      "agent": array{$resp/name/@ref/string()},
      "resp": $respString
    }
  }
let $edition := $in-file//editionStmt/edition/@n/string()
let $pubDate := $in-file//publicationStmt/date/text()

let $provenance := 
  map {
    "@id": $teiDocUri,
    "creator": $creators,
    "respStmts": $resps,
    "edition": $edition,
    "pubdate": $pubDate
  }
  
(: TODO: add to this section a reference, using https://schema.org/citation to the print catalogue of Wright? The trick is there may be multiple due to the part-level nature... :)

(: create a map function that will be serialized as JSON :)
let $json := 
  map {
    "@id": $ms-id,
    "@type": $ms-obj-type-uri,
    "label": $label,
    "idno": $idnos,
    "collection": $collectionInfo,
    "form": $forms,
    "parts": $parts,
    "derivedFrom": $provenance
  }

(: return $json :)
return json:serialize($json, map {"escape": "yes", "format": "xquery"})