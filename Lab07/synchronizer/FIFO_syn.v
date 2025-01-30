module FIFO_syn #(parameter WIDTH=8, parameter WORDS=64) (
    wclk,
    rclk,
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo,

    flag_fifo_to_clk1,
	flag_clk1_to_fifo
);
    //================================================================
    // Input & Output Declaration
    //================================================================
    input wclk, rclk;
    input rst_n;
    input winc;
    input [WIDTH-1:0] wdata;
    output reg wfull;
    input rinc;
    output reg [WIDTH-1:0] rdata;
    output reg rempty;

    //----------------------------------------------------------------
    // Flag Ports
    //----------------------------------------------------------------
    output  flag_fifo_to_clk2;
    input flag_clk2_to_fifo;

    output flag_fifo_to_clk1;
    input flag_clk1_to_fifo;

    //================================================================
    // Parameter & Integer Declaration
    //================================================================
    integer i, j, k, l, m, n; //@suppress


    //================================================================
    // Wire & Reg Declaration
    //================================================================
    wire [$clog2(WORDS):0] wq2_rptr;
    wire [$clog2(WORDS):0] rq2_wptr;
    reg  [$clog2(WORDS):0] wq2_rptr_reg;
    reg  [$clog2(WORDS):0] rq2_wptr_reg;
    reg  [$clog2(WORDS):0] wq2_rptr_bin;
    reg  [$clog2(WORDS):0] rq2_wptr_bin;
    
    wire [WIDTH-1:0] rdata_q;

    reg  [$clog2(WORDS):0] waddr;
    reg  [$clog2(WORDS):0] raddr;

    // Remember: 
    //   wptr and rptr should be gray coded
    //   Don't modify the signal name
    reg  [$clog2(WORDS):0] wptr;
    reg  [$clog2(WORDS):0] rptr;

    //================================================================
    // Design
    //================================================================
    function [$clog2(WORDS):0] gray_to_binary;
        input [$clog2(WORDS):0] gray;
        begin
            gray_to_binary[$clog2(WORDS)] = gray[$clog2(WORDS)];
            for (int i = $clog2(WORDS)-1; i >= 0; i = i - 1) begin
                gray_to_binary[i] = gray[i] ^ gray_to_binary[i+1];
            end
        end
    endfunction

    function [$clog2(WORDS):0] binary_to_gray;
        input [$clog2(WORDS):0] binary;
        begin
            binary_to_gray[$clog2(WORDS)] = binary[$clog2(WORDS)];
            for (int i = $clog2(WORDS)-1; i >= 0; i = i - 1) begin
                binary_to_gray[i] = binary[i] ^ binary[i+1];
            end
        end
    endfunction
            
    NDFF_BUS_syn #(
        .WIDTH($clog2(WORDS)+1)
    ) NDFF_BUS_syn_r2w (
        .D(rptr),
        .Q(wq2_rptr),
        .clk(wclk),
        .rst_n(rst_n)
    );

    NDFF_BUS_syn #(
        .WIDTH($clog2(WORDS)+1)
    ) NDFF_BUS_syn_w2r (
        .D(wptr),
        .Q(rq2_wptr),
        .clk(rclk),
        .rst_n(rst_n)
    );

    DUAL_64X8X1BM1 u_dual_sram (
        .A0(waddr[0]),
        .A1(waddr[1]),
        .A2(waddr[2]),
        .A3(waddr[3]),
        .A4(waddr[4]),
        .A5(waddr[5]),
        .B0(raddr[0]),
        .B1(raddr[1]),
        .B2(raddr[2]),
        .B3(raddr[3]),
        .B4(raddr[4]),
        .B5(raddr[5]),
        .DOA0(),
        .DOA1(),
        .DOA2(),
        .DOA3(),
        .DOA4(),
        .DOA5(),
        .DOA6(),
        .DOA7(),
        .DOB0(rdata_q[0]),
        .DOB1(rdata_q[1]),
        .DOB2(rdata_q[2]),
        .DOB3(rdata_q[3]),
        .DOB4(rdata_q[4]),
        .DOB5(rdata_q[5]),
        .DOB6(rdata_q[6]),
        .DOB7(rdata_q[7]),
        .DIA0(wdata[0]),
        .DIA1(wdata[1]),
        .DIA2(wdata[2]),
        .DIA3(wdata[3]),
        .DIA4(wdata[4]),
        .DIA5(wdata[5]),
        .DIA6(wdata[6]),
        .DIA7(wdata[7]),
        .DIB0(1'd0),
        .DIB1(1'd0),
        .DIB2(1'd0),
        .DIB3(1'd0),
        .DIB4(1'd0),
        .DIB5(1'd0),
        .DIB6(1'd0),
        .DIB7(1'd0),
        .WEAN(wfull | (~winc)),
        .WEBN(1'b1),
        .CKA(wclk),
        .CKB(rclk),
        .CSA(1'b1),
        .CSB(1'b1),
        .OEA(1'b1),
        .OEB(1'b1)
    );

    always @(posedge wclk or negedge rst_n) begin
        if (~rst_n) begin
            waddr <= 0;
        end else begin
            if (winc & ~wfull) begin
                waddr <= waddr + 1;
            end else begin
                waddr <= waddr;
            end
        end
    end

    always @(posedge rclk or negedge rst_n) begin
        if (~rst_n) begin
            raddr <= 0;
        end else begin
            if (rinc & ~rempty) begin
                raddr <= raddr + 1;
            end else begin
                raddr <= raddr;
            end
        end
    end

    always @(posedge wclk or negedge rst_n) begin
        if (~rst_n) begin
            wptr <= 0;
        end else begin
            wptr <= binary_to_gray(waddr);
        end
    end

    always @(posedge rclk or negedge rst_n) begin
        if (~rst_n) begin
            rptr <= 0;
        end else begin
            rptr <= binary_to_gray(raddr);
        end
    end

    always @(posedge wclk or negedge rst_n) begin
        if (~rst_n) begin
            wq2_rptr_reg <= 0;
        end else begin
            wq2_rptr_reg <= wq2_rptr;
        end
    end

    always @(posedge rclk or negedge rst_n) begin
        if (~rst_n) begin
            rq2_wptr_reg <= 0;
        end else begin
            rq2_wptr_reg <= rq2_wptr;
        end
    end

    always @(*) begin
        wq2_rptr_bin = gray_to_binary(wq2_rptr_reg);
        rq2_wptr_bin = gray_to_binary(rq2_wptr_reg);
    end

    always @(*) begin
        wfull  = (wq2_rptr_bin[$clog2(WORDS)] != waddr[$clog2(WORDS)]) && (wq2_rptr_bin[$clog2(WORDS)-1:0] == waddr[$clog2(WORDS)-1:0]);
        rempty = (rq2_wptr_bin == raddr);
    end
    
    always @(posedge rclk or negedge rst_n) begin
        if (~rst_n) begin
            rdata <= 0;
        end else begin
            rdata <= rdata_q;
        end
    end

endmodule
