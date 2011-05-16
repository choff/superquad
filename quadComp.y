%{
	#include <stdio.h>
	#include <string.h>
	#include <math.h>
	#include "global.h"
	#include "q_operations.h"
	
	extern int yylex(void);
	extern void yyerror(const char* s);
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
	const struct variable_type *var_type;
	struct q_operand operand;
	char string[1000];
	struct q_op_jump *jmp_op;
}

%start programm

%right ASSIGN

%token RETURN
%token TYPE_VOID
%token VAR_TYPE

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

%type <var_type> VAR_TYPE
%type <intval> INT_CONSTANT
%type <floatval> FLOAT_CONSTANT

%type <string> IDENTIFIER
%type <var_type> declaration 
%type <intval> parameter_list 
%type <string> id
%type <operand> expression
%type <operand> assignment
%type <intval> stmt_no_marker
%type <jmp_op> if_evaluate_marker
%type <jmp_op> else_marker

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
    : VAR_TYPE id
		{
			$$ = $1;	// necessary for declaration list
			// $<string>2: two entries up the stack (in this case, this refers to the value of 'id', which is the name of the identifier, assigned to yylval in quadComp.l)
			addVarToSymtab(&symbolTable, $<string>2, $1, symbolTableFather);
		}

    | declaration ',' id	// such as 'int x, y, z;'
    	{
			$$ = $1;
			addVarToSymtab(&symbolTable, $<string>3, $1, symbolTableFather);
		}

    ;

/*  If a function was declared with a prototype, parameter_list was already traversed and the parameter's entered into
	the symbol table. So we only add the parameters if they don't yet exist.

	The function name resides at $<string>-2 on the stack.

	$$ is set to the number of parameters in parameter_list, as this is what is needed
	for the function's symbol table entry.
*/
parameter_list
    : VAR_TYPE id
		{
			$$ = 1;
			symtabEntry* father = getSymboltableEntry(symbolTable, $<string>-2, NULL);
			if ( ! getSymboltableEntry(symbolTable, $<string>2, father) ) {
				symtabEntry* newEntry = addVarToSymtab(&symbolTable, $<string>2, $1, father);
				newEntry->parameter = 1;
			}
			else {
				// memOffset has to be advanced anyway
				memOffset += $1->size;
			}
		}
    | parameter_list ',' VAR_TYPE id
		{
			$$ = $1 + 1;
			symtabEntry* father = getSymboltableEntry(symbolTable, $<string>-2, NULL);
			if ( ! getSymboltableEntry(symbolTable, $<string>4, father) ) {
				symtabEntry* newEntry = addVarToSymtab(&symbolTable, $<string>4, $3, father);
				newEntry->parameter = $$;
			}
			else {
				// memOffset has to be advanced anyway
				memOffset += $3->size;
			}
		}
    | TYPE_VOID	{ $$ = 0; }
    ;

var_type
    : VAR_TYPE { DEBUG("Standart variable type"); }
    | TYPE_VOID { DEBUG("Void variable type"); }
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
    : IF '(' assignment ')' if_evaluate_marker matched_statement ELSE else_marker matched_statement {
		$8->target = q_op_list_get_instr_count();
	}
    | assignment ';'                                                
    | RETURN ';' {
		q_instr_add(Q_INSTR_TYPE_RET, NULL);
	}
    | RETURN assignment ';' {
		q_instr_add(Q_INSTR_TYPE_RET, &($2));
	}
    | WHILE '(' assignment ')' matched_statement                             
    | DO stmt_no_marker statement WHILE '(' assignment ')' ';'                              {
		// Jump to head of loop if "assignment" evaluated to "true"
		q_instr_add(Q_INSTR_TYPE_COND_JUMP, Q_JUMP_WHEN_TRUE($6), $2);
	}
    | '{' statement_list '}'                                                 
    | '{' '}'                                                                                                                                                                                       
    ;

unmatched_statement
    : IF '(' assignment ')' if_evaluate_marker statement {
		// Fill in correct jump target for the jump instruction generated by if_evaluate_marker
		$5->target = q_op_list_get_instr_count();
	}
    | WHILE '(' assignment ')' unmatched_statement          
    | IF '(' assignment ')' if_evaluate_marker matched_statement ELSE else_marker unmatched_statement {
		$8->target = q_op_list_get_instr_count();
	}
    ;

if_evaluate_marker
	: {
		/* Check if condition evaluated to false. If so, jump to the end of the "if" block.
		 * Since we do not know the end just yet, set the jump target to -1. It will be set
		 * When the whole if-block has been parsed. 
		 */
		$$ = (struct q_op_jump *) q_instr_add(Q_INSTR_TYPE_COND_JUMP, Q_JUMP_WHEN_FALSE($<operand>-1), Q_UNKNOWN_JUMP_TARGET);
	}
	;

else_marker
	: {
		$$ = (struct q_op_jump *) q_instr_add(Q_INSTR_TYPE_JUMP, Q_UNKNOWN_JUMP_TARGET);
		($<jmp_op>-2)->target = q_op_list_get_instr_count();
	}
	;

