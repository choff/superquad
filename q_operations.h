#ifndef Q_OPERATIONS_H
#define Q_OPERATIONS_H
#include "global.h"
#include <stdlib.h>


struct q_op {
	/* Generates code for this quadrupelcode statement. Returns the number of characters 
	 * printed in the buffer */
	int (*gen_code) (struct q_op *op, char *code_buf);
};

enum q_arithmetic_operator {
	Q_ARITHMETIC_OP_NONE = 0,
	Q_ARITHMETIC_OP_ADD,
	Q_ARITHMETIC_OP_SUB,
	Q_ARITHMETIC_OP_MUL,
	Q_ARITHMETIC_OP_MOD,
	Q_ARITHMETIC_OP_DIV
};

struct q_op_assignment {
	struct q_op op;
	
	symtabEntry *dest;
	
	struct q_operator *left_operand;
	enum q_arithmetic_operator arith_operator;
	struct q_operator *right_operand;
};

enum q_relative_operator {
	Q_RELATIVE_OP_LOWER = 0,
	Q_RELATIVE_OP_LOWER_EQUAL,
	Q_RELATIVE_OP_EQUAL,
	Q_RELATIVE_OP_GREATER_EQUAL,
	Q_RELATIVE_OP_GREATER
};

struct q_jump_condition {
	struct q_operator *left_operand;
	enum q_relative_operator rel_operator;
	struct q_operator *right_operand;
};

struct q_op_jump {
	struct q_op op; /* Pointer to parent "class" */
	
	struct q_jump_condition *condition; /* Jump condition, NULL for unconditional jump */
	int target; /* Index of target instruction */
};

struct q_op_list {
	struct q_op_list *next;

	struct q_op op;
};

enum q_operator_type {
	OPD_TYPE_LITERAL,
	OPD_TYPE_VARIABLE
};



struct q_operator {
	enum q_operator_type type;
	
	union {
		symtabEntry *symtabEntry;
		
		struct {
			const struct variable_type *type;
			union {
				int int_value;
				float float_value;
			} value;
		} literal;
	} data;
};

struct q_op *q_op_list_add(size_t q_op_size);
struct q_op_list *q_op_list_create(struct q_op_list *op_list, size_t q_op_size);

void q_op_assignment_init(struct q_op_assignment *assignment, symtabEntry *dest, struct q_operator *left_operand, 
                          enum q_arithmetic_operator arith_operator, struct q_operator *right_operand);

const struct variable_type *q_op_assignment_get_result_type(struct q_operator *left_operand, 
															struct q_operator *right_operand);

void q_op_jump_init(struct q_op_jump *jump, struct q_jump_condition *cond, int target);

struct q_jump_condition *q_jump_condition_create(struct q_operator *left_operand, enum q_relative_operator rel_operator, 
												 struct q_operator *right_operand);

#endif
