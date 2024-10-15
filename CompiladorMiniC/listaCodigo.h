#ifndef __LISTA_CODIGO__
#define __LISTA_CODIGO__

typedef enum { OPERACION, ARGUMENTO1, ARGUMENTO2, RESULTADO } Campo;

typedef struct {
    char * op;
    char * res;
    char * arg1;
    char * arg2;
} Operacion;

typedef struct ListaCRep * ListaC;
typedef struct PosicionListaCRep * PosicionListaC;

ListaC creaLC();

void liberaLC(ListaC codigo);

void insertaLC(ListaC codigo, PosicionListaC p, Operacion o);

Operacion recuperaLC(ListaC codigo, PosicionListaC p);

PosicionListaC buscaLC(ListaC codigo, PosicionListaC p, char *clave, Campo campo);

void asignaLC(ListaC codigo, PosicionListaC p, Operacion o);

void concatenaLC(ListaC codigo1, ListaC codigo2);

int longitudLC(ListaC codigo);

PosicionListaC inicioLC(ListaC codigo);

PosicionListaC finalLC(ListaC codigo);

PosicionListaC siguienteLC(ListaC codigo, PosicionListaC p);

void guardaResLC(ListaC codigo, char *res);

char * recuperaResLC(ListaC codigo);


#endif
