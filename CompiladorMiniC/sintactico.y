%{
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include <stdlib.h>
#include "listaSimbolos.h"
#include "listaCodigo.h"

// opciones y funciones auxiliares
extern int yylex();
extern int yylineno;
extern char * yytext;
void yyerror(const char * s);
char * unirCadenas(char * a, char * b);  

// errores
int numErroresSintacticos = 0; 
int numErroresSemanticos = 0; 

// variables y funciones para el manejo de la tabla de simbolos
Lista ListaSimbolos;
int contadorCadenas = 0;
Tipo TipoLS;
void establecerTipoLS(Tipo t);
void imprimeLS();
int contieneLS(char * simbolo);
int comprobarConstanteLS(char * simbolo);
int insertaEntradaLS(char * simbolo, Tipo tipo);

// variables y funciones para el manejo de la lista de codigo
ListaC salida;
int RegTemp[10] = { 0 };
int contadorEtiquetas = 1;
char * obtenRegTempLibre();
void liberaRegTemp(char * temp);
char * obtenEtiqueta();
void imprimeLC();

// funciones auxiliares para la creacion de operaciones
Operacion nuevaOpGeneral(char * op, char * res, char * arg1, char * arg2);
Operacion nuevaOpTipo1(char * op);
Operacion nuevaOpTipo2(char * op, char * res);
Operacion nuevaOpTipo3(char * op, char * res, char * arg1);
Operacion nuevaOpTipo4(char * op, char * res, char * arg1, char * arg2);

%}

%union {
    char * str; // yylval.str (a. lexico)
    ListaC codigo;
}

%code requires {
    #include "listaCodigo.h"
}

// no terminales
%type <codigo> declarations identifier_list asig expression statement statement_list print_list print_item read_list

// tokens
%token VOID							  "void"
%token VAR							  "var"
%token CONST						  "const"
%token IF							  "if"
%token ELSE							  "else"
%token WHILE						  "while"
%token PRINT						  "print"
%token READ							  "read"
%token <str> ID						  "id"
%token <str> INTLITERAL				  "int"
%token <str> STRING				      "string"
%token LPAREN						  "("
%token RPAREN						  ")"
%token SEMICOLON				      ";"
%token COMMA						  ","
%token ASSIGNOP					      "="
%token PLUSOP						  "+"
%token MINUSOP						  "-"
%token MULTOP					      "*"
%token DIVOP						  "/"
%token BKL							  "{"
%token BKR							  "}"

// conflictos
%left PLUSOP MINUSOP
%left MULTOP DIVOP
%left UMINUS
%expect 1

%%

program                             :   { 	ListaSimbolos = creaLS(); }
										"void" "id" "(" ")" "{" declarations statement_list "}"
                                        {	salida = creaLC();
                                            concatenaLC(salida, $7);
                                            liberaLC($7);
                                            concatenaLC(salida, $8);
                                            liberaLC($8);
                                            
                                            imprimeLS();
                                            liberaLS(ListaSimbolos);
                                            
                                            imprimeLC();
                                            liberaLC(salida);
                                        }
                                    ;


declarations                        : 	declarations "var" 
										{ 	establecerTipoLS(VARIABLE); }
										identifier_list ";"
                                        {	$$ = creaLC();
                                            concatenaLC($$, $1);
                                            liberaLC($1);
                                            concatenaLC($$, $4);
                                            liberaLC($4);
                                        }
                                        
                                    | 	declarations "const" 
                                    	{ 	establecerTipoLS(CONSTANTE); }
                                    	identifier_list ";"
                                        {	$$ = creaLC();
                                            concatenaLC($$, $1);
                                            liberaLC($1);
                                            concatenaLC($$, $4);
                                            liberaLC($4);
                                        }
                                        
                                    |   // lambda
                                        {	$$ = creaLC();
                                            creaLS();
                                        }
                                        
                                    // RECUPERACIÓN DE ERRORES EN LAS DECLARACIONES
                                    | 	declarations "var" error ";"
                                        { 	$$ = creaLC(); }
                                        
                                    | 	declarations "const" error ";"
                                        { 	$$ = creaLC(); }
                                    ;


identifier_list                     : asig
                                      { 	$$ = $1; }
                                      
                                    | identifier_list "," asig
                                      {		$$ = creaLC();
                                         	concatenaLC($$, $1);
                                            concatenaLC($$, $3);
                                      }
                                    ;


