#SIM=vcs -R
PREPRO=vppreproc -noline -noblank
COMP=iverilog 
SIM=vvp
CURR=$(shell pwd)
TOFSM=../dstate.py
TOFSMOPTS?=-rename_states -sd 1 
TC?=


all: beh_post.log rtl_post.log
	@diff beh_post.log rtl_post.log && echo TEST MATCH PASSED || \
            echo TEST MATCH FAILED

clean:
	rm -f out_sm.v out_beh.v *.log *.vcd \
          a.out *.vpost* tb.vcd out_sm.vg *.dot *.dbg *.dot.pdf

guild: beh_post.log
	cp beh_post.log gold.log

%.vpost: %.v
	$(PREPRO) $< > $@

%.vpost_behav: %.v
	$(PREPRO) -DBEHAV $< > $@

out_sm.v : in_smgen$(TC).vpost $(TOFSM)
	@echo -----------------------------------------------------------
	@echo     compiling in_smgen$(TC).vpost into a state machine out_sm.v
	@echo -----------------------------------------------------------
	$(TOFSM) $(TOFSMOPTS) in_smgen$(TC).vpost > out_sm.v

out_beh.v : in_smgen$(TC).vpost_behav $(TOFSM)
	@echo -----------------------------------------------------------
	@echo     compiling in_smgen$(TC).vpost_behav into behavioral out_beh.v
	@echo -----------------------------------------------------------
	$(TOFSM) $(TOFSMOPTS) in_smgen$(TC).vpost_behav -behav > out_beh.v

beh.log : out_beh.v tb.v
	@echo -----------------------------------------------------------
	@echo     running exemple tb including behavioral out_beh.v
	@echo -----------------------------------------------------------
	$(COMP) -g2005-sv -D BEHAV=1 tb.v 
	$(SIM)  a.out | tee beh.log 2>&1

rtl.log : out_sm.v tb.v
	@echo -----------------------------------------------------------
	@echo     running exemple tb including RTL out_sm.v
	@echo -----------------------------------------------------------
	$(COMP) -g2001 tb.v 
	$(SIM) a.out | tee rtl.log 2>&1

out_sm.vg: out_sm.v
	yosys -p "read_verilog out_sm.v; proc; opt; write_verilog out_sm.vg" > syn.log

gls.log: out_sm.vg tb.v
	@echo -----------------------------------------------------------
	@echo     running exemple tb including RTL out_sm.v
	@echo -----------------------------------------------------------
	$(COMP) -g1995 -D GLS=1 tb.v 
	$(SIM) a.out | tee gls.log 2>&1

gls: gls_post.log rtl_post.log
	@diff rtl_post.log gls_post.log && echo TEST MATCH PASSED || \
            echo TEST MATCH FAILED

dot:
	dot *.dot -Tpdf -O
fdp:
	fdp *.dot -Tpdf -O
twopi:
	twopi *.dot -Tpdf -O
circo:
	circo *.dot -Tpdf -O


#this auto-check has been tested for cver only (for other sims you
#may need to filter-out simulator generated lines before comparing) 
%_post.log : %.log
	@cat $*.log | awk '/starts/ {on=1} {if (on) {print}} /DONE/ {on=0}'\
            > $*_post.log

