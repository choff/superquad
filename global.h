#ifndef GLOBAL_H_
#define GLOBAL_H_

#include <stdlib.h>
#include <stdio.h>

extern const struct variable_type type_integer;
extern const struct variable_type type_real;
extern int memOffset;

void pr_debug(char *message, char *file, int lineno);
#define DEBUG(msg) (pr_debug(msg, __FILE__, __LINE__))


typedef enum symtab_EntryType {INTEGER, REAL, BOOL, PROC, NOP, ARR, FUNC, PROG, PRG_PARA}
	symtabEntryType;

typedef struct a_symtabEntry{
	char * name;
	symtabEntryType type;
	symtabEntryType internType;
	int offset;
	int line;
	int index1;
	int index2;
	struct a_symtabEntry * vater;
	int parameter;
	int number;
	float value;
	struct a_symtabEntry * next;
} symtabEntry;


/*
 * Variable type definitions
 */

// Memory needed by an int or a real, is added every time a variable is entered into the symbol table
#define SIZE_INT 4
#define SIZE_REAL 8

struct variable_type {
	size_t size;                 /* size of an instance of the variable(in bytes) */
	symtabEntryType symtabType;  /* type of the variable in the symbol table */
};


void  getSymbolTypePrintout(symtabEntryType type, char * writeIn);
void  writeSymboltable (symtabEntry * Symboltable, FILE * outputFile);

// Symbol table manipulation functions
symtabEntry* addSymboltableEntry (symtabEntry** Symboltable,char * name,symtabEntryType type,symtabEntryType internType,int offset,int line,int index1,int index2,symtabEntry * vater,int parameter);
symtabEntry* getSymboltableEntry(symtabEntry* Symboltable, char* name, symtabEntry* father);
symtabEntry* addVarToSymtab(symtabEntry** symbolTable, char* name, const struct variable_type* type, symtabEntry* father);
symtabEntry* getTempVariable(symtabEntry** symbolTable, char* name, const struct variable_type* type, symtabEntry* father);

#endif /*GLOBAL_H_*/
