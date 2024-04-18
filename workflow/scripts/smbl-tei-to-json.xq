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
  (:
  TODO
    - origDate --> dealing with non-Gregorian...
    - notBefore, notAfter, and label (from text node)
    - origPlace: get label and the ref as URI if available
  :)
  
  let $hands :=
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
  
  (:
  TODO: Contents
  - call a sub-function to handle this
  :)
  
  (:
  TODO: Additions
  - call a sub-function to handle this
  :)
  
  (: Return a map of the part and its sub-objects :)
  return map {
    "@id": $partId,
    "dcterms:type": $type,
    "extent": $extent,
    "support": $support,
    "note": $physDescNote,
    "creation": (),
    "hands" :[$hands]
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
    "form": [$forms],
    "parts": [$parts]
  }

return $json
(: return json:serialize($json) :)