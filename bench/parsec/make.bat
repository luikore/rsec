ghc -c Arithmetic.hs -fglasgow-exts -O2
ghc -c dllmain.c -O2
ghc -shared *.o -o Arithmetic.so -O2 -package parsec

