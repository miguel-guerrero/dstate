`define wait1(cond) `tick; while(~(cond)) `tick 
`define wait0(cond)        while(~(cond)) `tick 
`define incr(x, amnt=1'b1)  x = x + amnt
`define loop(var, val='b0)  var = val; do begin
`define next(var, limit, inc=1'b1) var = var + inc; end while(var != limit)
