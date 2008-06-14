/*
    Titel:        NEO 2.0 beta Autohotkey-Treiber
    $Revision$
    $Date$
    Autor:        Stefan Mayer <stm (at) neo-layout.org>
    Basiert auf:  neo20-all-in-one.ahk vom 29.06.2007
        
    TODO:         - ausgiebig testen... (besonders Vollst�ndigkeit bei Deadkeys)
                  - Bessere L�sung f�r das leeren von PriorDeadKey finden, damit die Sondertasten
                    nicht mehr abgefangen werden m�ssen.
                  - Alt+Tab+Shift sollte Alt+Tab umkehrt
                  - Testen ob die Capslockl�sung (siehe *1:: ebene 1) auch f�r Numpad gebraucht wird
                  - Sind Ebenen vom Touchpad noch richtig?
                  - AltGr wird von Programmen wie Wort und Eclipse oft abgefangen :-(
                  - iota geht nicht
    
    Ideen:        - Symbol �ndern (Neo-Logo abwarten)
                  - bei Ebene 4 rechte Hand (Numpad) z.B. Numpad5 statt 5 senden
    CHANGEHISTORY: 
                  Aktuelle Revision (von Matthias Berg):
                  - Ebenen 1 bis 4 ausschalten per Umschalter siehe erste Codezeile
                     nurEbenenFuenfUndSechs = 0
                  - Mod4-Lock durch Mod4+Mod4
                  - EbenenAktualisierung neu geschrieben
                  - Ebene 6 �ber Mod3+Mod4
                  - Ebenen (besonders Matheebene) an Referenz angepasst
                    (allerdings kaum um Ebenen 1&2 gek�mmert, besonders Compose k�nnte noch �berholt werden)
                  Revision 525 (von Matthias Berg):
                  - Capslock bei Zahlen und Sonderzeichen ber�cksichtigt
                  Revision 524 (von Matthias Berg):
                  - umgekehrtes ^ f�r o, a, �,i  sowie f�r die grossen vokale ( 3. ton chinesisch)
                    � damit wird jetzt PinYin vollst�ndig unterst�tzt caron, macron, akut, grave auf uiaeo�
                  - Sonderzeichen senden wieder blind -> Shortcuts funktionieren, Capslock ist leider Shiftlock
                  Revision 523 (von Matthias Berg):
    			        - CapsLock geht jetzt auch bei allen Zeichen ('send Zeichen' statt 'send {blind} Zeichen')
                  - vertikale Ellipse eingebaut
                  - Umschalt+Umschalt f�r Capslock statt Mod3+Mod3
                  - bei Suspend wird jetzt wirklich togglesuspend aufgerufen (auch beim aktivieren per shift+pause)
                  Revsion 490 (von Stefan Mayer): 
                  - SUBSCRIPT von 0 bis 9 sowie (auf Ziffernblock) + und -
                    � auch bei Ziffernblock auf der 5. Ebene
                  - Kein Parsen �ber die Zwischenablage mehr
                  - Vista-kompatibel
                  - Compose-Taste
                    � Br�che (auf Zahlenreihe und Hardware-Ziffernblock)
                    � r�mische Zahlen
                    � Ligaturen und Copyright
*/


/******************
 Globale Schalter *
******************/
; Sollen Ebenen 1-4 ignoriert werden? (kann z.B. vom dll Treiber �bernommen werden) Ja = 1, Nein = 0
nurEbenenFuenfUndSechs = 0


; aus Noras script kopiert:
#usehook on
#singleinstance force
#LTrim 
  ; Quelltext kann einger�ckt werden, 
  ; msgbox ist trotzdem linksb�ndig

SetTitleMatchMode 2
SendMode Input	

name    = Neo 2.0
enable  = Aktiviere %name%
disable = Deaktiviere %name%

; �berpr�fung auf deutsches Tastaturlayout 
; ----------------------------------------

regread, inputlocale, HKEY_CURRENT_USER, Keyboard Layout\Preload, 1
regread, inputlocalealias, HKEY_CURRENT_USER
     , Keyboard Layout\Substitutes, %inputlocale%
if inputlocalealias <>
   inputlocale = %inputlocalealias%
if inputlocale <> 00000407
{
   suspend   
   regread, inputlocale, HKEY_LOCAL_MACHINE
     , SYSTEM\CurrentControlSet\Control\Keyboard Layouts\%inputlocale%
     , Layout Text
   msgbox, 48, Warnung!, 
     (
     Nicht kompatibles Tastaturlayout:   
     `t%inputlocale%   
     `nDas deutsche QWERTZ muss als Standardlayout eingestellt  
     sein, damit %name% wie erwartet funktioniert.   
     `n�ndern Sie die Tastatureinstellung unter 
     `tSystemsteuerung   
     `t-> Regions- und Sprachoptionen   
     `t-> Sprachen 
     `t-> Details...   `n
     )
   exitapp
}

; Men� des Systray-Icons 
; ----------------------

menu, tray, nostandard
menu, tray, add, �ffnen, open
   menu, helpmenu, add, About, about
   menu, helpmenu, add, Autohotkey-Hilfe, help
   menu, helpmenu, add
   menu, helpmenu, add, http://&autohotkey.com/, autohotkey
   menu, helpmenu, add, http://www.neo-layout.org/, neo
menu, tray, add, Hilfe, :helpmenu
menu, tray, add
menu, tray, add, %disable%, togglesuspend
menu, tray, default, %disable%
menu, tray, add
menu, tray, add, Edit, edit
menu, tray, add, Reload, reload
menu, tray, add
menu, tray, add, Nicht im Systray anzeigen, hide
menu, tray, add, %name% beenden, exitprogram
menu, tray, tip, %name%


/*
   Variablen initialisieren
*/

Ebene = 1
PriorDeadKey := ""


/*
   ------------------------------------------------------
   Modifier
   ------------------------------------------------------
*/


; CapsLock durch Umschalt+Umschalt
*CapsLock::return ; Nichts machen beim Capslock release event (weil es Mod3 ist)

*#::return ; Nichts machen beim # release event (weil es Mod3 ist)

;RShift wenn vorher LShift gedr�ckt wurde
LShift & ~RShift::	
      if GetKeyState("CapsLock","T")
      {
         setcapslockstate, off
      }
      else
      {
         setcapslockstate, on
      }
return

;LShift wenn vorher RShift gedr�ckt wurde
RShift & ~LShift::
      if GetKeyState("CapsLock","T")
      {
         setcapslockstate, off
      }
      else
      {
         setcapslockstate, on
      }
return

; Mod4-Lock durch Mod4+Mod4
IsMod4Locked := 0
< & *SC138::
      if (IsMod4Locked) 
      {
         MsgBox Mod4-Feststellung aufgebehoben
         IsMod4Locked = 0
      }
      else
      {
         MsgBox Mod4 festgestellt: Um Mod4 wieder zu l�sen dr�cke beide Mod4 Tasten gleichzeitig 
         IsMod4Locked = 1
      }
return
/* ; das folgende wird seltsamerweise nicht gebraucht :)
SC138 & *<::
      if (IsMod4Locked) 
      {
         MsgBox Mod4-Feststellung aufgebehoben
         IsMod4Locked = 0
      }
      else
      {
         MsgBox Mod4 festgestellt: Um Mod4 wieder zu l�sen dr�cke beide Mod4 Tasten gleichzeitig 
         IsMod4Locked = 1
      }
return
*/
 
/*
;  Wird nicht mehr gebraucht weil jetzt auf b (bzw. *n::)
; KP_Decimal durch Mod4+Mod4
*<::
*SC138::
   if GetKeyState("<","P") and GetKeyState("SC138","P")
   {
      send {numpaddot}
   }
return
 
*/
  
/*
   Ablauf bei toten Tasten:
   1. Ebene Aktualisieren
   2. Abh�ngig von der Variablen "Ebene" Zeichen ausgeben und die Variable "PriorDeadKey" setzen
   
   Ablauf bei "lebenden" (sagt man das?) Tasten:
   1. Ebene Aktualisieren
   2. Abh�ngig von den Variablen "Ebene" und "PriorDeadKey" Zeichen ausgeben
   3. "PriorDeadKey" mit leerem String �berschreiben

   ------------------------------------------------------
   Reihe 1
   ------------------------------------------------------
*/
*^::
   EbeneAktualisieren()
   if Ebene = 1
   {
      SendUnicodeChar(0x02C6) ; circumflex, tot
      PriorDeadKey := "c1"
   }
   else if Ebene = 2
   {
      SendUnicodeChar(0x02C7)  ; caron, tot
      PriorDeadKey := "c2"
   }
   else if Ebene = 3
   {
      SendUnicodeChar(0x02D8)   ; brevis
      PriorDeadKey := "c3"
   }
   else if Ebene = 4
   {
      SendUnicodeChar(0x00B7)  ; Mittenpunkt, tot
      PriorDeadKey := "c5"
   }
   else if Ebene = 5
   {
      send - ; querstrich, tot
      PriorDeadKey := "c4"
   }
   else if Ebene = 6
   {
      Send .         ; punkt darunter (colon)
      PriorDeadKey := "c6"
   }
return

*1::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c1")          ; circumflex 1
         BSSendUnicodeChar(0x00B9)
      else if (PriorDeadKey = "c4")       ; toter -
         BSSendUnicodeChar(0x2081)
      else if (CompKey = "r_small_1")
         Comp3UnicodeChar(0x217A)          ; r�misch xi
      else if (CompKey = "r_capital_1")
         Comp3UnicodeChar(0x216A)          ; r�misch XI
      else
       {  
         if GetKeyState("CapsLock","T") 
         {
           if (IsModifierPressed())
           {
             send {blind}1
           }
           else
           {
              send 1
           }   
         }
         else {
           send {blind}1
         }
       }
      if (PriorDeadKey = "comp")
         CompKey := "1"
      else if (CompKey = "r_small")
         CompKey := "r_small_1"
      else if (CompKey = "r_capital")
         CompKey := "r_capital_1"
      else
         CompKey := ""
   }
   else if Ebene = 2
   {
      send �
      CompKey := ""
   }
   else if Ebene = 3
   {
      SendUnicodeChar(0x00B9) ; 2 Hochgestellte
      CompKey := ""
   }
   else if Ebene = 4
   {
      SendUnicodeChar(0x2022) ; bullet
      CompKey := ""
   }
   else if Ebene = 5
   {
      SendUnicodeChar(0x2640) ; Piktogramm weiblich
      CompKey := ""
   }
   else if Ebene = 6
   {
      SendUnicodeChar(0x00AC) ; Nicht-Symbol
      CompKey := ""
   }
   PriorDeadKey := ""
return

*2::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c1")          ; circumflex 
         BSSendUnicodeChar(0x00B2)
      else if (PriorDeadKey = "c4")       ; toter -
         BSSendUnicodeChar(0x2082)
      else if (CompKey = "r_small")
         CompUnicodeChar(0x2171)          ; r�misch ii
      else if (CompKey = "r_capital")
         CompUnicodeChar(0x2161)          ; r�misch II
      else if (CompKey = "r_small_1")
         Comp3UnicodeChar(0x217B)          ; r�misch xii
      else if (CompKey = "r_capital_1")
         Comp3UnicodeChar(0x216B)          ; r�misch XII
      else
       {  
         if GetKeyState("CapsLock","T") 
         {
           if (IsModifierPressed())
           {
             send {blind}2
           }
           else
           {
              send 2
           }
               
         }
         else {
           send {blind}2
         }
       }
      if (PriorDeadKey = "comp")
         CompKey := "2"
      else
         CompKey := ""         
   }
   else if Ebene = 2
   {
      SendUnicodeChar(0x2116) ; numero
      CompKey := ""
   }
   else if Ebene = 3
   {	
      SendUnicodeChar(0x00B2) ; 2 Hochgestellte
      CompKey := ""
   }
   else if Ebene = 4
   {
      SendUnicodeChar(0x2023) ; aufzaehlungspfeil
      CompKey := ""
   }
   else if Ebene = 5
   {
      SendUnicodeChar(0x26A5) ; Piktogramm Zwitter
      CompKey := ""
   }
   else if Ebene = 6
   {
      SendUnicodeChar(0x2228) ; Logisches Oder
      CompKey := ""
   }
   PriorDeadKey := ""
return

