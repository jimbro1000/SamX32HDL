module VideoMemoryBuffer(
	input read,
	input load,
	input [7:0] readData,
	output reg [7:0] data
);

	reg[2:0] pointer;
	reg[7:0] buffer [3:0];
	
	initial begin
		buffer[0] <= 7'd0;
		buffer[1] <= 7'd0;
		buffer[2] <= 7'd0;
		buffer[3] <= 7'd0;
		pointer <= 3'd0;
		data <= 7'd255;
	end

	always @(negedge read or negedge load) begin
		if (load == 1'b0) begin
			if (pointer != 3) begin
				buffer[pointer] <= readData;
				pointer <= pointer + 1;
			end
		end
		if (read == 1'b0) begin
			data <= buffer[0];
			buffer[0] <= buffer[1];
			buffer[1] <= buffer[2];
			buffer[2] <= buffer[3];
			if (pointer != 0)
				pointer <= pointer - 1;
		end
	end

endmodule

module VideoMemoryBuffer_testbench(
);

	reg read;
	reg load;
	reg [7:0] dataIn;
	wire [7:0] dataOut;
	
	VideoMemoryBuffer uut(
		.read(read),
		.load(load),
		.readData(dataIn),
		.data(dataOut)
	);
	
	initial begin
		read <= 1'b1;
		load <= 1'b1;
		
		dataIn <= 8'd32;
		#10 load <= 1'b0;
		#10 load <= 1'b1;
		
		dataIn <= 8'd64;
		#10 load <= 1'b0;
		#10 load <= 1'b1;
		
		dataIn <= 8'd128;
		#10 load <= 1'b0;
		#10 load <= 1'b1;
		
		dataIn <= 8'd0;
		#10 load <= 1'b0;
		#10 load <= 1'b1;
		
		#10 read <= 1'b0;
		#10 read <= 1'b1;
		
		#10 read <= 1'b0;
		#10 read <= 1'b1;
		
		dataIn <= 8'h55;
		#10 load <= 1'b0;
		#10 load <= 1'b1;
		
		#10 read <= 1'b0;
		#10 read <= 1'b1;
		
		#10 read <= 1'b0;
		#10 read <= 1'b1;
		
		#10 read <= 1'b0;
		#10 read <= 1'b1;
	end

endmodule