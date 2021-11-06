%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "exprType.h"
#include "symbolTable.h"

Node initial;
Stack stack;
FILE *fout;
int tabNum = 0;
int labelStack[1000];
int labelStackIndex = 0;
int isLabelUsed[1000];
int labelNum = 0;
char* programName;

/* Store any information of a function that user declares */
typedef struct Fun Fun;
struct Fun{
	char* name;
	char* argName[100];
	char* type[100];
    char* returnType;
	int argIndex;
};

void createFun(Fun* ptr, char* n){
    ptr->name = n;
    ptr->argIndex = 0;
}

void insertFunArg(Fun* ptr, char* n, char* t){
    ptr->argName[ptr->argIndex] = n;
    ptr->type[ptr->argIndex] = t;
    ptr->argIndex += 1;
}

void setReturnType(Fun* ptr, char* r){
    ptr->returnType = r;
}

/* Store any function that user declares */
Fun funArray[100];
int total_fun_index = 0;

void insertFun(Fun fun){
    funArray[total_fun_index] = fun;
    total_fun_index += 1;
}

int isConstant = 0;
int inGlobal = 0;
int inDeclare = 0;
int inProcedure = 0;                          // To differ now is in procedure declare or program 
int inIf = 0;
int inElse = 0;
int inWhile = 0;
int inFor = 0;

/* In statement, user invokes a function, and we use this to store the args that user types */
typedef struct InvocationArg InvocationArg;
struct InvocationArg{
    char* name;
    char* type[100];
    int total_arg_index;
    int error;
};

void insertInvocationArg(InvocationArg* ptr, char* type){
    ptr->type[ptr->total_arg_index] = type;
    ptr->total_arg_index += 1;
}

/* As global variable, the invoke function is stored in this */ 
InvocationArg calledProcedure;


void write(char* str){
    int i;
    for(i = 0; i < tabNum; i++){
        fprintf(fout, "\t");
    }
    fprintf(fout, str);
}
%}

/* tokens */ 

%union
{
    char* varName;
    int boolValue;
    int intValue;
    float floatValue;
    char* stringValue;
    exprType expression_type;
}
%token ',' ':' '.' ';' '(' ')' '[' ']'

%token BEG BOOLEAN BREAK CHARACTER CASE CONTINUE CONSTANT DECLARE DO
%token ELSE END EXIT FLOAT FOR IF IN INTEGER LOOP PRINT PRINTLN PROCEDURE
%token PROGRAM RETURN READ STRING THEN WHILE

%token <varName> ID
%token <boolValue> BOOL
%token <intValue> INT
%token <floatValue> FLO
%token <stringValue> STR

%right  ASSIGN
%left   OR
%left   AND
%left   NOT
%left   EQ NEQ
%left   LT LEQ GEQ GT
%left   '-' '+'
%left   '*' '/' '%'
%nonassoc UMINUS

%type <expression_type> expression
%type <expression_type> called_procedure

%% 
start:  PROGRAM ID
        {
            fprintf(fout, "class %s\n", $2);
            write("{\n");
            tabNum++;
            programName = $2;
            printf("start !\n\n");    
        }
        code END ID    
        {   
            tabNum--;
            write("}");
            if(strcmp($2, $6) != 0){
                yyerror("program names are not euqal !\n");
            }
            else{
                printf("End program!\n");
            }
        }

code:   DECLARE 
        {
            inDeclare = 1;
            inGlobal = 1;
        }
        declare 
        {
            /*
            This dump should show the global variable
            */
            printf("after declare:\n");
            dump(&stack.start->ptr);
            printf("Section 1 : done PROGRAM variable declare \n\n");
            fprintf(fout, "\n");
            inDeclare = 0;
            inGlobal = 0;
        }
        preprocedure
        {
            /*
            This dump should show the global variable and fun which declared correctly
            */
            printf("after procedure:\n");
            dump(&stack.start->ptr);
            printf("Section 2 : done PROGRAM procedure declare \n\n");
        }
        BEG 
        {
            write("method public static void main(java.lang.String[])\n");
            write("max_stack 15\n");
            write("max_locals 15\n");
            write("{\n");
            tabNum++;
        }    
        statement 
        {
            printf("Section 3 : done PROGRAM statement \n\n");
        }
        END 
        {
            write("return\n");
            tabNum--;
            write("}\n");
        }
        ';'
    |   preprocedure
        {
            printf("after procedure:\n");
            dump(&stack.start->ptr);
            printf("Section 1 : done PROGRAM procedure declare \n\n");
        }
        BEG 
        {
            write("method public static void main(java.lang.String[])\n");
            write("max_stack 15\n");
            write("max_locals 15\n");
            write("{\n");
            tabNum++;
        }
        statement 
        {
            printf("Section 2 : done PROGRAM statement \n\n");
        }
        END 
        {
            write("return\n");
            tabNum--;
            write("}\n");
        }
        ';'
    |   BEG 
        {
            write("method public static void main(java.lang.String[])\n");
            write("max_stack 15\n");
            write("max_locals 15\n");
            write("{\n");
            tabNum++;
        }
        statement
        {
            printf("Section : done PROGRAM statement \n\n");
        }
        END 
        {
            write("return\n");
            tabNum--;
            write("}\n");
        }
        ';'

declare:    
        /*
        Constant with type and value 
        */
        |   declare ID ':' CONSTANT ':' BOOLEAN ASSIGN 
            {
                isConstant = 1;
            }
            expression ';'
            {
                SymbolTable *temp;
                temp = &stack.last->ptr;

                if(strcmp($9.type, "boolean") == 0 && $9.b== 1){
                    insert(temp, $2, 1, 0, "boolean", 1, NULL, 0.0, NULL, NULL);
                }
                else if(strcmp($9.type, "boolean") == 0 && $9.b== 0){
                    insert(temp, $2, 1, 0, "boolean", 0, NULL, 0.0, NULL, NULL);
                }   
                else{
                    yyerror("wrong type assign, FOOL !\n");
                }     
                isConstant = 0;
            }
        |   declare ID ':' CONSTANT ':' INTEGER ASSIGN 
            {
                isConstant = 1;
            }
            expression ';'
            {   
                SymbolTable *temp;
                temp = &stack.last->ptr;

                if(strcmp($9.type, "int") == 0){
                    insert(temp, $2, 1, 0, "int", NULL, $9.i, 0.0, NULL, NULL);
                }
                else{
                    yyerror("wrong type assign, FOOL !\n");
                }
                isConstant = 0;
            }
        |   declare ID ':' CONSTANT ':' FLOAT ASSIGN 
            {
                isConstant = 1;
            }
            expression ';'
            {
                SymbolTable *temp;
                temp = &stack.last->ptr;
                
                if(strcmp($9.type, "float") == 0){
                    insert(temp, $2, 1, 0, "float", NULL, NULL, $9.f, NULL, NULL);
                }
                else{
                    yyerror("wrong type assign, FOOL !\n");
                }
                isConstant = 0;
            }
        |   declare ID ':' CONSTANT ':' STRING ASSIGN expression ';'
            {
                SymbolTable *temp;
                temp = &stack.last->ptr;
                
                if(strcmp($8.type, "string") == 0){
                    insert(temp, $2, 1, 0, "string", NULL, NULL, 0.0, $8.s, NULL);
                }
                else{
                    yyerror("wrong type assign, FOOL !\n");
                }
            }
        /* 
        Constant with only value 
        */
        |   declare ID ':' CONSTANT ASSIGN 
            {
                isConstant = 1;
            }
            expression ';'
            {
                SymbolTable *temp;
                temp = &stack.last->ptr;
                
                if(strcmp($7.type, "boolean") == 0 && $7.b== 1){
                    insert(temp, $2, 1, 0, "boolean", 1, NULL, 0.0, NULL, NULL);
                }
                else if(strcmp($7.type, "boolean") == 0 && $7.b== 0){
                    insert(temp, $2, 1, 0, "boolean", 0, NULL, 0.0, NULL, NULL);
                }
                else if(strcmp($7.type, "int") == 0){
                    insert(temp, $2, 1, 0, "int", NULL, $7.i, 0.0, NULL, NULL);
                } 
                else if(strcmp($7.type, "float") == 0){
                    insert(temp, $2, 1, 0, "float", NULL, NULL, $7.f, NULL, NULL);
                } 
                else if(strcmp($7.type, "string") == 0){
                    insert(temp, $2, 1, 0, "string", NULL, NULL, 0.0, $7.s, NULL);
                }
                else{
                    yyerror("wrong assign, FOOL !\n");
                }
                isConstant = 0;
            }
        /* 
        Nonconstant with nothing 
        */
        |   declare ID ';'
            {
                SymbolTable *temp;
                temp = &stack.last->ptr;
                
                insert(temp, $2, 0, 0, "int", NULL, NULL, 0.0, NULL, NULL);
                if(inGlobal == 1){
                    temp->stackIndex--;
                }

                if(stack.start->next == NULL){
                    write("field static int ");
                    fprintf(fout, "%s\n", $2);
                }
            }
        /* 
        Nonconstant with type and value 
        */
        |   declare ID ':' BOOLEAN ASSIGN expression ';'
            {   
                SymbolTable *temp;
                temp = &stack.last->ptr;
                
                if(strcmp($6.type, "boolean") == 0 && $6.b == 1){
                    insert(temp, $2, 0, 0, "boolean", 1, NULL, 0.0, NULL, NULL);
                    if(inGlobal == 1){
                        temp->stackIndex--;
                    }

                    /*
                     It is global variable
                    */
                    if(stack.start->next == NULL){
                        write("field static int ");
                        fprintf(fout, "%s = 1\n", $2);
                    }
                    /*
                     It is local variable
                    */
                    else{
                        write("istore ");
                        fprintf(fout, "%d\n", temp->stackIndex - 1);
                    }
                }
                else if(strcmp($6.type, "boolean") == 0 && $6.b == 0){
                    insert(temp, $2, 0, 0, "boolean", 0, NULL, 0.0, NULL, NULL);
                    if(inGlobal == 1){
                        temp->stackIndex--;
                    }

                    if(stack.start->next == NULL){
                        write("field static int ");
                        fprintf(fout, "%s = 0\n", $2);
                    }
                    else{
                        write("istore ");
                        fprintf(fout, "%d\n", temp->stackIndex - 1);
                    }
                }
                else{
                    yyerror("wrong type assign, FOOL !\n");
                }
            }
        |   declare  ID ':' INTEGER ASSIGN expression ';'
            {
                SymbolTable *temp;
                temp = &stack.last->ptr;
                
                if(strcmp($6.type, "int") == 0){
                    insert(temp, $2, 0, 0, "int", NULL, $6.i, 0.0, NULL, NULL);
                    if(inGlobal == 1){
                        temp->stackIndex--;
                    }

                    if(stack.start->next == NULL){
                        write("field static int ");
                        fprintf(fout, "%s = %d\n", $2, $6.i);
                    }
                    else{
                        write("istore ");
                        fprintf(fout, "%d\n", temp->stackIndex - 1);
                    }
                }
                else{
                    yyerror("wrong type assign, FOOL !\n");
                }
            }
        |   declare ID ':' FLOAT ASSIGN expression ';'
            {
                SymbolTable *temp;
                temp = &stack.last->ptr;
                
                if(strcmp($6.type, "float") == 0){
                    insert(temp, $2, 0, 0, "float", NULL, NULL, $6.f, NULL, NULL);
                    if(inGlobal == 1){
                        temp->stackIndex--;
                    }

                    if(stack.start->next == NULL){
                        write("field static float ");
                        fprintf(fout, "%s = %ff\n", $2, $6.f);
                    }
                    else{
                        write("fstore ");
                        fprintf(fout, "%d\n", temp->stackIndex - 1);
                    }
                }
                else{
                    yyerror("wrong type assign, FOOL !\n");
                }
            }
        |   declare ID ':' STRING ASSIGN expression ';'
            {
                SymbolTable *temp;
                temp = &stack.last->ptr;
                
                if(strcmp($6.type, "string") == 0){
                    insert(temp, $2, 0, 0, "string", NULL, NULL, 0.0, $6.s, NULL);
                }
                else{
                    yyerror("wrong type assign, FOOL !\n");
                }
            }
        /* 
        Nonconstant with only type 
        */
        |   declare ID ':' BOOLEAN ';'
            {
                SymbolTable *temp;
                temp = &stack.last->ptr;
                
                insert(temp, $2, 0, 0, "boolean", NULL, NULL, 0.0, NULL, NULL);
                if(inGlobal == 1){
                    temp->stackIndex--;
                }

                if(stack.start->next == NULL){
                    write("field static int ");
                    fprintf(fout, "%s\n", $2);
                }
            }
        |   declare ID ':' INTEGER ';'
            {
                SymbolTable *temp;
                temp = &stack.last->ptr;
                if(inGlobal == 1){
                    temp->stackIndex--;
                }

                insert(temp, $2, 0, 0, "int", NULL, NULL, 0.0, NULL, NULL);

                if(stack.start->next == NULL){
                    write("field static int ");
                    fprintf(fout, "%s\n", $2);
                }
            }
        |   declare ID ':' FLOAT ';'
            {
                SymbolTable *temp;
                temp = &stack.last->ptr;
                if(inGlobal == 1){
                    temp->stackIndex--;
                }
                
                insert(temp, $2, 0, 0, "float", NULL, NULL, 0.0, NULL, NULL);
                if(stack.start->next == NULL){
                    write("field static float ");
                    fprintf(fout, "%s\n", $2);
                }
            }
        |   declare ID ':' STRING ';'
            {
                SymbolTable *temp;
                temp = &stack.last->ptr;
                
                insert(temp, $2, 0, 0, "string", NULL, NULL, 0.0, NULL, NULL);
            }
        /* 
        Nonconstant with only value
        */
        |   declare ID ASSIGN expression ';'
            {
                SymbolTable *temp;
                temp = &stack.last->ptr;
                
                if(strcmp($4.type, "boolean") == 0 && $4.b== 1){
                    insert(temp, $2, 0, 0, "boolean", 1, NULL, 0.0, NULL, NULL);
                    if(inGlobal == 1){
                        temp->stackIndex--;
                    }

                    if(stack.start->next == NULL){
                        write("field static int ");
                        fprintf(fout, "%s = 1\n", $2);
                    }
                    else{
                        write("istore ");
                        fprintf(fout, "%d\n", temp->stackIndex - 1);
                    }
                }
                else if(strcmp($4.type, "boolean") == 0 && $4.b== 0){
                    insert(temp, $2, 0, 0, "boolean", 0, NULL, 0.0, NULL, NULL);
                    if(inGlobal == 1){
                        temp->stackIndex--;
                    }

                    if(stack.start->next == NULL){
                        write("field static int ");
                        fprintf(fout, "%s = 0\n", $2);
                    }
                    else{
                        write("istore ");
                        fprintf(fout, "%d\n", temp->stackIndex - 1);
                    }
                }
                else if(strcmp($4.type, "int") == 0){
                    insert(temp, $2, 0, 0, "int", NULL, $4.i, 0.0, NULL, NULL);
                    if(inGlobal == 1){
                        temp->stackIndex--;
                    }

                    if(stack.start->next == NULL){
                        write("field static int ");
                        fprintf(fout, "%s = %d\n", $2, $4.i);
                    }
                    else{
                        write("istore ");
                        fprintf(fout, "%d\n", temp->stackIndex - 1);
                    }
                } 
                else if(strcmp($4.type, "float") == 0){
                    insert(temp, $2, 0, 0, "float", NULL, NULL, $4.f, NULL, NULL);
                    if(inGlobal == 1){
                        temp->stackIndex--;
                    }

                    if(stack.start->next == NULL){
                        write("field static float ");
                        fprintf(fout, "%s = %ff\n", $2, $4.f);
                    }
                    else{
                        write("fstore ");
                        fprintf(fout, "%d\n", temp->stackIndex - 1);
                    }
                } 
                else if(strcmp($4.type, "string") == 0){
                    insert(temp, $2, 0, 0, "string", NULL, NULL, 0.0, $4.s, NULL);
                }
            }
        /* 
        Array
        */
        |   declare ID ':'  BOOLEAN '[' INT ']' ';'
            {
                SymbolTable *temp;
                temp = &stack.last->ptr;
                
                if($6 < 0 || $6 == 0){
                    yyerror("index canot be zero or smaller\n");
                }
                else{
                    insert(temp, $2, 0, 1, "boolean", NULL, NULL, 0.0, NULL, $6);
                }
            }
        |   declare ID ':'  INTEGER '[' INT ']' ';'
            {
                SymbolTable *temp;
                temp = &stack.last->ptr;
                
                if($6 < 0 || $6 == 0){
                    yyerror("index canot be zero or smaller\n");
                }
                else{
                    insert(temp, $2, 0, 1, "int", NULL, NULL, 0.0, NULL, $6);
                }
            }
        |   declare ID ':'  FLOAT '[' INT ']' ';'
            {
                SymbolTable *temp;
                temp = &stack.last->ptr;
                
                if($6 < 0 || $6 == 0){
                    yyerror("index canot be zero or smaller\n");
                }
                else{
                    insert(temp, $2, 0, 1, "float", NULL, NULL, 0.0, NULL, $6);
                }
            }
        |   declare ID ':'  STRING '[' INT ']' ';'
            {
                SymbolTable *temp;
                temp = &stack.last->ptr;
                
                if($6 < 0 || $6 == 0){
                    yyerror("index canot be zero or smaller\n");
                }
                else{
                    insert(temp, $2, 0, 1, "string", NULL, NULL, 0.0, NULL, $6);
                }
            }
        
        
