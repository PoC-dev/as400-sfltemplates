This file is part of a collection of templates for easy creation of subfile based 5250 (terminal) applications on AS/400, i5/OS and IBM i.

If you are already accustomed to subfiles and quickly start going, you may skip the introductory blah blah to the *Upload instructions* at your own risk of failure.

### License
It is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

It is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with it; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA or get it at http://www.gnu.org/licenses/gpl.html

A huge thank you goes to "Mathias Peter IT-Systemhaus", my current employer who allowed me to spend part of my work time on this project. See https://www.mathpeter.com for details.

### What the heck is this all about?
We're talking subfiles in an AS/400 (IBM i) context here.

A subfile is most often used to present multiple records of data in a scrollable list, on a single text screen for easy viewing and maybe picking records to process further, a bit like a spreadsheet presents data.

Subfiles thus are useful to the user, but very tedious to be handled properly for the programmer. To master just their basic functionality needs fundamental expertise. Beginners in programming don't have expertise but maybe also want to exploit the usefulness of subfiles as user.

This collection of files aims to provide tested and thus working templates for creating subfile-based applications with most expected features, as a starting point for experiencing a quick sense of achievement. Since the code is heavily commented, it should be fairly easy to get a grip on what's going on by reading code and at the same time have IBM documentation at hand for a quick lookup of details.

This text is lengthy because I assume little or no reader's knowledge about the inner workings of OS/400. So I provide a rough overview (and sometimes oversimplified statements) about inner workings as long as it's necessary to understand this template's logic. IBM has tons of documentation online, covering any topic the AS/400 is capable of dealing with. Use it!

Programming style is outdated in many ways. The templates were developed on V4R5 of OS/400, and are currently expected to work on V4R4 and up. Actual tests with available machines show, they trigger strange compilation errors on i5/OS V5R4, and compile just fine for IBM i 7.2 (V7R2) and 7.3 (V7R3).

In addition, some BIFs and exception handling functions are not available in
V4R2 and earlier. A long term goal is to change the existing code to enable V3 compatibility. This is not yet done. Porting the code to V2R3 will not happen, though: It completely lacks RPG IV. Also, I currently lack a machine running this release.

### Basics
Often, AS/400 programs are built with just these components:
- Physical File (*PF*); a database table holding the actual records.
- Logical File (*LF*, optional); allowing to access a subset of fields from the PF, or to apply different undexes (access aaths) to the data for different sorting of records.
- Display File (*DSPF*); the definition of the form(s) appearing on screen. A subset of possibilities a DSPF offers are subfiles. That's what all this fuzz is about.
- The "Driver" Program (*RPGLE*) is the entity that glues all components together. By referencing files in the program code, global variables will be created from the field names in the files. This has consequences:
   - Field definition attributes must be consistent over all files used. This is easily most easily achieved by defining the field once in the PF and reference the field from the DSPF. Notable exceptions are date/time fields.
   - If the names of the fields are kept equal between PF and DSPF, the whole magic boils down to just `READ` from the PF and `WRITE` to the DSPF to make the data appear on screen, for example.
- A Help Panel Group (*PNLGRP*, optional), an external object referenced in display files for providing cursor-position aware online-help facilities.
- A Message File (*MSGF), an external object referenced in display files for providing descriptive messages, most often for error conditions.

There are more file types available, but either not part of this template, or out of scope for this introduction.

Physical Files, Logical Files and Display Files are described in a text based format called Data Description Specifications (DDS). These source files then must be converted (compiled) into the particular OS/400 object before they can be used programmatically. If the file types are set accordingly through PDM Option 13 for each file, it's sufficient to use PDM Option 14 to actually compile. See next paragraph for file types.

The "Driver" program is written in (positional) ILE RPG IV, although I'm not making use of any ILE specific features, currently. RPG is the most used programming language on IBM i up to today. It nicely integrates the concept of external described files in an easy way. There are other native programming languages available, but they're not in scope of this document; namely COBOL, and C/C++.

Nonetheless, there are a *lot* of edge cases to consider and make a subfile display behave in an expectable way. A lot of code is there to handle corner cases.

#### What is a subfile, precisely?
Basically, subfiles allow to present multiple records of data on a single screen display. In practice, this facility is used to show the user a tabular display of data, and a record specific choice field. The data helps the user to associate it with a given record in a database file, and the choice field enables the user to tell the system what he wants to do with the selected field. This display should be familiar with AS/400 users. Many "work with" screens present such a list view.

> **Note:** This is an interesting case of integrated choice, providing selection of the desired data element and what to do with it at the same time. Probably remotely reminiscent about GUI's "right klick" feature.

At the definition level, subfiles are comprised of two associated *record format*s.

> A record format is one of many different ways to group and present objects on screen. A screen display might be composed of many record formats. Record formats are the basic building block for all kinds of DDS derived objects. See the *IBM DDS Reference* book for details.

One part of the subfile is the *subfile record format* itself. It defines the layout of one record — usually one line —, while the system later will take care of the repetition of this one definition to fill the screen. I'm talking about a record and not a line, because one record is perfectly allowed to occupy multiple screen lines in a subfile.

