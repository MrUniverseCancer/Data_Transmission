`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/02 17:30:30
// Design Name: 
// Module Name: generate_data
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module generate_data (
    output reg [2879:0] data  // 2880 bits of output data
);
    // Define a 192-bit width for small_data
    reg [191:0] small_data [0:14];  // 15 groups of 192-bit small_data
    
    // Temporary variable to store the generated data
    integer i, j;
    
    // Task to generate small_data with the given pattern
    task generate_small_data();
        begin
            // Generate 15 small_data groups with the desired pattern
            for (i = 0; i < 15; i = i + 1) begin
                // Fill the 192-bit data for each small_data group
                for (j = 1; j <= 24; j = j + 1) begin
                    // Generate the pattern based on `i` and `j`
                    // `i` is the group index and `j` is the bit index in the current group
                    // Create the value by increasing from 00 to BF for each small_data[i]
                    small_data[14-i][(25-j)*8-1 -: 8] = (i*24 + j) % 256;  // Simple pattern, values cycle through 0 to 255
                end
            end
        end
    endtask
    
    // Initial block to generate the data
    initial begin
        // Generate the 15 small_data arrays
        generate_small_data();
        
        // Combine the 15 small_data arrays into the 2880-bit data
        data = 0;  // Initialize to zero
        for (i = 0; i < 15; i = i + 1) begin
            // Concatenate each 192-bit small_data into the final data
            data[192*i +: 192] = small_data[i];
        end
    end
endmodule
