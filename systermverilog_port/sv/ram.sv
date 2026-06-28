module ram(

    input logic clk, enable, w_enable,
    input logic [7:0] address_bus,//address width
    input logic [7:0] data_in, //data width
    output logic [7:0] data_out, //data width
    output logic [7:0] ram_debug [0:255]

);

//synchronous read/write ram
typedef logic [7:0] ram_type [0:255];

ram_type ram_memory;
// Load the file at the start of the simulation
initial begin
    int fd, status;
    logic [7:0] val;
    
    // 1. Initialize all to 0
    for (int i = 0; i < 256; i++) ram_memory[i] = 8'h00;
    
    // 2. Open the file
    fd = $fopen("Assembler/output.txt", "r");
    if (fd == 0) begin
        $display("Error: Could not open file!");
    end else begin
        int addr = 0;
        // 3. Read one word at a time until end of file
        while (!$feof(fd) && addr < 256) begin
            status = $fscanf(fd, "%h", val);
            if (status == 1) begin
                ram_memory[addr] = val;
                addr++;
            end
        end
        $fclose(fd);
        $display("RAM load complete. RAM[0] is now: %h", ram_memory[5]);
    end
end

assign ram_debug = ram_memory;

always_ff @(posedge clk) begin

    if (enable) begin
        if (w_enable) begin
            ram_memory[address_bus] <= data_in;
        end
        data_out <= ram_memory[address_bus];


    end

end
endmodule