*3::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c1")          ; circumflex
         BSSendUnicodeChar(0x00B3)
      else if (PriorDeadKey = "c4")       ; toter -
         BSSendUnicodeChar(0x2083)
      else if (CompKey = "1")
         CompUnicodeChar(0x2153)          ; 1/3
      else if (CompKey = "2")
         CompUnicodeChar(0x2154)          ; 2/3
      else if (CompKey = "r_small")
         CompUnicodeChar(0x2172)          ; r�misch iii
      else if (CompKey = "r_capital")
         CompUnicodeChar(0x2162)          ; r�misch III
      else
       {  
         if GetKeyState("CapsLock","T") 
         {
           if (IsModifierPressed())
           {
             send {blind}3
           }
           else
           {
              send 3
           }
               
         }
         else {
           send {blind}3
         }
       }
      if (PriorDeadKey = "comp")
         CompKey := "3"
      else
         CompKey := ""         
   }
   else if Ebene = 2
   {
      send �
      CompKey := ""
   }
   else if Ebene = 3
   {
      SendUnicodeChar(0x00B3) ; 3 Hochgestellte
      CompKey := ""
   }
   else if Ebene = 4
   { } ; leer
   else if Ebene = 5
   {
      SendUnicodeChar(0x2642) ; Piktogramm Mann
      CompKey := ""
   }
   else if Ebene = 6
   {
      SendUnicodeChar(0x2227) ; Logisches Und
      CompKey := ""
   }   
   PriorDeadKey := ""
return

*4::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c1")          ; circumflex
         BSSendUnicodeChar(0x2074)
      else if (PriorDeadKey = "c4")       ; toter -
         BSSendUnicodeChar(0x2084)         
      else if (CompKey = "r_small")
         CompUnicodeChar(0x2173)          ; r�misch iv
      else if (CompKey = "r_capital")
         CompUnicodeChar(0x2163)          ; r�misch IV
      else
       {  
         if GetKeyState("CapsLock","T") 
         {
           if (IsModifierPressed())
           {
             send {blind}4
           }
           else
           {
              send 4
           }
               
         }
         else {
           send {blind}4
         }
       }
      if (PriorDeadKey = "comp")
         CompKey := "4"
      else
         CompKey := ""         
	}
   else if Ebene = 2
   {
      send �
      CompKey := ""
   }
    else if Ebene = 3
   {
      send �
      CompKey := ""
   }
   else if Ebene = 4
   {
      Send {PgUp}    ; Prev
      CompKey := ""
   }
   else if Ebene = 5
   {
      SendUnicodeChar(0x2113) ; Script small L
      CompKey := ""
   }
   else if Ebene = 6
   {
      SendUnicodeChar(0x22A5) ; Senkrecht
      CompKey := ""
   }   
   PriorDeadKey := ""
return

*5::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c1")          ; circumflex
         BSSendUnicodeChar(0x2075)
      else if (PriorDeadKey = "c4")       ; toter -
         BSSendUnicodeChar(0x2085)
      else if (CompKey = "1")
         CompUnicodeChar(0x2155)          ; 1/5
      else if (CompKey = "2")
         CompUnicodeChar(0x2156)          ; 2/5
      else if (CompKey = "3")
         CompUnicodeChar(0x2157)          ; 3/5
      else if (CompKey = "4")
         CompUnicodeChar(0x2158)          ; 4/5
      else if (CompKey = "r_small")
         CompUnicodeChar(0x2174)          ; r�misch v
      else if (CompKey = "r_capital")
         CompUnicodeChar(0x2164)          ; r�misch V
      else
       {  
         if GetKeyState("CapsLock","T") 
         {
           if (IsModifierPressed())
           {
             send {blind}5
           }
           else
           {
              send 5
           }
               
         }
         else {
           send {blind}5
         }
       }
      if (PriorDeadKey = "comp")
         CompKey := "5"
      else
         CompKey := ""         
	}
   else if Ebene = 2
   {
      send �
      CompKey := ""
   }
   else if Ebene = 3
   {
      send �
      CompKey := ""
   }
   else if Ebene = 4
   { } ; leer
   else if Ebene = 5
   {
      SendUnicodeChar(0x2020) ; Kreuz (Dagger)
      CompKey := ""
   }
   else if Ebene = 6
   {
      SendUnicodeChar(0x2221) ; Winkel
      CompKey := ""
   }   
   PriorDeadKey := ""
return

*6::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c1")          ; circumflex
         BSSendUnicodeChar(0x2076)
      else if (PriorDeadKey = "c4")       ; toter -
         BSSendUnicodeChar(0x2086)         
      else if (CompKey = "1")
         CompUnicodeChar(0x2159)          ; 1/6
      else if (CompKey = "5")
         CompUnicodeChar(0x215A)          ; 5/6
      else if (CompKey = "r_small")
         CompUnicodeChar(0x2175)          ; r�misch vi
      else if (CompKey = "r_capital")
         CompUnicodeChar(0x2165)          ; r�misch VI
      else
       {  
         if GetKeyState("CapsLock","T") 
         {
           if (IsModifierPressed())
           {
             send {blind}6
           }
           else
           {
              send 6
           }
               
         }
         else {
           send {blind}6
         }
       }
      if (PriorDeadKey = "comp")
         CompKey := "6"
      else
         CompKey := ""         
	}
   else if Ebene = 2
   {
      send �
      CompKey := ""
   }
   else if Ebene = 3
   {
      send �
      CompKey := ""
   }
   else if Ebene = 4
   {
      send �
      CompKey := ""
   }
   else if Ebene = 5
   {  } ; leer
   else if Ebene = 6
   {
      SendUnicodeChar(0x2225) ; parallel
      CompKey := ""
   }
   PriorDeadKey := ""
return

*7::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c1")          ; circumflex
         BSSendUnicodeChar(0x2077)
      else if (PriorDeadKey = "c4")       ; toter -
         BSSendUnicodeChar(0x2087)
      else if (CompKey = "r_small")
         CompUnicodeChar(0x2176)          ; r�misch vii
      else if (CompKey = "r_capital")
         CompUnicodeChar(0x2166)          ; r�misch VII
      else
       {  
         if GetKeyState("CapsLock","T") 
         {
           if (IsModifierPressed())
           {
             send {blind}7
           }
           else
           {
              send 7
           }
               
         }
         else {
           send {blind}7
         }
       }
      if (PriorDeadKey = "comp")
         CompKey := "7"
      else
         CompKey := ""         
	}
   else if Ebene = 2
   {
      send $
      CompKey := ""
   }
   else if Ebene = 3
   {
      send �
      CompKey := ""
   }
   else if Ebene = 4
   {
      send � 
      CompKey := ""
   }
   else if Ebene = 5
   {
      SendUnicodeChar(0x03F0) ; Kappa Symbol 
      CompKey := ""
   }
   else if Ebene = 6
   {
      SendUnicodeChar(0x2209) ; nicht Element von 
      CompKey := ""
   }
   PriorDeadKey := ""
return

*8::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c1")          ; circumflex
         BSSendUnicodeChar(0x2078)
      else if (PriorDeadKey = "c4")       ; toter -
         BSSendUnicodeChar(0x2088)
      else if (CompKey = "1")
         CompUnicodeChar(0x215B)          ; 1/8
      else if (CompKey = "3")
         CompUnicodeChar(0x215C)          ; 3/8
      else if (CompKey = "5")
         CompUnicodeChar(0x215D)          ; 5/8
      else if (CompKey = "7")
         CompUnicodeChar(0x215E)          ; 7/8
      else if (CompKey = "r_small")
         CompUnicodeChar(0x2177)          ; r�misch viii
      else if (CompKey = "r_capital")
         CompUnicodeChar(0x2167)          ; r�misch VIII
      else
       {  
         if GetKeyState("CapsLock","T") 
         {
           if (IsModifierPressed())
           {
             send {blind}8
           }
           else
           {
              send 8
           }
               
         }
         else {
           send {blind}8
         }
       }
      if (PriorDeadKey = "comp")
         CompKey := "8"
      else
         CompKey := ""         
	}
   else if Ebene = 2
   {
      send �
      CompKey := ""
   }
   else if Ebene = 3
   {
      send �
      CompKey := ""
   }
   else if Ebene = 4
   {
      Send /
      CompKey := ""
   }
   else if Ebene = 5
   {  }  ; leer
   else if Ebene = 6
   {
      SendUnicodeChar(0x2204) ; es existiert nicht
      CompKey := ""
   }
   PriorDeadKey := ""
return

*9::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c1")          ; circumflex
         BSSendUnicodeChar(0x2079)
      else if (PriorDeadKey = "c4")       ; toter -
         BSSendUnicodeChar(0x2089)
      else if (CompKey = "r_small")
         CompUnicodeChar(0x2178)          ; r�misch ix
      else if (CompKey = "r_capital")
         CompUnicodeChar(0x2168)          ; r�misch IX
      else
       {  
         if GetKeyState("CapsLock","T") 
         {
           if (IsModifierPressed())
           {
             send {blind}9
           }
           else
           {
              send 9
           }
               
         }
         else {
           send {blind}9
         }
       }
      if (PriorDeadKey = "comp")
         CompKey := "9"
      else
         CompKey := ""         
	}
   else if Ebene = 2
   {
      send �
      CompKey := ""
   }
   else if Ebene = 3
   {
      send �
      CompKey := ""
   }
   else if Ebene = 4
   {
      Send *
      CompKey := ""
   }
   else if Ebene = 5
   {  } ; leer
   else if Ebene = 6
   {
      SendUnicodeChar(0x2226) ; nicht parallel
      CompKey := ""
   }
   PriorDeadKey := ""
return

*0::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c1")          ; circumflex
         BSSendUnicodeChar(0x2070)
      else if (PriorDeadKey = "c4")       ; toter -
         BSSendUnicodeChar(0x2080)         
      else if (CompKey = "r_small_1")
         Comp3UnicodeChar(0x2179)          ; r�misch x
      else if (CompKey = "r_capital_1")
         Comp3UnicodeChar(0x2169)          ; r�misch X
      else
       {  
         if GetKeyState("CapsLock","T") 
         {
           if (IsModifierPressed())
           {
             send {blind}0
           }
           else
           {
              send 0
           }
               
         }
         else {
           send {blind}0
         }
       }
      if (PriorDeadKey = "comp")
         CompKey := "0"
      else
         CompKey := ""         
	}
   else if Ebene = 2
   {
      send �
      CompKey := ""
   }
   else if Ebene = 3
   {
      send �
      CompKey := ""
   }
   else if Ebene = 4
   {
      Send -
      CompKey := ""
   }
   else if Ebene = 5
   {  } ; leer
   else if Ebene = 6
   {
      SendUnicodeChar(0x2205) ; leere Menge
      CompKey := ""
   }
   PriorDeadKey := ""
return

*�::
   EbeneAktualisieren()
   if Ebene = 1
        {  
         if GetKeyState("CapsLock","T") 
         {
           if (IsModifierPressed())
           {
             send {blind}-
           }
           else
           {
              send -
           }
               
         }
         else {
           send {blind}-   ;Bindestrich
         }
       }
   else if Ebene = 2
      SendUnicodeChar(0x2013) ; Gedankenstrich
   else if Ebene = 3
      SendUnicodeChar(0x2014) ; Englische Gedankenstrich
   else if Ebene = 4
     { } ; leer ...  SendUnicodeChar(0x254C) 
   else if Ebene = 5
      SendUnicodeChar(0x2011) ; gesch�tzter Bindestrich
   else if Ebene = 6
      SendUnicodeChar(0x00AD) ; weicher Trennstrich
   PriorDeadKey := ""   CompKey := ""
return

*�::
   EbeneAktualisieren()
   if Ebene = 1
   {
      send {�}{space} ; akut, tot
      PriorDeadKey := "a1"
   }
   else if Ebene = 2
   {
      send ``{space}
      PriorDeadKey := "a2"
   }
   else if Ebene = 3
   {
      send � ; cedilla
      PriorDeadKey := "a3"
   }
   else if Ebene = 4
   {
      SendUnicodeChar(0x02D9) ; punkt oben dr�ber
      PriorDeadKey := "a5"
   }
   else if Ebene = 5
   {
      SendUnicodeChar(0x02DB) ; ogonek
      PriorDeadKey := "a4"
   }
   else if Ebene = 6
   {
      SendUnicodeChar(0x02DA)  ; ring obendrauf
      PriorDeadKey := "a6"
   }
return


/*
   ------------------------------------------------------
   Reihe 2
   ------------------------------------------------------
*/

*q::
   EbeneAktualisieren()
   if Ebene = 1
      sendinput {blind}x
   else if Ebene = 2
      sendinput {blind}X
   else if Ebene = 5
      SendUnicodeChar(0x03BE) ;xi
   else if Ebene = 6
      SendUnicodeChar(0x039E)  ; Xi
   PriorDeadKey := ""   CompKey := ""
return


*w::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c6")      ; punkt darunter 
         BSSendUnicodeChar(0x1E7F)
      else
         sendinput {blind}v
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "c6")      ; punkt darunter
         BSSendUnicodeChar(0x1E7E)
      else 
         sendinput {blind}V
   }
   else if Ebene = 3
      send _
   else if Ebene = 4
      Send {Backspace}
   else if Ebene = 6
      SendUnicodeChar(0x2259) ; estimates
   PriorDeadKey := ""   CompKey := ""
