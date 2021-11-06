typedef struct SymbolTable SymbolTable;
struct SymbolTable {
	char table[100][256];
	int isConstant[100];
	int isArray[100];
	char* type[100];
	int boolValue[100];
	int intValue[100];
	float floatValue[100];
	char* strValue[100];
	int arrayLen[100];
	int stack[100];
	int row;
	int pass;
	int stackIndex;
};

void create(SymbolTable *p){
	p->row = 0;
	p->pass = 0;
	p->stackIndex = 0;
}

int lookup(SymbolTable *a, char* s){
	int i;
	for(i = 0; i < a->row; i++){
		if(strcmp(a->table[i], s) == 0){
			return i;
		}
	}
	return -1;
}

void insert(SymbolTable *a, char* name, int c, int array, char* t, int b, int i, float f, char* str, int l){
	if(lookup(a, name) == -1){
		strcpy(a->table[a->row], name); 
		a->isConstant[a->row] = c;
		a->isArray[a->row] = array;
		a->type[a->row] = t;
		a->boolValue[a->row] = b;
		a->intValue[a->row] = i;
		a->floatValue[a->row] = f;
		a->strValue[a->row] = str;
		a->arrayLen[a->row] = l;
		a->stack[a->row] = a->stackIndex;
		a->row += 1;

		if(c != 1){
			a->stackIndex++;
		}
	}
	else{
		printf("error: this name has already exist!\n");
	}
}

void dump(SymbolTable *a){
	printf("Symbol Table : \n");
	int i;
	char temp[256];
	for(i = 0; i < a->row; i++){
		printf("index %d: ", i);
		printf("%s\t", a->table[i]);
		printf("type: %s\t", a->type[i]);
		if(a->isArray[i] == 1){
			if(strcmp(a->type[i], "boolean") == 0){
				printf("array length: %d", a->arrayLen[i]);
			}
			else if(strcmp(a->type[i], "int") == 0){
				printf("array length: %d", a->arrayLen[i]);
			}
			else if(strcmp(a->type[i], "float") == 0){
				printf("array length: %d", a->arrayLen[i]);
			}
			else if(strcmp(a->type[i], "string") == 0){
				printf("array length: %d", a->arrayLen[i]);
			}
		}
		else if(strcmp(a->type[i], "boolean") == 0){
			printf("value: %d", a->boolValue[i]);
		}
		else if(strcmp(a->type[i], "int") == 0){
			printf("value: %d", a->intValue[i]);
		}
		else if(strcmp(a->type[i], "float") == 0){
			printf("value: %f", a->floatValue[i]);
		}
		else if(strcmp(a->type[i], "string") == 0){
			printf("value: %s", a->strValue[i]);
		}
		printf("\n");
	}
	printf("\n");
}

// each function has its table, and the first one is for main program, called "main"
typedef struct Node Node;
struct Node {
	char* name;
	SymbolTable ptr;
	Node* previous;
	Node* next;
};

typedef struct Stack Stack;
struct Stack {
	Node* start;
	Node* last;
};

void push_back(Stack* stack, char* n){
	Node *current = (Node*) malloc(sizeof(Node));
	current->name = n;
	create(&current->ptr);
	current->previous = stack->last;
	current->next = NULL;
	stack->last->next = current;
	stack->last = current;
}

void pop_back(Stack *stack){
	dump(&stack->last->ptr);
	stack->last = stack->last->previous;
	stack->last->next = NULL;
}