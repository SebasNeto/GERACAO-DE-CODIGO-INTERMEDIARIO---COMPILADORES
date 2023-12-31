%{

#include <stdio.h>
#include <stdlib.h>

#include "tabelaSimbolos.h"
#include "ast.h"

#include "codegen.h"
#include "lex.yy.h"

extern int yylex();
extern char* yytext;
extern int yylineno;

int getLineNumber(void);
void yyerror(const char *s);

%}

%token <intValue> KW_INT KW_REAL VOID
%token IF ELSE WHILE LOOP INPUT RETURN
%token EQ LEQ LT GT GEQ NEQ
%token LIT_INT LIT_REAL LIT_CHAR
%token ID

%union {
    int intValue;
    float floatValue;
    char *strValue;
    Symbol *symbolEntry;
    ASTNode* astNode;
}

%type <intValue> LIT_INT
%type <floatValue> LIT_REAL
%type <strValue> LIT_CHAR
%type <symbolEntry> ID
%type <astNode> espec_tipo


%type <astNode> programa
%type <astNode> var
%type <astNode> exp
%type <astNode> lista_decl
%type <astNode> lista_com
%type <astNode> decl
%type <astNode> comando


%type <astNode> decl_func
%type <astNode> com_expr
%type <astNode> com_atrib

%type <astNode> com_selecao
%type <astNode> com_repeticao
%type <astNode> com_retorno

%type <astNode> exp_soma
%type <astNode> exp_mult
%type <astNode> op_relac
%type <astNode> exp_simples
%type <astNode> cham_func
%type <astNode> literais

%type <astNode> params
%type <astNode> decl_locais

%type <astNode> lista_param
%type <astNode> param

%type <astNode> decl_var
%type <astNode> com_comp



%%

programa: 
    lista_decl lista_com{
        astRaiz = criarNoAST(AST_PROGRAM, $1, $2, NULL);
    }
    ;

lista_decl:
    lista_decl decl {
        $$ = criarNoAST(AST_LIST_DECL, $1, $2, NULL);
    }
    | decl {
        $$ = criarNoAST(AST_DECL, $1, NULL, NULL);
    }
    ;

decl:
    decl_var { $$ = $1; } 
    | decl_func { $$ = $1; } 
    ;

decl_var:
    espec_tipo ID ';' {
        Symbol* entry = inserirSimbolo($1->type, $2->identifier);
        $$ = criarNoAST(AST_DECL_VAR, NULL, NULL, entry);
    }
    | espec_tipo ID '=' literais ';' {
        Symbol* entry = inserirSimbolo($1->type, $2->identifier);
        $$ = criarNoAST(AST_DECL_VAR, NULL, NULL, entry);
    }
    ;

espec_tipo:
    KW_INT { $$ = criarNoAST(AST_TYPE_INT, NULL, NULL, NULL); }
    | KW_REAL { $$ = criarNoAST(AST_TYPE_REAL, NULL, NULL, NULL); }
    | VOID { $$ = criarNoAST(AST_TYPE_VOID, NULL, NULL, NULL); }
    ;


decl_func:
    espec_tipo ID '(' params ')' com_comp {
        if ($1 && $1->symbol && $2 && $2->type) {
            Symbol* entry = inserirSimbolo($2->type, $1->symbol->identifier);
            $$ = criarNoAST(AST_FUNC_DECL, NULL, NULL, entry);
        } else {
            yyerror("Erro na declaração da função: símbolo nulo detectado.");
            $$ = NULL;
        }
    }
    ;


params:
    lista_param { $$ = $1; }
    | VOID { $$ = criarNoAST(AST_TYPE_VOID, NULL, NULL, NULL); }
    | /* vazio */ { $$ = NULL; }
    ;


lista_param:
    lista_param ',' param
    | param
    ;

param:
    espec_tipo var
    ;

decl_locais:
    decl_locais decl_var
    | /* vazio */ { $$ = NULL; }
    ;

lista_com:
    comando lista_com {
        $$ = criarNoAST(AST_LIST_COM, $1, $2, NULL);
    }
    | /* vazio */ {
        $$ = NULL;
    }
    ;

comando:
    com_expr { $$ = $1; } 
    | com_atrib { $$ = $1; } 
    | com_comp { $$ = $1; }  
    | com_selecao { $$ = $1; }  
    | com_repeticao { $$ = $1; }  
    | com_retorno { $$ = $1; }  
    ;

