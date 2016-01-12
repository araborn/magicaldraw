xquery version "3.0";

(:~ Prinzipielle Funktionsdatenbank um die Daten zu extrahieren die benötigt werden :)
module namespace collector="http://localhost:8080/exist/apps/magicaldraw/modules/collector";
import module namespace templates="http://exist-db.org/xquery/templates" at "templates.xql";

(:Sollte über den betreiber der App registriert werden, sinnvoll das in der app zu speichern? Ulrike oder Patrick fragen, je nachdem Marcel :)
import module namespace admin="http://localhost:8080/apps/magicaldraw/admin" at "admin.xqm";


import module namespace kwic="http://exist-db.org/xquery/kwic";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace text="http://exist-db.org/xquery/text";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace tei="http://www.tei-c.org/ns/1.0";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";


(:~ General Function, collects the data, given by the User :)
declare function collector:printResults($data-path as xs:string,$db as xs:string, $name as xs:string+, $term as xs:string+) {  
    let $base := collection(concat($data-path,"/",$db))
    let $results := <search>
                            {for $par in $term 
                                let $result := count(collector:range_simple($base,$name,$par))
                                return <request>
                                                <name>{$name}</name>
                                                <term>{$par}</term>
                                                <result>{$result}</result>
                                            </request>                                            
                            }
                            </search>

    return system:as-user($admin:admin-id,$admin:admin-pass,
                                    xmldb:store($data-path,"magic.xml",$results)
                                    )    
};


(:~Search with the range index :)
declare function collector:range_simple($db as node()*,$name as xs:string, $term as xs:string) {
    let $range_con := concat('("',$name,'"),"',$term,'"')
    let $range_funk := concat("//range:field-eq(",$range_con,")")
    let $range_db := concat("$db",$range_funk)
    return util:eval($range_db)
};




declare function collector:drawDia($node as node(), $model as map(*)(:,$name as xs:string, $x as xs:string, $y as xs:string:)) {
    let $data-path := "/db/apps/pessoa/resources/magic"
    let $rec := <circle cx ="40" cy ="40" r ="20" />
    
    let $svg_end := <?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" xmlns:xlink="http://www.w3.org/1999/xlink">
   
        {$rec}
        </svg>
        
        
        return system:as-user($admin:admin-id,$admin:admin-pass,
                                    xmldb:store($data-path,"magic.svg",$svg_end)
                                    )   

};