//CS240 2022

module projectCPU2022(clk,rst,wrEn,data_fromRAM,addr_toRAM,data_toRAM,PC,W);

input clk, rst;

input wire [15:0] data_fromRAM;
output reg [15:0] data_toRAM;
output reg wrEn;

// 12 can be made smaller so that it fits in the FPGA
output reg [12:0] addr_toRAM;
output reg [12:0] PC; // This has been added as an output for TB purposes
output reg [15:0] W; // This has been added as an output for TB purposes

// Your design goes in here

reg[12:0] PCnext;
reg[2:0] opcode, opcodeNext;
reg[2:0] state, stateNext;
reg[15:0] Wnext;

///////////////////////////

always @(posedge clk) begin
	state	<= #1 stateNext;
	PC	<= #1 PCnext;
	opcode <= #1 opcodeNext;
	W <= #1 Wnext;
end

////////////////////////////

always @*begin
	stateNext = state;
	PCnext = PC;
	opcodeNext = opcode;
	addr_toRAM = 0;
	wrEn = 0;
	data_toRAM = 0;
	Wnext = W;
	
	
	if(rst) begin
		stateNext = 0;
		PCnext = 0;
		opcodeNext = 0;
		addr_toRAM = 0;
		wrEn = 0;
		data_toRAM = 0;
		Wnext = 0;
	end

	else
		case(state)
			0: begin //read first memory location
				PCnext = PC;
				opcodeNext = opcode;
				addr_toRAM = PC;
				wrEn = 0;
				data_toRAM = 0;
				stateNext =1;
				Wnext = W;
			end
			
			1: begin //take opcode and request *A
				PCnext = PC;
				opcodeNext = data_fromRAM[15:13];
				addr_toRAM =  data_fromRAM[12:0]; 
				wrEn = 0;
				stateNext = 2;
				Wnext = W;
				data_toRAM = 0;
						
				if(data_fromRAM[12:0] == 0) begin //indirect
					data_toRAM = 0;
					addr_toRAM = 13'b0000000000100;					
					stateNext = 3;
				end 
				else begin
					if(opcodeNext == 3'b111) begin //CPfW
						wrEn 		  = 1;
						data_toRAM = W;
						PCnext = PC + 1;
						stateNext = 0; 
					end
				end
			end
			
			2: begin //take *A
				PCnext = PC+1;
				opcodeNext = opcode;
				addr_toRAM = 0;
				data_toRAM = 0;
				stateNext = 0;
				wrEn = 0;
		
					if(opcodeNext == 3'b101) begin //BZ 
						PCnext = (data_fromRAM == 0) ? W : (PC + 1);
						stateNext = 0;
					end
						
					if(opcodeNext == 3'b000) //ADD
						Wnext = W + data_fromRAM;
						
						
					if(opcodeNext == 3'b001) //NOR
						Wnext = (~(W | data_fromRAM));
					
					if(opcodeNext == 3'b010) begin //SRL
						if(data_fromRAM < 16) begin
							Wnext = W >> data_fromRAM;
						end
						else begin
							Wnext = W << (data_fromRAM[3:0]);
						end
					end
					
					if(opcodeNext == 3'b011) begin //RRL 
						if(data_fromRAM < 16) begin
							Wnext = ((W >> data_fromRAM) | (W << (16- data_fromRAM)));
						end
						else begin
							Wnext = ((W << data_fromRAM[3:0]) | (W >> (16 - data_fromRAM[3:0])));
						end
					end
					
					if(opcodeNext == 3'b100) begin //CMP  
						if(W < data_fromRAM) begin
							Wnext = 16'hFFFF;
						end
						else if(W == data_fromRAM) begin
							Wnext = 16'b0000;
						end
						else begin
							Wnext = 16'b0001;
						end
					end
					
					if(opcodeNext == 3'b110)  //CP2W  
						Wnext = data_fromRAM;
						
			end
			
			3: begin //take indirect
				PCnext = PC;
				opcodeNext = opcode;
				addr_toRAM = data_fromRAM;
				data_toRAM = 0;
				wrEn = 0;
				Wnext = W;
				stateNext = 2;
				
				if(opcodeNext == 3'b111) begin //CPfW
						wrEn 		  = 1;
						data_toRAM = W;
						PCnext = PC + 1;
						stateNext = 0; 
				end
				
			end
			
			default: begin
				stateNext = 0;
				PCnext = 0;
				opcodeNext = 0;
				addr_toRAM = 0;
				wrEn = 0;
				data_toRAM = 0;
				Wnext = 0;
			end
		
		endcase

end
endmodule
