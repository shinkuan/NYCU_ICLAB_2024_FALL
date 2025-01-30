module BB(
    //Input Ports
    input clk,
    input rst_n,
    input in_valid,
    input [1:0] inning, // Current inning number
    input half, // 0: top of the inning, 1: bottom of the inning
    input [2:0] action, // Action code

    //Output Ports
    output reg out_valid, // Result output valid
    output reg [7:0] score_A, // Score of team A (guest team)
    output reg [7:0] score_B, // Score of team B (home team)
    output reg [1:0] result // 0: Team A wins, 1: Team B wins, 2: Darw
);

    //==============================================//
    //             Action Memo for Students         //
    // Action code interpretation:
    // 3’d0: Walk (BB)
    // 3’d1: 1H (single hit)
    // 3’d2: 2H (double hit)
    // 3’d3: 3H (triple hit)
    // 3’d4: HR (home run)
    // 3’d5: Bunt (short hit)
    // 3’d6: Ground ball
    // 3’d7: Fly ball
    //==============================================//

    //==============================================//
    //             Parameter and Integer            //
    //==============================================//
    // State declaration for FSM
    // Example: parameter IDLE = 3'b000;

    //----------------------------------------------//
    //                    Actions                   //
    //----------------------------------------------//
    // Four Bad Ball
    localparam WALK = 3'd0;
    // Single Hit
    localparam ONE_H = 3'd1;
    // Double Hit
    // Note: When 2out, runner run one more base.
    localparam TWO_H = 3'd2;
    // Triple Hit
    localparam THREE_H = 3'd3;
    // Home Run
    localparam HR = 3'd4;
    // Bunt (short hit)
    // Note: Only happen when 0 or 1 out.
    // Note: The hitter is out, but the runner can run one more base.
    localparam BUNT = 3'd5;
    // Ground Ball
    // Note: Both the hitter and the runner at 1B are out.
    // Note: Remaining runners can run one more base.
    // Note: Scores doesn't count when 3 out.
    localparam GROUND_BALL = 3'd6;
    // Fly Ball
    // Note: Hitter out.
    // Note: Runners dont move except for the B3.
    // Note: Scores doesn't count when 3 out.
    localparam FLY_BALL = 3'd7;

    //==============================================//
    //                wire declaration              //
    //==============================================//
    wire is_two_out;
    wire [1:0] B2pB3;
    wire [1:0] B1pB2pB3;
    wire [3:0] added_score;
    wire [3:0] chosed_score;
    wire score_A_lt_score_B;
    wire [3:0] zero;

    //==============================================//
    //                 reg declaration              //
    //==============================================//
    reg B1, B2, B3; // Base status
    reg B1_next, B2_next, B3_next; // Base status next
    reg [1:0] out_count; // Out count
    reg [1:0] out_count_next; // Out count next
    reg is_three_out;
    reg [2:0] add_score; // Add score
    reg B_early_win; // Early win flag
    reg out_valid_state; // Output valid state
    // reg [1:0] cs, ns; // Current state, Next state


    //==============================================//
    //             Current State Block              //
    //==============================================//


    //==============================================//
    //              Next State Block                //
    //==============================================//


    //==============================================//
    //             Base and Score Logic             //
    //==============================================//
    assign B2pB3 = B2+B3;
    assign B1pB2pB3 = B1+B2pB3;
    assign added_score = chosed_score + add_score;
    assign chosed_score = {4{in_valid}} & (half ? score_B[3:0] : score_A[3:0]);
    assign score_A_lt_score_B = score_A < score_B;
    assign zero = 4'd0;
    
    //----------------------------------------------//
    //                      B1                      //
    //----------------------------------------------//
    always @(*) begin
        if (is_three_out || !in_valid) begin
            B1_next = 1'b0;
        end else begin
            case (action)
                WALK: begin
                    B1_next = 1'b1;
                end
                ONE_H: begin
                    B1_next = 1'b1;
                end
                TWO_H: begin
                    B1_next = 1'b0;
                end
                THREE_H: begin
                    B1_next = 1'b0;
                end
                HR: begin
                    B1_next = 1'b0;
                end
                BUNT: begin
                    B1_next = 1'b0;
                end
                GROUND_BALL: begin
                    B1_next = 1'b0;
                end
                FLY_BALL: begin
                    B1_next = B1;
                end
                default: begin
                    // Never reach here
                    B1_next = B1;
                end
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            B1 <= 1'b0;
        end else begin
            B1 <= B1_next;
        end
    end
    
    //----------------------------------------------//
    //                      B2                      //
    //----------------------------------------------//
    always @(*) begin
        if (is_three_out || !in_valid) begin
            B2_next = 1'b0;
        end else begin
            case (action)
                WALK: begin
                    B2_next = B1 || (!B1 && B2);
                end
                ONE_H: begin
                    B2_next = is_two_out ? 1'b0 : B1;
                end
                TWO_H: begin
                    B2_next = 1'b1;
                end
                THREE_H: begin
                    B2_next = 1'b0;
                end
                HR: begin
                    B2_next = 1'b0;
                end
                BUNT: begin
                    B2_next = B1;
                end
                GROUND_BALL: begin
                    B2_next = 1'b0;
                end
                FLY_BALL: begin
                    B2_next = B2;
                end
                default: begin
                    // Never reach here
                    B2_next = B2;
                end
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            B2 <= 1'b0;
        end else begin
            B2 <= B2_next;
        end
    end

    //----------------------------------------------//
    //                      B3                      //
    //----------------------------------------------//
    always @(*) begin
        if (is_three_out || !in_valid) begin
            B3_next = 1'b0;
        end else begin
            case (action)
                WALK: begin
                    B3_next = (B2 && B1) || (B3 && ({B2, B1}!=3'b11));
                end
                ONE_H: begin
                    B3_next = is_two_out ? B1 : B2;
                end
                TWO_H: begin
                    B3_next = is_two_out ? 1'b0 : B1;
                end
                THREE_H: begin
                    B3_next = 1'b1;
                end
                HR: begin
                    B3_next = 1'b0;
                end
                BUNT: begin
                    B3_next = B2;
                end
                GROUND_BALL: begin
                    B3_next = B2;
                end
                FLY_BALL: begin
                    B3_next = 1'b0;
                end
                default: begin
                    // Never reach here
                    B3_next = B2;
                end
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            B3 <= 1'b0;
        end else begin
            B3 <= B3_next;
        end
    end

    //----------------------------------------------//
    //                  out_count                   //
    //----------------------------------------------//
    assign is_two_out = (out_count == 2'd2);
    always @(*) begin
        if (!in_valid) begin
            is_three_out = 1'b0;
        end else begin
            case (action)
                WALK: begin
                    is_three_out = 1'b0;
                end
                ONE_H: begin
                    is_three_out = 1'b0;
                end
                TWO_H: begin
                    is_three_out = 1'b0;
                end
                THREE_H: begin
                    is_three_out = 1'b0;
                end
                HR: begin
                    is_three_out = 1'b0;
                end
                BUNT: begin
                    is_three_out = (out_count == 2'd2);
                end
                GROUND_BALL: begin
                    is_three_out = (out_count == 2'd2) || (B1 && out_count == 2'd1);
                end
                FLY_BALL: begin
                    is_three_out = (out_count == 2'd2);
                end
                default: begin
                    // Never reach here
                    is_three_out = 1'b0;
                end
            endcase
        end
    end
    
    always @(*) begin
        if (is_three_out || !in_valid) begin
            out_count_next = 2'd0;
        end else begin
            case (action)
                WALK: begin
                    out_count_next = out_count;
                end
                ONE_H: begin
                    out_count_next = out_count;
                end
                TWO_H: begin
                    out_count_next = out_count;
                end
                THREE_H: begin
                    out_count_next = out_count;
                end
                HR: begin
                    out_count_next = out_count;
                end
                BUNT: begin
                    out_count_next = out_count + 1;
                end
                GROUND_BALL: begin
                    // Since we already check is_three_out, we can
                    // let out_count_next = 2'd2 directly instead 
                    // of let out_count_next = out_count + 2.
                    out_count_next = B1 ? 2'd2 : out_count + 1;
                end
                FLY_BALL: begin
                    out_count_next = out_count + 1;
                end
                default: begin
                    // Never reach here
                    out_count_next = out_count;
                end
            endcase
        end
    end
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            out_count <= 2'd0;
        end else begin
            out_count <= out_count_next;
        end
    end
    
    //----------------------------------------------//
    //                  add_score                   //
    //----------------------------------------------//
    always @(*) begin
        if (is_three_out || !in_valid) begin
            add_score = 3'd0;
        end else begin
            case (action)
                WALK: begin
                    add_score = {2'b00, B1&&B2&&B3};
                end
                ONE_H: begin
                    add_score = is_two_out ? B2pB3 : {2'b00, B3};
                end
                TWO_H: begin
                    add_score = is_two_out ? B1pB2pB3 : B2pB3;
                end
                THREE_H: begin
                    add_score = B1pB2pB3;
                end
                HR: begin
                    add_score = B1pB2pB3+1;
                end
                BUNT: begin
                    add_score = {2'b00, B3};
                end
                GROUND_BALL: begin
                    add_score = {2'b00, B3};
                end
                FLY_BALL: begin
                    add_score = {2'b00, B3};
                end
                default: begin
                    // Never reach here
                    add_score = 3'd0;
                end
            endcase
        end
    end

    //----------------------------------------------//
    //                  B_early_win                 //
    //----------------------------------------------//
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            B_early_win <= 1'b0;
        end else
        if (out_valid) begin
            // Prevent early win flag affect the result
            B_early_win <= 1'b0;
        end else
        if ((inning == 2'd3) && !half && is_three_out) begin
            // Check early win when first half of the 3rd inning is over
            B_early_win <= (score_A_lt_score_B);
        end else begin
            B_early_win <= B_early_win;
        end
    end

    //==============================================//
    //                Output Block                  //
    //==============================================//
    //----------------------------------------------//
    //                  score_A                     //
    //----------------------------------------------//
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            score_A[3:0] <= 4'd0;
        end else
        if (out_valid) begin
            score_A[3:0] <= 4'd0;
        end else
        if (is_three_out || half || !in_valid) begin
            score_A[3:0] <= score_A[3:0];
        end else begin
            score_A[3:0] <= added_score;
        end
    end
    always @(*) begin
        score_A[7:4] = zero;
    end
    

    //----------------------------------------------//
    //                  score_B                     //
    //----------------------------------------------//
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            score_B[3:0] <= 4'd0;
        end else
        if (out_valid) begin
            score_B[3:0] <= 4'd0;
        end else
        if (is_three_out || !half || B_early_win || !in_valid) begin
            score_B[3:0] <= score_B[3:0];
        end else begin
            score_B[3:0] <= added_score;
        end
    end
    always @(*) begin
        score_B[7:4] = zero;
    end

    //----------------------------------------------//
    //                  result                      //
    //----------------------------------------------//
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            result <= 2'd0;
        end else begin
            case (1'b1)
                out_valid_state: result <= 2'd0;
                score_A == score_B: result <= 2'd2;
                default: result <= (score_A_lt_score_B) ? 2'd1 : 2'd0;
            endcase
        end
    end

    //----------------------------------------------//
    //              out_valid_state                 //
    //----------------------------------------------//
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            out_valid_state <= 1'b1;
        end else begin
            case (1'b1)
                out_valid: out_valid_state <= 1'b1;
                in_valid: out_valid_state <= 1'b0;
                default: out_valid_state <= out_valid_state;
            endcase
        end
    end

    //----------------------------------------------//
    //                  out_valid                   //
    //----------------------------------------------//
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0) begin
            out_valid <= 1'b0;
        end else begin
            case (1'b1)
                out_valid: out_valid <= 1'b0;
                out_valid_state: out_valid <= 1'b0;
                default: out_valid <= !in_valid;
            endcase
        end
    end

endmodule
