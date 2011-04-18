%{
	#include <stdio.h>
	#include "global.h"
	
	extern int yylineno;

	// global symbol table
	symtabEntry* symbolTable;
	
	// offset relative to the beginning of the function where this variable will be stored
	int memOffset;
	#define OFFSET_INT 4
	#define OFFSET_REAL 8
			   
	// global variable in which the current father (the context, for example the function) is saved
	symtabEntry* symbolTableFather;
%}
//Bison declarations

%union {
	int intval;
	float fval;
	char string[1000];
}

%start programm

%right ASSIGN

%token RETURN
%token TYPE_VOID
%token TYPE_FLOAT
%token TYPE_INT

%token IDENTIFIER

%token INT_CONSTANT
%token FLOAT_CONSTANT

/* Control structures */
%token IF
%token ELSE
%token WHILE
%token DO

/* Arithemetic and logical operations */
// Adapted from http://en.wikipedia.org/wiki/Operators_in_C_and_C%2B%2Bv 
//%left '='	// unsure about this, is it really necessary?
%left LOG_OR
%left LOG_AND
%left EQUAL NOT_EQUAL
%left '<' LESS_OR_EQUAL '>' GREATER_OR_EQUAL
%left SHIFTLEFT
%left '+' '-'
%left '*' '/' '%'
%left INC_OP DEC_OP U_PLUS U_MINUS '!' 

%%    // grammar rules


programm
    : function { DEBUG("Program with single function"); }                 
    | programm function { DEBUG("Program with more functions"); }
    ;

function
    : var_type id '(' parameter_list ')' ';'
	{ 
		DEBUG("Function prototype recognized");
		addSymboltableEntry(&symbolTable, $<string>2, FUNC, NOP, memOffset, 0, 0, 0, symbolTableFather, 0);
	}
    
	| var_type id '(' parameter_list ')' function_body { DEBUG("Function body recognized"); }
    ;

function_body
    : '{' statement_list  '}'
    | '{' declaration_list statement_list '}'
    ;

declaration_list
    : declaration ';'
    | declaration_list declaration ';'
    ;

declaration
    : TYPE_INT id
		{
			DEBUG("Found integer variable.");
			//$$ = INTEGER;	// necessary for declaration list
			/* symbolTable: the global symbol table
			   $2: two entries up the stack (in this case, this refers to the value of 'id', which is the name of the identifier, assigned to yylval in quadComp.l)
			   INTEGER: type; from the enumeration 'symtabEntryType' (defined in global.h)
               NOP: no idea why... 
			   memOffset: offset relative to the beginning of the function where this variable will be stored
			   0: no idea why...
			   0: if we had arrays, this would be the first dimension
			   0: if we had arrays, this would be the second dimension
			   symbolTableFather: global variable in which the current father is saved
			   0: this is not the table entry for a function, so there are no function parameters
			*/
			addSymboltableEntry(&symbolTable, $<string>2, INTEGER, NOP, memOffset, 0, 0, 0, symbolTableFather, 0);
			memOffset += OFFSET_INT;
		}

	| TYPE_FLOAT id
		{
			DEBUG("Found floating-point variable.");
			//$$ = REAL;	// necessary for declaration list
			addSymboltableEntry(&symbolTable, $<string>2, REAL , NOP, memOffset, 0, 0, 0, symbolTableFather, 0);
			memOffset += OFFSET_REAL;
		}

    | declaration ',' id	// such as 'int x, y, z;'
    	{   /*
			$$ = $1;
			if ($1 == INTEGER) {
				addSymboltableEntry(&symbolTable, $<string>3, INTEGER, NOP, memOffset, 0, 0, 0, symbolTableFather, 0);
				memOffset += OFFSET_INT;
			}
			else if ($2 == REAL) {
				addSymboltableEntry(&symbolTable, $<string>3, REAL, NOP, memOffset, 0, 0, 0, symbolTableFather, 0);
				memOffset += OFFSET_REAL;
			} */
		}

    ;

parameter_list
    : TYPE_INT id
    | TYPE_FLOAT id
    | parameter_list ',' TYPE_INT id
    | parameter_list ',' TYPE_FLOAT id
    | TYPE_VOID
    ;

var_type
    : TYPE_INT { DEBUG("Int variable type"); }
    | TYPE_VOID { DEBUG("Void variable type"); }
    | TYPE_FLOAT { DEBUG("Float variable type"); }
    ;



statement_list
    : statement
    | statement_list statement  
    ;

statement
    : matched_statement
    | unmatched_statement
    ;

matched_statement
    : IF '(' assignment ')' matched_statement ELSE matched_statement
    | assignment ';'                                                
    | RETURN ';'                                                 
    | RETURN assignment ';'                                                  
    | WHILE '(' assignment ')' matched_statement                             
    | DO statement WHILE '(' assignment ')' ';'                              
    | '{' statement_list '}'                                                 
    | '{' '}'                                                                                                                                                                                       
    ;

unmatched_statement
    : IF '(' assignment ')' statement                       
    | WHILE '(' assignment ')' unmatched_statement          
    | IF '(' assignment ')' matched_statement ELSE unmatched_statement 
    ;


assignment
    : expression                 
    | id ASSIGN          expression { DEBUG("Assignment recognized"); }
    ;

expression
    : INC_OP expression                        
    | DEC_OP expression                        
    | expression LOG_OR           expression   
    | expression LOG_AND          expression   
    | expression NOT_EQUAL        expression   
    | expression EQUAL            expression   
    | expression GREATER_OR_EQUAL expression   
    | expression LESS_OR_EQUAL    expression   
    | expression '>'              expression   
    | expression '<'              expression   
    | expression SHIFTLEFT        expression   
    | expression '+'              expression   
    | expression '-'              expression   
    | expression '*'              expression   
    | expression '/'              expression   
    | expression '%'              expression   
    | '!' expression                           
    | '+' expression %prec U_PLUS              
    | '-' expression %prec U_MINUS             
    | FLOAT_CONSTANT
    | INT_CONSTANT
    | '(' expression ')'                       
    | id '(' exp_list ')'                      
    | id '('  ')'                              
    | id
    ;

exp_list
    : expression
    | exp_list ',' expression	
    ;

id
    : IDENTIFIER	
    ;
    
%%

void pr_debug(char *message, char *file, int lineno) {
	fprintf(stderr, "%s(%d): %s\n", file, lineno, message);
}

int main() {
    yylineno = 1;

	DEBUG("Superquad is now starting the parse process...");

	yyparse();

	FILE* symFile;
	symFile = fopen("ourSym.txt", "w");
//	fputs(symFile, "blub\n");
    writeSymboltable(symbolTable, symFile);

	return 0;
}

yyerror(const char* s)  {
	printf("%s in line %d.\n", s, yylineno);
}