asig                                : "id"
                                       { 	if (!contieneLS($1)) insertaEntradaLS($1, TipoLS);
                                            else {
                                                numErroresSemanticos++;
                                                fprintf(stderr, "Error semántico (linea %d): \"%s\" ya está declarada\n", yylineno, $1);
                                            }
                                            $$ = creaLC();
                                       }
                                       
                                    | "id" "=" expression
                                        {	if (!contieneLS($1)) insertaEntradaLS($1, TipoLS);
                                            else {
                                                numErroresSemanticos++;
                                                fprintf(stderr, "Error semántico (linea %d): \"%s\" ya está declarada\n", yylineno, $1);
                                            }
                                            $$ = creaLC();
                                           	concatenaLC($$, $3);
                                            // sw $t0, _x
                                            Operacion o = nuevaOpTipo3("sw", recuperaResLC($3), unirCadenas("_", $1));
                                          	insertaLC($$, finalLC($$), o);
                                            liberaRegTemp(o.res);
                                           	liberaLC($3);
                                        }
                                    ;


statement_list                      : 	statement_list statement
                                        {	$$ = $1;
                                            concatenaLC($$, $2);
                                            liberaLC($2);
                                        }
                                        
                                    |	// lambda
                                        {	$$ = creaLC(); }
                                    ;


statement                           : 	"id" "=" expression ";"
                                        {	if (!contieneLS($1)) {
                                                numErroresSemanticos++;
                                                fprintf(stderr, "Error semántico (linea %d): \"%s\" no está declarada\n", yylineno, $1);
                                            } else {
                                                if (comprobarConstanteLS($1)) {
                                                    numErroresSemanticos++;
                                                    fprintf(stderr, "Error semántico (linea %d): \"%s\" es una constante\n", yylineno, $1);
                                                }
                                            }
											$$ = $3;
                                            // sw $t0, _x
                                            Operacion o = nuevaOpTipo3("sw", recuperaResLC($3), unirCadenas("_", $1));
                                            insertaLC($$, finalLC($$), o);
                                            liberaRegTemp(o.res);
                                        }
                                        
                                    | 	"{" statement_list "}"
                                        {	$$ = $2; }
                                        
                                    | 	"if" "(" expression ")" statement "else" statement
                                        {	$$ = $3;
                                            // beqz $ti, $endIfLabel 
                                            char * endIfLabel = obtenEtiqueta();
                                            char * beqzTempReg = recuperaResLC($3);
                                            Operacion o = nuevaOpTipo3("beqz", beqzTempReg, endIfLabel);
                                            liberaRegTemp(beqzTempReg);
                                            insertaLC($$, finalLC($$), o);
                                            
                                            // SI ($ti != 0)
                                            concatenaLC($$, $5);
                                            
                                            // b $endIfLabel
                                            char * endElseLabel = obtenEtiqueta();
                                            o = nuevaOpTipo2("b", endElseLabel);
                                            insertaLC($$, finalLC($$), o);
                                            
                                            // SI ($ti == 0)
                                            o = nuevaOpTipo2("etiq", endIfLabel);
                                            insertaLC($$, finalLC($$), o);
                                            concatenaLC($$, $7);
                                            
                                            // $endElseLabel
                                            o = nuevaOpTipo2("etiq", endElseLabel);
                                            insertaLC($$, finalLC($$), o);

                                            liberaLC($5);
                                            liberaLC($7);
                                        }
                                        
                                    | 	"if" "(" expression ")" statement
                                        {	$$ = $3;
                                            // beqz $ti, $endIfLabel
                                            char * endIfLabel = obtenEtiqueta();
                                            char * beqzTempReg = recuperaResLC($3);
                                            Operacion o = nuevaOpTipo3("beqz", beqzTempReg, endIfLabel);
                                            liberaRegTemp(beqzTempReg);
                                            insertaLC($$, finalLC($$), o);

                                            // SI ($ti != 0)
                                            concatenaLC($$, $5);

                                            // SI ($ti == 0)
                                            o = nuevaOpTipo2("etiq", endIfLabel);
                                            insertaLC($$, finalLC($$), o);

                                            liberaLC($5);
                                        }
                                        
                                    | 	"while" "(" expression ")" statement
                                        {	$$ = creaLC();
                                            // $beginWhileLabel
                                            char * beginWhileLabel = obtenEtiqueta();
                                            Operacion o = nuevaOpTipo2("etiq", beginWhileLabel);
                                            insertaLC($$, finalLC($$), o);
                                            concatenaLC($$, $3);

                                            // beqz $ti, $endWhileLabel
                                            char * endWhileLabel = obtenEtiqueta();
                                            char * beqzTempReg = recuperaResLC($3);
                                            o = nuevaOpTipo3("beqz", beqzTempReg, endWhileLabel);
                                            liberaRegTemp(beqzTempReg);
                                            insertaLC($$, finalLC($$), o);

                                            // SI ($ti != 0) (bucle)
                                            concatenaLC($$, $5);

                                            // b $beginWhileLabel
                                            o = nuevaOpTipo2("b", beginWhileLabel);
                                            insertaLC($$, finalLC($$), o);

                                            // $endWhileLabel
                                            o = nuevaOpTipo2("etiq", endWhileLabel);
                                            insertaLC($$, finalLC($$), o);

                                            liberaLC($3);
                                            liberaLC($5);
                                        }
                                        
                                    | 	"print" print_list ";"
                                        { $$ = $2; }
                                        
                                    | 	"read" read_list ";"
                                        { $$ = $2; }
                                    
                                    // RECUPERACIÓN DE ERRORES EN SENTENCIAS    
                                    | 	error ";"
                                        {	$$ = creaLC(); }
                                    ;