com_expr:
    exp ';' {
        $$ = criarNoAST(AST_EXPR, $1, NULL, NULL);
    }
    | ';' {
        $$ = criarNoAST(AST_EMPTY, NULL, NULL, NULL);
    }
    ;


com_atrib:
    var '=' exp ';' {
        Symbol* varEntry = retornaSimbolo($1->symbol->identifier);
        if (!varEntry) {
            yyerror("Variável não declarada");
        }else{
            $$ = criarNoAST(AST_ASSIGN, $1, $3, NULL);
        }
    }
    ;

com_comp:
    '{' decl_locais lista_com '}' {
        $$ = criarNoAST(AST_COMPOUND, $2, $3, NULL);
    }
    ;

com_selecao:
    IF '(' exp ')' comando {
        $$ = criarNoAST(AST_IF, $3, $5, NULL);
    }
    | IF '(' exp ')' com_comp ELSE comando {
        $$ = criarNoAST(AST_IF_ELSE, $3, $5, retornaSimbolo("AST_IF_ELSE"));
    }
    ;

com_repeticao:
    WHILE '(' exp ')' comando {
        $$ = criarNoAST(AST_WHILE, $3, $5, NULL); 
    }
    ;

com_retorno:
    RETURN ';' {
        $$ = criarNoAST(AST_RETURN, NULL, NULL, NULL); 
    }
    | RETURN exp ';' {
        $$ = criarNoAST(AST_RETURN, $2, NULL, NULL); 
    }
    ;

exp:
    exp_soma op_relac exp_soma {
        $$ = criarNoAST($2->type, $1, $3, NULL);
    }
    | exp_soma { $$ = $1; }
    ;

op_relac:
    LEQ { $$  = criarNoAST(AST_LEQ, NULL, NULL, NULL); }
    | LT { $$  = criarNoAST(AST_LT, NULL, NULL, NULL); }
    | GT { $$  = criarNoAST(AST_GT, NULL, NULL, NULL); }
    | GEQ { $$  = criarNoAST(AST_GEQ, NULL, NULL, NULL); }
    | EQ { $$  = criarNoAST(AST_EQ, NULL, NULL, NULL); }
    | NEQ { $$  = criarNoAST(AST_NEQ, NULL, NULL, NULL); }
    ;

exp_soma:
    exp_soma '+' exp_mult { $$ = criarNoAST(AST_ADD, $1, $3, NULL); }
    | exp_soma '-' exp_mult { $$ = criarNoAST(AST_SUB, $1, $3, NULL); }
    | exp_mult { $$ = $1; }
    ;

exp_mult:
    exp_mult '*' exp_simples { $$ = criarNoAST(AST_MUL, $1, $3, NULL); }
    | exp_mult '/' exp_simples { $$ = criarNoAST(AST_DIV, $1, $3, NULL); }
    | exp_simples { $$ = $1; }
    ;

exp_simples:
    '(' exp ')' { $$ = $2; }
    | var { $$ = $1; }
    | cham_func { $$ = $1; }
    | literais { $$ = $1; }
    ;

literais:
    LIT_INT { $$ = criarNoAST(AST_LIT_INT, NULL, NULL, inserirSimbolo(SYMBOL_SCALAR, yytext)); }
    | LIT_REAL { $$ = criarNoAST(AST_LIT_REAL, NULL, NULL, inserirSimbolo(SYMBOL_SCALAR, yytext)); }
    | LIT_CHAR { $$ = criarNoAST(AST_LIT_CHAR, NULL, NULL, inserirSimbolo(SYMBOL_SCALAR, yytext)); }
    ;

cham_func:
    ID '(' args ')' {
        Symbol* sym = retornaSimbolo($1->identifier);
        if (!sym) {
            yyerror("Função não declarada");
            $$ = NULL;
        }
    }
    ;


var:
    ID {
        Symbol* sym = retornaSimbolo($1->identifier);
        if (!sym) {
            yyerror("Variável não declarada");
        } else {
            $$ = criarNoAST(AST_ID, NULL, NULL, sym);
        }
    }
    | ID '[' LIT_INT ']' {
    }
    ;


args:
    lista_arg
    | /* vazio */
    ;

lista_arg:
    lista_arg ',' exp
    | exp
    ;

%%

int getLineNumber(void) {
    return yylineno;
}

void yyerror(const char *s) {
    fprintf(stderr, "Erro sintático na linha %d, próximo ao token '%s': %s\n", yylineno, yytext, s);
}