all: scan

scan: scanner.c
	gcc --std=c99 scanner.c -o scan

parse: parser.c scanner.c
	gcc --std=c99 parser.c scanner.c -o parse

scanner.c: scanner.l
	flex -o scanner.c scanner.l

parser.c parser.h: parser.y
	bison -d -o parser.c parser.y

clean:
	rm -f parse scan scanner.c parser.c parser.h
