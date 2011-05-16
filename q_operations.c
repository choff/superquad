#include "q_operations.h"
#include "global.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

const struct q_operand literal_zero = {
	OPD_TYPE_LITERAL,
	{
		.literal = {
			&type_integer,
			{ .int_value = 0 }
		}
	}
};

const struct q_operand literal_one = {
	OPD_TYPE_LITERAL,
	{
		.literal = {
			&type_integer,
			{ .int_value = 1 }
		}
	}
};

char q_arithmetic_operator_to_string(enum q_arithmetic_operator);
int q_op_assignment_gen_code(struct q_op *op, char *code_buf);

int q_operand_to_string(struct q_operand operator, char *string);

char *q_relative_operator_to_string(enum q_relative_operator rel_op);
int q_jump_condition_to_string(struct q_jump_condition *cond, char *code_buf);
int q_op_jump_gen_code(struct q_op *op, char *code_buf);

struct q_op_list *first_instruction = NULL;
struct q_op_list *last_instruction = NULL;
int instruction_count = 0;

/* Adds an instruction of type "type" to the instruction list.
 * Depending on the type of instruction, additional parameters have to be provided in the
 * varargs section */
struct q_op *q_instr_add(enum q_instruction_type type, ...) {
	struct q_op *op;
	char code_buf[100];

	va_list arg_list;
	va_start(arg_list, type);
	
	switch(type) {
		case Q_INSTR_TYPE_ASSIGN:
			op = q_op_list_add(sizeof(struct q_op_assignment));
			
			op->gen_code = q_op_assignment_gen_code;
			
			((struct q_op_assignment *) op)->dest = va_arg(arg_list, symtabEntry *);
			((struct q_op_assignment *) op)->left_operand = va_arg(arg_list, struct q_operand);
			((struct q_op_assignment *) op)->arith_operator = Q_ARITHMETIC_OP_NONE;

			break;
		case Q_INSTR_TYPE_CALC:
			op = q_op_list_add(sizeof(struct q_op_assignment));
			
			op->gen_code = q_op_assignment_gen_code;

			((struct q_op_assignment *) op)->dest = va_arg(arg_list, symtabEntry *);
			((struct q_op_assignment *) op)->left_operand = va_arg(arg_list, struct q_operand);
			((struct q_op_assignment *) op)->arith_operator = va_arg(arg_list, enum q_arithmetic_operator);
			((struct q_op_assignment *) op)->right_operand = va_arg(arg_list, struct q_operand);

			break;
		case Q_INSTR_TYPE_JUMP:
			op = q_op_list_add(sizeof(struct q_op_jump));
			
			op->gen_code = q_op_jump_gen_code;
	
			((struct q_op_jump *) op)->condition = NULL;
			((struct q_op_jump *) op)->target = va_arg(arg_list, int);
			
			break;
		case Q_INSTR_TYPE_COND_JUMP:
			op = q_op_list_add(sizeof(struct q_op_jump));
			
			op->gen_code = q_op_jump_gen_code;
	
			((struct q_op_jump *) op)->condition = va_arg(arg_list, struct q_jump_condition *);
			((struct q_op_jump *) op)->target = va_arg(arg_list, int);
			
			break;
		default: /* Unsupported instruction type */
			break;
	}
	
	va_end(arg_list);
	
	return op;
}

void q_instr_add_rel(symtabEntry *result, struct q_operand opd1, enum q_relative_operator relop, struct q_operand opd2) {
	q_instr_add(Q_INSTR_TYPE_COND_JUMP, q_jump_condition_create(opd1, relop, opd2), q_op_list_get_instr_count() + 3);
	q_instr_add(Q_INSTR_TYPE_ASSIGN, result, Q_FALSE);
	q_instr_add(Q_INSTR_TYPE_JUMP, q_op_list_get_instr_count() + 2);
	q_instr_add(Q_INSTR_TYPE_ASSIGN, result, Q_TRUE);
}

/*
 * Appends a new quadrupel code instruction to the end of the instruction list.
 * q_op_size: sizeof(...), where ... is the type of the instruction to be added
 */
