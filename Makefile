scanner: lex.yy.c y.tab.c y.tab.h
	gcc -o scanner y.tab.c lex.yy.c -lfl -ly

lex.yy.c: lex.l
	lex lex.l

y.tab.c: yacc.y
	bison -y -d yacc.y

clean:
	rm -f lex.yy.c
	rm -f y.tab.c
	rm -f y.tab.h
	rm -f scanner.exe
	rm -f scanner
	rm -f scanner.exe.stackdump

cleanjava:
	rm -f *.jasm *.class