%{
#include "sintactico.tab.h"
int numErroresLexicos = 0;
int inicioComentario;
%}

digito								[0-9]
entero								{digito}+
letra								[a-zA-Z]
cadena								\"([^\"\n]|\\+\")*\"
panico								[^ \r\n\t/a-zA-Z_0-9(){};,=+"*-]+

%x COMMULTI
%option yylineno

%%

[ \r\n\t]+							;
"//"(.*)[\n]						;
"/*"								{ yymore(); 
									  inicioComentario = yylineno; 
									  BEGIN(COMMULTI);
									}
<COMMULTI>([^*]|[*]+[^*/])* 		;
<COMMULTI>[*]+"/"					{ BEGIN(INITIAL); }
<COMMULTI><<EOF>>					{ numErroresLexicos++; 
									  fprintf(stderr, "Error léxico en la línea %d: comentario multilínea sin cerrar\n", inicioComentario);
									  return 0;
									}
void								return VOID;
var									return VAR;	
const								return CONST;	
if									return IF;
else 								return ELSE;
while								return WHILE;
print								return PRINT;
read								return READ;
({letra}|_)({letra}|{digito}|_)*	{ if(yyleng > 16) {
										numErroresLexicos++;
										fprintf(stderr, "Error léxico en la línea %d: identificador demasiado largo (\"%s\", longitud %d)\n", yylineno, yytext, yyleng);
									  }
									  yylval.str = strdup(yytext);
									  return ID;
									}
{entero}							{ long integer = atol(yytext);
									  if(integer > 2147483648){
									  	numErroresLexicos++;
									  	fprintf(stderr, "Error léxico en la línea %d: entero demasiado grande \"%s\"\n", yylineno, yytext);
									  }
									  yylval.str = strdup(yytext);
									  return INTLITERAL;
									}
{cadena}							{ yylval.str = strdup(yytext);
									  return STRING;
									}
"("									return LPAREN;
")"									return RPAREN;
";"									return SEMICOLON;
","									return COMMA;
"="									return ASSIGNOP;
"+"									return PLUSOP;
"-"									return MINUSOP;
"*"									return MULTOP;
"/"									return DIVOP;
"{"									return BKL;
"}"									return BKR;
{panico}							{ numErroresLexicos++;
									  fprintf(stderr, "Error léxico en línea %d: caracteres no válidos \"%s\"\n", yylineno, yytext);
									}
