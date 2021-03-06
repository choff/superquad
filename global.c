#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include "global.h"

const struct variable_type type_integer = {
	SIZE_INT,
	INTEGER
};

const struct variable_type type_real = {
	SIZE_REAL,
	REAL
};

//symtabEntry * theSymboltable=0;    //pointer as a entry to the Symboltable, which is a linked list

// offset relative to the beginning of a function where this variable will be stored
int memOffset = 0;

// Counter for temporary variables. Used for generating unique temp variable names.
int tempVarCnt = 0;


void writeSymboltable (symtabEntry * Symboltable, FILE * outputFile){
//writes the Symboltable in the outFile formated in a table view 

	fprintf (outputFile, "Symboltabelle\n");
	fprintf (outputFile, "Nr\tName                    Type    Int_Typ Offset\tLine\tIndex1\tIndex2\tVater\tParameter\n");
	fprintf (outputFile, "---------------------------------------------------------------------------------------------\n");
	
	//variables
	symtabEntry * currentEntry;  	// pointer for the current Symboltable entry for walking through the list
	int j;							// help variable, to build a string with the same length
	char helpString[21];			// string for formatted output
	
	int i = 0;
	currentEntry = Symboltable;
	do {
		//walks through the Symboltable
		fprintf(outputFile, "%d:\t", currentEntry->number); 
		 
//        if (i++ == 2) return 0;

		strncpy(helpString, currentEntry->name,20);
		for (j = 19; j >= strlen(currentEntry->name); j--) {
		//loop for formating the output to file 
			helpString[j] = ' ';
		}
		helpString[20] = 0;
		fprintf(outputFile, "%s\t", helpString);
		
		getSymbolTypePrintout(currentEntry->type, helpString);
		fprintf(outputFile, "%s", helpString);
		
		getSymbolTypePrintout(currentEntry->internType, helpString);
		fprintf(outputFile, "%s", helpString);
		
		fprintf(outputFile, "%d\t\t", currentEntry->offset);
		fprintf(outputFile, "%d\t\t", currentEntry->line);
		fprintf(outputFile, "%d\t\t", currentEntry->index1);
		fprintf(outputFile, "%d\t\t", currentEntry->index2);
		if(currentEntry->vater){
//			fprintf(outputFile, "%d\t\t", currentEntry->vater->number);
			fprintf(outputFile, "%s\t\t", currentEntry->vater->name);
		}
		else {
//			fprintf(outputFile, "0\t\t");
			fprintf(outputFile, "None\t\t");
		}
		fprintf(outputFile, "%d\t\t\n", currentEntry->parameter);
		
		fflush(outputFile);
		
		currentEntry = currentEntry->next;
	} while (currentEntry);
	
}


void getSymbolTypePrintout(symtabEntryType  type, char * writeIn){
//puts the printout for a given SymbolEntrytype to the given string
	switch(type){
	case PROG:     strcpy(writeIn,"Prg     ")  ;break;
	case NOP :     strcpy(writeIn,"None    ")  ;break;
	case REAL:     strcpy(writeIn,"Real    ")  ;break;
	case BOOL: 	   strcpy(writeIn,"Bool    ")  ;break;
	case INTEGER : strcpy(writeIn,"Int     ")  ;break;
	case ARR :     strcpy(writeIn,"Array   ")  ;break;
	case FUNC:     strcpy(writeIn,"Func    ")  ;break;
	case PROC:     strcpy(writeIn,"Proc    ")  ;break;
	case PRG_PARA: strcpy(writeIn,"P.Prmtr ")  ;break;
	default:       strcpy(writeIn,"        ")  ;break;
	}
}

/* Find and return the symbol table entry by name. */
symtabEntry* getSymboltableEntry (
	symtabEntry* symbolTable,
	char* name,
	symtabEntry* father
)
{
	while (symbolTable) {
		int sameName = !strcmp(name, symbolTable->name);
		int sameFather = symbolTable->vater == father;

		if (sameName && sameFather) {
			return symbolTable;
		}
        else {
			symbolTable = symbolTable->next;
		}
	}
	return symbolTable;
}

/*
 * Looks for a symbol table entry named "name" in the scope of the specified symbol table "context"
 */
symtabEntry* getSymboltableEntryInScope(symtabEntry *symbolTable, symtabEntry *context, const char* name) {
	symtabEntry *curr_symbol = symbolTable;
	
	while (curr_symbol) {
		if (strcmp(name, curr_symbol->name) == 0) {
			// Determine if the current identifier is also within scope of symbol table "context"
			symtabEntry *curr_context = context;
			
			while(true) {
				if (curr_context == curr_symbol->vater)
					return curr_symbol;
				
				if (curr_context == NULL)
					break;
				
				curr_context = curr_context->vater;
			}
		}
		
		curr_symbol = curr_symbol->next;
	}
	
	return NULL;
}


/* Creates a new temporary variable with pseudo-random name and adds it to the symbol table */
symtabEntry* getTempVariable(symtabEntry** symbolTable, const struct variable_type* type, symtabEntry* father)
{
	char tempVarName [10];
	sprintf(tempVarName, "H%i", tempVarCnt++);
	return addVarToSymtab(symbolTable, tempVarName, type, father);
}