/* 
Before the detail of procedure, we first initialize some variables 
*/
preprocedure:   
        |       PROCEDURE ID 
                {
                    printf("procedure \"%s\":\n", $2);
                    insert(&stack.start->ptr, $2, 0, 0, "fun", NULL, NULL, 0.0, NULL, NULL);    // push fun name into the main table
                    stack.start->ptr.stackIndex--;
                    inProcedure = 1;
                    Fun *fun = (Fun*) malloc(sizeof(Fun));
                    createFun(fun, $2);         
                    insertFun(*fun);            // let fun insert into funArray, so the last one is the current fun
                    push_back(&stack, $2);      // create a new table for this fun scope
                    free(fun);

                    write("method public static ");
                }
                procedure preprocedure

/* 
After initializing, analyze each procedure format 
*/
procedure:  '(' arguments ')' RETURN BOOLEAN
            {
                printf("done %s arguments declare\n\n", funArray[total_fun_index - 1].name);
                setReturnType(&funArray[total_fun_index - 1], "boolean");

                fprintf(fout, "int %s(", funArray[total_fun_index - 1].name);
                int i;
                for(i = 0; i < funArray[total_fun_index - 1].argIndex; i++){
                    fprintf(fout, "%s", funArray[total_fun_index - 1].type[i]);
                    if(funArray[total_fun_index - 1].argIndex != 1 && i != funArray[total_fun_index - 1].argIndex - 1){
                        fprintf(fout, ", ");
                    }
                }
                fprintf(fout, ")\n");
                write("max_stack 15\n");
                write("max_locals 15\n");
                write("{\n");
                tabNum++;
            }
                block
            END ID ';'
            {
                inProcedure = 0;
                /*
                in the end, we find id is not equal, so it needs to be deleted
                */
                if(strcmp(funArray[total_fun_index - 1].name, $9) != 0){
                    yyerror("procedure names are not equal!\n");
                    int i = lookup(&stack.start->ptr, funArray[total_fun_index - 1].name);
                    /*
                    let the name in main table empty, so it can't be searched
                    */
                    if(i != -1){                          
                        stack.start->ptr.table[i][0] = '\0';
                    }
                    /*
                    the last one in funArray is target, so we just let index sub 1
                    */
                    total_fun_index -=1;
                }

                tabNum--;
                write("}\n\n");
            }
        |   '(' arguments ')' RETURN INTEGER
            {
                printf("done %s arguments declare\n\n", funArray[total_fun_index - 1].name);
                setReturnType(&funArray[total_fun_index - 1], "int");

                fprintf(fout, "int %s(", funArray[total_fun_index - 1].name);
                int i;
                for(i = 0; i < funArray[total_fun_index - 1].argIndex; i++){
                    fprintf(fout, "%s", funArray[total_fun_index - 1].type[i]);
                    if(funArray[total_fun_index - 1].argIndex != 1 && i != funArray[total_fun_index - 1].argIndex - 1){
                        fprintf(fout, ", ");
                    }
                }
                fprintf(fout, ")\n");
                write("max_stack 15\n");
                write("max_locals 15\n");
                write("{\n");
                tabNum++;
            }
                block
            END ID ';'
            {
                inProcedure = 0;
                if(strcmp(funArray[total_fun_index - 1].name, $9) != 0){
                    yyerror("procedure names are not equal!\n");
                    int i = lookup(&stack.start->ptr, funArray[total_fun_index - 1].name);
                    if(i != -1){
                        stack.start->ptr.table[i][0] = '\0';
                    }
                    total_fun_index -=1;
                }

                tabNum--;
                write("}\n\n");
            }
        |   '(' arguments ')' RETURN FLOAT
            {
                printf("done %s arguments declare\n\n", funArray[total_fun_index - 1].name);
                setReturnType(&funArray[total_fun_index -1], "float");

                fprintf(fout, "float %s(", funArray[total_fun_index - 1].name);
                int i;
                for(i = 0; i < funArray[total_fun_index - 1].argIndex; i++){
                    fprintf(fout, "%s", funArray[total_fun_index - 1].type[i]);
                    if(funArray[total_fun_index - 1].argIndex != 1 && i != funArray[total_fun_index - 1].argIndex - 1){
                        fprintf(fout, ", ");
                    }
                }
                fprintf(fout, ")\n");
                write("max_stack 15\n");
                write("max_locals 15\n");
                write("{\n");
                tabNum++;
            }
                block
            END ID ';' 
            {
                inProcedure = 0;
                if(strcmp(funArray[total_fun_index - 1].name, $9) != 0){
                    yyerror("procedure names are not equal!\n");
                    int i = lookup(&stack.start->ptr, funArray[total_fun_index - 1].name);
                    if(i != -1){
                        stack.start->ptr.table[i][0] = '\0';
                    }
                    total_fun_index -=1;
                }

                tabNum--;
                write("}\n\n");
            }
        |   '(' arguments ')' RETURN STRING
            {
                printf("done %s arguments declare\n\n", funArray[total_fun_index - 1].name);
                setReturnType(&funArray[total_fun_index], "string");
            }
                block
            END ID ';'
            {
                inProcedure = 0;
                if(strcmp(funArray[total_fun_index - 1].name, $9) != 0){
                    yyerror("procedure names are not equal!\n");
                    int i = lookup(&stack.start->ptr, funArray[total_fun_index - 1].name);
                    if(i != -1){
                        stack.start->ptr.table[i][0] = '\0';
                    }
                    total_fun_index -=1;
                }

                tabNum--;
                write("}\n\n");
            }
        |   RETURN BOOLEAN
            {
                setReturnType(&funArray[total_fun_index - 1], "boolean");

                fprintf(fout, "int %s(", funArray[total_fun_index - 1].name);
                fprintf(fout, ")\n");
                write("max_stack 15\n");
                write("max_locals 15\n");
                write("{\n");
                tabNum++;
            }
                block
            END ID ';' 
            {
                inProcedure = 0;
                if(strcmp(funArray[total_fun_index - 1].name, $6) != 0){
                    yyerror("procedure names are not equal!\n");
                    int i = lookup(&stack.start->ptr, funArray[total_fun_index - 1].name);
                    if(i != -1){
                        stack.start->ptr.table[i][0] = '\0';
                    }
                    total_fun_index -=1;
                }

                tabNum--;
                write("}\n\n");
            }
        |   RETURN INTEGER
            {
                setReturnType(&funArray[total_fun_index - 1], "int");

                fprintf(fout, "int %s(", funArray[total_fun_index - 1].name);
                fprintf(fout, ")\n");
                write("max_stack 15\n");
                write("max_locals 15\n");
                write("{\n");
                tabNum++;
            }
                block
            END ID ';' 
            {
                inProcedure = 0;
                if(strcmp(funArray[total_fun_index - 1].name, $6) != 0){
                    yyerror("procedure names are not equal!\n");
                    int i = lookup(&stack.start->ptr, funArray[total_fun_index - 1].name);
                    if(i != -1){
                        stack.start->ptr.table[i][0] = '\0';
                    }
                    total_fun_index -=1;
                }

                tabNum--;
                write("}\n\n");
            }
        |   RETURN FLOAT
            {
                setReturnType(&funArray[total_fun_index - 1], "float");

                fprintf(fout, "float %s(", funArray[total_fun_index - 1].name);
                fprintf(fout, ")\n");
                write("max_stack 15\n");
                write("max_locals 15\n");
                write("{\n");
                tabNum++;
            }
                block
            END ID ';'
            {
                inProcedure = 0;
                if(strcmp(funArray[total_fun_index - 1].name, $6) != 0){
                    yyerror("procedure names are not equal!\n");
                    int i = lookup(&stack.start->ptr, funArray[total_fun_index - 1].name);
                    if(i != -1){
                        stack.start->ptr.table[i][0] = '\0';
                    }
                    total_fun_index -=1;
                }

                tabNum--;
                write("}\n\n");
            }
        |   RETURN STRING
            {
                setReturnType(&funArray[total_fun_index - 1], "string");
            }
                block
            END ID ';' 
            {
                inProcedure = 0;
                if(strcmp(funArray[total_fun_index - 1].name, $6) != 0){
                    yyerror("procedure names are not equal!\n");
                    int i = lookup(&stack.start->ptr, funArray[total_fun_index - 1].name);
                    if(i != -1){
                        stack.start->ptr.table[i][0] = '\0';
                    }
                    total_fun_index -=1;
                }

                tabNum--;
                write("}\n\n");
            }
        |   '(' arguments ')'
            {
                printf("done %s arguments declare\n\n", funArray[total_fun_index - 1].name);
                setReturnType(&funArray[total_fun_index - 1], "NULL");

                fprintf(fout, "void %s(", funArray[total_fun_index - 1].name);
                int i;
                for(i = 0; i < funArray[total_fun_index - 1].argIndex; i++){
                    fprintf(fout, "%s", funArray[total_fun_index - 1].type[i]);
                    if(funArray[total_fun_index - 1].argIndex != 1 && i != funArray[total_fun_index - 1].argIndex - 1){
                        fprintf(fout, ", ");
                    }
                }
                fprintf(fout, ")\n");
                write("max_stack 15\n");
                write("max_locals 15\n");
                write("{\n");
                tabNum++;
            }
                block
            END ID ';'
            {
                inProcedure = 0;
                if(strcmp(funArray[total_fun_index - 1].name, $7) != 0){
                    yyerror("procedure names are not equal!\n");
                    int i = lookup(&stack.start->ptr, funArray[total_fun_index - 1].name);
                    if(i != -1){
                        stack.start->ptr.table[i][0] = '\0';
                    }
                    total_fun_index -=1;
                }

                tabNum--;
                write("}\n\n");
            }
        |   
            {
                fprintf(fout, "void %s(", funArray[total_fun_index - 1].name);
                fprintf(fout, ")\n");
                write("max_stack 15\n");
                write("max_locals 15\n");
                write("{\n");
                tabNum++;
            }
                block
            END ID ';'
            {
                setReturnType(&funArray[total_fun_index - 1], "NULL");
                inProcedure = 0;
                if(strcmp(funArray[total_fun_index - 1].name, $4) != 0){
                    yyerror("procedure names are not equal!\n");
                    int i = lookup(&stack.start->ptr, funArray[total_fun_index - 1].name);
                    if(i != -1){
                        stack.start->ptr.table[i][0] = '\0';
                    }
                    total_fun_index -=1;
                }

                tabNum--;
                write("}\n\n");
            }

