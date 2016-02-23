xquery version "3.0";


module namespace draw="http://localhost:8080/apps/magicaldraw/modules/draw";
import module namespace admin="http://localhost:8080/apps/magicaldraw/admin" at "admin.xqm";
import module namespace collector="http://localhost:8080/apps/magicaldraw/modules/collector" at "collector.xqm";


import module namespace kwic="http://exist-db.org/xquery/kwic";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace text="http://exist-db.org/xquery/text";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace tei="http://www.tei-c.org/ns/1.0";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";

declare function draw:testShell($node as node(), $model as map(*)) {
    let $data-path := "/db/apps/pessoa/magic"
    let $magic :=    doc(concat($data-path,"/magic.xml"))
    return draw:createMeasureLine(0,0,0,0,125,10,"Entrys",45)
};


declare function draw:createSVGs($chartType as xs:string, $request as node(),$xml as xs:string) {
    switch($chartType) 
        case "bar" return draw:createBarChart($request, $xml)
        default return ()
};

declare function draw:createBarChart($request as node()*,$xml as xs:string) {
    let $data := doc($xml)    
    let $statisticPath := concat($data//header/appPath/data(.),"/",$data//header/folders/statistics/data(.))
    let $statisticName := concat("statistic_",$data//appName/data(.),".xml")
    let $statistic := doc(concat($data//header/appPath/data(.),"/",$data//header/folders/statistics/data(.),"/",$statisticName))//statistic[@id = $request/@id/data(.)]
    let $highest := collector:getHighestResult($statistic)
    let $amount := count($statistic/field)
    let $measure := draw:createMeasureLine(0,0,0,0,$highest,10,"Entrys",45) 
    let $graphic :=  for $pos in (1 to $amount)
                                   let $x := sum(20 * $pos)
                                   let $rect := draw:createRectangle($statistic,$pos,20,"fill:rgb(0,0,255);stroke-width:2;stroke:rgb(0,0,0)",$x)                            
                                   let $text := draw:createText($statistic,$pos,$x,45)
                                return ($rect,$text)            
    let $style := $request//style
    let $svg_end :=
    <svg height="{$style/height/data(.)}" width="{$style/width/data(.)}" viewBox="{$style/visibleWindow/x1/data(.)} {$style/visibleWindow/y1/data(.)} {$style/visibleWindow/x2/data(.)} {$style/visibleWindow/y2/data(.)}" xmlns="http://www.w3.org/2000/svg"  xmlns:xlink="http://www.w3.org/1999/xlink">
   
        {$graphic,$measure}
        </svg>
     let $svgname := concat($request//meta/chartName/data(.),".svg")
    return system:as-user($admin:admin-id,$admin:admin-pass,
                                    xmldb:store($statisticPath,$svgname,$svg_end)
                                    )     
   
   
};


(:~ Ist dafür Zuständig ein Rechteck zu Zeichnen :)
declare function draw:createRectangle($db  as node(),$position as xs:integer, $width as xs:integer, $style as xs:string, $translate as xs:integer) {
<rect 
    width="{$width}" 
    height="{$db//field[$position]/result/data(.)}"
    style="{$style}"
    transform="translate({$translate}) scale(1,-1)"
    />
    
};
(:~ Zeichnet den Text der Werte an die Entsprechénden Stellen:)
declare function draw:createText($db as node(), $position as xs:integer, $translate as xs:integer, $rotation as xs:integer) {
    <text
        transform="translate({$translate},10) rotate({$rotation})">
        {$db//field[$position]/text/data(.)}
     </text>
};

declare function draw:createMeasureLine($x1,$y1,$x2,$y2, $highest as xs:integer, $interval as xs:integer, $measureText as xs:string, $rotateText) {
        let $vertical := <line x1="{$x1}" y1="{$y1}" x2="{$x2}" y2="-{$highest}" style="stroke:rgb(255,0,0);stroke-width:1" />
        let $divide := $highest div $interval
        let $intervals := if( contains($divide,".")) then xs:integer(substring-before($divide,".")) else $divide
        
        let $horizontal := for $line in (1 to $intervals) 
                                        let $yM := sum($line * $interval)
                                        return( <line x1="-10" y1="-{$yM}" x2="5" y2="-{$yM}" style="stroke:rgb(255,0,0);stroke-width:1" />,
                                        <text x="-30" y="-{$yM}" fill="red" style="font-size:10px">{$yM}</text>)
        
        let $xText := <text x="-35" y="0" transform="rotate(-{$rotateText})" fill="red"  style="font-size:12px">{$measureText}</text>
        
        return ($vertical,$horizontal, $xText)
};


declare function draw:drawDia($node as node(), $model as map(*), $data-path as xs:string, $name as xs:string) {
    (: let $data-path := "/db/apps/pessoa/magic"
     :)
      doc(concat($data-path,"/",$name,".svg"))
};