return



*e::
   EbeneAktualisieren()
   if Ebene = 1
   { 
      if (PriorDeadKey = "t5")       ; Schr�gstrich
         BSSendUnicodeChar(0x0142)
      else if (PriorDeadKey = "a1")      ; akut 
         BSSendUnicodeChar(0x013A)
      else if (PriorDeadKey = "c2")     ; caron 
         BSSendUnicodeChar(0x013E)
      else if (PriorDeadKey = "a3")    ; cedilla
         BSSendUnicodeChar(0x013C)
      else if (PriorDeadKey = "c5")  ; Mittenpunkt
         BSSendUnicodeChar(0x0140)
      else if (PriorDeadKey = "c6") ; punkt darunter 
         BSSendUnicodeChar(0x1E37)
      else 
         sendinput {blind}l
      if (PriorDeadKey = "comp")            ; compose
         CompKey := "l_small"
      else
         CompKey := ""
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "a1")           ; akut 
         BSSendUnicodeChar(0x0139)
      else if (PriorDeadKey = "c2")     ; caron 
         BSSendUnicodeChar(0x013D)
      else if (PriorDeadKey = "a3")    ; cedilla
         BSSendUnicodeChar(0x013B)
      else if (PriorDeadKey = "t5")  ; Schr�gstrich 
         BSSendUnicodeChar(0x0141)
      else if (PriorDeadKey = "c5")  ; Mittenpunkt 
         BSSendUnicodeChar(0x013F)
      else if (PriorDeadKey = "c6") ; punkt darunter 
         BSSendUnicodeChar(0x1E36)
      else 
         sendinput {blind}L
      if (PriorDeadKey = "comp")            ; compose
         CompKey := "l_capital"
      else CompKey := ""
   }      
   else if Ebene = 3
   {
      send [
      CompKey := ""
   }
   else if Ebene = 4
   {
      Sendinput {Blind}{Up}
      CompKey := ""
   }
   else if Ebene = 5
   {
      SendUnicodeChar(0x03BB) ; lambda
      CompKey := ""
   }
   else if Ebene = 6
   {
      SendUnicodeChar(0x039B) ; Lambda
      CompKey := ""
   }
   PriorDeadKey := ""
return


*r::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c1")           ; circumflex
         BSSendUnicodeChar(0x0109)
      else if (PriorDeadKey = "c2")     ; caron
         BSSendUnicodeChar(0x010D)
      else if (PriorDeadKey = "a1")      ; akut
         BSSendUnicodeChar(0x0107)
      else if (PriorDeadKey = "a3")    ; cedilla
         BSSendUnicodeChar(0x00E7)
      else if (PriorDeadKey = "a5")  ; punkt dar�ber 
         BSSendUnicodeChar(0x010B)
      else if ( (CompKey = "o_small") or (CompKey = "o_capital") )
         Send {bs}�
      else
         sendinput {blind}c
      if (PriorDeadKey = "comp")
         CompKey := "c_small"
      else
         CompKey := ""
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "c1")          ; circumflex 
         BSSendUnicodeChar(0x0108)
      else if (PriorDeadKey = "c2")    ; caron 
         BSSendUnicodeChar(0x010C)
      else if (PriorDeadKey = "a1")     ; akut 
         BSSendUnicodeChar(0x0106)
      else if (PriorDeadKey = "a3")   ; cedilla 
         BSSendUnicodeChar(0x00E6)
      else if (PriorDeadKey = "a5") ; punkt dar�ber 
         BSSendUnicodeChar(0x010A)
      else if ( (CompKey = "o_small") or (CompKey = "o_capital") )
         Send {bs}�         
      else 
         sendinput {blind}C
      if (PriorDeadKey = "comp")
         CompKey = "c_capital"
      else
         CompKey := ""
   }
   else if Ebene = 3
   {
      send ]
      CompKey := ""
   }
   else if Ebene = 4
   {
      Send {Del}
      CompKey := ""
   }
   else if Ebene = 5
   {
      SendUnicodeChar(0x03C7) ;chi
      CompKey := ""
   }
   else if Ebene = 6
   {
      SendUnicodeChar(0x2102)  ; C (Komplexe Zahlen)
      CompKey := ""
   }
   PriorDeadKey := ""
return

*t::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c1")           ; circumflex
         BSSendUnicodeChar(0x0175)
      else
         sendinput {blind}w
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "c1")           ; circumflex
         BSSendUnicodeChar(0x0174)
      else
         sendinput {blind}W
   }
   else if Ebene = 3
      send {^}{space} ; untot
   else if Ebene = 4
      Send {Insert}
   else if Ebene = 5
      SendUnicodeChar(0x03C9) ; omega
   else if Ebene = 6
      SendUnicodeChar(0x03A9) ; Omega
   PriorDeadKey := ""   CompKey := ""
return

*z::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "a3")         ; cedilla
         BSSendUnicodeChar(0x0137)
      else if (PriorDeadKey = "c6") ; punkt darunter 
         BSSendUnicodeChar(0x1E33)
      else
         sendinput {blind}k
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "a3")         ; cedilla 
         BSSendUnicodeChar(0x0136)
      else if (PriorDeadKey = "c6") ; punkt darunter 
         BSSendUnicodeChar(0x1E32)
      else
         sendinput {blind}K
   }
   else if Ebene = 3
      sendraw !
   else if Ebene = 4
      Send �
   else if Ebene = 5
      SendUnicodeChar(0x03BA) ;kappa
   else if Ebene = 6
      SendUnicodeChar(0x221A) ; Wurzel
   PriorDeadKey := ""   CompKey := ""
return

*u::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c1")           ; circumflex
         BSSendUnicodeChar(0x0125)
      else if (PriorDeadKey = "c4")   ; Querstrich 
         BSSendUnicodeChar(0x0127)
      else if (PriorDeadKey = "a5")  ; punkt dar�ber 
         BSSendUnicodeChar(0x1E23)
      else if (PriorDeadKey = "c6") ; punkt darunter 
         BSSendUnicodeChar(0x1E25)
      else sendinput {blind}h
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "c1")           ; circumflex
         BSSendUnicodeChar(0x0124)
      else if (PriorDeadKey = "c4")   ; Querstrich
         BSSendUnicodeChar(0x0126)
      else if (PriorDeadKey = "a5")  ; punkt dar�ber 
         BSSendUnicodeChar(0x1E22)
      else if (PriorDeadKey = "c6") ; punkt darunter 
         BSSendUnicodeChar(0x1E24)
      else sendinput {blind}H
   }
   else if Ebene = 3
   {
      if (PriorDeadKey = "c4")    ; Querstrich
         BSSendUnicodeChar(0x2264) ; kleiner gleich
      else
         send {blind}<
   }
   else if Ebene = 4
   {
      if (PriorDeadKey = "c1")            ; circumflex
         BSSendUnicodeChar(0x2077)
      else if (PriorDeadKey = "c4")       ; toter -
         BSSendUnicodeChar(0x2087)
      else
         Send 7
   }
   else if Ebene = 5
      SendUnicodeChar(0x03C8) ;psi
   else if Ebene = 6
      SendUnicodeChar(0x03A8)  ; Psi
   PriorDeadKey := ""   CompKey := ""
return

*i::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c1")          ; circumflex
         BSSendUnicodeChar(0x011D)
      else if (PriorDeadKey = "c3")   ; brevis
         BSSendUnicodeChar(0x011F)
      else if (PriorDeadKey = "a3")   ; cedilla
         BSSendUnicodeChar(0x0123)
      else if (PriorDeadKey = "a5") ; punkt dar�ber 
         BSSendUnicodeChar(0x0121)
      else sendinput {blind}g
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "c1")           ; circumflex
         BSSendUnicodeChar(0x011C)
      else if (PriorDeadKey = "c3")    ; brevis 
         BSSendUnicodeChar(0x011E)
      else if (PriorDeadKey = "a3")    ; cedilla 
         BSSendUnicodeChar(0x0122)
      else if (PriorDeadKey = "a5")  ; punkt dar�ber 
         BSSendUnicodeChar(0x0120)
      else sendinput {blind}G
   }
   else if Ebene = 3
   {
      if (PriorDeadKey = "c4")    ; Querstrich
         SendUnicodeChar(0x2265) ; gr��er gleich
      else
         send >
   }
   else if Ebene = 4
   {
      if (PriorDeadKey = "c1")            ; circumflex
         BSSendUnicodeChar(0x2078)
      else if (PriorDeadKey = "c4")       ; toter -
         BSSendUnicodeChar(0x2088)
      else
         Send 8
   }
   else if Ebene = 5
      SendUnicodeChar(0x03B3) ;gamma
   else if Ebene = 6
      SendUnicodeChar(0x0393)  ; Gamma
   PriorDeadKey := ""   CompKey := ""
return

