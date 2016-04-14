xquery version "1.0";
(:
für alle Sprüche in wissen:
ACHTUNG: - bei allem müssen hier noch die Spruchterme aus Wissen berücksichtigt werden!
         - hier wird auf XML-Daten zugegriffen, die ebenfalls periodisch aktualisiert werden können
         
        - erzeuge 1 Ergebnisdokument spruch-1.xml
        bei / im Spruchnamen in - umwandeln x
        - Inhalte:
        Titel x
        Text des Spruches (mit Angabe des Objektes, Link zum Objekt und des Übersetzers)
            Achtung: 1 Spruch kann mehrere Texte haben x
        - wie viele Objekte tragen den Spruch? x 
        - der wievielthäufigste Spruch ist es damit? x
        PIE CHART: x
        - wie oft als Text und wie oft als Vignette und Text+Vignette belegt?
        - wie oft unsicher identifiziert?
        CHART (BALKEN und PIE?):
        - Spruchüberlieferung über die Zeit? absolut x
        - und relativ zur Verteilung aller Sprüche über die Zeit x
        CHART (BALKEN und PIE): x
        - auf welchen Objekttypen kommt der Spruch wie oft vor? (absolut und relativ)
        CHART (PIE): x
        - Testen: Geschlechtsspezifische Sprüche?
        CHART: x
        - Mar[ck]us fragen: macht die Untersuchung der geograph. Verteilung Sinn (Herkunft)?
        TABELLE: x
        - was sind die häufigsten Nachbarn dieses Spruches? (links und rechts; direkte Nachbarn? Oder gewichtet nach Nähe? Mar[ck]us fragen)      
:)

(: !!! maskierte Zeichen in Javscript !!!
   " > &#34;
   { > &#123;
   } > &#125;
:)

import module namespace math="http://exist-db.org/xquery/math" at "java:org.exist.xquery.modules.math.MathModule";

(: Variablen für Doppelkreisdiagramme :)
declare variable $local:rK := 70;
declare variable $local:rGr := 100;
(: Kreismittelpunkt :)
declare variable $local:Mx := 150;
declare variable $local:My := 150;
declare variable $local:biblWis := doc("/db/totenbuch/bibliography/bibliografie.xml");

declare function local:format-number($n as xs:decimal ,$s as xs:string) as xs:string {
    string(transform:transform(
      <any/>,
      <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
         <xsl:template match='/'>
            <xsl:value-of select="format-number({$n},'{$s}')"/>
         </xsl:template>
      </xsl:stylesheet>,
      ()
    ))
};

declare function local:spruchlabel-erstellen($spruch as node()) as xs:string{
    let $spruchlabel := if (starts-with(data($spruch), "Spruch") or $spruch = ("Adorationsszene", "Buch vom Atmen", "Hymnen und Gebete", "Ritualtext", "Verklärung", "Mythologische Szenen", "Jenseitsführer", "Leinenamulette", "Ausserordentliches Textgut", "Nicht identifizierter Spruch", "Nicht identifizierte Vignette")) then data($spruch) else concat("Spruch ", data($spruch))
    let $spruchlabel := replace($spruchlabel, "\(Pleyte\)", "Pl.")
    let $spruchlabel := replace($spruchlabel, "\(nach Saleh\)", "nach S.")
    let $spruchlabel := replace($spruchlabel, "(Nicht identifizierter|Nicht identifizierte)", "N. i.")
    let $spruchlabel := replace($spruchlabel, "Ausserordentliches", "Auss.")
    let $spruchlabel := replace($spruchlabel, "Mythologische", "Myth.")
    return $spruchlabel
};

declare function local:navigation-erstellen($spruch as node(), $pos as xs:integer) as node(){
    let $spruch := if ($spruch = "Ausserordentliches Textgut")
                   then "Auss. Textgut"
                   else $spruch
    return
    <div class="list-pages">
        <ul>
            <li><a class="link" href="/spruch/{translate(replace(lower-case($tb-update:sprueche[1]), '\s', '-'), '/', '-')}" title="zum ersten Spruch"><img src="/img/BUTTON-list-pages-first.png" /></a></li>
            <li><a class="link" href="/spruch/{translate(replace(lower-case($tb-update:sprueche[$pos - 1]), '\s', '-'), '/', '-')}" title="einen Spruch zurück"><img src="/img/BUTTON-list-pages-previous.png" />&#x00A0;&#x00A0;{data($tb-update:sprueche[$pos - 1])}</a></li>
            <li><span class="list-pages-current">{data($spruch)}</span></li>
            <li><a class="link" href="/spruch/{translate(replace(lower-case($tb-update:sprueche[$pos + 1]), '\s', '-'), '/', '-')}" title="einen Spruch vor">{data($tb-update:sprueche[$pos + 1])}&#x00A0;&#x00A0;<img src="/img/BUTTON-list-pages-next.png" /></a></li>
            <li><a class="link" href="/spruch/{translate(replace(lower-case($tb-update:sprueche[last()]), '\s', '-'), '/', '-')}" title="zum letzten Spruch"><img src="/img/BUTTON-list-pages-last.png" /></a></li>
        </ul>
     </div>
};

