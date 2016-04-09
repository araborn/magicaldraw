


(: Variablen für Doppelkreisdiagramme :)
declare variable $local:rK := 70;
declare variable $local:rGr := 100;
(: Kreismittelpunkt :)
declare variable $local:Mx := 150;
declare variable $local:My := 150;

declare function local:geschlechter-chart-erstellen($spruch as node()) as node()*{
    let $spruchlabel := local:spruchlabel-erstellen($spruch)
    let $spruchParam := concat($spruch, "-", "V", $spruch, "-", $spruch, "V")
    (: Pfade des kleinen Kreises (= einzelner Spruch) für das Geschlechter-Pie-Chart bestimmen :)
     let $pfadeKl := for $geschlecht at $pos in $tb-update:spruchzahlenGeschlecht//spruch[@name = $spruch]/geschlecht
                 let $label := let $name := $geschlecht/data(@name)
                               return 
                                 if ($name = "M")
                                 then "männlich"
                                 else if ($name = "F")
                                 then "weiblich"
                                 else $name
                 let $prozent := $geschlecht/ceiling(@prozent)
                (: Endpunkt des Kreissegments berechnen :)
                 let $winkelZumEndpunkt := if ($geschlecht/@prozent = '100') 
                                           then 359
                                           else $geschlecht/@prozent * 3.6
                 let $winkelRad := math:radians($winkelZumEndpunkt)
                 let $Ex := math:sin($winkelRad) * $local:rK + $local:rK
                let $Ey := $local:rK - math:cos($winkelRad) * $local:rK
                (: den Abstand vom Rand des Koordinatensystems zum Kreis berücksichtigen :)
                let $Ex := $Ex + $local:Mx - $local:rK
                let $Ey := $Ey + $local:My - $local:rK
                 (: Rotationswinkel des Kreissegmentes berechnen (= Summe der Endpunktwinkel der vorangehenden Segmente) :)
                 let $winkelSum := sum(for $prec in $geschlecht/preceding-sibling::geschlecht
                                       return $prec/@prozent * 3.6)
                 (: Sweep-Flag :)
                 let $flag := if ($winkelZumEndpunkt gt 180)
                              then 1
                              else 0
                 return <g xmlns:xlink="http://www.w3.org/1999/xlink">
                            <rect x="260" y="{$pos * 20}" width="11" height="11" stroke="none" stroke-width="0" fill="{$conf:colors[$pos]}"/>
                            <text text-anchor="start" x="275" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#666666">{$label}</text>
                            {if ($pos = 1)
                            then <text text-anchor="start" x="350" y="10" font-family="Arial" font-size="11" font-weight="bold" stroke="none" stroke-width="0" fill="#666666">{$spruchlabel}</text>
                            else ()}
                            <a xlink:href="/liste?geschlecht={data($geschlecht/@name)}&amp;spruch={$spruchParam}" title="Objekte anzeigen" class="svgTextLink"><text text-anchor="start" x="350" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#2381AE">{data($geschlecht)}</text></a>
                            <text text-anchor="start" x="380" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#666666">({$prozent}%)</text>
                            <a xlink:href="/liste?geschlecht={data($geschlecht/@name)}&amp;spruch={$spruchParam}" class="svgPieLink">
                            <path title="{$spruchlabel}, {$label}: {data($geschlecht)} ({$prozent}%)" 
                            d="M {$local:Mx} {$local:My}
                            L {$local:Mx} {$local:My - $local:rK} 
                            A {$local:rK} {$local:rK} 0 {$flag} 1 {$Ex} {$Ey} Z" stroke="white" fill="{$conf:colors[$pos]}" stroke-width="1" transform="rotate({$winkelSum}, {$local:Mx}, {$local:My})" />
                            </a>
                         </g>
                         