*o::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "t5")      ; durchgestrichen
         BSSendUnicodeChar(0x0192)
      else if (PriorDeadKey = "a5") ; punkt dar�ber 
         BSSendUnicodeChar(0x1E1F)
      else sendinput {blind}f
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "t5")       ; durchgestrichen
         BSSendUnicodeChar(0x0191)
      else if (PriorDeadKey = "a5")  ; punkt dar�ber 
         BSSendUnicodeChar(0x1E1E)
      else sendinput {blind}F
   } 
   else if Ebene = 3
   {
      if (PriorDeadKey = "c1")            ; circumflex 
         BSSendUnicodeChar(0x2259)   ; entspricht
      else if (PriorDeadKey = "t1")       ; tilde 
         BSSendUnicodeChar(0x2245)   ; ungef�hr gleich
      else if (PriorDeadKey = "t5")   ; Schr�gstrich 
         BSSendUnicodeChar(0x2260)   ; ungleich
      else if (PriorDeadKey = "c4")    ; Querstrich
         BSSendUnicodeChar(0x2261)   ; identisch
      else if (PriorDeadKey = "c2")      ; caron 
         BSSendUnicodeChar(0x225A)   ; EQUIANGULAR TO
      else if (PriorDeadKey = "a6")      ; ring dr�ber 
         BSSendUnicodeChar(0x2257)   ; ring equal to
      else
         send `=
   }
   else if Ebene = 4
   {
      if (PriorDeadKey = "c1")            ; circumflex
         BSSendUnicodeChar(0x2079)
      else if (PriorDeadKey = "c4")       ; toter -
         BSSendUnicodeChar(0x2089)
      else
         Send 9
   }
   else if Ebene = 5
      SendUnicodeChar(0x03D5) ; Symbol Phi
   else if Ebene = 6
      SendUnicodeChar(0x03A6)  ; Phi
   PriorDeadKey := ""   CompKey := ""
return

*p::
   EbeneAktualisieren()
   if Ebene = 1
      sendinput {blind}q
   else if Ebene = 2
      sendinput {blind}Q
   else if Ebene = 3
      send {&}
   else if Ebene = 4
   {
      if (PriorDeadKey = "c1")            ; circumflex
         BSSendUnicodeChar(0x207A)
      else if (PriorDeadKey = "c4")       ; toter -
         BSSendUnicodeChar(0x208A)
      else
         Send {+}
   }
   else if Ebene = 5
      SendUnicodeChar(0x03C6)  ;  phi
   else if Ebene = 6
      SendUnicodeChar(0x211A) ; Q (rationale Zahlen)
   PriorDeadKey := ""   CompKey := ""
return

*�::
   EbeneAktualisieren()
   if Ebene = 1
      if GetKeyState("CapsLock","T")
      {
         SendUnicodeChar(0x1E9E) ; versal-�
      }
      else
      {
         send �
      }      
   else if Ebene = 2
      if GetKeyState("CapsLock","T")
      {
         send �
      }
      else
      {
         SendUnicodeChar(0x1E9E) ; versal-�
      }
   else if Ebene = 3
      SendUnicodeChar(0x017F)   ; langes s
   else if Ebene = 4
      {} ; leer    
   else if Ebene = 5
      SendUnicodeChar(0x03C2) ; varsigma
   else if Ebene = 6
      SendUnicodeChar(0x2218)  ; Verkn�pfungsoperator
   PriorDeadKey := ""   CompKey := ""
return


*+::
   EbeneAktualisieren()
   if Ebene = 1
   {
      SendUnicodeChar(0x02DC)    ; tilde, tot 
      PriorDeadKey := "t1"
   }
   else if Ebene = 2
   {
      SendUnicodeChar(0x00AF)  ; macron, tot
      PriorDeadKey := "t2"
   }
   else if Ebene = 3
   {
      SendUnicodeChar(0x00A8)   ; Diaerese
      PriorDeadKey := "t3"
   }
   else if Ebene = 4
   {
      SendUnicodeChar(0x002F)  ; Schr�gstrich, tot
      PriorDeadKey := "t5"
   }
   else if Ebene = 5
   {
      send "        ;doppelakut
      PriorDeadKey := "t4"
   }
   else if Ebene = 6
   {
      SendUnicodeChar(0x02CF)  ; komma drunter, tot
      PriorDeadKey := "t6"
   }
return


/*
   ------------------------------------------------------
   Reihe 3
   ------------------------------------------------------
*/

*a::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c1")       ; circumflex
         BSSendUnicodeChar(0x00FB)
      else if (PriorDeadKey = "a1")  ; akut 
         BSSendUnicodeChar(0x00FA)
      else if (PriorDeadKey = "a2")  ; grave
         BSSendUnicodeChar(0x00F9)
      else if (PriorDeadKey = "t3")  ; Diaerese
         Send, {bs}�
      else if (PriorDeadKey = "t4")  ; doppelakut 
         BSSendUnicodeChar(0x0171)
      else if (PriorDeadKey = "c3")  ; brevis
         BSSendUnicodeChar(0x016D)
      else if (PriorDeadKey = "t2")  ; macron
         BSSendUnicodeChar(0x016B)
      else if (PriorDeadKey = "a4")  ; ogonek
         BSSendUnicodeChar(0x0173)
      else if (PriorDeadKey = "a6")  ; Ring
         BSSendUnicodeChar(0x016F)
      else if (PriorDeadKey = "t1")  ; tilde
         BSSendUnicodeChar(0x0169)
      else if (PriorDeadKey = "c2")  ; caron
         BSSendUnicodeChar(0x01D4)
      else
         sendinput {blind}u
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "c1")        ; circumflex
         BSSendUnicodeChar(0x00DB)
      else if (PriorDeadKey = "a1")   ; akut 
         BSSendUnicodeChar(0x00DA)
      else if (PriorDeadKey = "a2")   ; grave
         BSSendUnicodeChar(0x00D9)
      else if (PriorDeadKey = "t3")   ; Diaerese
         Send, {bs}�
      else if (PriorDeadKey = "a6")   ; Ring
         BSSendUnicodeChar(0x016E)
      else if (PriorDeadKey = "c3")   ; brevis
         BSSendUnicodeChar(0x016C)
      else if (PriorDeadKey = "t4")   ; doppelakut
         BSSendUnicodeChar(0x0170)
      else if (PriorDeadKey = "c2")   ; caron 
         BSSendUnicodeChar(0x01D3)
      else if (PriorDeadKey = "t2")   ; macron
         BSSendUnicodeChar(0x016A)
      else if (PriorDeadKey = "a4")   ; ogonek
         BSSendUnicodeChar(0x0172)
      else if (PriorDeadKey = "t1")   ; tilde
         BSSendUnicodeChar(0x0168)
      else
         sendinput {blind}U
   }
   else if Ebene = 3
      send \
   else if Ebene = 4
      Send {blind}{Home}
   else if Ebene = 6
      SendUnicodeChar(0x222E) ; contour integral
   PriorDeadKey := ""   CompKey := ""
return

*s::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c1")        ; circumflex
         BSSendUnicodeChar(0x00EE)
      else if (PriorDeadKey = "a1")   ; akut 
         BSSendUnicodeChar(0x00ED)
      else if (PriorDeadKey = "a2")   ; grave
         BSSendUnicodeChar(0x00EC)
      else if (PriorDeadKey = "t3")   ; Diaerese
         Send, {bs}�
      else if (PriorDeadKey = "t2")   ; macron
         BSSendUnicodeChar(0x012B)
      else if (PriorDeadKey = "c3")   ; brevis
         BSSendUnicodeChar(0x012D)
      else if (PriorDeadKey = "a4")   ; ogonek
         BSSendUnicodeChar(0x012F)
      else if (PriorDeadKey = "t1")   ; tilde
         BSSendUnicodeChar(0x0129)
      else if (PriorDeadKey = "a5")   ; (ohne) punkt dar�ber 
         BSSendUnicodeChar(0x0131)
      else if (PriorDeadKey = "c2")   ; caron
         BSSendUnicodeChar(0x01D0)
      else 
         sendinput {blind}i
      if (PriorDeadKey = "comp")      ; compose
         CompKey := "i_small"
      else 
         CompKey := ""
   }
   else if Ebene = 2
   {   
      if (PriorDeadKey = "c1")        ; circumflex
         BSSendUnicodeChar(0x00CE)
      else if (PriorDeadKey = "a1")   ; akut 
         BSSendUnicodeChar(0x00CD)
      else if (PriorDeadKey = "a2")   ; grave
         BSSendUnicodeChar(0x00CC)
      else if (PriorDeadKey = "t3")   ; Diaerese
         Send, {bs}�
      else if (PriorDeadKey = "t2")   ; macron
         BSSendUnicodeChar(0x012A)
      else if (PriorDeadKey = "c3")   ; brevis 
         BSSendUnicodeChar(0x012C)
      else if (PriorDeadKey = "a4")   ; ogonek
         BSSendUnicodeChar(0x012E)
      else if (PriorDeadKey = "t1")   ; tilde
         BSSendUnicodeChar(0x0128)
      else if (PriorDeadKey = "a5")   ; punkt dar�ber 
         BSSendUnicodeChar(0x0130)
      else if (PriorDeadKey = "c2")   ; caron
         BSSendUnicodeChar(0x01CF)
      else 
         sendinput {blind}I
      if (PriorDeadKey = "comp")      ; compose
         CompKey := "i_capital"
      else
         CompKey := ""
   }
   else if Ebene = 3
   {
      send `/
      CompKey := ""
   }
   else if Ebene = 4
   {
      Sendinput {Blind}{Left}
      CompKey := ""
   }
   else if Ebene = 5
   {
      MsgBox iota   
      SendUnicodeChar(0x03B9) ; iota
      CompKey := ""
   }
   else if Ebene = 6
   {
      SendUnicodeChar(0x222B) ; integral
      CompKey := ""
   }
      PriorDeadKey := ""
return

*d::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c1")        ; circumflex
         BSSendUnicodeChar(0x00E2)
      else if (PriorDeadKey = "a1")   ; akut 
         BSSendUnicodeChar(0x00E1)
      else if (PriorDeadKey = "a2")   ; grave
         BSSendUnicodeChar(0x00E0)
      else if (PriorDeadKey = "t3")   ; Diaerese
         send {bs}�
      else if (PriorDeadKey = "a6")   ; Ring 
         Send {bs}�
      else if (PriorDeadKey = "t1")   ; tilde
         BSSendUnicodeChar(0x00E3)
      else if (PriorDeadKey = "a4")   ; ogonek
         BSSendUnicodeChar(0x0105)
      else if (PriorDeadKey = "t2")   ; macron
         BSSendUnicodeChar(0x0101)
      else if (PriorDeadKey = "c3")   ; brevis
         BSSendUnicodeChar(0x0103)
      else if (PriorDeadKey = "c2")   ; caron
         BSSendUnicodeChar(0x01CE)
      else
         sendinput {blind}a
      if (PriorDeadKey = "comp")      ; compose
         CompKey := "a_small"
      else
         CompKey := ""
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "c1")        ; circumflex
         BSSendUnicodeChar(0x00C2)
      else if (PriorDeadKey = "a1")   ; akut 
         BSSendUnicodeChar(0x00C1)
      else if (PriorDeadKey = "a2")   ; grave
         BSSendUnicodeChar(0x00C0)
      else if (PriorDeadKey = "t3")   ; Diaerese
         send {bs}�
      else if (PriorDeadKey = "t1")   ; tilde
         BSSendUnicodeChar(0x00C3)
      else if (PriorDeadKey = "a6")   ; Ring 
         Send {bs}�
      else if (PriorDeadKey = "t2")   ; macron
         BSSendUnicodeChar(0x0100)
      else if (PriorDeadKey = "c3")   ; brevis 
         BSSendUnicodeChar(0x0102)
      else if (PriorDeadKey = "a4")   ; ogonek
         BSSendUnicodeChar(0x0104)
      else if (PriorDeadKey = "c2")   ; caron
         BSSendUnicodeChar(0x01CD)
      else
         sendinput {blind}A
      if (PriorDeadKey = "comp")      ; compose
         CompKey := "a_capital"
      else
         CompKey := ""
   }
   else if Ebene = 3
   {
      sendraw {
      CompKey := ""
   }
   else if Ebene = 4
   {
      Sendinput {Blind}{Down}
      CompKey := ""
   }
   else if Ebene = 5
   {
      SendUnicodeChar(0x03B1) ;alpha
      CompKey := ""
   }
   else if Ebene = 6
   {
      SendUnicodeChar(0x2200) ;fuer alle   
      CompKey := ""
   }
   PriorDeadKey := ""
return

*f::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c1")        ; circumflex
         BSSendUnicodeChar(0x00EA)
      else if (PriorDeadKey = "a1")   ; akut 
         BSSendUnicodeChar(0x00E9)
      else if (PriorDeadKey = "a2")   ; grave
         BSSendUnicodeChar(0x00E8)
      else if (PriorDeadKey = "t3")   ; Diaerese
         Send, {bs}�
      else if (PriorDeadKey = "a4")   ; ogonek
         BSSendUnicodeChar(0x0119)
      else if (PriorDeadKey = "t2")   ; macron
         BSSendUnicodeChar(0x0113)
      else if (PriorDeadKey = "c3")   ; brevis
         BSSendUnicodeChar(0x0115)
      else if (PriorDeadKey = "c2")   ; caron
         BSSendUnicodeChar(0x011B)
      else if (PriorDeadKey = "a5")   ; punkt dar�ber 
         BSSendUnicodeChar(0x0117)
      else if (CompKey = "a_small")   ; compose
      {
         Send {bs}�
         CompKey := ""
      }
      else if (CompKey = "o_small")   ; compose
      {
         Send {bs}�
         CompKey := ""
      }      
      else
         sendinput {blind}e
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "c1")        ; circumflex
         BSSendUnicodeChar(0x00CA)
      else if (PriorDeadKey = "a1")   ; akut 
         BSSendUnicodeChar(0x00C9)
      else if (PriorDeadKey = "a2")   ; grave
         BSSendUnicodeChar(0x00C8)
      else if (PriorDeadKey = "t3")   ; Diaerese
         Send, {bs}�
      else if (PriorDeadKey = "c2")   ; caron
         BSSendUnicodeChar(0x011A)
      else if (PriorDeadKey = "t2")   ; macron
         BSSendUnicodeChar(0x0112)
      else if (PriorDeadKey = "c3")   ; brevis 
         BSSendUnicodeChar(0x0114)
      else if (PriorDeadKey = "a4")   ; ogonek 
         BSSendUnicodeChar(0x0118)
      else if (PriorDeadKey = "a5")   ; punkt dar�ber 
         BSSendUnicodeChar(0x0116)
      else if (CompKey = "a_capital") ; compose
      {
         Send {bs}�
         CompKey := ""
      }
      else if (CompKey = "o_capital")        ; compose
      {
         Send {bs}�
         CompKey := ""
      }      
      else 
         sendinput {blind}E
   }
   else if Ebene = 3
      sendraw }
   else if Ebene = 4
      Sendinput {Blind}{Right}
   else if Ebene = 5
        SendUnicodeChar(0x03B5) ;epsilon
   else if Ebene = 6
        SendUnicodeChar(0x2203) ;es existiert   
   PriorDeadKey := ""   CompKey := ""
return

