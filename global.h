#ifndef GLOBAL_H_
#define GLOBAL_H_

#include <stdlib.h>
#include <stdio.h>

// Memory needed by an int or a real, is added every time a variable is entered into the symbol table
#define OFFSET_INT 4
#define OFFSET_REAL 8

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

void  getSymbolTypePrintout(symtabEntryType type, char * writeIn);
void  writeSymboltable (symtabEntry * Symboltable, FILE * outputFile);

// Symbol table manipulation functions
symtabEntry* addSymboltableEntry (symtabEntry** Symboltable,char * name,symtabEntryType type,symtabEntryType internType,int offset,int line,int index1,int index2,symtabEntry * vater,int parameter);
symtabEntry* getSymboltableEntry(symtabEntry* Symboltable, char* name, symtabEntry* father);
symtabEntry* addIntToSymtab(symtabEntry** symtab, char* name, symtabEntry* father);
symtabEntry* addRealToSymtab(symtabEntry** symtab, char* name, symtabEntry* father);

#endif /*GLOBAL_H_*/