/* 
When declaring, insert the args into the function information 
*/
arguments:  ID ':' BOOLEAN
            {
                printf("funName: %s \t arg: %s \t type: boolean\n", funArray[total_fun_index - 1].name, $1);
                insertFunArg(&funArray[total_fun_index - 1], $1, "boolean");
                /*
                I also put args into the symbol table of fun
                */
                insert(&stack.last->ptr, $1, 0, 0, "boolean", NULL, NULL, 0.0, NULL, NULL);
            }
        |   ID ':' INTEGER
            {   
                printf("funName: %s \t arg: %s \t type: int\n", funArray[total_fun_index - 1].name, $1);
                insertFunArg(&funArray[total_fun_index - 1], $1, "int");
                insert(&stack.last->ptr, $1, 0, 0, "int", NULL, NULL, 0.0, NULL, NULL);
            }
        |   ID ':' FLOAT
            {
                printf("funName: %s \t arg: %s \t type: float\n", funArray[total_fun_index - 1].name, $1);
                insertFunArg(&funArray[total_fun_index - 1], $1, "float");
                insert(&stack.last->ptr, $1, 0, 0, "float", NULL, NULL, 0.0, NULL, NULL);
            }
        |   ID ':' STRING
            {
                printf("funName: %s \t arg: %s \t type: string\n", funArray[total_fun_index - 1].name, $1);
                insertFunArg(&funArray[total_fun_index - 1], $1, "string");
                insert(&stack.last->ptr, $1, 0, 0, "string", NULL, NULL, 0.0, NULL, NULL);
            }
        |   arguments ';' ID ':' BOOLEAN
            {
                printf("funName: %s \t arg: %s \t type: boolean\n", funArray[total_fun_index - 1].name, $3);
                insertFunArg(&funArray[total_fun_index - 1], $3, "boolean");
                insert(&stack.last->ptr, $3, 0, 0, "boolean", NULL, NULL, 0.0, NULL, NULL);
            }
        |   arguments ';' ID ':' INTEGER
            {
                printf("funName: %s \t arg: %s \t type: int\n", funArray[total_fun_index - 1].name, $3);
                insertFunArg(&funArray[total_fun_index - 1], $3, "int");
                insert(&stack.last->ptr, $3, 0, 0, "int", NULL, NULL, 0.0, NULL, NULL);
            }
        |   arguments ';' ID ':' FLOAT
            {
                printf("funName: %s \t arg: %s \t type: float\n", funArray[total_fun_index - 1].name, $3);
                insertFunArg(&funArray[total_fun_index - 1], $3, "float");
                insert(&stack.last->ptr, $3, 0, 0, "float", NULL, NULL, 0.0, NULL, NULL);
            }
        |   arguments ';' ID ':' STRING 
            {
                printf("funName: %s \t arg: %s \t type: string\n", funArray[total_fun_index - 1].name, $3);
                insertFunArg(&funArray[total_fun_index - 1], $3, "string");
                insert(&stack.last->ptr, $3, 0, 0, "string", NULL, NULL, 0.0, NULL, NULL);
            }

/* 
Analyze each block format 
*/
block:  DECLARE 
        {
            inDeclare = 1;
        }
        declare 
        {
            /*
            This printf hints that it just finishs declaring the variable of procedure
            */
            if(inIf == 0 && inWhile == 0 && inFor == 0 && inProcedure == 1){
                printf("done %s variable declare\n\n", funArray[total_fun_index - 1].name);
            }
            inDeclare = 0;
        }
        BEG statement END ';'
        {
            /*
            This pop_back pops the last table, and show the symbolTable of this table
            */
            pop_back(&stack);   

            /* 
            All 0 means it is not in if or while or for loop right now 
            */         
            if(inIf == 0 && inWhile == 0 && inFor == 0 && inProcedure == 1){
                printf("done %s statement declare\n\n", funArray[total_fun_index - 1].name);
            }
        }
    |   BEG statement END ';'
        {
            pop_back(&stack);   
            if(inIf == 0 && inWhile == 0 && inFor == 0 && inProcedure == 1){
                printf("done %s statement declare\n\n", funArray[total_fun_index - 1].name);
            }
        }
    /* 
    this one use as simple_statement 
    */
    |   single_statement
        {
            pop_back(&stack);   
            if(inIf == 0 && inWhile == 0 && inFor == 0 && inProcedure == 1){
                printf("done %s statement declare\n\n", funArray[total_fun_index - 1].name);
            }
        }

