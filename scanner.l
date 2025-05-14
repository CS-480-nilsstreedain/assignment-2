%{
#include "parser.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern YYSTYPE yylval;

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

/* Use a simple queue for DEDENT tokens */
static int pending_dedents = 0;
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
    int lvl = yyleng;
    if (indent_stack_top() < lvl) {
        /*
         * If the current indentation level is greater than the previous indentation
         * level (stored at the top of the stack), then emit an INDENT and push the
         * new indentation level onto the stack.
         */
        indent_stack_push(lvl);
        return INDENT;
    } else if (indent_stack_top() > lvl) {
        /*
         * If the current indentation level is less than the previous indentation
         * level, pop indentation levels off the stack until the top is equal to
         * the current indentation level.  Emit a DEDENT for each element popped
         * from the stack.
         */
        while (!indent_stack_isempty() && indent_stack_top() > lvl) {
            indent_stack_pop();
            pending_dedents++;
        }
        
        /*
         * If we popped everything off the stack, that means the current
         * indentation level didn't match any on the stack, which is an indentation
         * error.
         */
        if (indent_stack_top() != lvl)
            fprintf(stderr, "Error: Incorrect indentation on line %d\n", yylineno);
            
        pending_dedents--;
        return DEDENT;
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
    if (indent_stack_top() > 0) {
        while (indent_stack_top() > 0) {
            indent_stack_pop();
            pending_dedents++;
        }
        
        YY_BUFFER_STATE state = YY_CURRENT_BUFFER;
        int pos = state->yy_buf_pos - state->yy_ch_buf;
        
        for (int i = yyleng - 1; i >= 0; i--)
            unput(yytext[i]);
        
        pending_dedents--;
        return DEDENT;
    }
    REJECT;
}

\r?\n {
    /*
     * This rule will apply only to endlines that come after a statement.
     * Endlines associated with empty lines and comments are handled above.
     * This rule handles both Unix-style and Windows-style line endings.
     */
    return NEWLINE;
}

<<EOF>> {
    /*
     * If we reach the end of the file, pop all indentation levels off the stack
     * and emit a DEDENT for each one.
     */
    if (pending_dedents > 0) {
        pending_dedents--;
        return DEDENT;
    } else if (_indent_stack_top > 0) {
        pending_dedents = _indent_stack_top;
        _indent_stack_top--;
        pending_dedents--;
        return DEDENT;
    }
    return 0;
}

[ \t]  /* Ignore spaces that haven't been handled above. */

. {
    if (pending_dedents > 0) {
        pending_dedents--;
        unput(yytext[0]);
        return DEDENT;
    }
    REJECT;
}

"and"       return AND;
"break"     return BREAK;
"elif"      return ELIF;
"else"      return ELSE;
"if"        return IF;
"not"       return NOT;
"or"        return OR;
"while"     return WHILE;
"True"      { yylval.int_val = 1;  return BOOLEAN; }
"False"     { yylval.int_val = 0;  return BOOLEAN; }

[a-zA-Z_][a-zA-Z0-9_]* {
    /*
     * This rule handling identifiers must come after all the keyword rules above,
     * since each keyword would otherwise be treated as a valid identifier.
     */
    yylval.string = strdup(yytext);
    return IDENTIFIER;
}

[0-9]*"."[0-9]+ {
    yylval.float_val = atof(yytext);
    return FLOAT;
}

[0-9]+ {
    yylval.int_val = atoi(yytext);
    return INTEGER;
}

"="     return ASSIGN;
"+"     return PLUS;
"-"     return MINUS;
"*"     return TIMES;
"/"     return DIVIDE;
"=="    return EQ;
"!="    return NEQ;
">="    return GTE;
">"     return GT;
"<="    return LTE;
"<"     return LT;
"("     return LPAREN;
")"     return RPAREN;
","     return COMMA;
":"     return COLON;

. {
    fprintf(stderr, "Unrecognized token on line %d: %s\n", yylineno, yytext);
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
