/* Copyright 2007-2025 Patrik Schindler <poc@pocnet.net>.
 *
 * This file is part of a collection of templates for easy creation of
 *  subfile-based applications on AS/400, iSeries and IBM i.
 *
 * This is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License as published by the
 *  Free Software Foundation; either version 2 of the License, or (at your
 *  option) any later version.
 *
 * It is distributed in the hope that it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *  FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 *  for more details.
 *
 * You should have received a copy of the GNU General Public License along
 *  with it; if not, write to the Free Software Foundation, Inc., 59
 *  Temple Place, Suite 330, Boston, MA 02111-1307 USA or get it at
 *  http://www.gnu.org/licenses/gpl.html
 *
 * Create global message file
 * Run me with strrexprc srcfile(qgpl/sflvorlage) srcmbr(crtmsgd)
 */

SAY "(Re)creating Message File and messages...";

"DLTMSGF MSGF(QGPL/GENERICMSG)"

"CRTMSGF MSGF(QGPL/GENERICMSG) SIZE(2) CCSID(*MSGD)",
"TEXT('Messages SFLVORLAGE')";

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

"ADDMSGD MSGID(SLT00001) MSGF(QGPL/GENERICMSG) MSG('Nur einen Datensatz",
"wählen.') SECLVL('Exakt einen Datensatz mit '1' markieren. Mehrfache",
"Auswahlen sind nicht zulässig. Als Abkürzung zum Löschen von mehrfachen",
"auswahlen F5=Aktualisieren drücken, um alle Datensätze neu zu laden und",
"Selektionen zu verwerfen.') SEV(10) TYPE(*NONE) LEN(*NONE)";

/* vim: ft=rexx textwidth=72 colorcolumn=81 autoindent
 */
