.ONESHELL:

DIRS=matmul7 matmul8 matmul9 test_seq2 tpg2b tpg2c tpg2d for1 for2 for3 for4 motor 

all:
	for i in $(DIRS); do make -C $$i all || exit 1; done

gls:
	for i in $(DIRS); do make -C $$i gls || exit 1; done

clean:
	for i in $(DIRS); do make -C $$i clean; done
	$(RM) -r __pycache__
