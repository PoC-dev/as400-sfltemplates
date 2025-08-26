     HCOPYRIGHT('2007-2025 Patrik Schindler <poc@pocnet.net>')
     H*
     H* This file is part of a collection of templates for easy creation of
     H*  subfile-based applications on AS/400, i5/OS and IBM i.
     H*
     H* This is free software; you can redistribute it and/or modify it
     H*  under the terms of the GNU General Public License as published by the
     H*  Free Software Foundation; either version 2 of the License, or (at your
     H*  option) any later version.
     H*
     H* It is distributed in the hope that it will be useful, but WITHOUT
     H*  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
     H*  FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
     H*  for more details.
     H*
     H* You should have received a copy of the GNU General Public License along
     H*  with it; if not, write to the Free Software Foundation, Inc., 59
     H*  Temple Place, Suite 330, Boston, MA 02111-1307 USA or get it at
     H*  http://www.gnu.org/licenses/gpl.html
     H*
     H* This is an example program for a program to handle subfile-related
     H*  tasks, for a load-paged SFL.
     H*
     H*
     H* Tweak default compiler output: Don't be too verbose.
     HOPTION(*NOXREF : *NOSECLVL : *NOSHOWCPY : *NOEXT : *NOSHOWSKP)
     H*
     H* When going prod, enable this for more speed/less CPU load.
     HOPTIMIZE(*FULL)
     H*
     H**************************************************************************
     H* List of INxx, we use:
     H*     71: WRITE into PF error. We only set it,
     H*         so any error will be ignored.
     H*
     H**************************************************************************
     F* File descriptors. Unfortunately, we're bound to handle files by file
     F*  name or record name. We can't use variables to make this more dynamic.
     F* Restriction of RPG.
     F*
     F* Main/primary file, used mainly for writing into.
     FV_SFLPF   UF A E           K DISK
     F*
     F**************************************************************************
     D* Global Variables (additional to autocreated ones by referenced files).
     D*
     D**************************************************************************
     C* Just write some values into the PF for testing purposes.
     C*
     C                   Z-ADD     1             KEYVAL
     C                   MOVEL     *BLANK        VALFLD
     C                   MOVEL     'Eins'        VALFLD
     C                   WRITE     SFLTBL                               71
     C*
     C                   Z-ADD     2             KEYVAL
     C                   MOVEL     *BLANK        VALFLD
     C                   MOVEL     'Zwei'        VALFLD
     C                   WRITE     SFLTBL                               71
     C*
     C                   Z-ADD     3             KEYVAL
     C                   MOVEL     *BLANK        VALFLD
     C                   MOVEL     'Drei'        VALFLD
     C                   WRITE     SFLTBL                               71
     C*
     C                   Z-ADD     4             KEYVAL
     C                   MOVEL     *BLANK        VALFLD
     C                   MOVEL     'Vier'        VALFLD
     C                   WRITE     SFLTBL                               71
     C*
     C                   Z-ADD     5             KEYVAL
     C                   MOVEL     *BLANK        VALFLD
     C                   MOVEL     'Fünf'        VALFLD
     C                   WRITE     SFLTBL                               71
     C*
     C                   Z-ADD     6             KEYVAL
     C                   MOVEL     *BLANK        VALFLD
     C                   MOVEL     'Sechs'       VALFLD
     C                   WRITE     SFLTBL                               71
     C*
     C                   Z-ADD     7             KEYVAL
     C                   MOVEL     *BLANK        VALFLD
     C                   MOVEL     'Sieben'      VALFLD
     C                   WRITE     SFLTBL                               71
     C*
     C                   Z-ADD     8             KEYVAL
     C                   MOVEL     *BLANK        VALFLD
     C                   MOVEL     'Acht'        VALFLD
     C                   WRITE     SFLTBL                               71
     C*
     C                   Z-ADD     9             KEYVAL
     C                   MOVEL     *BLANK        VALFLD
     C                   MOVEL     'Neun'        VALFLD
     C                   WRITE     SFLTBL                               71
     C*
     C                   Z-ADD     10            KEYVAL
     C                   MOVEL     *BLANK        VALFLD
     C                   MOVEL     'Zehn'        VALFLD
     C                   WRITE     SFLTBL                               71
     C*
     C                   Z-ADD     11            KEYVAL
     C                   MOVEL     *BLANK        VALFLD
     C                   MOVEL     'Elf'         VALFLD
     C                   WRITE     SFLTBL                               71
     C*
     C                   Z-ADD     12            KEYVAL
     C                   MOVEL     *BLANK        VALFLD
     C                   MOVEL     'Zwölf'       VALFLD
     C                   WRITE     SFLTBL                               71
     C*
     C                   Z-ADD     13            KEYVAL
     C                   MOVEL     *BLANK        VALFLD
     C                   MOVEL     'Dreizehn'    VALFLD
     C                   WRITE     SFLTBL                               71
     C*
     C                   Z-ADD     14            KEYVAL
     C                   MOVEL     *BLANK        VALFLD
     C                   MOVEL     'Vierzehn'    VALFLD
     C                   WRITE     SFLTBL                               71
     C*
     C                   Z-ADD     15            KEYVAL
     C                   MOVEL     *BLANK        VALFLD
     C                   MOVEL     'Fünfzehn'    VALFLD
     C                   WRITE     SFLTBL                               71
     C*
     C                   Z-ADD     16            KEYVAL
     C                   MOVEL     *BLANK        VALFLD
     C                   MOVEL     'Sechzehn'    VALFLD
     C                   WRITE     SFLTBL                               71
     C*
     C                   Z-ADD     17            KEYVAL
     C                   MOVEL     *BLANK        VALFLD
     C                   MOVEL     'Siebzehn'    VALFLD
     C                   WRITE     SFLTBL                               71
     C*
     C                   Z-ADD     18            KEYVAL
     C                   MOVEL     *BLANK        VALFLD
     C                   MOVEL     'Achtzehn'    VALFLD
     C                   WRITE     SFLTBL                               71
     C*
     C                   Z-ADD     19            KEYVAL
     C                   MOVEL     *BLANK        VALFLD
     C                   MOVEL     'Neunzehn'    VALFLD
     C                   WRITE     SFLTBL                               71
     C*
     C                   Z-ADD     20            KEYVAL
     C                   MOVEL     *BLANK        VALFLD
     C                   MOVEL     'Zwanzig'     VALFLD
     C                   WRITE     SFLTBL                               71
     C*
     C                   MOVE      *ON           *INLR
     C                   RETURN
     C**************************************************************************
     C* vim: syntax=rpgle colorcolumn=81 autoindent noignorecase
