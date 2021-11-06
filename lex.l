%{
#include <stdio.h>
#include <stdlib.h>
#include "exprType.h"
#include "y.tab.h"
#define MAX_LINE_LENG 256
#define LIST 					strcat(buf, yytext)
#define LIST_str				strcat(str, yytext)
#define	LIST_quote				strcat(str, "\"")
#define tokenBoolean(t, b) 		{return t;}
#define tokenIdentifier(t, i) 	{return t;}
#define tokenInteger(t, i) 		{return t;}
#define tokenReal(t, r)			{return t;}
#define tokenString(t) 			{return t;}

int linenum = 1;
char buf[MAX_LINE_LENG];
char str[MAX_LINE_LENG];
%}

%x		comment
%x		string

identifier		[a-z|A-Z][a-z|A-Z|0-9]*

digs		[0-9]+
integer		"-"?{digs}
plain_real	"-"?{digs}"."{digs}
expreal		"-"?{digs}"."{digs}[Ee][+-]?{digs}
real		{plain_real}|{expreal}

%%

"," 	{return *yytext;}
":" 	{return *yytext;}
"." 	{return *yytext;}
";" 	{return *yytext;}
"(" 	{return *yytext;}
")" 	{return *yytext;}
"[" 	{return *yytext;}
"]" 	{return *yytext;}

"+" 	{return *yytext;}
"-" 	{return *yytext;}
"*" 	{return *yytext;}
"/" 	{return *yytext;}
"%" 	{return *yytext;}

"<" 	{return LT;}
"<="	{return LEQ;}
">="	{return GEQ;}
">"		{return GT;}
"="		{return EQ;}
"/="	{return NEQ;}
":="	{return ASSIGN;}

"and"		{return AND;}
"or"		{return OR;}
"not"		{return NOT;}

"begin"		{return BEG;}
"boolean"	{return BOOLEAN;}
"break"		{return BREAK;}
"character"	{return CHARACTER;}
"case"		{return CASE;}
"continue"	{return CONTINUE;}
"constant"	{return CONSTANT;}
"declare"	{return DECLARE;}
"do"		{return DO;}
"else"		{return ELSE;}
"end"		{return END;}
"exit"		{return EXIT;}
"float"		{return FLOAT;}
"for"		{return FOR;}
"if"		{return IF;}
"in"		{return IN;}
"integer"	{return INTEGER;}
"loop"		{return LOOP;}
"print"		{return PRINT;}
"println"	{return PRINTLN;}
"procedure"	{return PROCEDURE;}
"program"	{return PROGRAM;}
"return"	{return RETURN;}
"read"		{return READ;}
"string"	{return STRING;}
"then"		{return THEN;}
"while"		{return WHILE;}

"true"		{yylval.boolValue = 1; tokenBoolean(BOOL, yytext);}
"false"		{yylval.boolValue = 0; tokenBoolean(BOOL, yytext);}

{identifier}	{
					yylval.varName = strdup(yytext);
					tokenIdentifier(ID, yytext);
				}

{integer}		{
					yylval.intValue = atoi(yytext); 
					tokenInteger(INT, yytext);
				}

{real}			{
					yylval.floatValue = atof(yytext); 
					tokenReal(FLO, yytext);
				}

\"				{BEGIN(string); str[0] = '\0';}
<string>\"		{BEGIN(INITIAL); yylval.stringValue = strdup(str); tokenString(STR);}
<string>\"\"	{LIST_quote;}
<string>.		{LIST_str;}


"{"				{BEGIN(comment);}
<comment>"}"	{BEGIN(INITIAL);}
<comment>.		{}
<comment>\n		{}

"--".*			{}

\n 	{}

[ \t\r]* 	{}

. 	{
		printf("bad character:'%s'\n", yytext);
		exit(-1);
	}

%%

/*int yywrap()
{
	return 0;
}
  
int main()
{
    extern FILE *yyin;

	char filename[256];
	printf("Please type input filename\n");
	scanf("%s", filename);
	if(filename != "0")
	{
		yyin = fopen(filename, "r");
	}
    yylex();
	yywrap();

    return 0;
}*/