statement:   
        |   statement ID ASSIGN expression ';'
            {
                /*
                For the ID searching, we start from the last table.
                If not find it, we go to the previous table, and just keep searching it.
                If still not find, the table should stop at the first table, because there is no more any previous table.
                And index should be -1
                */
                Node* temp;
                int index = -1;
                
                temp = stack.last;
                index = lookup(&temp->ptr, $2);

                while(index == -1 && temp->previous != NULL){
                    temp = temp->previous;
                    index = lookup(&temp->ptr, $2);
                }
                
                /*
                Find it, and we do assign
                */
                if(index != -1){
                    SymbolTable* current = &temp->ptr;
                    if(current->isConstant[index] == 1){
                        yyerror("assign to constant variable !\n");
                    }
                    else if(strcmp(current->type[index], "boolean") == 0 && strcmp($4.type, "boolean") == 0){
                        printf("do boolean assign\n");
                        current->boolValue[index] = $4.b;

                        /*
                        the variable assigned is global
                        */
                        if(strcmp(temp->name, "main") == 0){
                            write("putstatic int ");
                            fprintf(fout, "%s.%s\n", programName, $2);
                        }
                        /*
                        the variable assigned is local
                        */
                        else{
                            write("istore ");
                            fprintf(fout, "%d\n", current->stack[index]);
                        }
                    }
                    else if(strcmp(current->type[index], "int") == 0 && strcmp($4.type, "int") == 0){
                        printf("do int assign\n");
                        current->intValue[index] = $4.i;

                        if(strcmp(temp->name, "main") == 0){
                            write("putstatic int ");
                            fprintf(fout, "%s.%s\n", programName, $2);
                        }
                        else{
                            write("istore ");
                            fprintf(fout, "%d\n", current->stack[index]);
                        }
                    }
                    else if(strcmp(current->type[index], "float") == 0 && strcmp($4.type, "float") == 0){
                        printf("do float assign\n");
                        current->floatValue[index] = $4.f;

                        if(strcmp(temp->name, "main") == 0){
                            write("putstatic float ");
                            fprintf(fout, "%s.%s\n", programName, $2);
                        }
                        else{
                            write("fstore ");
                            fprintf(fout, "%d\n", current->stack[index]);
                        }
                    }
                    else if(strcmp(current->type[index], "string") == 0 && strcmp($4.type, "string") == 0){
                        printf("do string assign\n");
                        current->strValue[index] = $4.s;
                    }
                    else{
                        yyerror("wrong type to assign\n");
                    }
                }
                /*
                index is -1
                */
                else{
                    yyerror("unknown variable for assigning!\n");
                }
            }
        /* 
        Same searching way as ID, but it has range restrict
        */
        |   statement ID '[' expression ']' ASSIGN expression ';'
            {
                /*
                index should be "int"
                */
                if(strcmp($4.type, "int") != 0){
                    yyerror("type of index is not integer\n");
                }
                /*
                index should not be negative
                */
                else if($4.i < 0){
                    yyerror("index is smaller than zero\n");
                }
                else{
                    Node* temp;
                    int index = -1;

                    temp = stack.last;
                    index = lookup(&temp->ptr, $2);

                    while(index == -1 && temp->previous != NULL){
                        temp = temp->previous;
                        index = lookup(&temp->ptr, $2);
                    }

                    if(index != -1){
                        SymbolTable* current = &temp->ptr;
                        /*
                        index should not exceed the fixed length
                        */
                        if($4.i > current->arrayLen[index] || $4.i == current->arrayLen[index]){
                            yyerror("index out of range\n");
                        }
                        else if(strcmp(current->type[index], "boolean") == 0 && strcmp($7.type, "boolean") == 0){
                            printf("do boolean assign\n");
                            current->boolValue[index] = $7.b;
                        }
                        else if(strcmp(current->type[index], "int") == 0 && strcmp($7.type, "int") == 0){
                            printf("do int assign\n");
                            current->intValue[index] = $7.i;
                        }
                        else if(strcmp(current->type[index], "float") == 0 && strcmp($7.type, "float") == 0){
                            printf("do float assign\n");
                            current->floatValue[index] = $7.f;
                        }
                        else if(strcmp(current->type[index], "string") == 0 && strcmp($7.type, "string") == 0){
                            printf("do string assign\n");
                            current->strValue[index] = $7.s;
                        }
                        else{
                            yyerror("wrong type to assign\n");
                        }
                    }
                    else{
                        yyerror("unknown variable for assigning!\n");
                    }
                }
            }
        |   statement PRINT 
            {
                write("getstatic java.io.PrintStream java.lang.System.out\n");
            }
            expression ';'
            {
                printf("doing PRINT operation\n");

                if(strcmp("boolean", $4.type) == 0){
                    write("invokevirtual void java.io.PrintStream.print(boolean)\n");
                }
                else if(strcmp("int", $4.type) == 0){
                    write("invokevirtual void java.io.PrintStream.print(int)\n");
                }
                else if(strcmp("float", $4.type) == 0){
                    write("invokevirtual void java.io.PrintStream.print(float)\n");
                }
                else if(strcmp("string", $4.type) == 0){
                    write("invokevirtual void java.io.PrintStream.print(java.lang.String)\n");
                }
            }
        |   statement PRINTLN 
            {
                write("getstatic java.io.PrintStream java.lang.System.out\n");
            }
            expression ';'
            {
                printf("doing PRINTLN operation\n");

                if(strcmp("boolean", $4.type) == 0){
                    write("invokevirtual void java.io.PrintStream.println(boolean)\n");
                }
                else if(strcmp("int", $4.type) == 0){
                    write("invokevirtual void java.io.PrintStream.println(int)\n");
                }
                else if(strcmp("float", $4.type) == 0){
                    write("invokevirtual void java.io.PrintStream.println(float)\n");
                }
                else if(strcmp("string", $4.type) == 0){
                    write("invokevirtual void java.io.PrintStream.println(java.lang.String)\n");
                }
            }
        /* 
        About the ID in read operation,
        because the nontermainal "expression" also include ID,
        i just use expression deirectly. 
        */
        |   statement READ expression ';'
            {
                printf("doing READ operation\n");
            }
        |   statement RETURN ';'
            {
                write("return\n");
            }
        |   statement RETURN expression ';'
            {
                /* 
                return should only be appear when procedure declaration 
                */
                if(inProcedure == 0){
                    yyerror("try return something in PROGRAM\n");
                }
                else if(inProcedure == 1){
                    /* 
                    in procedure declaration, the last one in funArray is the current one 
                    */
                    if(strcmp($3.type, funArray[total_fun_index - 1].returnType) != 0){
                        yyerror("return type is not the same\n");
                    }
                    else{
                        if(strcmp($3.type, "float") == 0){
                            write("freturn\n");
                        }
                        else{
                            write("ireturn\n");
                        }
                    }
                }
            }
        |   statement IF expression THEN 
            {
                if(strcmp($3.type, "boolean") != 0){
                    yyerror("condition is not boolean\n");
                }
                /*
                "if" is a new scope, so i push_back a table for it.
                Also "while" and "for" loop are, too.
                */
                printf("in If:\n");
                inIf += 1;
                push_back(&stack, "if");
                stack.last->ptr.stackIndex = stack.last->previous->ptr.stackIndex;

                write("ifeq ");
                //fprintf(fout, "Lfalse\n");
                fprintf(fout, "L");
                fprintf(fout, "%d\n", labelNum);
                labelStack[labelStackIndex] = labelNum;
                labelStackIndex++;
                isLabelUsed[labelNum] = 1;
                labelNum++;
            }
            block 
            {
                write("goto ");
                //fprintf(fout, "Lexit\n");
                fprintf(fout, "L");
                fprintf(fout, "%d\n", labelNum);
                labelStack[labelStackIndex] = labelNum;
                labelStackIndex++;
                isLabelUsed[labelNum] = 1;
                labelNum++;
            }
            else_statement
            {
                if(strcmp($3.type, "boolean") == 0){
                    printf("done if condition\n");
                }
            }
        |   statement WHILE 
            {
                //write("Lbegin:\n");
                write("L");
                fprintf(fout, "%d:\n", labelNum);
                labelStack[labelStackIndex] = labelNum;
                labelStackIndex++;
                isLabelUsed[labelNum] = 1;
                labelNum++;
            }
            expression 
            {
                if(strcmp($4.type, "boolean") != 0){
                    yyerror("condition is not boolean\n");
                }
                printf("in while:\n");
                inWhile += 1;
                push_back(&stack, "while");
                stack.last->ptr.stackIndex = stack.last->previous->ptr.stackIndex;

                //write("ifeq Lexit\n");
                write("ifeq L");
                fprintf(fout, "%d\n", labelNum);
                labelStack[labelStackIndex] = labelNum;
                labelStackIndex++;
                isLabelUsed[labelNum] = 1;
                labelNum++;
            }
            LOOP block END LOOP ';'
            {
                if(strcmp($4.type, "boolean") == 0){
                    printf("done while operation\n");
                }
                inWhile -= 1;

                //write("goto Lbegin\n");
                write("goto L");
                fprintf(fout, "%d\n", labelStack[labelStackIndex - 2]);
                //write("Lexit:\n");
                write("L");
                fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                labelStackIndex -= 2;
                write("nop\n");
            }
        |   statement FOR 
            {
                printf("in for:\n");
                inFor += 1;
                push_back(&stack, "for");
                stack.last->ptr.stackIndex = stack.last->previous->ptr.stackIndex;
            }
            /*
            the same searching way as ID
            */
            '(' ID IN INT '.' '.' INT ')' 
            {
                Node* temp;
                int index = -1;
                
                temp = stack.last;
                index = lookup(&temp->ptr, $5);

                while(index == -1 && temp->previous != NULL){
                    temp = temp->previous;
                    index = lookup(&temp->ptr, $5);
                }

                if(index != -1){
                    SymbolTable* current = &temp->ptr;
                    if(current->isConstant[index] == 1){
                        yyerror("try use a constant for iteration !\n");
                    }
                    else if(strcmp(current->type[index], "int") == 0){
                        printf("variable \"%s\" in %s declare\n", $5, temp->name);

                        write("sipush ");
                        fprintf(fout, "%d\n", $7);
                        if(strcmp(temp->name, "main") == 0){
                            write("putstatic int ");
                            fprintf(fout, "%s.%s\n", programName, $5);
                        }
                        else{
                            write("istore ");
                            fprintf(fout, "%d\n", current->stack[index]);   
                        }
                        //write("Lbegin:\n");
                        write("L");
                        fprintf(fout, "%d:\n", labelNum);
                        labelStack[labelStackIndex] = labelNum;
                        labelStackIndex++;
                        isLabelUsed[labelNum] = 1;
                        labelNum++;
                        if(strcmp(temp->name, "main") == 0){
                            write("getstatic int ");
                            fprintf(fout, "%s.%s\n", programName, $5);
                        }
                        else{
                            write("iload ");
                            fprintf(fout, "%d\n", current->stack[index]); 
                        }
                        write("sipush ");
                        fprintf(fout, "%d\n", $10);
                        write("isub\n");

                        if($7 < $10){
                            //write("ifle Ltrue\n");
                            write("ifle L");
                            fprintf(fout, "%d\n", labelNum);
                            labelStack[labelStackIndex] = labelNum;
                            labelStackIndex++;
                            isLabelUsed[labelNum] = 1;
                            labelNum++;
                        }
                        else{
                            //write("ifge Ltrue\n");
                            write("ifge L");
                            fprintf(fout, "%d\n", labelNum);
                            labelStack[labelStackIndex] = labelNum;
                            labelStackIndex++;
                            isLabelUsed[labelNum] = 1;
                            labelNum++;
                        }
                        write("iconst_0\n");
                        //write("goto Lfalse\n");
                        write("goto L");
                        fprintf(fout, "%d\n", labelNum);
                        labelStack[labelStackIndex] = labelNum;
                        labelStackIndex++;
                        isLabelUsed[labelNum] = 1;
                        labelNum++;
                        //write("Ltrue:\n");
                        write("L");
                        fprintf(fout, "%d:\n", labelStack[labelStackIndex - 2]);
                        write("iconst_1\n");
                        //write("Lfalse:\n");
                        write("L");
                        fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                        labelStackIndex -= 2;
                    }
                    else{
                        yyerror("wrong type for iteration\n");
                    }
                }
                /*
                index is -1
                */
                else{
                    yyerror("unknown variable for iteration!\n");
                }
            }
            LOOP 
            {
                //write("ifeq Lexit\n");
                write("ifeq L");
                fprintf(fout, "%d\n", labelNum);
                labelStack[labelStackIndex] = labelNum;
                labelStackIndex++;
                isLabelUsed[labelNum] = 1;
                labelNum++;
            }
            block END LOOP ';'
            {   
                if($7 < 0 || $10 < 0){
                    yyerror("the number in for loop cannot be negative!\n");
                }
                else{
                    printf("done for operation\n");
                }
                inFor -= 1;

                Node* temp;
                int index = -1;
                
                temp = stack.last;
                index = lookup(&temp->ptr, $5);

                while(index == -1 && temp->previous != NULL){
                    temp = temp->previous;
                    index = lookup(&temp->ptr, $5);
                }

                if(index != -1){
                    SymbolTable* current = &temp->ptr;
                    if(current->isConstant[index] == 1){
                        yyerror("try use a constant for iteration !\n");
                    }
                    else if(strcmp(current->type[index], "int") == 0){
                        if(strcmp(temp->name, "main") == 0){
                            write("getstatic int ");
                            fprintf(fout, "%s.%s\n", programName, $5);
                        }
                        else{
                            write("iload ");
                            fprintf(fout, "%d\n", current->stack[index]); 
                        }
                        write("sipush 1\n");
                        if($7 < $10){
                            write("iadd\n");
                        }
                        else{
                            write("isub\n");
                        }
                        if(strcmp(temp->name, "main") == 0){
                            write("putstatic int ");
                            fprintf(fout, "%s.%s\n", programName, $5);
                        }
                        else{
                            write("istore ");
                            fprintf(fout, "%d\n", current->stack[index]);
                        }
                        //write("goto Lbegin\n");
                        write("goto L");
                        fprintf(fout, "%d\n", labelStack[labelStackIndex - 2]);
                        //write("Lexit:\n");
                        write("L");
                        fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                        labelStackIndex -= 2;
                        write("nop\n");
                    }
                    else{
                        yyerror("wrong type for iteration\n");
                    }
                }
                /*
                index is -1
                */
                else{
                    yyerror("unknown variable for iteration!\n");
                }
            }
        |   statement called_procedure ';'          // called a function with args
        |   statement ID ';'                        // called a function without args
            {
                // check function array
                char* RETURN_TYPE;
                int i;
                int exist = 0;
                for(i = 0; i < total_fun_index; i++){
                    if(strcmp($2, funArray[i].name) == 0){
                        RETURN_TYPE = funArray[i].returnType;
                        exist = 1;
                        break;
                    }
                }

                // no such fun
                if(exist == 0){
                    InvocationArg* ptr = (InvocationArg*) malloc(sizeof(InvocationArg));
                    ptr->name = "error";
                    ptr->total_arg_index = 0;
                    ptr->error = 1;
                    calledProcedure = *ptr;
                    yyerror("no such function\n");
                }
                // it exists
                else{
                    InvocationArg* ptr = (InvocationArg*) malloc(sizeof(InvocationArg));
                    ptr->name = $2;
                    ptr->total_arg_index = 0;
                    ptr->error = 0;
                    calledProcedure = *ptr;

                    if(strcmp(RETURN_TYPE, "NULL") == 0){
                        write("invokestatic void ");
                    }
                    else if(strcmp(RETURN_TYPE, "int") == 0){
                        write("invokestatic int ");
                    }
                    fprintf(fout, "%s.%s()\n", programName, $2);
                }

                if(calledProcedure.error == 0){
                    printf("%s successfully done\n", calledProcedure.name);
                }
            }

