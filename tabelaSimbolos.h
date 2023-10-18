// symbol_table.h

#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#define SYMBOL_SCALAR 1
#define SYMBOL_LABEL  2

typedef struct symbol {
    char* identifier;
    int type;
    int scope;  // 0 para global, 1 para local, etc.
    int offset; // Deslocamento de memória para variáveis locais
    int nParams; // Número de parâmetros, se for uma função
    struct symbol* paramsList; // Lista de parâmetros, se for uma função
    char* label; // Rótulo associado, se necessário
    char* tempReg; // Registro temporário associado, se necessário
    struct symbol* next; // Para lidar com colisões na tabela de símbolos
} Symbol;


#define TABLE_SIZE 100
void iniciarTabela();
unsigned int hash(char* key);
// Protótipos das funções
Symbol* inserirSimbolo(char* identifier, int type);
Symbol* retornaSimbolo(char* identifier);
void removerSimbolo(char* identifier);


void print_simboloTabela() ;
#endif // SYMBOL_TABLE_H