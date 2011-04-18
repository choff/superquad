#include "q_operations.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char q_arithmetic_operator_to_string(enum q_arithmetic_operator);
int q_op_assignment_gen_code(struct q_op *op, char *code_buf);

char *q_relative_operator_to_string(enum q_relative_operator rel_op);
int q_jump_condition_to_string(struct q_jump_condition *cond, char *code_buf);
int q_op_jump_gen_code(struct q_op *op, char *code_buf);

/* Allocates space for an element to be placed in the quadrupelcode operation list.
 * q_op_size is the size of the quadrupelcode instruction to be placed in the linked list.
 */
struct q_op_list *q_op_list_create(struct q_op_list *op_list, size_t q_op_size) {
	struct q_op_list *result = malloc(sizeof(struct q_op_list) - sizeof(struct q_op) + q_op_size);
	
	result->next = NULL;
	if (op_list)
		op_list->next = result;
	
	return result;
}


void q_op_assignment_init(struct q_op_assignment *assignment, char *dest,
						  char *left_operand, enum q_arithmetic_operator arith_operator, char *right_operand) {
	assignment->op.gen_code = q_op_assignment_gen_code;

	strcpy(assignment->left_operand, left_operand);
	strcpy(assignment->right_operand, right_operand);
	assignment->arith_operator = arith_operator;
}

char q_arithmetic_operator_to_string(enum q_arithmetic_operator operator) {
	switch(operator) {
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
	struct q_op_assignment *assignment = (struct q_op_assignment *) op;

	if (assignment->arith_operator == Q_ARITHMETIC_OP_NONE)
		return sprintf(code_buf, "%s := %s", assignment->dest, assignment->left_operand);
	else
		return sprintf(code_buf, "%s := %s %c %s", assignment->dest, assignment->left_operand,
					   q_arithmetic_operator_to_string(assignment->arith_operator), assignment->right_operand);
}


struct q_jump_condition *q_jump_condition_create(char *left_operand, enum q_relative_operator rel_operator, 
												 char *right_operand) {
	struct q_jump_condition *cond = malloc(sizeof(struct q_jump_condition));
	
	strcpy(cond->left_operand, left_operand);
	strcpy(cond->right_operand, right_operand);
	cond->rel_operator = rel_operator;
	
	return cond;
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
	return sprintf(code_buf, "IF (%s %s %s)", cond->left_operand, q_relative_operator_to_string(cond->rel_operator),
				   cond->right_operand);
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