else_statement: ELSE 
                {
                    printf("in Else:\n");
                    /*
                    "else" is also another block
                    */
                    push_back(&stack, "else");
                    stack.last->ptr.stackIndex = stack.last->previous->ptr.stackIndex;

                    //write("Lfalse:\n");
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 2]);
                    write("nop\n");
                }
                block END IF ';'
                {
                    inIf -= 1;

                    //write("Lexit:\n");
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                    labelStackIndex -= 2;
                    write("nop\n");
                }
            |   END IF ';'
                {
                    inIf -= 1;

                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 2]);
                    write("goto L");
                    fprintf(fout, "%d\n", labelStack[labelStackIndex - 1]);
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                    labelStackIndex -= 2;
                    write("nop\n");
                }

/* 
simple statement, all are the same action as statement 
*/
single_statement:   ID ASSIGN expression ';'
                    {
                        Node* temp;
                        int index = -1;

                        temp = stack.last;
                        index = lookup(&temp->ptr, $1);

                        while(index == -1 && temp->previous != NULL){
                            temp = temp->previous;
                            index = lookup(&temp->ptr, $1);
                        }

                        if(index != -1){
                            SymbolTable* current = &temp->ptr;
                            if(current->isConstant[index] == 1){
                                yyerror("assign to constant variable !\n");
                            }
                            else{
                                if(strcmp(current->type[index], "boolean") == 0 && strcmp($3.type, "boolean") == 0){
                                    printf("do boolean assign\n");
                                    current->boolValue[index] = $3.b;

                                    if(strcmp(temp->name, "main") == 0){
                                        write("putstatic int ");
                                        fprintf(fout, "%s.%s\n", programName, $1);
                                    }
                                    else{
                                        write("istore ");
                                        fprintf(fout, "%d\n", current->stack[index]);
                                    }
                                }
                                else if(strcmp(current->type[index], "int") == 0 && strcmp($3.type, "int") == 0){
                                    printf("do int assign\n");
                                    current->intValue[index] = $3.i;

                                    if(strcmp(temp->name, "main") == 0){
                                        write("putstatic int ");
                                        fprintf(fout, "%s.%s\n", programName, $1);
                                    }
                                    else{
                                        write("istore ");
                                        fprintf(fout, "%d\n", current->stack[index]);
                                    }
                                }
                                else if(strcmp(current->type[index], "float") == 0 && strcmp($3.type, "float") == 0){
                                    printf("do float assign\n");
                                    current->floatValue[index] = $3.f;

                                    if(strcmp(temp->name, "main") == 0){
                                        write("putstatic float ");
                                        fprintf(fout, "%s.%s\n", programName, $1);
                                    }
                                    else{
                                        write("fstore ");
                                        fprintf(fout, "%d\n", current->stack[index]);
                                    }
                                }
                                else if(strcmp(current->type[index], "string") == 0 && strcmp($3.type, "string") == 0){
                                    printf("do string assign\n");
                                    current->strValue[index] = $3.s;
                                }
                                else{
                                    yyerror("wrong type to assign\n");
                                }
                            }
                        }
                        else{
                            yyerror("unknown variable for assigning!\n");
                        }
                    }
                |   ID '[' expression ']' ASSIGN expression ';'
                    {
                        if(strcmp($3.type, "int") != 0){
                            yyerror("type of index is not integer\n");
                        }
                        else{
                            if($3.i < 0){
                                yyerror("index is smaller than zero\n");
                            }
                            else{
                                Node* temp;
                                int index = -1;
                                /* If in program right now, check main table */
                                temp = stack.last;
                                index = lookup(&temp->ptr, $1);

                                while(index == -1 && temp->previous != NULL){
                                    temp = temp->previous;
                                    index = lookup(&temp->ptr, $1);
                                }

                                if(index != -1){
                                    SymbolTable* current = &temp->ptr;
                                    if($3.i > current->arrayLen[index] || $3.i == current->arrayLen[index]){
                                        yyerror("index out of range\n");
                                    }
                                    else{
                                        if(strcmp(current->type[index], "boolean") == 0 && strcmp($6.type, "boolean") == 0){
                                            printf("do boolean assign\n");
                                            current->boolValue[index] = $6.b;
                                        }
                                        else if(strcmp(current->type[index], "int") == 0 && strcmp($6.type, "int") == 0){
                                            printf("do int assign\n");
                                            current->intValue[index] = $6.i;
                                        }
                                        else if(strcmp(current->type[index], "float") == 0 && strcmp($6.type, "float") == 0){
                                            printf("do float assign\n");
                                            current->floatValue[index] = $6.f;
                                        }
                                        else if(strcmp(current->type[index], "string") == 0 && strcmp($6.type, "string") == 0){
                                            printf("do string assign\n");
                                            current->strValue[index] = $6.s;
                                        }
                                        else{
                                            yyerror("wrong type to assign\n");
                                        }
                                    }
                                }
                                else{
                                    yyerror("unknown variable for assigning!\n");
                                }
                            }
                        }
                    }
                |   PRINT 
                    {
                        write("getstatic java.io.PrintStream java.lang.System.out\n");
                    }
                    expression ';'
                    {
                        printf("doing PRINT operation\n");
                        if(strcmp("boolean", $3.type) == 0){
                            write("invokevirtual void java.io.PrintStream.print(boolean)\n");
                        }
                        else if(strcmp("int", $3.type) == 0){
                            write("invokevirtual void java.io.PrintStream.print(int)\n");
                        }
                        else if(strcmp("float", $3.type) == 0){
                            write("invokevirtual void java.io.PrintStream.print(float)\n");
                        }
                        else if(strcmp("string", $3.type) == 0){
                            write("invokevirtual void java.io.PrintStream.print(java.lang.String)\n");
                        }
                    }
                |   PRINTLN
                    {
                        write("getstatic java.io.PrintStream java.lang.System.out\n");
                    }
                    expression ';'
                    {
                        printf("doing PRINTLN operation\n");
                        if(strcmp("boolean", $3.type) == 0){
                            write("invokevirtual void java.io.PrintStream.println(boolean)\n");
                        }
                        else if(strcmp("int", $3.type) == 0){
                            write("invokevirtual void java.io.PrintStream.println(int)\n");
                        }
                        else if(strcmp("float", $3.type) == 0){
                            write("invokevirtual void java.io.PrintStream.println(float)\n");
                        }
                        else if(strcmp("string", $3.type) == 0){
                            write("invokevirtual void java.io.PrintStream.println(java.lang.String)\n");
                        }
                    }
                |   READ expression ';'
                    {
                        printf("doing READ operation\n");
                    }
                |   RETURN ';'
                    {
                        write("return\n");
                    }
                |   RETURN expression ';'
                    {
                        if(inProcedure == 0){
                            yyerror("try return something in PROGRAM\n");
                        }
                        else if(inProcedure == 1){
                            if(strcmp($2.type, funArray[total_fun_index - 1].returnType) != 0){
                                yyerror("return type is not the same\n");
                            }
                            else{
                                if(strcmp($2.type, "float") == 0){
                                    write("freturn\n");
                                }
                                else{
                                    write("ireturn\n");
                                }
                            }
                        }
                    }
                |   IF expression THEN 
                    {
                        if(strcmp($2.type, "boolean") != 0){
                            yyerror("condition is not boolean\n");
                        }
                        printf("in If:\n");
                        inIf += 1;
                        push_back(&stack, "if");
                        stack.last->ptr.stackIndex = stack.last->previous->ptr.stackIndex;

                        write("ifeq ");
                        //fprintf(fout, "Lfalse\n");
                        fprintf(fout, "L");
                        fprintf(fout, "%d\n", labelNum);
                        labelStack[labelStackIndex] = labelNum;
                        labelStackIndex++;
                        isLabelUsed[labelNum] = 1;
                        labelNum++;
                    }
                    block 
                    {
                        write("goto ");
                        //fprintf(fout, "Lexit\n");
                        fprintf(fout, "L");
                        fprintf(fout, "%d\n", labelNum);
                        labelStack[labelStackIndex] = labelNum;
                        labelStackIndex++;
                        isLabelUsed[labelNum] = 1;
                        labelNum++;
                    }
                    else_statement
                    {
                        if(strcmp($2.type, "boolean") == 0){
                            printf("done if condition\n");
                        }
                    }
                |   WHILE 
                    {
                        //write("Lbegin:\n");
                        write("L");
                        fprintf(fout, "%d:\n", labelNum);
                        labelStack[labelStackIndex] = labelNum;
                        labelStackIndex++;
                        isLabelUsed[labelNum] = 1;
                        labelNum++;
                    }
                    expression 
                    {
                        if(strcmp($3.type, "boolean") != 0){
                            yyerror("condition is not boolean\n");
                        }
                        printf("in while:\n");
                        inWhile += 1;
                        push_back(&stack, "while");
                        stack.last->ptr.stackIndex = stack.last->previous->ptr.stackIndex;

                        //write("ifeq Lexit\n");
                        write("ifeq L");
                        fprintf(fout, "%d\n", labelNum);
                        labelStack[labelStackIndex] = labelNum;
                        labelStackIndex++;
                        isLabelUsed[labelNum] = 1;
                        labelNum++;
                    }
                    LOOP block END LOOP ';'
                    {
                        if(strcmp($3.type, "boolean") == 0){
                            printf("done while operation\n");
                        }
                        inWhile -= 1;
                        //write("goto Lbegin\n");
                        write("goto L");
                        fprintf(fout, "%d\n", labelStack[labelStackIndex - 2]);
                        //write("Lexit:\n");
                        write("L");
                        fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                        labelStackIndex -= 2;
                        write("nop\n");
                    }
                |   FOR 
                    {
                        printf("in for:\n");
                        inFor += 1;
                        push_back(&stack, "for");
                        stack.last->ptr.stackIndex = stack.last->previous->ptr.stackIndex;
                    }
                    '(' ID IN INT '.' '.' INT ')' 
                    {
                        Node* temp;
                        int index = -1;
                        
                        temp = stack.last;
                        index = lookup(&temp->ptr, $4);

                        while(index == -1 && temp->previous != NULL){
                            temp = temp->previous;
                            index = lookup(&temp->ptr, $4);
                        }

                        if(index != -1){
                            SymbolTable* current = &temp->ptr;
                            if(current->isConstant[index] == 1){
                                yyerror("try use a constant for iteration !\n");
                            }
                            else if(strcmp(current->type[index], "int") == 0){
                                printf("variable \"%s\" in %s declare\n", $4, temp->name);

                                write("sipush ");
                                fprintf(fout, "%d\n", $6);
                                if(strcmp(temp->name, "main") == 0){
                                    write("putstatic int ");
                                    fprintf(fout, "%s.%s\n", programName, $4);
                                }
                                else{
                                    write("istore ");
                                    fprintf(fout, "%d\n", current->stack[index]);   
                                }
                                //write("Lbegin:\n");
                                write("L");
                                fprintf(fout, "%d:\n", labelNum);
                                labelStack[labelStackIndex] = labelNum;
                                labelStackIndex++;
                                isLabelUsed[labelNum] = 1;
                                labelNum++;
                                if(strcmp(temp->name, "main") == 0){
                                    write("getstatic int ");
                                    fprintf(fout, "%s.%s\n", programName, $4);
                                }
                                else{
                                    write("iload ");
                                    fprintf(fout, "%d\n", current->stack[index]); 
                                }
                                write("sipush ");
                                fprintf(fout, "%d\n", $9);
                                write("isub\n");

                                if($6 < $9){
                                    //write("ifle Ltrue\n");
                                    write("ifle L");
                                    fprintf(fout, "%d\n", labelNum);
                                    labelStack[labelStackIndex] = labelNum;
                                    labelStackIndex++;
                                    isLabelUsed[labelNum] = 1;
                                    labelNum++;
                                }
                                else{
                                    //write("ifge Ltrue\n");
                                    write("ifge L");
                                    fprintf(fout, "%d\n", labelNum);
                                    labelStack[labelStackIndex] = labelNum;
                                    labelStackIndex++;
                                    isLabelUsed[labelNum] = 1;
                                    labelNum++;
                                }
                                write("iconst_0\n");
                                //write("goto Lfalse\n");
                                write("goto L");
                                fprintf(fout, "%d\n", labelNum);
                                labelStack[labelStackIndex] = labelNum;
                                labelStackIndex++;
                                isLabelUsed[labelNum] = 1;
                                labelNum++;
                                //write("Ltrue:\n");
                                write("L");
                                fprintf(fout, "%d:\n", labelStack[labelStackIndex - 2]);
                                write("iconst_1\n");
                                //write("Lfalse:\n");
                                write("L");
                                fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                                labelStackIndex -= 2;
                            }
                            else{
                                yyerror("wrong type for iteration\n");
                            }
                        }
                        /*
                        index is -1
                        */
                        else{
                            yyerror("unknown variable for iteration!\n");
                        }
                    }
                    LOOP 
                    {
                        //write("ifeq Lexit\n");
                        write("ifeq L");
                        fprintf(fout, "%d\n", labelNum);
                        labelStack[labelStackIndex] = labelNum;
                        labelStackIndex++;
                        isLabelUsed[labelNum] = 1;
                        labelNum++;
                    }
                    block END LOOP ';'
                    {    
                        if($6 < 0 || $9 < 0){
                            yyerror("the number in for loop cannot be negative!\n");
                        }
                        else{
                            printf("done for operation\n");
                        }
                        inFor -= 1;

                        Node* temp;
                        int index = -1;
                        
                        temp = stack.last;
                        index = lookup(&temp->ptr, $4);

                        while(index == -1 && temp->previous != NULL){
                            temp = temp->previous;
                            index = lookup(&temp->ptr, $4);
                        }

                        if(index != -1){
                            SymbolTable* current = &temp->ptr;
                            if(current->isConstant[index] == 1){
                                yyerror("try use a constant for iteration !\n");
                            }
                            else if(strcmp(current->type[index], "int") == 0){
                                if(strcmp(temp->name, "main") == 0){
                                    write("getstatic int ");
                                    fprintf(fout, "%s.%s\n", programName, $4);
                                }
                                else{
                                    write("iload ");
                                    fprintf(fout, "%d\n", current->stack[index]); 
                                }
                                write("sipush 1\n");
                                if($6 < $9){
                                    write("iadd\n");
                                }
                                else{
                                    write("isub\n");
                                }
                                if(strcmp(temp->name, "main") == 0){
                                    write("putstatic int ");
                                    fprintf(fout, "%s.%s\n", programName, $4);
                                }
                                else{
                                    write("istore ");
                                    fprintf(fout, "%d\n", current->stack[index]);
                                }
                                //write("goto Lbegin\n");
                                write("goto L");
                                fprintf(fout, "%d\n", labelStack[labelStackIndex - 2]);
                                //write("Lexit:\n");
                                write("L");
                                fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                                labelStackIndex -= 2;
                                write("nop\n");
                            }
                            else{
                                yyerror("wrong type for iteration\n");
                            }
                        }
                        /*
                        index is -1
                        */
                        else{
                            yyerror("unknown variable for iteration!\n");
                        }
                    }
                |   called_procedure ';'
                |   ID ';'
                    {
                        char* RETURN_TYPE;
                        int i;
                        int exist = 0;
                        for(i = 0; i < total_fun_index; i++){
                            if(strcmp($1, funArray[i].name) == 0){
                                RETURN_TYPE = funArray[i].returnType;
                                exist = 1;
                                break;
                            }
                        }

                        if(exist == 0){
                            InvocationArg* ptr = (InvocationArg*) malloc(sizeof(InvocationArg));
                            ptr->name = "error";
                            ptr->total_arg_index = 0;
                            ptr->error = 1;
                            calledProcedure = *ptr;
                            yyerror("no such function\n");
                        }
                        else{
                            InvocationArg* ptr = (InvocationArg*) malloc(sizeof(InvocationArg));
                            ptr->name = $1;
                            ptr->total_arg_index = 0;
                            ptr->error = 0;
                            calledProcedure = *ptr;

                            if(strcmp(RETURN_TYPE, "NULL") == 0){
                                write("invokestatic void ");
                            }
                            else if(strcmp(RETURN_TYPE, "int") == 0){
                                write("invokestatic int ");
                            }
                            fprintf(fout, "%s.%s()\n", programName, $1);
                        }

                        if(calledProcedure.error == 0){
                            printf("%s successfully done\n", calledProcedure.name);
                        }
                    }

