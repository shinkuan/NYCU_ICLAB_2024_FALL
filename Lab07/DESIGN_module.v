module CLK_1_MODULE (
    clk,
    rst_n,
    in_valid,
	in_row,
    in_kernel,
    out_idle,
    handshake_sready,
    handshake_din,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

	fifo_empty,
    fifo_rdata,
    fifo_rinc,
    out_valid,
    out_data,

    flag_clk1_to_fifo,
    flag_fifo_to_clk1
);
    //================================================================
    // Input & Output Declaration
    //================================================================
    input               clk;
    input               rst_n;
    input               in_valid;
    input       [17:0]  in_row;
    input       [11:0]  in_kernel;
    input               out_idle;
    output reg          handshake_sready;
    output reg  [29:0]  handshake_din;
    // You can use the the custom flag ports for your design
    input               flag_handshake_to_clk1;
    output              flag_clk1_to_handshake;

    input               fifo_empty;
    input       [ 7:0]  fifo_rdata;
    output              fifo_rinc;
    output reg          out_valid;
    output reg  [ 7:0]  out_data;
    // You can use the the custom flag ports for your design
    output              flag_clk1_to_fifo;
    input               flag_fifo_to_clk1;

    //================================================================
    // Parameter & Integer Declaration
    //================================================================
    integer i, j, k, l, m, n; //@suppress

    localparam STATE_IDLE = 4'd0;
    localparam STATE_INPT = 4'd1;
    localparam STATE_SEND = 4'd2;
    localparam STATE_WAIT = 4'd3;
    
    //================================================================
    // Wire & Reg Declaration
    //================================================================
    reg  [ 3:0] cs, ns;

    reg  [ 2:0] matrix [5:0][5:0];
    reg  [ 2:0] kernel [5:0][1:0][1:0];

    reg  [ 8:0] in_cnt;

    reg  [17:0] in_row_reg;
    reg  [11:0] in_kernel_reg;

    //================================================================
    // Design
    //================================================================
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cs <= STATE_IDLE;
        end else begin
            cs <= ns;
        end
    end

    always @(*) begin
        case (cs)
            STATE_IDLE: begin
                ns = in_valid ? STATE_INPT : STATE_IDLE;
            end
            STATE_INPT: begin
                ns = in_cnt == 5 ? STATE_SEND : STATE_INPT;
            end
            STATE_SEND: begin
                ns = handshake_sready ? STATE_SEND : (out_idle ? STATE_WAIT : STATE_SEND);
            end
            STATE_WAIT: begin
                ns = in_cnt == 9'o544 ? STATE_IDLE : STATE_SEND;
            end
            default: begin
                ns = STATE_IDLE;
            end
        endcase
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            in_row_reg <= 0;
            in_kernel_reg <= 0;
        end else begin
            in_row_reg <= in_row;
            in_kernel_reg <= in_kernel;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            in_cnt <= 0;
        end else begin
            case (cs)
                STATE_IDLE: begin
                    in_cnt <= 0;
                end
                STATE_INPT: begin
                    in_cnt <= in_cnt == 5 ? 0 : in_cnt + 1;
                end
                STATE_SEND: begin
                    in_cnt <= in_cnt;
                end
                STATE_WAIT: begin
                    if (in_cnt[2:0] == 4) begin
                        in_cnt[2:0] <= 0;
                        if (in_cnt[5:3] == 4) begin
                            in_cnt[5:3] <= 0;
                            in_cnt[8:6] <= in_cnt[8:6] + 1;
                        end else begin
                            in_cnt[5:3] <= in_cnt[5:3] + 1;
                        end
                    end else begin
                        in_cnt[2:0] <= in_cnt[2:0] + 1;
                    end
                end
                default: begin
                    in_cnt <= in_cnt;
                end
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (i = 0; i < 6; i = i + 1) begin
                for (j = 0; j < 6; j = j + 1) begin
                    matrix[i][j] <= 0;
                end
            end
            for (i = 0; i < 6; i = i + 1) begin
                for (j = 0; j < 2; j = j + 1) begin
                    for (k = 0; k < 2; k = k + 1) begin
                        kernel[i][j][k] <= 0;
                    end
                end
            end
        end else begin
            case (cs)
                STATE_INPT: begin
                    {matrix[in_cnt[2:0]][5], matrix[in_cnt[2:0]][4], matrix[in_cnt[2:0]][3], matrix[in_cnt[2:0]][2], matrix[in_cnt[2:0]][1], matrix[in_cnt[2:0]][0]} <= in_row_reg;
                    {kernel[in_cnt[2:0]][1][1], kernel[in_cnt[2:0]][1][0], kernel[in_cnt[2:0]][0][1], kernel[in_cnt[2:0]][0][0]} <= in_kernel_reg;
                end
                default: begin
                    for (i = 0; i < 6; i = i + 1) begin
                        for (j = 0; j < 6; j = j + 1) begin
                            matrix[i][j] <= matrix[i][j];
                        end
                    end
                    for (i = 0; i < 6; i = i + 1) begin
                        for (j = 0; j < 2; j = j + 1) begin
                            for (k = 0; k < 2; k = k + 1) begin
                                kernel[i][j][k] <= kernel[i][j][k];
                            end
                        end
                    end
                end
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            handshake_sready <= 0;
        end else begin
            case (cs)
                STATE_WAIT: begin
                    handshake_sready <= 1;
                end
                default: begin
                    handshake_sready <= 0;
                end
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            handshake_din <= 0;
        end else begin
            case (cs) 
                STATE_WAIT: begin
                    handshake_din <=   {6'd0, 
                                        kernel[in_cnt[8:6]][1][1],
                                        kernel[in_cnt[8:6]][1][0],
                                        kernel[in_cnt[8:6]][0][1],
                                        kernel[in_cnt[8:6]][0][0],
                                        matrix[in_cnt[5:3]+1][in_cnt[2:0]+1],
                                        matrix[in_cnt[5:3]+1][in_cnt[2:0]  ],
                                        matrix[in_cnt[5:3]  ][in_cnt[2:0]+1],
                                        matrix[in_cnt[5:3]  ][in_cnt[2:0]  ]};
                end
                default: begin
                    handshake_din <= 0;
                end
            endcase
        end
    end
    
    //----------------------------------------------------------------
    // Output
    //----------------------------------------------------------------
    assign fifo_rinc = ~fifo_empty;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out_valid <= 0;
        end else begin
            out_valid <= fifo_rinc;
        end
    end

    // always @(posedge clk or negedge rst_n) begin
    //     if (~rst_n) begin
    //         out_data <= 0;
    //     end else begin
    //         case (cs)
    //             default: begin
    //                 out_data <= 0;
    //             end
    //         endcase
    //     end
    // end
    always @(*) begin
        out_data = out_valid ? fifo_rdata : 0;
    end
    

