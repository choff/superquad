#ifndef Q_IDENTIFIER_H
#define Q_IDENTIFIER_H
#include <stdlib.h>

#define IDENTIFIER_NAME_SIZE 20

enum q_identifier_type {
    TYPE_INTEGER = 0,
    TYPE_FLOAT
};

struct q_identifier {
    enum q_identifier_type type;
    char name [IDENTIFIER_NAME_SIZE];
};

struct q_identifier *q_identifier_create(enum q_identifier_type type, char *name);
struct q_identifier *q_temp_identifier_create(enum q_identifier_type type);
#endif