The second part is the *subfile control format*. This mainly defines the attributes and functioning of the subfile itself in regard of scrolling logic. Also, you assign a counting variable via the SFLRCDNBR statement. This serves the same purpose as the automatically generated "relative record number" in physical (database) files: You can address a certain record unambiguously. Note that subfiles cannot have an index field, thus the counting variable is the only way to randomly  address individual records in a subfile. The main challenge is to establish an association of a database record with a subfile record, because both facilities usually do not share a common field for addressing a record unambiguously. The subfile control format also may contain screen elements (such as headings, or a footer listing the allowed function keys), or even further, non tabular database fields, for displaying a user name, the system name, etc. You can't do nesting with subfiles.

Subfile- and subfile control records are not allowed to overlap on a given screen.
- Elements defined in the control record format define the location and area of the control record format. The control record format is allowed to occupy no screen space at all.
- Elements defined in the subfile format, together with the `SFLPAG` parameter in the control record format, define the location and area of the subfile record format on screen.

Also, while subfile control records are allowed to contain actual screen elements, those elements must be grouped either above or below the subfile record. Otherwise the control area would overlap with the subfile itself, which is not allowed and will yield compile errors if tried. If you need elements above **and** below the subfile display, you need to introduce a separate, non-control record format containing the "leftover" screen elements. Often, the subfile control record format's elements are defined above the subfile itself, and elements below the subfile are defined as said separate record format.

At the programming level, subfiles (usually) work like this:
- You prepare the subfile by either clearing or initializing it (set the associated display file indicator to **ON*, write the control record format), and reset it subsequently in the same manner.
- In a loop:
   - `READ` the next record from a database file into the variables which have been created implicitly by referencing the database file.
   - increment the *sflrcdnbr* variable by 1. Note that counting starts at 1, not 0.
   - check maximum subfile records have been handled already and subsequently exit the loop.
   - check if *EOF* or other database read error conditions happened. Use the DB *EOF* indicator to set *sflend*, so the user knows when he already scrolled the tabular subfile display all the way down. Then exit the loop.
   - `WRITE` the subfile record format, implicitly including *sflrcdnbr*. Because the subfile record format's field shares names and definitions with the database file, there is no intermediate copy step of database to screen buffer variables required.
