module AXI_Master(
input clk ,reset,
input [3:0]AWID,
input [31:0]AWADDR,
input [3:0]AWLEN,
input [2:0]AWSIZE,
input [1:0]AWBURST,
input AWREADY,
input [31:0]WDATA,
input [3:0]WSTRB,
input WREADY,
input [3:0]BID,
input [1:0]BRESP,
input BVALID,
input [3:0]ARID,
input [31:0]ARADDR,
input [3:0]ARLEN,
input [2:0]ARSIZE,
input [1:0]ARBURST,  
input ARREADY,
input [31:0]RDATA,
input [1:0]RRESP,
input RLAST,
input RVALID,
output reg AWVALID,
output reg [3: 0] WID,
output reg WLAST,
output reg WVALID,
output reg BREADY,
output reg ARVALID,
output reg [3:0] RID,
output reg RREADY,
output reg [1:0]AWBURST_out,
output reg [2:0] AWSIZE_out,
output reg [3:0] AWLEN_out,
output reg [31:0] AWADDR_out,
output reg [3 : 0] AWID_out,
output reg [3 : 0] WSTRB_out,
output reg [31 : 0]WDATA_out,
output reg [3 : 0] ARID_out,
output reg [31 : 0]ARADDR_out,
output reg [3 : 0]ARLEN_out,
output reg [2 : 0]ARSIZE_out,
output reg [1 : 0] ARBURST_out );

     localparam  AWRITE_IDLE    = 2'b00;
     localparam  AWRITE_START   = 2'b01;
     localparam  AWRITE_WAIT    = 2'b11;
     localparam  AWRITE_VALID   = 2'b10;

     localparam DWRITE_INIT     = 3'b000;
     localparam DWRITE_TRANSFER = 3'b001;
     localparam DWRITE_READY    = 3'b011;
     localparam DWRITE_VALID    = 3'b010;
     localparam DWRITE_ERROR    = 3'b110;

     localparam RBWRITE_IDLE    = 2'b00;
     localparam RBWRITE_START   = 2'b01;
     localparam RBWRITE_READY   = 2'b11;

     localparam AREAD_IDLE      = 3'b000;
     localparam AREAD_WAIT      = 3'b001;            
     localparam AREAD_READY     = 3'b011;
     localparam AREAD_VALID     = 3'b010;
     localparam AREAD_EXTRA     = 3'b110;

     localparam DREAD_CLEAR     = 2'b00;
     localparam DREAD_STARTM    = 2'b01;
     localparam DREAD_READ      = 2'b11;
     localparam DREAD_VALID     = 2'b10;

     reg [1 : 0] AWCS , AWNS; 
     reg [2 : 0] DWCS , DWNS;
     reg [4 : 0] count , count_next;
     reg [1 : 0] RBCS , RBNS;    
     reg [2 : 0] ARCS , ARNS;
     reg [31 : 0] slaveaddress , slaveaddress_r , slaveaddress_n , ARADDR_r;
     reg [1  : 0] DRCS , DRNS;
     reg [31 : 0] wrap_boundary,first_time, first_time_next;
     reg [7 : 0] read_memory [4096-1 : 0];

       always@(posedge clk or negedge reset) begin
        if(!reset)
            AWCS <= AWRITE_IDLE;
        else
            AWCS <= AWNS;
     end

      always@(*)
     begin
       case(AWCS)
            AWRITE_IDLE: begin
                AWVALID = 1'd0;
                AWBURST_out= 'd0;
                AWSIZE_out= 'd0;
                AWLEN_out = 'd0;
                AWADDR_out= 'd0;
                AWID_out = 'd0;
                AWNS = AWRITE_START; 
            end

            AWRITE_START: begin
                if(AWADDR > 32'h0)
                begin
                    AWVALID= 1'b1;
                    AWBURST_out= AWBURST;
                    AWSIZE_out= AWSIZE;
                    AWLEN_out= AWLEN;
                    AWADDR_out= AWADDR;
                    AWID_out= AWID;
                    AWNS = AWRITE_WAIT;
                end
                else
                    AWNS = AWRITE_IDLE;                
            end
             AWRITE_WAIT: begin
                if(AWREADY)
                              
                    AWNS = AWRITE_VALID;               
                         
                else
                              
                   AWNS = AWRITE_WAIT;              
                        
            end
            AWRITE_VALID: begin
                AWVALID = 1'b0;
                if(AWREADY)
                    AWNS = AWRITE_IDLE;
                else
                    AWNS = AWRITE_VALID;
               
            end        
        endcase     
     end
      always@(posedge clk or negedge reset) begin
        if(!reset)
         begin
             DWCS <= DWRITE_INIT;
             count   <= 5'b0;
         end
         
         else
         begin
         
            DWCS <= DWNS;
            count   <= count_next;
          end     
     end

     always@(*) begin
     
        case(DWCS)
        
            DWRITE_INIT: begin
                
                WID         = 'd0;
                WDATA_out   = 'd0;
                WSTRB_out   = 'd0;
                WLAST       = 'd0;
                WVALID      = 'd0;
                count_next  = 'd0;
                
                if(AWREADY)
                    DWNS = DWRITE_TRANSFER;
                else
                    DWNS = DWRITE_INIT;
            
            end
            DWRITE_TRANSFER: begin
                if(AWADDR > 32'h5ff && AWADDR <= 32'hfff && AWSIZE < 3'b100)
                begin
                
                    WID          = AWID_out;
                    WDATA_out    = WDATA;
                    WSTRB_out    = WSTRB;
                    WVALID       = 1'b1;
                    count_next   = count + 1'b1;  
                    DWNS = DWRITE_READY;
                
                end
                
                else
                begin
                    count_next   = count + 1'b1;  
                    DWNS = DWRITE_ERROR; 
                end
            end
             DWRITE_READY: begin
                if(WREADY)
                begin
                    if(count_next == (AWLEN + 1'b1))                
                        WLAST = 1'b1;                                       
                    else                   
                        WLAST = 1'b0;

                    DWNS = DWRITE_VALID;
                end
                
                else
            
                    DWNS = DWRITE_READY;    
            end
            DWRITE_VALID: begin
                WVALID = 1'b0;
                if(count_next == (AWLEN + 1'b1))
                begin
                
                   DWNS = DWRITE_INIT; 
                   WLAST        = 1'b0;
                end
                else
                    DWNS = DWRITE_TRANSFER;
                end

                 DWRITE_ERROR: begin
            
                if(count_next == (AWLEN + 1'b1))
                begin
                    
                    WLAST= 1'b1;
                    DWNS = DWRITE_VALID;
                
                end
                
                else
                begin
                    WLAST= 1'b0;
                    DWNS = DWRITE_TRANSFER;
                 end
                 end
           endcase
          end

       always@(posedge clk or negedge reset) begin
        
        if(!reset)   
            RBCS <= RBWRITE_IDLE;
        else
            RBCS <= RBNS;       
     end
     always@(*)begin
     
        case(RBCS)
        
            RBWRITE_IDLE: begin
                BREADY = 1'b0;
                RBNS = RBWRITE_START; 
            end
            
            RBWRITE_START: begin
                if(BVALID) 
                   RBNS =  RBWRITE_READY;
                 end
            
            RBWRITE_READY: begin
                BREADY        = 1'b1;
                RBNS  = RBWRITE_IDLE;
            end
        
        endcase
     
     end
      always@(posedge clk or negedge reset)
     begin
     
        if(!reset)
            ARCS <= AREAD_IDLE;
        else
            ARCS <= ARNS;
     end

      always@(*)begin
     
        case(ARCS)
            
            AREAD_IDLE: begin
           
                ARID_out = 'd0;
                ARADDR_out= 'd0;
                ARLEN_out= 'd0; 
                ARSIZE_out= 'd0;    
                ARBURST_out= 'd0;
                ARVALID = 'd0;
                ARNS = AREAD_WAIT;
           
            end 
         
            AREAD_WAIT: begin
            
                if(ARADDR > 32'h0)
                begin
                
                    ARID_out     = ARID;
                    ARADDR_out   = ARADDR;
                    ARLEN_out    = ARLEN; 
                    ARSIZE_out   = ARSIZE;    
                    ARBURST_out  = ARBURST;
                    ARVALID      = 1'b1;
                    ARNS = AREAD_READY; 
                
                end
                else
                   ARNS = AREAD_IDLE;
            end
            
            AREAD_READY: begin
            
                if(ARREADY)
               
                    ARNS = AREAD_VALID;
                else
                    ARNS = AREAD_READY;
            end
            
            AREAD_VALID: begin
                ARVALID = 1'b0;
                if(RLAST)
                    ARNS = AREAD_EXTRA;
             else
                    ARNS = AREAD_VALID;
            end
            
            AREAD_EXTRA:
                ARNS = AREAD_IDLE;
        endcase
          end

   always@(posedge clk or negedge reset)begin
     
        if(!reset)
            DRCS     <= DREAD_CLEAR;
        else
        begin
            DRCS   <= DRNS;
            first_time <= first_time_next;
        end
     
     end

      always@(*)begin
     
        if(ARREADY) 
            ARADDR_r = ARADDR;

        case(DRCS)
        
            DREAD_CLEAR: begin
            
                RREADY           = 1'd0;
                first_time_next = 32'd0;
                slaveaddress     = 32'd0;
                slaveaddress_r   = 32'd0;  
                DRNS     = DREAD_STARTM;
            
            end
            
            DREAD_STARTM: begin
                if(RVALID)
                begin
                    DRNS  = DREAD_READ;
                    slaveaddress  = slaveaddress_r; 
                end
                else
                    DRNS  = DREAD_STARTM;
            end
            
            DREAD_READ: begin
       
                DRNS  = DREAD_VALID;
                RREADY        = 1'b1;
                case(ARBURST)
                    2'b00: begin
                    
                        slaveaddress = ARADDR_r;
                        case(ARSIZE)
                        
                            3'b000: begin
                                read_memory[slaveaddress] = RDATA[7:0];
                                
                            end
                            
                            3'b001: begin
                                
                                read_memory[slaveaddress]     = RDATA[7:0];
                                read_memory[slaveaddress + 1] = RDATA[15:8];
                            
                            end
                            
                            3'b010: begin
                                read_memory[slaveaddress]     = RDATA[7:0];
                                read_memory[slaveaddress + 1] = RDATA[15:8];
                                read_memory[slaveaddress + 2] = RDATA[23:16];
                                read_memory[slaveaddress + 3] = RDATA[31:24];
                            
                            end
                            
                        
                        endcase
                    
                    end
                    2'b01: begin
                    
                        if(first_time== 0)
                        begin
                            slaveaddress     = ARADDR_r;
                            first_time_next = 1;
                        
                        end    
                        
                        else
                      first_time_next = first_time;
                        
                        if(RLAST)
                        first_time_next = 0;
                         
                        else
                            first_time_next = first_time;

                        case(ARSIZE)
                        
                            3'b000: 
                                read_memory[slaveaddress]     = RDATA[7:0];
                            
                            3'b001: begin
                            
                                read_memory[slaveaddress]         = RDATA[7:0];
                                read_memory[slaveaddress + 1]     = RDATA[15:8];
                                slaveaddress_r = slaveaddress + 2;
                            
                            end
                            
                            3'b010: begin
                            
                                read_memory[slaveaddress]          = RDATA[7:0];
                                read_memory[slaveaddress + 1]      = RDATA[15:8];
                                read_memory[slaveaddress + 2]      = RDATA[23:16];
                                read_memory[slaveaddress + 3]      = RDATA[31:24];
                                slaveaddress_r = slaveaddress + 4;
                                
                            end
                        
                        endcase
                        
                    end
                    
                    
                    2'b10: begin
                    
                        if(first_time == 0)
                        begin
                        
                            slaveaddress     = ARADDR_r;
                            first_time_next = 1;
                        
                        end    
                        
                        else
                            first_time_next = first_time;
                        if(RLAST)
                            first_time_next = 0;
                        else
                            first_time_next = first_time;

                        case(ARLEN)
                            4'b0001: begin
                            
                                case(ARSIZE)
                                
                                    3'b000:
                                 wrap_boundary = 2 * 1;
                                    3'b001: 
                                         
                                        wrap_boundary = 2 * 2;
                                
                                    3'b010: 
                                     
                                        wrap_boundary = 2 * 4;
                                   
                                endcase
                            
                            end
                            
                            4'b0011: begin
                            
                                case(ARSIZE)
                                
                                    3'b000: 
                                        wrap_boundary = 4 * 1;
                                    
                                    3'b001:
                                        wrap_boundary = 4 * 2;
                                   
                                    3'b010:
                                        wrap_boundary = 4 * 4;
                                   
                                endcase
                            
                            end
                            
                            4'b0111: begin
                            
                                case(ARSIZE)
                                
                                    3'b000: 
                                        wrap_boundary = 8 * 1;
                                    
                                   
                                    
                                    3'b001:
                                        wrap_boundary = 8 * 2;
                                   
                                    3'b010: 
                                        wrap_boundary = 8 * 4;
                                   
                                endcase
                            
                            end
                            
                            4'b1111: begin
                            
                                case(ARSIZE)
                                
                                    3'b000:
                                        wrap_boundary = 16 * 1;
                                  
                                    3'b001: 
                                        wrap_boundary = 16 * 2;
                                    
                                    3'b010: 
                                        wrap_boundary = 16 * 4;
                                    
                                endcase
                            
                            end
                            
                        endcase
                        
                        case(ARSIZE)
                        
                            3'b000: begin
                                read_memory[slaveaddress] = RDATA[7 : 0];
                                slaveaddress_n= slaveaddress + 1;
                                
                                if(slaveaddress_n % wrap_boundary == 0)
                                   slaveaddress_r = slaveaddress_n - wrap_boundary;
                                else
                                    slaveaddress_r = slaveaddress_n;
                            end
                            
                            3'b001: begin
                           
                                read_memory[slaveaddress] = RDATA[7 : 0];
                                slaveaddress_n            = slaveaddress + 1;  
                                
                                if(slaveaddress_n % wrap_boundary == 0)
                                    slaveaddress_r = slaveaddress_n - wrap_boundary;
                                
                                else
                                
                                    slaveaddress_r = slaveaddress_n;
                               
                                read_memory[slaveaddress_r] = RDATA[15 : 8];
                                slaveaddress_n              = slaveaddress_r + 1;
                                
                                if(slaveaddress_n % wrap_boundary == 0)
                               
                                    slaveaddress_r = slaveaddress_n - wrap_boundary;
                             
                                else
                               
                                    slaveaddress_r = slaveaddress_n;
                               
                            end
                            
                            3'b010: begin
                            
                                read_memory[slaveaddress] = RDATA[7 : 0];
                                slaveaddress_n            = slaveaddress + 1;  
                                
                                if(slaveaddress_n % wrap_boundary == 0)
                               
                                    slaveaddress_r = slaveaddress_n - wrap_boundary;
                          
                                else
                                
                                    slaveaddress_r = slaveaddress_n;
                               
                                read_memory[slaveaddress_r] = RDATA[15 : 8];
                                slaveaddress_n              = slaveaddress_r + 1;
                                
                                if(slaveaddress_n % wrap_boundary == 0)
                               
                                    slaveaddress_r = slaveaddress_n - wrap_boundary;
                                
                                else
                                    slaveaddress_r = slaveaddress_n;
                                
                                read_memory[slaveaddress_r] = RDATA[23 : 16];
                                slaveaddress_n              = slaveaddress_r + 1;
                            
                                if(slaveaddress_n % wrap_boundary == 0)
                               
                                    slaveaddress_r = slaveaddress_n - wrap_boundary;
                                
                                else
                               
                                    slaveaddress_r = slaveaddress_n;
                              
                                read_memory[slaveaddress_r] = RDATA[31 : 24];
                                slaveaddress_n              = slaveaddress_r + 1;
                            
                                if(slaveaddress_n % wrap_boundary == 0)
                               
                                    slaveaddress_r = slaveaddress_n - wrap_boundary;
                              
                                else
                               
                                    slaveaddress_r = slaveaddress_n;
                               
                            end
                        
                        endcase 
                    
                    end 
                    
                endcase
            
            end
            
            DREAD_VALID: begin
            
                RREADY = 1'b0;
                
                if(RLAST)
                
                    DRNS = DREAD_CLEAR;
               
                else
               
                    DRNS = DREAD_STARTM;
               
            end
        
        endcase
     
     end

    
endmodule
            
            


            
                

