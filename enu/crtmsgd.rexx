/* Copyright 2007-2026 Patrik Schindler <poc@pocnet.net>.
 *
 * This file is part of a collection of templates for easy creation of
 *  subfile-based applications on AS/400, iSeries and IBM i.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation  and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Create global message file
 * Run me with strrexprc srcfile(qgpl/sfltmpls) srcmbr(crtmsgd)
 */

SAY "(Re)creating Message File and messages...";

"DLTMSGF MSGF(QGPL/GENERICMSG)";

"CRTMSGF MSGF(QGPL/GENERICMSG) SIZE(2) CCSID(*MSGD) TEXT('Messages SFLTMPLs')";

"ADDMSGD MSGID(ERR0012) MSGF(QGPL/GENERICMSG) MSG('Requested record not",
"found.') SEV(10) TYPE(*NONE) LEN(*NONE) SECLVL('The requested record could",
"not be found. The request will be ignored. Deselect the record and press",
"Enter.')";

"ADDMSGD MSGID(ERR1021) MSGF(QGPL/GENERICMSG) MSG('Record already existing.')",
"SEV(30) TYPE(*NONE) LEN(*NONE) SECLVL('The entered data corresponds to a",
"record that already exists and cannot be added. Either adjust the data",
"record and press Enter, or cancel the addition by pressing F12=Cancel.')";

"ADDMSGD MSGID(ERR1218) MSGF(QGPL/GENERICMSG) MSG('Requested record already",
"in use.') SEV(20) TYPE(*NONE) LEN(*NONE) SECLVL('The requested record is",
"currently being edited by another user. Duplicate editing is not permitted.",
"Wait and resubmit the request, or deselect the record and press Enter to",
"continue with other work.')";

"ADDMSGD MSGID(INF0001) MSGF(QGPL/GENERICMSG) MSG('Record not written.')",
"SEV(0) TYPE(*NONE) LEN(*NONE) SECLVL('The record was not written because no",
"change in screen form data was detected.')";

"ADDMSGD MSGID(INF0999) MSGF(QGPL/GENERICMSG) MSG('Subfile full.') SEV(10)",
"TYPE(*NONE) LEN(*NONE) SECLVL('The subfile can hold a maximum of 999",
"entries. The program attempted to display another entry. This problem must",
"be reported to the system programmer. Some entries are not visible.')";

"ADDMSGD MSGID(RDO1218) MSGF(QGPL/GENERICMSG) MSG('Requested record opened",
"read-only.') SEV(10) TYPE(*NONE) LEN(*NONE) SECLVL('The requested record is",
"currently being edited by another user. Duplicate editing is not permitted.",
"Therefore, the record is displayed without editing options.')";

"ADDMSGD MSGID(SLT0001) MSGF(QGPL/GENERICMSG) MSG('Choose only one entry.')",
"SEV(10) TYPE(*NONE) LEN(*NONE) SECLVL('Select only one entry with ''1''.",
"Multiple choices are not allowed. To quickly discard all selections, press",
"F5=Refresh.')";

/* vim: ft=rexx textwidth=80 colorcolumn=81 autoindent
 */