print_list                          : 	print_item
                                        { $$ = $1; }
                                        
                                    | 	print_list "," print_item
                                        {	$$ = creaLC();
                                            concatenaLC($$, $1);
                                            liberaLC($1);
                                            concatenaLC($$, $3);
                                            liberaLC($3);
                                        }
                                    ;


print_item                          : 	expression
                                        {	$$ = $1;
                                            // move $a0, $t0 
                                            char * temp = recuperaResLC($1);
                                            Operacion o = nuevaOpTipo3("move", "$a0", temp);
                                            insertaLC($$, finalLC($$), o);
                                            liberaRegTemp(temp);

                                            // li $v0, 4 
                                            o = nuevaOpTipo3("li", "$v0", "1");
                                            insertaLC($$, finalLC($$), o);

                                            // syscall
                                            o = nuevaOpTipo1("syscall");
                                            insertaLC($$, finalLC($$), o);
                                        }
                                        
                                    | 	"string"
                                        {	int id = insertaEntradaLS($1, CADENA);
                                            $$ = creaLC();
                                            // la $a0, $str1 
                                            char * aux = (char *) malloc(4 + 4 + 1); // "$str" + "9999" + 0
                                            sprintf(aux, "$str%d", id);
                                            Operacion o = nuevaOpTipo3("la", "$a0", aux);
                                            insertaLC($$, finalLC($$), o);

                                            // li $v0, 4 
                                            o = nuevaOpTipo3("li", "$v0", "4");
                                            insertaLC($$, finalLC($$), o);

                                            // syscall
                                            o = nuevaOpTipo1("syscall");
                                            insertaLC($$, finalLC($$), o);
                                        }
                                    ;


read_list                           : "id"
                                        {	if (!contieneLS($1)) {
                                                numErroresSemanticos++;
                                                fprintf(stderr, "Error semántico (linea %d): \"%s\" no está declarada\n", yylineno, $1);
                                            } else {
                                                if (comprobarConstanteLS($1)) {
                                                    numErroresSemanticos++;
                                                    fprintf(stderr, "Error semántico (linea %d): \"%s\" es una constante\n", yylineno, $1);
                                                }
                                            }
                                            $$ = creaLC();
                                            // li $v0, 5
                                            Operacion o = nuevaOpTipo3("li", "$v0", "5");
                                            insertaLC($$, finalLC($$), o);

                                            // syscall
                                            o = nuevaOpTipo1("syscall");
                                            insertaLC($$, finalLC($$), o);

                                            // sw $v0, _x
                                            o = nuevaOpTipo3("sw", "$v0", unirCadenas("_", $1));
                                            insertaLC($$, finalLC($$), o);
                                        }
                                        
                                    | 	read_list "," "id"
                                        {	if (!contieneLS($3)) {
                                                numErroresSemanticos++;
                                                fprintf(stderr, "Error semántico (linea %d): \"%s\" no está declarada\n", yylineno, $3);
                                            } else {
                                                if (comprobarConstanteLS($3)) {
                                                    numErroresSemanticos++;
                                                    fprintf(stderr, "Error semántico (linea %d): \"%s\" es una constante\n", yylineno, $3);
                                                }
                                            }
                                            $$ = $1;
                                        }
                                    ;


