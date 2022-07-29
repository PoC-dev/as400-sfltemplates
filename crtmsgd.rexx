/* Create global message file */
/* $Id: crtmsgd.rexx,v 1.8 2022/07/29 16:30:47 poc Exp $ */

SAY "Creating Message File and messages...";

"CRTMSGF MSGF(QGPL/GENERICMSG) SIZE(2) CCSID(*MSGD)";

"ADDMSGD MSGID(ERR0000) MSGF(QGPL/GENERICMSG) MSG('Dateizugriffsfehler",
"&1.') SECLVL('Beim Zugriffsversuch von eben wurde ein Fehler &1",
"gefunden. Bitte den Programmierer informieren. Der Benutzer sollte",
"einstweilen die Applikation mit F3 beenden.') SEV(30)",
"FMT((*DEC 4 0)) TYPE(*NONE) LEN(*NONE)";

"ADDMSGD MSGID(ERR0012) MSGF(QGPL/GENERICMSG) MSG('Angeforderter",
"Datensatz nicht gefunden.') SECLVL('Der angeforderte Datensatz konnte",
"nicht (mehr) gefunden werden. Die Anforderung wird ignoriert. Markierung",
"entfernen und Eingabetaste drücken.') SEV(10) TYPE(*NONE) LEN(*NONE)";

"ADDMSGD MSGID(ERR1021) MSGF(QGPL/GENERICMSG) MSG('Wert bereits",
"vorhanden.') SECLVL('Der eingegebene Datensatz entspricht einem bereits",
"vorhanden und kann nicht eingefügt werden. Entweder Datensatz anpassen",
"und Eingabetaste drücken oder Hinzufügen von Daten durch F12=Abbruch",
"verwerfen.') SEV(30) TYPE(*NONE) LEN(*NONE)";

"ADDMSGD MSGID(ERR1218) MSGF(QGPL/GENERICMSG) MSG('Angeforderter",
"Datensatz in Benutzung.') SECLVL('Der angeforderte Datensatz wird",
"momentan durch einen anderen Benutzer bearbeitet. Eine Doppelbearbeitung",
"ist nicht vorgesehen.  Warten und Anforderung erneut absenden oder",
"Markierung entfernen und Eingabetaste drücken und mit anderen Arbeiten",
"fortfahren.') SEV(20) TYPE(*NONE) LEN(*NONE)";

"ADDMSGD MSGID(RDO1218) MSGF(QGPL/GENERICMSG) MSG('Angeforderter",
"Datensatz wurde schreibgeschützt geöffnet, da bereits in Bearbeitung.')",
"SECLVL('Der angeforderte Datensatz wird momentan durch einen anderen",
"Benutzer bearbeitet.  Eine Doppelbearbeitung ist nicht vorgesehen. Der",
"Datensatz wird daher ohne Bearbeitungsmöglichkeit angezeigt.') SEV(10)",
"TYPE(*NONE) LEN(*NONE)";

"ADDMSGD MSGID(INF0001) MSGF(QGPL/GENERICMSG) MSG('Datensatz nicht",
"geschrieben.') SECLVL('Der Datensatz wurde nicht geschrieben, da keine",
"Änderung im Bildschirmformular erkannt wurde.') SEV(0) TYPE(*NONE)",
"LEN(*NONE)";

"ADDMSGD MSGID(INF0999) MSGF(QGPL/GENERICMSG) MSG('Subfile ist voll.')",
"SECLVL('Das Subfile kann maximal 999 Einträge fassen. Das Programm hat",
"versucht, einen weiteren Eintrag anzuzeigen. Dieses Problem muss dem",
"Systemprogrammierer gemeldet werden. Einige Einträge sind nicht",
"sichtbar.') SEV(10) TYPE(*NONE) LEN(*NONE)";

/* vim: ft=rexx textwidth=72 colorcolumn=81 autoindent
 */
