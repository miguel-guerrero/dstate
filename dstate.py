#!/usr/bin/env python3
#------------------------------------------------------------------------------
# Copyright (c) 2018-Present, Miguel A. Guerrero
# All rights reserved.
# 
# This is free software released under GNU Lesser GPL license version 3.0 (LGPL 3.0)
# 
# See http://www.gnu.org/licenses/lgpl-3.0.txt for a full text
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
# OF THE POSSIBILITY OF SUCH DAMAGE.
# 
# Please send bugs and suggestions to: miguel.a.guerrero@gmail.com
#------------------------------------------------------------------------------
import re
import VlogParser
import sys
from collections import Counter

#--- Top level parsing of the file
#--- Identify several sections and grab their contents

def error(*args):
    print("ERROR:", *args, file=sys.stderr)
    sys.exit(1)

def warning(*args):
    print("WARNING:", *args, file=sys.stderr)

def debug(*args):
    print("DEBUG:", *args, file=sys.stderr)

def parseInputFile(fileIn):
    state = -2;
    line_no = 0;
    line_base = 0;
    with open(fileIn) as fin:
        line = fin.readline()
        while line:
            lineStr = line.strip()
            line_no += 1
            if state < 0:
                if 'SmBegin' ==  lineStr:
                    state = 0
                    registered_in = ""
                    combo_in = ""
                    inp = ""
                else:
                    print(line, end='')
            elif state == 0: #REGISTERED
                if 'SmCombo' == lineStr:
                    state = 1
                elif 'SmForever' == lineStr:
                    line_base = line_no
                    state = 2
                else:
                    registered_in += line
            elif state == 1: #COMBO
                if 'SmForever' == lineStr:
                    line_base = line_no
                    state = 2
                else:
                    combo_in += line
            elif state == 2: #BEHAV_LOOP
                if 'SmEnd' == lineStr:
                    state=3
                else:
                    m=re.match('(\s*)SmFlopped:\s*(.*)', line)
                    if m:
                        registered_in += m.group(1) + m.group(2) + "\n"
                    else:
                        m=re.match('(\s*)SmCombo:\s*(.*)', line)
                        if m:
                            combo_in += m.group(1) + m.group(2) + "\n"
                        else:
                            inp += line

            if state == 3:
                conv = FsmConverter(args)
                ind = conv.extract_initial(registered_in, isff=True)
                conv.extract_initial(combo_in, isff=False)
                conv.process_block(inp, "", line_base, fileIn)
                registered_in = ""
                combo_in = ""
                inp = ""
                state = -1

            line = fin.readline()

    return state


