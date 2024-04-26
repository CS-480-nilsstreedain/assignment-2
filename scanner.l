%{
#include <stdio.h>
#include <stdlib.h>

/*
 * Set up a simplified stack to track indentation level as described in the
 * Python docs.  Put 0 on top of the stack.
 *
 * https://docs.python.org/3/reference/lexical_analysis.html#indentation
 */
#define MAX_INDENT_LEVELS 128
static int _indent_stack[MAX_INDENT_LEVELS] = { 0 };
static int _indent_stack_top = 0;
void indent_stack_push(int);
void indent_stack_pop();
int indent_stack_top();
int indent_stack_isempty();
%}

%option noyywrap
%option yylineno

%%

^[ \t]*\r?\n  /* Skip blank lines */

^[ \t]*#.*\r?\n  /* Skip whole-line comments. */

#.*$  /* Skip comments on the same line as a statement. */

^[ \t]+ {
    /*
     * Handle indentation as described in Python docs linked above. Note that
     * this rule's pattern treats leading spaces and leading tabs equivalently,
     * which could cause some unexpected behavior (compared to normal Python
     * indentation behavior) if they're combined in a single line.  For the
     * purposes of this project, that's OK.
     */
    if (indent_stack_top() < yyleng) {
        /*
         * If the current indentation level is greater than the previous indentation
         * level (stored at the top of the stack), then emit an INDENT and push the
         * new indentation level onto the stack.
         */
        printf("INDENT\n");
        indent_stack_push(yyleng);
    } else {
        /*
         * If the current indentation level is less than the previous indentation
         * level, pop indentation levels off the stack until the top is equal to
         * the current indentation level.  Emit a DEDENT for each element popped
         * from the stack.
         */
        while (!indent_stack_isempty() && indent_stack_top() != yyleng) {
            indent_stack_pop();
            printf("DEDENT\n");
        }

        /*
         * If we popped everything off the stack, that means the current
         * indentation level didn't match any on the stack, which is an indentation
         * error.
         */
        if (indent_stack_isempty()) {
            fprintf(stderr, "Error: Incorrect indentation on line %d\n", yylineno);
            return 1;
        }
    }
}

^[^ \t\r\n]+ {
    /*
     * If we find a line that's not indented (i.e. a line that begins with
     * non-whitespace characters), pop all indentation levels off the stack,
     * and emit a DEDENT for each one.  Then, call REJECT, so the next rule
     * matching this token (i.e. the one at the beginning of the line) is also
     * applied.
     */
    while (indent_stack_top() != 0) {
        indent_stack_pop();
        printf("DEDENT\n");
    }
    REJECT;
}

\r?\n {
  /*
   * This rule will apply only to endlines that come after a statement.
   * Endlines associated with empty lines and comments are handled above.
   * This rule handles both Unix-style and Windows-style line endings.
   */
  printf("NEWLINE\n");
}

<<EOF>> {
    /*
     * If we reach the end of the file, pop all indentation levels off the stack
     * and emit a DEDENT for each one.
     */
    while(indent_stack_top() != 0) {
        indent_stack_pop();
        printf("DEDENT\n");
    }
    yyterminate();
}

[ \t]  /* Ignore spaces that haven't been handled above. */

"and"       printf("AND\t\t%s\n", yytext);
"break"     printf("BREAK\t\t%s\n", yytext);
"def"       printf("DEF\t\t%s\n", yytext);
"elif"      printf("ELIF\t\t%s\n", yytext);
"else"      printf("ELSE\t\t%s\n", yytext);
"for"       printf("FOR\t\t%s\n", yytext);
"if"        printf("IF\t\t%s\n", yytext);
"not"       printf("NOT\t\t%s\n", yytext);
"or"        printf("OR\t\t%s\n", yytext);
"return"    printf("RETURN\t\t%s\n", yytext);
"while"     printf("WHILE\t\t%s\n", yytext);
"True"      printf("BOOLEAN\t\t%d\n", 1);
"False"     printf("BOOLEAN\t\t%d\n", 0);

[a-zA-Z_][a-zA-Z0-9_]* {
    /*
     * This rule handling identifiers must come after all the keyword rules above,
     * since each keyword would otherwise be treated as a valid identifier.
     */
    printf("IDENTIFIER\t%s\n", yytext);
}

[0-9]*"."[0-9]+ {
    printf("FLOAT\t\t%f\n", atof(yytext));
}

[0-9]+ {
    printf("INTEGER\t\t%d\n", atoi(yytext));
}

"="     printf("ASSIGN\t\t%s\n", yytext);
"+"     printf("PLUS\t\t%s\n", yytext);
"-"     printf("MINUS\t\t%s\n", yytext);
"*"     printf("TIMES\t\t%s\n", yytext);
"/"     printf("DIVIDEDBY\t%s\n", yytext);
"=="    printf("EQ\t\t%s\n", yytext);
"!="    printf("NEQ\t\t%s\n", yytext);
">"     printf("GT\t\t%s\n", yytext);
">="    printf("GTE\t\t%s\n", yytext);
"<"     printf("LT\t\t%s\n", yytext);
"<="    printf("LTE\t\t%s\n", yytext);
"("     printf("LPAREN\t\t%s\n", yytext);
")"     printf("RPAREN\t\t%s\n", yytext);
","     printf("COMMA\t\t%s\n", yytext);
":"     printf("COLON\t\t%s\n", yytext);

. {
    fprintf(stderr, "Unrecognized token on line %d: %s\n", yylineno, yytext);
    return 1;
}

%%

/*
 * This function pushes another level to the indentation stack.
 */
void indent_stack_push(int l) {
    /*
     * Increment index of top and make sure it's still within the bounds of the
     * stack array.  If it isn't exit with an error.
     */
    _indent_stack_top++;
    if (_indent_stack_top >= MAX_INDENT_LEVELS) {
        fprintf(stderr, "ERROR: too many levels of indentation\n");
        exit(1);
    }
    _indent_stack[_indent_stack_top] = l;
}

/*
 * This function pops the top from the indent stack.
 */
void indent_stack_pop() {
    if (indent_stack_top >= 0) {
        _indent_stack_top--;
    }
}

/*
 * This function returns the top of the indent stack.  Returns -1 if the
 * indent stack is empty.
 */
int indent_stack_top() {
    return _indent_stack_top >= 0 ? _indent_stack[_indent_stack_top] : -1;
}

/*
 * This function returns 1 if the indent stack is empty or 0 otherwise.
 */
int indent_stack_isempty() {
    return _indent_stack_top < 0;
}

int main() {
    return yylex();
}
