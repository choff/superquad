#include "q_operations.h"
#include "global.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

char q_arithmetic_operator_to_string(enum q_arithmetic_operator);
int q_op_assignment_gen_code(struct q_op *op, char *code_buf);

const struct variable_type *q_operator_get_type(struct q_operator *operator);
int q_operator_to_string(struct q_operator *operator, char *string);

char *q_relative_operator_to_string(enum q_relative_operator rel_op);
int q_jump_condition_to_string(struct q_jump_condition *cond, char *code_buf);
int q_op_jump_gen_code(struct q_op *op, char *code_buf);

struct q_op_list *first_instruction = NULL;
struct q_op_list *last_instruction = NULL;

/*
 * Appends a new quadrupel code instruction to the end of the instruction list.
 * q_op_size: sizeof(...), where ... is the type of the instruction to be added
 */
struct q_op *q_op_list_add(size_t q_op_size) {
	last_instruction = q_op_list_create(last_instruction, q_op_size);
	
	if (!first_instruction)
		first_instruction = last_instruction;
	
	return &(last_instruction->op);
}

/* 
 * Allocates space for a new element to be placed in the quadrupelcode operation list.
 * q_op_size is the size of the quadrupelcode instruction to be placed in the linked list.
 */
struct q_op_list *q_op_list_create(struct q_op_list *op_list, size_t q_op_size) {
	struct q_op_list *result = malloc(sizeof(struct q_op_list) - sizeof(struct q_op) + q_op_size);
	
	result->next = NULL;
	if (op_list)
		op_list->next = result;
	
	return result;
}

void q_op_assignment_init(struct q_op_assignment *assignment, symtabEntry *dest, struct q_operator *left_operand, 
                          enum q_arithmetic_operator arith_operator, struct q_operator *right_operand) {
	assignment->op.gen_code = q_op_assignment_gen_code;

	assignment->dest = dest;
	assignment->left_operand = left_operand;
	assignment->right_operand = right_operand;
	assignment->arith_operator = arith_operator;
}

const struct variable_type *q_op_assignment_get_result_type(struct q_operator *left_operand, 
															struct q_operator *right_operand) {
	if (q_operator_get_type(left_operand) == &type_real || q_operator_get_type(right_operand) == &type_real)
		return &type_real;
	else
		return &type_integer;
}

char q_arithmetic_operator_to_string(enum q_arithmetic_operator operator) {
	switch (operator) {
		case Q_ARITHMETIC_OP_ADD:
			return '+';
		case Q_ARITHMETIC_OP_SUB:
			return '-';
		case Q_ARITHMETIC_OP_MUL:
			return '*';
		case Q_ARITHMETIC_OP_MOD:
			return '%';
		case Q_ARITHMETIC_OP_DIV:
			return '/';
		default:
			return 0;
	}
}

int q_op_assignment_gen_code(struct q_op *op, char *code_buf) {
	struct q_op_assignment *ass_op = (struct q_op_assignment *) op;

	int cnt = sprintf(code_buf, "%s := ", ass_op->dest->name);
	cnt += q_operator_to_string(ass_op->left_operand, &code_buf[cnt]);

	if (ass_op->arith_operator != Q_ARITHMETIC_OP_NONE) {
		code_buf[cnt++] = ' ';
		code_buf[cnt++] = q_arithmetic_operator_to_string(ass_op->arith_operator);
		cnt += q_operator_to_string(ass_op->right_operand, &code_buf[cnt]);
	}

	return cnt;
}


struct q_jump_condition *q_jump_condition_create(struct q_operator *left_operand, enum q_relative_operator rel_operator, 
												 struct q_operator *right_operand) {
	struct q_jump_condition *cond = malloc(sizeof(struct q_jump_condition));
	
	cond->left_operand = left_operand;
	cond->right_operand = right_operand;
	cond->rel_operator = rel_operator;
	
	return cond;
}

const struct variable_type *q_operator_get_type(struct q_operator *operator) {
	switch(operator->type) {
		case OPD_TYPE_LITERAL:
			return operator->data.literal.type;
		case OPD_TYPE_VARIABLE:
			if (operator->data.symtabEntry->type == type_real.symtabType)
				return &type_real;
			else
				return &type_integer;
		default:
			return NULL;
	}
}

int q_operator_to_string(struct q_operator *operator, char *string) {
	switch(operator->type) {
		case OPD_TYPE_LITERAL:
			if (operator->data.symtabEntry->type == type_real.symtabType)
				return sprintf(string, "%f", operator->data.literal.value.float_value);
			else if (operator->data.symtabEntry->type == type_integer.symtabType)
				return sprintf(string, "%d", operator->data.literal.value.int_value);
			else /* unknown type */
				return 0;
			
		case OPD_TYPE_VARIABLE:
			return sprintf(string, "%s", operator->data.symtabEntry->name);
		default:
			return 0;
	}
}

void q_op_jump_init(struct q_op_jump *jump, struct q_jump_condition *cond, int target) {
	jump->op.gen_code = q_op_jump_gen_code;
	
	jump->condition = cond;
	jump->target = target;
}

char *q_relative_operator_to_string(enum q_relative_operator rel_op) {
	switch(rel_op) {
		case Q_RELATIVE_OP_LOWER:
			return "<";
		case Q_RELATIVE_OP_LOWER_EQUAL:
			return "<=";
		case Q_RELATIVE_OP_EQUAL:
			return "=";
		case Q_RELATIVE_OP_GREATER_EQUAL:
			return ">=";
		case Q_RELATIVE_OP_GREATER:
			return ">";
		default:
			return NULL;
	}
}

int q_jump_condition_to_string(struct q_jump_condition *cond, char *code_buf) {
	int cnt = sprintf(code_buf, "IF (");
	cnt += q_operator_to_string(cond->left_operand, &code_buf[cnt]);
	cnt += sprintf(&code_buf[cnt], " %s ", q_relative_operator_to_string(cond->rel_operator));
	cnt += q_operator_to_string(cond->right_operand, &code_buf[cnt]);
	code_buf[cnt++] = ')';
	
	return cnt;
}

int q_op_jump_gen_code(struct q_op *op, char *code_buf) {
	struct q_op_jump *jmp_op = (struct q_op_jump *) op;
	char *pos = code_buf;

	if(jmp_op->condition) {
		pos += q_jump_condition_to_string(jmp_op->condition, code_buf);
		*(pos++) = ' ';
	}
	
	pos += sprintf(code_buf, "GOTO %d", jmp_op->target);
	return (code_buf - pos);
}