/*
user call fun with args
*/
called_procedure:   ID '('
                    {
                        /*
                        Search in funArray
                        */
                        int i;
                        int exist = 0;
                        for(i = 0; i < total_fun_index; i++){
                            if(strcmp($1, funArray[i].name) == 0){
                                exist = 1;
                                break;
                            }
                        }

                        /*
                        no such function, we state that this already an error
                        */
                        if(exist == 0){
                            InvocationArg* ptr = (InvocationArg*) malloc(sizeof(InvocationArg));
                            ptr->name = "error";
                            ptr->total_arg_index = 0;
                            ptr->error = 1;
                            calledProcedure = *ptr;
                            yyerror("no such function\n");
                        }
                        /*
                        it exists
                        */
                        else{
                            InvocationArg* ptr = (InvocationArg*) malloc(sizeof(InvocationArg));
                            ptr->name = $1;
                            ptr->total_arg_index = 0;
                            ptr->error = 0;
                            calledProcedure = *ptr;
                        }
                    }
                    enter_invocation_arg
                    {
                        /*
                        we set the return type if this fun is still not in error state
                        */
                        if(calledProcedure.error == 0){
                            int i;
                            for(i = 0; i < total_fun_index; i++){
                                if(strcmp(calledProcedure.name, funArray[i].name) == 0){
                                    $$.type = funArray[i].returnType;
                                    break;
                                }
                            }

                            fprintf(fout, ")\n");
                            printf("%s successfully done\n", calledProcedure.name);
                        }
                    }

/* 
do args checking,
if anyinh wrong, just go into error state. 
*/
enter_invocation_arg:   invocation_arg ')'
                        {
                            /*
                            it should not be in error state,
                            if it is, just ignore anything that user types.
                            */
                            if(calledProcedure.error == 0){
                                /*
                                First, we find the corresponding fun
                                */
                                Fun temp;
                                int i;
                                for(i = 0; i < total_fun_index; i++){
                                    if(strcmp(calledProcedure.name, funArray[i].name) == 0){
                                        temp = funArray[i];
                                        break;
                                    }
                                }

                                /*
                                the number of args should be the same
                                */
                                if(temp.argIndex == calledProcedure.total_arg_index){
                                    int j;
                                    /*
                                    the type of each args should be the same as we were declaring
                                    */
                                    write("invokestatic int ");
                                    fprintf(fout, "%s.%s(", programName, temp.name);

                                    for(j = 0; j < temp.argIndex; j++){
                                        if(strcmp(temp.type[j], calledProcedure.type[j]) != 0){
                                            calledProcedure.error = 1;
                                            yyerror("an argument type is unmatch\n");
                                            break;
                                        }
                                        else{
                                            fprintf(fout, "%s", temp.type[j]);
                                            if(temp.argIndex != 1 && j != temp.argIndex - 1){
                                                fprintf(fout, ", ");
                                            }
                                        }
                                    }
                                }
                                else{
                                    calledProcedure.error = 1;
                                    yyerror("the number of arguments is wrong\n");
                                }
                            }
                        }

/* 
we record the args that user type in this nontermainal, 
and it will be easy for the after args type checking 

it should not be in error state,
if it is, just ignore anything that user types.
*/
invocation_arg: expression
                {
                    if(calledProcedure.error == 0){
                        insertInvocationArg(&calledProcedure, $1.type);
                    }
                }
            |   invocation_arg ',' expression
                {
                    if(calledProcedure.error == 0){
                        insertInvocationArg(&calledProcedure, $3.type);
                    }
                }

