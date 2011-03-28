all: clean	global.exe 

################################################################

#global.exe: global.o quadComp_y.o lex.yy.o
#	gcc -g -o global.exe global.o quadComp_y.o lex.yy.o -lm -lfl

global.exe: global.o
	gcc -g -o global.exe global.o

#lex.yy.o : lex.yy.c
#	gcc -g -Wall -std=c99 -c lex.yy.c

global.o: global.c global.h
	gcc	-g -Wall -std=c99 -c global.c

#quadComp_y.o : quadComp.tab.c quadComp.tab.h global.h
#	gcc -g -c quadComp.tab.c -o quadComp_y.o

#quadComp.tab.c quadComp.tab.h : quadComp.y
#	bison -v -d quadComp.y

#lex.yy.c : quadComp.l
#	flex  quadComp.l 

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
	