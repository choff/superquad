%{
//Prologue




%}
//Bison declarations


// Adapted from http://en.wikipedia.org/wiki/Operators_in_C_and_C%2B%2Bv 
%left '='	// unsure about this, is it really necessary?
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
    : function                  
    | programm function         
    ;



function
    : var_type id '(' parameter_list ')' ';'
    | var_type id '(' parameter_list ')' function_body
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
    : INT id
    | FLOAT id
    | declaration ',' id
    ;

parameter_list
    : INT id
    | FLOAT id
    | parameter_list ',' INT id
    | parameter_list ',' FLOAT id
    | VOID                     
    |                          
    ;

var_type
    : INT 
    | VOID
    | FLOAT
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
    | id '='          expression 
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
    | CONSTANT                                 
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

//Epilogue
