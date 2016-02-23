xquery version "3.0";

(:~ Prinzipielle Funktionsdatenbank um die Daten zu extrahieren die benötigt werden :)
module namespace collector="http://localhost:8080/apps/magicaldraw/modules/collector";
import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";
import module namespace draw="http://localhost:8080/apps/magicaldraw/modules/draw" at "draw.xqm";

(:Sollte über den betreiber der App registriert werden, sinnvoll das in der app zu speichern? Ulrike oder Patrick fragen, je nachdem Marcel :)
import module namespace admin="http://localhost:8080/apps/magicaldraw/admin" at "admin.xqm";


import module namespace kwic="http://exist-db.org/xquery/kwic";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace text="http://exist-db.org/xquery/text";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace tei="http://www.tei-c.org/ns/1.0";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";



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

declare function collector:createStatisticXML($appPath as xs:string, $db as node()) {
   let $collection := if($db/meta/subFolder/data(.) eq "") then collection($appPath) else collection(concat($appPath,"/",$db/meta/subFolder/data(.)))
   let $statistic := for $field in $db//fields/field
                                let $result := count(collector:range_simple($collection,$db//search/term/data(.),$field/name/data(.)))
                                return <field>
                                                <text>{$field/text/data(.)}</text>
                                                <name>{$field/name/data(.)}</name>
                                                <result>{$result}</result>
                                            </field>
   let $stats := <statistic id="{$db/@id/data(.)}">
                             {$statistic}
                        </statistic>
   return $stats
};


(:~ General Function, collects the data, given by the User :)
(:
declare function collector:printResults($data-path as xs:string,$db as xs:string, $range as xs:string+, $term as xs:string+, $names as xs:string+) {  
    let $base := collection(concat($data-path,"/",$db))
    
    let $results := <graphics>
                            {for $x in (1 to count($term))
                                let $result := count(collector:range_simple($base,$range,$term[$x]))
                                return <request>
                                                <name>{$names[$x]}</name>
                                                <term>{$term[$x]}</term>
                                                <field_name>{$range}</field_name>
                                                <result>{$result}</result>                                                
                                            </request>                                            
                            }
                            </graphics>
    (:
    let $results := <graphics>
                            {for $par in $term 
                                let $result := count(collector:range_simple($base,$range,$par))
                                return <request>
                                                <name>{$name}</name>
                                                <term>{$par}</term>
                                                <field_name>{$range}</field_name>
                                                <result>{$result}</result>                                                
                                            </request>                                            
                            }
                            </graphics> :)
    let $height := 400
    let $width := 300
    let $scale := (-30,-100,300,1)
    let $data-path := "/db/apps/pessoa/magic"
    return ( system:as-user($admin:admin-id,$admin:admin-pass,
                                    xmldb:store($data-path,"magic.xml",$results)
                                    ) , draw:createSVG($height,$width,$scale))   
};
:)

(:~Search with the range index :)
declare function collector:range_simple($db as node()*,$name as xs:string, $term as xs:string) {
    let $range_con := concat('("',$name,'"),"',$term,'"')
    let $range_funk := concat("//range:field-eq(",$range_con,")")
    let $range_db := concat("$db",$range_funk)
    return util:eval($range_db)
};

declare function collector:getHighestResult($db) as xs:integer{
    let $result := for $a in $db//field/result/data(.)
                            order by xs:integer($a) descending
                            return $a
      return $result[1]
};                      



