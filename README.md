
# INTRODUCTION

**dstate** : Derived State Machines from sequential code for Verilog HDL

This tool generates a verilog FSM based on a behavioral / sequential
description in verilog of the functionality. The input is plain text file 
with several sections.
 
    sm_decl :=
       'SmBegin'
          flop_decl+
       ['SmCombo'
          combo_decl+ ]
       'SmForever'
       ...
       'SmEnd'

Anything not present within SmBegin/SmEnd markers is copied verbatim to the
output, which allows interleaving these blocks anywhere in the middle of 
user code.

EBNF notation:
 
    'terminal'       Represents a terminal expected without the quotes
    :=               Defines a non-terminal
    []               Indicate enclosing items are optional
    +                One or more repetitions
    item1 item2      Indicates sequencing of items (terminal or not)
    |                Indicates alternatives
 
The body of each section (represented as ...) is written in verilog.
Single line comments // style are allowed
 
Flop declaration Section is used to add 'reg' type of variable definitions 
that can be used on the main functional loop. The syntax for each entry is

    flop_decl := ['local'] ['reg'] [width_decl] var_name ['=' initial_value] ';'

    width_decl := /*empty*/ | '[' integer_expr ':' integer_expr ']'

    varname := verilog_identifier
 
- if **local** is specified, the declaration is local to the block generated
- **local reg** is equivalent to local
- if **reg** is speficied, the declaration is made outside the block generated 
  to have module scope
- if neither **local** nor **reg** are specified, the var is expected to be 
  declared externally by the user. The statement may still be required to 
  provide an initial value

The init_value is used to define the reset value in flops generated under
flop declaration block

Section SmCombo is used to add 'reg' type of variable definitions that 
can be used on the main functional loop for 2-block style FSMs. 
The syntax for each entry is:

    combo_decl := ['local'] ['reg'] [width_decl] var_name ['=' init_value] ';'

where fields have the same meaning than above other than init_value.

The init_value is used to define the initial value of the combinational vars 
defined under SmCombo.
 
SmForever/SmEnd define the functionality of the block. This block of 
code is the body of a loop that would repeat forever. This code can be 
written in sequential / behavioral style, dstate will unwrap the sequential 
(non-synthesizable) code into FSM  style RTL that implements the same 
functionality but is now synthesizable.
 
The tool can also generate a wrapper for the behvioral code given to allow 
behavioral simulation. Both representations (behavioral with wrapper and FSM)
are equivalent in functionality and can replace each other in a higher level 
simulation. The FSM representation is the only one synthesizable by 
conventional tools, whereas the behavioral one is more readable and amenable 
to initial testing / debugging.


# GETTING STARTED

 Multiple examples are provided in sub-directories. The file in_smen.v 
 contains a description of the code in the format specified above. 
 
 Doing:
 
    $ make
 
 Will generate the following files:
 
-  out_beh.v : behavioral code in in.v with wrapper logic. Note how an infinite 
               loop with a clock in between iterations has been inserted along 
               with logic to react to reset. This code is simulable by any 
               verilog simulator but not synthesizable.

 - out_sm.v : FSM style generated code. Equivalent to out_beh.v but is also 
              synthesizable (1 block type)
 
 Note that a clock event (wait for clock edge) is represented by the 

    `tick; 
 
 macro on the input representation.
 
The testbench test.v performs a simple test of the code. It can include 
either generated representation of the code (out_beh.v or out_sm.v) 
depending on a plus-argument (see Makefile). Executing `make` will run a 
test for both representations and compare them to a golden file (gold.log 
included in the package). Both tests (with same testbench) invoke 
Pragmatic's 'cver' simulator 
Please modifie SIM varible in examples/Makefile to invoke your own simulator. 

# CONTROL

For a description of all the options do: 
    
    $ ./dstate.py --help
    
    usage: dstate.py [-h] [-prefix PREFIX] [-clk CLK] [-state STATE] [-rst RST]
                     [-dbg DBG] [-name NAME] [-tab TAB] [-sd SD]
                     [-next_suffix NEXT_SUFFIX] [-curr_suffix CURR_SUFFIX]
                     [-ena ENA] [-local_next [LOCAL_NEXT]]
                     [-falling_edge [FALLING_EDGE]] [-sync_rst [SYNC_RST]]
                     [-high_act_rst [HIGH_ACT_RST]] [-behav [BEHAV]]
                     [-rename_states [RENAME_STATES]] [-drop_suffix [DROP_SUFFIX]]
                     file

    positional arguments:
      file                  Input file to process

    optional arguments:
      -h, --help            show this help message and exit
      -prefix PREFIX        Prefix for state names
      -clk CLK              Clock name
      -state STATE          Name of state variable generated
      -rst RST              Reset name
      -dbg DBG              Debug Level
      -name NAME            Used to derive block name etc.
      -tab TAB              Used to indent
      -sd SD                delay for <= assignements
      -next_suffix NEXT_SUFFIX
                            suffix for next state variables
      -curr_suffix CURR_SUFFIX
                            suffix for next state variables
      -ena ENA              fms enable signal base (fsm # will be appended)
      -local_next [LOCAL_NEXT]
                            Keep next declarations local
      -falling_edge [FALLING_EDGE]
                            Clock active on falling edge
      -sync_rst [SYNC_RST]  Syncrhonous reset
      -high_act_rst [HIGH_ACT_RST]
                            reset active high
      -behav [BEHAV]        Output is behavioral
      -rename_states [RENAME_STATES]
                            Rename/simplify merged output states
      -drop_suffix [DROP_SUFFIX]
                            Rename ffs to be have no suffix outside dstate
                        
The output of the tool is generated on stdout

All options can be abbreviated until unique.

The output is FSM style by default. To produce behavioral code with a 
wrapper use -beh option.

The script contains options to define reset as

    synchronous / active high   -> -sync -high
    synchronous / active low    -> -sync 
    asynchronous / active high  -> -high
    asynchronous / active low   -> (default)
 
The name of the reset signal can be specified using -rst <name> option
Similarly the name of the clock signal can be specified using -clk <name> 
option. The active clock edge is rising by default but can be changed to 
falling with -fall option.
 
Other options are available to control the name of the following items:

    FSM state variable : -state s
    generated block name seed : -name s
    prefix for state constants : -prefix s

# BUGS

 This code is in Beta testing. Please report any bugs along with input file 
 and command line used to allow its reproduction to: miguel.a.guerrero@gmail.com
 
 Suggestions for improvement are most welcomed

# DEPENDENCIES

The tests use:

- **iverilog** : verilog simulator    (sudo apt-get install iverilog)
- **vppreproc** : verilog preprocessor (sudo apt-get install libverilog-perl)

Optional:

- **gtkwave** : waveform viewer      (sudo apt-get install gtkwave)
- **yosys** : logic synthesis      (http://www.clifford.at/yosys) 
             required only if running GLS over generated code 

# LICENSING

See LICENSE and NOTICE files for details
