module AXI_Slave
(
    
    input  clk,
    input  reset,
    
    input WVALID, 
    input WLAST,
    input [3 : 0]WSTRB,
    input [31 : 0]WDATA,
    input [3: 0]WID,
    input BREADY,
    input AWVALID,
    input [1: 0]AWBURST,
    input [2: 0]AWSIZE,
    input [3 : 0]AWLEN,
    input [31: 0]AWADDR,
    input [3 : 0]AWID,
    input [3 : 0]ARID,
    input [31 : 0]ARADDR,
    input [3 : 0]ARLEN,
    input [2 : 0]ARSIZE,
    input [1 : 0]ARBURST,
    input ARVALID,
    input RREADY,
    
    output reg WREADY,
    output reg [3 : 0] BID,
    output reg [1 : 0] BRESP,
    output reg BVALID,
    output reg AWREADY,
    output reg ARREADY,
    output reg [3 : 0] RID,
    output reg [31 : 0]RDATA,
    output reg [1 : 0]RRESP,
    output reg RLAST,
    output reg RVALID
    
);
    localparam AWSLAVE_IDLE  = 0;
    localparam AWSLAVE_START = 1;
    localparam AWSLAVE_READY = 2;
      localparam DWSLAVE_INIT  = 0;
    localparam DWSLAVE_START = 1; 
    localparam DWSLAVE_READY = 2;
    localparam DWSLAVE_VALID = 3;
     localparam RBSLAVE_IDLE  = 0;
    localparam RBSLAVE_LAST  = 1;
    localparam RBSLAVE_START = 2;
    localparam RBSLAVE_WAIT  = 3;
    localparam RBSLAVE_VALID = 4;
    localparam ARSLAVE_IDLE  = 0;
    localparam ARSLAVE_WAIT  = 1;
    localparam ARSLAVE_READY = 2;
    localparam DRSLAVE_CLEAR  = 0;
    localparam DRSLAVE_START  = 1;
    localparam DRSLAVE_WAIT   = 2;
    localparam DRSLAVE_VALID  = 3;
    localparam DRSLAVE_ERROR  = 4;
    reg [1 : 0] AWCS , AWNS;
    reg [1 : 0] DWCS , DWNS;
    reg [31 : 0] AWADDR_r;
    reg [31 : 0] masteraddress , masteraddress_r , masteraddress_n;
    reg first_time , first_time_next;
    integer wrap_boundary1;
    reg [2 : 0] RBCS , RBNS;
    reg [1 : 0] ARCS , ARNS;
    reg [2 : 0] DRCS , DRNS;
    reg first_time2 , first_time2_next;
    integer wrap_boundary2;
    reg [4  : 0] counter , counter_next;
    reg [31 : 0] ARADDR_r;
    reg [31 : 0] readdata_address , readdata_address_r , readdata_address_n;
    reg [7 : 0] slave_memory [4096-1 : 0];
    always@(posedge clk or negedge reset)
    begin
    
        if(!reset)
        begin
        
            AWCS <= AWSLAVE_IDLE;
            
        end
        else begin
        
            AWCS <= AWNS;
            
        end
        
    end

    always@(*)
    begin
    
        case(AWCS)
        
            AWSLAVE_IDLE: begin
                
                AWREADY = 1'b0;
                AWNS = AWSLAVE_START;
                
            end
            
            AWSLAVE_START: begin
                
                if(AWVALID)
                begin
                    
                    AWNS = AWSLAVE_READY;
                
                end
                else begin
                
                    AWNS = AWSLAVE_START;
                
                end
            
            end
            
            AWSLAVE_READY: begin
            
                AWREADY = 1'b1;
                AWNS = AWSLAVE_IDLE;
            
            end
            
        endcase
        
    end
    always@(posedge clk or negedge reset)
    begin
    
        if(!reset)
        begin
        
            DWCS     <= DWSLAVE_INIT;
            
        end
        else begin
        
            DWCS     <= DWNS;
            first_time <= first_time_next;
            
        end
        
    end
    
    always@(*)
    begin
    
        if(AWVALID == 1'b1)
        begin
            
            AWADDR_r = AWADDR;
        
        end
        
        case(DWCS)
        
            DWSLAVE_INIT: begin
            
                WREADY           = 1'b0;
                first_time_next = 1'b0;
                masteraddress    = 32'h0;
                masteraddress_r  = 32'h0;
                DWNS     = DWSLAVE_START;
                
            end
            
            DWSLAVE_START: begin
            
                if(WVALID)
                begin
                
                    DWNS     = DWSLAVE_READY;
                    masteraddress    = masteraddress_r;
                
                end
                else begin
                
                    DWNS     = DWSLAVE_START;
                
                end
            
            end
            
            DWSLAVE_READY: begin
            
                if(WLAST)
                begin
                    
                    DWNS     <= DWSLAVE_INIT;
                
                end
                else begin
                
                    DWNS     <= DWSLAVE_VALID;
                
                end
                
                WREADY = 1'b1;
                
                case(AWBURST)
                
                    2'b00: begin
                    
                        masteraddress = AWADDR_r;
                        case(WSTRB)
                        
                            4'b0001: begin
                            
                                slave_memory[masteraddress] = WDATA[7 : 0];
                            
                            end
                            
                            4'b0010: begin
                            
                                slave_memory[masteraddress] = WDATA[15 : 8];
                            
                            end
                            
                            4'b0100: begin
                            
                                slave_memory[masteraddress] = WDATA[23 : 16];
                            
                            end
                            
                            4'b1000: begin
                            
                                slave_memory[masteraddress] = WDATA[31 : 24];
                            
                            end
                            
                            4'b0011: begin
                            
                                slave_memory[masteraddress]     = WDATA[7 : 0];
                                slave_memory[masteraddress + 1] = WDATA[15 : 8];
                            
                            end
                            
                            4'b0101: begin
                            
                                slave_memory[masteraddress]     = WDATA[7 : 0];
                                slave_memory[masteraddress + 1] = WDATA[23 : 16];
                            
                            end
                            
                            4'b1001: begin
                            
                                slave_memory[masteraddress]     = WDATA[7 : 0];
                                slave_memory[masteraddress + 1] = WDATA[31 : 24];
                            
                            end
                            
                            4'b0110: begin
                            
                                slave_memory[masteraddress]     = WDATA[15 : 8];
                                slave_memory[masteraddress + 1] = WDATA[23 : 16];
                            
                            end
                            
                            4'b1010: begin
                            
                                slave_memory[masteraddress]     = WDATA[15 : 8];
                                slave_memory[masteraddress + 1] = WDATA[31 : 24];
                            
                            end
                            
                            4'b1100: begin
                            
                                slave_memory[masteraddress]     = WDATA[23 : 16];
                                slave_memory[masteraddress + 1] = WDATA[31 : 24];
                            
                            end
                            
                            4'b0111: begin
                            
                                slave_memory[masteraddress]     = WDATA[7 : 0];
                                slave_memory[masteraddress + 1] = WDATA[15 : 8];
                                slave_memory[masteraddress + 2] = WDATA[23 : 16];
                            
                            end
                            
                            4'b1110: begin
                            
                                slave_memory[masteraddress]     = WDATA[15 : 8];
                                slave_memory[masteraddress + 1] = WDATA[23 : 16];
                                slave_memory[masteraddress + 2] = WDATA[31 : 24];
                            
                            end
                            
                            4'b1011: begin
                            
                                slave_memory[masteraddress]     = WDATA[7 : 0];
                                slave_memory[masteraddress + 1] = WDATA[15 : 8];
                                slave_memory[masteraddress + 2] = WDATA[31 : 24];
                            
                            end
                            
                            4'b1101: begin
                            
                                slave_memory[masteraddress]     = WDATA[7 : 0];
                                slave_memory[masteraddress + 1] = WDATA[23 : 16];
                                slave_memory[masteraddress + 2] = WDATA[31 : 24];
                            
                            end
                            
                            4'b1111: begin
                            
                                slave_memory[masteraddress]     = WDATA[7 : 0];
                                slave_memory[masteraddress]     = WDATA[15 : 8];
                                slave_memory[masteraddress + 1] = WDATA[23 : 16];
                                slave_memory[masteraddress + 2] = WDATA[31 : 24];
                            
                            end
                            
                            default: begin
                            
                            
                            end
                        
                        endcase
                    
                    end
                    
                    2'b01: begin
                    
                        if(first_time == 1'b0)
                        begin
                        
                            masteraddress    = AWADDR_r;
                            first_time_next = 1'b1;
                        
                        end
                        else begin
                        
                            first_time_next = first_time;
                            
                        end
                        
                        if(BREADY)
                        begin
                            
                            first_time_next = 1'b0;
                        
                        end
                        else begin
                        
                            first_time_next = first_time;    
                        
                        end
                        
                        case(WSTRB)
                        
                            4'b0001: begin
                            
                                slave_memory[masteraddress] = WDATA[7 : 0];
                                masteraddress_r             = masteraddress + 1'b1;
                            
                            end
                            
                            4'b0010: begin
                            
                                slave_memory[masteraddress] = WDATA[15 : 8];
                                masteraddress_r             = masteraddress + 1'b1;
                            
                            end
                            
                            4'b0100: begin
                            
                                slave_memory[masteraddress] = WDATA[23 : 16];
                                masteraddress_r             = masteraddress + 1'b1;
                            
                            end
                            
                            4'b1000: begin
                            
                                slave_memory[masteraddress] = WDATA[31 : 24];
                                masteraddress_r             = masteraddress + 1'b1;
                            
                            end
                            
                            4'b0011: begin
                            
                                slave_memory[masteraddress]     = WDATA[7 : 0];
                                slave_memory[masteraddress + 1] = WDATA[15 : 8];
                                masteraddress_r                 = masteraddress + 2;
                            
                            end
                            
                            4'b0101: begin
                            
                                slave_memory[masteraddress]     = WDATA[7 : 0];
                                slave_memory[masteraddress + 1] = WDATA[23 : 16];
                                masteraddress_r                 = masteraddress + 2;
                            
                            end
                            
                            4'b1001: begin
                            
                                slave_memory[masteraddress]     = WDATA[7 : 0];
                                slave_memory[masteraddress + 1] = WDATA[31 : 24];
                                masteraddress_r                 = masteraddress + 2;
                            
                            end
                            
                            4'b0110: begin
                            
                                slave_memory[masteraddress]     = WDATA[15 : 8];
                                slave_memory[masteraddress + 1] = WDATA[23 : 16];
                                masteraddress_r                 = masteraddress + 2;
                            
                            end
                            
                            4'b1010: begin
                            
                                slave_memory[masteraddress]     = WDATA[15 : 8];
                                slave_memory[masteraddress + 1] = WDATA[31 : 24];
                                masteraddress_r                 = masteraddress + 2;
                            
                            end
                            
                            4'b1100: begin
                            
                                slave_memory[masteraddress]     = WDATA[23 : 16];
                                slave_memory[masteraddress + 1] = WDATA[31 : 24];
                                masteraddress_r                 = masteraddress + 2;
                            
                            end
                            
                            4'b0111: begin
                            
                                slave_memory[masteraddress]     = WDATA[7 : 0];
                                slave_memory[masteraddress + 1] = WDATA[15 : 8];
                                slave_memory[masteraddress + 2] = WDATA[23 : 16];
                                masteraddress_r                 = masteraddress + 3;
                            
                            end
                            
                            4'b1110: begin
                            
                                slave_memory[masteraddress]     = WDATA[15 : 8];
                                slave_memory[masteraddress + 1] = WDATA[23 : 16];
                                slave_memory[masteraddress + 2] = WDATA[31 : 24];
                                masteraddress_r                 = masteraddress + 3;
                            
                            end
                            
                            4'b1011: begin
                            
                                slave_memory[masteraddress]     = WDATA[7 : 0];
                                slave_memory[masteraddress + 1] = WDATA[15 : 8];
                                slave_memory[masteraddress + 2] = WDATA[31 : 24];
                                masteraddress_r                 = masteraddress + 3;
                            
                            end
                            
                            4'b1101: begin
                            
                                slave_memory[masteraddress]     = WDATA[7 : 0];
                                slave_memory[masteraddress + 1] = WDATA[23 : 16];
                                slave_memory[masteraddress + 2] = WDATA[31 : 24];
                                masteraddress_r                 = masteraddress + 3;
                            
                            end
                            
                            4'b1111: begin
                            
                                slave_memory[masteraddress]     = WDATA[7 : 0];
                                slave_memory[masteraddress]     = WDATA[15 : 8];
                                slave_memory[masteraddress + 1] = WDATA[23 : 16];
                                slave_memory[masteraddress + 2] = WDATA[31 : 24];
                                masteraddress_r                 = masteraddress + 4;
                            
                            end
                            
                            default: begin
                            
                            
                            end
                        
                        endcase
                    
                    end
                    
                    2'b10: begin
                    
                        if(first_time == 1'b0)
                        begin
                        
                            masteraddress    = AWADDR_r;
                            first_time_next = 1'b1;
                        
                        end
                        else begin
                        
                            first_time_next = first_time;
                            
                        end
                        
                        if(BREADY)
                        begin
                            
                            first_time_next = 1'b0;
                        
                        end
                        else begin
                        
                            first_time_next = first_time;    
                        
                        end
                        
                        case(AWLEN)
                        
                            4'b0001: begin
                            
                                case(AWSIZE)
                                    
                                    3'b000: begin
                                    
                                        wrap_boundary1 = 2*1;
                                    
                                    end
                                    
                                    3'b001: begin
                                    
                                        wrap_boundary1 = 2*2;
                                    
                                    end
                                    
                                    3'b010: begin
                                    
                                        wrap_boundary1 = 2*4;
                                    
                                    end
                                
                                endcase
                                
                            end
                            
                            4'b0011: begin
                            
                                case(AWSIZE)
                                    
                                    3'b000: begin
                                    
                                        wrap_boundary1 = 4*1;
                                    
                                    end
                                    
                                    3'b001: begin
                                    
                                        wrap_boundary1 = 4*2;
                                    
                                    end
                                    
                                    3'b010: begin
                                    
                                        wrap_boundary1 = 4*4;
                                    
                                    end
                                
                                endcase
                                
                            end
                            
                            4'b0111: begin
                            
                                case(AWSIZE)
                                    
                                    3'b000: begin
                                    
                                        wrap_boundary1 = 8*1;
                                    
                                    end
                                    
                                    3'b001: begin
                                    
                                        wrap_boundary1 = 8*2;
                                    
                                    end
                                    
                                    3'b010: begin
                                    
                                        wrap_boundary1 = 8*4;
                                    
                                    end
                                
                                endcase
                                
                            end
                            
                            4'b0111: begin
                            
                                case(AWSIZE)
                                    
                                    3'b000: begin
                                    
                                        wrap_boundary1 = 16*1;
                                    
                                    end
                                    
                                    3'b001: begin
                                    
                                        wrap_boundary1 = 16*2;
                                    
                                    end
                                    
                                    3'b010: begin
                                    
                                        wrap_boundary1 = 16*4;
                                    
                                    end
                                
                                endcase
                                
                            end
                        
                        endcase
                        
                        case(WSTRB)
                        
                            4'b0001: begin
                            
                                slave_memory[masteraddress] = WDATA[7 : 0];
                                masteraddress_n             = masteraddress + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                            
                            end
                            
                            4'b0010: begin
                            
                                slave_memory[masteraddress] = WDATA[15 : 8];
                                masteraddress_n             = masteraddress + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                            
                            end
                            
                            4'b0100: begin
                            
                                slave_memory[masteraddress] = WDATA[23 : 16];
                                masteraddress_n             = masteraddress + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                            
                            end
                            
                            4'b1000: begin
                            
                                slave_memory[masteraddress] = WDATA[31 : 24];
                                masteraddress_n             = masteraddress + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                            
                            end
                            
                            4'b0011: begin
                            
                                slave_memory[masteraddress] = WDATA[7 : 0];
                                masteraddress_n             = masteraddress + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                                
                                slave_memory[masteraddress_r] = WDATA[15 : 8];
                                masteraddress_n               = masteraddress_r + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                            
                            end
                            
                            4'b0101: begin
                            
                                slave_memory[masteraddress] = WDATA[7 : 0];
                                masteraddress_n             = masteraddress + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                                
                                slave_memory[masteraddress_r] = WDATA[23 : 16];
                                masteraddress_n               = masteraddress_r + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                            
                            end
                            
                            4'b1001: begin
                            
                                slave_memory[masteraddress] = WDATA[7 : 0];
                                masteraddress_n             = masteraddress + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                                
                                slave_memory[masteraddress_r] = WDATA[31 : 24];
                                masteraddress_n               = masteraddress_r + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                            
                            end
                            
                            4'b0110: begin
                            
                                slave_memory[masteraddress] = WDATA[15 : 8];
                                masteraddress_n             = masteraddress + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                                
                                slave_memory[masteraddress_r] = WDATA[23 : 16];
                                masteraddress_n               = masteraddress_r + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                            
                            end
                            
                            4'b1010: begin
                            
                                slave_memory[masteraddress] = WDATA[15 : 8];
                                masteraddress_n             = masteraddress + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                                
                                slave_memory[masteraddress_r] = WDATA[31 : 24];
                                masteraddress_n               = masteraddress_r + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                            
                            end
                            
                            4'b1100: begin
                            
                                slave_memory[masteraddress] = WDATA[23 : 16];
                                masteraddress_n             = masteraddress + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                                
                                slave_memory[masteraddress_r] = WDATA[31 : 24];
                                masteraddress_n               = masteraddress_r + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                            
                            end
                            
                            4'b0111: begin
                            
                                slave_memory[masteraddress] = WDATA[7 : 0];
                                masteraddress_n             = masteraddress + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                                
                                slave_memory[masteraddress_r] = WDATA[15 : 8];
                                masteraddress_n               = masteraddress_r + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                                
                                slave_memory[masteraddress_r] = WDATA[23 : 16];
                                masteraddress_n               = masteraddress_r + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                            
                            end
                            
                            4'b1110: begin
                            
                                slave_memory[masteraddress] = WDATA[15 : 8];
                                masteraddress_n             = masteraddress + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                                
                                slave_memory[masteraddress_r] = WDATA[23 : 16];
                                masteraddress_n               = masteraddress_r + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                                
                                slave_memory[masteraddress_r] = WDATA[31 : 24];
                                masteraddress_n               = masteraddress_r + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                            
                            end
                            
                            4'b1011: begin
                            
                                slave_memory[masteraddress] = WDATA[7 : 0];
                                masteraddress_n             = masteraddress + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                                
                                slave_memory[masteraddress_r] = WDATA[15 : 8];
                                masteraddress_n               = masteraddress_r + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                                
                                slave_memory[masteraddress_r] = WDATA[31 : 24];
                                masteraddress_n               = masteraddress_r + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                            
                            end
                            
                            4'b1101: begin
                            
                                slave_memory[masteraddress] = WDATA[7 : 0];
                                masteraddress_n             = masteraddress + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                                
                                slave_memory[masteraddress_r] = WDATA[23 : 16];
                                masteraddress_n               = masteraddress_r + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                                
                                slave_memory[masteraddress_r] = WDATA[31 : 24];
                                masteraddress_n               = masteraddress_r + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                            
                            end
                            
                            4'b1111: begin
                            
                                slave_memory[masteraddress] = WDATA[7 : 0];
                                masteraddress_n             = masteraddress + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                                
                                slave_memory[masteraddress_r] = WDATA[15 : 8];
                                masteraddress_n               = masteraddress_r + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                                
                                slave_memory[masteraddress_r] = WDATA[31 : 24];
                                masteraddress_n               = masteraddress_r + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                                
                                slave_memory[masteraddress_r] = WDATA[23 : 16];
                                masteraddress_n               = masteraddress_r + 1;
                                
                                if(masteraddress_n % wrap_boundary1 == 0)
                                begin
                                
                                    masteraddress_r = masteraddress_n - wrap_boundary1;
                                    
                                end
                                else begin
                                    
                                    masteraddress_r = masteraddress_n;
                                
                                end
                            
                            end
                        
                        endcase
                    
                    end
                
                endcase
            
            end
            
            DWSLAVE_VALID: begin
                
                WREADY = 1'b0;
                DWNS     = DWSLAVE_START;
            
            end
        
        endcase
    
    end
    always@(posedge clk or negedge reset)
    begin
    
        if(!reset)
        begin
        
            RBCS <= RBSLAVE_IDLE;
        
        end
        else begin
        
            RBCS <= RBNS;
        
        end
    
    end
    
    always@(*)
    begin
    
        case(RBCS)
        
            RBSLAVE_IDLE: begin
            
                BID    = 'd0;
                BRESP  = 'd0;
                BVALID = 1'b0;
                RBNS = RBSLAVE_LAST;
            
            end
            
            RBSLAVE_LAST: begin
            
                if(WLAST)
                begin
                
                    RBNS = RBSLAVE_START;
                
                end
                else begin
                
                   RBNS = RBSLAVE_LAST; 
                
                end
            
            end
            
            RBSLAVE_START: begin
            
                BID = AWID;
                
                if(AWADDR > 32'h5ff && AWADDR <= 32'hfff && AWSIZE < 3'b011)
                begin
                
                    
                    BRESP = 2'b00;
                
                end
                else if(AWADDR > 32'h1ff && AWADDR <= 32'h5ff || AWSIZE > 3'b010)
                begin
                
                   
                    BRESP = 2'b10;
                
                end
                else begin
                    
                  
                    BRESP = 2'b11;
                
                end
                
                BVALID = 1'b1;
                RBNS = RBSLAVE_WAIT;
            
            end
            
            RBSLAVE_WAIT: begin
            
                if(BREADY)
                begin
                
                   RBNS = RBSLAVE_IDLE; 
                
                end
            
            end
            
        endcase//RBCS
    
    end
    always@(posedge clk or negedge reset)
    begin
    
        if(!reset)
        begin
        
            ARCS <= ARSLAVE_IDLE;
        
        end
        else begin
        
            ARCS <= ARNS;
        
        end
    
    end
    
    always@(*)
    begin
    
        case(ARCS)
        
            ARSLAVE_IDLE: begin
            
                ARREADY      = 1'b0;
                ARNS = ARSLAVE_WAIT; 
            
            end
            
            ARSLAVE_WAIT: begin
                
                if(ARVALID)
                begin
                
                   ARNS = ARSLAVE_READY; 
                
                end
                else begin
                    
                   ARNS = ARSLAVE_WAIT; 
                
                end
            
            end
            
            ARSLAVE_READY: begin
                
                ARNS = ARSLAVE_IDLE;
                ARREADY      = 1'b1;
            
            end
        
        endcase
    
    end
    always@(posedge clk or negedge reset)
    begin
    
        if(!reset)
        begin
        
            DRCS     <= DRSLAVE_CLEAR;
            counter     <= 5'b0;
        
        end
        else begin
        
            DRCS     <= DRNS;
            counter     <= counter_next;
            first_time2 <= first_time2_next;
        
        end
    
    end
    
    always@(*)
    begin
    
        if(ARVALID)
        begin
        
            ARADDR_r = ARADDR;
        
        end
        
        case(DRCS)
        
            DRSLAVE_CLEAR: begin
            
                RID     = 'd0;
                RDATA   = 'd0;
                RRESP   = 'd0;
                RLAST   = 1'b0;
                
                counter_next       = 5'b0;
                readdata_address   = 32'h0;
                readdata_address_r = 32'h0;
                first_time2_next   = 1'b0;
                
                if(ARVALID)
                begin
                
                   DRNS =  DRSLAVE_START;
                
                end
                else begin
                
                    DRNS =  DRSLAVE_CLEAR;
                
                end
            
            end//DRSLAVE_CLEAR
            
            DRSLAVE_START: begin
            
                if(ARADDR > 32'h1ff && ARADDR <= 32'hfff && ARSIZE < 3'b100)
                begin
                
                    RID = ARID;
                    case(ARBURST)
                    
                        2'b00: begin
                        
                            readdata_address = ARADDR;
                            case(ARSIZE)
                            
                                3'b000: begin
                                
                                    RDATA[7 : 0] = slave_memory[readdata_address];
                                
                                end
                                
                                3'b001: begin
                                
                                    RDATA[7 : 0]  = slave_memory[readdata_address];
                                    RDATA[15 : 8] = slave_memory[readdata_address + 1];
                                
                                end
                                
                                3'b010: begin
                                
                                    RDATA[7 : 0]   = slave_memory[readdata_address];
                                    RDATA[15 : 8]  = slave_memory[readdata_address + 1];
                                    RDATA[23 : 16] = slave_memory[readdata_address + 2];
                                    RDATA[31 : 24] = slave_memory[readdata_address + 3];
                                
                                end
                            
                            endcase//ARSIZE
                        
                        end//Fixed
                        
                        2'b01: begin
                        
                            if(first_time2 == 1'b0)
                            begin
                            
                                readdata_address = ARADDR_r;
                                first_time2_next = 1;
                            
                            end
                            else begin
                            
                                first_time2_next = first_time2;
                            
                            end
                            
                            if(counter_next == ARLEN + 5'b1)
                            begin
                            
                                first_time2_next = 1'b0;
                            
                            end
                            else begin
                                
                                first_time2_next = first_time2;
                            
                            end
                            
                            case(ARSIZE)
                            
                                3'b000: begin
                                
                                    RDATA[7 : 0] = slave_memory[readdata_address];
                                
                                end
                                
                                3'b001: begin
                                
                                    RDATA[7 : 0]  = slave_memory[readdata_address];
                                    RDATA[15 : 8] = slave_memory[readdata_address + 1];
                                    readdata_address_r = readdata_address + 2;
                                
                                end
                                
                                3'b010: begin
                                
                                    RDATA[7 : 0]   = slave_memory[readdata_address];
                                    RDATA[15 : 8]  = slave_memory[readdata_address + 1];
                                    RDATA[23 : 16] = slave_memory[readdata_address + 2];
                                    RDATA[31 : 24] = slave_memory[readdata_address + 3];
                                    readdata_address_r = readdata_address + 4;
                                
                                end
                            
                            endcase//ARSIZE
                        
                        end//Increment
                        
                        2'b10: begin
                        
                            if(first_time2 == 1'b0)
                            begin
                            
                                readdata_address = ARADDR_r;
                                first_time2_next = 1;
                            
                            end
                            else begin
                            
                                first_time2_next = first_time2;
                            
                            end
                            
                            if(counter_next == ARLEN + 5'b1)
                            begin
                            
                                first_time2_next = 1'b0;
                            
                            end
                            else begin
                                
                                first_time2_next = first_time2;
                            
                            end
                            
                            case(ARLEN)
                            
                                4'b0001: begin
                                
                                    case(ARSIZE)
                                    
                                        3'b000: begin
                                        
                                            wrap_boundary2 = 2 * 1;                                            
                                        
                                        end
                                        
                                        3'b001: begin
                                        
                                            wrap_boundary2 = 2 * 2;                                            
                                        
                                        end
                                        
                                        3'b010: begin
                                        
                                            wrap_boundary2 = 2 * 4;                                            
                                        
                                        end
                                    
                                    endcase
                                
                                end
                                
                                4'b0011: begin
                                
                                    case(ARSIZE)
                                    
                                        3'b000: begin
                                        
                                            wrap_boundary2 = 4 * 1;                                            
                                        
                                        end
                                        
                                        3'b001: begin
                                        
                                            wrap_boundary2 = 4 * 2;                                            
                                        
                                        end
                                        
                                        3'b010: begin
                                        
                                            wrap_boundary2 = 4 * 4;                                            
                                        
                                        end
                                    
                                    endcase
                                
                                end
                                
                                4'b0111: begin
                                
                                    case(ARSIZE)
                                    
                                        3'b000: begin
                                        
                                            wrap_boundary2 = 8 * 1;                                            
                                        
                                        end
                                        
                                        3'b001: begin
                                        
                                            wrap_boundary2 = 8 * 2;                                            
                                        
                                        end
                                        
                                        3'b010: begin
                                        
                                            wrap_boundary2 = 8 * 4;                                            
                                        
                                        end
                                    
                                    endcase
                                
                                end
                                
                                4'b1111: begin
                                
                                    case(ARSIZE)
                                    
                                        3'b000: begin
                                        
                                            wrap_boundary2 = 16 * 1;                                            
                                        
                                        end
                                        
                                        3'b001: begin
                                        
                                            wrap_boundary2 = 16 * 2;                                            
                                        
                                        end
                                        
                                        3'b010: begin
                                        
                                            wrap_boundary2 = 16 * 4;                                            
                                        
                                        end
                                    
                                    endcase
                                
                                end
                            
                            endcase
                            
                            case(ARSIZE)
                            
                                3'b000: begin
                                
                                    RDATA[7 : 0]       = slave_memory[readdata_address];
                                    readdata_address_n = readdata_address + 1;
                                    
                                    if(readdata_address_n % wrap_boundary2 == 0)
                                    begin
                                    
                                        readdata_address_r = readdata_address_n - wrap_boundary2; 
                                    
                                    end
                                    else begin
                                    
                                        readdata_address_r = readdata_address_n;
                                    
                                    end
                                
                                end//1-Byte
                                
                                3'b001: begin
                                
                                    RDATA[7 : 0]       = slave_memory[readdata_address];
                                    readdata_address_n = readdata_address + 1;
                                    
                                    if(readdata_address_n % wrap_boundary2 == 0)
                                    begin
                                    
                                        readdata_address_r = readdata_address_n - wrap_boundary2; 
                                    
                                    end
                                    else begin
                                    
                                        readdata_address_r = readdata_address_n;
                                    
                                    end
                                    
                                    RDATA[15 : 8]       = slave_memory[readdata_address_r];
                                    readdata_address_n  = readdata_address_r + 1;
                                    
                                    if(readdata_address_n % wrap_boundary2 == 0)
                                    begin
                                    
                                        readdata_address_r = readdata_address_n - wrap_boundary2; 
                                    
                                    end
                                    else begin
                                    
                                        readdata_address_r = readdata_address_n;
                                    
                                    end
                                
                                end//2-Bytes
                                
                                3'b001: begin
                                
                                    RDATA[7 : 0]       = slave_memory[readdata_address];
                                    readdata_address_n = readdata_address + 1;
                                    
                                    if(readdata_address_n % wrap_boundary2 == 0)
                                    begin
                                    
                                        readdata_address_r = readdata_address_n - wrap_boundary2; 
                                    
                                    end
                                    else begin
                                    
                                        readdata_address_r = readdata_address_n;
                                    
                                    end
                                    
                                    RDATA[15 : 8]       = slave_memory[readdata_address_r];
                                    readdata_address_n  = readdata_address_r + 1;
                                    
                                    if(readdata_address_n % wrap_boundary2 == 0)
                                    begin
                                    
                                        readdata_address_r = readdata_address_n - wrap_boundary2; 
                                    
                                    end
                                    else begin
                                    
                                        readdata_address_r = readdata_address_n;
                                    
                                    end
                                    
                                    RDATA[23 : 16]       = slave_memory[readdata_address_r];
                                    readdata_address_n   = readdata_address_r + 1;
                                    
                                    if(readdata_address_n % wrap_boundary2 == 0)
                                    begin
                                    
                                        readdata_address_r = readdata_address_n - wrap_boundary2; 
                                    
                                    end
                                    else begin
                                    
                                        readdata_address_r = readdata_address_n;
                                    
                                    end
                                    
                                    RDATA[31 : 24]       = slave_memory[readdata_address_r];
                                    readdata_address_n   = readdata_address_r + 1;
                                    
                                    if(readdata_address_n % wrap_boundary2 == 0)
                                    begin
                                    
                                        readdata_address_r = readdata_address_n - wrap_boundary2; 
                                    
                                    end
                                    else begin
                                    
                                        readdata_address_r = readdata_address_n;
                                    
                                    end
                                
                                end//4-Bytes
                            
                            endcase//ARSIZE
                        
                        end//Wrapping
                    
                    endcase//ARBURST
                    
                    RVALID       = 1'b1;
                    counter_next = counter + 5'b1;
                    DRNS = DRSLAVE_WAIT;
                    RRESP        = 2'b00;
                
                end//end if
                else begin
                
                    if(ARSIZE >= 3'b011)
                    begin
                    
                        RRESP        = 2'b10;
                    
                    end
                    else begin
                    
                        RRESP        = 2'b11;
                    
                    end
                    
                    counter_next = counter + 5'b1;
                    DRNS = DRSLAVE_ERROR;
                
                end
            
            end//DRSLAVE_START
            
            DRSLAVE_WAIT: begin
            
                if(RREADY)
                begin
                    
                    if(counter_next == ARLEN + 1)
                    begin
                        
                        RLAST = 1'b1;
                    
                    end
                    else begin
                    
                        RLAST = 1'b0;
                        
                    end
                
                    DRNS = DRSLAVE_VALID;
                    
                end
                else begin
                
                    DRNS = DRSLAVE_WAIT;
                
                end
            
            end//DRSLAVE_WAIT
            
            DRSLAVE_VALID: begin
            
                RVALID = 1'b0;
                
                if(counter_next == ARLEN + 1)
                begin
                
                    DRNS = DRSLAVE_CLEAR;
                    RLAST        = 1'b1;
                
                end
                else begin
                
                    readdata_address = readdata_address_r;
                    DRNS     = DRSLAVE_START;
                
                end
            
            end//DRSLAVE_VALID
            
            DRSLAVE_ERROR: begin
            
                if(counter_next == ARLEN + 1)
                begin
                
                    DRNS = DRSLAVE_VALID;
                    RLAST        = 1'b1;
                
                end    
                else begin
                
                    DRNS = DRSLAVE_START;
                    RLAST        = 1'b0;
                
                end 
            
            end
        
        endcase//DRCS
    
    end
    
endmodule