symtabEntry* addVarToSymtab(symtabEntry** symbolTable, char* name, const struct variable_type* type, symtabEntry* father)
{
//	char message[100];
//	
//	char* scope = father ? father->name : "global scope";
//	sprintf(message, "Found integer variable in '%s'.", scope);
////	sprintf(message, "Found integer variable.");
//-g
//	DEBUG(message);

	/* symbolTable: the global symbol table
	   $2: two entries up the stack (in this case, this refers to the value of 'id', which is the name of the identifier, assigned to yylval in quadComp.l)
	   type->symtabType: type; from the enumeration 'symtabEntryType' (defined in global.h)
	   NOP: no idea why... 
	   memOffset: offset relative to the beginning of the function where this variable will be stored
	   0: no idea why...
	   0: if we had arrays, this would be the first dimension
	   0: if we had arrays, this would be the second dimension
	   father: current father element
	   0: this is not the table entry for a function, so there are no function parameters
	*/
	symtabEntry* newEntry = addSymboltableEntry(symbolTable, name, type->symtabType, NOP, memOffset, 0, 0, 0, father, 0);
	memOffset += type->size;

	return newEntry;
}

// Adds an entry into the symbol table, returns the new entry.
symtabEntry* addSymboltableEntry (symtabEntry** Symboltable,
						  char * name,
						  symtabEntryType type,
						  symtabEntryType internType,
						  int offset,
						  int line,
						  int index1,
						  int index2,
						  symtabEntry * vater,
						  int parameter) {
	//adds a symbolEntry to the end of the Symboltable. If there global variable theSymboltable is not 
	//initialized, this will be done with the first call of this function
	
	symtabEntry * newSymtabEntry = (symtabEntry*) malloc (sizeof (symtabEntry));
	
	//allocates the memory for the new symtabEntry
	newSymtabEntry->name = (char *) malloc (strlen(name) +1);
	
	strcpy(newSymtabEntry->name,name);
	newSymtabEntry->type = type;
	newSymtabEntry->internType = internType;
	newSymtabEntry->offset = offset;
	newSymtabEntry->line = line;
	newSymtabEntry->index1 = index1;
	newSymtabEntry->index2 = index2;
	newSymtabEntry->vater = vater;
	newSymtabEntry->parameter = parameter;
	newSymtabEntry->next = 0;
		
	if (!(*Symboltable)){
		DEBUG("Symbol table empty, initializing.");
		//there is no entry in the Symboltable
		(*Symboltable) = newSymtabEntry;
	}
	else {
		//there is at least one entry in the Symboltable
		symtabEntry * symtabHelp = (*Symboltable);
		while (symtabHelp->next) {
		//walks to the last entry of Symboltable
			symtabHelp = symtabHelp->next;
		}
		symtabHelp->next = newSymtabEntry;
	}

	return newSymtabEntry;
}


/*
int main_w (void){
	FILE * outputFile;

	//sample for a valid symboltable
	addSymboltableEntry(theSymboltable,"If_Demo"  , PROG,  		NOP, 18, 0, 0, 0, 0, 0 );
	addSymboltableEntry(theSymboltable,"wert"     , INTEGER,	NOP,  0, 0, 0, 0, 0, 0 );
	addSymboltableEntry(theSymboltable,"d"        , INTEGER,  	NOP,  4, 0, 0, 0, 0, 0 );
	addSymboltableEntry(theSymboltable,"H0"       , BOOL,  		NOP,  8, 0, 0, 0, 0, 0 );
	addSymboltableEntry(theSymboltable,"H1"       , BOOL,  		NOP,  9, 0, 0, 0, 0, 0 );
	addSymboltableEntry(theSymboltable,"H2"       , BOOL,  		NOP, 10, 0, 0, 0, 0, 0 );
	addSymboltableEntry(theSymboltable,"H3"       , BOOL,  		NOP, 11, 0, 0, 0, 0, 0 );
	addSymboltableEntry(theSymboltable,"H4"       , BOOL,  		NOP, 12, 0, 0, 0, 0, 0 );
	addSymboltableEntry(theSymboltable,"H5"       , BOOL,  		NOP, 13, 0, 0, 0, 0, 0 );
	addSymboltableEntry(theSymboltable,"H6"       , BOOL,  		NOP, 14, 0, 0, 0, 0, 0 );
	addSymboltableEntry(theSymboltable,"H7"       , BOOL,  		NOP, 15, 0, 0, 0, 0, 0 );
	addSymboltableEntry(theSymboltable,"H8"       , BOOL,  		NOP, 16, 0, 0, 0, 0, 0 );
	addSymboltableEntry(theSymboltable,"H9"       , BOOL,  		NOP, 17, 0, 0, 0, 0, 0 );
	
	
	if((outputFile = fopen ("./Symboltable.out","w")) != 0)
		writeSymboltable(theSymboltable, outputFile);
	fclose(outputFile);
	
	return 1;
}
*/

