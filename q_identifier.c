#include "q_identifier.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

/* Creates a new identifier and adds it to the symbol table */
struct q_identifier *q_identifier_create(enum q_identifier_type type, char *name) {
    struct q_identifier *identifier = malloc(sizeof(struct q_identifier));
    identifier->type = type;
    strcpy(identifier->name, name);
    
    return NULL;
}

/* Creates a new helper variable and adds it to the symbol table */
struct q_identifier *q_temp_identifier_create(enum q_identifier_type type) {
    return NULL;
}

