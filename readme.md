This file is part of a collection of templates for easy creation of subfile based 5250 (terminal) applications on AS/400, i5/OS and IBM i.

### License
It is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

It is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with it; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA or get it at http://www.gnu.org/licenses/gpl.html

A huge thank you goes to "Mathias Peter IT-Beratung und Dienstleistungen", my current employer who allowed me to spend part of my work time on this project. See https://www.mathpeter.com for details.

### WTF?
A subfile is most often used to present multiple records of data in a list, on a single screen for easy viewing and maybe picking records to process further. A bit like a spreadsheet presents some data, that is.

Subfiles thus are useful but very tedious to be handled properly. To master just their basic functionality needs fundamental expertise. Beginners don't have expertise but maybe also want to exploit the usefulness of Subfiles.

This collection of files aims to provide tested and thus working templates for creating subfile-based applications with most expected features, as a starting point for experiencing a quick sense of achievement. Since the code is heavily commented, it should be fairly easy to get a grip on what's going on by reading code and at the same time have IBM documentation at hand for a quick lookup of details.

This text is lengthy because I assume little or no reader's knowledge about the inner workings of OS/400. So I provide a rough overview (and sometimes oversimplified statements) about inner workings as long as it's necessary to understand this template's logic. IBM has tons of documentation online, covering any topic the AS/400 is capable of dealing with. Use it!

Since I developed these files for my own usage, and my primary language is German, all static text in the display files, and error messages in the message file is in German Language. Feel free to translate as desired. But please first compile the project as is and tinker with the screens to get some idea which text belongs where. It would be bad if you first translate everything and then the outcome behaves erratic because strings are much longer and you don't know what went wrong and where. Google Translator is there to assist.

Programming Style is outdated in many ways. The templates were developed on V4R5 of OS/400, and are expected to work on all V4 versions.

Actual tests with available machines show, they trigger strange compilation errors on i5/OS V5R4, and compile just fine for IBM i 7.2 (V7R2). In addition, some BIFs and exception handling functions are not available in V3R2 and earlier. Porting the code to V3R2 might not happen, though. The same is even more true for V2R3: It completely lacks ILE RPG. For both of these unsupported releases, I've planned to reimplement the code itself in ILE C, and translate the German texts to english - because both of my CISC machines feature English OS versions.

Using these examples assumes you are able to:
- Create a source physical file with a record length of at least 112 char (hint: `CRTSRCPF`),
- How to use PDM to work with file members (hint: `WRKMBRPDM`),
- Upload the files of this project into the SRC PF (hint: use FTP with ASCII translation),
- Set the correct file types for automatic invocation of the matching compiler and enable syntax checking in the 5250-Editor called SEU (hint: `WRKMBRPDM`),
- Optionally know how to use SEU for making changes. People knowing vi basi commands will discover certain similarities that makes it easy to learn.

