compilador : sintactico.tab.c lex.yy.c main.c listaSimbolos.c listaCodigo.c
	gcc sintactico.tab.c lex.yy.c main.c listaSimbolos.c listaCodigo.c -lfl -o compilador

lex.yy.c : lexico.l sintactico.tab.h
	flex lexico.l

sintactico.tab.h sintactico.tab.c : sintactico.y listaSimbolos.h listaCodigo.h
	bison -d -v sintactico.y

clear : 
	rm -f sintactico.output sintactico.tab.* lex.yy.c compilador