expression: '('expression')'                
            {
                $$ = $2;
            }
        |   expression '+' expression
            {
                if(strcmp($1.type, "int") == 0 && strcmp($3.type, "int") == 0){
                    $$.type = "int";
                    $$.i = $1.i + $3.i;
                    printf("done int add operation\n");

                    if(isConstant == 0 && inGlobal == 0){
                        write("iadd\n");
                    }
                }
                else if(strcmp($1.type, "float") == 0 && strcmp($3.type, "float") == 0){
                    $$.type = "float";
                    $$.f = $1.f + $3.f;
                    printf("done float add operation\n");

                    if(isConstant == 0 && inGlobal == 0){
                        write("fadd\n");
                    }
                }
                else if(strcmp($1.type, "float") == 0 && strcmp($3.type, "int") == 0){
                    $$.type = "float";
                    $$.f = $1.f + (float)$3.i;
                    printf("done float & int add operation\n");

                    if(isConstant == 0 && inGlobal == 0){
                        write("i2f\n");
                        write("fadd\n");
                    }
                }
                else if(strcmp($1.type, "int") == 0 && strcmp($3.type, "float") == 0){
                    $$.type = "float";
                    $$.f = (float)$1.i + $3.f;
                    printf("done int & float add operation\n");
                }
                else{
                    yyerror("Type unmatch\n");
                }
            }
        |   expression '-' expression
            {
                if(strcmp($1.type, "int") == 0 && strcmp($3.type, "int") == 0){
                    $$.type = "int";
                    $$.i = $1.i - $3.i;
                    printf("done int sub operation\n");

                    if(isConstant == 0 && inGlobal == 0){
                        write("isub\n");
                    }
                }
                else if(strcmp($1.type, "float") == 0 && strcmp($3.type, "float") == 0){
                    $$.type = "float";
                    $$.f = $1.f - $3.f;
                    printf("done float sub operation\n");

                    if(isConstant == 0 && inGlobal == 0){
                        write("fsub\n");
                    }
                }
                else if(strcmp($1.type, "float") == 0 && strcmp($3.type, "int") == 0){
                    $$.type = "float";
                    $$.f = $1.f - (float)$3.i;
                    printf("done float & int sub operation\n");

                    if(isConstant == 0 && inGlobal == 0){
                        write("i2f\n");
                        write("fsub\n");
                    }
                }
                else if(strcmp($1.type, "int") == 0 && strcmp($3.type, "float") == 0){
                    $$.type = "float";
                    $$.f = (float)$1.i - $3.f;
                    printf("done int & float sub operation\n");
                }
                else{
                    yyerror("Type unmatch\n");
                }
            }
        |   expression '*' expression
            {
                if(strcmp($1.type, "int") == 0 && strcmp($3.type, "int") == 0){
                    $$.type = "int";
                    $$.i = $1.i * $3.i;
                    printf("done int mul operation\n");

                    if(isConstant == 0 && inGlobal == 0){
                        write("imul\n");
                    }
                }
                else if(strcmp($1.type, "float") == 0 && strcmp($3.type, "float") == 0){
                    $$.type = "float";
                    $$.f = $1.f * $3.f;
                    printf("done float mul operation\n");

                    if(isConstant == 0 && inGlobal == 0){
                        write("fmul\n");
                    }
                }
                else if(strcmp($1.type, "float") == 0 && strcmp($3.type, "int") == 0){
                    $$.type = "float";
                    $$.f = $1.f * (float)$3.i;
                    printf("done float & int mul operation\n");
                }
                else if(strcmp($1.type, "int") == 0 && strcmp($3.type, "float") == 0){
                    $$.type = "float";
                    $$.f = (float)$1.i * $3.f;
                    printf("done int & float mul operation\n");

                    if(isConstant == 0 && inGlobal == 0){
                        write("i2f\n");
                        write("fmul\n");
                    }
                }
                else{
                    yyerror("Type unmatch\n");
                }
            }
        |   expression '/' expression
            {
                if(strcmp($1.type, "int") == 0 && strcmp($3.type, "int") == 0){
                    $$.type = "int";
                    $$.i = $1.i / $3.i;
                    printf("done int div operation\n");

                    if(isConstant == 0 && inGlobal == 0){
                        write("idiv\n");
                    }
                }
                else if(strcmp($1.type, "float") == 0 && strcmp($3.type, "float") == 0){
                    $$.type = "float";
                    $$.f = $1.f / $3.f;
                    printf("done float div operation\n");

                    if(isConstant == 0 && inGlobal == 0){
                        write("fdiv\n");
                    }
                }
                else if(strcmp($1.type, "float") == 0 && strcmp($3.type, "int") == 0){
                    $$.type = "float";
                    $$.f = $1.f / (float)$3.i;
                    printf("done float & int div operation\n");

                    if(isConstant == 0 && inGlobal == 0){
                        write("i2f\n");
                        write("fdiv\n");
                    }
                }
                else if(strcmp($1.type, "int") == 0 && strcmp($3.type, "float") == 0){
                    $$.type = "float";
                    $$.f = (float)$1.i / $3.f;
                    printf("done int & float div operation\n");
                }
                else{
                    yyerror("Type unmatch\n");
                }
            }
        |   expression '%' expression
            {
                if(strcmp($1.type, "int") == 0 && strcmp($3.type, "int") == 0){
                    $$.type = "int";
                    $$.i = $1.i % $3.i;
                    printf("done int mod operation\n");

                    if(isConstant == 0 && inGlobal == 0){
                        write("irem\n");
                    }
                }
                else{
                    yyerror("Type unmatch\n");
                }
            }
        |   '-'expression  %prec UMINUS    
            {
                if(strcmp($2.type, "int") == 0) {
                    $$.type = "int";
                    $$.i = -1 * $2.i;
                    printf("done int negative operation\n");

                    write("ineg\n");
                }
                else if(strcmp($2.type, "float") == 0){
                    $$.type = "float";
                    $$.f = -1 * $2.f;
                    printf("done float negative operation\n");

                    write("fneg\n");
                }
                else{
                    yyerror("need to be int or float\n");
                }
            }
        |   expression LT expression
            {
                if(strcmp($1.type, "int") == 0 && strcmp($3.type, "int") == 0){
                    $$.type = "boolean";
                    if($1.i < $3.i){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }

                    write("isub\n");
                    write("iflt L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("iconst_0\n");
                    write("goto L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 2]);
                    write("iconst_1\n");
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                    labelStackIndex -= 2;
                }
                else if(strcmp($1.type, "float") == 0 && strcmp($3.type, "float") == 0){
                    $$.type = "boolean";
                    if($1.f < $3.f){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }

                    write("fcmpl\n");
                    write("iflt L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("iconst_0\n");
                    write("goto L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 2]);
                    write("iconst_1\n");
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                    labelStackIndex -= 2;
                }
                else if(strcmp($1.type, "float") == 0 && strcmp($3.type, "int") == 0){
                    $$.type = "boolean";
                    if($1.f < (float)$3.i){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }

                    write("i2f\n");
                    write("fcmpl\n");
                    write("iflt L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("iconst_0\n");
                    write("goto L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 2]);
                    write("iconst_1\n");
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                    labelStackIndex -= 2;
                }
                else if(strcmp($1.type, "int") == 0 && strcmp($3.type, "float") == 0){
                    $$.type = "boolean";
                    if((float)$1.i < $3.f){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }
                }
                else{
                    yyerror("Type unmatch\n");
                }
            }
        |   expression LEQ expression
            {
                if(strcmp($1.type, "int") == 0 && strcmp($3.type, "int") == 0){
                    $$.type = "boolean";
                    if($1.i < $3.i || $1.i == $3.i){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }

                    write("isub\n");
                    write("ifle L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("iconst_0\n");
                    write("goto L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 2]);
                    write("iconst_1\n");
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                    labelStackIndex -= 2;
                }
                else if(strcmp($1.type, "float") == 0 && strcmp($3.type, "float") == 0){
                    $$.type = "boolean";
                    if($1.f < $3.f || $1.f == $3.f){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }

                    write("fcmpl\n");
                    write("ifle L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("iconst_0\n");
                    write("goto L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 2]);
                    write("iconst_1\n");
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                    labelStackIndex -= 2;
                }
                else if(strcmp($1.type, "float") == 0 && strcmp($3.type, "int") == 0){
                    $$.type = "boolean";
                    if($1.f < (float)$3.i || $1.f == (float)$3.i){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }
                    
                    write("i2f\n");
                    write("fcmpl\n");
                    write("ifle L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("iconst_0\n");
                    write("goto L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 2]);
                    write("iconst_1\n");
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                    labelStackIndex -= 2;
                }
                else if(strcmp($1.type, "int") == 0 && strcmp($3.type, "float") == 0){
                    $$.type = "boolean";
                    if((float)$1.i < $3.f || (float)$1.i == $3.f){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }
                }
                else{
                    yyerror("Type unmatch\n");
                }
            }
        |   expression EQ expression
            {
                if(strcmp($1.type, "int") == 0 && strcmp($3.type, "int") == 0){
                    $$.type = "boolean";
                    if($1.i == $3.i){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }

                    write("isub\n");
                    write("ifeq L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("iconst_0\n");
                    write("goto L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 2]);
                    write("iconst_1\n");
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                    labelStackIndex -= 2;
                }
                else if(strcmp($1.type, "float") == 0 && strcmp($3.type, "float") == 0){
                    $$.type = "boolean";
                    if($1.f == $3.f){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }

                    write("fcmpl\n");
                    write("ifeq L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("iconst_0\n");
                    write("goto L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 2]);
                    write("iconst_1\n");
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                    labelStackIndex -= 2;
                }
                else if(strcmp($1.type, "float") == 0 && strcmp($3.type, "int") == 0){
                    $$.type = "boolean";
                    if($1.f == (float)$3.i){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }

                    write("i2f\n");
                    write("fcmpl\n");
                    write("ifeq L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("iconst_0\n");
                    write("goto L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 2]);
                    write("iconst_1\n");
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                    labelStackIndex -= 2;
                }
                else if(strcmp($1.type, "int") == 0 && strcmp($3.type, "float") == 0){
                    $$.type = "boolean";
                    if((float)$1.i == $3.f){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }
                }
                else{
                    yyerror("Type unmatch\n");
                }
            }
        |   expression GEQ expression
            {
                if(strcmp($1.type, "int") == 0 && strcmp($3.type, "int") == 0){
                    $$.type = "boolean";
                    if($1.i > $3.i || $1.i == $3.i){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }

                    write("isub\n");
                    write("ifge L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("iconst_0\n");
                    write("goto L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 2]);
                    write("iconst_1\n");
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                    labelStackIndex -= 2;
                }
                else if(strcmp($1.type, "float") == 0 && strcmp($3.type, "float") == 0){
                    $$.type = "boolean";
                    if($1.f > $3.f || $1.f == $3.f){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }

                    write("fcmpl\n");
                    write("ifge L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("iconst_0\n");
                    write("goto L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 2]);
                    write("iconst_1\n");
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                    labelStackIndex -= 2;
                }
                else if(strcmp($1.type, "float") == 0 && strcmp($3.type, "int") == 0){
                    $$.type = "boolean";
                    if($1.f > (float)$3.i || $1.f == (float)$3.i){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }

                    write("i2f\n");
                    write("fcmpl\n");
                    write("ifge L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("iconst_0\n");
                    write("goto L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 2]);
                    write("iconst_1\n");
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                    labelStackIndex -= 2;
                }
                else if(strcmp($1.type, "int") == 0 && strcmp($3.type, "float") == 0){
                    $$.type = "boolean";
                    if((float)$1.i > $3.f || (float)$1.i == $3.f){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }
                }
                else{
                    yyerror("Type unmatch\n");
                }
            }
        |   expression GT expression
            {
                if(strcmp($1.type, "int") == 0 && strcmp($3.type, "int") == 0){
                    $$.type = "boolean";
                    if($1.i > $3.i){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }

                    write("isub\n");
                    write("ifgt L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("iconst_0\n");
                    write("goto L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 2]);
                    write("iconst_1\n");
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                    labelStackIndex -= 2;
                }
                else if(strcmp($1.type, "float") == 0 && strcmp($3.type, "float") == 0){
                    $$.type = "boolean";
                    if($1.f > $3.f){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }

                    write("fcmpl\n");
                    write("ifgt L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("iconst_0\n");
                    write("goto L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 2]);
                    write("iconst_1\n");
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                    labelStackIndex -= 2;
                }
                else if(strcmp($1.type, "float") == 0 && strcmp($3.type, "int") == 0){
                    $$.type = "boolean";
                    if($1.f > (float)$3.i){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }

                    write("i2f\n");
                    write("fcmpl\n");
                    write("ifgt L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("iconst_0\n");
                    write("goto L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 2]);
                    write("iconst_1\n");
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                    labelStackIndex -= 2;
                }
                else if(strcmp($1.type, "int") == 0 && strcmp($3.type, "float") == 0){
                    $$.type = "boolean";
                    if((float)$1.i > $3.f){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }
                }
                else{
                    yyerror("Type unmatch\n");
                }
            }
        |   expression NEQ expression
            {
                if(strcmp($1.type, "int") == 0 && strcmp($3.type, "int") == 0){
                    $$.type = "boolean";
                    if($1.i != $3.i){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }

                    write("isub\n");
                    write("ifne L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("iconst_0\n");
                    write("goto L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 2]);
                    write("iconst_1\n");
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                    labelStackIndex -= 2;
                }
                else if(strcmp($1.type, "float") == 0 && strcmp($3.type, "float") == 0){
                    $$.type = "boolean";
                    if($1.f != $3.f){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }

                    write("fcmpl\n");
                    write("ifne L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("iconst_0\n");
                    write("goto L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 2]);
                    write("iconst_1\n");
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                    labelStackIndex -= 2;
                }
                else if(strcmp($1.type, "float") == 0 && strcmp($3.type, "int") == 0){
                    $$.type = "boolean";
                    if($1.f != (float)$3.i){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }

                    write("i2f\n");
                    write("fcmpl\n");
                    write("ifne L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("iconst_0\n");
                    write("goto L");
                    fprintf(fout, "%d\n", labelNum);
                    labelStack[labelStackIndex] = labelNum;
                    labelStackIndex++;
                    isLabelUsed[labelNum] = 1;
                    labelNum++;
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 2]);
                    write("iconst_1\n");
                    write("L");
                    fprintf(fout, "%d:\n", labelStack[labelStackIndex - 1]);
                    labelStackIndex -= 2;
                }
                else if(strcmp($1.type, "int") == 0 && strcmp($3.type, "float") == 0){
                    $$.type = "boolean";
                    if((float)$1.i != $3.f){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }
                }
                else{
                    yyerror("Type unmatch\n");
                }
            }
        |   expression AND expression
            {
                if(strcmp($1.type, "boolean") == 0 && strcmp($3.type, "boolean") == 0){
                    $$.type = "boolean";
                    if($1.b == 0 || $3.b == 0){
                        $$.b = 0;
                    }
                    else{
                        $$.b = 1;
                    }

                    write("iand\n");
                }
                else{
                    yyerror("Type unmatch\n");
                }
            }
        |   expression OR expression
            {
                if(strcmp($1.type, "boolean") == 0 && strcmp($3.type, "boolean") == 0){
                    $$.type = "boolean";
                    if($1.b == 1 || $3.b == 1){
                        $$.b = 1;
                    }
                    else{
                        $$.b = 0;
                    }

                    write("ior\n");
                }
                else{
                    yyerror("Type unmatch\n");
                }
            }
        |   NOT expression
            {
                if(strcmp($2.type, "boolean") == 0){
                    $$.type = "boolean";
                    if($2.b == 1){
                        $$.b = 0;
                    }
                    else{
                        $$.b = 1;
                    }
                }
                else{
                    yyerror("Type unmatch\n");
                }
            }
        /*
        Same searching way as ID in "statement"
        */
        |   ID '[' expression ']'
            {
                if(strcmp($3.type, "int") != 0){
                    yyerror("type of index is not integer\n");
                }
                else{
                    if($3.i < 0){
                        yyerror("index is smaller than zero\n");
                    }
                    else{
                        Node* temp;
                        int index = -1;
                        
                        temp = stack.last;
                        index = lookup(&temp->ptr, $1);

                        while(index == -1 && temp->previous != NULL){
                            temp = temp->previous;
                            index = lookup(&temp->ptr, $1);
                        }

                        if(index != -1){
                            SymbolTable* current = &temp->ptr;
                            if($3.i > current->arrayLen[index] || $3.i == current->arrayLen[index]){
                                yyerror("index out of range\n");
                            }
                            else{
                                /*
                                nothing wrong, set type
                                */
                                printf("array variable \"%s\" in %s declare\n", $1, temp->name);                              
                                $$.type = current->type[index];
                            }
                        }
                        else{
                            yyerror("unknown variable for assigning!\n");
                        }
                    }
                }
            }
        /* 
        Same searching way as ID in "statement" 
        */
        |   ID
            {
                Node* temp;
                int index = -1;
                
                temp = stack.last;
                index = lookup(&temp->ptr, $1);

                while(index == -1 && temp->previous != NULL){
                    temp = temp->previous;
                    index = lookup(&temp->ptr, $1);
                }

                if(index != -1){
                    /*
                    nothing wrong, set type
                    */
                    SymbolTable* current = &temp->ptr;
                    printf("variable \"%s\" in %s declare\n", $1, temp->name);
                    $$.type = current->type[index];

                    if(strcmp(current->type[index], "boolean") == 0){
                        $$.b = current->boolValue[index];

                        if(current->isConstant[index] == 1){
                            if(current->boolValue[index] == 0){
                                write("iconst_0\n");
                            }
                            else{
                                write("iconst_1\n");
                            }
                        }
                        else{
                            if(strcmp(temp->name, "main") == 0){
                                write("getstatic int ");
                                fprintf(fout, "%s.%s\n", programName, $1);
                            }
                            else{
                                write("iload ");
                                fprintf(fout, "%d\n", current->stack[index]);
                            }
                        }
                    }
                    else if(strcmp(current->type[index], "int") == 0){
                        $$.i = current->intValue[index];

                        if(current->isConstant[index] == 1){
                            write("sipush ");
                            fprintf(fout, "%d\n", current->intValue[index]);
                        }
                        else{
                            if(strcmp(temp->name, "main") == 0){
                                write("getstatic int ");
                                fprintf(fout, "%s.%s\n", programName, $1);
                            }
                            else{
                                write("iload ");
                                fprintf(fout, "%d\n", current->stack[index]);
                            }
                        }
                    }
                    else if(strcmp(current->type[index], "float") == 0){
                        $$.f = current->floatValue[index];

                        if(current->isConstant[index] == 1){
                            write("ldc ");
                            fprintf(fout, "%ff\n", current->floatValue[index]);
                        }
                        else{
                            if(strcmp(temp->name, "main") == 0){
                                write("getstatic float ");
                                fprintf(fout, "%s.%s\n", programName, $1);
                            }
                            else{
                                write("fload ");
                                fprintf(fout, "%d\n", current->stack[index]);
                            }
                        }
                    }
                    else if(strcmp(current->type[index], "string") == 0){
                        $$.s = current->strValue[index];

                        if(current->isConstant[index] == 1){
                            write("ldc \"");
                            fprintf(fout, "%s\"\n", current->strValue[index]);
                        }
                    }
                    /*
                    note that it might a fun called without args
                    */
                    else if(strcmp(current->type[index], "fun") == 0){
                        Fun temp;
                        int i;
                        int exist = 0;
                        for(i = 0; i < total_fun_index; i++){
                            if(strcmp($1, funArray[i].name) == 0){
                                temp = funArray[i];
                                exist = 1;
                                break;
                            }
                        }

                        if(exist == 0){
                            InvocationArg* ptr = (InvocationArg*) malloc(sizeof(InvocationArg));
                            ptr->name = "error";
                            ptr->total_arg_index = 0;
                            ptr->error = 1;
                            calledProcedure = *ptr;
                            yyerror("no such function\n");
                        }
                        else{
                            InvocationArg* ptr = (InvocationArg*) malloc(sizeof(InvocationArg));
                            ptr->name = $1;
                            ptr->total_arg_index = 0;
                            ptr->error = 0;
                            calledProcedure = *ptr;
                        }

                        if(calledProcedure.error == 0){
                            $$.type = temp.returnType;
                            printf("%s successfully done\n", calledProcedure.name);
                        }
                    }
                }
                else if(index == -1){
                    $$.type = "NULL";                   // because we can't find, so the type is null
                    yyerror("can't find variable\n");
                }
            }
        |   BOOL
            {
                $$.type = "boolean";
                
                if($1 == 1){
                    $$.b = 1;
                    if(isConstant == 0 && inGlobal == 0){
                        write("iconst_1\n");
                    }
                }
                else if($1 == 0){
                    $$.b = 0;
                    if(isConstant == 0 && inGlobal == 0){
                        write("iconst_0\n");
                    }
                }
            }
        |   INT
            {
                $$.type = "int";
                $$.i = $1;

                if(isConstant == 0 && inGlobal == 0){
                    write("sipush ");
                    fprintf(fout, "%d\n", $1);
                }
            }
        |   FLO
            {
                $$.type = "float";
                $$.f = $1;

                if(isConstant == 0 && inGlobal == 0){
                    write("ldc ");
                    fprintf(fout, "%f", $1);
                    fprintf(fout, "f\n");
                }
            }
        |   STR
            {
                $$.type = "string";
                $$.s = $1;

                write("ldc \"");
                fprintf(fout, "%s\"\n", $1);
            }
        /* 
        a function called with args 
        */
        |   called_procedure
            {
                $$.type = $1.type;
                if(strcmp($$.type, "boolean") == 0){
                    $$.b = $1.b;
                }
                else if(strcmp($$.type, "int") == 0){
                    $$.i = $1.i;
                }
                else if(strcmp($$.type, "float") == 0){
                    $$.f = $1.f;
                }
                else if(strcmp($$.type, "string") == 0){
                    $$.s = $1.s;
                }
            }

%% 
int yyerror(char *msg)  
{
    printf("error: %s", msg); 
}

int main(int argc,char* argv[])
{
    extern FILE *yyin;

    char* fileName;
    strcpy(fileName, argv[1]);
    fileName = strtok(fileName, ".");
    char* saveName = strdup(fileName);
    strcat(saveName, ".jasm");

    fout = fopen(saveName, "w+");

    if(fout==NULL) {
        printf("Fail To Open File out1.txt!!");
        return;
    }

    /*
    initialize the first node, which contain the main table.
    */
    initial.name = "main";
    create(&initial.ptr); 
    initial.previous = NULL;
    initial.next = NULL;

    stack.start = &initial;
    stack.last = &initial;

    int i;
    for(i = 0; i < 1000; i++){
        isLabelUsed[i] = 0;
    }

    if((yyin=fopen(argv[1],"r"))==NULL)
    {
        printf("Error reading files, the program terminates immediately\n");
        exit(0);
    }
    yyparse();

    return 0; 
}