Some of these topics are covered in the Wiki on [try-as400.pocnet.net](https://try-as400.pocnet.net).

### Basics
Often, AS/400 programs are build with just these components:
- Physical File (*PF*); a Database Table holding the actual records.
- Logical File (*LF*, optional); allowing to access a subset of fields from the PF, or to apply different Indexes (Access Paths) to the data.
- Display File (*DSPF*); the Definition of the Form(s) appearing on Screen. A subset of possibilities a DSPF offers are subfiles. That's what all this fuzz is about.
- The "Driver" Program (*RPGLE*) is the entity that glues all components together. By referencing files in the program code, global variables will be created from the field names in the files. This has consequences:
   - Field definition attributes must be consistent over all files used. This is easily most easily achieved by defining the field once in the PF and reference the field from the DSPF. Notable exceptions are date/time fields.
   - If the names of the fields are kept equal between PF and DSPF, the whole magic boils down to just `READ` from the PF and `WRITE` to the DSPF to make the data appear on screen, for example.
- A Help Panel Group (*PNLGRP*, optional), an external object referenced in display files for providing cursor-position aware online-help facilities.
- A Message File (*MSGF), an external object referenced in display files for providing descriptive messages, most often for error conditions.

There are more file types available, but not part of this template.

Physical Files, Logical Files and Display Files are described in a text based format called Data Description Specifications (DDS). These source files then must be converted (compiled) into the particular OS/400 object before they can be used programmatically. If the file types are set accordingly through PDM Option 13 for each file, it's sufficient to use PDM Option 14 to actually compile. See next paragraph for file types.

The "Driver" program is written in (positional) ILE RPG IV. RPG is the most used programming language up to today. It nicely integrates the concept of external files in an easy way. There are other programming languages available, but they're not in scope of this document.

Nonetheless, there are a *lot* of edge cases to consider and make a subfile display behave in an expectable way.

#### What is a subfile, precisely?
Basically, subfiles allow to present multiple records of data on a single screen display. In practice, this facility is used to show the user a tabular display of data, and a choice field. The data helps the user to associate the presented data with a given record in a database file, and the choice field enables the user to tell the system what he wants to do with the selected field. This display should be familiar with AS/400 users. Many "work with" screens present such a list view.

At the definition level, subfiles are comprised of two associated *record format*s. (A record format is one of possibly many different ways to access, and present data. See the IBM "DDS Reference" book for details.)

One part of the subfile is the subfile record format itself. It defines the layout of one record, while the system later will take care of the repetition of this one definition to fill the screen. I'm talking about a record and not a line, because one record is perfectly allowed to occupy multiple lines on a screen.

The second part is the subfile control format. It mainly defines the functioning of the subfile itself in regard of scrolling logic. Also, you assign a counting variable via the SFLRCDNBR statement. This serves the same purpose as the automatically generated "relative record number" in phyical (database) files: You can address a certain record unambiguously. Note that subfiles cannot have an index field, thus the counting variable is the only way to address individual records in a subfile. The main challenge is to establish an association of a database field with a SFL field, because both facilities usually do not share a common way of addressing a record. The subfile control format also may contain static screen elements (such as headings, or a screen footer listing the allowed function keys), or even further, non tabular database fields, for displaying a user name, the system name, etc.

Subfile- and subfile control records are not allowed to overlap.
- Elements defined in the control record format define the location and area of the control record format.
- Elements defined in the subfile format, together with the `SFLPAG` parameter in the control record format define the location and area of the subfile record format.

Also, while subfile control records are allowed to contain actual screen elements, those elements must be grouped either before or after the subfile record. Otherwise the control area would overlap with the subfile, which is now allowed. If you need elements above and below the subfile display, you need to introduce a separate record format containing the "leftover" screen elements.

At the programming level, subfiles (usually) work like this:
- You prepare the subfile by either clearing or initializing it (set the associated indicator to *ON and write the control record).
- In a loop:
   - You `READ` the next record from a database file into the variables which have been created implicitly by referencing the database file.
   - You set the `SFLRCDNBR` variable to the next free record number of the subfile.
   - You `WRITE` the data including `SFLRCDNBR` to the SFL record format.
   - Test for `EOF` or other conditions signalling that all desired records have been copied to the SFL. Possibly use this condition to indicate `SFLEND`.
  - Update the associated `SFLDSP`/`SFLDSPCTL` indicators, and `WRITE` the control record format to make the display appear on screen.
- End loop.

**Note**: You need to make sure that the subfile itself must contain at least one record. If an empty SFL is tried to be displayed (`SFLDSP` set), the application will crash.

Handling user input from a subfile works like this:
- Use `READC` to read the next changed subfile record. It reads the complete record, not just the edited field. `SFLRCDNBR` is implicitly set.
- Branch to the desired function depending on the user's selection.
- Optional: If the user changed a record on disk by using the aforementioned function, you may choose to `UPDATE` the single changed record in the SFL. This saves time and CPU-cycles compared to reloading the complete SFL to show the current database records.
- Test for EOF to exit the loop.

#### Flavors of subfiles
The AS/400 basically supports two and a half variants of subfiles:

1. Type *Load-All* will be fed all records in a database file at once. Scroll handling is done by the OS. Preserving option values beyond scrolling boundaries is handled by the OS. Drawbacks are: The more records to load, the more delay until the SFL is displayed. Fixed maximum number of records. Keeping Data in the PF and on screen in sync means frequent reloads. Implementing means to scroll to a certain record (find by primary key) is very cumbersome and needs help of some kind of table, array or other facilities to have a mapping of SFL line numbers (AKA: RRNs) to primary key values in the PF. It is not implemented in this example for the sake of simplicity.

   2. A subtype of Load-All is the *Expandable Subfile*. The SFL gets loaded a small amount of records (one screen page). Thus, the delay until displaying this screen is small. Every keypress for page down instructs the program to load the next bunch of records. The SFL will be expanded in memory on the fly as needed. Scrollback is still handled by the OS. Scrolldown-Handling must be implemented by the programmer. All other restrictions from the Load-All variant still apply.

2. Type *Load-Paged* means that the SFL is as big as one screen of data. There's about 200 lines of additiomnal code needed to make handling the SFL as neat as with a Load-All SFL. Keeping Data in sync is easier because data must be read into the SFL for every scroll anyway. It's relatively easy to implement a position-to feature for jumping to a certain record. Also, there is no limit to the apparent number of records. Since data is re-read from disk with every scroll, any selection (OPT-Field) what to do with the record(s) in question are lost with every scroll. There are different means how to save the selection values and refill them when needed, but for the sake of simplicity, there is no selection saver implemented (yet).

This project provides definitions for both Load-All and Load-Paged SFLs. Expandable subfiles can be created by extending the Load-All Subfile with elements from the Load-Paged DSPF and Code.

Additionally, there are definitions for a prompting screen when records are to be deleted. This is always a type Load-All, because normally, only a few records at once are to be deleted.

Finally, there is a *details* record format containing all fields contained in the PF, for creation, duplication, editing, and viewing of all data.

For reasons stated above, Load-All SFLs are best when there are only a few records to be handled, less than about half dozen scrolls. That's most likely small enough to not need a position-to feature and the delay between loading and displaying stays bearable even on older machines.

On a side note, Load-All flavors are most likely the ones to be used when records are to be selected with SQL, as a result set. While there's no big difference in dealing with a file pointer compared to a SQL cursor, variant 2 adds complexity without any additional benefit.

See *Further Reading* below to learn more about display files and how to create application displays.

#### Description of Files
The example project comprises of three (groups of) files:
- `V_SFLPF` is the shared database file. Shared, because both Load-All and Load- Paged reference this file.
- `V_LODALLDF`, `V_LODALLPG`, and `V_LODALLHP` are the template files for a Load-All project.
- `V_LODPAGDF`, `V_LODPAGPG`, `V_POSLF`, and `V_LODPAGHP` are template files for a Load-Paged project with a position-to field.
- `V_DTLDHP` is a shared help panel group for the details screen.
- `V_SFLDLTHP` is a shared help panel group for the delete confirmation screen.

Additionally, there are:
- `V_SFLMAXID` for fast creation of primary key values.
- `V_SFLPFLOD` writes test data into `V_SFLPF`, so it must not be done by hand.
- `CHANGELOG` contains old changes entries before I moved the source files to CVS.
- `CRTMSGD` is an (yet untested) REXX script to batch create a message file with predefined text and second-level help.
- `MAKEFILE` is a makefile template for `TMKMAKE` on OS/400. For details, see
 [Setting up TMKMAKE](https://try-as400.pocnet.net/wiki/Setting_up_TMKMAKE)

##### File suffix descriptions, PDM types
- `PF` = Physical File, a database table where records will be allocated within. Designated in PDM as type PF.
- `LF` = Logical File, a read-only file referencing a PF, but possibly providing
  - a different search index (aka: sorting order) than the PF, or
  - a subset of fields contained in the PF, or
  - a (More or less) static preselection of records (select/omit), or
  - a static defined so called *join* over multiple database tables.
  - Logical Files may contain more than one record format. Using different index fields in one file is somewhat restricted.
- `DF` = Display File, a screen form description. Designated in PDM as type DSPF.
- `PG` = Program Object, the "driver" with accompanying logic for data movement. Designated in PDM as type RPGLE, in our case.
- `HP` = Help Panel Group, the Online Help Facility. Designated in PDM as type *PNLGRP*.

##### Database files
The AS/400 platform is SQL capable since a long time. Deliberately gnoring this capability, this example focuses on classical API calls to read/write/update/delete database file contents. On very old and thus slow machines, SQL ain't no fun regarding speed. Also, integration of SQL is somewhat clumsy and this project aims to provide a reasonably feature-complete template with as little complexity as possible.

In this regard, it's important to realize that in contrast to SQL (that always operates on a set of records), the classical API operates with a file pointer that points to a certain record. It can be positioned to other records by certain API calls. Operations (aka, other API calls) take place only on that particular record.

- `READ`ing a record usually sets a lock on that one record until the next record is read or the complete file is explicitly `UNLOCK`ed, or closed.
  - `READ` can be called with the option of not creating a lock.
- `WRITE`'ng a record just creates a new record and holds no lock.
- It is not allowed to `UPDATE` a record without a previous `READ` (for obtaining a lock). Doing so yields an operating system exception and the program will be ended.
  - It is allowed to `DELETE` a record without a previous `READ`, though.

This simple interface is blazingly fast, because the database doesn't need to collect a complete SQL result set before giving it to your program. Somewhat oversimplified, the DB2 Engine on OS/400 is using more or less the same primitives to access data: Some kind of SQL to classical API translator. While this isn't exactly correct, it's true enough to help understanding what's approximately going on under the hood.

It is also important to really get the hang of that we're talking about a *file* pointer. This means, that the position of the Physical File's pointer is completely independent of any accompanying Logical File's pointer. Multiple record formats in a logical file share a common file pointer, because it's a file pointer and not a record format pointer. We exploit this fact to ease handling of the Load-Paged subfile. See below.

###### The Physical File
Physical Files may contain only one Record Format. Here it is called SFLTBL. The format name is referenced when reading and writing to the physical file. OS/400 complains at compile time if file name and record name are equal. For that, I'm most often using the suffix TBL for the record format name, because it's a table, while the file name is usually prefixed with "PF". Thus, the PF itself is called `V_SFLPF`.

To make the template components compilable and readily usable (for testing purposes), the PF already contains two field descriptions:
- A numeric field comprised of 4 digits with 0 digits after the decimal separator (locale specific),
- A fixed length text field. Unused storage is automatically filled with blanks. The database knows about coping with VARCHAR fields but RPG does not. So it would be necessary to convert between fixed and variable length strings in the course of the program. I've ommitted varchar for the sake of simplicity.
- The numeric field is used as PRIMARY KEY (see Globals-Flag: UNIQUE).

See *Further Reading* below to learn more about data types and other stuff regarding physical files.

###### The Logical File
As the name `V_POSLF` suggests, this file is mainly used to aid in positioning, and only for the Load-Paged variant of Subfiles. Load-Paged means the programmer has to take care of scrolling logic, because the subfile is exactly the size of one screen of the said subfile.

The logical file has two record formats, `FWDPOS` and `BCKPOS`.

- `FWDPOS` is supposed to only retrieve fields appearing in the subfile record format itself: No need to load all fields into memory when they're not needed. - - `BCKPOS` is thought to retrieve nothing but only the primary key field(s), because it is just used to move the file pointer backwards in the row of records a number of times.

See *Further Reading* below to learn more about logical files' capabilities.

##### Display Files
Display files describe the appearance of screens. Examples of elements are data fields (for input and output of data in textual form), static text (for providing field names or headings, listing valid Function Keys, amongst other uses). To ease development, display files (can) reference fields from physical or logical files.

Data fields do not necessarily represent an 1:1 view of the content of a database's field. Less usual elements like pulldown menus, single- and multiple choice selections are also based on data fields. Thus, they are not necessarily text-like fields to show on screen.

Each element can have certain flags, such as colour and other attributes. Fields can have even more attributes as well as being pre-checked for matching content (only numeric, must be filled entirely, etc.)

Additional information for elements can or must be provided:
- A position on the screen where to to begin the defined element is mandatory, with only a few exceptions.
- Attributes for the elements are optional with a few exceptions when creating some types of fields.
  - Attributes can be colour, style (underline), visibility, etc.
  - Color and classic attributes are alike. `COLOR(RED)` and `DSPATR(BLINK)` yield the same result. This is because color screens have been introduced relatively late to the 5250 world.

Element attributes are contained in the character cell immediately preceding the particular element. For that reason, column one in displays is most often not used by actual screen elements. The same reason prevents elements of different type or different attributes to be immediately adjacent to another in the same line (row) of a display. Since the screen buffer is circular, it is indeed possible to use seemingly forbidden screen positions. Using column 1 makes the attribute field appear one line above, in the last column. Using row 1, column 1 makes the attribute field appear in the last row, and last column of the screen.

Most elements can be modified by conditioning numbers. This includes attribute changes.

###### Commonalities between 5250 and HTML forms
It is important to realise that Display Files resemble what we once knew as simple HTML forms in a web browser window.
- A form is sent to the screen (or browser) to be filled out by the user.
- After entering data, the user presses enter (or the Submit button in HTML) to send back the entire form for processing at once.

There is no communication between host and terminal (emulation) while entering data into fields. This explains certain restrictions regarding interactivity in these screens. Browsers provide a JavaScript Engine to do local processing. There's no JS equivalent for 5250 screens.

###### Using record formats to group screen elements
Screen elements to be shown on a screen are grouped into a so called *record format*s. Display files can contain multiple record formats. There are different types of record formats, the most important ones being regular ones and subfile record formats, with the accompanying subfile control record format.

A simple record format usually controls the entire display, but it's also possible to create record formats occupying only certain areas of a screen. This possibility is exploited with Subfiles, so one screen can show headings for the subfile along with the subfile itself. Finally, it's possible to draw windows on a screen. Each window can contain at least one or more record formats itself.

With some effort of creativity, it's possible to create sort of pseudo graphics output, commonly known as *ASCII Art* (but in this case, it's *EBCDIC Art*). Capabilities are somewhat limited with the given screen space, though.

The DSPF provided has record formats for a list- and a details screen, both in 24x80 only.

Some restrictions apply when dynamically switching display modes, so this capability is out of scope for this project.

###### Providing online help
Help facilities should enable an untrained user to make use of an application, or help him with reminding about details within an application's screens. OS/400 offers *help panel groups* to make it easy for the application developer to provide formatted help texts to end users.

The help facility basically shows fragments of help panel group objects associated with either a rectangular screen position, or with "objects" on a given screen. See below for details.

A very negative example of not helpful online help is Microsoft Windows NT 4. Often, help for a dialog with several fields to fill out provides a mere description about the function a dialog serves with no further explanation about the fields and which kind of data is expected there.

In general, IBM online help on the AS/400 often shines by
- providing extensive details about the meaning of each field and what type of data is expected,
- some safe default to assume if it's unclear what data to provide.

##### The Driver Program
The driver program references the PF, possibly the LF (in case of Load-Paged), and basically handles moving of data between the database and the screen.

While this sounds relatively easy, providing means of catching errors and to also make usage for the user more comfy involves a considerable amount of additional code.

Since this whole thing revolves about subfiles and loading them, the central routine to understand is `LOADDSPSFL`.

Handling a Load-All Subfile is straightforward:
- Loop start,
  - read a record,
  - increment `SFLRCDNBR`,
  - write into the SFL when no error occurred. Error means either `EOF` was encountered on database read, or the maximum subfile records have been loaded into the SFL.

Handling a Load-Paged Subfile is also straightforward:
- Loop start,
  - read a record,
  - write into the SFL when no error occurred. Error means `EOF` was encountered on database read, or maximum subfile records (worth one screen of data) have been loaded.

Scrolling backwards in a Load-All subfile is more tricky. There are multiple ways to achieve relate the proper file pointer position in the database file to re-load the subfile from there.

A Load-Paged subfile is all about relative positioning of data depending on the data contained in the SFL before. The database engine also allows us to do relative positioning (aka, read *n* records forward or backwards). So, my solution to the problem is to read two times SFL size of previous records (counted from the end of a scrolldown-cycle) and do a SFL load from that point. This relative-read approach enables scrollback after using a position-to function and also copes perfectly with deleted or added records.

A drawback of this approach is additional necessary code to check for `BOF` condition, and use this to completely start from scratch for loading records.

So far, reading backwards twice the amount and then loading the SFL forward may seem like a waste of CPU resources. Here I trade efficiency for easiness of code.

The logical file (positioning-aid) contains two record formats:
- `BCKPOS` contains the PRIMARY KEY field, so reading backwards is very fast, because the database engine just needs to read from the index.
- `FWDPOS` is thought to contain only the fields of a database file that are actually shown in the Subfile. It's not clever to load all fields of a very broad table to just discard much of that data because it's not needed in the Subfile.

This enables us to do reads more efficiently. Since both record formats are in the same file and thus share the same file pointer, they can be used as desired but always point to the same record in the database file.

See *Further Reading* below for a reference to the ILE RPG language. This should help understanding the code.

##### The Help Panels
Online Help is an often neglected topic. The AS/400 facilities make it comparatively easy to create helpful online help, because the help text can be made different for different cursor positions on screen.

Help Panels are created with something that resembles HTML in a crude way (called GML). Not all Features of basic HTML are provided, also. See the examples and try out the help on different cursor positions in the SFL itself.

You can add references to help entries by
- absolute screen positions (rectangle), as used in the details record format
- numbered static screen elements, as used for the subfile headings in the subfile control format,
- whole record, as used in the "no data", and "bottom" (function key display) record formats,
- other means.

The mentioned only part of all possibilities because these are which I used in
the example display files.

You can also add cross references to other help panels thru hyperlinks.
Example:
```
:LINK PERFORM='DSPHELP HELPSECTION HELPPNLGRPOBJ'.
This is the text appearing within the link
:ELINK.
```

See *Further Reading* below: *Application Display Programming* has a chapter about Help Panels.

##### The message file
This file is not created with source statements, but with the appropriate commands on the command line. The REXX script `CRTMSGD` has been provided to create a message file with the appropriate messages in German language. The messages are mainly meant for explaining error conditions.

Messages are conditioned with indicators in the display file, to show appropriate informational messages and errors in the message line, usually in line 24 of the display.

The message file, the message IDs and the associated conditioning indicators are all defined in the display file.

So far, these messages have been defined, and are conditioned with indicators as follows:
```
ERR0012  *IN91  Record not found on CHAINing.
ERR1021  *IN92  Duplicate Key on WRITE.
ERR1218  *IN93  Record already locked on DELETE'ng.
RDO1218  *IN94  Record locked on CHAINing, opened read-only.
INF0001  *IN95  No change in details screen detected, no UPDATE attempted.
INF0999  *IN96  Subfile is full. (Load-All, Delete SFL)
```

The Rexx-Script purposely creates the message file in the `QGPL` library. It can be reused by all projects derived from these templates, so it's not necessary to have a special (project specific) message files with all the same definitions over and over.

### Usage Hints
To actually make use of the template files, you need to decide if a Load-All SFL is sufficient or a Load-Paged is more appropriate. Also, Load-Paged includes the classical *Position-To* feature. For Details about Pros and Cons, see *A Word on Subfiles* above.

Then, make the appropriate changes, which have to be consistent across the involved files.

Compilation of objects might fail for various reasons. If there was an error, have a close look at the compiler output in the default output queue. Most often this is `QPRINT`. Type `WRKOUTQ` on a command line to review output queues and their content. Maybe first clear them of old stuff and recompile to not search too long for the most recent output. Compiler logs are extremely verbose and finding errors can be tricky. Especially when searching for syntax errors in RPG programs, errors might create a chain of further errors. This happens most often when the compiler has been ignoring a statement, that is needed in the subsequent code. I recommend you to take time, patience and develop a strong spirit against rushing.

#### PF
The PF procedure is the same for Load-All and Load-Paged variants of SFLs.

Copy `V_SFLPF` into a new library with a new name. I recommend to name the file XXXPF, where XXX is a a string up to seven characters. OS-Restrictions about valid special characters and may-not-begin-with-a-digit apply.

Edit the PF and rename the record format to be XXXTBL, or just XXX if XXXTBL exceeds the 10 character length limit of a record format. Modify and add fields to match your requirements. See *Further Reading* below for valid data types in *DDS for Physical and Logical Files*
.
After adding fields, I recommend to sort them by field size: Biggest first, smallest last, to minimize wasted space through padding.

If done, save and exit. Type 14 into the `OPT` field in PDM to create your physical file.

#### LF
A LF is strictly required only for Load-Paged SFLs derived from these templates. Of ourse, your enhancements to a Load-All SFL can impose a need for a LF, e. g. to provide a different sorting order within the SFL, compared to the PRIMARY KEY field, which isn't often a user friendly display ordering.

For Load-Paged SFLs, copy `V_POSLF` into a new library with the same name. Edit the LF but leave the record format names alone. Change the `PFILE` statement to match the name of your physival file. Add field names already defined in the PF to match your requirements:
- Add only fields to be displayed in the SFL itself into `FWDPOS` record format,
- Add the keys field(s) to `BCKPOS` record format.

Both measures lessen unneccessary work for the machine (and thus, faster response times).

If done, save and exit. Type 14 into the `OPT` field in PDM to create your logical file.

Another requirement for an LF can arise from the need to have an automatically maintained, and invisible primary key field. `V_SFLMAXID` has been prepared for this purpose. Change the referred PF name in the heading. Later, code in the RPG file has to be uncommented. Of course you need to make sure, your PF has a numeric field `ID`, before compiling.

If done, save and exit. Type 14 into the `OPT` field in PDM to create your logical file.

#### DSPF
The fields created in the PF should be somehow reflected on the display. The easier part is to do this in the `DETAILFRM` record format.

##### Details record format
- List the fields in a convenient order,
- provide field names as static text,
- connect both with runs of dots as shown in the example,
- make sure fields have unique conditioning indicators in the range 60..69. Yes, more than 9 fields cannot make use of cursor positioning in this example. If there are more than 9 editable fields on one screen, it's probably either too crowded or too advanced and thus out of scope for these templates.

##### Subfile
The list view can be more tricky. I strongly recommend to use a text editor with a monospaced font, an on-screen ruler and/or cursor position display to test-build one subfile line. Example (starts in Column 2 as on the real screen):
```
         1         2         3         4         5         6         7         8
12345678901234567890123456789012345678901234567890123456789012345678901234567890
 Opt  Field1                      Field2                         Field3
  _   __________________________  _____________________________  ______________
```
- Decide which fields need to be displayed.
- Leave at least two blank positions between fields to enhance readability.
- If all desired fields won't fit on one line,
  - remove the R(eference) tag,
  - add a `'$'` to the field name to indicate a "derived field",
  - add proper length and data type to the field definition.
  - Later in the code, field content can be easily shortened, see comments there.

**Note:** Never shorten a key field, because cut content can't be related to the matching record in the PF anymore! (Or provide the key field as hidden record.)
- Decide about headings placement,
  - if heading text will be longer than individual fields,
  - if headings are shorter and meant for right-aligned numeric fields.
- If you have numeric fields, always add a `Y` in the data type column, and probably use an `EDTCDE` to get rid of leading zeros.

You can always type Option 17 in PDM to call `SDA` (Scree Design Agent). It helps greatly with reviewing screens without code being written yet, using SDA option 12. Maybe refrain from saving changes made in SDA: It will delete all comments and most likely reorder statements.

If done, save and exit. Type 14 into the `OPT` field in PDM to create your display file.

#### Program
An RPG program has these sections, most often annotated with comments. Because of the comments, I'll delve into details too much.
- H(eading) defines compiler flags, copyright text.
- F(files) define I/O.
- D(efinitions) are for creating variables, and call prototypes.
- C(ompute) statements are actual code.

**Note:** The V3 ILE RPG compiler doesn't support compiler flags in `H` lines.

Code is divided into subroutines, to get a good balance between (unnecessary) code duplication and readability. The first routine is implicit the `main()` routine (as known in C).

When helpful, optical separator lines have been inserted as comments to contain loops or other code flow, to enhance readability.

**Note:** Because of the positional nature of the code (position of statements along a line is important), watch out when using simple search and replace in a text editor! For any change made, obey the correct position of code in the individual line! When in doubt, make use of `F4`-Prompting in SEU.

Changes to be made for customizing your own application.
- Obey the `CVTOPT` comments in the H(eader).
- Replace the name of the PF.
- Replace the name of the record format of the PF.
- Delete the definition of `VALFLD$`, it is in for testing purposes *only*.
- Replace `KEYVAL` with the field name of your individual primary key.
- Change the field listing in `SETCSRPOS` appropriately to your definition of fields in the DSPF `DETAILFRM` record format.

##### NULL fields
- obey the `ALWNULL` compile option in the H(eader).
- change the `CHECKNULL` and `SETNULL` SRs; otherwise delete them and their accompanying `EXSR` calls.

When using the readymade application, keep in mind:
- A value of just blanks in a text field will be turned into NULL,
- a value of 0 (`*ZERO`) for a numeric field will be turned into NULL.

##### Shortened fields
If you have *one* shortened field for the Subfile (named with a $ at the end), replace `VALFLD` with the appropriate name of your (original) field in both the `PREPSFLDTA` and `*INZSR` SRs.

If you have *more than one* field to be shortened, move the field length  calculation from `*INZSR` before the calculation statements in `PREPSFLDTA`. Duplicate and change the whole block for any to-be-shortened field.

If you don't need this facility, delete the mentioned parts.

Moreover, if you neither use NULL fields, nor shortened fields, nor other customization of SFL data, you may also completely get rid of `PREPSFLDTA` SR.

##### Primary key ID
If you want to use the automatic ID generation,
- Uncomment the code in the `INCLASTID` SR,
- Uncomment the two EXSR calls to `INCLASTID`.

If you don't need this facility, delete the mentioned parts.

##### General advice
If done, save and exit. Type 14 into the `OPT` field in PDM to create your program. You can start it with `CALL PROGNAME` (assuming you named the RPGLE source PROGNAME).

It is pretty normal that even for a template derived program to not successfully compile at the first try. Generating unintended inconsistencies with the changes laid out above is very easy. So, read the compiler output, fix the error(s) and try again. More nasty are run time errors. This means, the code is basically working, but a condition arises which makes the program crash. On the appropriate prompting screen from OS/400, type D(ebug) and carefully examine the generated program debug dump in the output queue `QEZDEBUG`. Always remember that the templates as delivered work and have no known run time failures.

#### PNLGRP
Change the text as required. Add more sections for newly introduced fields in
your display files. Note: You need to create references to your help text in
the DSPF itself!

If done, save and exit. Type 14 into the `OPT` field in PDM to create your panel group.

### Further Reading
To successfully understand these templates, I strongly recommend to get hold and make use of the following documentation from IBM:
- [DDS for Physical and Logical Files](https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/rzakb/rzakbprint.htm)
- [DDS for Display Files](https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/rzakc/print.htm)
- [ILE RPG Reference](https://www.ibm.com/support/knowledgecenter/ssw_ibm_i_74/rzasd/rzasdprintthis.htm)
- [Source Entry Utility manual](https://try-as400.pocnet.net/wiki/File:Source_Entry_Utility-v4.pdf) (Editor)
- [Application Display Programming](http://public.dhe.ibm.com/systems/power/docs/systemi/v6r1/en_US/sc415715.pdf)

----
```
vim: textwidth=78 autoindent
$Id: readme.md,v 1.21 2023/10/14 14:10:23 poc Exp $
```
