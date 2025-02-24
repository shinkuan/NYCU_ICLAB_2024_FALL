
module NDFF_syn(D, Q, clk, rst_n);
input D;
input clk;
input rst_n;  

output Q;

reg A1,A2;

assign Q = A2;

always @(posedge clk or negedge rst_n) // @suppress "Behavior-specific 'always' should be used instead of general purpose 'always'"
begin
    if(!rst_n)
        A1 <= 0;
    else
        A1 <= D;  
end

always @(posedge clk or negedge rst_n) // @suppress "Behavior-specific 'always' should be used instead of general purpose 'always'"
begin
    if(!rst_n)
        A2 <= 0;
    else
        A2 <= A1;  
end

endmodule