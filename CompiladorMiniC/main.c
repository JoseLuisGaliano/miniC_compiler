#include <stdio.h>
#include <stdlib.h>

extern int yyparse();
extern char *yytext;
extern int  yyleng;
extern FILE *yyin;
extern int yylex();
FILE *fich;

extern int numErroresLexicos;
extern int numErroresSintacticos;
extern int numErroresSemanticos;

int main()
{
    int i;
    char nombre[80];
    scanf("%s",nombre);
	printf("\n");
    if ((fich=fopen(nombre,"r"))==NULL) {
        printf("***ERROR, no puedo abrir el fichero\n");
        exit(1);		}
    yyin=fich;
    yyparse(); // Lanzamos el analizador léxico
    fclose(fich);
    
	if(numErroresLexicos + numErroresSintacticos + numErroresSemanticos != 0){
		fprintf( stderr, "Se han encontrado errores durante la compilación:\n");
		fprintf( stderr, "Errores léxicos: %d\n", numErroresLexicos);
		fprintf( stderr, "Errores sintácticos: %d\n", numErroresSintacticos);
		fprintf( stderr, "Errores semánticos: %d\n", numErroresSemanticos);
	} 
    
    return 0;
}
