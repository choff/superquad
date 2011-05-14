%option noyywrap
%{
	#include "global.h"
	#include "q_operations.h"
	#include "quadComp.tab.h"
%}


%%

\/\/.*\n { DEBUG("One-line comment"); } // one-line comment
\/\*.*\*\/ { DEBUG("Mutiline comment"); } // mutiline comment

"||"	{ return LOG_OR; } // 
"&&"	{ return LOG_AND; }
"!="	{ return NOT_EQUAL; }
"=="	{ return EQUAL; }
">="	{ return GREATER_OR_EQUAL; }
"<="	{ return LESS_OR_EQUAL; }
"<<"	{ return SHIFTLEFT; }

"="		{ DEBUG("Assign recognized"); return ASSIGN; }

"--"	{ return DEC_OP; }
"++"	{ return INC_OP; }

"void"	{ return TYPE_VOID; }
"if"	{ return IF; }
"else"	{ return ELSE; }
"return"	{return RETURN; }
"while"	{ return WHILE; }
"do"	{ return DO; }
"int"	{ DEBUG("Int recognized"); yylval.var_type = &type_integer; return VAR_TYPE; }
"float"	{ DEBUG("Float recognized"); yylval.var_type = &type_real; return VAR_TYPE; }

[0-9]+.[0-9]+	{ yylval.floatval = atof(yytext); return FLOAT_CONSTANT; }
[0-9]+	{ yylval.intval = atoi(yytext); return INT_CONSTANT; }

[a-zA-Z_][a-zA-Z0-9_]*	{ 
	// yytext will be overwritten once the next token is scanned, therefore we
	// have to save its contents to yylval here
	strcpy(yylval.string, yytext);
	char tmp[1000];
	sprintf(tmp, "Identifier \"%s\"", yylval.string);
	DEBUG(tmp);
	return IDENTIFIER;
}

[{}()[\];,\.<>\/\*+-]	{return *yytext;}

. { } // Filter all other characters.
%%
