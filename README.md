
# INTRODUCTION

**dstate** : Derived State Machines from sequential code for Verilog HDL

This tool generates a verilog FSM based on a behavioral / sequential
description in verilog of the functionality. The input is a plain text file 
with several sections.
 
    sm_decl :=  'SmBegin'
                    flop_decl+
                'SmForever'
                    ...
                'SmEnd'

Anything _not_ present within **SmBegin/SmEnd** markers is copied verbatim to the output, which allows interleaving these blocks anywhere in the middle of user code, which will be left completely unprocessed by the tool.

The contents of the description between SmBegin/SmEnd is processed by dstate and the generated contents replaces its definition section on the output file.

The syntax description used here uses the following EBNF notation:
 
    'terminal'       Represents a terminal expected without the quotes
    :=               Defines a non-terminal
    []               Indicate enclosed items are optional
    +                One or more repetitions
    item1 item2      Indicates sequencing of items (terminal or not)
    |                Indicates alternatives
 
The body of each section (represented as ...) is written in verilog.
Single line comments // style are allowed
 
Flop declaration Section is used to add 'reg' type of variable definitions 
that can be used on the main functional loop. The syntax for each entry is

    flop_decl := ['local'] ['reg'] [width_decl] var_name ['=' initial_value] ';'

    width_decl := /*empty*/ 
                | '[' integer_expr ':' integer_expr ']'

    varname := verilog_identifier
 
- if **local** is specified, the declaration is local to the block generated
- **local reg** is equivalent to local
- if only **reg** is speficied, the declaration is made outside the block 
  to have module scope
- if neither **local** nor **reg** are specified, the var is expected to be 
  declared externally by the user. The statement may still be required to 
  provide an initial value.

The init_value is used to define the reset value in flops generated under
flop declaration block

**SmForever/SmEnd** define the functionality of the block. This block of 
code is the body of a loop that would repeat forever. This code can be 
written in _sequential / behavioral style_, dstate will unwrap the sequential (non-synthesizable) code into a FSM RTL that implements the same functionality but is now _synthesizable_.
 
The tool can also generate a wrapper for the behavioral code given to allow 
behavioral simulation. Both representations (behavioral with wrapper and FSM) are equivalent in functionality and can replace each other in a higher level simulation. The FSM representation is the only one synthesizable by 
conventional tools, whereas the behavioral one is more readable and amenable to initial testing / debugging.

# AN EXAMPLE

