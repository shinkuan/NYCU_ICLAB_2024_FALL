`define CYCLE_TIME 20.0
`ifdef RTL
    `define CYCLE_TIME 20.0
`endif
`ifdef GATE
    `define CYCLE_TIME 20.0
`endif

`define RANDOM_SEED     // Comment this line to use fixed seed
`define SEED_NUMBER     9532
`define PATTERN_NUMBER  100000

module PATTERN #(parameter IP_BIT = 8)(
    //Output Port
    IN_code,
    //Input Port
	OUT_code
);
    //=========================================
    // Input & Output
    //=========================================
    output reg [IP_BIT+4-1:0] IN_code;
    input [IP_BIT-1:0] OUT_code;

    //================================================================
    // clock
    //================================================================
    `ifdef RANDOM_SEED
    int  SEED           = get_time();
    `else
    int  SEED           = `SEED_NUMBER;
    `endif
    real PATTERN_NUM    = `PATTERN_NUMBER;

    //================================================================
    // wire & reg
    //================================================================
    reg [0:IP_BIT-1]   code;
    reg [1:IP_BIT+4] encode;

    //================================================================
    // Design
    //================================================================
    initial begin
        `ifdef SHINKUAN
        $display("**************************************************");
        $display("            PATTERN MADE BY SHIN-KUAN             ");
        $display("**************************************************");
        `endif
        $display("\033[33m██╗      █████╗ ██████╗      ██████╗  ██████╗ \033[0m");
        $display("\033[33m██║     ██╔══██╗██╔══██╗    ██╔═████╗██╔════╝ \033[0m");
        $display("\033[33m██║     ███████║██████╔╝    ██║██╔██║███████╗ \033[0m");
        $display("\033[33m██║     ██╔══██║██╔══██╗    ████╔╝██║██╔═══██╗\033[0m");
        $display("\033[33m███████╗██║  ██║██████╔╝    ╚██████╔╝╚██████╔╝\033[0m");
        $display("\033[33m╚══════╝╚═╝  ╚═╝╚═════╝      ╚═════╝  ╚═════╝ \033[0m");
        $display("\033[32mSeed: %d\033[0m", SEED);
        $display("\033[32mPattern Number: %d\033[0m", PATTERN_NUM);
        $display("==================================================");
        for (int i = 0; i < PATTERN_NUM; i = i + 1) begin
            generate_code();
            send_input();
            wait_output();
            check_output();
            $display("\033[32mPattern %d Passed\033[0m", i);
        end
        $display("\033[32m");
        $display("**************************************************");
        $display("                 ALL PATTERN PASS                 ");
        $display("**************************************************");
        $display("                    SEED: %d", SEED);
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

    task generate_code(); begin
        integer j;
        reg [4:0] i;
        code = $random(SEED);
        encode = {
            1'b0, // parity[0]
            1'b0, // parity[1]
            code[0],
            1'b0, // parity[2]
            code[1:3],
            1'b0, // parity[3]
            code[4:IP_BIT-1]
        };

        // Calculate parity
        for (i = 0; i <= IP_BIT+4; i = i + 1) begin
            if (i[0]) encode[1] = encode[1] ^ encode[i];
            if (i[1]) encode[2] = encode[2] ^ encode[i];
            if (i[2]) encode[4] = encode[4] ^ encode[i];
            if (i[3]) encode[8] = encode[8] ^ encode[i];
        end

        // Randomly flip a bit
        if ({$random(SEED)}%2 == 1) begin
            j = 1+({$random(SEED)} % (IP_BIT+4)); // 1 ~ (IP_BIT+4)
            encode[j] = ~encode[j];
        end

    end endtask
    
    task send_input(); begin
        IN_code = encode;
    end endtask

    task wait_output(); begin
        #`CYCLE_TIME;
    end endtask

    task check_output(); begin
        if (OUT_code != code) begin
            $display("\033[31mError: OUT_code = %b, code = %b, IN_code = %b\033[0m", OUT_code, code, encode[1:IP_BIT+4]);
            $finish;
        end
    end endtask

endmodule