declare function local:nachweise-erstellen($spruch as node()) as node()*{
    for $nachweis at $posNachweis in $tb-update:spruchtexte[@TBName = $spruch]/nachweis
    let $tbObjekt := $nachweis/@TBObjekt
    let $tm := $tb-update:objekte[@id = $tbObjekt]/@tm
    let $tbName := $nachweis/parent::spruchtext/@TBName
    let $author := $nachweis/ancestor::spruchtexte/@author
    (: Periode des Objektes, auf dem der Spruch nachgewiesen ist :)
    let $periode := $tb-update:objekte[@id = $tbObjekt]//periode
    let $last := count($nachweis//satz)
    let $text := <div>
                  {for $satz at $pos in $nachweis//satz[1]
                   return
                   <blockquote id="NachweisKurz{$posNachweis}" class="onBlock">{data($satz)}...
                  &#x00A0;<p class="link onInline" onclick="dojo.byId('NachweisLang{$posNachweis}').className = 'onBlock', dojo.byId('NachweisKurz{$posNachweis}').className = 'offDis';"><span class="link-mehr">mehr</span></p>
                     </blockquote>}
                  <blockquote id="NachweisLang{$posNachweis}" class="offDis">
                    {for $satz at $pos in $nachweis//satz
                    return
                    <div>{data($satz)} {if ($pos = $last) 
                                      then ("&#x00A0;", <p class="link onInline" onclick="dojo.byId('NachweisKurz{$posNachweis}').className = 'onBlock', dojo.byId('NachweisLang{$posNachweis}').className = 'offDis';"><span class="link-weniger">ausblenden</span></p>)
                                      else ()}</div>}
                  </blockquote>
                     (<a href="/objekt/tm{$tm}">TM {data($tm)}</a>, {data($periode)}, übersetzt von: {data($author)})
                  </div>
    return
    <div> 
       {$text}
    </div>
};

declare function local:bibliografie-erstellen($spruch as node()) as node()?{
    if (exists($local:biblWis//bibl[matches(tb_spruch, concat("(^|\s)", $spruch, "(,\s|$)"))]))
    then <ul class="registerLiteraturBibliografie bibl">{for $bibl in $local:biblWis//bibl[matches(tb_spruch, concat("(^|\s)", $spruch, "(,\s|$)"))]
         let $short := $bibl/normalize-space(short)
         let $ueber := $bibl/normalize-space(uebergeordneter_titeleintrag)
         let $titel := <span class="wrap">
                            <span class="eintrag">{data($bibl/long)}</span>
                            {if ($bibl/url != "")
                            then <a href="{$bibl/url}" title="zum Text">
                                    <img src="{if (ends-with($bibl/url, '.pdf')) then '/icons/application_pdf.png' else '/icons/document.png'}" />
                                 </a>
                            else ()}
                        </span>
         let $anfangsbuchstabe := if ($bibl/autor_herausgeber_institution = '')
                                  then if ($bibl/titel = '') 
                                      then if($bibl/reihentitel = '') 
                                           then if ($bibl/url = '') 
                                                then substring(translate(upper-case($bibl/zeitschrift_zeitung), 'ІÄÖÜШŠŽČÁÉÍÓÚ*[', 'IAOUSSZCAEIOU'), 1, 1) 
                                                else upper-case(substring($bibl/url, 1, 1)) 
                                           else substring(translate(upper-case($bibl/reihentitel), 'ІÄÖÜШŠŽČÁÉÍÓÚ*[', 'IAOUSSZCAEIOU'), 1, 1) 
                                      else substring(translate(upper-case($bibl/titel), 'ІÄÖÜШŠŽČÁÉÍÓÚ*[', 'IAOUSSZCAEIOU'), 1, 1) 
                                  else substring(translate(upper-case($bibl/autor_herausgeber_institution), 'ІÄÖÜШŠŽČÁÉÍÓÚ*[', 'IAOUSSZCAEIOU'), 1, 1)
         order by $titel
         return <li id="{$bibl/@id}">{$titel}<a href="/register/bibliografie-{$anfangsbuchstabe}#{$bibl/@id}" title="zum Register"><img src="/icons/index.png" alt="zum Register" /></a>
            <!-- <abbr class="unapi-id" title="{$bibl/@id}"/>-->
            <!-- COinS -Tag -->
            <span class="{$bibl/coin/@class}" title="{$bibl/coin/@title}" /></li>}
         </ul>
    else <p>Es liegen keine Einträge vor.</p>
};

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
                            <a xlink:href="/liste?geschlecht={data($geschlecht/@name)}&amp;spruch={$spruchParam}" class="svgPieLink"><path title="{$spruchlabel}, {$label}: {data($geschlecht)} ({$prozent}%)" d="M {$local:Mx} {$local:My} L {$local:Mx} {$local:My - $local:rK} A {$local:rK} {$local:rK} 0 {$flag} 1 {$Ex} {$Ey} Z" stroke="white" fill="{$conf:colors[$pos]}" stroke-width="1" transform="rotate({$winkelSum}, {$local:Mx}, {$local:My})" /></a>
                         </g>
    (: Pfade des großen Kreises (= alle Sprüche) für das Geschlechter-Pie-Chart bestimmen :)  
    let $pfadeGr := for $geschlecht at $pos in $tb-update:spruchzahlenGeschlecht//spruch[@name = "alle"]/geschlecht
                    let $label := let $name := $geschlecht/data(@name)
                               return 
                                 if ($name = "M")
                                 then "männlich"
                                 else if ($name = "F")
                                 then "weiblich"
                                 else $name
                    let $prozent := $geschlecht/ceiling(@prozent)
                    (: Endpunkt des Kreissegments berechnen :)
                    let $winkelZumEndpunkt := $geschlecht/@prozent * 3.6
                    let $winkelRad := math:radians($winkelZumEndpunkt)
                    let $Ex := math:sin($winkelRad) * $local:rGr + $local:rGr
                    let $Ey := $local:rGr - math:cos($winkelRad) * $local:rGr
                    (: den Abstand vom Rand des Koordinatensystems zum Kreis berücksichtigen :)
                    let $Ex := $Ex + $local:Mx - $local:rGr
                    let $Ey := $Ey + $local:My - $local:rGr
                    (: Rotationswinkel des Kreissegmentes berechnen (= Summe der Endpunktwinkel der vorangehenden Segmente) :)
                    let $winkelSum := sum(for $prec in $geschlecht/preceding-sibling::geschlecht
                                          return $prec/@prozent * 3.6)
                    (: Sweep-Flag :)
                    let $flag := if ($winkelZumEndpunkt gt 180)
                                 then 1
                                 else 0
                    return <g xmlns:xlink="http://www.w3.org/1999/xlink">
                             {if ($pos = 1)
                             then <text text-anchor="start" x="500" y="10" font-family="Arial" font-size="11" font-weight="bold" stroke="none" stroke-width="0" fill="#666666">alle Sprüche</text>
                             else ()}
                             <text text-anchor="start" x="500" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#666666">{data($geschlecht)}</text>
                             <text text-anchor="start" x="550" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#666666">({$prozent}%)</text>
                             <path title="alle Sprüche, {$label}: {data($geschlecht)} ({$prozent}%)" d="M {$local:Mx} {$local:My} L {$local:Mx} {$local:My - $local:rGr} A {$local:rGr} {$local:rGr} 0 {$flag} 1 {$Ex} {$Ey}" stroke="white" fill="{$conf:colors2[$pos]}" stroke-width="1" transform="rotate({$winkelSum}, {$local:Mx}, {$local:My})" />
                           </g>
    return ($pfadeGr, $pfadeKl)
};

declare function local:regionen-chart-erstellen($spruch as node()) as node()*{
    let $spruchlabel := local:spruchlabel-erstellen($spruch)
    let $spruchParam := concat($spruch, "-", "V", $spruch, "-", $spruch, "V")
    (: Pfade des kleinen Kreises (= einzelner Spruch) für das Regionen-Pie-Chart bestimmen :)
     let $pfadeKlRegion := for $region at $pos in $tb-update:spruchzahlenRegionen//spruch[@name = $spruch]/region
                 let $label := $region/data(@name)
                 let $prozent := $region/ceiling(@prozent)
                (: Endpunkt des Kreissegments berechnen :)
                 let $winkelZumEndpunkt := if ($region/@prozent = '100') 
                                           then 359
                                           else $region/@prozent * 3.6
                 let $winkelRad := math:radians($winkelZumEndpunkt)
                 let $Ex := math:sin($winkelRad) * $local:rK + $local:rK
                 let $Ey := $local:rK - math:cos($winkelRad) * $local:rK
                 (: den Abstand vom Rand des Koordinatensystems zum Kreis berücksichtigen :)
                 let $Ex := $Ex + $local:Mx - $local:rK
                 let $Ey := $Ey + $local:My - $local:rK
                 (: Rotationswinkel des Kreissegmentes berechnen (= Summe der Endpunktwinkel der vorangehenden Segmente) :)
                 let $winkelSum := sum(for $prec in $region/preceding-sibling::region
                                       return $prec/@prozent * 3.6)
                 (: Sweep-Flag :)
                 let $flag := if ($winkelZumEndpunkt gt 180)
                              then 1
                              else 0
                 return <g xmlns:xlink="http://www.w3.org/1999/xlink">
                            <rect x="260" y="{$pos * 20}" width="11" height="11" stroke="none" stroke-width="0" fill="{$conf:colors[$pos]}"/>
                            <text text-anchor="start" x="275" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#666666">{$label}</text>
                            {if ($pos = 1)
                            then <text text-anchor="start" x="370" y="10" font-family="Arial" font-size="11" font-weight="bold" stroke="none" stroke-width="0" fill="#666666">{$spruchlabel}</text>
                            else ()}
                            <a xlink:href="/liste?region={$label}&amp;spruch={$spruchParam}" title="Objekte anzeigen" class="svgTextLink"><text text-anchor="start" x="370" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#2381AE">{data($region)}</text></a>
                            <text text-anchor="start" x="400" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#666666">({$prozent}%)</text>
                            <a xlink:href="/liste?region={$label}&amp;spruch={$spruchParam}" class="svgPieLink"><path title="{$spruchlabel}, {$label}: {data($region)} ({$prozent}%)" d="M {$local:Mx} {$local:My} L {$local:Mx} {$local:My - $local:rK} A {$local:rK} {$local:rK} 0 {$flag} 1 {$Ex} {$Ey} Z" stroke="white" fill="{$conf:colors[$pos]}" stroke-width="1" transform="rotate({$winkelSum}, {$local:Mx}, {$local:My})" /></a>
                         </g>
    (: Pfade des großen Kreises (= alle Sprüche) für das Regionen-Pie-Chart bestimmen :)  
    let $pfadeGrRegion := for $region at $pos in $tb-update:spruchzahlenRegionen//spruch[@name = "alle"]/region
                    let $label := $region/data(@name)
                    let $prozent := $region/ceiling(@prozent)
                    (: Endpunkt des Kreissegments berechnen :)
                    let $winkelZumEndpunkt := $region/@prozent * 3.6
                    let $winkelRad := math:radians($winkelZumEndpunkt)
                    let $Ex := math:sin($winkelRad) * $local:rGr + $local:rGr
                    let $Ey := $local:rGr - math:cos($winkelRad) * $local:rGr
                    (: den Abstand vom Rand des Koordinatensystems zum Kreis berücksichtigen :)
                    let $Ex := $Ex + $local:Mx - $local:rGr
                    let $Ey := $Ey + $local:My - $local:rGr
                    (: Rotationswinkel des Kreissegmentes berechnen (= Summe der Endpunktwinkel der vorangehenden Segmente) :)
                    let $winkelSum := sum(for $prec in $region/preceding-sibling::region
                                          return $prec/@prozent * 3.6)
                    (: Sweep-Flag :)
                    let $flag := if ($winkelZumEndpunkt gt 180)
                                 then 1
                                 else 0
                    return <g>
                             {if ($pos = 1)
                             then <text text-anchor="start" x="500" y="10" font-family="Arial" font-size="11" font-weight="bold" stroke="none" stroke-width="0" fill="#666666">alle Sprüche</text>
                             else ()}
                             <text text-anchor="start" x="500" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#666666">{data($region)}</text>
                             <text text-anchor="start" x="550" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#666666">({$prozent}%)</text>
                             <path title="alle Sprüche, {$label}: {data($region)} ({$prozent}%)" d="M {$local:Mx} {$local:My} L {$local:Mx} {$local:My - $local:rGr} A {$local:rGr} {$local:rGr} 0 {$flag} 1 {$Ex} {$Ey}" stroke="white" fill="{$conf:colors2[$pos]}" stroke-width="1" transform="rotate({$winkelSum}, {$local:Mx}, {$local:My})" />
                           </g>
 return ($pfadeGrRegion, $pfadeKlRegion)
};

declare function local:spruchart-chart-erstellen($spruch as node()) as node()*{
let $spruchlabel := local:spruchlabel-erstellen($spruch)
let $spruchParam := concat($spruch, "-", "V", $spruch, "-", $spruch, "V")
(: Pfade des kleinen Kreises (= einzelner Spruch) für das Spruchart-Pie-Chart bestimmen :)
 let $pfadeKlSpruchart := for $art at $pos in $tb-update:spruchzahlenObjekte//spruch[@name = $spruch]/objektzahlen/child::*[not(name() = 'gesamt')]
             let $label := let $art := $art/name()
                           return
                              if ($art = "nurSpruch")
                              then "Text"
                              else if ($art = "nurVignette")
                              then "Vignette"
                              else if ($art = "spruchUndVignette")
                              then "Text und Vignette"
                              else "unsicher identifiziert"
             let $artWert := lower-case(replace($label, "\s", "-"))
             let $prozent := $art/ceiling(@prozent)
            (: Endpunkt des Kreissegments berechnen :)
             let $winkelZumEndpunkt := if ($art/@prozent = '100') 
                                       then 359
                                       else $art/@prozent * 3.6
             let $winkelRad := math:radians($winkelZumEndpunkt)
             let $Ex := math:sin($winkelRad) * $local:rK + $local:rK
            let $Ey := $local:rK - math:cos($winkelRad) * $local:rK
            (: den Abstand vom Rand des Koordinatensystems zum Kreis berücksichtigen :)
            let $Ex := $Ex + $local:Mx - $local:rK
            let $Ey := $Ey + $local:My - $local:rK
             (: Rotationswinkel des Kreissegmentes berechnen (= Summe der Endpunktwinkel der vorangehenden Segmente) :)
             let $winkelSum := sum(for $prec in $art/preceding-sibling::*[not(name() = 'gesamt')]
                                   return $prec/@prozent * 3.6)
             (: Sweep-Flag :)
             let $flag := if ($winkelZumEndpunkt gt 180)
                          then 1
                          else 0
             return <g xmlns:xlink="http://www.w3.org/1999/xlink">
                        <rect x="260" y="{$pos * 20}" width="11" height="11" stroke="none" stroke-width="0" fill="{$conf:colors[$pos]}"/>
                        <text text-anchor="start" x="275" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#666666">{$label}</text>
                        {if ($pos = 1)
                        then <text text-anchor="start" x="400" y="10" font-family="Arial" font-size="11" font-weight="bold" stroke="none" stroke-width="0" fill="#666666">{$spruchlabel}</text>
                        else ()}
                        <a xlink:href="/liste?spruchart={$artWert}&amp;spruchname={$spruch}" title="Objekte anzeigen" class="svgTextLink"><text text-anchor="start" x="400" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#2381AE">{data($art)}</text></a>
                        <text text-anchor="start" x="430" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#666666">({$prozent}%)</text>
                        <a xlink:href="/liste?spruchart={$artWert}&amp;spruchname={$spruch}" class="svgPieLink"><path title="{$spruchlabel}, {$label}: {data($art)} ({$prozent}%)" d="M {$local:Mx} {$local:My} L {$local:Mx} {$local:My - $local:rK} A {$local:rK} {$local:rK} 0 {$flag} 1 {$Ex} {$Ey} Z" stroke="white" fill="{$conf:colors[$pos]}" stroke-width="1" transform="rotate({$winkelSum}, {$local:Mx}, {$local:My})" /></a>
                     </g>
 (: Pfade des großen Kreises (= alle Sprüche) für das Spruchart-Pie-Chart bestimmen :)  
    let $pfadeGrSpruchart := for $art at $pos in $tb-update:spruchzahlenObjekte//spruch[@name = "alle"]/objektzahlen/child::*[not(name() = 'gesamt')]
                    let $label := let $art := $art/name()
                                    return
                                       if ($art = "nurSpruch")
                                       then "Spruch"
                                       else if ($art = "nurVignette")
                                       then "Vignette"
                                       else if ($art = "spruchUndVignette")
                                       then "Spruch und Vignette"
                                       else "unsicher identifiziert"
                    let $prozent := $art/ceiling(@prozent)
                    (: Endpunkt des Kreissegments berechnen :)
                    let $winkelZumEndpunkt := $art/@prozent * 3.6
                    let $winkelRad := math:radians($winkelZumEndpunkt)
                    let $Ex := math:sin($winkelRad) * $local:rGr + $local:rGr
                    let $Ey := $local:rGr - math:cos($winkelRad) * $local:rGr
                    (: den Abstand vom Rand des Koordinatensystems zum Kreis berücksichtigen :)
                    let $Ex := $Ex + $local:Mx - $local:rGr
                    let $Ey := $Ey + $local:My - $local:rGr
                    (: Rotationswinkel des Kreissegmentes berechnen (= Summe der Endpunktwinkel der vorangehenden Segmente) :)
                    let $winkelSum := sum(for $prec in $art/preceding-sibling::*[not(name() = 'gesamt')]
                                          return $prec/@prozent * 3.6)
                    (: Sweep-Flag :)
                    let $flag := if ($winkelZumEndpunkt gt 180)
                                 then 1
                                 else 0
                    return <g>
                             {if ($pos = 1)
                             then <text text-anchor="start" x="520" y="10" font-family="Arial" font-size="11" font-weight="bold" stroke="none" stroke-width="0" fill="#666666">alle Sprüche</text>
                             else ()}
                             <text text-anchor="start" x="520" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#666666">{data($art)}</text>
                             <text text-anchor="start" x="570" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#666666">({$prozent}%)</text>
                             <path title="alle Sprüche, {$label}: {data($art)} ({$prozent}%)" d="M {$local:Mx} {$local:My} L {$local:Mx} {$local:My - $local:rGr} A {$local:rGr} {$local:rGr} 0 {$flag} 1 {$Ex} {$Ey}" stroke="white" fill="{$conf:colors2[$pos]}" stroke-width="1" transform="rotate({$winkelSum}, {$local:Mx}, {$local:My})" />
                           </g>
 return ($pfadeGrSpruchart, $pfadeKlSpruchart)
};

declare function local:objektgruppen-chart-erstellen($spruch as node()) as node()*{
    let $spruchlabel := local:spruchlabel-erstellen($spruch)
    let $spruchParam := concat($spruch, "-", "V", $spruch, "-", $spruch, "V")
    (: Pfade des kleinen Kreises (= Einzelspruch) für das Objektgruppen-Pie-Chart :)
    let $pfadeKlObjektgr := for $objgr at $pos in $tb-update:spruchzahlenObjektgruppen//spruch[@name = $spruch]/objektgruppe
                            let $label := $objgr/data(@name)
                             let $prozent := $objgr/ceiling(@prozent)
                            (: Endpunkt des Kreissegments berechnen :)
                             let $winkelZumEndpunkt := if ($objgr/@prozent = '100') 
                                                       then 359
                                                       else $objgr/@prozent * 3.6
                             let $winkelRad := math:radians($winkelZumEndpunkt)
                             let $winkelRad := math:radians($winkelZumEndpunkt)
                            let $Ex := math:sin($winkelRad) * $local:rK + $local:rK
                            let $Ey := $local:rK - math:cos($winkelRad) * $local:rK
                            (: den Abstand vom Rand des Koordinatensystems zum Kreis berücksichtigen :)
                            let $Ex := $Ex + $local:Mx - $local:rK
                            let $Ey := $Ey + $local:My - $local:rK
                             (: Rotationswinkel des Kreissegmentes berechnen (= Summe der Endpunktwinkel der vorangehenden Segmente) :)
                             let $winkelSum := sum(for $prec in $objgr/preceding-sibling::objektgruppe
                                                   return $prec/@prozent * 3.6)
                             (: Sweep-Flag :)
                             let $flag := if ($winkelZumEndpunkt gt 180)
                                          then 1
                                          else 0
                             return <g xmlns:xlink="http://www.w3.org/1999/xlink">
                                        <rect x="270" y="{$pos * 20}" width="11" height="11" stroke="none" stroke-width="0" fill="{$conf:colors[$pos]}"/>
                                        <text text-anchor="start" x="285" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#666666">{$label}</text>
                                        {if ($pos = 1)
                                        then <text text-anchor="start" x="400" y="10" font-family="Arial" font-size="11" font-weight="bold" stroke="none" stroke-width="0" fill="#666666">{$spruchlabel}</text>
                                        else ()}
                                        <a xlink:href="/liste?objektgruppe={$label}&amp;spruch={$spruchParam}" title="Objekte anzeigen" class="svgTextLink"><text text-anchor="start" x="400" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#2381AE">{data($objgr)}</text></a>
                                        <text text-anchor="start" x="430" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#666666">({$prozent}%)</text>
                                        <a xlink:href="/liste?objektgruppe={$label}&amp;spruch={$spruchParam}" class="svgPieLink"><path title="{$spruchlabel}, {$label}: {data($objgr)} ({$prozent}%)" d="M {$local:Mx} {$local:My} L {$local:Mx} {$local:My - $local:rK} A {$local:rK} {$local:rK} 0 {$flag} 1 {$Ex} {$Ey} Z" stroke="white" fill="{$conf:colors[$pos]}" stroke-width="1" transform="rotate({$winkelSum}, {$local:Mx}, {$local:My})" /></a>
                                     </g>
    (: Pfade des großen Kreises (= alle Sprüche) für das Objektgruppen-Pie-Chart :)
    let $pfadeGrObjektgr := for $objgr at $pos in $tb-update:spruchzahlenObjektgruppen//spruch[@name = "alle"]/objektgruppe
                            let $label := $objgr/data(@name)
                            let $prozent := $objgr/ceiling(@prozent)
                            (: Endpunkt des Kreissegments berechnen :)
                            let $winkelZumEndpunkt := $objgr/@prozent * 3.6
                            let $winkelRad := math:radians($winkelZumEndpunkt)
                            let $Ex := math:sin($winkelRad) * $local:rGr + $local:rGr
                            let $Ey := $local:rGr - math:cos($winkelRad) * $local:rGr
                            (: den Abstand vom Rand des Koordinatensystems zum Kreis berücksichtigen :)
                            let $Ex := $Ex + $local:Mx - $local:rGr
                            let $Ey := $Ey + $local:My - $local:rGr
                            (: Rotationswinkel des Kreissegmentes berechnen (= Summe der Endpunktwinkel der vorangehenden Segmente) :)
                            let $winkelSum := sum(for $prec in $objgr/preceding-sibling::objektgruppe
                                                  return $prec/@prozent * 3.6)
                            (: Sweep-Flag :)
                            let $flag := if ($winkelZumEndpunkt gt 180)
                                         then 1
                                         else 0
                            return <g>
                                     {if ($pos = 1)
                                     then <text text-anchor="start" x="510" y="10" font-family="Arial" font-size="11" font-weight="bold" stroke="none" stroke-width="0" fill="#666666">alle Sprüche</text>
                                     else ()}
                                     <text text-anchor="start" x="510" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#666666">{data($objgr)}</text>
                                     <text text-anchor="start" x="560" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#666666">({$prozent}%)</text>
                                     <path title="alle Sprüche, {$label}: {data($objgr)} ({$prozent}%)" d="M {$local:Mx} {$local:My} L {$local:Mx} {$local:My - $local:rGr} A {$local:rGr} {$local:rGr} 0 {$flag} 1 {$Ex} {$Ey}" stroke="white" fill="{$conf:colors2[$pos]}" stroke-width="1" transform="rotate({$winkelSum}, {$local:Mx}, {$local:My})" />
                                   </g>
   return ($pfadeGrObjektgr, $pfadeKlObjektgr)
};

declare function local:schrift-chart-erstellen($spruch as node()) as node()*{
    let $spruchlabel := local:spruchlabel-erstellen($spruch)
    let $spruchParam := concat($spruch, "-", "V", $spruch, "-", $spruch, "V")
    (: Pfade des kleinen Kreises (= einzelner Spruch) bestimmen :)
    let $pfadeKl := for $schrift at $pos in $tb-update:spruchzahlenSchrift//spruch[@name = data($spruch)]/schrift
                    let $label := if ($schrift/data(@name) = "keine Schrift vorhanden")
                                  then "keine vorhanden"
                                  else $schrift/data(@name)
                    let $prozent := $schrift/ceiling(@prozent)
                    (: Endpunkt des Kreissegments berechnen :)
                    let $winkelZumEndpunkt := if ($schrift/@prozent = '100') 
                                              then 359
                                              else $schrift/@prozent * 3.6
                    let $winkelRad := math:radians($winkelZumEndpunkt)
                    let $Ex := math:sin($winkelRad) * $local:rK + $local:rK
                    let $Ey := $local:rK - math:cos($winkelRad) * $local:rK
                    (: den Abstand vom Rand des Koordinatensystems zum Kreis berücksichtigen :)
                    let $Ex := $Ex + $local:Mx - $local:rK
                    let $Ey := $Ey + $local:My - $local:rK
                    (: Rotationswinkel des Kreissegmentes berechnen (= Summe der Endpunktwinkel der vorangehenden Segmente) :)
                    let $winkelSum := sum(for $prec in $schrift/preceding-sibling::schrift
                                          return $prec/@prozent * 3.6)
                    (: Sweep-Flag :)
                    let $flag := if ($winkelZumEndpunkt gt 180)
                                 then 1
                                 else 0
                    return <g xmlns:xlink="http://www.w3.org/1999/xlink">
                               <rect x="260" y="{$pos * 20}" width="11" height="11" stroke="none" stroke-width="0" fill="{$conf:colors[$pos]}"/>
                               <text text-anchor="start" x="275" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#666666">{$label}</text>
                               {if ($pos = 1)
                               then <text text-anchor="start" x="370" y="10" font-family="Arial" font-size="11" font-weight="bold" stroke="none" stroke-width="0" fill="#666666">{$spruchlabel}</text>
                               else ()}
                               <a xlink:href="/liste?schrift={data($schrift/@name)}&amp;spruch={$spruchParam}" title="Objekte anzeigen" class="svgTextLink"><text text-anchor="start" x="370" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#2381AE">{data($schrift)}</text></a>
                               <text text-anchor="start" x="400" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#666666">({$prozent}%)</text>
                               <a xlink:href="/liste?schrift={data($schrift/@name)}&amp;spruch={$spruchParam}" class="svgPieLink"><path title="{$spruchlabel}, {$label}: {data($schrift)} ({$prozent}%)" d="M {$local:Mx} {$local:My} L {$local:Mx} {$local:My - $local:rK} A {$local:rK} {$local:rK} 0 {$flag} 1 {$Ex} {$Ey} Z" stroke="white" fill="{$conf:colors[$pos]}" stroke-width="1" transform="rotate({$winkelSum}, {$local:Mx}, {$local:My})" /></a>
                            </g>
    (: Pfade des großen Kreises (= alle Sprüche) bestimmen :)  
    let $pfadeGr := for $schrift at $pos in $tb-update:spruchzahlenSchrift//spruch[@name = "alle"]/schrift
                let $label := if ($schrift/data(@name) = "keine Schrift vorhanden")
                              then "keine vorhanden"
                              else $schrift/data(@name)
                let $prozent := $schrift/ceiling(@prozent)
                (: Endpunkt des Kreissegments berechnen :)
                let $winkelZumEndpunkt := $schrift/@prozent * 3.6
                let $winkelRad := math:radians($winkelZumEndpunkt)
                let $Ex := math:sin($winkelRad) * $local:rGr + $local:rGr
                let $Ey := $local:rGr - math:cos($winkelRad) * $local:rGr
                (: den Abstand vom Rand des Koordinatensystems zum Kreis berücksichtigen :)
                let $Ex := $Ex + $local:Mx - $local:rGr
                let $Ey := $Ey + $local:My - $local:rGr
                (: Rotationswinkel des Kreissegmentes berechnen (= Summe der Endpunktwinkel der vorangehenden Segmente) :)
                let $winkelSum := sum(for $prec in $schrift/preceding-sibling::schrift
                                      return $prec/@prozent * 3.6)
                (: Sweep-Flag :)
                let $flag := if ($winkelZumEndpunkt gt 180)
                             then 1
                             else 0
                return <g xmlns:xlink="http://www.w3.org/1999/xlink">
                         {if ($pos = 1)
                         then <text text-anchor="start" x="500" y="10" font-family="Arial" font-size="11" font-weight="bold" stroke="none" stroke-width="0" fill="#666666">alle Sprüche</text>
                         else ()}
                         <text text-anchor="start" x="500" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#666666">{data($schrift)}</text>
                         <text text-anchor="start" x="550" y="{$pos * 20 + 10}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#666666">({$prozent}%)</text>
                         <path title="alle Sprüche, {$label}: {data($schrift)} ({$prozent}%)" d="M {$local:Mx} {$local:My} L {$local:Mx} {$local:My - $local:rGr} A {$local:rGr} {$local:rGr} 0 {$flag} 1 {$Ex} {$Ey}" stroke="white" fill="{$conf:colors2[$pos]}" stroke-width="1" transform="rotate({$winkelSum}, {$local:Mx}, {$local:My})" />
                       </g>
   return ($pfadeGr, $pfadeKl)
};

declare function local:motivliste-erstellen($spruch as node()) as node()+{
    let $wissen := collection("/db/totenbuch/knowledge")
    let $sprueche := $wissen//skizze/spruch[. = $spruch]
    return
        if ($sprueche)
        then (<div id="Umzeichnungen">
                 <h2>Vignettenumzeichnungen</h2>
                 <div class="abbildungen">
                   <ul>
                   {for $skizze in $wissen//skizzen/skizze[spruch = $spruch]
                    let $dateiname := substring-before(replace($skizze/@url, '.([a-zA-Z]+)$', '#$1'), '#')
                    let $thumbnail := concat($dateiname, '_s.jpg')
                    let $max := concat($dateiname, '.jpg')
                    return
                        <li>
                            <a dojoType="dojox.image.LightboxCostum" group="{$spruch}" href="/motifs/{$max}" title="{$dateiname}">
                                <img src="/motifs/{$thumbnail}" alt="{$dateiname}"/>
                            </a>
                            <p class="caption">  
                                Objekt: {let $tm := $tb-update:objekte[@id = $skizze/@objekt-id]/@tm
                                            return <a href="/objekt/tm{data($tm)}">TM {data($tm)}</a>}, 
                                Motive: {let $motive := $skizze/motiv
                                         let $motive := for $motiv in $motive
                                                        order by $motiv collation "http://exist-db.org/collation?lang=DE"
                                                        return $motiv
                                         let $anzahlMotive := count($motive)
                                         for $motiv at $pos in $motive
                                         return (<a href="/register/motive-gruppen#{data($motiv)}" title="zum Register">{data($motiv)}</a>,
                                                if ($pos lt $anzahlMotive)
                                                then ", "
                                                else ())}
                            </p>
                        </li>}
                    </ul>
                </div>
            </div>, 
            <div id="Motive">
                <h2>Motive</h2>
                <p>Die folgende Liste umfasst die Motive, die auf den Vignetten zu Spruch {$spruch} vorkommen. 
                Sie verweist auch auf Umzeichnungen anderer Vignetten, die dieselben Motive enthalten.</p>
                <ul>
                    {for $motiv at $motivPos in distinct-values($sprueche/preceding-sibling::motiv)
                    order by $motiv collation "http://exist-db.org/collation?lang=DE"
                    return
                        <li class="{if ($motivPos mod 2 = 0) then 'even' else 'odd'}">
                            <span class="motivname">{$motiv}</span> <span class="gruppenname"><strong>Gruppe: </strong> {$wissen//motive//motiv[@name = $motiv]/parent::gruppe/data(@name)}</span>
                            <span id="UmzOn-{$motivPos}" class="link onInline" onclick="dojo.byId('Abbildungen-{$motivPos}').className = 'abbildungen onBlock', dojo.byId('UmzOn-{$motivPos}').className = 'link offDis', dojo.byId('UmzOff-{$motivPos}').className = 'link onInline';"><span class="link-mehr">Vignettenumzeichnungen anzeigen</span></span>
                            <span id="UmzOff-{$motivPos}" class="link offDis" onclick="dojo.byId('Abbildungen-{$motivPos}').className = 'abbildungen offDis', dojo.byId('UmzOff-{$motivPos}').className = 'link offDis', dojo.byId('UmzOn-{$motivPos}').className = 'link onInline';"><span class="link-weniger">Vignettenumzeichnungen ausblenden</span></span>
                            <span class="registerlink"><a href="/register/motive-gruppen#{$motiv}" title="zum Register"><img alt="zum Register" src="/icons/index.png" /></a></span>
                            <div id="Abbildungen-{$motivPos}" class="abbildungen offDis">
                                <ul>{for $skizze in $wissen//skizzen/skizze[motiv = $motiv]
                                 let $dateiname := substring-before(replace($skizze/@url, '.([a-zA-Z]+)$', '#$1'), '#')
                                 let $thumbnail := concat($dateiname, '_s.jpg')
                                 let $max := concat($dateiname, '.jpg')
                                 return
                                    <li>
                                        <a dojoType="dojox.image.LightboxCostum" group="{$motiv}" href="/motifs/{$max}" title="{$dateiname}">
                                            <img src="/motifs/{$thumbnail}" alt="{$dateiname}"/>
                                        </a>
                                        <p class="caption">
                                            Objekt: {let $tm := $tb-update:objekte[@id = $skizze/@objekt-id]/@tm
                                            return <a href="/objekt/tm{data($tm)}">TM {data($tm)}</a>}, 
                                            {if (count($skizze/spruch) gt 1)
                                             then "Sprüche: "
                                             else "Spruch: "}
                                             {for $spruch at $pos in $skizze/spruch
                                             return (<a href="/spruch/{replace($spruch, '/', '-')}">{data($spruch)}</a>,
                                                    if ($pos != count($skizze/spruch))
                                                    then ", "
                                                    else ())}
                                        </p>
                                    </li>
                                }</ul>
                            </div>
                        </li>
                    }
                </ul>
            </div>)
        else (<div id="Umzeichnungen">
                <h2>Vignettenumzeichnungen</h2>
                <p>Es liegen keine Vignettenumzeichnungen zu diesem Spruch vor.</p>
             </div>, 
             <div id="Motive">
                <h2>Motive</h2>
                <p>Zu diesem Spruch liegen keine Vignettenumzeichnungen mit Motiven vor.</p>
             </div>)
};

let $wissen := collection("/db/totenbuch/knowledge")
let $colors := for $color at $pos in $conf:colors
                let $color := concat("'", $color, "'")
                return if ($pos != count($conf:colors))
                       then concat($color, ",")
                       else $color
(: Text und Charts für die einzelnen Sprüche generieren :)
let $spruchAuswahl := ("172 (Pleyte)/1B")
let $spruchseiten := for $spruch at $pos in $tb-update:sprueche[. = $spruchAuswahl]
                     let $link := replace($spruch, "/", "-")
                     let $link := lower-case($link)
                     let $link := replace($link, " ", "-")
                     let $bibliografie := local:bibliografie-erstellen($spruch)
                     let $spruchParam := concat($spruch, "-", "V", $spruch, "-", $spruch, "V")
                     let $spruchlabel := local:spruchlabel-erstellen($spruch)
                     let $ueberschrift := (if (ngram:contains($spruch, "Spruch")) 
                                          then ()
                                          else if (ngram:contains($spruch, "Vignette"))
                                          then ()
                                          else if ($spruch = ("Ausserordentliches Textgut", "Mythologische Szenen", "Leinenamulette", "Buch vom Atmen", "Jenseitsführer", "Hymnen und Gebete", "Ritualtext", "Verklärung"))
                                          then ()
                                          else "Spruch",
                                          data($spruch))
                     let $spruchzahl := $tb-update:spruchzahlenObjekte//spruch[@name = $spruch]//gesamt
                     let $rang := count($tb-update:spruchzahlenObjekte//spruch[@name = $spruch]/preceding-sibling::spruch)
                     let $nachweise := local:nachweise-erstellen($spruch)
                     let $schriftChart := local:schrift-chart-erstellen($spruch)
                     let $geschlechterChart := local:geschlechter-chart-erstellen($spruch)
                     let $regionenChart := local:regionen-chart-erstellen($spruch)
                     let $spruchartChart := local:spruchart-chart-erstellen($spruch)
                     let $objektgruppenChart := local:objektgruppen-chart-erstellen($spruch)
                    let $periodenZahlenJS := let $rows := for $periode in $tb-update:spruchzahlenPerioden//spruch[@name = $spruch]/periode
                                                          let $einzeln := $periode/ceiling(@prozent) div 100
                                                          let $gesamt := $tb-update:spruchzahlenPerioden//spruch[@name = 'alle']/periode[@name = $periode/@name]/ceiling(@prozent) div 100
                                                          return concat("['", $periode/@name, "',", data($gesamt), ",", data($einzeln), "]")
                                             return string-join($rows, ", ")
                    let $nachbarnSpruchzahlen := $tb-update:spruchzahlenNachbarn//spruch[@name = $spruch]/nachbar[spruch != $spruch] (: den akt. Spruch ausschließen! :)
                    let $nachbarnJS := let $nachbarn := for $nachbar in $nachbarnSpruchzahlen[position() = 1 to 5]
                                                        let $quote := $nachbar/haeufigkeit/data(@prozent)
                                                        let $quote := ceiling($quote * 100)
                                                        let $quote := if (not($quote)) then 0 else $quote
                                                        let $quoteRevers := $tb-update:spruchzahlenNachbarn//spruch[@name = $nachbar/spruch]/nachbar[spruch = $spruch]/haeufigkeit/data(@prozent)
                                                        let $quoteRevers := ceiling($quoteRevers * 100)
                                                        let $quoteRevers := if (not($quoteRevers)) then 0 else $quoteRevers
                                                        let $link := replace($nachbar/data(spruch), "/", "-")
                                                        let $link := lower-case($link)
                                                        let $link := replace($link, " ", "-")
                                                        return concat("['<a href=&quot;/spruch/", $link, "&quot;>", $nachbar/data(spruch), "</a>',", $nachbar/data(haeufigkeit), ",", $quote, ",", $quoteRevers, "]")
                                       let $nachbarn := string-join($nachbarn, ", ")
                                       return concat("<span>", $nachbarn, "</span>")
                    let $nachbarnJSAll := let $nachbarn := for $nachbar in $nachbarnSpruchzahlen
                                                        let $quote := $nachbar/haeufigkeit/data(@prozent)
                                                        let $quote := ceiling($quote * 100)
                                                        let $quote := if (not($quote)) then 0 else $quote
                                                        let $quoteRevers := $tb-update:spruchzahlenNachbarn//spruch[@name = $nachbar/spruch]/nachbar[spruch = $spruch]/haeufigkeit/data(@prozent)
                                                        let $quoteRevers := ceiling($quoteRevers * 100)
                                                        let $quoteRevers := if (not($quoteRevers)) then 0 else $quoteRevers
                                                        let $link := replace($nachbar/data(spruch), "/", "-")
                                                        let $link := lower-case($link)
                                                        let $link := replace($link, " ", "-")
                                                        return concat("['<a href=&quot;/spruch/", $link, "&quot;>", $nachbar/data(spruch), "</a>',", $nachbar/data(haeufigkeit), ",", $quote, ",", $quoteRevers, "]")
                                       let $nachbarn := string-join($nachbarn, ", ")
                                       return concat("<span>", $nachbarn, "</span>")
                    let $circles := (: maximale Größe des Grafikbereichs :)
                                    let $max := 300
                                    (: der häufigste Nachbar als Ausgangspunkt für das Maß :)
                                    let $mass := ($max -100) div $nachbarnSpruchzahlen[1]/data(haeufigkeit)
                                    (: Rotationswinkel für die Verbindungslinien :)
                                     let $winkel := (-60, -20, 20, 60, 100, 140, 180, 220)
                                     for $nachbar at $pos in $nachbarnSpruchzahlen[position() = 1 to 8]
                                     let $gewicht := $nachbar/data(haeufigkeit) * $mass
                                     (: Zentrum des Nachbarpunktes :)
                                     let $zentrum := 325 + (($max - $gewicht) div 2)
                                     (: Punkt, an dem der Beschriftungstext ansetzen soll :)
                                     let $textX := if ($zentrum = 0) then 12 else $zentrum + 7
                                     let $textY := 325 + 5
                                     (: um wieviel der Text verschoben werden muss, wenn der Winkel über 90 Grad ist :)
                                     let $transX := -($textX * 2)
                                     let $transY := - 650
                                     return
                                        (<line x1="{if ($zentrum = 0) then 5 else $zentrum}" y1="325" x2="325" y2="325" stroke="#2381AE" stroke-width="{$gewicht div 100 + 1}" transform="rotate({$winkel[$pos]}, 325, 325)">
                                           <title>{data($spruch)} - {data($nachbar/spruch)} ({data($nachbar/haeufigkeit)}x)</title>
                                        </line>,
                                        <circle cx="{if ($zentrum = 0) then 5 else $zentrum}" cy="325" r="5" fill="#2381AE" transform="rotate({$winkel[$pos]}, 325, 325)">
                                           <title>{$nachbar/data(spruch)}</title>
                                        </circle>,
                                        <a xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="/spruch/{replace(lower-case($nachbar/spruch), '\s', '-')}" class="svgTextLink" title="zur Spruchseite"><text text-anchor="{if ($winkel[$pos] gt 90) then 'end' else 'start'}" x="{$textX}" y="{$textY}" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#2381AE" transform="rotate({$winkel[$pos]}, 325, 325) {if ($winkel[$pos] gt 90) then concat(',scale(-1,-1), translate(', $transX, ',',$transY, ')') else()}">{data($nachbar/spruch)}</text></a>)
                    let $motive := local:motivliste-erstellen($spruch)
                    let $navigation := local:navigation-erstellen($spruch, $pos)
                    return
                        <div class="sprueche">
                            <div id="SpruchHeader">
                                <h1>{$ueberschrift}</h1>
                                {$navigation}
                            </div>
                            <ul class="Navigation">
                                <li><a href="#NachweiseSpruchtext">Übersetzungen des Spruchtextes</a></li>
                                <li><a href="#Spruchvorkommen">Spruchvorkommen</a></li>
                                <li><a href="#NachHerkunft">Nach Herkunft</a></li>
                                <li><a href="#NachPerioden">Nach Epochen</a></li>
                                <li><a href="#NachObjektgruppen">Nach Objektgruppen</a></li>
                                <li><a href="#NachGeschlechtBesitzer">Nach Geschlecht der Besitzer</a></li>
                                <li><a href="#NachSchriften">Nach Schriften</a></li>
                                {if ($spruch = ("Buch vom Atmen", "Hymnen und Gebete", "Ritualtext", "Verklärung", "Jenseitsführer", "Leinenamulette", "Ausserordentliches Textgut"))
                                then ()
                                else
                                 <li><a href="#TextVignette">Vorkommen als Text und Vignette</a></li>
                                }
                                <li><a href="#Umzeichnungen">Vignettenumzeichnungen</a></li>
                                <li><a href="#Motive">Motive</a></li>
                                <li><a href="#BenachbarteSprueche">Benachbarte Sprüche</a></li>
                                <li><a href="#Bibliografie">Bibliografie</a></li>
                            </ul>
                            <!-- Spruchtext ausgeben -->
                            <div id="NachweiseSpruchtext">
                               <h2>Übersetzungen des Spruchtextes</h2>
                               {if (exists($nachweise))
                               then $nachweise
                               else "Es liegen keine Übersetzungen vor."}
                             </div>
                            <div>
                             <div id="Spruchvorkommen">
                                <h2>Spruchvorkommen</h2>
                                <!-- auf wie vielen Objekten kommt der Spruch vor? -->
                                <p>Der Spruch kommt auf <a href="/liste?spruch={$spruchParam}" title="Objekte anzeigen">{data($spruchzahl)} Objekt{if (data($spruchzahl) != "1") then "en" else()}</a> vor. Die Häufigkeit betreffend steht er damit an {$rang}. Stelle.</p>
                                <script type="text/javascript" src="https://www.google.com/jsapi"/>
                               </div>
                                <div id="NachHerkunft">
                                 <h2>Nach Herkunft</h2>
                                 <p>Die Zuordnung der Herkunftsorte zu Ober-, Mittel- und Unterägypten basiert auf einer groben Einteilung anhand von Breitengraden: größer als 29.7° für Unterägypten, zwischen 25.9° und und 29.7° für Mittelägypten und kleiner als 25.9° für Oberägypten.</p>
                                 <svg xmlns="http://www.w3.org/2000/svg" version="1.1" baseProfile="full" width="650" height="300">
                                    {$regionenChart}
                                </svg>
                               </div>
                               <div id="NachPerioden">
                                <h2>Nach Epochen</h2>
                                <script type="text/javascript">
                                  google.load('visualization', '1.0', &#123;'packages':['corechart']&#125;);
                                  google.setOnLoadCallback(drawCharts);
                                  
                                   function drawCharts()&#123;
                                        drawPeriodenAbsolut();
                                    &#125;
                                 </script>
                                <script type="text/javascript">
                                    function drawPeriodenAbsolut()&#123;
                                        var data = new google.visualization.DataTable();
                                        data.addColumn('string', 'Epochen');
                                        data.addColumn('number', 'Durchschnittliche Objektzahl für alle Sprüche');
                                        data.addColumn('number', &#34;Objektzahl {$spruchlabel}&#34;)
                                        data.addRows([
                                            {$periodenZahlenJS}
                                        ]);
                                        
                                    var chart = new google.visualization.ColumnChart(document.getElementById('PeriodenChart'));
                                    chart.draw(data, &#123;width: 650, height: 450,
                                              hAxis: &#123;title: 'Epoche', titleTextStyle: &#123;color: 'gray'&#125;&#125;,
                                              vAxis: &#123;title: 'Objektzahl', titleTextStyle: &#123;color: 'gray'&#125;, format: '##%'&#125;,
                                              chartArea:&#123;left:"10%", right:"5%", width:"85%", height:"55%", top: "10%", bottom: "35%"&#125;,
                                              legend: 'bottom',
                                              backgroundColor: &#34;{$conf:backgroundColor}&#34;,
                                              colors: [{$colors}]
                                            &#125;);
                                    &#125;
                                 </script>
                                <div id="PeriodenChart"></div>
                               </div>
                               <div id="NachObjektgruppen">
                                 <h2>Nach Objektgruppen</h2>
                                 <svg style="margin-top: 20px;" xmlns="http://www.w3.org/2000/svg" version="1.1" baseProfile="full" width="650" height="600">
                                    {$objektgruppenChart}
                                 </svg>
                                </div>
                               <div id="NachGeschlechtBesitzer">
                                <h2>Nach Geschlecht der Besitzer</h2>
                                <svg xmlns="http://www.w3.org/2000/svg" version="1.1" baseProfile="full" width="650" height="300">
                                    {$geschlechterChart}
                                </svg>
                               </div>
                               <div id="NachSchriften">
                                  <h2>Nach Schriften</h2>
                                  <svg xmlns="http://www.w3.org/2000/svg" version="1.1" baseProfile="full" width="650" height="300">
                                    {$schriftChart}
                                  </svg>
                               </div>
                               <!-- Diese Untersuchung NICHT für: Buch vom Atmen, Hymnen und Gebete, Ritualtext, Verklärung, Jenseitsführer, Leinenamulette, Ausserordentliches Textgut. -->
                               {if ($spruch = ("Buch vom Atmen", "Hymnen und Gebete", "Ritualtext", "Verklärung", "Jenseitsführer", "Leinenamulette", "Ausserordentliches Textgut"))
                               then ()
                               else
                               <div id="TextVignette">
                                 <h2>Vorkommen als Text und Vignette</h2>
                                 <!-- PIE CHART: wie oft kommt der Spruch mit/ohne Vignette vor? wie oft ist er unsicher identifiziert? etc. -->
                                 <svg style="margin-top: 20px;" xmlns="http://www.w3.org/2000/svg" version="1.1" baseProfile="full" width="650" height="300">
                                    {$spruchartChart}
                                </svg>
                               </div>}
                               {$motive}
                               <div id="BenachbarteSprueche">
                               {if (count($nachbarnSpruchzahlen) = 0)
                               then <div>
                                        <h2>Benachbarte Sprüche</h2>
                                        <p>Es gibt keine direkt benachbarten Sprüche.</p>
                                    </div>
                               else
                               <div>
                                <h2>Benachbarte Sprüche</h2>
                                <p>Es gibt {count($nachbarnSpruchzahlen)} verschiedene direkt benachbarte Sprüche.</p>
                                <p>Es wird kein Unterschied gemacht, ob ein Spruch als Text, als Vignette oder als Text mit Vignette vorkommt. 
                                Es wird ignoriert, ob die Identifikation eines Spruches auf einem Objekt unsicher ist. Es ist zu berücksichtigen, 
                                dass viele Objekte nur fragmentarisch vorliegen, so dass vielfach Lücken in der Spruchabfolge bestehen. Es werden 
                                keine Nachbarschaften über Lücken hinweg angenommen.</p>
                                <p>Berücksichtigt werden Sprüche auf Papyrus, Lederrollen, Mumienbinden und Leichentüchern. Nicht berücksichtigt werden 
                                Sprüche auf Särgen, Gräbern und Anderem (Möbel, Stelen, Tempel, etc.).</p>
                                <p>Wenn hier von "Sprüchen" die Rede ist, dann ist zu beachten, dass nur "kanonische" Sprüche aus einer definierten Spruchliste 
                                berücksichtigt werden. Bei der Beschreibung des Textbestandes (der "Sequenz") auf Objekten werden auch Sprüche erfasst, die nicht 
                                in dieser Liste stehen. Solche Sprüche unterbrechen die Nachbarschaft zwischen Sprüchen der "Positivliste".</p>
                                <p>Die häufigsten benachbarten Sprüche sind hier aufgelistet. Dabei bezeichnet die Spalte "Quote" die relative Häufigkeit des Nachbarn 
                                vom aktuellen Spruch aus gesehen und die Spalte "Quote revers" die relative Häufigkeit der Nachbarschaft ausgehend vom benachbarten Spruch.</p>
                                <script type="text/javascript">
                                    google.load('visualization', '1', &#123;packages:['table']&#125;);
                                    google.setOnLoadCallback(drawTable);
                                    function drawTable() &#123;
                                      var data = new google.visualization.DataTable();
                                      data.addColumn('string', 'benachbarter Spruch');
                                      data.addColumn('number', 'Häufigkeit (absolut)');
                                      data.addColumn('number', 'Quote (in %)');
                                      data.addColumn('number', 'Quote revers (in %)');
                                      data.addRows([
                                                    {let $str := util:eval($nachbarnJS)
                                                    for $node in $str/node()
                                                    return $node}
                                                   ]);
                                     var table = new google.visualization.Table(document.getElementById('NachbarTabelle'));
                                      table.draw(data, &#123;showRowNumber: false, allowHtml: true&#125;);
                                    &#125;
                                    function drawTableAll() &#123;
                                      var data = new google.visualization.DataTable();
                                      data.addColumn('string', 'benachbarter Spruch');
                                      data.addColumn('number', 'Häufigkeit');
                                      data.addColumn('number', 'Quote (in %)');
                                      data.addColumn('number', 'Quote revers (in %)');
                                      data.addRows([
                                                    {let $str := util:eval($nachbarnJSAll)
                                                    for $node in $str/node()
                                                    return $node}
                                                   ]);
                                     var table = new google.visualization.Table(document.getElementById('NachbarTabelle'));
                                      table.draw(data, &#123;showRowNumber: false, allowHtml: true&#125;);
                                    &#125;
                                </script>
                                <div id="NachbarTabellenWrap">
                                  <div>
                                    <div id="NachbarTabelle" style="width: 600px;"></div>
                                    <span class="link right" onclick="dojo.xhrGet(&#123;url: '/queries/tabelle-nachbarn.xql?show=all&amp;spruch={$spruch}',load: function(result)&#123;dojo.byId('NachbarTabellenWrap').innerHTML = result; drawTableAll();&#125;&#125;)">Alle anzeigen</span>
                                  </div>
                                </div>
                                <br />
                                <h3>Grafik der häufigsten Nachbarn</h3>
                                <p>Die Häufigkeit der Nachbarschaft wird durch die Dicke der Verbindungslinie und die Entfernung zum aktuellen Spruch (in der Mitte) widergespiegelt.</p>
                                <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" baseProfile="full" width="650" height="650" style="border: 1px solid #DDDDDD;">
                                    <!-- fünf Kreise für die häufigsten Nachbarn, jeweils mit Verbindungslinie zum Zentrum, der häufigste Nachbar liegt am nächsten und hat die dickste Verbindungslinie -->
                                    {$circles}
                                    <!-- Zentrum: der Spruch, um den es geht -->
                                    <circle cx="325" cy="325" r="5" fill="#669900">
                                        <title>{data($spruch)}</title>
                                    </circle>
                                    <a xlink:href="/spruch/{$link}" class="svgTextLink" title="zur Spruchseite"><text text-anchor="start" x="343" y="330" font-family="Arial" font-size="11" stroke="none" stroke-width="0" fill="#000000">{data($spruch)}</text></a>)
                                 </svg>
                                </div>
                                }
                               </div>
                                <div id="Bibliografie">
                                <h2>Bibliografie</h2>
                                {$bibliografie}
                             </div>
                            </div>
                        </div>
(: die Spruchseiten speichern :)
let $ergebnisse := for $seite at $pos in $spruchseiten
                (: let $dateiname := replace($tb-update:sprueche[$pos], "/", "-") :)
                let $dateiname := replace($spruchAuswahl[$pos], "/", "-")
                let $dateiname := lower-case($dateiname)
                let $dateiname := replace($dateiname, " ", "-")
                let $dateiname := concat($dateiname, ".xml")
                let $ueberschrift := data($seite/h1[1])
                let $ergebnis := util:catch("java.lang.Exception", xmldb:store("/db/totenbuch/static/spells", $dateiname, $seite), (concat("Exception: ", $util:exception-message), util:log("ERROR", $util:exception-message)))
                (: Meldung zurückgeben :)
                    return 
                        if (starts-with($ergebnis, "Exception: "))
                        then <li class="error">Fehler beim Aktualisieren der Einzelspruchseite für {$ueberschrift}: {$ergebnis}</li>
                        else 
                         <li>{$ueberschrift}</li>
return
    <div>
        <p>Folgende Einzelspruchseiten wurden aktualisiert:</p>
        <ul>
           {$ergebnisse}
        </ul>
    </div>