The following example gives an quick overview of the mode of operation. It implements a simple automatic door controller that drives two signals (_motor_up/motor_dn_) once the door is activated throgh the input _activate_. If the door is up (up_limit is active) and the door is activated, the controller will drive the door down until the sensor for down position is active (_motor_dn_). Similarty if we estart on the down position the activation will drive the door till it reaches the up position. The example is based on the following [lecture notes](https://www.academia.edu/21043868/Logic_Design_Verilog_FSM_in_class_design_example_s_1_Verilog_FSM_Design_Example_Automatic_Garage_Door_Opener_and_Timers)

      1 `define wait1(cond) `tick; while(~(cond)) `tick
      2 
      3 module motor(
      4     input clk, activate, up_limit, dn_limit, rst_n,
      5     output motor_up, motor_dn
      6 );
      7 
      8 SmBegin
      9    reg motor_up = 0;
     10    reg motor_dn = 0;
     11 SmForever
     12    if (up_limit) begin
     13       `wait1(activate);
     14       motor_dn = 1;
     15       `wait1(dn_limit);
     16       motor_dn = 0;
     17    end
     18    else begin
     19       `wait1(activate);
     20       motor_up = 1;
     21       `wait1(up_limit);
     22       motor_up = 0;
     23    end
     24 SmEnd
     25 
     26 endmodule

In the code above the macro **\`wait1(cond)** is defined to wait until a condition is true inserting at least 1 clock cycle of wait. Similarly the examples provided often define a **\`wait0(cond)** where the the wait is for 0 or more cycles.

The example prouces the following output once processed:

      1 module motor(
      2     input clk, activate, up_limit, dn_limit, rst_n,
      3     output motor_up, motor_dn
      4 );
      5 
      6 // begin dstate0
      7 localparam SM0_0 = 0;
      8 localparam SM0_1 = 1;
      9 localparam SM0_2 = 2;
     10 localparam SM0_3 = 3;
     11 localparam SM0_4 = 4;
     12 // SmBegin ff decl begin
     13 reg  motor_up_q;
     14 reg  motor_dn_q;
     15 // SmBegin ff decl end
     16 always @(posedge clk or negedge rst_n) begin : dstate0
     17     // SmBegin ff local begin
     18     reg  motor_up;
     19     reg  motor_dn;
     20     // SmBegin ff local end
     21     reg [2:0] state0_q, state0;
     22     if (~rst_n) begin
     23         // SmBegin ff init begin
     24         motor_up_q <= #1 0;
     25         motor_dn_q <= #1 0;
     26         // SmBegin ff init end
     27         state0_q <= #1 SM0_0;
     28     end
     29     else begin
     30         // set defaults for next state vars begin
     31         motor_up = motor_up_q;
     32         motor_dn = motor_dn_q;
     33         // set defaults for next state vars end
     34         state0 = state0_q;
     35         // SmForever
     36         case (state0_q)
     37             SM0_0: begin
     38                 if (up_limit) begin
     39                     state0 = SM0_1;
     40                 end
     41                 else begin
     42                     state0 = SM0_3;
     43                 end
     44             end
     45             SM0_1: begin
     46                 if (~(activate)) begin
     47                     // stay
     48                 end
     49                 else begin
     50                     motor_dn = 1;
     51                     state0 = SM0_2;
     52                 end
     53             end
     54             SM0_2: begin
     55                 if (~(dn_limit)) begin
     56                     // stay
     57                 end
     58                 else begin
     59                     motor_dn = 0;
     60                     state0 = SM0_0;
     61                 end
     62             end
     63             SM0_3: begin
     64                 if (~(activate)) begin
     65                     // stay
     66                 end
     67                 else begin
     68                     motor_up = 1;
     69                     state0 = SM0_4;
     70                 end
     71             end
     72             SM0_4: begin
     73                 if (~(up_limit)) begin
     74                     // stay
     75                 end
     76                 else begin
     77                     motor_up = 0;
     78                     state0 = SM0_0;
     79                 end
     80             end
     81         endcase
     82         // SmEnd
     83         // Update ffs with next state vars begin
     84         motor_up_q <= #1 motor_up;
     85         motor_dn_q <= #1 motor_dn;
     86         // Update ffs with next state vars end
     87         state0_q <= #1 state0;
     88     end
     89 end
     90 // end dstate0
     91 
     92 endmodule

 Few notes:
- The input is more compact and close to the original intent (the factors bellow are typical)
    - dstate: 26 lines
    - manualy written FSM (see lecture notes link): 5 states, 73 lines (condensed HDL style)
    - dstate generated code: 5 states, 92 lines (with comments, uncondensed style)
- The chunk SmBegin/SmEnd block has been replaced by a new implementation that is now synthesizable (the style is not the conventional 1 or 2 block FSM, more of a mix but still synthesizable)
- The input uses blocking assignements exclusively. This is by design to simplify the process as sequential thinking is simpler and less error prone than mixing things that happen in the current cycle vs. scheduled for the next. The tool takes care of inserting non blocking assignements only for final state values.
- Multiple SmBegin/SmEnd can be present in a single file. They will be internally labeled with suffixes 0, 1, .. (e.g. state0/state1...)

For mode details look into one of the mattrix multiply exmples provided (matmul*)

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
              synthesizable
 
 Note that a clock event (wait for clock edge) is represented by the 

    `tick; 
 
 macro on the input representation. The macro is internally defined based on the clock polarity and reset type given to the tool.

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
                        
The output of the tool is generated on **stdout**

All options can be abbreviated until unique.

The output is FSM style by default. To produce behavioral code with a 
wrapper use -behav option.

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
 and command line used to allow its reproduction to: miguel.a.guerrero at gmail.com
 
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
