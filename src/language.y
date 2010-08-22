%{
/***************************************************************************
 *
 * $Id$
 *
 * Grammar and parser for the mscgen language.
 * Copyright (C) 2009 Michael C McTernan, Michael.McTernan.2001@cs.bris.ac.uk
 *
 * This file is part of msclib.
 *
 * Msc is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * Msclib is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Foobar; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 ***************************************************************************/

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "safe.h"
#include "msc.h"

/* Lexer prototype to prevent compiler warning */
int yylex(void);

/* Use verbose error reporting such that the expected token names are dumped */
#define YYERROR_VERBOSE

/* Name of parameter that is passed to yyparse() */
#define YYPARSE_PARAM yyparse_result

#define YYMALLOC malloc_s

unsigned long lex_getlinenum(void);

/* yyerror
 *  Error handling function.  The TOK_XXX names are substituted for more
 *  understandable values that make more sense to the user.
 */
void yyerror(const char *str)
{
    static const char *tokNames[] = { "TOK_OCBRACKET",          "TOK_CCBRACKET",
                                      "TOK_OSBRACKET",          "TOK_CSBRACKET",
                                      "TOK_REL_DOUBLE_TO",      "TOK_REL_DOUBLE_FROM",
                                      "TOK_REL_SIG_TO",         "TOK_REL_SIG_FROM",
                                      "TOK_REL_METHOD_TO",      "TOK_REL_METHOD_FROM",
                                      "TOK_REL_RETVAL_TO",      "TOK_REL_RETVAL_FROM",
                                      "TOK_REL_CALLBACK_TO",    "TOK_REL_CALLBACK_FROM",
                                      "TOK_REL_SIG",            "TOK_REL_METHOD",
                                      "TOK_REL_RETVAL",         "TOK_REL_DOUBLE",
                                      "TOK_EQUAL",              "TOK_COMMA",
                                      "TOK_SEMICOLON",          "TOK_MSC",
                                      "TOK_ATTR_LABEL",         "TOK_ATTR_URL",
                                      "TOK_ATTR_IDURL",         "TOK_ATTR_ID",
                                      "TOK_ATTR_LINE_COLOUR",   "TOK_ATTR_TEXT_COLOUR",
                                      "TOK_SPECIAL_ARC",        "TOK_UNKNOWN",
                                      "TOK_STRING",             "TOK_QSTRING",
                                      "TOK_OPT_HSCALE",         "TOK_ASTERISK",
                                      "TOK_OPT_WIDTH",          "TOK_ARC_BOX",
                                      "TOK_ARC_ABOX",           "TOK_ARC_RBOX",
                                      "TOK_ATTR_TEXT_BGCOLOUR", "TOK_ATTR_ARC_TEXT_BGCOLOUR",
                                      "TOK_REL_LOSS_TO",        "TOK_REL_LOSS_FROM",
                                      "TOK_OPT_ARCGRADIENT",    "TOK_ATTR_ARC_SKIP" };

    static const char *tokRepl[] =  { "{",             "}",
                                      "[",             "]",
                                      ":>",            "<:",
                                      "->",            "<-",
                                      "=>",            "<=",
                                      ">>",            "<<",
                                      "=>>",           "<<=",
                                      "--",            "==",
                                      "..",            "::",
                                      "=",             ",",
                                      ";",             "msc",
                                      "label",         "url",
                                      "idurl",         "id",
                                      "linecolour",    "textcolour",
                                      "'...', '---'",  "characters",
                                      "string",        "quoted string",
                                      "hscale",        "'*'",
                                      "width",         "box",
                                      "abox",          "rbox",
                                      "textbgcolour",  "arctextbgcolor",
                                      "-x",            "x-",
                                      "arcgradient",   "arcskip" };
    static const int tokArrayLen = sizeof(tokNames) / sizeof(char *);

    char *s;
    int   t;

    /* Print standard message part */
    fprintf(stderr,"Error detected at line %lu: ", lex_getlinenum());

    /* Search for TOK */
    s = strstr(str, "TOK_");
    while(s != NULL)
    {
        int found = 0;

        /* Print out message until start of the token is found */
        while(str < s)
        {
            fprintf(stderr, "%c", *str);
            str++;
        }

        /* Look for the token name */
        for(t = 0; t < tokArrayLen && !found; t++)
        {
            if(strncmp(tokNames[t], str, strlen(tokNames[t])) == 0)
            {
                /* Dump the replacement string */
                fprintf(stderr, "'%s'", tokRepl[t]);

                /* Skip the token name */
                str += strlen(tokNames[t]);

                /* Exit the loop */
                found = 1;
            }
        }

        /* Check if a replacement was found */
        if(!found)
        {
            /* Dump the next char and skip it so that TOK doesn't match again */
            fprintf(stderr, "%c", *str);
            str++;
        }

        s = strstr(str, "TOK_");
    }

    fprintf(stderr, "%s.\n", str);

}

int yywrap()
{
    return 1;
}


char *removeEscapes(const char *in)
{
    const uint16_t l = strlen(in);
    char          *r = malloc_s(l + 1);
    uint16_t       t, u;

    if(r != NULL)
    {
        for(t = u = 0; t < l; t++)
        {
            r[u] = in[t];
            if(in[t] != '\\' || in[t + 1] != '\"')
            {
                u++;
            }
        }

        r[u] = '\0';
    }

    return r;
}

extern FILE *yyin;
extern int   yyparse (void *YYPARSE_PARAM);


Msc MscParse(FILE *in)
{
    Msc m;

    yyin = in;

    /* Parse, and check that no errors are found */
    if(yyparse((void *)&m) == 0)
    {
        return m;
    }
    else
    {
        return NULL;
    }
}


%}

