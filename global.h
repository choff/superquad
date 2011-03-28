#ifndef GLOBAL_H_
#define GLOBAL_H_

#endif /*GLOBAL_H_*/

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

void  addSymboltableEntry (symtabEntry * Symboltable,char * name,symtabEntryType type,symtabEntryType internType,int offset,int line,int index1,int index2,symtabEntry * vater,int parameter);
void  getSymbolTypePrintout(symtabEntryType type, char * writeIn);
void  writeSymboltable (symtabEntry * Symboltable, FILE * outputFile);
