xquery version "3.0";

(:~ Prinzipielle Funktionsdatenbank um die Daten zu extrahieren die benötigt werden :)
module namespace collector="http://localhost:8080/exist/apps/magicaldraw/collector";
import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace draw="http://localhost:8080/exist/apps/magicaldraw/draw" at "draw.xqm";

(:Sollte über den betreiber der App registriert werden, sinnvoll das in der app zu speichern? Ulrike oder Patrick fragen, je nachdem Marcel :)
import module namespace admin="http://localhost:8080/apps/magicaldraw/admin" at "admin.xqm";


import module namespace kwic="http://exist-db.org/xquery/kwic";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace text="http://exist-db.org/xquery/text";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace tei="http://www.tei-c.org/ns/1.0";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";


(:~
: Sammelt anhand des Pfades der von app:moreMagic weitergegeben wurde die Daten.
: Erstellt die Statistik XML her und speichert sie im entsprechenden Ordner im ausgewählten Projekt, lässt alle weiteren Daten von collector:createStatisticXML() erstellen
: Leitet diese XML weiter an draw:createSVGs welche dann die SVGs erstellt
:
@param $xml Der Pfad der von app:moreMagic weiter gegeben wurde
@return Gibt die SVGs aus
:)
declare function collector:collectData($xml as xs:string) {
    let $data := doc($xml)
    let $dataPath := concat($data//header/appPath/data(.),"/",$data//header/folders/data/data(.))
    let $statisticPath := concat($data//header/appPath/data(.),"/",$data//header/folders/statistics/data(.))
    let $statisticName := concat("statistic_",$data//appName/data(.),".xml")
   let $createStatisticXML := for $requests in $data//request
                                                    return collector:createStatisticXML($dataPath,$requests)
    let $completeXML := <statistics>
                                        {$createStatisticXML}
                                        </statistics>
    let $saveXML := system:as-user($admin:admin-id,$admin:admin-pass,
                                    xmldb:store($statisticPath,$statisticName,$completeXML))
   
   let $svgs := for $request in $data//request
                            return draw:createSVGs($request//meta/chartType/data(.),$request,$xml)
    
    return $svgs
};


(:~
:   Sammelt über eine query Funktion alle Statistichen Daten der angegeben Parameter die der nutzer vorher in die XML eingegeben hat
:
: @param $appPath Der Pfad zu den Daten innerhalb der App für die die Grafiken erstellt werden soll, wird von collector:collectData erstellt
: @param $db Alle request Elemente die in der XML stehen
: @return Gibt die Ergebnisse als XML Elemente wieder
:)
declare function collector:createStatisticXML($appPath as xs:string, $db as node()) {
   let $collection := if($db/meta/subFolder/data(.) eq "") then collection($appPath) else collection(concat($appPath,"/",$db/meta/subFolder/data(.)))
   let $statistic := for $field in $db//fields/field
                                let $result := count(collector:range_simple($collection,$db//search/term/data(.),$field/name/data(.)))                                 
                                return <field>
                                                <text>{$field/text/data(.)}</text>
                                                <name>{$field/name/data(.)}</name>
                                                <result>{$result}</result>          
                                                {if(exists($field/color)) then <color>{$field/color/data(.)}</color> else ()}
                                            </field>
   let $stats := <statistic id="{$db/@id/data(.)}">
                             {$statistic}
                        </statistic>
   return $stats
};


(:~
: Suchfunktion die auf der Range Query Index basiert
@param $db Node Collection der Daten
@param $name Der Field name des Indexes
@param $term Kategoriesrungs Element
@return Gibt die Treffer weiter
:)
declare function collector:range_simple($db as node()*,$name as xs:string, $term as xs:string) {
    let $range_con := concat('("',$name,'"),"',$term,'"')
    let $range_funk := concat("//range:field-eq(",$range_con,")")
    let $range_db := concat("$db",$range_funk)
    return util:eval($range_db)
};

(:~ 
: Simple Helferfunktion, um das höchste Resultat weiter zu geben
@param $db Node der momentanen Statistik Datei
@result Höchstes Resultat
:)
declare function collector:getHighestResult($db) as xs:integer{
    let $result := for $a in $db//field/result/data(.)
                            order by xs:integer($a) descending
                            return $a
      return $result[1]
};                      



