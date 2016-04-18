xquery version "3.0";


module namespace draw="http://localhost:8080/exist/apps/magicaldraw/draw";
import module namespace admin="http://localhost:8080/apps/magicaldraw/admin" at "admin.xqm";
import module namespace collector="http://localhost:8080/exist/apps/magicaldraw/collector" at "collector.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" ;


import module namespace kwic="http://exist-db.org/xquery/kwic";
declare namespace util="http://exist-db.org/xquery/util";
declare namespace text="http://exist-db.org/xquery/text";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace tei="http://www.tei-c.org/ns/1.0";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";

import module namespace math="http://exist-db.org/xquery/math" at "java:org.exist.xquery.modules.math.MathModule";

(:
declare function draw:testShell($node as node(), $model as map(*)) {
    let $data-path := "/db/apps/pessoa/magic"
    let $magic :=    doc(concat($data-path,"/magic.xml"))
    return draw:createMeasureLine(0,0,0,0,125,10,"Entrys",45)
};
:)

(:~
: Erstellt aus den Daten vom Collector die Charts
@param $chartType Grafiken Typ der Erstellt werden soll
@param $request 

:)
declare function draw:createSVGs($chartType as xs:string, $request as node(),$xml as xs:string) {
    let $data := doc($xml)    
    let $statisticPath := concat($data//header/appPath/data(.),"/",$data//header/folders/statistics/data(.))
    let $statisticName := concat("statistic_",$data//appName/data(.),".xml")
    let $statistic := doc(concat($data//header/appPath/data(.),"/",$data//header/folders/statistics/data(.),"/",$statisticName))//statistic[@id = $request/@id/data(.)]
    let $style := $request//style 
    let $svgMeasure := (xs:integer($style/height/data(.)) ,xs:integer($style/width/data(.)) )
     let $viewBox := ($style/visibleWindow/x1/data(.),$style/visibleWindow/y1/data(.),$style/visibleWindow/x2/data(.),$style/visibleWindow/y2/data(.))
    let $colors := if($style/color/data(.) eq "custom") then  $statistic/field else doc("/db/apps/magicaldraw/data/colors.xml")//section[@name = $style/color/data(.)]
    let $amount := count($statistic/field)
    let $svgname := concat($request//meta/chartName/data(.),".svg")

return  switch($chartType) 
        case "bar" return draw:createBarChart($statistic,$amount,$style,$colors,$svgMeasure,$svgname,$statisticPath)
        case "pie" return draw:createPieChart($statistic,$amount,$style,$colors,$svgMeasure,$svgname,$statisticPath)
        default return ()


};

(:~createBarChart
: Erstellt ein Balkendiagramm
:)
declare function draw:createBarChart($statistic as node()*,$amount as xs:integer,$style as node()*,$colors as node()*,$svgMeasure as xs:integer+,$svgname,$path){
    let $highest := xs:integer(collector:getHighestResult($statistic))
    let $mW := ($svgMeasure[2] - 40) div ($amount +1)
    let $mH := ($svgMeasure[1] - 70) div $highest
    let $multiplikators := ($mH,$mW)
    let $measure :=<g xmlns:xlink="http://www.w3.org/1999/xlink">{ draw:createMeasureLine( (0,0,0,$svgMeasure[1]-70),$highest,10 * $mH,10,$svgMeasure,"Entrys",45,$amount+1,sum($svgMeasure[1] - 60)) }</g>
    let $graphic :=  for $pos in (1 to $amount)
                                   let $hight := $statistic//field[$pos]/result/data(.)
                                   let $x := sum(for $past in (1 to $pos -1 ) return $mW + 5)
                                   let $translate := ($x + 30,sum($svgMeasure[1] - 60))
                                   let $color := if( $style/color/data(.) = "custom") then $colors[position() = $pos]/color/data(.)  else  $colors/color[position() = $pos]/data(.)
                                   let $title := concat($statistic//field[$pos]/text/data(.)," [",$hight,"]")
                                   let $rect := draw:createRectangle($hight * $mH, $mW,concat("fill:",$color,";stroke-width:1;stroke:rgb(0,0,0)"),$translate,$title)                            
                                   let $text := draw:createText($statistic,$pos,$translate,45)
                                return <g xmlns:xlink="http://www.w3.org/1999/xlink">{($rect,$text) }</g>           
                                
    let $chart := 
    <svg height="{$svgMeasure[1]}" width="{$svgMeasure[2]}"  xmlns="http://www.w3.org/2000/svg"  xmlns:xlink="http://www.w3.org/1999/xlink">
        {$measure,$graphic} 
        </svg>
         
   return system:as-user($admin:admin-id,$admin:admin-pass,
                                    xmldb:store($path,$svgname,$chart)
                                    )   
};

(:~ 
Ist dafür Zuständig ein Rechteck zu Zeichnen :)
declare function draw:createRectangle($hight as xs:integer, $width as xs:integer, $style as xs:string, $translate as xs:integer+,$title) {
<rect 
    width="{$width}" 
    height="{$hight}"
    style="{$style}"
    title="{$title}"
    transform="translate({$translate}) scale(1,-1)"
    onmouseover="evt.target.setAttribute('opacity', '0.5');"
    onmouseout="evt.target.setAttribute('opacity','1)');"
    />    
};
(:~ 
Zeichnet den Text der Werte an die Entsprechénden Stellen:)
declare function draw:createText($db as node(), $position as xs:integer, $translate as xs:integer+, $rotation as xs:integer) {
    <text
        transform="translate({$translate[1]} { sum($translate[2]  + 10)}) rotate({$rotation})">
        {$db//field[$position]/text/data(.)}
     </text>
};

declare function draw:createMeasureLine($vL as xs:integer+, $highest as xs:integer, $multi as xs:integer,$interval as xs:integer, $svgMeasure as xs:integer+, $measureText as xs:string, $rotateText,$amount as xs:integer, $translate as xs:integer) {
        let $vertical := <line x1="{$vL[1]}" y1="{$vL[2]}" x2="{$vL[3]}" y2="-{$vL[4]}" style="stroke:rgb(255,0,0);stroke-width:1" transform="translate(15 {$translate})"/>
        let $divide := xs:integer($highest) div $interval 
        let $intervals := xs:integer(floor($divide))
        
        let $horizontal := for $line in (0 to $intervals) 
                                        let $yM := sum($multi * $line)
                                        return if($line = 0) then ( <line x1="-10" y1="-0" x2="{$svgMeasure[2]}" y2="-0" style="stroke:rgb(255,0,0);stroke-width:1" 
                                        transform="translate(0 {$translate})"/>)
                                        else 
                                        ( <line x1="-10" y1="-{$yM}" x2="{$svgMeasure[2]}" y2="-{$yM}" style="stroke:rgb(255,0,0);stroke-width:1" 
                                        transform="translate(0 {$translate})"/>,
                                        <text x="-30" y="-{$yM}" fill="red" style="font-size:10px" transform="translate(30 {$translate})">{$line * $interval}</text>)
        
        let $xText := <text x="-35" y="0" transform="translate(20 {$translate}) rotate(-{$rotateText})" fill="red"  style="font-size:12px" >{$measureText}</text>
        
        return ($vertical,$horizontal, $xText)
};


declare function draw:createPieChart($statistic as node()*,$amount as xs:integer,$style as node()*,$colors as node()*,$svgMeasure as xs:integer+,$svgname,$path) {
    let $svgMx := $svgMeasure[1] div 2
    let $svgMy := $svgMx   
    let $KreisRadius := $svgMx -10
    let $results := for $field in $statistic/field order by xs:integer($field/result/data(.)) ascending return $field
    let $sum := sum(for $field in $results/result/data(.) return $field) + $amount
    let $perPercent := 100 div $sum 
    let $graphic := for $pos in (1 to $amount)
                                let $winkelSum := sum(for $field in (1 to ($pos - 1)) return  ( ceiling(xs:integer($results[position() = $field]/result/data(.)) *$perPercent) * 3.6 ) ) 
                                let $color := if( $style/color/data(.) = "custom") then $results[position() = $pos]/color/data(.)  else  $colors/color[position() = $pos]/data(.)
                                let $percent := ceiling( xs:integer($results[position() = $pos]/result/data(.))*$perPercent)
                                let $name := $results[position() = $pos]/text/data(.)
                                return draw:createPiePiece($percent,$KreisRadius,$svgMx,$svgMy,$winkelSum,$name,$color, $pos)
    let $svg_end :=
    <svg height="{$svgMeasure[1]}" width="{$svgMeasure[2]}" xmlns="http://www.w3.org/2000/svg"  xmlns:xlink="http://www.w3.org/1999/xlink">
   
        {$graphic} 
        </svg>
    return system:as-user($admin:admin-id,$admin:admin-pass,
                                    xmldb:store($path,$svgname,$svg_end)
                                    ) 
};

declare function draw:createPiePiece($percent as xs:integer, $KreisRadius as xs:integer, $Mx  as xs:integer, $My  as xs:integer, $winkelSum as xs:integer,$name as xs:string, $color as xs:string, $pos as xs:integer) {
    let $winkel := if($percent = 100) then 359 else $percent * 3.6
    let $radian := math:radians($winkel)
    let $Ex := math:sin($radian) * $KreisRadius + $KreisRadius 
    let $Ey := $KreisRadius - math:cos($radian) * $KreisRadius 
    let $Ex := $Ex + $Mx - $KreisRadius
    let $Ey := $Ey + $My - $KreisRadius
    
    let $Ty := $pos * 20
    let $Tx := $Mx * 2 + 20
    
     let $flag := if ($winkel gt 180) then 1 else 0
    return <g xmlns:xlink="http://www.w3.org/1999/xlink">
                    <rect x="{$Tx}" y="{$Ty}" width="11" height="11" stroke="none" stroke-width="0" fill="{$color}"/>
                    <text text-anchor="start" x="{$Tx + 15}" y="{$Ty + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#666666">{$name}</text>              
                    <text text-anchor="start" x="{$Tx + 120}" y="{$Ty + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#666666">({$percent}%)</text>
                    <path title="{$name} ({$percent}% ) " id="{$pos}"
                    d="M {$Mx} {$My} L {$Mx} {$My - $KreisRadius} A {$KreisRadius} {$KreisRadius} 0 {$flag} 1 {$Ex} {$Ey} Z"
                    stroke="white" fill="{$color}"
                    stroke-width="1"
                    transform="rotate({$winkelSum}, {$Mx}, {$My})"
                    onmouseover="evt.target.setAttribute('opacity', '0.5');"
                    onmouseout="evt.target.setAttribute('opacity','1)');"
                    />                    
                </g>   
};

declare function draw:calculateRadiant($result as xs:integer, $perPercent as xs:integer) as xs:integer{
    let $multi :=$result * $perPercent
   let $result :=  round-half-to-even($multi ,2)
   return $result
};

declare function draw:drawDia($node as node(), $model as map(*), $data-path as xs:string, $name as xs:string) {
    (: let $data-path := "/db/apps/pessoa/magic"
     :)
      doc(concat($data-path,"/",$name,".svg"))
};