endmodule

module CLK_2_MODULE (
    clk,
    rst_n,
    in_valid,
    fifo_full,
    in_data,
    out_valid,
    out_data,
    busy,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake,

    flag_fifo_to_clk2,
    flag_clk2_to_fifo
);

    //================================================================
    // Input & Output Declaration
    //================================================================
    input clk;
    input rst_n;
    input in_valid;
    input fifo_full;
    input [29:0] in_data;
    output reg out_valid;
    output reg [7:0] out_data;
    output reg busy;

    // You can use the the custom flag ports for your design
    input  flag_handshake_to_clk2;
    output flag_clk2_to_handshake;

    input  flag_fifo_to_clk2;
    output flag_clk2_to_fifo;

    //================================================================
    // Parameter & Integer Declaration
    //================================================================
    integer i, j, k, l, m, n; //@suppress

    localparam STATE_IDLE = 4'd0;
    localparam STATE_CAL1 = 4'd1;
    localparam STATE_CAL2 = 4'd2;
    localparam STATE_CAL3 = 4'd3;
    localparam STATE_CAL4 = 4'd4;
    localparam STATE_SEND = 4'd5;
    
    //================================================================
    // Wire & Reg Declaration
    //================================================================
    reg  [ 3:0] cs, ns;
    reg  [29:0] data;
    reg  [ 7:0] mac;
    reg  [ 2:0] mac_a, mac_b;

    //================================================================
    // Design
    //================================================================
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            cs <= STATE_IDLE;
        end else begin
            cs <= ns;
        end
    end

    always @(*) begin
        case (cs)
            STATE_IDLE: begin
                ns = in_valid ? STATE_CAL1 : STATE_IDLE;
            end
            STATE_CAL1: begin
                ns = STATE_CAL2;
            end
            STATE_CAL2: begin
                ns = STATE_CAL3;
            end
            STATE_CAL3: begin
                ns = STATE_CAL4;
            end
            STATE_CAL4: begin
                ns = STATE_SEND;
            end
            STATE_SEND: begin
                ns = fifo_full ? STATE_SEND : STATE_IDLE;
            end
            default: begin
                ns = STATE_IDLE;
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data <= 0;
        end else begin
            case (cs)
                STATE_IDLE: begin
                    data <= in_data;
                end
                default: begin
                    data <= data;
                end
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            busy <= 0;
        end else begin
            case (cs)
                STATE_IDLE: begin
                    busy <= in_valid ? 1 : 0;
                end
                STATE_CAL1,
                STATE_CAL2,
                STATE_CAL3,
                STATE_CAL4: begin
                    busy <= 1;
                end
                STATE_SEND: begin
                    busy <= fifo_full ? 1 : 0;
                end
                default: begin
                    busy <= 0;
                end
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out_valid <= 0;
        end else begin
            case (cs)
                STATE_SEND: begin
                    out_valid <= fifo_full ? 0 : 1;
                end
                default: begin
                    out_valid <= 0;
                end
            endcase
        end
    end

    always @(*) begin
        mac = out_data + mac_a * mac_b;
    end
    always @(*) begin
        case (cs)
            STATE_CAL1: begin
                mac_a = data[14:12];
                mac_b = data[2:0];
            end
            STATE_CAL2: begin
                mac_a = data[17:15];
                mac_b = data[5:3];
            end
            STATE_CAL3: begin
                mac_a = data[20:18];
                mac_b = data[8:6];
            end
            STATE_CAL4: begin
                mac_a = data[23:21];
                mac_b = data[11:9];
            end
            default: begin
                mac_a = 0;
                mac_b = 0;
            end
        endcase
    end
    

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            out_data <= 0;
        end else begin
            case (cs)
                STATE_IDLE: begin
                    out_data <= 0;
                end
                STATE_CAL1,
                STATE_CAL2,
                STATE_CAL3,
                STATE_CAL4: begin
                    out_data <= mac;
                end
                STATE_SEND: begin
                    out_data <= out_data;
                end
                default: begin
                    out_data <= 0;
                end
            endcase
        end
    end
    
endmodule