%token TOK_STRING TOK_QSTRING TOK_EQUAL TOK_COMMA TOK_SEMICOLON TOK_OCBRACKET TOK_CCBRACKET
       TOK_OSBRACKET TOK_CSBRACKET TOK_MSC
       TOK_ATTR_LABEL TOK_ATTR_URL TOK_ATTR_ID TOK_ATTR_IDURL
       TOK_ATTR_LINE_COLOUR TOK_ATTR_TEXT_COLOUR TOK_ATTR_TEXT_BGCOLOUR
       TOK_ATTR_ARC_LINE_COLOUR TOK_ATTR_ARC_TEXT_COLOUR TOK_ATTR_ARC_TEXT_BGCOLOUR
       TOK_REL_LOSS_TO TOK_REL_LOSS_FROM
       TOK_REL_SIG_BI      TOK_REL_SIG_TO      TOK_REL_SIG_FROM
       TOK_REL_METHOD_BI   TOK_REL_METHOD_TO   TOK_REL_METHOD_FROM
       TOK_REL_RETVAL_BI   TOK_REL_RETVAL_TO   TOK_REL_RETVAL_FROM
       TOK_REL_DOUBLE_BI   TOK_REL_DOUBLE_TO   TOK_REL_DOUBLE_FROM
       TOK_REL_CALLBACK_BI TOK_REL_CALLBACK_TO TOK_REL_CALLBACK_FROM
       TOK_REL_BOX         TOK_REL_ABOX
       TOK_REL_RBOX
       TOK_SPECIAL_ARC     TOK_OPT_HSCALE
       TOK_OPT_WIDTH       TOK_OPT_ARCGRADIENT
       TOK_ASTERISK        TOK_UNKNOWN
       TOK_REL_SIG TOK_REL_METHOD TOK_REL_RETVAL TOK_REL_DOUBLE
       TOK_ATTR_ARC_SKIP

%union
{
    char         *string;
    Msc           msc;
    MscOpt        opt;
    MscOptType    optType;
    MscArc        arc;
    MscArcList    arclist;
    MscArcType    arctype;
    MscEntity     entity;
    MscEntityList entitylist;
    MscAttrib     attrib;
    MscAttribType attribType;
};

%type <msc>        msc
%type <opt>        optlist opt
%type <optType>    optval TOK_OPT_HSCALE TOK_OPT_WIDTH TOK_OPT_ARCGRADIENT
%type <arc>        arc arcrel
%type <arclist>    arclist
%type <entity>     entity
%type <entitylist> entitylist
%type <arctype>    relation_box relation_line relation_bi relation_to relation_from
                   TOK_REL_SIG_BI TOK_REL_METHOD_BI TOK_REL_RETVAL_BI TOK_REL_CALLBACK_BI
                   TOK_REL_SIG_TO TOK_REL_METHOD_TO TOK_REL_RETVAL_TO TOK_REL_CALLBACK_TO TOK_REL_DOUBLE_BI
                   TOK_REL_SIG_FROM TOK_REL_METHOD_FROM TOK_REL_RETVAL_FROM TOK_REL_CALLBACK_FROM
                   TOK_REL_DOUBLE_TO TOK_REL_DOUBLE_FROM
                   TOK_REL_LOSS_TO TOK_REL_LOSS_FROM
                   TOK_SPECIAL_ARC TOK_REL_BOX TOK_REL_ABOX TOK_REL_RBOX
                   TOK_REL_SIG TOK_REL_METHOD TOK_REL_RETVAL TOK_REL_DOUBLE
%type <attrib>     attrlist attr
%type <attribType> attrval
                   TOK_ATTR_LABEL TOK_ATTR_URL TOK_ATTR_ID TOK_ATTR_IDURL
                   TOK_ATTR_LINE_COLOUR TOK_ATTR_TEXT_COLOUR TOK_ATTR_TEXT_BGCOLOUR
                   TOK_ATTR_ARC_LINE_COLOUR TOK_ATTR_ARC_TEXT_COLOUR  TOK_ATTR_ARC_TEXT_BGCOLOUR
                   TOK_ATTR_ARC_SKIP
%type <string>     string TOK_STRING TOK_QSTRING


