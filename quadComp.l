%option noyywrap
%{
	#include "global.h"
	#include "quadComp.tab.h"
%}


%%

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
"int"	{ return TYPE_INT; }
"float"	{ return TYPE_FLOAT; }

[0-9]+.[0-9]+	{ yylval = atof(yytext); return FLOAT_CONSTANT; }
[0-9]+	{ yylval = atoi(yytext); return INT_CONSTANT; }

[a-zA-Z][a-zA-Z0-9_]*	{ return IDENTIFIER; }

%%