- End loop.
- Update the associated *sfldsp*/*sfldspctl* indicators, and `WRITE` the control record format to make the display appear on screen.

Net result: A subfile with data is displayed on screen. In case of a load-all subfile, you can already scroll through the data. See below for details.

> **Note**: You need to make sure that the subfile itself contains at least one record. If an empty subfile is tried to be displayed (`SFLDSP` set), the application **will crash**. The subfile templates include code to deal with this condition, and instead display another record format stating there are no records in the PF.

Handling user input from a subfile works like this:
- Use `READC` in a loop to read (user) changed subfile records. It reads the complete record, not just the edited Opt field. *Sflrcdnbr* is implicitly set.
- Branch to the desired program function, depending on the user's selection.
- Optional: If the user changed a record on disk by using the aforementioned function, you may choose to `UPDATE` the single changed record from disk into the subfile. This saves time and CPU-cycles compared to reloading the complete subfile, just to show just updated database record
- Test for *EOF* to exit the loop.

#### Flavors of subfiles
The AS/400 basically supports two and a half variants of subfiles:

1. Type *Load-All* will be fed all records in a database file at once. Advantages are: Scroll-handling is done by the OS. Preserving option values beyond scrolling boundaries is handled by the OS. Drawbacks are: The more records to load, the more delay until the subfile is eventually displayed. Fixed maximum number of records. Keeping Data in the PF and on screen in sync means frequent reloads. Implementing means to scroll to a certain record (find by primary key) is very cumbersome and needs help of some kind of intermediate table, array or other facilities to have a mapping of subfile line numbers (AKA: RRNs) to primary key values in the PF. It is not implemented in this example for the sake of simplicity.

   - A subtype of Load-All is the *Expandable Subfile*. The subfile gets loaded one screen worth of records. Thus, the delay until displaying this screen is small. Every keypress for page down instructs the program to load the next bunch of records. The subfile will be expanded in memory on the fly as needed. Scrollback is still handled by the OS. Scrolldown-Handling must be implemented by the programmer. All other restrictions from the Load-All variant still apply.

2. Type *Load-Paged* means that the subfile is as small as one screen of data. Hence, the subfile is displayed as quickly as an expandable subfile. Drawback is, about 200 lines of additional code are needed to make handling the subfile approximately as neat as with a Load-All subfile. For the user, that is. Keeping displayed data in sync with the database on disk is seemingly automatic, because the table on disk must be read into the subfile for every scroll anyway, forcing frequent reloads naturally. Also, it's relatively easy to implement a position-to feature for jumping to a certain record. In addition, there is no limit to the apparently displayed number of records. Since data is re-read from disk with every scroll, any selection (Opt-Field) what to do with the record(s) in question are usually lost with every scroll. There are different means how to save the selection values and refill them when needed, but for the sake of simplicity, there is no selection saver implemented (yet).

This project provides definitions for both Load-All and Load-Paged subfiles. Expandable subfiles can be created by extending the Load-All Subfile with elements from the Load-Paged DSPF and Code, and is left as an exercise to the reader.

Additionally, there are definitions for a prompting screen when records are to be deleted. This is always a type Load-All, because normally, only a few records at once are to be deleted.

Finally, there is a *details* record format containing all fields contained in the PF, for creation, duplication, editing, and viewing a single record.

For reasons stated above, Load-All subfiles are best when there are only a few records to be handled, maybe less than about half dozen scrolls, 13 records each. That's most likely small enough number to not need a position-to feature, and the delay between loading and displaying for Load-All stays bearable even on machines from the last century.

On a side note, Load-All flavors are most likely the ones to be used when records are to be selected with SQL, as a result set, and presented in a subfile. While there's no big difference in dealing with a file pointer compared to a SQL cursor, Load-Paged adds complexity without any additional benefit.

See *Further Reading* below to learn more about display files and how to create application displays.

#### Description of files
> **Note:** I'm primarily [editing those files on Linux with *vim*](https://try-as400.pocnet.net/wiki/How_to_program_an_Application#A_Word_on_Editors). Hence I added file type specific vim options to the files. Those appear as comments, but vim reads them anyway, and sets the appropriate options. You can leave them, or delete them. It's up to you.

The example project comprises of three (groups of) files:
- `V_SFLPF` is the shared database file. Shared, because both Load-All and Load-Paged subfile objects reference this file.
- `V_LODALLDF`, `V_LODALLPG`, and `V_LODALLHP` are the template files for a Load-All project.
- `V_LODPAGDF`, `V_LODPAGPG`, `V_POSLF`, and `V_LODPAGHP` are template files for a Load-Paged project with a position-to field.
- `V_SFLDLTHP` is a shared help panel group for the delete confirmation screen.

> **Note:** The contained text in `V_SFLDLTHP` is generic enough to just compile it to `QGPL/SFLDLTHP`, and modify the references in the DSPF(s) accordingly. So you can enjoy an automatic online help text for the delete-confirmation screen for each derived project, without further effort but changing the panel group name in the DSPF definition.

Additionally, there are:
- `V_SFLPFLOD` writes test data into `V_SFLPF`, so it must not be done by hand.
- `CRTMSGD` is a REXX script to batch-create a message file with predefined text and appropriate second-level help.

Language-specific files have been placed into their respective subdirectories.

##### File suffix descriptions, PDM types
The `WRKMBRPDM` command allows to easily send source members to the appropriate compiler by using option number 14 (or 15). In addition, member names must be unique within a source PF. Hence I came up with a naming schema as follows:
- **`PF`** = Physical File, a database table where records will be allocated within. Designated in PDM as type **PF**.
- **`LF`** = Logical File, designated in PDM as type **LF**. A file referencing one or more PFs, possibly providing (a mix of)
  - a different search index (aka: sorting order) than the PF, or
  - a subset of fields contained in the PF, or
  - a (more or less) static preselection of records (select/omit) from the PF, or
  - a static defined so called *join* over multiple database tables.
- **`DF`** = Display File, a screen form description. Designated in PDM as type **DSPF**.
- **`PG`** = Program Object, the "driver" with accompanying logic for data movement. Designated in PDM as type **RPGLE**.
- **`HP`** = Help Panel Group, the Online Help Facility. Designated in PDM as type **PNLGRP**.

> **Note:** Logical Files may contain more than one record format. Using different index fields in one file but different record formats is somewhat restricted.

Other member types, such as menus, have unique names naturally, because they usually aren't composed from multiple members.

##### OS/400 files
In general, files are better called objects. Files are always objects, but not all objects can hold user data. For this reason, I'm using the term file anyway.

###### File query options
The AS/400 platform supports SQL as query option since V1R1M0, released in late 1988. Deliberately ignoring this capability, this example focuses on classical API calls to read/write/update/delete database file contents mainly for performance reasons.

SQL introduces additional application startup delay, delayed handling of `F5=Refresh`, and other delays. On very old and thus comparably slow machines, this frequent waiting quickly becomes annoying. Also, the integration of SQL in RPG is somewhat clumsy and this project aims to provide a reasonably feature-complete template with as little complexity as possible.

In this regard, it's important to realize that in contrast to SQL (that always operates on a *set* of records), the classical API operates with a *file pointer* that marks one certain record. Operations like update, or delete are done by calling RPG functions and take place only on that particular record. The pointer can be positioned to other records by other RPG calls, such as SetLL, Read, or Chain.

- `READ`ing or `CHAIN`ing (to) a record usually sets a lock on that one record until another record is read, or the complete file is explicitly `UNLOCK`ed, or `CLOSE`d.
  - RPG commands which read a record can be called with the option of not creating a lock, e. g. when no subsequent `UPDATE` is needed.
- `WRITE`'ng a record just creates a new record and holds no lock.
- It is not allowed to `UPDATE` a record without a previous `READ` (for obtaining a lock). Violating this rule yields an operating system exception and the program will be forcibly ended.
  - It is allowed to `DELETE` a record without a previous `READ`, though. An implicit lock is acquired prior.

This simple interface is blazingly fast even on old machines, because the database doesn't need to first optimize the SQL query before, and collect a complete SQL result set before passing a cursor to your program. In fact, SQL does emulate the old record-by-record handling when passing result sets to RPG.

Somewhat oversimplified, the DB2 Engine on oder OS/400 releases is using more or less the primitives explained above to access data: Some kind of SQL to classical API translator. While this isn't exactly correct, it's true enough to help understanding what's approximately going on under the hood.

It is also important to really get the hang of that we're talking about a *file* pointer. This means, that the position of the Physical File's pointer is completely independent of any accompanying Logical File's pointer. Multiple record formats of a logical file share a common file pointer, because it's a file pointer and not a record format pointer. This fact is exploited to ease handling of the Load-Paged subfile, see below.

###### The physical file
Physical Files may contain only one Record Format. Here it is called *sfltbl*.

The record format name is referenced when reading and writing to the physical file, while unlocking or explicit open/close operations are applied to the file itself.

This is the reason OS/400's RPG compiler complains if file name and record name are equal. For that, I'm most often using the suffix TBL for the record format name, because it's a table, while the file name is usually postfixed with "PF". Thus, the PF itself is called *v_sflpf*.

> **Note:** It's possible to use certain options in RPG's file specifications to essentially rename the record format, and subsequently eliminiate ambiguity. This becomes important when you create data holding objects (PFs) through SQL.

To make the template components compilable and readily usable (mainly for testing purposes), the PF already contains two field descriptions:
- A numeric field comprised of 4 digits with 0 digits after the decimal separator,
- A fixed length text field. Unused storage is automatically filled with blanks. The database knows about coping with type *varchar* fields but RPG does not. So it would be necessary to convert between fixed and variable length strings in the course of the program. Thus, I've omitted using *varchar* fields for the sake of keeping the template applications reasonably simple.
- The numeric field is used as *primary key* (see PF globals flag: `UNIQUE`).

See *Further Reading* below to learn more about data types and other stuff regarding physical files.

> **Note:** If you plan to access char data by external means, such as ODBC, you'll be passed all those padding blanks. Starting with OS release 7.3, the ODBC driver can be instructed to tell the OS to automatically chop away those blanks.

###### The logical file
As the name *v_poslf* suggests, this file is mainly used to aid in positioning, and only for the Load-Paged variant of subfiles. Load-Paged means, the programmer has to take care of the scrolling logic, because the subfile is exactly the size of one screen of the said subfile, 13 lines by default.

The logical file has two record formats, *fwdpos* and *bckpos*.

- *fwdpos* is supposed to only retrieve fields appearing in the subfile record format itself: No need to load all fields into memory when they're not needed.
  - Sometimes, it's necessary to load additional data fields into the subfile, tucked away into hidden fields. One particular use case is if you want to apply different colors to individual subfile records, depending on a value of a field which is not shown as a column of the subfile itself. Then you also must add this field to *fwdpos*.
- *bckpos* is supposed to retrieve nothing but only the primary key field(s), because it is just used to move the file pointer backwards according to the subfile's size.

See *Further Reading* below to learn more about logical files' capabilities.

##### Display file
The display file describes the appearance of screens. Screens are composed of textual elements at specific locations.

Said elements are grouped into *record formats*. These record formats can overwrite or overlay each other. Some limitations apply, though.

Examples of screen elements are data input/output fields (for data in textual form), static text (for providing field names or headings, listing valid Function Keys, etc.), special elements such as window borders, single-/multiple choice fields — the textual equivalent of checkboxes and radio buttons —, and more.

To ease development and later changes, display file input/output fields (can) reference fields from physical or logical files for automatic definition consistency.

Data fields must not necessarily show an 1:1 view of the content of a database's field. Numeric fields can be *edited* automatically. Editing bears some similarity to number formatting rules in spreadsheet software. Text display fields in a subfile can be made shorter than in the database, to fit more columns (fields) on a given subfile screen.

Each screen element can have certain flags, such as color and other attributes. Data fields can have even more attributes as well as pre-checks be applied for restricting content to certain data types (only numeric, must be filled entirely, etc.).

Definitions for elements include:
- An optional element name, mandatory for data fields.
- A position on the screen where to place the top left corner of the element. Providing a position is mandatory unless you define a hidden field.
- Attributes for the elements are optional. Not all attributes are valid for all element types.
  - Attributes can be color, style (underline), visibility, etc.

> **Note:** [Color support has been derived from classic monochrome attributes.](https://try-as400.pocnet.net/wiki/5250_colors_and_display_attributes) `COLOR(RED)` and `DSPATR(BLINK)` yield the same result on a color display. This is because color screens have been introduced relatively late to the 5250 world. 5250 predates the AS/400 platform for more than a decade.

Element attributes are contained in the character position immediately preceding the particular element. For that reason, column one in displays is most often not used by actual screen elements. The same reason prevents elements of different type or different attributes to be immediately adjacent to another in the same line (row) of a display. Since the screen buffer is circular, it is indeed possible to use seemingly forbidden screen positions. Using column 1 makes the attribute field appear one line above, in the last column. Using row 1, column 1 makes the attribute field appear in the last row, and last column of the screen.

Most screen elements can be modified at runtime by conditioning numbers, so called *indicators*. This includes attribute changes.

###### Commonalities between 5250 and HTML forms
It is important to realise that Display Files resemble what was once known as simple HTML forms in a web browser window.
- A form is sent to the screen (or browser) by the server, to be filled out by the user.
- After entering data into the appropriate fields, the user presses enter (or the Submit button in HTML) to send back the entire form for processing at once.

There is no communication taking place between host/server and terminal (emulation)/browser while entering data into fields. This explains certain restrictions regarding interactivity in these screens. Browsers provide a JavaScript Engine to do local processing. There's no JS equivalent for 5250 screens.

###### Using record formats to group screen elements
Screen elements to be shown on a screen are grouped into a so called *record formats*. Display files can contain multiple record formats. There are different types of record formats, the most important ones being regular ones and subfile record formats, with the accompanying subfile control record format.

A simple record format usually fills the entire display, but it's also possible to create record formats occupying only parts of a screen display. This possibility is exploited with Subfiles, so one screen can show headings for the subfile along with the subfile itself. Finally, it's possible to draw windows on a screen. Each window can contain at least one or more record formats itself. Hence, almost arbitrarily complex screen displays can be developed, assisting the user by not obscuring the base data display with a new screen, but only partly with a window.

With some effort of creativity, it's possible to create sort of pseudo graphics output, commonly known as *ASCII Art* (but in this case, it's *EBCDIC Art*). Capabilities are somewhat limited with the given screen estate, though.

The DSPF provided has record formats for a list- and a details screen, both in 24×80 display mode only. The sole other supported mode is 27×132.

Some restrictions apply when dynamically switching display modes, so this capability is out of scope for this project.

###### Providing online help
Help facilities should enable an untrained user to properly use an application, or help him by reminding him about details within an application's screens. OS/400 offers *help panel groups* to make it easy for the application developer to provide formatted help texts to end users.

The help facility basically shows fragments of help panel group objects associated with either a rectangular screen position, or with "objects" on a given screen. See below for details.

A very negative example of not helpful online help is Microsoft Windows NT 4. Often, help for a dialog with several fields to fill out provides a terse description about the function a dialog serves, with no or just terse further explanation about the fields and which kind of data is expected there, lest how to derive the expected data.

In general, IBM online help on the AS/400 often shines by
- providing extensive details about the meaning of each field and what type of data is expected,
- some safe default to assume if it's still unclear what data to provide.

I suggest to see these as base requirements for your own help facilities to introduce a professional touch to your applications.

##### The driver program
This one references the PF, possibly the LF (in case of Load-Paged), the DSPF, and basically handles moving of data between the database and the screen in both directions.

While this sounds relatively easy, providing means of catching errors and making the application usage comfortable for the user involves a considerable amount of additional code.

Since this whole thing revolves about subfiles, the central routine to understand is *loaddspsfl*.  It has already been roughly described in the "What is a subfile, precisely?" section above.

Scrolling backwards in a Load-Paged subfile is more tricky than scrolling forward. There are multiple ways to derive the proper file pointer position in the database file to re-load the subfile from there. This is how I've done it.

A Load-Paged subfile is all about relative positioning of records compared to the records being in the subfile before. This is most apparent when simply loading a subfile "forward". But similar logic can be applied when reading backwards.

The database engine allows us to do relative positioning (aka, read *n* records forward or backwards). So, my solution to the problem is to basically read two times the subfile's size of previous records (counted from the end of a scrolldown-cycle) and do a forward subfile load from that point. This relative-read approach enables scrollback even after using a position-to function to set the initial database file pointer position, and also copes perfectly with meanwhile deleted or added records.

A drawback of this approach is additional necessary code to check for *BOF* condition, and use this to completely start from scratch for loading records.

So far, reading backwards twice the amount and then loading the subfile forward may seem like a waste of CPU resources. Here I trade efficiency for comprehensibility of the underlying code.

The logical file (positioning-aid) contains the two record formats *bckpos* and *fwdpos*, as discussed in the section about the Logical File above.

This enables us to do reads in both directions more efficiently. Since both record formats are in the same file and thus share the same file pointer, they can be used for their designated directions of reading, but in the end always point to the same record in the database file.

See *Further Reading* below for a reference to the ILE RPG language.

##### The help panel groups
Online Help is an often neglected topic. The AS/400 facilities make it (technically) comparatively easy to create online help, because the help text is formatted for displaying upon compile time. The backing facility is called the *User Interface Manager* (UIM). While it provides much more than just help panels, the subfile templates only use the help panel facility of UIM so far.

Help text can be created for different cursor positions on screen. This is achieved by help panels having multiple *sections*.

In addition, a display file might reference a "global" section of a help panel group as part of the global DSPF definitions.

Help Panels are written in something that resembles HTML in a crude way, called [GML](https://en.wikipedia.org/wiki/IBM_Generalized_Markup_Language). Not all Features of basic HTML are provided, though: Resulting output is meant to be viewed on a text screen, and in simple printouts. See the provided examples and try out pressing `F1` on different cursor positions to get some understanding how the facility works.

You can add references from screen elements to help entries by
- absolute screen positions (rectangle), as used in the details record format
- numbered static screen elements, as used for the subfile headings in the subfile control format,
- whole record, as used in the "no data", and "bottom" (function key display) record formats.

The mentioned references are only part of all possibilities because these are used in the example display files.

See *Further Reading* below: *Application Display Programming* has a chapter about UIM help panel group tags.

###### Sections
An individual *section* of a help panel group object is shown on screen in a window when the user moves the cursor to a screen location, and presses the help key, or F1. It is confined between the `:HELP.` … `:EHELP.` delimiters.

There is also the notion of an *expanded help*, being displayed when
- pressing F2 in an already displaying help window or screen,
- pressing the help key, or F1 in an otherwise unspecified cursor position.

The aforementioned global help is always prefixed to the expanded help text. The expanded help contains each individual help text for a given screen's elements in order of the screen elements. The order in which the help is written in the panel group source doesn't matter, but it can be helpful for clarity to write individual sections in the order of fields in the respective screen.

When written properly, the expanded help resembles an automatic manual for how to actually use an application and/or screen.

###### Links
You can also add cross references to other help panels thru hyperlinks.
Example:
```
:LINK PERFORM='DSPHELP HELPSECTION HELPPNLGRPOBJ'.
This is the text appearing within the link
:ELINK.
```

See *Further Reading* below: *Application Display Programming* has a chapter about Help Panels.

##### The message file
This file is not created with classic source statements, and being compiled, but with just commands on the command line. I have provided the REXX script *crtmsgd* to create a message file with the appropriate messages in the desired language. The messages are mainly meant for explaining error conditions.

Messages are shown by setting indicators in the display file, revealing contextual informational and error text descriptions in the message line, usually in line 24 of the screen display.

The message file's IDs are referenced in the display file. The individual references are conditioned with indicator values. Upon setting individual indicators to `*ON`, messages are then shown in the message line.

These messages have been defined, and are conditioned with indicators as follows:
```
ERR0012  *IN91  Record not found on CHAINing.
ERR1021  *IN92  Duplicate Key on WRITE.
ERR1218  *IN93  Record already locked on DELETE'ng.
RDO1218  *IN94  Record locked on CHAINing, opened read-only.
INF0001  *IN95  No change in details screen detected, no UPDATE attempted.
INF0999  *IN96  Subfile is full. (Load-All, Delete subfile)
SLT0001  Currently not used in the subfile template.
```

The Rexx-Script purposely creates the message file in the *qgpl* library. It meant to be used by all projects derived from these templates, so it's not necessary to have a special (project specific) message file with all the same definitions over and over.

#### The menu system
Because running your application with `CALL MYPGM` after changing the current library accordingly is cumbersome, I have added a template menu to the project.

Some components (text) of menus are always the same. For that reason, I have established the file *qgpl/menuuim*. Currently, it contains just three members with mainly static text:
- *#funckeys* — definition of function keys and assigned functions
- *#funckeysh* — function keys help text
- *#menuusgh* — generic menu usage instructions

Additionally, the subfile template includes a template menu named *menu* as a starting point for your own menus. The members above are included at convenient spots within that file.

Menu contents, including help texts, are heavily influenced by IBM standard menus and help texts, to create a consistent menu experience for the user.

##### Menu hierarchy
With the given menu example, it's possible to create a custom menu hierarchy for displaying at signon time, and branch to the respective submenus of your projects from there.

Some thoughts:
- Collect source for "generic" menus higher in the hierarchy in *qgpl/menuuim*,
- compile those generic menus into *qgpl* where they can be easily accessed regardless of current library value,
- use `ACTION='MENU MYLIB/MYMENU` in the member text to display another menu,
- leave out the `CRTMNU… MNULIB` parameter; a change of the current library isn't advantageous for generic menus.

See also the *menu* related instructions below.

### Upload instructions
Follow these instructions to upload this project's data to your AS/400 or IBM i system for eventual usage.

Prerequisites:
- Working TCP/IP configuration,
- FTP client.

First, create the data files for holding the sources and include files from a 5250 session.

Traditionally, the templates were German only, so the source file also had a German name. For ease of understanding by English speakers, the source file name for the English language templates itself differs, while the menu source and includes holding file is the same for both languages.

If English is desired, run:
```
CRTSRCPF FILE(QGPL/SFLTMPLS) TEXT('Subfile-Templates')
CRTSRCPF FILE(QGPL/MENUUIM) TEXT('Shared Menu Panels')
```

If German is desired, run:
```
CRTSRCPF FILE(QGPL/SFLVORLAGE) TEXT('Subfile-Vorlage')
CRTSRCPF FILE(QGPL/MENUUIM) TEXT('Shared Menu Panels')
```

Next, run the upload commands file matching the desired language with your command line FTP client **from the project's base directory**.

If English is desired, run:
```
ftp as400 < enu/ftpupload.txt
```

If German is desired, run:
```
ftp as400 < deu/ftpupload.txt
```

This uploads all files to the respective files as members, and sets the file type and comments accordingly.

> **Note:** It would have been easy to also add the `CRTSRCPF` commands to *ftpupload.txt*. But since this needs to be done just once, while uploads might be necessary more often (because of updates to this repository), I refrained from doing so.

After the uploads commenced, you will have a repository of members in the respective file for usage, as well as a "global" *qgpl/menuuim* file for inclusion of shared definitions, and your own higher level menus.

What remains to be done is to run the REXX script for creating the *message file* with common error messages being used by all subfile template derived projects.

If the English source file has been created, run:
```
strrexprc srcfile(qgpl/sfltmpls) srcmbr(crtmsgd)
```

If the German source file has been created, run:
```
strrexprc srcfile(qgpl/sflvorlage) srcmbr(crtmsgd)
```

> **Note:** The script **deletes an already present message file**, and recreates it from scratch. This is meant to ease maintaining consistency. Of course, if you added your own definitions before, they will be gone. **You have been warned.**

### Usage Hints
To actually make use of a template flavor, I advise to create a new library for your shiny new project, and create a source PF there.
```
CRTLIB LIB(MYNEWPROJ)
CRTSRCPF FILE(MYNEWPROJ/SOURCES)
CHGCURLIB CURLIB(MYNEWPROJ)
```

Next, decide if a Load-All subfile is a good fit, or a Load-Paged is more appropriate. Also, Load-Paged includes the classic *Position-To* feature, to have the list display scroll to the first record with the given search term. For Details about Pros and Cons, see *Flavors of subfiles* above.

Now, run `WRKMBRPDM` with the appropriate templates source file as parameter to show the list of source members. Type a *3* next to all files you need for your new project. Which files exactly those might be is explained at length in the sections above. Type options, press Enter. If the copy process is done, press `F3` to exit PDM.

Finally, make appropriate changes by running PDM again against your new source PF with `WRKMBRPDM MYNEWPROJ/SOURCES`. Proposed changes include changing the member names, and deleting or editing of the member description text.

> **Note:** All changes have to be consistent across the involved files. No matter if outside or "inside" (text) of the affected files.

A hint in advance. Compilation of objects might fail for various reasons. If there was an error, have a close look at the compiler output in the default output queue. Most often this is *qprint*. Type `WRKOUTQ` on a command line to list existing output queues and their content. Maybe first clear them of old entries with option 14, and recompile to not search too long for the most recent output.

Compiler logs are extremely verbose and finding errors can be tricky. Especially when tackling syntax errors in RPG programs, just one error might create a chain of further errors in the log output. This usually happens when the compiler ignores a statement whose result is needed later. I recommend you to take time, patience and develop a strong spirit against rushing.

#### PF
The PF customization procedure is the same for Load-All and Load-Paged variants of subfiles.

I assume you already copied *v_sflpf* into e. g. *mynewproj/sources* with a new member name as outlined above. I recommend to name the file "*xxx*pf", where *xxx* is a a string up to seven characters. OS-Restrictions about valid special characters and may-not-begin-with-a-digit apply.

Edit the PF and rename the record format to be "*xxx*tbl", or just *xxx* if *xxxtbl* exceeds the 10 character name length limit of a record format. Modify and add fields to match your requirements. See *Further Reading* below for valid data types in *DDS for Physical and Logical Files*.

After adding fields, I recommend to (manually) sort them by field size: Biggest first, smallest last, to minimize wasted space through padding. I presume that there might be a performance impact for older machines.

If done, save and exit. Type 14 into the *Opt* field in PDM to create your physical file.

#### LF
A LF is strictly required only for my variant of Load-Paged subfiles. Of course, your enhancements to a Load-All subfile can impose a need for a LF, e. g. to provide a different sorting order within the subfile, compared to the primary key field, which might not offer user friendly list ordering.

I assume you already copied *v_poslf* into e. g. *mynewproj/sources* with the same name. Edit the LF but leave the record format names alone. Change the `PFILE` statement to match the name of your physical file. Add field names already defined in the PF to match your requirements:
- Add only fields to be contained in the subfile itself to *fwdpos* record format,
- Add just the keys field(s) to *bckpos* record format.

Both measures lessen unneccessary work for the machine (and thus, yield faster response times).

If done, save and exit. Type 14 into the *Opt* field in PDM to create your logical file.

#### DSPF
The fields created in the PF should be somehow presented on the screen display for viewing, and editing. My templates employ three distinct displays for that purpose:
- The main subfile list view,
- the delete confirmation subfile list view,
- the edit/view details record format.

##### Details record format
- List the fields in a convenient order,
- provide field names as static text,
- connect both with runs of dots as shown in the example,
- make sure fields have unique conditioning indicators in the range 60..69. Yes, more than 9 fields cannot make use of automatic cursor positioning in this example. If there are more than 9 editable fields on one screen, it's probably either too crowded or too advanced and thus out of scope for these templates.
- Change/add help screen coordinates and references to respective help panel group sections.

##### Main subfile
The list view can be more tricky. I strongly recommend to use a text editor with a monospaced font, an on-screen ruler and/or cursor position display to test-build one subfile line. Example (starts in Column 2 as on the real screen):
```
         1         2         3         4         5         6         7         8
12345678901234567890123456789012345678901234567890123456789012345678901234567890
 Opt  Field1                      Field2                         Field3
  _   __________________________  _____________________________  ______________
```

With this you can easily deduce the position within a line where fields must be placed.

General rules:
- Decide which fields need to be displayed,
- leave at least two blank positions between fields to enhance readability,
- if all desired fields won't fit on one line, you can shorten text fields:
  - add a `$` to the field name to indicate a "derived field" (this is just by definition and has no deeper technical meaning),
  - remove the R(eference) tag,
  - add proper length and data type to the field definition to make it fit.
  - Later in the code, field content can be easily shortened, see comments there. Look for the appropriate section in the *prepsfldta* subroutine.

> **Note:** Never shorten a key field for display purposes, because cut content can't be related to the matching record in the PF anymore! (Or provide the unaltered key field as hidden field in the subfile.)

If you have numeric fields, always add a *Y* in the data type column, and probably use an `EDTCDE()` option statement to get rid of leading zeros.

To view the result, you can type Option 17 in PDM to call up *SDA* (Screen Design Agent). It allows reviewing screens without code being written yet, using SDA option 12. I suggest to refrain from saving changes made in SDA: It will delete all comments and most likely reorder statements.

If done, save and exit SEU. Type 14 into the *Opt* field in PDM to create your display file.

#### Program
An RPG program is divided into sections. I've annotated them with comments. Because of the comments, I'll not delve into details too much.
- H(eading) defines compiler flags, copyright text, etc.
- F(files) define I/O.
- D(efinitions) are for creating (global) variables, and call prototypes.
- C(ompute) statements are actual code.

Code is divided into subroutines, to get a good balance between (unnecessary) code duplication and readability. The first and otherwise unnamed routine implicitly becomes the `main()` routine, as known in C.

Optical separator lines of various lengths have been inserted as comments to enhance readability. They optically enframe loops or other conditional code flow, because indentation for clarity isn't possible with positional code.

> **Note:** Because of the positional nature of the code (position of statements along a line is important), watch out when using simple search and replace in a text editor! For any change made, obey the correct position of code in the individual line! When in doubt, make use of `F4`-Prompting in SEU.

Changes to be made for customizing your own application.
- Obey the `CVTOPT` statement(s) in the H(eader).
- Replace the name of the PF.
- Replace the name of the PF's record format.
- Delete the definition of *valfld$*, it is there for testing purposes *only*.
- Replace *keyval* with the field name of your individual primary key.
- Change the field listing in the *setcsrpos* subroutine appropriately to your definition of fields in the DSPF *detailfrm* record format.

##### NULL fields
- Obey the `ALWNULL` compile option in the H(eader),
- change the *checknull* and *setnull* subroutines. If not needed, delete them and their accompanying `EXSR` calls.

When using the finished application, keep in mind:
- A value of just blanks in a text field will be turned into NULL,
- a value of 0 (`*ZERO`) for a numeric field will be turned into NULL.

##### Shortened text fields
If you have *one* shortened field for the subfile (named with a *$* at the end), replace *valfld* with the appropriate name of your (original) field in both the *prepsfldta* and **inzsr* subroutines.

If you have *more than one* field to be shortened, move the field length calculation from **inzsr* to just before the calculation statements in *prepsfldta*. Duplicate and change the whole block for any to-be-shortened field. Or come up with your own, more efficient way of handling this case.

If you don't need this facility, delete the mentioned parts and `EXSR` calls.

Moreover, if you neither use NULL fields, nor shortened fields, nor other customization of subfile data, you may also completely get rid of the *prepsfldta* subroutine. Don't forget to also delete the appropriate `EXSR` calls.

##### Primary key ID
Older releases of OS/400 lack a truly database-integrated way of generating unique primary key values. One way of obtaining collision-free values is to use the [Data Area read-and-lock mechanism](https://try-as400.pocnet.net/wiki/Using_Data_Areas_in_RPG_to_derive_a_primary_key_value) of the operating system.

If you want to use the described automatic ID generation,
- Create the data area according to your primary key definition, e. g. `crtdtaara dtaara(maxidarea) type(*dec) len(11 0) value(0)`,
- uncomment the data are definition in the **inzsr* subroutine definition,
- uncomment the lock-and-calc code in the *inclastid* subroutine,
- uncomment the two `EXSR` calls to *inclastid*.

If you don't need this facility, delete the mentioned parts. Don't forget to also delete the corresponding `EXSR` calls. They're commented out by default, but why keep unneeded crap?

##### General advice
If done, save and exit. Type 14 into the *Opt* field in PDM to create your program. You can run it with `CALL PROGNAME` (assuming you named the RPGLE source PROGNAME).

It is pretty normal that even for a template derived program to not successfully compile at the first try. Too many places for required changes go unnoticed easily.

Generating unintended inconsistencies with the changes laid out above is frustratingly easy. So, read the compiler output, fix the error(s) and try again. You will succeed eventually.

More nasty are run time errors. This means, the code is basically working, but a condition arises which makes the program crash. Upon display of the appropriate prompting screen from OS/400, type D(ebug) and carefully examine the generated program debug dump in the output queue *qezdebug*. Always remember that the templates as delivered work and have no known run time failures.

#### PNLGRP
Change the help texts as required. Add more sections for newly introduced fields in your display files.

> **Note:** You need to create references to your help text in the DSPF itself! This has been mentioned in the *DSPF* section above.

If done, save and exit. Type 14 into the *Opt* field in PDM to create your panel group.

#### MENU
Change entries as shown in the example member. Then compile the menu.

A menu can't be compiled with just Option 14 from PDM, because of prerequisites for includes, etc. It has to be compiled with a customized command depending on your menu name and target library:
```
CRTMNU MENU(MYLIB/CMDFOOBAR) TYPE(*UIM) SRCFILE(MYLIB/SOURCES) INCFILE(QGPL/MENUUIM) CURLIB(*MNULIB)
```

> **Note:** The parameter `CURLIB(*MNULIB)` automatically changes the current library to the library where the menu object resides. This is most often what you want for application specific menus who normally reside in a common library.

### Further reading
To successfully understand these templates, I strongly recommend to get hold and make use of the following documentation from IBM:
- [DDS for Physical and Logical Files](https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/rzakb/rzakbprint.htm) (Link to PDF)
- [DDS for Display Files](https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/rzakc/print.htm) (Link to PDF)
- [ILE RPG Reference](https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/rzasd/rzasdprintthis.htm) (Link to PDF)
- [Source Entry Utility manual](https://try-as400.pocnet.net/wiki/File:Source_Entry_Utility-v4.pdf) (Editor) — (Link to PDF)
- [Application Display Programming](http://public.dhe.ibm.com/systems/power/docs/systemi/v6r1/en_US/sc415715.pdf) (direct PDF download)

----
poc@pocnet.net, 2025-08-28

```
vim: textwidth=78 autoindent
```
