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
	/* CONSTANT */
	/* IDENTIFIER */


%%