*g::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c1")        ; circumflex
         BSSendUnicodeChar(0x00F4)
      else if (PriorDeadKey = "a1")   ; akut 
         BSSendUnicodeChar(0x00F3)
      else if (PriorDeadKey = "a2")   ; grave
         BSSendUnicodeChar(0x00F2)
      else if (PriorDeadKey = "t3")   ; Diaerese
         Send, {bs}�
      else if (PriorDeadKey = "t1")   ; tilde
         BSSendUnicodeChar(0x00F5)
      else if (PriorDeadKey = "t4")   ; doppelakut
         BSSendUnicodeChar(0x0151)
      else if (PriorDeadKey = "t5")   ; Schr�gstrich
         BSSendUnicodeChar(0x00F8)
      else if (PriorDeadKey = "t2")   ; macron
         BSSendUnicodeChar(0x014D)
      else if (PriorDeadKey = "c3")   ; brevis 
         BSSendUnicodeChar(0x014F)
      else if (PriorDeadKey = "a4")   ; ogonek
         BSSendUnicodeChar(0x01EB)
      else if (PriorDeadKey = "c2")   ; caron
         BSSendUnicodeChar(0x01D2)                   	
      else
         sendinput {blind}o
      if (PriorDeadKey = "comp")      ; compose
         CompKey := "o_small"
      else
         CompKey := ""
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "c1")        ; circumflex
         BSSendUnicodeChar(0x00D4)
      else if (PriorDeadKey = "a1")   ; akut 
         BSSendUnicodeChar(0x00D3)
      else if (PriorDeadKey = "a2")   ; grave
         BSSendUnicodeChar(0x00D2)
      else if (PriorDeadKey = "t5")   ; Schr�gstrich
         BSSendUnicodeChar(0x00D8)
      else if (PriorDeadKey = "t1")   ; tilde
         BSSendUnicodeChar(0x00D5)
      else if (PriorDeadKey = "t4")   ; doppelakut
         BSSendUnicodeChar(0x0150)
      else if (PriorDeadKey = "t3")   ; Diaerese
         send {bs}�
      else if (PriorDeadKey = "t2")   ; macron 
         BSSendUnicodeChar(0x014C)
      else if (PriorDeadKey = "c3")   ; brevis 
         BSSendUnicodeChar(0x014E)
      else if (PriorDeadKey = "a4")   ; ogonek
         BSSendUnicodeChar(0x01EA)
      else if (PriorDeadKey = "c2")   ; caron
         BSSendUnicodeChar(0x01D1)    
      else
         sendinput {blind}O
      if (PriorDeadKey = "comp")      ; compose
         CompKey := "o_capital"
      else
         CompKey := ""
   }
   else if Ebene = 3
   {
      send *
      CompKey := ""
   }
   else if Ebene = 4
   {
      Send {blind}{End}
      CompKey := ""
   }
   else if Ebene = 5
   {
      SendUnicodeChar(0x03C9) ; omega
      CompKey := ""
   }
   else if Ebene = 6
   {
      SendUnicodeChar(0x2208) ; element of
      CompKey := ""
   }
   PriorDeadKey := ""
return

*h::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c1")           ; circumflex
         BSSendUnicodeChar(0x015D)
      else if (PriorDeadKey = "a1")      ; akut 
         BSSendUnicodeChar(0x015B)
      else if (PriorDeadKey = "c2")     ; caron
         BSSendUnicodeChar(0x0161)
      else if (PriorDeadKey = "a3")    ; cedilla
         BSSendUnicodeChar(0x015F)
      else if (PriorDeadKey = "a5")  ; punkt dar�ber 
         BSSendUnicodeChar(0x1E61)
      else if (PriorDeadKey = "c6") ; punkt darunter 
         BSSendUnicodeChar(0x1E63)
      else   
         sendinput {blind}s
      if (PriorDeadKey = "comp")
         CompKey := "s_small"
      else
         CompKey := ""
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "c1")           ; circumflex
         BSSendUnicodeChar(0x015C)
      else if (PriorDeadKey = "c2")     ; caron
         BSSendUnicodeChar(0x0160)
      else if (PriorDeadKey = "a1")      ; akut 
         BSSendUnicodeChar(0x015A)
      else if (PriorDeadKey = "a3")    ; cedilla 
         BSSendUnicodeChar(0x015E)
      else if (PriorDeadKey = "a5")  ; punkt dar�ber 
         BSSendUnicodeChar(0x1E60)
      else if (PriorDeadKey = "c6") ; punkt darunter 
         BSSendUnicodeChar(0x1E62)
      else
         sendinput {blind}S
      if (PriorDeadKey = "comp")
         CompKey := "s_capital"
      else
         CompKey := ""
   }
   else if Ebene = 3
   {
      send ?
      CompKey := ""
   }
   else if Ebene = 4
   {
      Send �
      CompKey := ""
   }
   else if Ebene = 5
   {
      SendUnicodeChar(0x03C3) ;sigma
      CompKey := ""
   }
   else if Ebene = 6
   {
      SendUnicodeChar(0x03A3)  ; Sigma
      CompKey := ""
   }
   PriorDeadKey := ""
return

*j::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "a1")          ; akut
         BSSendUnicodeChar(0x0144)
      else if (PriorDeadKey = "t1")     ; tilde
         BSSendUnicodeChar(0x00F1)
      else if (PriorDeadKey = "c2")    ; caron
         BSSendUnicodeChar(0x0148)
      else if (PriorDeadKey = "a3")   ; cedilla
         BSSendUnicodeChar(0x0146)
      else if (PriorDeadKey = "a5") ; punkt dar�ber 
         BSSendUnicodeChar(0x1E45)
      else
         sendinput {blind}n
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "c2")         ; caron
         BSSendUnicodeChar(0x0147)
      else if (PriorDeadKey = "t1")     ; tilde
         BSSendUnicodeChar(0x00D1)
      else if (PriorDeadKey = "a1")     ; akut 
         BSSendUnicodeChar(0x0143)
      else if (PriorDeadKey = "a3")   ; cedilla 
         BSSendUnicodeChar(0x0145)
      else if (PriorDeadKey = "a5") ; punkt dar�ber 
         BSSendUnicodeChar(0x1E44)
      else
         sendinput {blind}N
   }
   else if Ebene = 3
      send (
   else if Ebene = 4
   {
      if (PriorDeadKey = "c1")            ; circumflex
         BSSendUnicodeChar(0x2074)
      else if (PriorDeadKey = "c4")       ; toter -
         BSSendUnicodeChar(0x2084)
      else
         Send 4
   }
   else if Ebene = 5
      SendUnicodeChar(0x03BD) ; nu
   else if Ebene = 6
      SendUnicodeChar(0x2115) ; N (nat�rliche Zahlen)
   PriorDeadKey := ""   CompKey := ""
return

*k::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "a1")           ; akut 
         BSSendUnicodeChar(0x0155)
      else if (PriorDeadKey = "c2")     ; caron
         BSSendUnicodeChar(0x0159)
      else if (PriorDeadKey = "a3")    ; cedilla
         BSSendUnicodeChar(0x0157)
      else if (PriorDeadKey = "a5")  ; punkt dar�ber 
         BSSendUnicodeChar(0x0E59)
      else if (PriorDeadKey = "c6") ; punkt darunter 
         BSSendUnicodeChar(0x1E5B)
      else 
         sendinput {blind}r
      if (PriorDeadKey = "comp")
         CompKey := "r_small"
      else
         CompKey := ""
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "c2")          ; caron
         BSSendUnicodeChar(0x0158)
      else if (PriorDeadKey = "a1")      ; akut 
         BSSendUnicodeChar(0x0154)
      else if (PriorDeadKey = "a3")    ; cedilla 
         BSSendUnicodeChar(0x0156)
      else if (PriorDeadKey = "a5")  ; punkt dar�ber 
         BSSendUnicodeChar(0x1E58)
      else if (PriorDeadKey = "c6") ; punkt darunter 
         BSSendUnicodeChar(0x1E5A)
      else 
         sendinput {blind}R
      if (PriorDeadKey = "comp")
         CompKey := "r_capital"
      else
         CompKey := ""
   }
   else if Ebene = 3
   {
      send )
      CompKey := ""
   }
   else if Ebene = 4
   {
      if (PriorDeadKey = "c1")            ; circumflex
         BSSendUnicodeChar(0x2075)
      else if (PriorDeadKey = "c4")       ; toter -
         BSSendUnicodeChar(0x2085)
      else
         Send 5
      CompKey := ""
   }
   else if Ebene = 5
   {
      SendUnicodeChar(0x03C1) ;rho
      CompKey := ""
   }
   else if Ebene = 6
   {
      SendUnicodeChar(0x211D) ; R (reelle Zahlen)
      CompKey := ""
   }
   PriorDeadKey := ""
return

*l::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c2")          ; caron 
         BSSendUnicodeChar(0x0165)
      else if (PriorDeadKey = "a3")    ; cedilla
         BSSendUnicodeChar(0x0163)
      else if (PriorDeadKey = "c4")   ; Querstrich
         BSSendUnicodeChar(0x0167)
      else if (PriorDeadKey = "a5")  ; punkt dar�ber 
         BSSendUnicodeChar(0x1E6B)
      else if (PriorDeadKey = "c6") ; punkt darunter 
         BSSendUnicodeChar(0x1E6D)
      else 
         sendinput {blind}t
      if (PriorDeadKey = "comp")
         CompKey := "t_small"
      else
         CompKey := ""
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "c2")          ; caron
         BSSendUnicodeChar(0x0164)
      else if (PriorDeadKey = "a3")    ; cedilla 
         BSSendUnicodeChar(0x0162)
      else if (PriorDeadKey = "c4")   ; Querstrich
         BSSendUnicodeChar(0x0166)
      else if (PriorDeadKey = "a5")  ; punkt dar�ber 
         BSSendUnicodeChar(0x1E6A)
      else if (PriorDeadKey = "c6") ; punkt darunter 
         BSSendUnicodeChar(0x1E6C)
      else 
         sendinput {blind}T
      if (PriorDeadKey = "comp")
         CompKey := "t_capital"
      else
         CompKey := ""
   }
   else if Ebene = 3
   {
      send {blind}- ; Bis
      CompKey := ""
   }
   else if Ebene = 4
   {
      if (PriorDeadKey = "c1")            ; circumflex
         BSSendUnicodeChar(0x2076)
      else if (PriorDeadKey = "c4")       ; toter -
         BSSendUnicodeChar(0x2086)
      else
         Send 6
      CompKey := ""
   }
   else if Ebene = 5
   {
      SendUnicodeChar(0x03C4) ; tau
      CompKey := ""
   }
   else if Ebene = 6
   {
      SendUnicodeChar(0x2202 ) ; partielle Ableitung
      CompKey := ""
   }
   PriorDeadKey := ""
return