class FsmConverter:

    sm_num=-1

    def __init__(self, args):
        self.args = args
        FsmConverter.sm_num += 1
        self.oname = f"{self.args.name}{self.sm_num}"
        self.ff_decl_in = ""
        self.ff_local_decl_in = ""
        self.ff_rst_in  = ""
        self.ff_update_ffs = ""
        self.ff_rename_ffs = ""
        self.ff_update_ffs_beh = ""
        self.ff_update_nxt = ""
        self.combo_decl_in = ""
        self.combo_local_decl_in = ""
        self.combo_init_in = ""
        self.reg_track_isff={}
        self.reg_track_init={}
        self.rename_state = {}
        self.parser = None
        self.root = None

    def extract_initial(self, txt, isff):

        def get_width_var(width, var):
            m = re.search('(\[.*\])\s*(.*)', var)
            if m:
                width, var = m.groups()
            else:
                var = re.sub('^\s*', '', var)
            return width, var
 
        nxt = self.args.next_suffix
        curr = self.args.curr_suffix
        sd = self.args.sd
        for line in txt.split('\n'):
            line = line.replace(';', '') # TODO
            m = re.match('(\s+)', line)
            ind = m.group(1) if m else ""
            line = line.rstrip()
  
            if line != "":
                init_assings = re.split(',', line)
                width = ""
                local = decl = False
                for init_assign in init_assings:
                    try:
                        var, init = re.split('\s*\<?\=\s*', init_assign)
                    except:
                        error("missing initial val:", init_assign)
  
                    if re.search('reg', var):
                        decl = True
                        var = re.sub('reg\s*', '', var)
  
                    if re.search('local', var):
                        local = decl = True
                        var = re.sub('local\s*', '', var)
  
                    width, var = get_width_var(width, var)
  
                    self.reg_track_init[var] = init
                    self.reg_track_isff[var] = isff
  
                    eff_local = local or self.args.drop_suffix #drop_suffix implies local
  
                    if isff:
                        var_pair = f"{var}{curr}, {var}{nxt}" 
                        if eff_local:
                            self.ff_local_decl_in += f"reg {width} {var_pair};\n";
                        elif decl:
                            if self.args.local_next:
                                self.ff_decl_in       += f"reg {width} {var}{curr};\n"
                                self.ff_local_decl_in += f"reg {width} {var}{nxt};\n"
                            else:
                                self.ff_decl_in       += f"reg {width} {var_pair};\n"
   
                        if init != "":
                            self.ff_rst_in += f"{var}{curr} <= {sd}{init};\n"
                            if self.args.behav:
                                self.ff_rst_in += f"{var}{nxt} <= {sd}{init};\n"
   
                        self.ff_update_ffs += f"{var}{curr} <= {sd}{var}{nxt};\n"
   
                        scope_cur = self.oname+"." if eff_local else ""
                        scope_nxt = self.oname+"." if eff_local or self.args.local_next else ""
                        self.ff_update_ffs_beh += f"{scope_cur}{var}{curr} <= {sd}{scope_nxt}{var}{nxt};\n"
   
                        self.ff_update_nxt += f"{var}{nxt} = {var}{curr};\n"
   
                        if self.args.drop_suffix and not local:
                            self.ff_rename_ffs += f"wire {width} {var} = {scope_cur}{var}{curr};\n"
                    else:
                        if local:
                            self.combo_local_decl_in += f"reg {width} {var}{curr};\n";
                        else:
                            if decl:
                              self.combo_decl_in += f"reg {width} {var}{curr};\n"
                        if init != "":
                            self.combo_init_in += f"{var}{curr} = {init};\n"
 
        return ind


    def process_block(self, beh_in, ind, line_base, file_base=''):
        self.oprefix = f"{self.args.prefix}{self.sm_num}_"
        self.ostate = f"{self.args.state}{self.sm_num}"
 
        #Expand the input to have an infinite loop around it
        inp  = "while(1) begin\n"
        inp += "`tick;\n"
        inp += beh_in
        inp += "end\n"
 
        #Start VLOG parsing
        if self.args.dbg >= 3:
            print("--- input ---\n")
            print(inp)
            print("-------------\n")
 
        #--- generate code ---
        self.tick, self.tick_no_rst = get_ticks(self.args)
        self.reset_cond, self.not_reset_cond = get_resets(self.args)
 
        #Start transformations and output generation
        if not self.args.behav:
 
            #parse the code and build a syntax tree
            self.parser = parser = VlogParser.VlogParser(inp, line_base, file_base)
            self.root = root = parser.start_rule()
  
            #--- state machine (RTL) output
            if self.args.dbg > 0:
                with open('dstate.dbg', 'w') as f:
                    print("-- before source --", file=f)
                    print(f"{inp}", file=f)
                parser.st_show_from_node(f"{self.sm_num}_00_before", root)
                parser.dump_dot(f"{self.sm_num}_00_before", root)
  
            self.expand_tree_structs(parser, root, root, ind)
            if self.args.dbg > 0:
                parser.st_show_from_node(f"{self.sm_num}_02_after_expand_struct", root)
                parser.dump_dot(f"{self.sm_num}_02_after_expand_struct", root)
  
            self.convert_to_dag(parser, root, root, ind)
  
            if self.args.dbg > 0:
                parser.st_show_from_node(f"{self.sm_num}_04_after_convert_to_dag", root)
                parser.dump_dot(f"{self.sm_num}_04_after_convert_to_dag", root)
  
            self.merge_states(parser, root, ind)
  
            if self.args.dbg > 0:
                parser.st_show_from_node(f"{self.sm_num}_09_after_merge_states", root)
                parser.dump_dot(f"{self.sm_num}_09_after_merge_states", root)
  
            self.dump_tree_sm(parser, root, ind, line_base, file_base)
 
        else:
            sd_stm = " "+self.args.sd +";" if self.args.sd else ""
            tab = self.args.tab
            ena = ""
            if self.args.ena != "":
                ena = self.args.ena + str(self.sm_num)

            #--- Behavioral output
            print()
            print (f"// begin dstate{self.sm_num}")
            if ena == "":
                print(ind + f"`define tick begin update_ffs{self.sm_num}; {self.tick}; "+
                            f"if ({self.reset_cond}) disable {self.oname}_loop; end")
            else:
                print(ind + f"`define tick begin update_ffs{self.sm_num}; do {self.tick}; while(~{ena}); "+
                            f"if ({self.reset_cond}) disable {self.oname}_loop; end")
  
            if self.ff_decl_in != "":
                print(ind + "// SmBegin ff begin")
                indpr(ind, self.ff_decl_in)
                print(ind + "// SmBegin ff end")
  
            if self.combo_decl_in != "":
                print(ind + "// SmCombo begin")
                indpr(ind, self.combo_decl_in)
                print(ind + "// SmCombo end")
  
            print(ind + f"always {self.tick} begin : {self.oname}")
            if self.ff_local_decl_in != "":
                print(ind + tab + "// SmBegin ff local begin")
                indpr(ind + tab, self.ff_local_decl_in)
                print(ind + tab + "// SmBegin ff local end")
  
            if self.combo_local_decl_in != "":
                print (ind + tab + "// SmCombo local begin")
                indpr(ind + tab, self.combo_local_decl_in)
                print (ind + tab + "// SmCombo local end")
  
            print (ind +   tab + f"if ({self.not_reset_cond}) begin")
            print (ind + 2*tab +  f"begin : {self.oname}_loop")
            print (ind + 3*tab +    "while (1) begin")
            print (ind + 4*tab +     f"// SmForever {file_base}:{line_base}")
            indpr (ind + 4*tab,        beh_in)
            print (ind + 4*tab +      "// SmEnd")
            print (ind + 4*tab +      "`tick;")
            print (ind + 3*tab +     "end")
            print (ind + 2*tab +    "end")
            print (ind +   tab +  "end")
  
            if self.ff_rst_in != "":
                print (ind + tab + "// SmBegin ff init begin")
                indpr (ind + tab, self.ff_rst_in)
                print (ind + tab + "// SmBegin ff init end")
  
            print (ind + "end")
            if self.args.drop_suffix:
                print(ind + "// drop_suffix begin")
                indpr(ind, self.ff_rename_ffs)
                print(ind + "// drop_suffix end")
            self.print_task_update_ffs(ind)
            print (ind + "`undef tick")
            print (f"// end dstate{self.sm_num}\n")

    #--------------------------------------------------------------------
    # tree modification related routines
    #--------------------------------------------------------------------
    def expand_tree_structs(self, p, root, node, ind, cnt=[0]):
        while node:
            org_nxt = node.nxt
            expanded = False
  
            if p.has_tick(node):
  
                if node.typ == "cs":
                    error("case with `tick inside are not supported yet")
   
                elif node.typ == "eif":
                    assert False, "unexpected typ eif in expand_tree_structs"
   
                elif node.typ == "fo":
                    try:
                        init, cond, post = node.code.split(";")
                    except:
                        error("syntax error in for estatement for ({node.code})")
    
                    body = node.child[1]
    
                    init_node = p.node_add("sn", code=init, nxt=node, child=[None, None, None])
                    p.node_preinsert(init_node, node)
    
                    node.typ = "wh"
                    node.code = cond
    
                    post_node = p.node_add("sn", code=post, nxt=None,  child=[None, None, None])
                    ending_node = p.node_find_last(body)
                    if ending_node:
                        ending_node.nxt = post_node
    
                    #expand for block, given post_node as nxt
                    self.expand_tree_structs(p, root, body, ind, cnt)
                    expanded = True
   
                elif node.typ == "if":
                    self.expand_tree_structs(p, root, node.child[1], ind, cnt)
                    self.expand_tree_structs(p, root, node.child[2], ind, cnt)
   
                elif node.typ == "wh":
                    self.expand_tree_structs(p, root, node.child[1], ind, cnt)
  
            else:
                node.nxt = org_nxt
  
            if expanded and self.args.dbg > 1:
                p.st_show_from_node(f"{self.sm_num}_01_during_expand_structs{cnt[0]}", root)
                p.dump_dot(f"{self.sm_num}_01_during_expand_structs{cnt[0]}", root, f"{node} expanded")
                cnt[0] += 1
  
            node = org_nxt


    #--------------------------------------------------------------------
    # Convert syntax tree in a DAG
    #--------------------------------------------------------------------
    def convert_to_dag(self, p, root, node, ind, top_nxt=None, cnt=[0]):
        while node:
            org_nxt = node.nxt
            nxt = org_nxt or top_nxt
            expanded = False
  
            if p.has_tick(node):
                if node.typ == "cs":
                    error("internal 'cs' is expected to be pre-expanded in convert_to_dag")
   
                elif node.typ == "do":
                    body = node.child[1]
                    eif_node = p.node_add("eif", code=node.code, nxt=None, child=[None, None, None])
                    # refill node with the original body block
                    node.copy_flds_from(body)
                    p.node_rm(body) # this node got copied, now removed
                    self.convert_to_dag(p, root, node, ind, eif_node, cnt)
                    #eif_node links are filled up afterwards to avoid an infinite loop
                    eif_node.child = [None, node, nxt]
                    expanded = True
   
                elif node.typ == "dop":
                    self.convert_to_dag(p, root, node.child[2], ind, nxt, cnt)
                    node.typ = "eif"
                elif node.typ == "fo":
                    error("internal 'fo' is expected to be pre-expanded in convert_to_dag")
                elif node.typ == "if":
                    i = node.child[1]
                    self.convert_to_dag(p, root, i, ind, nxt, cnt)
                    i = node.child[2]
                    self.convert_to_dag(p, root, i, ind, nxt, cnt)
                    if i is None:
                       node.child[2]=nxt
                    node.typ = "eif"
                    node.nxt = None
                    expanded = True
                elif node.typ == "wh":
                    i = node.child[1]
                    self.convert_to_dag(p, root, i, ind, node, cnt)
                    node.child[2] = nxt
                    node.typ = "eif"
                    node.nxt = None
                    expanded = True
                else:
                    node.child[1] = nxt
                    node.nxt = None
            else:
                node.nxt = nxt
  
            if expanded and self.args.dbg > 1:
                p.st_show_from_node(f"{self.sm_num}_03_during_convert_to_dag{cnt[0]}", root)
                p.dump_dot(f"{self.sm_num}_03_during_convert_to_dag{cnt[0]}", root, f"{node} expanded")
                cnt[0] += 1
  
            node = org_nxt

    def merge_states(self, p, root, ind):
        cnt = 0
        tab = self.args.tab
        some_merged = True
        while some_merged:
            some_merged = False
            tks={}
            for node in p.nodes:
                if node.typ == "tk":
                    tks[node.code] = node
 
            for mode in ("abs", "rel"): #TODO rel
                code_cnt=Counter()
                code_by_node={}
  
                for code in tks.keys(): #TODO sort
                    visited = set()
                    node = tks[code]
                    out = self.dump_subtree_sm(node.succ(), ind + "      ", mode, node, visited)
                    code_cnt[out] += 1
                    code_by_node[node]=out
  
                for code in code_cnt.keys():
                    cnt = code_cnt[code]
                    if cnt > 1:
                        nodes_to_merge=[]
                        for i in code_by_node.keys():
                            if code_by_node[i] == code:
                               nodes_to_merge.append(i)
    
                        if mode == "abs":
                            some_merged = self.merge_ids_abs(p, nodes_to_merge, code)
                        else:
                            #print("// ########### Need to implement ##########\n") TODO
                            some_merged = self.merge_ids_rel(p, nodes_to_merge, code)
                        if some_merged:
                            break

                if some_merged:
                    if self.args.dbg > 1:
                        p.st_show_from_node(f"{self.sm_num}_05_during_merging{cnt}", root)
                        p.dump_dot(f"{self.sm_num}_05_during_merging{cnt}", root)
                        cnt += 1
                    break
        #while some_merged

    def merge_ids_abs(self, p, nodes_to_merge, code):
        node_a, node_b = nodes_to_merge[:2]
        self.merge_keeping_first(p, node_a, node_b)
        return True

    def merge_ids_rel(self, p, nodes_to_merge, code):
        node_a, node_b = nodes_to_merge[:2]
        self.merge_keeping_first(p, node_a, node_b)
        return True

    def merge_keeping_first(self, p, node_a, node_b):
        link_type_given_node = p.links_to(node_b)
        nodes_linking_to_b = list(link_type_given_node.keys()) # TODO sort
        #anything pointing to b should now point to a
        for node_from in nodes_linking_to_b:
            link_types = link_type_given_node[node_from]
            for t in link_types:
                if t == "bt":
                    node_from.child[1] = node_a
                if t == "bf":
                    node_from.child[2] = node_a
                if t == "nx":
                    node_from.nxt = node_a
 
        p.node_rm(node_b) #tk removed
        lst = sorted((node_a.code, node_b.code))
        #if self.args.rename_states:
        #   node_a.code = lst[0]
        #else:
        node_a.code= "_".join(lst)

    #--------------------------------------------------------------------
    # code generation
    #--------------------------------------------------------------------
    def find_first_tk(self, p, node):

        def find_first_tk_sub(node):
            if node is None or node.visited:
                return
            node.visited = True
            if node.typ == "tk":
                return node
            lst = (node.child[1], node.child[2], node.child[0], node.nxt)
            for n in lst:
                ntk = find_first_tk_sub(n)
                if ntk is not None:
                    return ntk
 
        for n in p.nodes:
            n.visited = False
        node = find_first_tk_sub(node)
        if node is not None:
            return node
        error("Cannot determine initial state (no `tick?)")


    def state_name(self, node):
        st_name = f"{self.oprefix}S{node.code}";
        if self.args.rename_states:
            renamed = self.rename_state.get(node)
            if renamed is not None:
                st_name = f"{self.oprefix}{renamed}"
        return st_name;

    def dump_tree_sm(self, p, root, ind, line_base, file_base):
        sd = self.args.sd
        tab = self.args.tab
        nxt = self.args.next_suffix
        curr = self.args.curr_suffix
        mode = "rel"
 
        ena_guard = ""
        if self.args.ena != "":
            ena = self.args.ena + str(self.sm_num)
            ena_guard = f"if ({ena}) "
 
        tks={}
        for node in p.nodes:
            if node.typ == "tk":
                tks[node.code] = node
 
        state_bits_m1 = 0
        max_state = 2
        par_out = ""
        for cnt, code in enumerate(sorted(tks.keys())):
            node = tks[code]
            self.rename_state[node] = cnt
            st_name = self.state_name(node)
            par_out += f"localparam {st_name} = {cnt};\n"
            if cnt >= max_state:
                max_state *= 2
                state_bits_m1 += 1
 
        init_state = self.find_first_tk(p, root)
        init_state = self.state_name(init_state)
 
        print()
        print (f"// begin dstate{self.sm_num}")
        indpr(ind, par_out)
 
        # SINGLE BLOCK STYLE
        if self.ff_decl_in != "":
            print(ind + "// SmBegin ff decl begin")
            indpr(ind, self.ff_decl_in)
            print(ind + "// SmBegin ff decl end")
  
        if self.combo_decl_in != "":
            print(ind + "// SmCombo decl begin")
            indpr(ind, self.combo_decl_in)
            print(ind + "// SmCombo decl end")
  
        print(ind + f"always {self.tick} begin : {self.oname}")
  
        if self.ff_local_decl_in != "":
            print(ind + tab + "// SmBegin ff local begin")
            indpr(ind + tab, self.ff_local_decl_in)
            print(ind + tab + "// SmBegin ff local end")
  
        if self.combo_local_decl_in != "":
            print(ind + tab + "// SmCombo local begin")
            indpr(ind + tab, self.combo_local_decl_in)
            print(ind + tab + "// SmCombo local end")
  
        print(ind + tab + f"reg [{state_bits_m1}:0] {self.ostate}{curr}, {self.ostate}{nxt};")
  
        print(ind + tab + f"if ({self.reset_cond}) begin")
        if self.ff_rst_in != "":
            print(ind + 2*tab + "// SmBegin ff init begin")
            indpr(ind + 2*tab, self.ff_rst_in)
            print(ind + 2*tab + "// SmBegin ff init end")
  
        print(ind + 2*tab + f"{self.ostate}{curr} <= {sd}{init_state};")
        print(ind + tab +  "end")
        print(ind + tab + f"else {ena_guard}begin")
        print(ind + 2*tab +f"// set defaults for next state vars begin")
        indpr(ind + 2*tab , self.ff_update_nxt)
        print(ind + 2*tab +f"// set defaults for next state vars end")
        print(ind + 2*tab +f"{self.ostate}{nxt} = {self.ostate}{curr};")
        print(ind + 2*tab +  "// SmForever")
        print(ind + 2*tab + f"case ({self.ostate}{curr})")
  
        for code in sorted(tks.keys()):
            visited = set()
            node = tks[code]
            st_name = self.state_name(node)
            print(ind+ 3*tab + f"{st_name}: begin")
            print(self.dump_subtree_sm(node.succ(), ind + 4*tab, mode, node, visited), end='')
            print(ind+ 3*tab + f"end")
  
        print(ind + 2*tab + "endcase")
        print(ind + 2*tab + "// SmEnd")
        print(ind + 2*tab +f"// Update ffs with next state vars begin")
        indpr(ind + 2*tab , self.ff_update_ffs)
        print(ind + 2*tab +f"// Update ffs with next state vars end")
        print(ind + 2*tab +f"{self.ostate}{curr} <= {sd}{self.ostate}{nxt};")
        print(ind + tab+ "end")
        print(ind + "end")
        if self.args.drop_suffix:
            print(ind + "// drop_suffix begin")
            indpr(ind, self.ff_rename_ffs)
            print(ind + "// drop_suffix end")
 
        print (f"// end dstate{self.sm_num}\n")

    def print_task_update_ffs(self, ind):
        tab = self.args.tab
        print(ind +f"task update_ffs{self.sm_num};")
        print(ind + tab +  "begin")
        indpr(ind + 2*tab , self.ff_update_ffs_beh)
        print(ind + tab +  "end")
        print(ind + "endtask")

    def assign(self, lhs, rhs):
        return f"{lhs} <= {self.args.sd}{rhs}"

    def dump_subtree_sm(self, node, ind, mode, state_node, visited_in):

        visited = set(visited_in) # make a value copy
 
        def flagged_visited(node):
           if visited is not None:
               visited.add(node.uid)
 
        curr = self.args.curr_suffix
        nxt = self.args.next_suffix
        tab = self.args.tab
        out = ""
        while node:
            if visited and node.uid in visited:
               visited_str = ', '.join([str(x) for x in visited])
               self.parser.st_show_from_node(f"error", self.root)
               self.parser.dump_dot(f"error", self.root, msg='loop within '+visited_str, hilight=list(visited))
               error(f"SM{self.sm_num} There is a loop path without `tick within", 
                     f"the set of nodes {visited_str}. Currently @{node.uid}. See error.dot/.dbg")
          
            nx  = node.nxt
            ch1 = node.child[1]
            ch2 = node.child[2]
  
            if node.typ == "eif":
                flagged_visited(node)
                cond = node.code
                if is_one(cond):
                    out += self.dump_subtree_sm(ch1, ind, mode, state_node, visited)
                elif is_zero(cond):
                    n = ch2 if ch2 else nx
                    if n:
                        out += self.dump_subtree_sm(n, ind, mode, state_node, visited)
                else:
                    out += ind + f"if ({cond}) begin\n"
                    out += self.dump_subtree_sm(ch1, ind + tab, mode, state_node, visited)
                    out += ind + "end\n"
                    n = ch2 if ch2 else nx
                    if n:
                        out += ind + "else begin\n"
                        out += self.dump_subtree_sm(n, ind + tab, mode, state_node, visited)
                        out += ind + "end\n"
                node = None
            elif node.typ == "if":
                flagged_visited(node)
                cond = node.code
                if is_one(cond):
                    out += self.dump_subtree_sm(ch1, ind, mode, state_node, visited)
                elif is_zero(cond):
                    out += self.dump_subtree_sm(ch2, ind, mode, state_node, visited)
                else:
                    out += ind + f"if ({cond}) begin" + "\n"
                    out += self.dump_subtree_sm(ch1, ind + tab, mode, state_node, visited)
                    out += ind +  "end\n"
                    if ch2:
                        out += ind + "else begin\n"
                        out += self.dump_subtree_sm(ch2, ind + tab, mode, state_node, visited)
                        out += ind + "end\n"
                node = nx
            elif node.typ == "fo":
                flagged_visited(node)
                cond = node.code
                out += ind + f"for ({cond}) begin" + "\n"
                out += self.dump_subtree_sm(ch1, ind + tab, mode, state_node, visited)
                out += ind + "end\n"
                node = nx
            elif node.typ == "wh":
                flagged_visited(node)
                cond = node.code
                out += ind + f"while ({cond}) begin" + "\n"
                out += self.dump_subtree_sm(ch1, ind + tab, mode, state_node, visited)
                out += ind + "end\n"
                node = nx
            elif node.typ == "sn":
                flagged_visited(node)
                out_code = node.code
                out += ind + f"{out_code};\n"
                node=node.succ()
            elif node.typ == "cm":
                out += ind + f"{node.code}"
                node=node.succ()
            elif node.typ == "cs":
                flagged_visited(node)
                cond = node.code
                out += ind + f"case ({cond})" + "\n"
                out += self.dump_subtree_sm(ch1, ind + tab, mode, state_node, visited)
                out += ind + "endcase\n"
                node = nx
            elif node.typ == "csb":
                flagged_visited(node)
                expr = node.code
                out += ind + f"{expr} begin" + "\n"
                out += self.dump_subtree_sm(ch1, ind + tab, mode, state_node, visited)
                out += ind + "end\n"
                node = nx
            elif node.typ == "tk":
                if mode == "rel" and node == state_node:
                    out += ind + "// stay\n"
                else:
                    state_name = self.state_name(node)
                    out += ind + f"{self.ostate}{nxt} = {state_name};\n"
                node=None
            else:
                out += ind + f"// Ignoring node={node} typ={node.typ} code='{node.code}'"+"\n"
                node=node.succ()
        return out

    def change_assign(self, code):
        inString = False;
        prev = "";
        for i in range(len(code)):
            x1 = code[i]
            x2 = code[i:i+2]
            if inString:
                if x1 == '"' and prev != '\\':
                    inString = False
            else:
                if x1 == '"' and prev != '\\':
                    inString = True
                elif x2 == "<=":
                    lhs = code[0:i]
                    rhs = code[i+2:]
                    return self.assign(lhs, rhs)
            prev = x1
        return code


