%{
	#include <stdio.h>
	
	extern int yylineno;

	void pr_debug(char *message, char *file, int lineno);
	#define DEBUG(msg) (pr_debug(msg, __FILE__, __LINE__))
%}
//Bison declarations

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
    : function { printf("Program with single function"); }                 
    | programm function { printf("Program with more functions"); }
    ;



function
    : var_type id '(' parameter_list ')' ';' { DEBUG("Function prototype recognized\n"); }
    | var_type id '(' parameter_list ')' function_body { DEBUG("Function body recognized\n"); }
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
    | TYPE_FLOAT id
    | declaration ',' id
    ;

parameter_list
    : TYPE_INT id
    | TYPE_FLOAT id
    | parameter_list ',' TYPE_INT id
    | parameter_list ',' TYPE_FLOAT id
    | TYPE_VOID
    ;

var_type
    : TYPE_INT { DEBUG("Int variable type\n"); }
    | TYPE_VOID { DEBUG("Void variable type\n"); }
    | TYPE_FLOAT { DEBUG("Float variable type\n"); }
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
	printf("Superquad is now starting the parse process...\n");

	yyparse();
	return 0;
}

yyerror(const char* s)  {
	printf("%s in line %d.\n", s, yylineno);
}
