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
     H* Compiler flags.
     H* You may add CVTOPT(*DATETIME) and ALWNULL(*USRCTL) if you need to deal
     H*  with Date/Time-Fields and/or NULL-capable fields respectively.
     H*
     H* Tweak default compiler output: Don't be too verbose.
     HOPTION(*NOXREF : *NOSECLVL : *NOSHOWCPY : *NOEXT : *NOSHOWSKP)
     H*
     H* When going prod, enable this for more speed/less CPU load.
     H*OPTIMIZE(*FULL)
     H*
     H*************************************************************************
     H* List of INxx, we use:
     H*- Keys:
     H* 01..24: Command Attn Keys. (DSPF)
     H* 25..27: Paging up/down, Home. (DSPF)
     H*     28: Content of DSPF Record Format has changed. (DSPF)
     H*     29: Valid Command Key pressed. (DSPF)
     H*- SFL Handling (both regular and deletion):
     H*     31: SFLDSP.
     H*     32: SFLDSPCTL.
     H*     33: SFLCLR.
     H*     34: SFLEND, EOF from Database file.
     H*     35: Begin-of-File, BOF from Database file.
     H*- General DSPF Conditioning:
     H*     41: Place Cursor in Pos-To Field.
     H*     42: Indicate ADDREC/DUPREC was called. (DSPF)
     H*     43: Indicate CHGREC was called. (DSPF)
     H*     44: Indicate DSPREC was called. (DSPF)
     H* 60..69: Detail record cursor placement. (DSPF)
     H*- Other Stuff:
     H*     71: READC from Subfile EOF.
     H*     72: SETLL of POSTO found no records.
     H*     77: We must handle deletion of records, since at least one record
     H*         was marked for deletion.
     H*     78: Indicate DUPREC was called.
     H*     79: Indicate that we need to reload the SFL.
     H*- Error Conditions:
     H*     81: Carry over IN91 for next dspf write.
     H*     82: Carry over IN92 for next dspf write.
     H*     83: Carry over IN93 for next dspf write.
     H*     84: Carry over IN94 for next dspf write.
     H*     85: Carry over IN95 for next dspf write.
     H*     91: Record was not found (deleted?). (ERR0012)
     H*     92: Tried to insert duplicate record. (ERR1021)
     H*     93: Locked record is not available for change/deletion. (ERR1218)
     H*     94: Locked record has been opened read only. (RDO1218)
     H*     95: Record has not been written, because no change. (INF0001)
     H*     96: Subfile is full. (INF0999)
     H*     98: Generic File Error Flag within DETAIL-Record views,
     H*          always set when FSTAT > 0.
     H*     99: Set Reverse Video for SFL OPT entry.
     H*
     H*************************************************************************
     F* File descriptors. Unfortunately, we're bound to handle files by file
     F*  name or record name. We can't use variables to make this more dynamic.
     F* Restriction of RPG.
     F*
     F* Main/primary file, used mainly for writing into.
     FV_SFLPF   UF A E           K DISK    INFDS(FINFDS)
     F*
     F* LF as positioning aid for READ/READP: We read just key values which is
     F*  considerably faster than reading whole records from the main file.
     F*  Also this helps us keeping a consistent pointer state between the
     F*  virtual SFL canvas vs. database current record position. Input only!
     F* Important! We're dealing with a *file* pointer, which is implicitly
     F*  shared by all record formats in that logical file!
     FV_POSLF   IF   E           K DISK
     F*
     F* Display file with multiple subfiles among other record formats.
     FV_LODPAGDFCF   E             WORKSTN
     F                                     SFILE(MAINSFL:SFLRCDNBR)
     F                                     SFILE(DLTSFL:SFLDLTNBR)
     F*
     F*************************************************************************
     D* Global Variables (additional to autocreated ones by referenced files).
     D* Sorted by size, descending, to minimise memory padding.
     D*
     D* Needed for proper UPDATE of SFL: An overlay of our current data from
     D*  the main file. Beware, this is *not* a copy but just a pointer (of a
     D*  different kind).
     DT_SFLTBL       E DS                  EXTNAME(V_SFLPF:SFLTBL) INZ
     D* To actually store stuff, we need separate space. V4 doesn't know about
     D*  LIKEDS, so we need to build the struct by hand.
     DC_SFLTBL         DS                  INZ
     D C_KEYVAL                            LIKE(KEYVAL)
     D C_VALFLD                            LIKE(VALFLD)
     D*
     D* (Fake) field, much shorter for demonstration of the function shown in
     D*  PREPSFLDTA. Uses dynamic calculation for adding an ellipse if a string
     D*  is longer than the destination field.
     DVALFLD$          S                   LIKE(VALFLD)
     D*
     D* DS for holding dynamic data for shortening Strings.
     DSTRSHRTDS        DS                  INZ
     D STRLEN_CUR                     3S 0
     D STRLEN_MIN                     3S 0
     D STRLEN_MAX                     3S 0
     D*
     D* Save point for SFL Indicators, to not interfere with deletion logic.
     DSAVIND           S              1A   DIM(9) INZ('0')
     D*
     D* How many records do we have in the database?
     D* Information struct for getting a file's record count.
     DFINFDS           DS
     D DBRCDCNT              156    159I 0
     D*
     D* Must equal SFLPAG in the Display File. CONST not allowed: Is already
     D*  specified as ordinary variable via DSPF-Inclusion. Duh!
     DSFLSIZ           S              5S 0 INZ(13)
     D*
     D* File Error status variable to track READ/WRITE/UPDATE/DELETE.
     DFSTAT            S              5S 0
     D*
     D* This should contain the number of records last read into the SFL.
     DSFLRCDCNT        S              2S 0
     D*
     D* This is used for proper READP iterations and gets calculated on the fly
     D*  within RELOADSFL and PAGEUP routines.
     DREADPVAL         S              2S 0
     D*
     D*************************************************************************
     C* Start the main loop: Write SFLCTL and wait for keypress to read.
     C*  This will be handled after *INZSR was implicitly called by RPG for
     C*  the first time we run.
     C     *IN03         DOUEQ     *ON
     C     *IN12         OREQ      *ON
     C*
     C* Show F-Key footer display.
     C                   WRITE     MAINBTM
     C*
     C* Make sure, we have an indicator of "no records" when SFL is empty.
     C     *IN31         IFEQ      *OFF
     C                   WRITE     MAINND
     C                   ENDIF
     C*
     C* Reset global SFL Error State from last loop iteration.
     C                   MOVE      *OFF          *IN99
     C*
     C*----------------------------
     C* Set Error indicators according to carry-over indicators set before.
     C*
     C* Show message when we can't find the record anymore.
     C     *IN81         IFEQ      *ON
     C                   WRITE     MAINCTL
     C                   MOVE      *OFF          *IN81
     C                   MOVE      *ON           *IN91
     C                   ENDIF
     C*
     C* Show message when we have a duplicate key.
     C     *IN82         IFEQ      *ON
     C                   WRITE     MAINCTL
     C                   MOVE      *OFF          *IN82
     C                   MOVE      *ON           *IN92
     C                   ENDIF
     C*
     C* Show message when we have a locked record.
     C     *IN83         IFEQ      *ON
     C                   WRITE     MAINCTL
     C                   MOVE      *OFF          *IN83
     C                   MOVE      *ON           *IN93
     C                   ENDIF
     C*
     C* Show message when we have not detected a change in the form.
     C     *IN85         IFEQ      *ON
     C                   WRITE     MAINCTL
     C                   MOVE      *OFF          *IN85
     C                   MOVE      *ON           *IN95
     C                   ENDIF
     C*----------------------------
     C* Show Subfile control record and wait for keypress.
     C                   EXFMT     MAINCTL
     C*
     C* Jump out immediately if user pressed F3. We need this additionally
     C*  to the DOUEQ-Loop to prevent another loop-cycle and thus late exit.
     C     *IN03         IFEQ      *ON
     C                   MOVE      *OFF          *IN03
     C                   MOVE      *ON           *INLR
     C                   RETURN
     C                   ENDIF
     C*
     C*------------------------------------------------------------------------
     C* Handle Pos-To field first, if used and enough records in database.
     C* Beware of Pitfall! If you redefine POSTO from numeric to character,
     C*  you MUST fill it with *BLANK instead of *ZERO to appear empty!
     C     POSTO         IFNE      *ZERO
     C     DBRCDCNT      ANDGT     SFLSIZ
     C     POSTO         SETLL     FWDPOS                             72
     C*
     C* Force cursor back into search field (most likely, we'll be instructed
     C*  to search again), and reset.
     C                   MOVE      *ON           *IN41
     C                   MOVE      *ZERO         POSTO
     C*
     C* If we found something, load from there. If not, go up one page, to
     C*  prevent seeing "no data" because not found usually means EOF.
     C     *IN72         IFEQ      *OFF
     C                   EXSR      LOADDSPSFL
     C                   ELSE
     C*
     C* If we hit EOF from previous read, go back two pages. If not, one.
     C     *IN34         IFEQ      *ON
     C     SFLSIZ        MULT      2             READPVAL
     C                   ELSE
     C                   Z-ADD     SFLSIZ        READPVAL
     C                   ENDIF
     C*
     C* Read backwards to the point we calculated above.
     C                   EXSR      READPSR
     C*
     C                   ENDIF
     C                   ITER
     C*
     C                   ELSE
     C* Nothing to do, let cursor jump to or stay in SFL.
     C                   MOVE      *OFF          *IN41
     C                   ENDIF
     C*
     C*------------------------------------------------------------------------
     C* Handle Returned F-Keys. These are usually defined as CA in the DSPF and
     C*  return no data to handle. IN29 indicates any valid key has been
     C*  pressed. Watching IN29 here might save a few CPU cycles.
     C     *IN29         IFEQ      *ON
     C                   SELECT
     C*
     C*----------------------------
     C* Handle SFL Reload with data from database.
     C     *IN05         WHENEQ    *ON
     C*
     C* If @EOF, load only current number of records to prevent jumping display.
     C     *IN34         IFEQ      *OFF
     C                   Z-ADD     SFLSIZ        READPVAL
     C                   ELSE
     C                   Z-ADD     SFLRCDCNT     READPVAL
     C                   ENDIF
     C*
     C                   EXSR      READPSR
     C*
     C*------------------
     C* Handle Addition of Records.
     C     *IN06         WHENEQ    *ON
     C                   EXSR      ADDREC
     C                   EXSR      POSTRCDADD
     C*
     C*------------------
     C* Scroll- and cursor handling.
     C     *IN25         WHENEQ    *ON
     C                   EXSR      PAGEDOWN
     C     *IN26         WHENEQ    *ON
     C                   EXSR      PAGEUP
     C     *IN27         WHENEQ    *ON
     C                   MOVE      *ON           *IN41
     C*
     C*----------------------------
     C                   ENDSL
     C                   ITER
     C* If no F-Keys were pressed, handle OPT choices.
     C                   ELSE
     C*
     C* Only read from SFL if SFL actually has entries!
     C     *IN31         IFEQ      *ON
     C*
     C* Loop and read changed records from the SFL. This implicitly affects the
     C*  SFL RRN variable! Read starts automatically at record 1.
     C     *ZERO         DOWEQ     *ZERO
     C                   READC     MAINSFL                                71
     C     *IN71         IFEQ      *ON
     C* If there was an error one loop-iteration before, leave loop immediately.
     C* Aka, locked record or the like; so the user can see where we stopped.
     C     *IN99         OREQ      *ON
     C                   LEAVE
     C                   ENDIF
     C*------------------------------------------------------------------------
     C* Better use SELECT/WHENxx than CASExx: There's no "OTHER" with CASExx
     C*  but we need to ignore a blank/invalid selection with a new loop
     C*  iteration to prevent UPDATEing RRN 1 with the last READ/WRITE-Cycle
     C*  from LOADDSPSFL.
     C                   SELECT
     C     OPT           WHENEQ    '2'
     C                   EXSR      CHGREC
     C* We possibly have locked a record before.
     C                   UNLOCK    V_SFLPF
     C*
     C     OPT           WHENEQ    '3'
     C                   EXSR      DUPREC
     C*
     C     OPT           WHENEQ    '4'
     C                   EXSR      DLTPREP
     C*
     C     OPT           WHENEQ    '5'
     C                   EXSR      DSPREC
     C*
     C     OPT           WHENEQ    ' '
     C* Reset Error State for that one entry. Remember, we're still in READC.
     C                   MOVE      *OFF          *IN99
     C*
     C                   OTHER
     C                   ITER
     C                   ENDSL
     C*------------------------------------------------------------------------
     C* Handle SFL Updates: We may only UPDATE a SFL with an immediate prior
     C*  READ. This makes the following section cumbersome. But it's still
     C*  more desirable than to reload the whole SFL after every change.
     C* Copy original data (from disk) to data-copy.
     C                   CLEAR                   C_SFLTBL
     C                   MOVEL     T_SFLTBL      C_SFLTBL
     C*
     C* Now re-read the record from the subfile position we last were at
     C* (implicit SFLRCDNBR, already set).
     C     SFLRCDNBR     CHAIN     MAINSFL
     C* Discard (outdated) data from SFL by restoring from our saved copy.
     C                   EVAL      T_SFLTBL  =   C_SFLTBL
     C* *BLANK out OPT to show to the user we're finished with that one. Keep
     C*  entry active if error occured within an EXSR call.
     C     *IN99         IFEQ      *OFF
     C                   MOVE      *BLANK        OPT
     C                   ENDIF
     C*
     C* Set conditioning INxx for every row of data or do other stuff like
     C*  shortening of strings and the like.
     C                   EXSR      PREPSFLDTA
     C*
     C* Finally, update the record in the SFL.
     C                   UPDATE    MAINSFL
     C*
     C* User may quit from current READC-loop.
     C     *IN03         IFEQ      *ON
     C                   MOVE      *OFF          *IN03
     C                   MOVE      *ON           *INLR
     C                   RETURN
     C                   ENDIF
     C*
     C* User may interrupt current READC-loop.
     C     *IN12         IFEQ      *ON
     C                   MOVE      *OFF          *IN12
     C                   LEAVE
     C                   ENDIF
     C*
     C* End of readc-loop!
     C                   ENDDO
     C* End of If-IN31-ON.
     C                   ENDIF
     C*
     C*------------------------------------------------------------------------
     C* If we have records to delete, do now.
     C     *IN77         IFEQ      *ON
     C*
     C* Save current SFL *INs so we can freely set ours for deletion.
     C                   MOVEA     *IN(31)       SAVIND(1)
     C                   MOVEA     '0000'        *IN(31)
     C*
     C* Since we have previously collected all records to delete,
     C*  set *IN34 for SFLEND.
     C                   MOVE      *ON           *IN34
     C*
     C* Now handle the deletion itself.
     C                   EXSR      DODLTSFL
     C*
     C* If user exited with *IN12 before, just unset and redisplay.
     C     *IN12         IFEQ      *ON
     C                   MOVE      *OFF          *IN12
     C* Restore previous SFL *INs. They got deleted by clearing DLTSFL.
     C                   MOVEA     SAVIND(1)     *IN(31)
     C                   ELSE
     C* After deletion, position file pointer at next record relative to last
     C*  deletion. Do only if we have enough records in PF.
     C     DBRCDCNT      IFLE      SFLSIZ
     C     *LOVAL        SETLL     FWDPOS
     C                   MOVE      *OFF          *IN72
     C*
     C                   ELSE
     C*
     C     KEYVAL        SETLL     FWDPOS                             72
     C                   ENDIF
     C*
     C* If we found a match, load from there. If not, just pretend to move up
     C*  one page.
     C     *IN72         IFEQ      *OFF
     C                   EXSR      LOADDSPSFL
     C                   ELSE
     C                   EXSR      PAGEUP
     C                   ENDIF
     C                   ENDIF
     C*
     C                   ENDIF
     C*------------------------------------------------------------------------
     C* We're finished with our loop, so we can safely reload, if needed.
     C* Just UPDATEing the SFL record muddles up sorting if the (sort) key
     C*  value changes. Also on duplication, we must force a reload, just like
     C*  addrec does, so we can actually see the new record.
     C     *IN79         IFEQ      *ON
     C                   MOVE      *OFF          *IN79
     C                   EXSR      POSTRCDADD
     C                   ENDIF
     C*------------------------------------------------------------------------
     C* End of OPT-Handling (IN29 = OFF).
     C                   ENDIF
     C* End of main loop.
     C                   ENDDO
     C* Properly end *PGM.
     C                   MOVE      *ON           *INLR
     C                   RETURN
     C*========================================================================
     C* SFL subroutines
     C*========================================================================
     C     CLEARSFL      BEGSR
     C* Reset SFL state to before the first load.
     C*
     C                   MOVEA     '0010'        *IN(31)
     C                   MOVE      *ZERO         SFLRCDNBR
     C                   WRITE     MAINCTL
     C                   MOVE      *OFF          *IN33
     C*
     C                   ENDSR
     C*************************************************************************
     C     LOADDSPSFL    BEGSR
     C* Read over next, at most SFLPAG count of records in the nicely sorted LF,
     C*  and write them into the SFL. Increment SFLRCDNBR which determines the
     C*  line where the record is to be be inserted.
     C* Stop when SFL is full or EOF happens (*IN34).
     C*
     C* Reset SFL state to default.
     C                   EXSR      CLEARSFL
     C*----------------------------
     C* Read loop start.
     C     1             DO        SFLSIZ
     C                   READ      FWDPOS                                 34
     C     *IN34         IFEQ      *ON
     C                   LEAVE
     C                   ENDIF
     C*
     C* Set conditioning INxx for every row of data or do other stuff like
     C*  shortening of strings and the like.
     C                   EXSR      PREPSFLDTA
     C*
     C* Reset OPT to blank to prevent stray OPT entries to be duplicated.
     C                   MOVE      *BLANK        OPT
     C*
     C* Reset error *INs.
     C                   MOVEA     '000000000'   *IN(91)
     C*
     C* Increment line-number-to-insert.
     C                   ADD       1             SFLRCDNBR
     C*
     C* Write ready-made records into the SFL.
     C                   WRITE     MAINSFL
     C                   ENDDO
     C*----------------------------
     C* Save the number of copied records.
     C                   Z-ADD     SFLRCDNBR     SFLRCDCNT
     C*
     C* Loop ended. Display the subfile- and subfile control records, or
     C*  indicate an empty SFL by (not) setting IN31.
     C*------------------
     C     SFLRCDNBR     IFGT      *ZERO
     C                   MOVE      *ON           *IN31
     C*
     C* Try to find out if next record will be EOF or not: So we can indicate
     C*  "more" or EOF to the user. This prevents a scrolldown to an empty SFL
     C*  showing "no records".
     C* Do check only if SFL is full. If not, we're certainly at EOF.
     C     SFLRCDCNT     IFEQ      SFLSIZ
     C                   READ      FWDPOS                                 34
     C     *IN34         IFEQ      *OFF
     C                   READP     FWDPOS                                 35
     C                   ENDIF
     C                   ELSE
     C* If SFL is not full, allow scrollback, if we have enough records in PF.
     C     DBRCDCNT      IFGT      SFLSIZ
     C                   MOVE      *OFF          *IN35
     C                   ENDIF
     C                   ENDIF
     C*------------------
     C                   ELSE
     C*------------------
     C* If SFL is empty, don't try to show: We'll crash! Instead show excuse.
     C                   MOVE      *OFF          *IN31
     C                   ENDIF
     C*------------------
     C*
     C* Always place cursor in line 1 after a reload.
     C                   Z-ADD     1             SFLRCDNBR
     C*
     C* Finally allow to show all the data on the display. Actual DSPF write
     C*  is handled in the main routine.
     C                   MOVE      *ON           *IN32
     C*
     C                   ENDSR
     C*************************************************************************
     C     PREPSFLDTA    BEGSR
     C* Prepare Data before inserting into the SFL: Set INxx for color, shorten
     C*  Strings or stuff like that.
     C*
     C* Cut string and optionally add ellipse (if DB field is larger).
     C                   MOVEL     *BLANK        VALFLD$
     C                   EVAL      STRLEN_CUR=%LEN(%TRIMR(VALFLD))
     C     STRLEN_CUR    IFGT      STRLEN_MAX
     C     STRLEN_MIN    SUBST     VALFLD:1      VALFLD$
     C                   CAT       '...':0       VALFLD$
     C                   ELSE
     C     STRLEN_MAX    SUBST     VALFLD:1      VALFLD$
     C                   ENDIF
     C*
     C* Check for NULL fields and overwrite with *BLANK so fields appear empty.
     C                   EXSR      CHECKNULL
     C*
     C                   ENDSR
     C*************************************************************************
     C     POSTRCDADD    BEGSR
     C* Clean up SFL display after inserting a record (aka: addrec/duprec).
     C*
     C* Neat trick: Position SFL to what we just inserted and set off BoF.
     C* This holds also true for CHGREC.
     C     DBRCDCNT      IFGT      SFLSIZ
     C     KEYVAL        SETLL     FWDPOS
     C                   EXSR      LOADDSPSFL
     C                   MOVE      *OFF          *IN35
     C                   ELSE
     C* If SFL is not filled, load from beginning and indicate BOF.
     C                   EXSR      GOFIRST
     C                   ENDIF
     C*
     C                   ENDSR
     C*========================================================================
     C* Scroll handling/positioning SFL Subroutines
     C*========================================================================
     C     GOFIRST       BEGSR
     C* Reset file pointer as we were run for the first time.
     C     *LOVAL        SETLL     FWDPOS
     C*
     C                   EXSR      LOADDSPSFL
     C                   MOVE      *ON           *IN35
     C*
     C                   ENDSR
     C*************************************************************************
     C     PAGEDOWN      BEGSR
     C* What to do if user pressed pagedown: Blindly switch off BOF indicator
     C*  and start another iteration of load-from-here-into-SFL.
     C* Can be called only without EOF being set (prohibited by DSPF cond.)
     C                   MOVE      *OFF          *IN35
     C*
     C                   EXSR      LOADDSPSFL
     C*
     C                   ENDSR
     C*************************************************************************
     C     PAGEUP        BEGSR
     C* What to do if user pressed pageup: Calculate proper count of backward
     C*  reads and do it.
     C     *IN34         IFEQ      *OFF
     C     SFLSIZ        MULT      2             READPVAL
     C                   ELSE
     C     SFLSIZ        ADD       SFLRCDCNT     READPVAL
     C                   ENDIF
     C*
     C                   EXSR      READPSR
     C*
     C                   ENDSR
     C*************************************************************************
     C     READPSR       BEGSR
     C* Common SR for handling relative backward-reading.
     C*
     C* Handle EOF condition from LF: Reposition positioning aid. After EOF
     C*  (or BOF) we MUST reposition the DB pointer according to IBM docs.
     C     *IN34         IFEQ      *ON
     C     *HIVAL        SETGT     BCKPOS
     C                   MOVEA     '10'          *IN(34)
     C                   ENDIF
     C*
     C* Now, skip the appropriate number of records backwards blindly. If BOF
     C*  occurs, just start from scratch to have a sane beginning.
     C     1             DO        READPVAL
     C                   READP     BCKPOS                                 35
     C     *IN35         IFEQ      *ON
     C                   EXSR      GOFIRST
     C                   LEAVESR
     C                   ENDIF
     C                   ENDDO
     C*
     C* Try to find out if another READP will hit BOF or not. This updates the
     C* appropriate indicator for the SFL-Show-Beginning-String.
     C                   READP     BCKPOS                                 35
     C     *IN35         IFEQ      *ON
     C                   EXSR      GOFIRST
     C                   LEAVESR
     C                   ELSE
     C                   READ      BCKPOS
     C* And refill the SFL starting with the current LF pointer position.
     C                   EXSR      LOADDSPSFL
     C                   ENDIF
     C*
     C                   ENDSR
     C*========================================================================
     C* Some useful general Subroutines
     C*========================================================================
     C     *INZSR        BEGSR
     C* Stuff to do before the main routine starts.
     C*
     C* Pre-Calculate length for one field-to-be-shortened.
     C                   EVAL      STRLEN_MAX=%LEN(VALFLD$)
     C     STRLEN_MAX    SUB       3             STRLEN_MIN
     C*
     C* Derive maximum ID from data area.
     C*    *DTAARA       DEFINE    MAXIDAREA     NEWID             4 0
     C*
     C* Force Cursor into search field.
     C                   MOVE      *ON           *IN41
     C*
     C* Load Subfile.
     C                   EXSR      GOFIRST
     C*
     C                   ENDSR
     C*************************************************************************
     C     SETERRIND     BEGSR
     C* Set *INxx to show errors in the message line. These have been defined
     C*  in the appropriate display file.
     C* Other errors shall be catched by the OS handler.
     C*
     C                   SELECT
     C     FSTAT         WHENEQ    12
     C* Error 0012 = Record not found.
     C                   MOVE      *ON           *IN91
     C     FSTAT         WHENEQ    1021
     C* Error 1021 = Duplicate key.
     C                   MOVE      *ON           *IN92
     C     FSTAT         WHENEQ    1218
     C* Error 1218 = Desired record is locked.
     C                   MOVE      *ON           *IN93
     C                   ENDSL
     C*
     C                   ENDSR
     C*************************************************************************
     C     INHERITERR    BEGSR
     C* To show ERRMSG/IDs, we already need to have the right RECFMT on screen.
     C*  So write, then set IN for the following EXFMT to actually display the
     C*  message.
     C*
     C* Show message when we can't find the record anymore.
     C     *IN81         IFEQ      *ON
     C                   WRITE     DETAILFRM
     C                   MOVE      *OFF          *IN81
     C                   MOVE      *ON           *IN91
     C                   ENDIF
     C*
     C* Show message when we have a duplicate key.
     C     *IN82         IFEQ      *ON
     C                   WRITE     DETAILFRM
     C                   MOVE      *OFF          *IN82
     C                   MOVE      *ON           *IN92
     C                   ENDIF
     C*
     C* Show message when we have a locked record.
     C     *IN83         IFEQ      *ON
     C                   WRITE     DETAILFRM
     C                   MOVE      *OFF          *IN83
     C                   MOVE      *ON           *IN93
     C                   ENDIF
     C*
     C* Show message when we have a locked record, but continued readonly.
     C     *IN84         IFEQ      *ON
     C                   WRITE     DETAILFRM
     C                   MOVE      *OFF          *IN84
     C                   MOVE      *ON           *IN94
     C                   ENDIF
     C*
     C* Show message when we have not detected a change in the form.
     C     *IN85         IFEQ      *ON
     C                   WRITE     DETAILFRM
     C                   MOVE      *OFF          *IN85
     C                   MOVE      *ON           *IN95
     C                   ENDIF
     C*
     C                   ENDSR
     C*************************************************************************
     C*    INCLASTID     BEGSR
     C* Last-ID-Handler.
     C*    *LOCK         IN        NEWID
     C*                  ADD       1             NEWID
     C*                  Z-ADD     NEWID         ID
     C*                  WRITE(E)  MYTBL
     C*                  EVAL      FSTAT=%STATUS(MYTABLE)
     C*    FSTAT         IFGT      *ZERO
     C*                  UNLOCK    NEWID
     C*                  ELSE
     C*                  OUT       NEWID
     C*                  ENDIF
     C*
     C*                  ENDSR
     C*========================================================================
     C* SFL Handlers for deleting records.
     C*========================================================================
     C     DLTPREP       BEGSR
     C* For every record selected (OPT 4, see above) copy entry into the
     C*  secondary subfile screen (not yet shown) and blindly set flag IN77.
     C* This implicitly requires displayed fields in DLTSFL not being a
     C*  superset of fields in regular SFL!
     C*
     C* Save current SFL *INs so we can freely set ours for deletion.
     C                   MOVEA     *IN(31)       SAVIND(1)
     C                   MOVEA     '0000'        *IN(31)
     C                   MOVE      *OFF          *IN99
     C*
     C                   MOVE      '4'           DOPT
     C                   ADD       1             SFLDLTNBR
     C                   WRITE     DLTSFL
     C                   MOVE      *ON           *IN77
     C*
     C* Restore previous SFL *INs.
     C                   MOVEA     SAVIND(1)     *IN(31)
     C*
     C                   ENDSR
     C*************************************************************************
     C     CLEARDLTSFL   BEGSR
     C* Reset SFL state to before the first load. Also clear "deletion needed".
     C*
     C                   MOVEA     '0010'        *IN(31)
     C                   MOVE      *ZERO         SFLDLTNBR
     C                   WRITE     DLTCTL
     C                   MOVE      *OFF          *IN33
     C                   MOVE      *OFF          *IN77
     C*
     C                   ENDSR
     C*************************************************************************
     C     DODLTSFL      BEGSR
     C* Show may-i-delete-SFL and wait for keypress. Handle deletions if still
     C*  selected with '4'. Note: The SFL has SFLNXTCHG set on permanently to
     C*  enable reading the whole SFL, even without user changes.
     C*
     C* Prevent Crashing with empty SFL. Should not happen, but who knows?
     C     SFLDLTNBR     IFGT      *ZERO
     C                   MOVE      *ON           *IN31
     C                   ELSE
     C                   MOVE      *OFF          *IN31
     C                   WRITE     DLTND
     C                   ENDIF
     C*
     C* Write F-Keys only once.
     C                   WRITE     DLTBTM
     C*
     C* Finally show all the data on the display.
     C                   MOVE      *ON           *IN32
     C*
     C*----------------------------
     C* Loop SFL display-again until there's no more error.
     C     *ZERO         DOWEQ     *ZERO
     C                   EXFMT     DLTCTL
     C*
     C     *IN12         IFEQ      *ON
     C                   EXSR      CLEARDLTSFL
     C                   LEAVESR
     C                   ENDIF
     C*
     C* Make sure we're beginning read from first entry.
     C                   Z-ADD     1             SFLDLTNBR
     C*
     C*------------------
     C* READC loop start.
     C     *ZERO         DOWEQ     *ZERO
     C                   READC     DLTSFL                                 71
     C     *IN71         IFEQ      *ON
     C                   LEAVE
     C                   ENDIF
     C*
     C* Delete only if record is preselected with '4'. Note, we need the field
     C*  designation in DDS to be both Input/Output for this to work!
     C     DOPT          IFEQ      '4'
     C*
     C* Delete record.
     C     KEYVAL        DELETE(E) SFLTBL
     C                   EVAL      FSTAT=%STATUS(V_SFLPF)
     C     FSTAT         IFGT      *ZERO
     C                   EXSR      SETERRIND
     C                   MOVE      *ON           *IN99
     C                   UPDATE    DLTSFL
     C                   MOVE      *OFF          *IN99
     C                   LEAVE
     C* End-if-FSTAT-gt-*ZERO
     C                   ENDIF
     C*
     C* At this point, we most likely successfully deleted a record.
     C                   MOVE      *BLANK        DOPT
     C                   MOVE      *OFF          *IN99
     C                   UPDATE    DLTSFL
     C*
     C* End-if-DOPT=4
     C                   ENDIF
     C* Loop is left on EOF of DSLTSFL.
     C                   ENDDO
     C*------------------
     C* Leave this loop also if there was EOF (all Records have been treated).
     C*
     C     *IN71         IFEQ      *ON
     C                   MOVE      *OFF          *IN71
     C                   LEAVE
     C                   ENDIF
     C*
     C                   ENDDO
     C*----------------------------
     C* Clear SFL for next run.
     C                   EXSR      CLEARDLTSFL
     C*
     C                   ENDSR
     C*========================================================================
     C* Code for displaying/changing/creating/duplicating record details
     C*  in a separate record format
     C*========================================================================
     C     ADDREC        BEGSR
     C* Clear variables from stray entries. Then present the display to the
     C*  user, for entering data. Wait for the user to press return and deliver
     C*  that data for us to process and eventually insert into the main file.
     C                   CLEAR                   DETAILFRM
     C*
     C*----------------------------
     C* Show the prepared form within a loop, until there are no more errors.
     C                   Z-ADD     99999         FSTAT
     C     FSTAT         DOUEQ     *ZERO
     C* Show matching todo-string.
     C                   MOVEA     '100'         *IN(42)
     C                   EXFMT     DETAILFRM
     C                   EXSR      RSTDSPMOD
     C*
     C* Whee! User pressed a key! May we add a record?
     C     *IN03         IFEQ      *ON
     C     *IN12         OREQ      *ON
     C                   MOVE      *OFF          *IN12
     C                   LEAVESR
     C                   ENDIF
     C*
     C* Now try to WRITE the record, but only if the user actually
     C*  changed anything, or we had an error condition before.
     C     *IN28         IFEQ      *ON
     C     *IN98         OREQ      *ON
     C*
     C* Prepare empty fields to be NULL.
     C                   EXSR      SETNULL
     C*
     C* Increment ID.
     C*                  EXSR      INCLASTID
     C*
     C* Try to write the record.
     C                   WRITE(E)  SFLTBL
     C                   EVAL      FSTAT=%STATUS(V_SFLPF)
     C     FSTAT         IFGT      *ZERO
     C                   MOVE      *ON           *IN98
     C                   EXSR      SETERRIND
     C                   ITER
     C                   ENDIF
     C*
     C* At this point, we most likely successfully inserted a record.
     C                   MOVE      *OFF          *IN98
     C*
     C* Set Reload-Indicator to reflect changes.
     C                   MOVE      *ON           *IN79
     C*
     C* If there was no change in display (IN28).
     C                   ELSE
     C                   MOVE      *ON           *IN85
     C                   LEAVE
     C*
     C                   ENDIF
     C* End of loop-unil-no-error.
     C                   ENDDO
     C*----------------------------
     C*
     C                   ENDSR
     C*************************************************************************
     C     DUPREC        BEGSR
     C* Set "we wanna duplicate" flag, no last state of cursor-placement,
     C*  and let CHGREC do the hard work.
     C                   MOVEA     '0000000000'  *IN(60)
     C                   MOVE      *ON           *IN78
     C                   EXSR      CHGREC
     C                   MOVE      *OFF          *IN78
     C*
     C                   ENDSR
     C*************************************************************************
     C     CHGREC        BEGSR
     C* Load data of the desired record from the database file. Maybe condition
     C*  the data and WRITE it into the DSPF. Wait for the user to press return
     C*  so we may process the data and UPDATE the database file.
     C* We also handle DUPREC with *IN78, because the main difference is
     C*  UPDATE vs. WRITE.
     C*
     C* Show the prepared form within a loop, until there are no more errors.
     C*
     C                   Z-ADD     99999         FSTAT
     C     FSTAT         DOUEQ     *ZERO
     C*
     C* No lock needed for duplication, but for updating.
     C     *IN78         IFEQ      *ON
     C     KEYVAL        CHAIN(EN) SFLTBL
     C                   ELSE
     C     KEYVAL        CHAIN(E)  SFLTBL
     C                   ENDIF
     C*
     C                   EVAL      FSTAT=%STATUS(V_SFLPF)
     C     FSTAT         IFGT      *ZERO
     C                   MOVE      *ON           *IN98
     C                   EXSR      SETERRIND
     C*------------------
     C* Since we'll open the record in question readonly, here is an extension
     C*  to the SETERRIND handler.
     C* Error 1218 = Desired record is locked. (Show record readonly.)
     C     FSTAT         IFEQ      1218
     C* Disable "locked" indicator again, and set IN84 for showing r/o message.
     C                   MOVE      *OFF          *IN98
     C                   MOVE      *OFF          *IN93
     C                   MOVE      *ON           *IN84
     C                   EXSR      DSPREC
     C                   MOVE      *OFF          *IN84
     C                   LEAVESR
     C                   ENDIF
     C*------------------
     C                   MOVE      *ON           *IN99
     C                   LEAVESR
     C                   ENDIF
     C*
     C                   MOVE      *OFF          *IN98
     C*
     C* Position cursor in DSPF to field where it was with last CHGREC.
     C     *IN78         IFEQ      *OFF
     C                   EXSR      SETCSRPOS
     C                   ENDIF
     C*
     C* Check for NULL fields and overwrite with *BLANK so fields appear empty.
     C                   EXSR      CHECKNULL
     C*
     C* Show matching todo-string.
     C     *IN78         IFEQ      *ON
     C                   MOVEA     '100'         *IN(42)
     C                   ELSE
     C                   MOVEA     '010'         *IN(42)
     C                   ENDIF
     C*
     C* Set Error indicators according to carry-over indicators set before.
     C                   EXSR      INHERITERR
     C                   EXFMT     DETAILFRM
     C                   EXSR      RSTDSPMOD
     C*
     C* Whee! User pressed a key! May we add (duplicate) or change a record?
     C     *IN03         IFEQ      *ON
     C     *IN12         OREQ      *ON
     C                   LEAVESR
     C                   ENDIF
     C*
     C* Now try to WRITE/UPDATE the record, but only if the user actually
     C*  changed anything or there has been an error before.
     C     *IN28         IFEQ      *ON
     C     *IN98         OREQ      *ON
     C*
     C* Prepare empty fields to be NULL.
     C                   EXSR      SETNULL
     C*
     C* Try to write or update the record.
     C     *IN78         IFEQ      *ON
     C*                  EXSR      INCLASTID
     C                   WRITE(E)  SFLTBL
     C                   ELSE
     C                   UPDATE(E) SFLTBL
     C                   ENDIF
     C                   EVAL      FSTAT=%STATUS(V_SFLPF)
     C     FSTAT         IFGT      *ZERO
     C                   MOVE      *ON           *IN98
     C                   EXSR      SETERRIND
     C                   ITER
     C                   ENDIF
     C*
     C* If there was no change in display (IN28).
     C                   ELSE
     C                   MOVE      *ON           *IN85
     C                   LEAVE
     C                   ENDIF
     C*
     C* End of loop-unil-no-error.
     C                   ENDDO
     C*----------------------------
     C*
     C* Reset error-state: After end of loop there is no more error.
     C                   MOVE      *OFF          *IN98
     C*
     C* Set Reload-Indicator to reflect changes.
     C                   MOVE      *ON           *IN79
     C*
     C                   ENDSR
     C*************************************************************************
     C     DSPREC        BEGSR
     C* Load data of the current selected record from the database file. Maybe
     C*  condition the data and WRITE it into the DSPF. Wait for the user to
     C*  press any key to return to the main program.
     C*
     C* Show the prepared form within a loop, until there are no more errors.
     C*
     C                   Z-ADD     99999         FSTAT
     C     FSTAT         DOUEQ     *ZERO
     C*
     C     KEYVAL        CHAIN(EN) SFLTBL
     C*
     C                   EVAL      FSTAT=%STATUS(V_SFLPF)
     C     FSTAT         IFGT      *ZERO
     C                   MOVEA     '11'          *IN(98)
     C                   EXSR      SETERRIND
     C                   LEAVESR
     C                   ENDIF
     C*
     C                   MOVE      *OFF          *IN98
     C*
     C* Check for NULL fields and overwrite with *BLANK so fields appear empty.
     C                   EXSR      CHECKNULL
     C*
     C* Show matching todo-string.
     C                   MOVEA     '001'         *IN(42)
     C*
     C* Set Error indicators according to carry-over indicators set before.
     C                   EXSR      INHERITERR
     C                   EXFMT     DETAILFRM
     C                   EXSR      RSTDSPMOD
     C*
     C* Whee! User pressed a key!
     C     *IN03         IFEQ      *ON
     C     *IN12         OREQ      *ON
     C                   LEAVESR
     C                   ENDIF
     C*
     C* End of loop-unil-no-error.
     C                   ENDDO
     C*----------------------------
     C*
     C* Reset error-state: After end of loop there is no more error.
     C                   MOVE      *OFF          *IN98
     C*
     C                   ENDSR
     C*========================================================================
     C* Some useful general Subroutines for Detail-Record-handling
     C*========================================================================
     C     SETCSRPOS     BEGSR
     C* Here we check in which record format the cursor was last time and place
     C*  the cursor via DSPATR(PC) via *IN6x into the same field.
     C                   MOVEA     '0000000000'  *IN(60)
     C     CSREC         IFEQ      'DETAILFRM'
     C                   SELECT
     C     CSFLD         WHENEQ    'KEYVAL'
     C                   MOVE      *ON           *IN60
     C     CSFLD         WHENEQ    'VALFLD'
     C                   MOVE      *ON           *IN61
     C                   ENDSL
     C                   ENDIF
     C*
     C                   ENDSR
     C*************************************************************************
     C     RSTDSPMOD     BEGSR
     C* Reset stuff to default.
     C                   MOVEA     '000'         *IN(42)
     C*
     C                   ENDSR
     C*************************************************************************
     C     CHECKNULL     BEGSR
     C* Check for NULL-Fields and empty var. Needs ALWNULL(*USRCTL) in the
     C*  compiler flags!
     C*
     C*                  IF        %NULLIND(KEYVAL)
     C*                  MOVE      *ZERO         KEYVAL
     C*                  ENDIF
     C*
     C*                  IF        %NULLIND(VALFLD)
     C*                  MOVEL     *BLANK        VALFLD
     C*                  ENDIF
     C*
     C                   ENDSR
     C*************************************************************************
     C     SETNULL       BEGSR
     C* Set Null-Indicator for empty fields. Needs ALWNULL(*USRCTL) in the
     C*  compiler flags!
     C*
     C*    KEYVAL        IFEQ      *ZERO
     C*                  EVAL      %NULLIND(KEYVAL) = *ON
     C*                  ENDIF
     C*    VALFLD        IFEQ      *BLANK
     C*                  EVAL      %NULLIND(VALFLD) = *ON
     C*                  ENDIF
     C*
     C                   ENDSR
     C*************************************************************************
     C* vim: syntax=rpgle colorcolumn=81 autoindent noignorecase