*�::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c4")        ; Querstrich
         BSSendUnicodeChar(0x0111)
      else if (PriorDeadKey = "t5")  ; Schr�gstrich
         BSSendUnicodeChar(0x00F0)
      else if (PriorDeadKey = "c2")     ; caron
         BSSendUnicodeChar(0x010F)
      else if (PriorDeadKey = "a5")  ; punkt dar�ber 
         BSSendUnicodeChar(0x1E0B)
      else if (PriorDeadKey = "c6") ; punkt darunter 
         BSSendUnicodeChar(0x1E0D)
      else 
         sendinput {blind}d
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "c4")        ; Querstrich
         BSSendUnicodeChar(0x0110)
      else if (PriorDeadKey = "t5")  ; Schr�gstrich
         BSSendUnicodeChar(0x00D0)
      else if (PriorDeadKey = "c2")     ; caron 
         BSSendUnicodeChar(0x010E)
      else if (PriorDeadKey = "a5")  ; punkt dar�ber 
         BSSendUnicodeChar(0x1E0A)
      else if (PriorDeadKey = "c6") ; punkt darunter 
         BSSendUnicodeChar(0x1E0D)
      else sendinput {blind}D
   }
   else if Ebene = 3
      send :
   else if Ebene = 4
     {}  ; leer ... Send `,
   else if Ebene = 5
      SendUnicodeChar(0x03B4) ;delta
   else if Ebene = 6
      SendUnicodeChar(0x0394)  ; Delta
   PriorDeadKey := ""   CompKey := ""
return

*�::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "t3")       ; Diaerese
         Send {bs}�
      else if (PriorDeadKey = "a1")      ; akut 
         BSSendUnicodeChar(0x00FD)
      else if (PriorDeadKey = "c1")    ; circumflex
         BSSendUnicodeChar(0x0177)
      else
         sendinput {blind}y
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "a1")           ; akut 
         BSSendUnicodeChar(0x00DD)
      else if (PriorDeadKey = "t3")    ; Diaerese
         Send {bs}�
      else if (PriorDeadKey = "c1")      ; circumflex
         BSSendUnicodeChar(0x0176)
      else
         sendinput {blind}Y
   }
   else if Ebene = 3
      send @
   else if Ebene = 4
  	  { } ; leer ... 
   else if Ebene = 5
  	  SendUnicodeChar(0x03C5) ; upsilon
   else if Ebene = 6
      SendUnicodeChar(0x2207) ; nabla
   PriorDeadKey := ""   CompKey := ""
return

;SC02B (#) wird zu Mod3


/*
   ------------------------------------------------------
   Reihe 4
   ------------------------------------------------------
*/

;SC056 (<) wird zu Mod4

*y::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "t2")        ; macron
         BSSendUnicodeChar(0x01D6)
      else if (PriorDeadKey = "a1")   ; akut 
         BSSendUnicodeChar(0x01D8)
      else if (PriorDeadKey = "a2")   ; grave
         BSSendUnicodeChar(0x01DC)
      else if (PriorDeadKey = "c2")   ; caron
         BSSendUnicodeChar(0x01DA)
      else
         sendinput {blind}�
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "t2")        ; macron
         BSSendUnicodeChar(0x01D5)
      else if (PriorDeadKey = "a1")   ; akut 
         BSSendUnicodeChar(0x01D7)
      else if (PriorDeadKey = "a2")   ; grave
         BSSendUnicodeChar(0x01DB)
      else if (PriorDeadKey = "c2")   ; caron
         BSSendUnicodeChar(0x01D9)
      else
         sendinput {blind}�
   }
   else if Ebene = 3
      send {blind}{#}
   else if Ebene = 4
      Send {Esc}
   else if Ebene = 5
     {} ; leer
   else if Ebene = 6
      SendUnicodeChar(0x221D) ; proportional

   PriorDeadKey := ""   CompKey := ""
return

*x::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "t2")        ; macron
         BSSendUnicodeChar(0x022B)
      else
         sendinput {blind}�
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "t2")        ; macron
         BSSendUnicodeChar(0x022A)
      else
         sendinput {blind}�
   }
   else if Ebene = 3
      send $
   else if Ebene = 4
      Send {Tab}
   else if Ebene = 5
       {} ;leer
   else if Ebene = 6
      SendUnicodeChar(0x2111) ; Fraktur I
   PriorDeadKey := ""   CompKey := ""
return

*c::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "t2")        ; macron
         BSSendUnicodeChar(0x01DF)
      else
         sendinput {blind}�
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "t2")        ; macron
         BSSendUnicodeChar(0x001DE)
      else
         sendinput {blind}�
   }
   else if Ebene = 3
      send |
   else if Ebene = 4
      Send {PgDn}    ; Next
   else if Ebene = 5
      SendUnicodeChar(0x03B7) ; eta
   else if Ebene = 6
      SendUnicodeChar(0x211C) ; altes R
   PriorDeadKey := ""   CompKey := ""
return

*v::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "a5")      ; punkt dar�ber 
         BSSendUnicodeChar(0x1E57)
      else
         sendinput {blind}p
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "a5")      ; punkt dar�ber 
         BSSendUnicodeChar(0x1E56)
      else 
         sendinput {blind}P
   }
   else if Ebene = 3
   {
      if (PriorDeadKey = "t1")    ; tilde
         BSSendUnicodeChar(0x2248)
      else
         sendraw ~
   }      
   else if Ebene = 4
      Send {Enter}
   else if Ebene = 5
      SendUnicodeChar(0x03C0) ;pi
   else if Ebene = 6
      SendUnicodeChar(0x03A0)  ; Pi
   PriorDeadKey := ""   CompKey := ""
return

*b::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c2")         ; caron
         BSSendUnicodeChar(0x017E)
      else if (PriorDeadKey = "a1")     ; akut
         BSSendUnicodeChar(0x017A)
      else if (PriorDeadKey = "a5") ; punkt dr�ber
         BSSendUnicodeChar(0x017C)
      else if (PriorDeadKey = "c6") ; punkt drunter
         BSSendUnicodeChar(0x1E93)
      else 
         sendinput {blind}z
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "c2")         ; caron  
         BSSendUnicodeChar(0x017D)
      else if (PriorDeadKey = "a1")     ; akut 
         BSSendUnicodeChar(0x0179)
      else if (PriorDeadKey = "a5") ; punkt dar�ber 
         BSSendUnicodeChar(0x017B)
      else if (PriorDeadKey = "c6") ; punkt drunter
         BSSendUnicodeChar(0x1E92)
      else
         sendinput {blind}Z
   }
   else if Ebene = 3
      send ``{space} ; untot
   else if Ebene = 5
     {} ; leer   
   else if Ebene = 5
      SendUnicodeChar(0x03B6) ;zeta 
   else if Ebene = 6
      SendUnicodeChar(0x2124)  ; Z (ganze Zahlen)
   PriorDeadKey := ""   CompKey := ""
return

*n::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "a5")      ; punkt dar�ber 
         BSSendUnicodeChar(0x1E03)
      else 
         sendinput {blind}b
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "a5")       ; punkt dar�ber 
         BSSendUnicodeChar(0x1E02)
      else 
         sendinput {blind}B
   }
   else if Ebene = 3
      send {blind}{+}
   else if Ebene = 4
      send {NumpadDot}
   else if Ebene = 5
      SendUnicodeChar(0x03B2) ; beta
   else if Ebene = 6
      SendUnicodeChar(0x21D2) ; Doppel-Pfeil rechts
   PriorDeadKey := ""   CompKey := ""
return

*m::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "a5")       ; punkt dar�ber 
         BSSendUnicodeChar(0x1E41)
      else if (PriorDeadKey = "c6") ; punkt darunter 
         BSSendUnicodeChar(0x1E43)
      else if ( (CompKey = "t_small") or (CompKey = "t_capital") )       ; compose
         CompUnicodeChar(0x2122)          ; TM
      else if ( (CompKey = "s_small") or (CompKey = "s_capital") )       ; compose
         CompUnicodeChar(0x2120)          ; SM
      else
         sendinput {blind}m
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "a5")       ; punkt dar�ber 
         BSSendUnicodeChar(0x1E40)
      else if (PriorDeadKey = "c6") ; punkt darunter 
         BSSendUnicodeChar(0x1E42)
      else if ( (CompKey = "t_capital") or (CompKey = "t_small") )       ; compose
         CompUnicodeChar(0x2122)          ; TM
      else if ( (CompKey = "s_capital") or (CompKey = "s_small") )       ; compose
         CompUnicodeChar(0x2120)          ; SM
      else 
         sendinput {blind}M
   }
   else if Ebene = 3
      send `%
   else if Ebene = 4
   {
      if (PriorDeadKey = "c1")            ; circumflex
         BSSendUnicodeChar(0x00B9)
      else if (PriorDeadKey = "c4")       ; toter -
         BSSendUnicodeChar(0x2081)
      else
         Send 1
   }
   else if Ebene = 5
      SendUnicodeChar(0x03BC) ; griechisch mu, micro w�re 0x00B5
   else if Ebene = 6
      SendUnicodeChar(0x21D4) ; doppelter Doppelpfeil (genau dann wenn)
   PriorDeadKey := ""   CompKey := ""
return

*,::
   EbeneAktualisieren()
   if Ebene = 1
       {  
         if GetKeyState("CapsLock","T") 
         {
           if (IsModifierPressed())
           {
             send {blind},
           }
           else
           {
              send `,
           }
               
         }
         else {
           send {blind},
         }
       }
   else if Ebene = 2
       SendUnicodeChar(0x22EE) ;  vertikale ellipse 
   else if Ebene = 3
      send "
   else if Ebene = 4
   {
      if (PriorDeadKey = "c1")            ; circumflex
         BSSendUnicodeChar(0x00B2)
      else if (PriorDeadKey = "c4")       ; toter -
         BSSendUnicodeChar(0x2082)
      else
         Send 2
   }
   else if Ebene = 5
      SendUnicodeChar(0x03F1) ; varrho
   else if Ebene = 6
      SendUnicodeChar(0x21D0) ; Doppelpfeil links
   PriorDeadKey := ""   CompKey := ""
return

*.::
   EbeneAktualisieren()
   if Ebene = 1
        {  
         if GetKeyState("CapsLock","T") 
         {
           if (IsModifierPressed())
           {
             send {blind}.
           }
           else
           {
              send .
           }
               
         }
         else {
           send {blind}.
         }
       }
  else if Ebene = 2
      SendUnicodeChar(0x2026)  ; ellipse
   else if Ebene = 3
      send '
   else if Ebene = 4
   {
      if (PriorDeadKey = "c1")            ; circumflex
         BSSendUnicodeChar(0x00B3)
      else if (PriorDeadKey = "c4")       ; toter -
         BSSendUnicodeChar(0x2083)
      else
         Send 3
   }
   else if Ebene = 5
      SendUnicodeChar(0x03B8) ;theta
   else if Ebene = 6
      SendUnicodeChar(0x0398)  ; Theta
   PriorDeadKey := ""   CompKey := ""
return


*-::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (PriorDeadKey = "c1")           ; circumflex
         BSSendUnicodeChar(0x0135)
      else if (PriorDeadKey = "c2")      ; caron
         BSSendUnicodeChar(0x01F0)
      else if (CompKey = "i_small")        ; compose
         CompUnicodeChar(0x0133)          ; ij
      else if (CompKey = "l_small")        ; compose
         CompUnicodeChar(0x01C9)          ; lj
      else if (CompKey = "l_capital")       ; compose
         CompUnicodeChar(0x01C8)          ; Lj
      else
         sendinput {blind}j
   }
   else if Ebene = 2
   {
      if (PriorDeadKey = "c1")            ; circumflex
         BSSendUnicodeChar(0x0134)
      else if (CompKey = "i_capital")        ; compose
         CompUnicodeChar(0x0132)          ; IJ
      else if (CompKey = "l_capital")        ; compose
         CompUnicodeChar(0x01C7)          ; LJ
      else
         sendinput {blind}J
   }
   else if Ebene = 3
      send `;
   else if Ebene = 4
     {} ; leer ... Send .
   else if Ebene = 5
      SendUnicodeChar(0x03D1) ; vartheta
   else if Ebene = 6
      SendUnicodeChar(0x2261) ; identisch
   PriorDeadKey := ""   CompKey := ""
return

/*
   ------------------------------------------------------
   Numpad
   ------------------------------------------------------

   folgende Tasten verhalten sich bei ein- und ausgeschaltetem
   NumLock gleich:
*/

*NumpadDiv::
   EbeneAktualisieren()
   if ( (Ebene = 1) or (Ebene = 2) )
      send {NumpadDiv}
   else if Ebene = 3
      send �
   else if ( (Ebene = 4) or (Ebene = 5) )
      SendUnicodeChar(0x2215)   ; slash
   PriorDeadKey := ""   CompKey := ""
return

*NumpadMult::
   EbeneAktualisieren()
   if ( (Ebene = 1) or (Ebene = 2) )
      send {NumpadMult}
   else if Ebene = 3
      send �
   else if ( (Ebene = 4) or (Ebene = 5) )
      SendUnicodeChar(0x22C5)  ; cdot
   PriorDeadKey := ""   CompKey := ""
return

*NumpadSub::
   EbeneAktualisieren()
   if ( (Ebene = 1) or (Ebene = 2) )
   {
      if (PriorDeadKey = "c1")          ; circumflex
         BSSendUnicodeChar(0x207B)
      else if (PriorDeadKey = "c4")       ; toter -
         BSSendUnicodeChar(0x208B)         
      else
         send {blind}{NumpadSub}
   }
   else if Ebene = 3
      SendUnicodeChar(0x2212) ; echtes minus
   PriorDeadKey := ""   CompKey := ""
return

*NumpadAdd::
   EbeneAktualisieren()
   if ( (Ebene = 1) or (Ebene = 2) )
   {
      if (PriorDeadKey = "c1")          ; circumflex
         BSSendUnicodeChar(0x207A)
      else if (PriorDeadKey = "c4")       ; toter -
         BSSendUnicodeChar(0x208A)         
      else
         send {blind}{NumpadAdd}
   }
   else if Ebene = 3
      send �
   else if ( (Ebene = 4) or (Ebene = 5) )
      SendUnicodeChar(0x2213)   ; -+
   PriorDeadKey := ""   CompKey := ""
return

*NumpadEnter::
   EbeneAktualisieren()
   if ( (Ebene = 1) or (Ebene = 2) )
      send {NumpadEnter}      
   else if Ebene = 3
      SendUnicodeChar(0x2260) ; neq
   else if ( (Ebene = 4) or (Ebene = 5) )
      SendUnicodeChar(0x2248) ; approx
   PriorDeadKey := ""   CompKey := ""
return

/*
   folgende Tasten verhalten sich bei ein- und ausgeschaltetem NumLock
   unterschiedlich:

   bei NumLock ein
*/



*Numpad7::
   EbeneAktualisieren()
   if Ebene = 1
   {
      send {blind}{Numpad7}
      if (PriorDeadKey = "comp")
         CompKey := "Num_7"
      else
         CompKey := ""       
   }
   else if Ebene = 2
   {
      send {NumpadHome}
      CompKey := ""
   }
   else if Ebene = 3
   {
      SendUnicodeChar(0x2195)   ; Hoch-Runter-Pfeil
      CompKey := ""
   }
   else if ( (Ebene = 4) or (Ebene = 5) )
   {
      SendUnicodeChar(0x226A)  ; ll
      CompKey := ""
   }
   PriorDeadKey := ""
return

*Numpad8::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (CompKey = "Num_1")
         CompUnicodeChar(0x215B)       ; 1/8
      else if (CompKey = "Num_3")
         CompUnicodeChar(0x215C)       ; 3/8
      else if (CompKey = "Num_5")
         CompUnicodeChar(0x215D)       ; 5/8
      else if (CompKey = "Num_7")
         CompUnicodeChar(0x215E)       ; 7/8
      else
         send {blind}{Numpad8}
      if (PriorDeadKey = "comp")
         CompKey := "Num_8"
      else
         CompKey := "" 
   }
   else if Ebene = 2
   {
      send {NumpadUp}
      CompKey := ""
   }
   else if Ebene = 3
   {
      SendUnicodeChar(0x2191)     ; uparrow
      CompKey := ""
   }
   else if ( (Ebene = 4) or (Ebene = 5) )
   {
      SendUnicodeChar(0x2229)    ; intersection
      CompKey := ""
   }
   PriorDeadKey := ""   CompKey := ""
return

*Numpad9::
   EbeneAktualisieren()
   if Ebene = 1
   {
      send {blind}{Numpad9}
      if (PriorDeadKey = "comp")
         CompKey := "Num_9"
      else
         CompKey := "" 
   }
   else if Ebene = 2
   {
      send {NumpadPgUp}
      CompKey := ""
   }
   else if ( (Ebene = 4) or (Ebene = 5) )
   {
      SendUnicodeChar(0x226B)  ; gg
      CompKey := ""
   }
   PriorDeadKey := ""
return



*Numpad4::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (CompKey = "Num_1")
         CompUnicodeChar(0x00BC)       ; 1/4
      else if (CompKey = "Num_3")
         CompUnicodeChar(0x00BE)       ; 3/4
      else
         send {blind}{Numpad4}
      if (PriorDeadKey = "comp")
         CompKey := "Num_4"
      else
         CompKey := ""
   }
   else if Ebene = 2
   {
      send {NumpadLeft}
      CompKey := ""
   }
   else if Ebene = 3
   {
      SendUnicodeChar(0x2190)     ; leftarrow
      CompKey := ""
   }
   else if ( (Ebene = 4) or (Ebene = 5) )
   {
      SendUnicodeChar(0x2282)  ; subset of
      CompKey := ""
   }
   PriorDeadKey := ""
return

*Numpad5::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (CompKey = "Num_1")
         CompUnicodeChar(0x2155)       ; 1/5
      else if (CompKey = "Num_2")
         CompUnicodeChar(0x2156)       ; 2/5
      else if (CompKey = "Num_3")
         CompUnicodeChar(0x2157)       ; 3/5
      else if (CompKey = "Num_4")
         CompUnicodeChar(0x2158)       ; 4/5
      else
         send {blind}{Numpad5}
      if (PriorDeadKey = "comp")
         CompKey := "Num_5"
      else
         CompKey := ""
   }
   else if Ebene = 2
   {
      send {NumpadClear}
      CompKey := ""
   }
   else if Ebene = 3
   {
      send �
      CompKey := ""
   }
   else if ( (Ebene = 4) or (Ebene = 5) )
   {
      SendUnicodeChar(0x220A) ; small element of
      CompKey := ""
   }
   PriorDeadKey := ""
