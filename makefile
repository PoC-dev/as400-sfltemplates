# $Id: makefile,v 1.3 2023/10/14 15:31:06 poc Exp $

# Note: To understand this file, accustom yourself with
# - make: https://en.wikipedia.org/wiki/Make_(software)
# - tmkmake: https://try-as400.pocnet.net/wiki/Setting_up_TMKMAKE

# Variables used by rules
DSTLIB=MYLIB
SRCFILE=SOURCES
STAMPFILE=BLDTMSTMPS

# Global rules for recreating everything, if required --------------------------
# Add your targets below to have them recreated as necessary with just a simple
# call to tmkmake.
all: curlib commonfiles loadall loadpag

# This is to make sure that even if we run in batch, we can use unqualified
# names in rules. Because there are no dependents, the rule is executed always.
curlib:
    CHGCURLIB CURLIB($(DSTLIB))

# Menu -------------------------------------------------------------------------
# This file is not existing, so we don't list it in the "all" target.  It is
# kept as an example, though.
CMDCTI<MENU>: MYMENU.$(SRCFILE)<FILE>
    CRTMNU MENU($(@F)) TYPE(*UIM) SRCFILE($(SRCFILE)) INCFILE(QGPL/MENUUIM)

# Load-All template -------------------------------------------------------------
loadall: V_LODALLHP<PNLGRP> V_LODALLPG<PGM>

V_LODALLHP<PNLGRP>: V_LODALLHP.$(SRCFILE)<FILE>
    CRTPNLGRP PNLGRP($(@F)) SRCFILE($(SRCFILE))

V_LODALLDF<FILE>: V_LODALLDF.$(SRCFILE)<FILE> V_SFLPF.$(STAMPFILE)<FILE>
    CRTDSPF FILE($(@F)) SRCFILE($(SRCFILE))

V_LODALLPG<PGM>: V_LODALLPG.$(SRCFILE)<FILE> V_LODALLDF<FILE> +
        V_SFLPF.$(STAMPFILE)<FILE>
    CRTBNDRPG PGM($(@F)) SRCFILE($(SRCFILE))

# Load-All template -------------------------------------------------------------
loadpag: V_LODPAGHP<PNLGRP> V_LODPAGPG<PGM>

V_LODPAGHP<PNLGRP>: V_LODPAGHP.$(SRCFILE)<FILE>
    CRTPNLGRP PNLGRP($(@F)) SRCFILE($(SRCFILE))


V_POSLF.$(STAMPFILE)<FILE>: V_POSLF.$(SRCFILE)<FILE> +
        V_SFLPF.$(STAMPFILE)<FILE>
    -DLTF FILE($(@M))
    CRTLF FILE($(@M)) SRCFILE($(SRCFILE))
    -RMVM FILE($(@F)) MBR($(@M))
    ADDPFM FILE($(@F)) MBR($(@M))

V_LODPAGDF<FILE>: V_LODPAGDF.$(SRCFILE)<FILE> V_SFLPF.$(STAMPFILE)<FILE>
    CRTDSPF FILE($(@F)) SRCFILE($(SRCFILE))


V_LODPAGPG<PGM>: V_LODPAGPG.$(SRCFILE)<FILE> V_LODPAGDF<FILE> +
        V_SFLPF.$(STAMPFILE)<FILE>
    CRTBNDRPG PGM($(@F)) SRCFILE($(SRCFILE))

# Common files ------------------------------------------------------------------
# Note: V_SFLMAXID is not listed because generation will fail without
# customization.
commonfiles: V_SFLDLTHP<PNLGRP> V_SFLPFLOD<PGM>

V_SFLDLTHP<PNLGRP>: V_SFLDLTHP.$(SRCFILE)<FILE>
    CRTPNLGRP PNLGRP($(@F)) SRCFILE($(SRCFILE))


V_SFLPF.$(STAMPFILE)<FILE>: V_SFLPF.$(SRCFILE)<FILE>
    CHGPF FILE($(@M)) SRCFILE($(SRCFILE))
    -RMVM FILE($(@F)) MBR($(@M))
    ADDPFM FILE($(@F)) MBR($(@M))

V_SFLMAXID.$(STAMPFILE)<FILE>: V_SFLMAXID.$(SRCFILE)<FILE> +
        V_SFLPF.$(STAMPFILE)<FILE>
    -DLTF FILE($(@M))
    CRTLF FILE($(@M)) SRCFILE($(SRCFILE))
    -RMVM FILE($(@F)) MBR($(@M))
    ADDPFM FILE($(@F)) MBR($(@M))


V_SFLPFLOD<PGM>: V_SFLPFLOD.$(SRCFILE)<FILE> V_SFLPF.$(STAMPFILE)<FILE>
    CRTBNDRPG PGM($(@F)) SRCFILE($(SRCFILE))

# EOF --------------------------------------------------------------------------
# vim: ft=make textwidth=80 colorcolumn=81 expandtab tabstop=4 shiftwidth=4
