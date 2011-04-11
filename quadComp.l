%option noyywrap
%option yylineno

%{
	#include "global.h"
	#include "quadComp.tab.h"
%}


%%

\/\/.*\n { fprintf(stderr, "One-line comment\n"); } // one-line comment
\/\*.*\*\/ { fprintf(stderr, "Mutiline comment\n"); } // mutiöine comment

"||"	{ return LOG_OR; }
"&&"	{ return LOG_AND; }
"!="	{ return NOT_EQUAL; }
"=="	{ return EQUAL; }
">="	{ return GREATER_OR_EQUAL; }
"<="	{ return LESS_OR_EQUAL; }
"<<"	{ return SHIFTLEFT; }
"void"	{ return TYPE_VOID; }
"if"	{ return IF; }
"else"	{ return ELSE; }
"return"	{return RETURN; }
"while"	{ return WHILE; }
"do"	{ return DO; }
"int"	{ fprintf(stderr, "Int recognized\n"); return TYPE_INT; }
"float"	{ fprintf(stderr, "Float recognized\n"); return TYPE_FLOAT; }

[0-9]+.[0-9]+	{ yylval = atof(yytext); return FLOAT_CONSTANT; }
[0-9]+	{ yylval = atoi(yytext); return INT_CONSTANT; }

[a-zA-Z][a-zA-Z0-9_]*	{ fprintf(stderr, "Identifier \"%s\"\n", yytext); return IDENTIFIER; }

%%