expression                          : 	expression "+" expression
                                        {	$$ = creaLC();
                                            concatenaLC($$, $1);
                                            concatenaLC($$, $3);

                                            // add $t2, $t1, $t0 
                                            Operacion o = nuevaOpTipo4("add", obtenRegTempLibre(), recuperaResLC($1), recuperaResLC($3));
                                            guardaResLC($$, o.res);
                                            liberaRegTemp(o.arg1);
                                            liberaRegTemp(o.arg2);
                                            insertaLC($$, finalLC($$), o);

                                            liberaLC($1);
                                            liberaLC($3);
                                        }
                                        
                                    |	expression "-" expression
                                       	{	$$ = creaLC();
                                            concatenaLC($$, $1);
                                            concatenaLC($$, $3);

                                            // sub $t2, $t1, $t0 
                                            Operacion o = nuevaOpTipo4("sub", obtenRegTempLibre(), recuperaResLC($1), recuperaResLC($3));
                                            guardaResLC($$, o.res);
                                            liberaRegTemp(o.arg1);
                                            liberaRegTemp(o.arg2);
                                            insertaLC($$, finalLC($$), o);

                                            liberaLC($1);
                                            liberaLC($3);
                                       	}
                                       	
                                    | 	expression "*" expression
                                        {	$$ = creaLC();
                                            concatenaLC($$, $1);
                                            concatenaLC($$, $3);

                                            // mul $t2, $t1, $t0 
                                            Operacion o = nuevaOpTipo4("mul", obtenRegTempLibre(), recuperaResLC($1), recuperaResLC($3));
                                            guardaResLC($$, o.res);
                                            liberaRegTemp(o.arg1);
                                            liberaRegTemp(o.arg2);
                                            insertaLC($$, finalLC($$), o);

                                            liberaLC($1);
                                            liberaLC($3);
                                       	}
                                       	
                                    | 	expression "/" expression
                                        {	$$ = creaLC();
                                            concatenaLC($$, $1);
                                            concatenaLC($$, $3);

                                            // div $t2, $t1, $t0 
                                            Operacion o = nuevaOpTipo4("div", obtenRegTempLibre(), recuperaResLC($1), recuperaResLC($3));
                                            guardaResLC($$, o.res);
                                            liberaRegTemp(o.arg1);
                                            liberaRegTemp(o.arg2);
                                            insertaLC($$, finalLC($$), o);

                                            liberaLC($1);
                                            liberaLC($3);
                                       	}
                                       	
                                    | 	"-" expression %prec UMINUS
                                       	{	$$ = creaLC();
                                            concatenaLC($$, $2);

                                            // neg $t1, $t0
                                            Operacion o = nuevaOpTipo3("neg", obtenRegTempLibre(), recuperaResLC($2));
                                            guardaResLC($$, o.res);
                                            liberaRegTemp(o.arg1);
                                            insertaLC($$, finalLC($$), o);

                                            liberaLC($2);
                                        }
                                        
                                    | 	"(" expression ")"
                                        {	$$ = $2; }
                                        
                                    | 	"id"
                                        {	if (!contieneLS($1)) {
                                                numErroresSemanticos++;
                                                fprintf(stderr, "Error semántico (linea %d): \"%s\" no está declarada\n", yylineno, $1);
                                            }
											$$ = creaLC();

                                            // lw $t0, _id 
                                            Operacion o = nuevaOpTipo3("lw", obtenRegTempLibre(), unirCadenas("_", $1));
                                            guardaResLC($$, o.res);
                                            insertaLC($$, finalLC($$), o);
                                        }
                                        
                                    | "int"
                                        {	$$ = creaLC();

                                            // li $t0, 9
                                            Operacion o = nuevaOpTipo3("li", obtenRegTempLibre(), $1);
                                            guardaResLC($$, o.res);
                                            insertaLC($$, finalLC($$), o);
                                        }
                                    ;
%%

void yyerror(const char * s) {
    numErroresSintacticos++;
    fprintf(stderr, "Error sintáctico (línea %d): (yyerror) %s \n", yylineno, s);
}

char * unirCadenas(char * a, char * b) {
    int l = strlen(a) + strlen(b) + 1;
    char * aux = (char *) malloc(l);
    sprintf(aux, "%s%s", a, b);
    return aux;
}

// ---tabla de simbolos---

void establecerTipoLS(Tipo t) {
    TipoLS = t;
}