struct q_op *q_op_list_add(size_t q_op_size) {
	last_instruction = q_op_list_create(last_instruction, q_op_size);
	instruction_count++;
	
	if (!first_instruction)
		first_instruction = last_instruction;
	
	return &(last_instruction->op);
}

int q_op_list_get_instr_count() {
	return instruction_count;
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

const struct variable_type *q_op_assignment_get_result_type(struct q_operand left_operand, 
															struct q_operand right_operand) {
	if (q_operand_get_type(left_operand) == &type_real || q_operand_get_type(right_operand) == &type_real)
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
	cnt += q_operand_to_string(ass_op->left_operand, &code_buf[cnt]);

	if (ass_op->arith_operator != Q_ARITHMETIC_OP_NONE) {
		code_buf[cnt++] = ' ';
		code_buf[cnt++] = q_arithmetic_operator_to_string(ass_op->arith_operator);
		code_buf[cnt++] = ' ';
		cnt += q_operand_to_string(ass_op->right_operand, &code_buf[cnt]);
	}

	return cnt;
}


struct q_jump_condition *q_jump_condition_create(struct q_operand left_operand, enum q_relative_operator rel_operator, 
												 struct q_operand right_operand) {
	struct q_jump_condition *cond = malloc(sizeof(struct q_jump_condition));
	
	cond->left_operand = left_operand;
	cond->right_operand = right_operand;
	cond->rel_operator = rel_operator;
	
	return cond;
}

struct q_operand q_operand_init_variable(symtabEntry *varEntry) {
	struct q_operand operand;
	operand.type = OPD_TYPE_VARIABLE;
	operand.data.varEntry = varEntry;
	
	return operand;
}

const struct variable_type *q_operand_get_type(struct q_operand operator) {
	switch(operator.type) {
		case OPD_TYPE_LITERAL:
			return operator.data.literal.type;
		case OPD_TYPE_VARIABLE:
			if (operator.data.varEntry->type == type_real.symtabType)
				return &type_real;
			else
				return &type_integer;
		default:
			return NULL;
	}
}

int q_operand_to_string(struct q_operand operator, char *string) {
	switch(operator.type) {
		case OPD_TYPE_LITERAL:
			if (operator.data.literal.type == &type_real)
				return sprintf(string, "%f", operator.data.literal.value.float_value);
			else if (operator.data.literal.type == &type_integer)
				return sprintf(string, "%d", operator.data.literal.value.int_value);
			else /* unknown type */
				return 0;
			
		case OPD_TYPE_VARIABLE:
			return sprintf(string, "%s", operator.data.varEntry->name);
		default:
			return 0;
	}
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
		case Q_RELATIVE_OP_NOT_EQUAL:
			return "<>";
		default:
			return NULL;
	}
}

int q_jump_condition_to_string(struct q_jump_condition *cond, char *code_buf) {
	int cnt = sprintf(code_buf, "IF (");
	cnt += q_operand_to_string(cond->left_operand, &code_buf[cnt]);
	cnt += sprintf(&code_buf[cnt], " %s ", q_relative_operator_to_string(cond->rel_operator));
	cnt += q_operand_to_string(cond->right_operand, &code_buf[cnt]);
	code_buf[cnt++] = ')';
	code_buf[cnt] = 0;
	
	return cnt;
}

int q_op_jump_gen_code(struct q_op *op, char *code_buf) {
	struct q_op_jump *jmp_op = (struct q_op_jump *) op;
	char *pos = code_buf;

	if(jmp_op->condition) {
		pos += q_jump_condition_to_string(jmp_op->condition, code_buf);
		*(pos++) = ' ';
	}
	
	pos += sprintf(pos, "GOTO %d", jmp_op->target);
	return (code_buf - pos);
}

void q_op_gen_code(FILE *output_file) {
	char code_buf [200];
	int instr_idx = 0;
	
	for (struct q_op_list *instr = first_instruction; instr != NULL; instr = instr->next) {
		instr->op.gen_code(&instr->op, code_buf);
		fprintf(output_file, "%d: %s\n", instr_idx++, code_buf);
	}
}