assignment
    : expression                    {
		// return value of the expression
		$$ = $1;
	}
    | id ASSIGN          expression { 
		DEBUG("Assignment recognized");

		// Lookup identifier in symbol table
		symtabEntry *symtabEntry = getSymboltableEntryInScope(symbolTable, symbolTableFather, $1);
		if (!symtabEntry) {
			fprintf(stderr, "In function %s: Variable not declared: %s\n", symbolTableFather->name, $1);
			YYABORT;
		}
		q_instr_add(Q_INSTR_TYPE_ASSIGN, symtabEntry, $3);

		// return the value that was assigned
		$$ = $3;
	}
    ;

expression
    : INC_OP expression {
		if ($2.type == OPD_TYPE_LITERAL) {
			fprintf(stderr, "Cannot pre-increment a literal value.\n");
			YYABORT;
		}

		// var := var + 1
		q_instr_add(Q_INSTR_TYPE_CALC, $2.data.varEntry, $2, Q_ARITHMETIC_OP_ADD, literal_one);

		$$ = $2;
	}
    | DEC_OP expression                      {
		// TODO
		$$ = literal_one;
	}
    | expression LOG_OR           expression {
		symtabEntry *retVarEntry = getTempVariable(&symbolTable, &type_integer, symbolTableFather);
		$$ = q_operand_init_variable(retVarEntry);

		q_instr_add(Q_INSTR_TYPE_COND_JUMP, Q_JUMP_WHEN_TRUE($1), q_op_list_get_instr_count() + 4);
		q_instr_add(Q_INSTR_TYPE_COND_JUMP, Q_JUMP_WHEN_TRUE($3), q_op_list_get_instr_count() + 3);

		q_instr_add(Q_INSTR_TYPE_ASSIGN, retVarEntry, Q_FALSE);
		q_instr_add(Q_INSTR_TYPE_JUMP, q_op_list_get_instr_count() + 2);
		q_instr_add(Q_INSTR_TYPE_ASSIGN, retVarEntry, Q_TRUE);
	}
    | expression LOG_AND          expression {
		symtabEntry *retVarEntry = getTempVariable(&symbolTable, &type_integer, symbolTableFather);
		$$ = q_operand_init_variable(retVarEntry);

		q_instr_add(Q_INSTR_TYPE_COND_JUMP, Q_JUMP_WHEN_FALSE($1), q_op_list_get_instr_count() + 4);
		q_instr_add(Q_INSTR_TYPE_COND_JUMP, Q_JUMP_WHEN_FALSE($3), q_op_list_get_instr_count() + 3);

		q_instr_add(Q_INSTR_TYPE_ASSIGN, retVarEntry, Q_TRUE);
		q_instr_add(Q_INSTR_TYPE_JUMP, q_op_list_get_instr_count() + 2);
		q_instr_add(Q_INSTR_TYPE_ASSIGN, retVarEntry, Q_FALSE);
	}
    | expression NOT_EQUAL        expression {
		symtabEntry *result = getTempVariable(&symbolTable, &type_integer, symbolTableFather);
		$$ = q_operand_init_variable(result);

		q_instr_add_rel(result, $1, Q_RELATIVE_OP_NOT_EQUAL, $3);
	}
    | expression EQUAL            expression {
		symtabEntry *result = getTempVariable(&symbolTable, &type_integer, symbolTableFather);
		$$ = q_operand_init_variable(result);

		q_instr_add_rel(result, $1, Q_RELATIVE_OP_EQUAL, $3);
	}
    | expression GREATER_OR_EQUAL expression {
		symtabEntry *result = getTempVariable(&symbolTable, &type_integer, symbolTableFather);
		$$ = q_operand_init_variable(result);

		q_instr_add_rel(result, $1, Q_RELATIVE_OP_GREATER_EQUAL, $3);
	}
    | expression LESS_OR_EQUAL    expression {
		symtabEntry *result = getTempVariable(&symbolTable, &type_integer, symbolTableFather);
		$$ = q_operand_init_variable(result);

		q_instr_add_rel(result, $1, Q_RELATIVE_OP_LOWER_EQUAL, $3);
	}
    | expression '>'              expression {
		symtabEntry *result = getTempVariable(&symbolTable, &type_integer, symbolTableFather);
		$$ = q_operand_init_variable(result);

		q_instr_add_rel(result, $1, Q_RELATIVE_OP_GREATER, $3);
	}
    | expression '<'              expression {
		symtabEntry *result = getTempVariable(&symbolTable, &type_integer, symbolTableFather);
		$$ = q_operand_init_variable(result);

		q_instr_add_rel(result, $1, Q_RELATIVE_OP_LOWER, $3);
	}
    | expression SHIFTLEFT        expression {
		symtabEntry *retVarEntry = getTempVariable(&symbolTable, q_op_assignment_get_result_type($1, $3), symbolTableFather);
		$$ = q_operand_init_variable(retVarEntry);
                                                                           
		if (q_operand_get_type($3)->symtabType == INTEGER) {
			if ($3.type == OPD_TYPE_LITERAL) {
				struct q_operand rightMulOp;
				rightMulOp.type = OPD_TYPE_LITERAL;
				rightMulOp.data.literal.type = &type_integer;
				rightMulOp.data.literal.value.int_value = (int) pow(2, $3.data.literal.value.int_value);
				q_instr_add(Q_INSTR_TYPE_CALC, retVarEntry, $1, Q_ARITHMETIC_OP_MUL, rightMulOp);
			}
			else {
				fprintf(stderr, "Can only shift by a constant value.");
				YYABORT;
			}
		}
		else {
			fprintf(stderr, "Can't shift by a non-integer value.");
			YYABORT;
		}
	}
    | expression '+'              expression {
		symtabEntry *retVarEntry = getTempVariable(&symbolTable, q_op_assignment_get_result_type($1, $3), symbolTableFather);
		$$ = q_operand_init_variable(retVarEntry);

		q_instr_add(Q_INSTR_TYPE_CALC, retVarEntry, $1, Q_ARITHMETIC_OP_ADD, $3);
	}
    | expression '-'              expression {
		symtabEntry *retVarEntry = getTempVariable(&symbolTable, q_op_assignment_get_result_type($1, $3), symbolTableFather);
		$$ = q_operand_init_variable(retVarEntry);

		q_instr_add(Q_INSTR_TYPE_CALC, retVarEntry, $1, Q_ARITHMETIC_OP_SUB, $3);
	}
    | expression '*'              expression {
		symtabEntry *retVarEntry = getTempVariable(&symbolTable, q_op_assignment_get_result_type($1, $3), symbolTableFather);
		$$ = q_operand_init_variable(retVarEntry);

		q_instr_add(Q_INSTR_TYPE_CALC, retVarEntry, $1, Q_ARITHMETIC_OP_MUL, $3);
	}
    | expression '/'              expression {
		symtabEntry *retVarEntry = getTempVariable(&symbolTable, q_op_assignment_get_result_type($1, $3), symbolTableFather);
		$$ = q_operand_init_variable(retVarEntry);

		q_instr_add(Q_INSTR_TYPE_CALC, retVarEntry, $1, Q_ARITHMETIC_OP_DIV, $3);
	}
    | expression '%'              expression {
		symtabEntry *retVarEntry = getTempVariable(&symbolTable, q_op_assignment_get_result_type($1, $3), symbolTableFather);
		$$ = q_operand_init_variable(retVarEntry);

		q_instr_add(Q_INSTR_TYPE_CALC, retVarEntry, $1, Q_ARITHMETIC_OP_MOD, $3);
	}
    | '!' expression                         {
		symtabEntry *retVarEntry = getTempVariable(&symbolTable, &type_integer, symbolTableFather);
		$$ = q_operand_init_variable(retVarEntry);

		q_instr_add(Q_INSTR_TYPE_COND_JUMP, Q_JUMP_WHEN_FALSE($2), q_op_list_get_instr_count() + 3);

		q_instr_add(Q_INSTR_TYPE_ASSIGN, retVarEntry, Q_FALSE);
		q_instr_add(Q_INSTR_TYPE_JUMP, q_op_list_get_instr_count() + 2);

		q_instr_add(Q_INSTR_TYPE_ASSIGN, retVarEntry, Q_TRUE);
	}
    | '+' expression %prec U_PLUS            {
		// TODO
		$$ = literal_one;
	}
    | '-' expression %prec U_MINUS           {
		// TODO
		$$ = literal_one;
	}
    | FLOAT_CONSTANT {
		DEBUG("Float constant recognized");

		$$.type = OPD_TYPE_LITERAL;
		$$.data.literal.type = &type_real;
		$$.data.literal.value.float_value = $1;
	}
    | INT_CONSTANT {
		DEBUG("Int constant recognized");

		$$.type = OPD_TYPE_LITERAL;
		$$.data.literal.type = &type_integer;
		$$.data.literal.value.int_value = $1;
	}
    | '(' expression ')'                     {
		// TODO
		$$ = literal_one;
	}
    | id '(' exp_list ')'                    {
		// TODO
		$$ = literal_one;
	}
    | id '('  ')'                            {
		// TODO
		$$ = literal_one;
	}
    | id {
		// Lookup identifier in symbol table
		symtabEntry *entry = getSymboltableEntryInScope(symbolTable, symbolTableFather, $1);
		if (!entry) {
			fprintf(stderr, "In function %s: Variable not declared: %s\n", symbolTableFather->name, $1);
			YYABORT;
		}
		
		$$ = q_operand_init_variable(entry);
	}
    ;

exp_list
    : expression
    | exp_list ',' expression	
    ;

id
    : IDENTIFIER { strcpy($$, $1); }
    ;

stmt_no_marker
	: {
		$$ = q_op_list_get_instr_count();
	}
    
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
	q_op_gen_code(stdout);

	return 0;
}

void yyerror(const char* s)  {
	printf("%s in line %d.\n", s, yylineno);
}
