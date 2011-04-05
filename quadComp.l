%{

}

%}


%%

"||"	{ return LOG_OR; }
"&&"	{ return LOG_AND; }
"!="	{ return NOT_EQUAL; }
"=="	{ return EQUAL; }
">="	{ return GREATER_OR_EQUAL; }
"<="	{ return LESS_OR_EQUAL; }
"<<"	{ return SHIFTLEFT; }
"void"	{ return VOID; }
"if"	{ return IF; }
"else"	{ return ELSE; }
"return"	{return RETURN; }
"while"	{ return WHILE; }
"do"	{ return DO; }
"int"	{ return INT; }
"float"	{ return FLOAT; }
[0-9]+.[0-9]+	{ return CONSTANT; }
[0-9]+	{ return CONSTANT; }
[a-zA-Z][a-zA-Z0-9_]*	{ return IDENTIFIER; }
	/* CONSTANT */
	{ return CONSTANT; }
	/* IDENTIFIER */

%%