return

*Numpad6::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (CompKey = "Num_1")
         CompUnicodeChar(0x2159)       ; 1/6
      else if (CompKey = "Num_5")
         CompUnicodeChar(0x215A)       ; 5/6
      else
         send {blind}{Numpad6}
      if (PriorDeadKey = "comp")
         CompKey := "Num_6"
      else
         CompKey := ""
   }
   else if Ebene = 2
   {
      send {NumpadRight}
      CompKey := ""
   }
   else if Ebene = 3
   {
      SendUnicodeChar(0x2192)     ; rightarrow
      CompKey := ""
   }
   else if ( (Ebene = 4) or (Ebene = 5) )
   {
      SendUnicodeChar(0x2283) ; superset of
      CompKey := ""
   }
   PriorDeadKey := ""
return

*Numpad1::
   EbeneAktualisieren()
   if Ebene = 1
   {
      send {blind}{Numpad1}
      if (PriorDeadKey = "comp")
         CompKey := "Num_1"
      else
         CompKey := ""
   }
   else if Ebene = 2
   {
      send {NumpadEnd}
      CompKey := ""
   }
   else if Ebene = 3
   {
      SendUnicodeChar(0x2194) ; Links-Rechts-Pfeil
      CompKey := ""
   }
   else if ( (Ebene = 4) or (Ebene = 5) )
   {
      SendUnicodeChar(0x2264)   ; leq
      CompKey := ""
   }
   PriorDeadKey := ""
return

*Numpad2::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (CompKey = "Num_1")
         CompUnicodeChar(0x00BD)       ; 1/2
      else
         send {blind}{Numpad2}
      if (PriorDeadKey = "comp")
         CompKey := "Num_2"
      else
         CompKey := ""
   }
   else if Ebene = 2
   {
      send {NumpadDown}
      CompKey := ""
   }
   else if Ebene = 3
   {
      SendUnicodeChar(0x2193)     ; downarrow
      CompKey := ""
   }
   else if ( (Ebene = 4) or (Ebene = 5) )
   {
      SendUnicodeChar(0x222A)  ; vereinigt
      CompKey := ""
   }
   PriorDeadKey := ""
return

*Numpad3::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (CompKey = "Num_1")
         CompUnicodeChar(0x2153)       ; 1/3
      else if (CompKey = "Num_2")
         CompUnicodeChar(0x2154)       ; 2/3
      else
         send {blind}{Numpad3}
      if (PriorDeadKey = "comp")
         CompKey := "Num_3"
      else
         CompKey := ""
   }
   else if Ebene = 2
      send {NumpadPgDn}
   else if Ebene = 3
      SendUnicodeChar(0x21CC) ; RIGHTWARDS HARPOON OVER LEFTWARDS HARPOON
   else if ( (Ebene = 4) or (Ebene = 5) )
      SendUnicodeChar(0x2265)  ; geq
   PriorDeadKey := ""   CompKey := ""
return

*Numpad0::
   EbeneAktualisieren()
   if Ebene = 1
   {
      send {blind}{Numpad0}
      if (PriorDeadKey = "comp")
         CompKey := "Num_0"
      else
         CompKey := ""
   }
   else if Ebene = 2
   {
      send {NumpadIns}
      CompKey := ""
   }
   else if Ebene = 3
   {
      send `%
      CompKey := ""
   }
   else if ( (Ebene = 4) or (Ebene = 5) )
   {
      send � 
      CompKey := ""
   }
   PriorDeadKey := ""
return

*NumpadDot::
   EbeneAktualisieren()
   if Ebene = 1
   {
      send {NumpadDot}
      CompKey := ""
   }
   else if Ebene = 2
   {
      send {NumpadDel}
      CompKey := ""
   }
   else if Ebene = 3
   {
      send .
      CompKey := ""
   }
   else if ( (Ebene = 4) or (Ebene = 5) )
   {
      send `,
      CompKey := ""
   }
   PriorDeadKey := ""
return

/*
   bei NumLock aus
*/

*NumpadHome::
   EbeneAktualisieren()
   if Ebene = 1
   {
      send {NumpadHome}
      CompKey := ""
   }
   else if Ebene = 2
   {
      send {Numpad7}
      if (PriorDeadKey = "comp")
         CompKey := "Num_7"
      else
         CompKey := ""
   }
   else if ( (Ebene = 4) or (Ebene = 5) )
   {
      SendUnicodeChar(0x226A)  ; ll
      CompKey := ""
   }
   PriorDeadKey := ""
return

*NumpadUp::
   EbeneAktualisieren()
   if Ebene = 1
   {
      send {NumpadUp}
      CompKey := ""
   }
   else if Ebene = 2
   {
      if (CompKey = "Num_1")
         CompUnicodeChar(0x215B)       ; 1/8
      else if (CompKey = "Num_3")
         CompUnicodeChar(0x215C)       ; 3/8
      else if (CompKey = "Num_5")
         CompUnicodeChar(0x215D)       ; 5/8
      else if (CompKey = "Num_7")
         CompUnicodeChar(0x215E)       ; 7/8
      else
         send {Numpad8}
      if (PriorDeadKey = "comp")
         CompKey := "Num_8"
      else
         CompKey := ""
   }
   else if Ebene = 3
   {
      SendUnicodeChar(0x2191)     ; uparrow
      CompKey := ""
   }
   else if ( (Ebene = 4) or (Ebene = 5) )
   {
      SendUnicodeChar(0x2229)    ; intersection
      CompKey := ""
   }
   PriorDeadKey := ""
return

*NumpadPgUp::
   EbeneAktualisieren()
   if Ebene = 1
   {
      send {NumpadPgUp}
      CompKey := ""
   }
   else if Ebene = 2
   {
      send {Numpad9}
      if (PriorDeadKey = "comp")
         CompKey := "Num_9"
      else
         CompKey := ""
   }
   else if ( (Ebene = 4) or (Ebene = 5) )
   {
      SendUnicodeChar(0x226B)  ; gg
      CompKey := ""
   }
   PriorDeadKey := ""
return

*NumpadLeft::
   EbeneAktualisieren()
   if Ebene = 1
   {
      send {NumpadLeft}
      CompKey := ""
   }
   else if Ebene = 2
   {
      if (CompKey = "Num_1")
         CompUnicodeChar(0x00BC)       ; 1/4
      else if (CompKey = "Num_3")
         CompUnicodeChar(0x00BE)       ; 3/4
      else
         send {Numpad4}
      if (PriorDeadKey = "comp")
         CompKey := "Num_4"
      else
         CompKey := ""
   }
   else if Ebene = 3
   {
      SendUnicodeChar(0x2190)     ; leftarrow
      CompKey := ""
   }
   else if ( (Ebene = 4) or (Ebene = 5) )
   {
      SendUnicodeChar(0x2282)  ; subset of
      CompKey := ""
   }
   PriorDeadKey := ""
return

*NumpadClear::
   EbeneAktualisieren()
   if Ebene = 1
   {
      send {NumpadClear}
      CompKey := ""
   }
   else if Ebene = 2
   {
      if (CompKey = "Num_1")
         CompUnicodeChar(0x2155)       ; 1/5
      else if (CompKey = "Num_2")
         CompUnicodeChar(0x2156)       ; 2/5
      else if (CompKey = "Num_3")
         CompUnicodeChar(0x2157)       ; 3/5
      else if (CompKey = "Num_4")
         CompUnicodeChar(0x2158)       ; 4/5
      else
         send {Numpad5}
      if (PriorDeadKey = "comp")
         CompKey := "Num_5"
      else
         CompKey := ""
   }
   else if Ebene = 3
   {
      send �
      CompKey := ""
   }
   else if ( (Ebene = 4) or (Ebene = 5) )
   {
      SendUnicodeChar(0x220A) ; small element of
      CompKey := ""
   }
   PriorDeadKey := ""
return

*NumpadRight::
   EbeneAktualisieren()
   if Ebene = 1
   {
      send {NumpadRight}
      CompKey := ""
   }
   else if Ebene = 2
   {
      if (CompKey = "Num_1")
         CompUnicodeChar(0x2159)       ; 1/6
      else if (CompKey = "Num_5")
         CompUnicodeChar(0x215A)       ; 5/6
      else
         send {Numpad6}
      if (PriorDeadKey = "comp")
         CompKey := "Num_6"
      else
         CompKey := ""
   }
   else if Ebene = 3
   {
      SendUnicodeChar(0x2192)     ; rightarrow
      CompKey := ""
   }
   else if ( (Ebene = 4) or (Ebene = 5) )
   {
      SendUnicodeChar(0x2283) ; superset of
      CompKey := ""
   }
   PriorDeadKey := ""
return

*NumpadEnd::
   EbeneAktualisieren()
   if Ebene = 1
   {
      send {NumpadEnd}
      CompKey := ""
   }
   else if Ebene = 2
   {
      send {Numpad1}
      if (PriorDeadKey = "comp")
         CompKey := "Num_1"
      else
         CompKey := ""
   }
   else if Ebene = 3
   {
      SendUnicodeChar(0x21CB) ; LEFTWARDS HARPOON OVER RIGHTWARDS HARPOON
      CompKey := ""
   }
   else if ( (Ebene = 4) or (Ebene = 5) )
   {
      SendUnicodeChar(0x2264)   ; leq
      CompKey := ""
   }
   PriorDeadKey := ""
return

*NumpadDown::
   EbeneAktualisieren()
   if Ebene = 1
   {
      send {NumpadDown}
      CompKey := ""
   }
   else if Ebene = 2
   {
      if (CompKey = "Num_1")
         CompUnicodeChar(0x00BD)       ; 1/2
      else
         send {Numpad2}
      if (PriorDeadKey = "comp")
         CompKey := "Num_2"
      else
         CompKey := ""
   }
   else if Ebene = 3
   {
      SendUnicodeChar(0x2193)     ; downarrow
      CompKey := ""
   }
   else if ( (Ebene = 4) or (Ebene = 5) )
   {
      SendUnicodeChar(0x222A)  ; vereinigt
      CompKey := ""
   }
   PriorDeadKey := ""
