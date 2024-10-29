module sys_bus (
    // cpu -> imem
    input  [31:0] cpu_imem_addr,
    output [31:0] cpu_imem_data,
    output [31:0] imem_addr,            	
    input  [31:0] imem_data, 

    // cpu -> bus
    input  [31:0] cpu_dmem_addr,        
    input  [31:0] cpu_dmem_data_in,     
    input         cpu_dmem_wen,        
    output reg [31:0] cpu_dmem_data_out,

    // bus -> ram 
    input  [31:0] dmem_read_data,     
    output [31:0] dmem_write_data,    
    output [31:0] dmem_addr,           
    output reg    dmem_wen,

    // bus -> rom 
    input  [31:0] dmem_rom_read_data,
    output [31:0] dmem_rom_addr, 

    // bus -> uart
    input  [31:0] uart_read_data,   
    output [31:0] uart_write_data,   
    output [31:0] uart_addr,         
    output reg    uart_wen
);
    assign imem_addr = cpu_imem_addr;
    assign cpu_imem_data = imem_data;
    assign dmem_addr = cpu_dmem_addr;
    assign dmem_write_data = cpu_dmem_data_in;
    assign dmem_rom_addr = cpu_dmem_addr;
    assign uart_addr = cpu_dmem_addr;
    assign uart_write_data = cpu_dmem_data_in;

    always @(*) begin
        case (cpu_dmem_addr[31:28])
            4'h0: begin								//ROM
                cpu_dmem_data_out <= dmem_rom_read_data;
                dmem_wen <= 0;
                uart_wen <= 0;
            end
            4'h1: begin     					// RAM
                dmem_wen <= cpu_dmem_wen;
                cpu_dmem_data_out <= dmem_read_data;
                uart_wen <= 0;
            end
            4'h2: begin     					// uart io
                uart_wen <= cpu_dmem_wen;
                cpu_dmem_data_out <= uart_read_data;
                dmem_wen <= 0;
            end
            default:   begin
                dmem_wen <= 0;
                uart_wen <= 0;
                cpu_dmem_data_out <= 0;
            end
        endcase
    end
endmodule