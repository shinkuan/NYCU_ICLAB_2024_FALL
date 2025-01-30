`define CYCLE_TIME 7.0
`ifdef RTL
    `define CYCLE_TIME 7.0
`endif
`ifdef GATE
    `define CYCLE_TIME 7.0
`endif
`ifdef POST
    `define CYCLE_TIME 7.0
`endif

`define SEED_NUMBER     9532
`define PATTERN_NUMBER  10000

module PATTERN(
    // Output signals
    clk,
    rst_n,
    
    in_valid,
    in_valid2,
    
    image,
    template,
    image_size,
    action,

    // Input signals
    out_valid,
    out_value
);

    //================================================================
    // I/O declaration
    //================================================================
    // Output
    output reg       clk, rst_n;
    output reg       in_valid;
    output reg       in_valid2;

    output reg [7:0] image;
    output reg [7:0] template;
    output reg [1:0] image_size;
    output reg [2:0] action;

    // Input
    input out_valid;
    input out_value;

    //================================================================
    // clock
    //================================================================
    real CYCLE = `CYCLE_TIME;
    always #(CYCLE/2.0) clk = ~clk; // @suppress

    // int  SEED           = 62910358;
    int  SEED           = get_time();
    real PATTERN_NUM    = `PATTERN_NUMBER;

    //================================================================
    // integer & parameter
    //================================================================
    integer i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z; // @suppress
    integer mid_action_count; // 0 ~ 6
    integer size_add_back;

    integer latency;
    integer total_latency;

    //================================================================
    // wire & reg
    //================================================================
    reg  [01:0] image_size_reg;
    reg  [07:0] image_reg       [02:0][15:0][15:0];     // COLOR, Y, X
    reg  [02:0] action_reg      [07:0][07:0];           // SET, ACTION
    reg  [07:0] template_reg    [02:0][02:0];           // Y, X

    reg  [07:0] gray_scale_reg_old  [15:0][15:0];           // Y, X
    reg  [07:0] gray_scale_reg  [15:0][15:0];           // Y, X
    reg  [19:0] golden_result   [15:0][15:0];           // Y, X
    reg  [07:0] in_cro          [2:0][2:0];

    //================================================================
    // design
    //================================================================
    initial begin
        `ifdef SHINKUAN
            $display("**************************************************");
            $display("            PATTERN MADE BY SHIN-KUAN             ");
            $display("**************************************************");
        `endif
        $display("\033[33m██╗      █████╗ ██████╗      ██████╗ ███████╗\033[0m");
        $display("\033[33m██║     ██╔══██╗██╔══██╗    ██╔═████╗██╔════╝\033[0m");
        $display("\033[33m██║     ███████║██████╔╝    ██║██╔██║███████║\033[0m");
        $display("\033[33m██║     ██╔══██║██╔══██╗    ████╔╝██║╚════██║\033[0m");
        $display("\033[33m███████╗██║  ██║██████╔╝    ╚██████╔╝███████║\033[0m");
        $display("\033[33m╚══════╝╚═╝  ╚═╝╚═════╝      ╚═════╝ ╚══════╝\033[0m");
        $display("Seed: %d", SEED);
        latency = 0;
        total_latency = 0;
        reset;
        for (int pat_id = 0; pat_id < PATTERN_NUM; pat_id = pat_id+1) begin
            $display(">===============================<");
            $display("           PATTERN %d", pat_id);
            $display(">===============================<");
            generate_img_size;
            generate_image;
            generate_template;
            generate_action;
            send_in_valid1;
            repeat (2+{$random}%3) @(negedge clk);
            for (int action_set_count = 0; action_set_count < 8; action_set_count = action_set_count + 1) begin
                $display("Action Set %d", action_set_count);
                send_in_valid2(action_set_count);
                golden_calculation(action_set_count);
                wait_out;
                verify_out;
                $display("Latecy: %d", latency);
                repeat (1+{$random}%3) @(negedge clk);
            end
        end
        
        $display("\033[32m");
        $display("**************************************************");
        $display("                 ALL PATTERN PASS                 ");
        $display("**************************************************");
        $display("                    SEED: %d", SEED);
        $display("           Total Latency: %d cycles", total_latency);
        $display("\033[33m /| ､\033[0m");
        $display("\033[33m(°､ ｡ 7\033[0m");
        $display("\033[33m |､  ~ヽ\033[0m");
        $display("\033[33m じしf_,)〳\033[0m");
        $finish;
    end
    
    function integer get_time();
        int    file_pointer;
        int    t;

        void'($system("date +%N > sys_time"));
        file_pointer = $fopen("sys_time","r");
        void'($fscanf(file_pointer,"%d",t));
        $fclose(file_pointer);
        void'($system("rm sys_time"));
        return t;
    endfunction

    task reset; begin
        force clk   = 0;
        rst_n       = 1'b1;
        in_valid    = 1'b0;
        in_valid2   = 1'b0;
        image       = 8'bX;
        template    = 8'bX;
        image_size  = 2'bX;
        action      = 3'bX;
        #50;
        rst_n = 0;
        #100;
        rst_n = 1;
        #50;
        release clk;
        repeat (2) @(negedge clk);
    end endtask

    task generate_img_size; begin
        image_size_reg = 0 + {$random(SEED)}%(3); // 0 ~ 2
    end endtask

    task generate_image; begin
        integer i, j, k;
        for (i = 0; i < 3; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                for (k = 0; k < 16; k = k + 1) begin
                    image_reg[i][j][k] = 0 + {$random(SEED)}%(256); 
                end
            end
        end
    end endtask

    task generate_template; begin
        integer i, j;
        for (i = 0; i < 3; i = i + 1) begin
            for (j = 0; j < 3; j = j + 1) begin
                template_reg[i][j] = 0 + {$random(SEED)}%(256); 
            end
        end
    end endtask

    task generate_action; begin
        integer i, j;
        for (i = 0; i < 8; i = i + 1) begin
            mid_action_count = 0 + {$random(SEED)}%(7);
            action_reg[i][0] = 0 + {$random(SEED)}%(3); // 0 ~ 2
            for (j = 1; j < mid_action_count+1; j = j + 1) begin
                action_reg[i][j] = 3 + {$random(SEED)}%(4); // 3 ~ 6
            end
            action_reg[i][mid_action_count+1] = 7;
        end
    end endtask
    
    task send_in_valid1; begin
        in_valid = 1'b1;
        fork
            send_image_size;
            send_image;
            send_template;
        join
        in_valid = 1'b0;
    end endtask

    task send_image_size; begin
        image_size = image_size_reg;
        @(negedge clk);
        image_size = 2'bX;
    end endtask

    task send_image; begin
        integer i, j, k, size;
        case(image_size_reg)
            2'd0: size = 4;
            2'd1: size = 8;
            2'd2: size = 16;
            default: size = 0;
        endcase
        for (j = 0; j < size; j = j + 1) begin
            for (k = 0; k < size; k = k + 1) begin
                for (i = 0; i < 3; i = i + 1) begin
                    image = image_reg[i][j][k];
                    @(negedge clk);
                end
            end
        end
        image = 8'bX;
    end endtask

    task send_template; begin
        integer i, j;
        for (i = 0; i < 3; i = i + 1) begin
            for (j = 0; j < 3; j = j + 1) begin
                template = template_reg[i][j];
                @(negedge clk);
            end
        end
        template = 8'bX;
    end endtask

    task send_in_valid2; 
        input [2:0] action_set_count;
    begin
        in_valid2 = 1'b1;
        fork
            send_action(action_set_count);
        join
        in_valid2 = 1'b0;
    end endtask

    task send_action; 
        input [2:0] action_set_count;
    begin
        integer i;
        for (i = 0; i < 8; i = i + 1) begin
            action = action_reg[action_set_count][i];
            @(negedge clk);
            if (action == 7) begin
                break;
            end
        end
        action = 3'bX;
    end endtask

    task wait_out; begin
        latency = 1;
        while (out_valid !== 1'b1) begin
            latency = latency + 1;
            @(negedge clk);
        end
        total_latency = total_latency + latency;
    end endtask

    task verify_out; begin
        integer i, j, k, size;
        integer error_flag = 0;
        reg [19:0] get_result;
        case(image_size_reg)
            2'd0: size = 4;
            2'd1: size = 8;
            2'd2: size = 16;
            default: size = 0;
        endcase

        for (i = 0; i < size; i = i + 1) begin
            for (j = 0; j < size; j = j + 1) begin
                for (k = 19; k >= 0; k = k - 1) begin
                    get_result[k] = out_value;
                    if (golden_result[i][j][k] !== out_value) begin
                        error_flag = 1;
                    end
                    @(negedge clk);
                end
                if (error_flag == 1) begin
                    $display("ERROR: Output is not correct");
                    $display("golden_result[%d][%d] = %b", i, j, golden_result[i][j]);
                    $display("get_result = %b", get_result);
                    #100;
                    $finish;
                end
            end
        end

        if (error_flag == 1) begin
            $display("ERROR: Output is not correct");
        end

        spec22_checker;
        image_size_reg = image_size_reg + size_add_back;

    end endtask

    task golden_calculation; 
        input [2:0] action_set_count;
    begin
        integer i, j, k, l, m, n, o, p, q, size;
        integer max0, max1, max2;
        logic [7:0] in [8:0];
        size_add_back = 0;
        case(image_size_reg)
            2'd0: size = 4;
            2'd1: size = 8;
            2'd2: size = 16;
            default: size = 0;
        endcase
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                case(action_reg[action_set_count][0])
                    2'd0: begin
                        gray_scale_reg[i][j] = image_reg[0][i][j];
                        gray_scale_reg[i][j] = (image_reg[1][i][j] > gray_scale_reg[i][j]) ? image_reg[1][i][j] : gray_scale_reg[i][j];
                        gray_scale_reg[i][j] = (image_reg[2][i][j] > gray_scale_reg[i][j]) ? image_reg[2][i][j] : gray_scale_reg[i][j];
                    end
                    2'd1: begin
                        gray_scale_reg[i][j] = (image_reg[0][i][j] + image_reg[1][i][j] + image_reg[2][i][j]) / 3;
                    end
                    2'd2: begin
                        gray_scale_reg[i][j] = (image_reg[0][i][j] >> 2) + (image_reg[1][i][j] >> 1) + (image_reg[2][i][j] >> 2);
                    end
                    default: begin
                        $display("ERROR: action_reg[action_set_count][0] = %d", action_reg[action_set_count][0]);
                        gray_scale_reg[i][j] = 0;
                    end
                endcase
            end
        end
        #1;
        for (i = 1; i < 8; i = i + 1) begin
            if (action_reg[action_set_count][i] == 7) begin
                break;
            end
            for (j = 0; j < size; j = j + 1) begin
                for (k = 0; k < size; k = k + 1) begin
                    gray_scale_reg_old[j][k] = gray_scale_reg[j][k];
                end
            end
            case(action_reg[action_set_count][i])
                3'd3: begin
                    // Max pooling
                    if (size == 4) begin
                        continue;
                    end
                    for (j = 0; j < size; j = j + 2) begin
                        for (k = 0; k < size; k = k + 2) begin
                            gray_scale_reg[j/2][k/2] = gray_scale_reg_old[j][k];
                            max1 = gray_scale_reg_old[j][k+1] > gray_scale_reg_old[j][k] ? gray_scale_reg_old[j][k+1] : gray_scale_reg_old[j][k];
                            max2 = gray_scale_reg_old[j+1][k] > gray_scale_reg_old[j+1][k+1] ? gray_scale_reg_old[j+1][k] : gray_scale_reg_old[j+1][k+1];
                            max0 = max1 > max2 ? max1 : max2;
                            gray_scale_reg[j/2][k/2] = max0;
                        end
                    end
                    image_size_reg = image_size_reg - 1;
                    size_add_back = size_add_back + 1;
                    size = size / 2;
                end
                3'd4: begin
                    // Negative
                    for (j = 0; j < size; j = j + 1) begin
                        for (k = 0; k < size; k = k + 1) begin
                            gray_scale_reg[j][k] = 255 - gray_scale_reg_old[j][k];
                        end
                    end
                end
                3'd5: begin
                    // Horizontal flip
                    for (j = 0; j < size; j = j + 1) begin
                        for (k = 0; k < size/2; k = k + 1) begin
                            gray_scale_reg[j][k] = gray_scale_reg_old[j][size-k-1];
                            gray_scale_reg[j][size-k-1] = gray_scale_reg_old[j][k];
                        end
                    end
                end
                3'd6: begin
                    // Median filter
                    for (j = 0; j < size; j = j + 1) begin
                        for (k = 0; k < size; k = k + 1) begin
                            l = (j == 0) ? 0 : j-1;
                            m = (j == size-1) ? size-1 : j+1;
                            n = (k == 0) ? 0 : k-1;
                            o = (k == size-1) ? size-1 : k+1;
                            in[0] = gray_scale_reg_old[l][n];
                            in[1] = gray_scale_reg_old[l][k];
                            in[2] = gray_scale_reg_old[l][o];
                            in[3] = gray_scale_reg_old[j][n];
                            in[4] = gray_scale_reg_old[j][k];
                            in[5] = gray_scale_reg_old[j][o];
                            in[6] = gray_scale_reg_old[m][n];
                            in[7] = gray_scale_reg_old[m][k];
                            in[8] = gray_scale_reg_old[m][o];
                            for (p = 0; p < 9; p = p + 1) begin
                                for (q = 0; q < 8; q = q + 1) begin
                                    if (in[q] >= in[q+1]) begin
                                        r = in[q];
                                        in[q] = in[q+1];
                                        in[q+1] = r;
                                    end
                                end
                            end
                            gray_scale_reg[j][k] = in[4];
                        end
                    end
                end
                default: begin
                    $display("ERROR: action_reg[action_set_count][%d] = %d", i, action_reg[action_set_count][i]);
                end
            endcase
            #1;
        end
        #1;
        for (j = 0; j < size; j = j + 1) begin
            for (k = 0; k < size; k = k + 1) begin
                gray_scale_reg_old[j][k] = gray_scale_reg[j][k];
            end
        end
        for (i = 0; i < size; i = i + 1) begin
            for (j = 0; j < size; j = j + 1) begin
                in_cro[0][0] = (i == 0 || j == 0) ? 0 : gray_scale_reg_old[i-1][j-1];
                in_cro[0][1] = (i == 0) ? 0 : gray_scale_reg_old[i-1][j];
                in_cro[0][2] = (i == 0 || j == size-1) ? 0 : gray_scale_reg_old[i-1][j+1];
                in_cro[1][0] = (j == 0) ? 0 : gray_scale_reg_old[i][j-1];
                in_cro[1][1] = gray_scale_reg_old[i][j];
                in_cro[1][2] = (j == size-1) ? 0 : gray_scale_reg_old[i][j+1];
                in_cro[2][0] = (i == size-1 || j == 0) ? 0 : gray_scale_reg_old[i+1][j-1];
                in_cro[2][1] = (i == size-1) ? 0 : gray_scale_reg_old[i+1][j];
                in_cro[2][2] = (i == size-1 || j == size-1) ? 0 : gray_scale_reg_old[i+1][j+1];
                golden_result[i][j] = 0;
                for (k = 0; k < 3; k = k + 1) begin
                    for (l = 0; l < 3; l = l + 1) begin
                        golden_result[i][j] = golden_result[i][j] + in_cro[k][l] * template_reg[k][l];
                    end
                end
            end
        end
    end endtask

    always @(negedge rst_n) #20 spec8_checker;
    task spec8_checker; begin
        if (out_value !== 1'b0 || out_valid) begin
            $display("\033[31m");
            $display("**************************************************");
            $display("              SPEC4 CHECKER ERROR                 ");
            $display("**************************************************");
            $display("out_value and out_valid should be reset to 0 after reset at %d", $time);
            $display("out_value: %H, out_valid: %b", out_value, out_valid);
            $display("\033[0m");
            repeat (20) @(negedge clk);
            $finish(1);
        end
    end endtask

    always @(*) spec19_checker;
    task spec19_checker; begin
        if ((out_valid && in_valid) || (out_valid && in_valid2)) begin
            $display("\033[31m");
            $display("**************************************************");
            $display("              SPEC19 CHECKER ERROR                 ");
            $display("**************************************************");
            $display("out_valid should not overlap with in_valid or in_valid2 at %d", $time);
            $display("\033[0m");
            repeat (20) @(negedge clk);
            $finish(1);
        end
    end endtask
    
    task spec22_checker; begin
        if (out_valid) begin
            $display("\033[31m");
            $display("**************************************************");
            $display("              SPEC22 CHECKER ERROR                 ");
            $display("**************************************************");
            $display("out_valid should be 0 after output finished. at %d", $time);
            $display("\033[0m");
            repeat (20) @(negedge clk);
            $finish(1);
        end
    end endtask

    always @(negedge clk) spec0_checker;
    task spec0_checker; begin
        if (out_value===1'b1 && out_valid!==1'b1) begin
            $display("\033[31m");
            $display("**************************************************");
            $display("              SPEC0 CHECKER ERROR                 ");
            $display("**************************************************");
            $display("out_value sould be 0 when out_valid is 0 at %d", $time);
            $display("\033[0m");
            repeat (20) @(negedge clk);
            $finish(1);
        end
    end endtask

endmodule
