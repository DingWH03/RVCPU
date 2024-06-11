module SimpleCPU_tb;

    // Parameters
    parameter CLK_PERIOD = 10;  // Clock period in simulation time units

    // Signals for the testbench
    reg clk = 0;
    reg reset = 1;
    reg [7:0] test_address;
    reg [15:0] test_data_in;
    reg rw_enable;
    reg data_out;

    // Instantiate InstructionMemory module
    InstructionMemory instr_mem (
        .clk(clk),
        .rw_enable(rw_enable),
        .address(test_address),
        .data_in(test_data_in),
        .data_out(data_out)
    );

    // Instantiate SimpleCPU module
    SimpleCPU cpu_inst (
        .clk(clk),
        .reset(reset),
        .data_out(instr_mem.data_out),  // Connect InstructionMemory output to SimpleCPU data_out
        .rw_enable(),
        .address(),
        .data_in()
    );

    // Clock generation
    always #((CLK_PERIOD / 2)) clk = ~clk;  // Toggle clock at half the period

    // Initial block for testbench
    initial begin
        // Reset sequence
        #20;  // Wait for some time

        // Release reset
        reset = 0;

        // Test scenario 1: Write an instruction to memory
        test_address = 8'h00;      // Memory address to write
        test_data_in = 16'b0000000000001010;   // Instruction to write (example)
        rw_enable = 0;             // Enable memory write

        #10;  // Wait for a few cycles

        rw_enable = 1;
        $display("Read data from port 1: %h", data_out);

        #10
        reset = 1;

        #10
        reset = 0;

        #10
        

        // Test scenario 2: Read an instruction from memory and execute
        test_address = 8'h00;      // Memory address to read
        test_data_in = 16'h0000;   // No data write during read
        rw_enable = 0;             // Enable memory read

        #20;  // Wait for a few cycles

        // Terminate simulation
        $finish;
    end

endmodule
