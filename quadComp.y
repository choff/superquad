%{
	#include <stdio.h>
	#include "global.h"
	
	extern int yylineno;

	// global symbol table
	symtabEntry* symbolTable;
	
	// offset relative to the beginning of the function where this variable will be stored
//	int memOffset;
			   
	// global variable in which the current father (the context, for example the function) is saved
	symtabEntry* symbolTableFather = NULL;
%}
//Bison declarations

%union {
	int intval;
	float floatval;
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

%type <string> IDENTIFIER
%type <intval> declaration 
%type <intval> parameter_list 
%type <string> id

%%    // grammar rules


programm
    : function { DEBUG("Program with single function"); }                 
    | programm function { DEBUG("Program with more functions"); }
    ;

function
    : var_type id set_father '(' parameter_list ')' ';'
	{ 
		// $5: number of parameters in parameter_list
		getSymboltableEntry(symbolTable, $<string>2, NULL)->parameter = $5;
	}
    
	| var_type id set_father '(' parameter_list ')'
		{
			getSymboltableEntry(symbolTable, $<string>2, NULL)->parameter = $5;
		}
	  function_body
	  	{
			symbolTableFather = NULL;	// leaving function scope
			DEBUG("Resetting memOffset to 0.");
			memOffset = 0;
		}
    ;

set_father
	: 
		{
			// function already has a symbol table entry if a prototype was
			// declared
			// $<string>0 is the function's name (id)
			symbolTableFather = getSymboltableEntry(symbolTable, $<string>0, NULL);
			
			if (!symbolTableFather) {
				// function not in symbol table
				addSymboltableEntry(&symbolTable, $<string>0, FUNC, NOP, memOffset, 0, 0, 0, NULL, 0);
			}
			
			symbolTableFather = getSymboltableEntry(symbolTable, $<string>0, NULL);
		}
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
			$$ = INTEGER;	// necessary for declaration list
			// $<string>2: two entries up the stack (in this case, this refers to the value of 'id', which is the name of the identifier, assigned to yylval in quadComp.l)
			addIntToSymtab(&symbolTable, $<string>2, symbolTableFather);
		}

	| TYPE_FLOAT id
		{
			$$ = REAL;	// necessary for declaration list
			addRealToSymtab(&symbolTable, $<string>2, symbolTableFather);
		}

    | declaration ',' id	// such as 'int x, y, z;'
    	{   
			$$ = $1;
			if ($1 == INTEGER) {
				addIntToSymtab(&symbolTable, $<string>3, symbolTableFather);
			}
			else if ($1 == REAL) {
				addRealToSymtab(&symbolTable, $<string>3, symbolTableFather);
			} 
		}

    ;

/*  If a function was declared with a prototype, parameter_list was already traversed and the parameter's entered into
	the symbol table. So we only add the parameters if they don't yet exist.

	The function name resides at $<string>-2 on the stack.

	$$ is set to the number of parameters in parameter_list, as this is what is needed
	for the function's symbol table entry.
*/
parameter_list
    : TYPE_INT id
		{
			$$ = 1;
			symtabEntry* father = getSymboltableEntry(symbolTable, $<string>-2, NULL);
			if ( ! getSymboltableEntry(symbolTable, $<string>2, father) ) {
				symtabEntry* newEntry = addIntToSymtab(&symbolTable, $<string>2, father);
				newEntry->parameter = 1;
			}
			else {
				// memOffset has to be advanced anyway
				memOffset += OFFSET_INT;
			}
		}
    | TYPE_FLOAT id
		{
			$$ = 1;
			symtabEntry* father = getSymboltableEntry(symbolTable, $<string>-2, NULL);
			if ( ! getSymboltableEntry(symbolTable, $<string>2, father) ) {
				symtabEntry* newEntry = addRealToSymtab(&symbolTable, $<string>2, father);
				newEntry->parameter = 1;
			}
			else {
				// memOffset has to be advanced anyway
				memOffset += OFFSET_REAL;
			}
		}
    | parameter_list ',' TYPE_INT id
		{
			$$ = $1 + 1;
			symtabEntry* father = getSymboltableEntry(symbolTable, $<string>-2, NULL);
			if ( ! getSymboltableEntry(symbolTable, $<string>4, father) ) {
				symtabEntry* newEntry = addIntToSymtab(&symbolTable, $<string>4, father);
				newEntry->parameter = $$;
			}
			else {
				// memOffset has to be advanced anyway
				memOffset += OFFSET_INT;
			}
		}
    | parameter_list ',' TYPE_FLOAT id
		{
			$$ = $1 + 1;
			symtabEntry* father = getSymboltableEntry(symbolTable, $<string>-2, NULL);
			if ( ! getSymboltableEntry(symbolTable, $<string>4, father) ) {
				symtabEntry* newEntry = addRealToSymtab(&symbolTable, $<string>4, father);
				newEntry->parameter = $$;
			}
			else {
				// memOffset has to be advanced anyway
				memOffset += OFFSET_REAL;
			}
		}
    | TYPE_VOID	{ $$ = 0; }
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
    : IDENTIFIER { /*DEBUG("IDENTIFIER:"); DEBUG($1); strcpy($$, $1);*/ }
    ;
    
%%

int main(int argc, char **argv) {
	printf("Argument count is: %d", argc);

    yylineno = 1;

	DEBUG("Superquad is now starting the parse process...");

	yyparse();

	FILE* symFile;
	symFile = fopen("ourSym.txt", "w");
//	fputs("blub\n", symFile);
    writeSymboltable(symbolTable, symFile);

	return 0;
}

yyerror(const char* s)  {
	printf("%s in line %d.\n", s, yylineno);
}
