# Compilador mini C

Compilador escrito en C para el lenguaje mini C, una versión simplificada de C. Consiste de un analizador léxico implementado con la herramienta Flex y un analizador sintáctico/semántico implementado con Bison. Detalles sobre el diseño y la implementación se dan en la memoria.

## Manual de uso

Usando una distribución de Linux, abrir con una terminal el directorio "CompiladorMiniC" y ejecutar:

```
$ make
$ ./compilador > prueba.s 2> errores
prueba.mc                               // El programa espera que pases el fichero de entrada
$ usr/bin/spim -file prueba.s
```

**Fecha de desarrollo**: Marzo - Mayo 2022
