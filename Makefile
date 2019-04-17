.ONESHELL:

DIRS=examples/matmul_simple examples/matmul_fast examples/motor examples/tpg \
     tests/test_seq2 tests/tpg2 tests/tpg3 tests/for1 tests/for2 tests/for3 tests/for4

all:
	for i in $(DIRS); do make -C $$i all || exit 1; done

gls:
	for i in $(DIRS); do make -C $$i gls || exit 1; done

clean:
	for i in $(DIRS); do make -C $$i clean; done
	$(RM) -r __pycache__