void imprimeLS() {
    PosicionLista p;
	printf("##################\n# Seccion de datos\n");
    printf("\t.data\n");

    p = inicioLS(ListaSimbolos);
    int cadena = 1;
    while (p != finalLS(ListaSimbolos)) {
        Simbolo s = recuperaLS(ListaSimbolos, p);
        if (s.tipo == CADENA) {
            printf("$str%d:\n", cadena);
            printf("\t.asciiz \"%s\"\n", s.nombre);
            cadena++;
        }
        assert(p != finalLS(ListaSimbolos));
        p = siguienteLS(ListaSimbolos, p);
    }

    p = inicioLS(ListaSimbolos);
    while (p != finalLS(ListaSimbolos)) {
        Simbolo s = recuperaLS(ListaSimbolos, p);
        if (s.tipo == VARIABLE || s.tipo == CONSTANTE) {
            printf("_%s:\n", s.nombre);
            printf("\t.word 0\n");
        }
        assert(p != finalLS(ListaSimbolos));
        p = siguienteLS(ListaSimbolos, p);
    }

    printf("\n");
}

int contieneLS(char * simbolo) {
    PosicionLista p = buscaLS(ListaSimbolos, simbolo);
    return (p != finalLS(ListaSimbolos));
}

int comprobarConstanteLS(char * simbolo) {
    PosicionLista p = buscaLS(ListaSimbolos, simbolo);
    if (p != finalLS(ListaSimbolos)) {
        Simbolo s = recuperaLS(ListaSimbolos, p);
        return s.tipo == CONSTANTE;
    } else return 0;
}


int insertaEntradaLS(char * simbolo, Tipo tipo) {
    Simbolo s;
    s.tipo = tipo;
    if(tipo == CADENA){
    	// Quitamos comillas
    	char * cadena = strdup(simbolo);
    	cadena++;
    	cadena[strlen(cadena) - 1] = 0;
    	simbolo = cadena;
    	// Actualizamos
    	contadorCadenas++;
    	s.valor = contadorCadenas;
    }
    else s.valor = 0;
    s.nombre = simbolo;
    insertaLS(ListaSimbolos, finalLS(ListaSimbolos), s);
    return s.valor;
}

// ---lista de codigo---

char * obtenRegTempLibre() {
    for (int i = 0; i < 10; i++) {
        if (RegTemp[i] == 0) {
            RegTemp[i] = 1;
            char aux[8];
            sprintf(aux, "$t%d", i);
            return strdup(aux);
        }
    }
    printf("No hay registros temporales libres.\n");
    exit(1);
}

void liberaRegTemp(char * temp) {
    int i = atoi(temp + 2);
    RegTemp[i] = 0;
}

char * obtenEtiqueta() {
    char aux[16];
    sprintf(aux, "$l%d", contadorEtiquetas++);
    return strdup(aux);
}

void imprimeLC() {
    printf("###################\n# Seccion de codigo\n");
    printf("\t.text\n");
    printf("\t.globl main\n");
    printf("\n");
    printf("main:\n");
    
    PosicionListaC p = inicioLC(salida);
    Operacion o;
    while (p != finalLC(salida)) {
        assert(p != finalLC(salida));
        o = recuperaLC(salida, p);
        if (!strcmp(o.op, "etiq")) {
            printf("%s:", o.res);
        } else {
            printf("\t%s",o.op);
            if (o.res != NULL) printf(" %s",o.res);
            if (o.arg1 != NULL) printf(", %s",o.arg1);
            if (o.arg2 != NULL) printf(", %s",o.arg2);
        }
        printf("\n");
        assert(p != finalLC(salida));
        p = siguienteLC(salida, p);
    }
    printf("\n");
    printf("##############\n# Fin\n");
    printf("\tli $v0, 10\n");
    printf("\tsyscall\n");
}

// ---operaciones---

Operacion nuevaOpGeneral(char * op, char * res, char * arg1, char * arg2) {
    Operacion nueva;
    nueva.op = op;
    nueva.res = res;
    nueva.arg1 = arg1;
    nueva.arg2 = arg2;
    return nueva;
}

Operacion nuevaOpTipo1(char * op) {
    return nuevaOpGeneral(op, NULL, NULL, NULL);
}

Operacion nuevaOpTipo2(char * op, char * res) {
    return nuevaOpGeneral(op, res, NULL, NULL);
}

Operacion nuevaOpTipo3(char * op, char * res, char * arg1) {
    return nuevaOpGeneral(op, res, arg1, NULL);
}


Operacion nuevaOpTipo4(char * op, char * res, char * arg1, char * arg2) {
   	return nuevaOpGeneral(op, res, arg1, arg2);
}