return

*NumpadPgDn::
   EbeneAktualisieren()
   if Ebene = 1
   {
      send {NumpadPgDn}
      CompKey := ""
   }
   else if Ebene = 2
   {
      if (CompKey = "Num_1")
         CompUnicodeChar(0x2153)       ; 1/3
      else if (CompKey = "Num_2")
         CompUnicodeChar(0x2154)       ; 2/3
      else
         send {Numpad3}
      if (PriorDeadKey = "comp")
         CompKey := "Num_3"
      else
         CompKey := ""
   }
   else if Ebene = 3
   {
      SendUnicodeChar(0x21CC) ; RIGHTWARDS HARPOON OVER LEFTWARDS HARPOON   
      CompKey := ""
   }
   else if ( (Ebene = 4) or (Ebene = 5) )
   {
      SendUnicodeChar(0x2265)  ; geq
      CompKey := ""
   }
   PriorDeadKey := ""
return

*NumpadIns::
   EbeneAktualisieren()
   if Ebene = 1
   {
      send {NumpadIns}
      CompKey := ""
   }
   else if Ebene = 2
   {
      send {Numpad0}
      if (PriorDeadKey = "comp")
         CompKey := "Num_0"
      else
         CompKey := ""
   }
   else if Ebene = 3
   {
      send `%
      CompKey := ""
   }
   else if ( (Ebene = 4) or (Ebene = 5) )
   {
      send � 
      CompKey := ""
   }
   PriorDeadKey := ""
return

*NumpadDel::
   EbeneAktualisieren()
   if Ebene = 1
   {
      send {NumpadDel}
      CompKey := ""
   }
   else if Ebene = 2
   {
      send {NumpadDot}
      CompKey := ""
   }
   else if Ebene = 3
   {
      send .
      CompKey := ""
   }
   else if ( (Ebene = 4) or (Ebene = 5) )
   {
      send `,
      CompKey := ""
   }
   PriorDeadKey := ""
return


/*
   ------------------------------------------------------
   Sondertasten
   ------------------------------------------------------
*/

*Space::
   EbeneAktualisieren()
   if Ebene = 1
   {
      if (CompKey = "r_small_1")
         Comp3UnicodeChar(0x2170)          ; r�misch i
      else if (CompKey = "r_capital_1")
         Comp3UnicodeChar(0x2160)          ; r�misch I
      else
         Send {blind}{Space}
   }
   if  Ebene  =  2
      Send  {blind}{Space}
   if Ebene = 3
      Send {blind}{Space}
   if Ebene = 4
   {
      if (PriorDeadKey = "c1")            ; circumflex
         BSSendUnicodeChar(0x2070)
      else if (PriorDeadKey = "c4")       ; toter -
         BSSendUnicodeChar(0x2080)
      else
         Send 0
   }
   else if Ebene = 5
      SendUnicodeChar(0x00A0)   ; gesch�tztes Leerzeichen
   else if Ebene = 6
      SendUnicodeChar(0x202F) ; schmales Leerzeichen
   PriorDeadKey := ""   CompKey := ""
return

/*
   Folgende Tasten sind nur aufgef�hrt, um PriorDeadKey zu leeren.
   Irgendwie sieht das noch nicht sch�n aus. Vielleicht l�sst sich dieses
   Problem irgendwie eleganter l�sen...
   
   Nachtrag:
   Weil es mit Alt+Tab Probleme gab, wird hier jetzt erstmal rumgeflickschustert,
   bis eine allgemeinere L�sung gefunden wurde.
*/

*Enter::
   sendinput {Blind}{Enter}
   PriorDeadKey := ""   CompKey := ""
return

*Backspace::
   sendinput {Blind}{Backspace}
   PriorDeadKey := ""   CompKey := ""
return



/*
Auf Mod3+Tab liegt Compose. AltTab funktioniert, jedoch ShiftAltTab nicht.
Wenigstens kommt es jetzt nicht mehr zu komischen Ergebnissen, wenn man Tab 
nach einem DeadKey dr�ckt...
*/

*Tab::
   if ( GetKeyState("SC038","P") )
   {
      SC038 & Tab::AltTab            ; http://de.autohotkey.com/docs/Hotkeys.htm#AltTabDetail
   }
   else if GetKeyState("#","P")
   {
      PriorDeadKey := "comp"
      CompKey := ""
   }
   else
   {
      send {blind}{Tab}
      PriorDeadKey := ""
      CompKey := ""
   }
return

*SC038::                            ; LAlt, damit AltTab funktioniert
   send {blind}{LAlt}
   PriorDeadKey := ""   CompKey := ""
return

*Home::
   sendinput {Blind}{Home}
   PriorDeadKey := ""   CompKey := ""
return

*End::
   sendinput {Blind}{End}
   PriorDeadKey := ""   CompKey := ""
return

*PgUp::
   sendinput {Blind}{PgUp}
   PriorDeadKey := ""   CompKey := ""
return

*PgDn::
   sendinput {Blind}{PgDn}
   PriorDeadKey := ""   CompKey := ""
return

*Up::
   sendinput {Blind}{Up}
   PriorDeadKey := ""   CompKey := ""
return

*Down::
   sendinput {Blind}{Down}
   PriorDeadKey := ""   CompKey := ""
return

*Left::
   sendinput {Blind}{Left}
   PriorDeadKey := ""   CompKey := ""
return

*Right::
   sendinput {Blind}{Right}
   PriorDeadKey := ""   CompKey := ""
return


/*
   ------------------------------------------------------
   Funktionen
   ------------------------------------------------------
*/

/*
Ebenen laut Referenz:
1. Ebene (kein Mod)      4. Ebene (Mod4)
2. Ebene (Umschalt)      5. Ebene (Mod3+Umschalt)
3. Ebene (Mod3)          6. Ebene (Mod3+Mod4)
*/
/*
EbeneAktualisieren()
{
   global
   Ebene = 1

   ; ist Shift down?
   if ( GetKeyState("Shift","P") )
   {
      Ebene += 1
   }
   ; ist Mod3 down?
   if ( GetKeyState("CapsLock","P") or GetKeyState("#","P") )
   {
      Ebene += 2
   }
   
   ; ist Mod4 down? Mod3 hat Vorrang!
   else if ( GetKeyState("<","P") or GetKeyState("SC138","P") )
   {
      Ebene += 4
   }
}
*/


 EbeneAktualisieren()
{
   global
   if (nurEbenenFuenfUndSechs)
   {
      if ( IsMod3Pressed() )
      {
        if ( IsShiftPressed() )
        {
           Ebene = 5
        }
        else if ( IsMod4Pressed() )
        {
           Ebene = 6      
        }
      } 
      else
      {
        Ebene = -1
      }  
   }
   else 
   {   
     if ( IsShiftPressed() )
     {  ; Umschalt
   		if ( IsMod3Pressed() )
	    	{ ; Umschalt UND Mod3 
            if ( IsMod4Pressed() )
            {  ; Umschald UND Mod3 UND Mod4 
               ; Ebene 8 impliziert Ebene 6
               Ebene = 6
             }
            else
            { ; Umschald UND Mod3 NICHT Mod4
                Ebene = 5	               
            }
        }
		else 
		{  ; Umschalt NICHT Mod3
            if ( IsMod4Pressed() )
            {  ; Umschald UND Mod4 NICHT Mod3
               ; Ebene 7 impliziert Ebene 4 
                Ebene = 6
            }
            else
            { ; Umschald NICHT Mod3 NICHT Mod4
               Ebene = 2	
            }
         }   
     }
     else
     { ; NICHT Umschalt
		if ( IsMod3Pressed() )
		{ ; Mod3 NICHT Umschalt 
           if ( IsMod4Pressed() )
           {  ; Mod3 UND Mod4 NICHT Umschalt
               Ebene = 6
           }
           else
           { ; Mod3 NICHT Mod4 NICHT Umschalt
               Ebene = 3	
           }
        }
		else 
		{  ; NICHT Umschalt NICHT Mod3
           if ( IsMod4Pressed() )
           {  ; Mod4 NICHT Umschalt NICHT Mod3 
               Ebene = 4
           }
           else
           { ; NICHT Umschalt NICHT Mod3 NICHT Mod4
               Ebene = 1
           }
       	}   
      }
   }
}

IsShiftPressed()
{
  return GetKeyState("Shift","P")
}

IsMod3Pressed()
{
  return ( GetKeyState("CapsLock","P") or GetKeyState("#","P") )
}

IsMod4Pressed()
{
   global
   if (IsMod4Locked) 
   {
      if (IsShiftPressed()) 
      {
       return ( GetKeyState("<","P") or GetKeyState("SC138","P") )
      }
      else 
      {
       return (not ( GetKeyState("<","P") or GetKeyState("SC138","P") ))
      } 
   }
   else {
       return ( GetKeyState("<","P") or GetKeyState("SC138","P") )
   }
}


/*************************
  Alte Methoden
*************************/

/*
Unicode(code)
{
   saved_clipboard := ClipboardAll
   Transform, Clipboard, Unicode, %code%
   sendplay ^v
   Clipboard := saved_clipboard
}

BSUnicode(code)
{
   saved_clipboard := ClipboardAll
   Transform, Clipboard, Unicode, %code%
   sendplay {bs}^v
   Clipboard := saved_clipboard
}
*/

IsModifierPressed()
{
   if (GetKeyState("LControl","P") or GetKeyState("RControl","P") or GetKeyState("LAlt","P") or GetKeyState("RAltl","P") or GetKeyState("LWin","P") or GetKeyState("RWin","P") or GetKeyState("LShift","P") or GetKeyState("RShift","P") or GetKeyState("AltGr","P") ) 
    {
       return 1
    }
    else
    {
       return 0
    }
}

SendUnicodeChar(charCode)
{
   VarSetCapacity(ki, 28 * 2, 0)

   EncodeInteger(&ki + 0, 1)
   EncodeInteger(&ki + 6, charCode)
   EncodeInteger(&ki + 8, 4)
   EncodeInteger(&ki +28, 1)
   EncodeInteger(&ki +34, charCode)
   EncodeInteger(&ki +36, 4|2)

   DllCall("SendInput", "UInt", 2, "UInt", &ki, "Int", 28)
}

BSSendUnicodeChar(charCode)
{
   send {bs}
   SendUnicodeChar(charCode)
}

CompUnicodeChar(charCode)
{
   send {bs}
	 SendUnicodeChar(charCode)
}

Comp3UnicodeChar(charCode)
{
   send {bs}
   send {bs}
   SendUnicodeChar(charCode)
}


EncodeInteger(ref, val)
{
   DllCall("ntdll\RtlFillMemoryUlong", "Uint", ref, "Uint", 4, "Uint", val)
}


/*
   ------------------------------------------------------
   Shift+Pause "pausiert" das Script.
   ------------------------------------------------------
*/

+pause::
Suspend, Permit
   goto togglesuspend
return

; ------------------------------------


togglesuspend:
   if A_IsSuspended
   {
      menu, tray, rename, %enable%, %disable%
	  menu, tray, tip, %name%
      suspend , off ; Schaltet Suspend aus -> NEO
   }
   else
   {
      menu, tray, rename, %disable%, %enable%
      menu, tray, tip, %name% : Deaktiviert  
      suspend , on  ; Schaltet Suspend ein -> QWERTZ 
   }

return



help:
   Run, %A_WinDir%\hh mk:@MSITStore:autohotkey.chm
return


about:
   msgbox, 64, %name% � Ergonomische Tastaturbelegung, 
   (
   %name% 
   `nDas Neo-Layout ersetzt das �bliche deutsche 
   Tastaturlayout mit der Alternative Neo, 
   beschrieben auf http://neo-layout.org/. 
   `nDazu sind keine Administratorrechte n�tig. 
   `nWenn Autohotkey aktiviert ist, werden alle Tastendrucke 
   abgefangen und statt dessen eine �bersetzung weitergeschickt. 
   `nDies geschieht transparent f�r den Anwender, 
   es muss nichts installiert werden. 
   `nDie Zeichen�bersetzung kann leicht �ber das Icon im 
   Systemtray deaktiviert werden.  `n
   )
return


neo:
   run http://neo-layout.org/
return

autohotkey:
   run http://autohotkey.com/
return

open:
   ListLines ; shows the Autohotkey window
return

edit:
   edit
return

reload:
   Reload
return

hide:
   menu, tray, noicon
return

exitprogram:
   exitapp
return