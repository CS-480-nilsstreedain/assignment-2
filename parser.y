%{
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>

int yylex(void);
extern int yylineno;
void yyerror(const char *s);

int error_count = 0;

/* symbol table */
static char *vars[1024];
static int var_count = 0;

int is_defined(const char *n) {
    for (int i = 0; i < var_count; i++)
        if (strcmp(vars[i], n) == 0) return 1;
    return 0;
}
    
void add_var(const char *n) {
    if (!is_defined(n))
        vars[var_count++] = strdup(n);
}
%}

%locations

%union {
    char *string;
    double float_val;
    int    int_val;
}

%token <int_val>   INTEGER BOOLEAN
%token <float_val> FLOAT
%token <string>    IDENTIFIER

%token IF ELIF ELSE WHILE BREAK AND OR NOT
%token INDENT DEDENT NEWLINE COLON
%token ASSIGN PLUS MINUS TIMES DIVIDE
%token EQ NEQ GT GTE LT LTE
%token LPAREN RPAREN COMMA

%left    OR
%left    AND
%right   NOT
%nonassoc EQ NEQ GT GTE LT LTE
%left    PLUS MINUS
%left    TIMES DIVIDE
%right   UMINUS

%type <string> program stmt_list stmt assign_stmt if_stmt elif_list else_opt while_stmt break_stmt expr indented_stmt_list

%start program

%%

program
    : stmt_list {
        if (error_count == 0) {
            printf("#include <stdio.h>\nint main() {\n");
            for (int i = 0; i < var_count; i++)
                printf("double %s;\n", vars[i]);
            
            printf("\n/* Begin program */\n\n");
            printf("%s", $1);
            printf("\n/* End program */\n\n");
            
            for (int i = 0; i < var_count; i++)
                printf("printf(\"%s: %%lf\\n\", %s);\n", vars[i], vars[i]);
            
            printf("}\n");
        }
        
        free($1);
    };
    
stmt_list
    : { $$ = strdup(""); }
    | stmt_list stmt {
        asprintf(&$$, "%s%s", $1, $2);
        free($1); free($2);
    };

indented_stmt_list : INDENT stmt_list DEDENT { $$ = $2; };

stmt
    : INDENT{
        fprintf(stderr, "Indent error at %d\n", yylineno);
        error_count++;
        $$ = strdup("");
    }
    |assign_stmt | if_stmt | while_stmt | break_stmt
    | error NEWLINE { $$ = strdup(""); };

assign_stmt
    : IDENTIFIER ASSIGN expr NEWLINE {
        add_var($1);
        asprintf(&$$, "%s = %s;\n", $1, $3);
        free($1); free($3);
    };

if_stmt
    : IF expr COLON NEWLINE indented_stmt_list elif_list else_opt {
        asprintf(&$$, "if (%s) {\n%s}%s%s\n", $2, $5, $6, $7);
        free($2); free($5); free($6); free($7);
    };

elif_list
    : { $$ = strdup(""); }
    | elif_list ELIF expr COLON NEWLINE indented_stmt_list {
        asprintf(&$$, "%s else if (%s) {\n%s}", $1, $3, $6);
        free($1); free($3); free($6);
    };

else_opt
    : { $$ = strdup(""); }
    | ELSE COLON NEWLINE indented_stmt_list {
        asprintf(&$$, " else {\n%s}", $4);
        free($4);
    };

while_stmt
    : WHILE expr COLON NEWLINE indented_stmt_list {
        asprintf(&$$, "while (%s) {\n%s}\n", $2, $5);
        free($2); free($5);
    };

break_stmt: BREAK NEWLINE { $$ = strdup("break;\n"); };
expr
    : expr OR expr {    asprintf(&$$, "%s || %s", $1, $3);  free($1); free($3); }
    | expr AND expr {   asprintf(&$$, "%s && %s", $1, $3);  free($1); free($3); }
    | NOT expr {        asprintf(&$$, "!%s", $2);           free($2);           }
    | expr EQ expr {    asprintf(&$$, "%s == %s", $1, $3);  free($1); free($3); }
    | expr NEQ expr {   asprintf(&$$, "%s != %s", $1, $3);  free($1); free($3); }
    | expr GT expr {    asprintf(&$$, "%s > %s", $1, $3);   free($1); free($3); }
    | expr GTE expr {   asprintf(&$$, "%s >= %s", $1, $3);  free($1); free($3); }
    | expr LT expr {    asprintf(&$$, "%s < %s", $1, $3);   free($1); free($3); }
    | expr LTE expr {   asprintf(&$$, "%s <= %s", $1, $3);  free($1); free($3); }
    | expr PLUS expr {  asprintf(&$$, "%s + %s", $1, $3);   free($1); free($3); }
    | expr MINUS expr { asprintf(&$$, "%s - %s", $1, $3);   free($1); free($3); }
    | expr TIMES expr { asprintf(&$$, "%s * %s", $1, $3);   free($1); free($3); }
    | expr DIVIDE expr {asprintf(&$$, "%s / %s", $1, $3);   free($1); free($3); }
    | MINUS expr %prec UMINUS {
        asprintf(&$$, "-%s", $2);
        free($2);
    }
    | LPAREN expr RPAREN {
        asprintf(&$$, "(%s)", $2);
        free($2);
    }
    | INTEGER { asprintf(&$$, "%d", $1); }
    | FLOAT { asprintf(&$$, "%g", $1); }
    | BOOLEAN {
        if ($1)
            $$ = strdup("1");
        else
            $$ = strdup("0");
    }
    | IDENTIFIER {
        if (!is_defined($1)) {
            fprintf(stderr, "Undefined '%s' at %d\n", $1, yylineno);
            error_count++;
        }
        $$ = strdup($1);
        free($1);
    };

%%

int main(void) {
    int result = yyparse();
    return 0;
}

void yyerror(const char *s) {
    fprintf(stderr, "Parser error at line %d: %s\n", yylineno, s);
    error_count++;
}
