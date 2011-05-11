all: clean	global.exe 

################################################################

gccOptions = -g -Wfatal-errors -O0

global.exe: global.o quadComp_y.o lex.yy.o q_operations.o q_identifier.o
	gcc -g -o global.exe global.o quadComp_y.o q_operations.o q_identifier.o lex.yy.o -lm -lfl

# -D_POSIX_SOURCE fixes a warning about allegedly implicit declaration of function 'fileno', see http://compilers.iecc.com/comparch/article/04-01-065
lex.yy.o : lex.yy.c
	gcc $(gccOptions) -D_POSIX_SOURCE -std=c99 -c lex.yy.c

global.o: global.c global.h
	gcc $(gccOptions) -std=c99 -c global.c

quadComp_y.o : quadComp.tab.c quadComp.tab.h global.h
	gcc $(gccOptions) -c quadComp.tab.c -o quadComp_y.o

q_operations.o :
	gcc -g -c q_operations.c -o q_operations.o

q_identifier.o:
	gcc -g -c q_identifier.c -o q_identifier.o

quadComp.tab.c quadComp.tab.h : quadComp.y
	bison -v -d quadComp.y

lex.yy.c : quadComp.l
	flex  quadComp.l 

###############################################################


clean : 
	rm -f global.o
	rm -f lex.yy.o
	rm -f lex.yy.c
	rm -f quadComp.output
	rm -f quadComp.tab.c
	rm -f quadComp.tab.h
	rm -f quadComp_y.o
	rm -f global.exe
	rm -f Symboltable.out
	rm -f Quadrupelcode.out
	rm -f q_operations.o
	rm -f q_identifier.o