%%
msc:          TOK_MSC TOK_OCBRACKET optlist TOK_SEMICOLON entitylist TOK_SEMICOLON arclist TOK_SEMICOLON TOK_CCBRACKET
{
    $$ = MscAlloc($3, $5, $7);
    *(Msc *)yyparse_result = $$;

}
           | TOK_MSC TOK_OCBRACKET entitylist TOK_SEMICOLON arclist TOK_SEMICOLON TOK_CCBRACKET
{
    $$ = MscAlloc(NULL, $3, $5);
    *(Msc *)yyparse_result = $$;

};

optlist:     opt
           | optlist TOK_COMMA opt
{
    $$ = MscLinkOpt($1, $3);
};

opt:         optval TOK_EQUAL string
{
    $$ = MscAllocOpt($1, $3);
};

optval:      TOK_OPT_HSCALE | TOK_OPT_WIDTH | TOK_OPT_ARCGRADIENT;

entitylist:   entity
{
    $$ = MscLinkEntity(NULL, $1);   /* Create new list */
}
            | entitylist TOK_COMMA entity
{
    $$ = MscLinkEntity($1, $3);     /* Add to existing list */
};



entity:       string
{
    $$ = MscAllocEntity($1);
}
            | entity TOK_OSBRACKET attrlist TOK_CSBRACKET
{
    MscEntityLinkAttrib($1, $3);
}
;

arclist:      arc
{
    $$ = MscLinkArc(NULL, $1);      /* Create new list */
}
              | arclist TOK_SEMICOLON arc
{
    $$ = MscLinkArc($1, $3);     /* Add to existing list */
}
              | arclist TOK_COMMA arc
{
    /* Add a special 'parallel' arc */
    $$ = MscLinkArc(MscLinkArc($1, MscAllocArc(NULL, NULL, MSC_ARC_PARALLEL)), $3);
};
;



arc:          arcrel TOK_OSBRACKET attrlist TOK_CSBRACKET
{
    MscArcLinkAttrib($1, $3);
}
              | arcrel;

arcrel:       TOK_SPECIAL_ARC
{
    $$ = MscAllocArc(NULL, NULL, $1);
}
            | string relation_box string
{
    $$ = MscAllocArc($1, $3, $2);
}
            | string relation_bi string
{
    MscArc arc = MscAllocArc($1, $3, $2);
    MscArcLinkAttrib(arc, MscAllocAttrib(MSC_ATTR_BI_ARROWS, "true"));
    $$ = arc;
}
            | string relation_to string
{
    $$ = MscAllocArc($1, $3, $2);
}
            | string relation_line string
{
    MscArc arc = MscAllocArc($1, $3, $2);
    MscArcLinkAttrib(arc, MscAllocAttrib(MSC_ATTR_NO_ARROWS, "true"));
    $$ = arc;
}
            | string relation_from string
{
    $$ = MscAllocArc($3, $1, $2);
}
            | string relation_to TOK_ASTERISK
{
    $$ = MscAllocArc($1, "*", $2);
}
            | TOK_ASTERISK relation_from string
{
    $$ = MscAllocArc($3, "*", $2);
};

relation_box:  TOK_REL_BOX | TOK_REL_ABOX | TOK_REL_RBOX;
relation_line: TOK_REL_SIG | TOK_REL_METHOD | TOK_REL_RETVAL | TOK_REL_DOUBLE;
relation_bi:   TOK_REL_SIG_BI | TOK_REL_METHOD_BI | TOK_REL_RETVAL_BI | TOK_REL_CALLBACK_BI | TOK_REL_DOUBLE_BI;
relation_to:   TOK_REL_SIG_TO | TOK_REL_METHOD_TO | TOK_REL_RETVAL_TO | TOK_REL_CALLBACK_TO | TOK_REL_DOUBLE_TO | TOK_REL_LOSS_TO;
relation_from: TOK_REL_SIG_FROM | TOK_REL_METHOD_FROM | TOK_REL_RETVAL_FROM | TOK_REL_CALLBACK_FROM | TOK_REL_DOUBLE_FROM | TOK_REL_LOSS_FROM;

attrlist:    attr
           | attrlist TOK_COMMA attr
{
    $$ = MscLinkAttrib($1, $3);
};

attr:         attrval TOK_EQUAL string
{
    $$ = MscAllocAttrib($1, $3);
};

attrval:      TOK_ATTR_LABEL | TOK_ATTR_URL | TOK_ATTR_ID | TOK_ATTR_IDURL |
              TOK_ATTR_LINE_COLOUR | TOK_ATTR_TEXT_COLOUR | TOK_ATTR_TEXT_BGCOLOUR |
              TOK_ATTR_ARC_LINE_COLOUR | TOK_ATTR_ARC_TEXT_COLOUR | TOK_ATTR_ARC_TEXT_BGCOLOUR |
              TOK_ATTR_ARC_SKIP;


string: TOK_QSTRING
{
    $$ = removeEscapes($1);
}
      | TOK_STRING
{
    $$ = $1;
};
%%


/* END OF FILE */
