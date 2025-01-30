module Handshake_syn #(parameter WIDTH=8) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    flag_handshake_to_clk1,
    flag_clk1_to_handshake,

    flag_handshake_to_clk2,
    flag_clk2_to_handshake
);
    //================================================================
    // Input & Output Declaration
    //================================================================
    input                   sclk, dclk;
    input                   rst_n;
    input                   sready;
    input      [WIDTH-1:0]  din;
    input                   dbusy;
    output                  sidle;
    output reg              dvalid;
    output reg [WIDTH-1:0]  dout;

    //----------------------------------------------------------------
    // Flag Ports
    //----------------------------------------------------------------
    output reg flag_handshake_to_clk1;
    input      flag_clk1_to_handshake;

    output     flag_handshake_to_clk2;
    input      flag_clk2_to_handshake;

    //================================================================
    // Parameter & Integer Declaration
    //================================================================
    integer i, j, k, l, m, n; //@suppress

    localparam SRC_STATE_IDLE = 4'd0;
    localparam SRC_STATE_BUSY = 4'd1;
    localparam SRC_STATE_WAIT = 4'd2;

    localparam DST_STATE_IDLE = 4'd0;
    localparam DST_STATE_RECV = 4'd1;
    localparam DST_STATE_BUSY = 4'd2;

    //================================================================
    // Request & Acknowledge Signals
    //================================================================
    // Do not modify the name of the signals
    reg     sreq;
    wire    dreq;
    reg     dack;
    wire    sack;

    //================================================================
    // Wire & Reg Declaration
    //================================================================
    reg  [3:0] scs, sns;
    reg  [3:0] dcs, dns;

    reg  [WIDTH-1:0] data;
    
    //================================================================
    // Design
    //================================================================
    //----------------------------------------------------------------
    // NDFF
    //----------------------------------------------------------------
    NDFF_syn NDFF_syn_req (
        .D(sreq),
        .Q(dreq),
        .clk(dclk),
        .rst_n(rst_n)
    );

    NDFF_syn NDFF_syn_ack (
        .D(dack),
        .Q(sack),
        .clk(sclk),
        .rst_n(rst_n)
    );

    //----------------------------------------------------------------
    // State Machine
    //----------------------------------------------------------------
    always @(posedge sclk or negedge rst_n) begin
        if (!rst_n) begin
            scs <= SRC_STATE_IDLE;
        end else begin
            scs <= sns;
        end
    end

    always @(*) begin
        case (scs)
            SRC_STATE_IDLE: begin
                sns = sready ? SRC_STATE_BUSY : SRC_STATE_IDLE;
            end
            SRC_STATE_BUSY: begin
                sns = sack ? SRC_STATE_WAIT : SRC_STATE_BUSY;
            end
            SRC_STATE_WAIT: begin
                sns = sack ? SRC_STATE_WAIT : SRC_STATE_IDLE;
            end
            default: begin
                sns = SRC_STATE_IDLE;
            end
        endcase
    end

    always @(posedge dclk or negedge rst_n) begin
        if (~rst_n) begin
            dcs <= DST_STATE_IDLE;
        end else begin
            dcs <= dns;
        end
    end
    
    always @(*) begin
        case (dcs)
            DST_STATE_IDLE: begin
                dns = dreq ? DST_STATE_RECV : DST_STATE_IDLE;
            end
            DST_STATE_RECV: begin
                dns = dbusy ? DST_STATE_RECV : DST_STATE_BUSY;
            end
            DST_STATE_BUSY: begin
                dns = dreq ? DST_STATE_BUSY : DST_STATE_IDLE;
            end
            default: begin
                dns = DST_STATE_IDLE;
            end
        endcase
    end
    
    //----------------------------------------------------------------
    // NDFF
    //----------------------------------------------------------------
    always @(posedge sclk or negedge rst_n) begin
        if (~rst_n) begin
            sreq <= 0;
        end else begin
            case (scs)
                SRC_STATE_IDLE: begin
                    sreq <= dreq;
                end
                SRC_STATE_BUSY: begin
                    sreq <= 1;
                end
                SRC_STATE_WAIT: begin
                    sreq <= 0;
                end
                default: begin
                    sreq <= 0;
                end
            endcase
        end
    end

    always @(posedge dclk or negedge rst_n) begin
        if (~rst_n) begin
            dack <= 0;
        end else begin
            case (dcs)
                DST_STATE_IDLE: begin
                    dack <= 0;
                end
                DST_STATE_RECV,
                DST_STATE_BUSY: begin
                    dack <= 1;
                end
                default: begin
                    dack <= dack;
                end
            endcase
        end
    end

    //----------------------------------------------------------------
    // Data
    //----------------------------------------------------------------
    always @(posedge sclk or negedge rst_n) begin
        if (~rst_n) begin
            data <= 0;
        end else begin
            if (scs == SRC_STATE_IDLE) begin
                data <= din;
            end else begin
                data <= data;
            end
        end
    end

    always @(posedge dclk or negedge rst_n) begin
        if (~rst_n) begin
            dout <= 0;
        end else begin
            if (dcs == DST_STATE_RECV) begin
                dout <= data;
            end else begin
                dout <= dout;
            end
        end
    end

    //----------------------------------------------------------------
    // Output
    //----------------------------------------------------------------
    assign sidle = (scs == SRC_STATE_IDLE) ? 1 : 0;

    always @(posedge dclk or negedge rst_n) begin
        if (~rst_n) begin
            dvalid <= 0;
        end else begin
            case (dcs)
                DST_STATE_IDLE: begin
                    dvalid <= 0;
                end
                DST_STATE_RECV: begin
                    dvalid <= 1;
                end
                DST_STATE_BUSY: begin
                    dvalid <= 0;
                end
                default: begin
                    dvalid <= 0;
                end
            endcase
        end
    end


endmodule