#--------------------------------------------------------------------
# Misc routines
#--------------------------------------------------------------------
def get_ticks(args):
    tick = "@("
    tick += "negedge " if args.falling_edge else "posedge "
    tick += args.clk
    tick_no_rst = tick + ")"
 
    if not args.sync_rst:
        tick += " or "
        tick += "posedge " if args.high_act_rst else "negedge "
        tick += args.rst
    tick += ")"
    return tick, tick_no_rst


def get_resets(args):
    return (args.rst, f"~{args.rst}") if args.high_act_rst else \
           (f"~{args.rst}", args.rst)

def is_one(expr):
    return re.match(r"\s*1\s*$", expr) or \
           re.match(r"\s*1'b1\s*$", expr) or \
           re.match(r"\s*'b1\s*$", expr)

def is_zero(expr):
    return re.match(r"\s*0\s*$", expr) or \
           re.match(r"\s*1'b0\s*$", expr) or \
           re.match(r"\s*'b0\s*$", expr)

#--------------------------------------------------------------------
# General misc routines
#--------------------------------------------------------------------
def get_base(path):
    path = re.sub('^.*\/', '', path)
    return path

def indpr(indent, txt):
    txt = txt.rstrip()
    for line in txt.split('\n'):
        print(indent + line)

#--------------------------------------------------------------------
# M A I N
#--------------------------------------------------------------------
def mainCmdParser():
    from  argparse import ArgumentParser

    cmdParser = ArgumentParser(epilog='Example: ./dstate.py in.v > out.v\n\n')
    cmdParser.add_argument("file", type=str, default="/dev/stdin",
        help="Input file to process (default, stdin)")

    cmdParser.add_argument("-behav", default=False, action='store_true',
        help="Output is behavioral (default, synthesizable RTL)")

    cmdParser.add_argument("-next_suffix", type=str, default="",
        help="Suffix for next state variables (default, no suffix)")

    cmdParser.add_argument("-curr_suffix", type=str, default="_r",
        help="Suffix for next state variables (default, '_r')")

    cmdParser.add_argument("-drop_suffix", default=False, action='store_true',
        help="Rename FFs to be have no suffix "
             "(see -curr_suffix) outside generated block (default, false)")

    cmdParser.add_argument("-ena", type=str, default="",
        help="If provided generates a enable signal to advance the SM. "
             "this parameter provides the base name of the user provided signal "
             "(default, no enable generated, SM number will be appended)")

    cmdParser.add_argument("-local_next", default=False, action='store_true',
        help="Keep declarations of next state variables local "
             "(default, false)")

    cmdParser.add_argument("-rename_states", default=False, action='store_true',
        help="Rename/simplify merged state constant names (default, false)")

    cmdParser.add_argument("-prefix", type=str, default="SM",
        help="Prefix for state value constants "
             "(default, 'SM' followed by SM instance number)")

    cmdParser.add_argument("-clk", type=str, default="clk",
        help="Clock name (default, 'clk')")

    cmdParser.add_argument("-state", type=str, default="state",
        help="Name of state variable generated "
             "(default, 'state' followed by SM instance number)")

    cmdParser.add_argument("-rst", type=str, default=None,
        help="Reset name (default, 'rst_n' if active low, 'rst' if active high) "
             "see -high_act_rst")

    cmdParser.add_argument("-name", type=str, default="dstate",
        help="Used to derive block name etc. "
             "(default, 'dstate' followed by SM instance number)")

    cmdParser.add_argument("-tab", type=str, default="\t",
        help="Used to indent output (default, uses tabs)")

    cmdParser.add_argument("-sd", type=str, default=None,
        help="Simulation Delay for <= assignements (default, no delay)")

    cmdParser.add_argument("-falling_edge", default=False, action='store_true',
        help="Clock active on falling edge (default, rising)")

    cmdParser.add_argument("-sync_rst", default=False, action='store_true',
        help="Synchronous reset (default, async)")

    cmdParser.add_argument("-high_act_rst", default=False, action='store_true',
        help="Reset active high (default, active low)")

    cmdParser.add_argument("-dbg", type=int, default=0,
        help="Debug Level (default, 0)")

    args = cmdParser.parse_args()
    args.sd = "#" + args.sd + " " if args.sd else ""
    if args.rst is None:
        args.rst = "rst" if args.high_act_rst else "rst_n"
    if args.next_suffix == args.curr_suffix:
        error(f'-next_suffix option cannot match -curr_suffix one: {args.curr_suffix}')
    return args

if __name__=="__main__":
    args = mainCmdParser()
    state = parseInputFile(args.file)
    if state == -2:
        warning("SmBegin section not found")
        sys.exit(0)
    elif state == 0:
        error("SmCombo section not found")
    elif state == 1:
        error("SmForever section not found")
    elif state == 2:
        error("SmEnd not found")
    sys.exit(0)

