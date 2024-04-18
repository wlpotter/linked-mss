xquery version "3.1";

declare default element namespace "http://www.tei-c.org/ns/1.0";

import module namespace functx="http://www.functx.com" at "http://www.xqueryfunctions.com/xq/functx-1.0.1-nodoc.xq";


declare variable $file-path external;
(: set as /home/arren/Documents/GitHub/britishLibrary-data/data/tei/103.xml :)
declare variable $in-file := doc($file-path);

(: Global variable for the manuscript-object-level URI :)
declare variable $ms-id := $in-file//msDesc/msIdentifier/idno[@type="URI"]/text();

(:~
: Taks a tei:msPart, or tei:msDesc that does not have an msPart
: Takes a string giving the part identifier, should be a URI
: Returns a JSON map containing information relevant to that part
: TODO EXAMPLE MAP
:  :)
declare function local:create-part-map($part as node(), $partId as xs:string)
as item() {
  let $type := $part/head/listRelation[@type="Wright-BL-Taxonomy"]/relation[@ref="http://purl.org/dc/terms/type"]/@passive/string()
  
  let $extent := $part/physDesc/objectDesc/supportDesc/extent/measure[@type="composition"]
  let $extent := map {
    "type": $extent/@unit/string(),
    "label": $extent/text(),
    "quantity": $extent/@quantity/string()
  }
  
  let $support := $part/physDesc/objectDesc/supportDesc/@material/string()
  
  let $physDescNote := $part/physDesc/p//text() => string-join(" ") => normalize-space()
  
  let $origin := $part/history/origin
  
  let $origDate :=
    array {
      for $date in $origin/origDate
      let $calendar := $date/@*[name() = "calendar" or name() = "datingMethod"]/string()
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
      "origDate": ($origDate),
      "origPlace": $origPlace
    }
  
  let $hands :=
  array {
    for $hand in $part/physDesc/handDesc/handNote
    let $handId := $ms-id||"#"||$hand/@xml:id/string()
    let $scope := $hand/@scope/string()
    let $writingInfo := $hand/@script/string()
    (: note: substring-before and substring-after should use the first occurence of a delimiter, important for cases like 'syr-x-syrm' for Melkite Syriac :)
    (: TODO: map language and script to URIs :)
    let $language := substring-before($writingInfo, "-")
    let $script := substring-after($writingInfo, "-")
    let $note := $hand//text() => string-join(" ") => normalize-space()
    return map {
      "@id": $handId,
      "scope": $scope,
      "language": $language,
      "script": $script,
      "note": $note
    }
}

  let $contentLang := $part/msContents/textLang/@mainLang/string() => functx:substring-before-if-contains("-")
  
  let $contents := array {
    for $item in $part/msContents/msItem
    return local:create-msItem-map($item, $contentLang)
  }
  
  (:
  TODO: Additions
  - call a sub-function to handle this
  :)
  let $additions := array {
    for $add in $part/physDesc/additions/list/item
    return local:create-addition-map($add)
  }
  
  (: Return a map of the part and its sub-objects :)
  return map {
    "@id": $partId,
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

declare function local:create-msItem-map($item as node(), $contentLang as xs:string)
as item() {
  let $itemId := $ms-id||"#"||$item/@xml:id/string()
  let $locus := local:create-array-of-locus-maps($item/locus)
  
  (: TODO :)
  let $authors := array {
    for $auth in $item/author
    return map {
      "@id": $auth/@ref/string(),
      (: TODO: role map to uri, maybe syriaca authors-editors roles? :)
      "role": "author",
      "name": $auth//text() => string-join(" ") => normalize-space()
    }
  }
  let $editors := array {
    for $ed in $item/editor
    return map {
      "@id": $ed/@ref/string(),
      (: TODO: role map to uri, maybe syriaca authors-editors roles? :)
      "role": $ed/@role/string(),
      "name": $ed//text() => string-join(" ") => normalize-space()
    }
  }
  
  let $workRef := $item/title/@ref/string()
  let $title := $item/title//text() => string-join(" ") => normalize-space()
  
  let $excerpts := array {
    for $ex in $item/*[functx:is-value-in-sequence(name(), ("rubric", "incipit", "quote", "explicit", "finalRubric"))]
    return map {
      "locus": local:create-array-of-locus-maps($ex/locus),
      "type": $ex/name(),
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
    "contents": array {
      for $sub in $item/msItem
      return local:create-msItem-map($sub, $contentLang)
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

(: ################### :)

(: MS Object Level :)


(: get the URI for the manuscript :)
let $msIdentifier := $in-file//msDesc/msIdentifier
let $shelfmark := $msIdentifier/altIdentifier/idno[@type="BL-Shelfmark"]/text()
(: TODO: entry is at part level as well :)
let $wrightEntry := $msIdentifier/altIdentifier/idno[@type="Wright-BL-Roman"]/text()

(: Collection, repository, settlement, and country should all become mapped to individuals via a URI :)
let $collection := $msIdentifier/collection/text()
let $repository := $msIdentifier/repository/text()
let $settlement := $msIdentifier/settlement/text()
let $country := $msIdentifier/country/text()

(: form value either in the main msDesc or an msPart, in the latter case get all distinct values :)
(: note: should become individuals in the ontology :)
let $forms :=
  if(not($in-file//msDesc/msPart)) then
    $in-file//msDesc/physDesc/objectDesc/@form/string()
  else 
    for $part in $in-file//msDesc/msPart
    return $part/physDesc/objectDesc/@form/string()
let $forms := distinct-values($forms)

(: ################### :)
(: Parts :)

let $parts := 
  if(not($in-file//msDesc/msPart)) then
    (: create the part using the msDesc as the context node. Construct the id for the part :)
    local:create-part-map($in-file//msDesc, $ms-id||"#Part1")
  else
    for $part in $in-file//msDesc/msPart
    (: create a part map for each of the parts :)
    return local:create-part-map($part, $part/msIdentifier/idno[@type="URI"]/text())
  
(: ################### :)
(: Provenance Info :)

(: TODO: add to this section :)
(:
- derivedFrom (use pubStmt/idno)
- creator (use creator editor idnos)
- partOf (needs a named graph for the collection, which will get its own collection-level metadata)
- respStmts (see the example for how to grab this)
- edition
- pub date
- in the prov-d field, maybe, you can also say that the TEI record itself is based on the print bibl and cite the bibl, pages, entry, and url of it
  - trick here is it's part-level...
:)


(: create a map function that will be serialized as JSON :)
let $json := 
  map {
    "@id": $ms-id,
    "shelfmark": $shelfmark,
    "wrightEntry": $wrightEntry,
    "collection": $collection,
    "repository": $repository,
    "settlement": $settlement,
    "country": $country,
    "form": $forms,
    "parts": $parts
  }

(: return $json :)
return json:serialize($json, map {"escape": "no"})