
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

The init_value, if provided, is used to define the reset value in flops generated 
under flop declaration block.

**SmForever/SmEnd** define the functionality of the block. This block of 
code is the body of a loop that would repeat forever. This code can be 
written in _sequential / behavioral style_, dstate will unwrap the sequential (non-synthesizable) code into a FSM RTL that implements the same functionality but is now _synthesizable_.
 
The tool can also generate a wrapper for the behavioral code given (see --behav option) to allow 
behavioral simulation. Both representations (behavioral with wrapper and FSM) are equivalent in functionality and can replace each other in a higher level simulation. The FSM representation is the only one synthesizable by 
conventional tools, whereas the behavioral one is more readable and amenable to initial test and debug.

# AN EXAMPLE

The following example gives an quick overview of the mode of operation. It implements a simple automatic door controller that drives two signals (_motor_up/motor_dn_) once the door is activated throgh the input _activate_. If the door is up (up_limit is active) and the door is activated, the controller will drive the door down until the sensor for down position is active (_motor_dn_). Similarty if we estart on the down position the activation will drive the door till it reaches the up position. The example is based on the following [lecture notes](https://www.academia.edu/21043868/Logic_Design_Verilog_FSM_in_class_design_example_s_1_Verilog_FSM_Design_Example_Automatic_Garage_Door_Opener_and_Timers)

```systemverilog
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
```

In the code above the macro **\`wait1(cond)** is defined to wait until a condition is true inserting at least 1 clock cycle of wait. Similarly the examples provided often define a **\`wait0(cond)** where the the wait is for 0 or more cycles.

The example produces the following output once processed:

```systemverilog
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
    12 always @(posedge clk or negedge rst_n) begin : dstate0
    13     // SmBegin ff local begin
    14     reg  motor_up_q, motor_up;
    15     reg  motor_dn_q, motor_dn;
    16     // SmBegin ff local end
    17     reg [2:0] state0_q, state0;
    18     if (~rst_n) begin
    19         // SmBegin ff init begin
    20         motor_up_q <= 0;
    21         motor_dn_q <= 0;
    22         // SmBegin ff init end
    23         state0_q <= SM0_0;
    24     end
    25     else begin
    26         // set defaults for next state vars begin
    27         motor_up = motor_up_q;
    28         motor_dn = motor_dn_q;
    29         // set defaults for next state vars end
    30         state0 = state0_q;
    31         // SmForever
    32         case (state0_q)
    33             SM0_0: begin
    34                 if (up_limit) begin
    35                     state0 = SM0_1;
    36                 end
    37                 else begin
    38                     state0 = SM0_3;
    39                 end
    40             end
    41             SM0_1: begin
    42                 if (~(activate)) begin
    43                     // stay
    44                 end
    45                 else begin
    46                     motor_dn = 1;
    47                     state0 = SM0_2;
    48                 end
    49             end
    50             SM0_2: begin
    51                 if (~(dn_limit)) begin
    52                     // stay
    53                 end
    54                 else begin
    55                     motor_dn = 0;
    56                     state0 = SM0_0;
    57                 end
    58             end
    59             SM0_3: begin
    60                 if (~(activate)) begin
    61                     // stay
    62                 end
    63                 else begin
    64                     motor_up = 1;
    65                     state0 = SM0_4;
    66                 end
    67             end
    68             SM0_4: begin
    69                 if (~(up_limit)) begin
    70                     // stay
    71                 end
    72                 else begin
    73                     motor_up = 0;
    74                     state0 = SM0_0;
    75                 end
    76             end
    77         endcase
    78         // SmEnd
    79         // Update ffs with next state vars begin
    80         motor_up_q <= motor_up;
    81         motor_dn_q <= motor_dn;
    82         // Update ffs with next state vars end
    83         state0_q <= state0;
    84     end
    85 end
    86 // drop_suffix begin
    87 wire  motor_up = dstate0.motor_up_q;
    88 wire  motor_dn = dstate0.motor_dn_q;
    89 // drop_suffix end
    90 // end dstate0
    91 
    92 endmodule
```

 Few notes:
- The input is more compact and close to the original intent (the factors bellow are typical)
    - dstate: 26 lines
    - manualy written FSM (see lecture notes link): 5 states, 73 lines (condensed HDL style)
    - dstate generated code: 5 states, 92 lines (with comments, uncondensed style)
- The chunk SmBegin/SmEnd block has been replaced by a new implementation that is now synthesizable (the style is not the conventional 1 or 2 block FSM, more of a mix but still synthesizable)
- The input uses blocking assignements exclusively. This is by design to simplify the process as sequential thinking is simpler and less error prone than mixing things that happen in the current cycle vs. scheduled for the next. The tool takes care of inserting non blocking assignements only for final state values.
- Multiple SmBegin/SmEnd can be present in a single file. They will be internally labeled with suffixes 0, 1, .. (e.g. state0/state1...)

For mode details look into **examples** directory, for example matmul_simple.

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

    usage: dstate.py [-h] [-behav] [-next_suffix NEXT_SUFFIX]
                 [-curr_suffix CURR_SUFFIX] [-drop_suffix] [-ena ENA]
                 [-local_next] [-rename_states] [-prefix PREFIX] [-clk CLK]
                 [-state STATE] [-rst RST] [-name NAME] [-tab TAB] [-sd SD]
                 [-falling_edge] [-sync_rst] [-high_act_rst] [-dbg DBG]
                 file

    positional arguments:
      file                  Input file to process (default, stdin)

    optional arguments:
      -h, --help            show this help message and exit
      -behav                Output is behavioral (default, synthesizable RTL)
      -next_suffix NEXT_SUFFIX
                            Suffix for next state variables (default, no suffix)
      -curr_suffix CURR_SUFFIX
                            Suffix for next state variables (default, '_r')
      -drop_suffix          Rename FFs to be have no suffix (see -curr_suffix)
                            outside generated block (default, false)
      -ena ENA              SM enable signal base (default, no enable generated,
                            SM number will be appended)
      -local_next           Keep declarations of next state variables local
                            (default, false)
      -rename_states        Rename/simplify merged state constant names (default,
                            false)
      -prefix PREFIX        Prefix for state value constants (default, 'SM'
                            followed by SM instance number)
      -clk CLK              Clock name (default, 'clk')
      -state STATE          Name of state variable generated (default, 'state'
                            followed by SM instance number)
      -rst RST              Reset name (default, 'rst_n' if active low, 'rst' if
                            active high)
      -name NAME            Used to derive block name etc. (default, 'dstate'
                            followed by SM instance number)
      -tab TAB              Used to indent output (default, uses tabs)
      -sd SD                Delay for <= assignements (default, no delay)
      -falling_edge         Clock active on falling edge (default, rising)
      -sync_rst             Synchronous reset (default, async)
      -high_act_rst         Reset active high (default, active low)
      -dbg DBG              Debug Level (default, 0)
    
                        
The output of the tool is generated on **stdout**

All options can be abbreviated until unique.

The output is FSM style by default. To produce behavioral code with a 
wrapper use -behav option.

The script contains options to define reset as

    synchronous / active high   -> -sync_rst -high_act_rst
    synchronous / active low    -> -sync_rst 
    asynchronous / active high  -> -high_act_rst
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
  you can customize the simulator used under common/include.mk  
  To install it locally from the source without root access use install_iverilog.sh  
  See http://iverilog.icarus.com

- **vppreproc** : verilog preprocessor (sudo apt-get install libverilog-perl)  
  run ./install_prep.sh if you want to install it without root access.

Optional:

- **gtkwave** : waveform viewer      (sudo apt-get install gtkwave)  
  see http://gtkwave.sourceforge.net

- **yosys** : logic synthesis      (http://www.clifford.at/yosys) 
             used only if running GLS over generated code (make gls)

# LICENSING

See LICENSE and NOTICE files for details
