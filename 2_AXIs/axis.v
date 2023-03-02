module axi_data_fifo(
  input aclk,        // AXI clock
  input aresetn,     // AXI reset (active low)
  input s_axis_tvalid, // Stream input valid signal
  input s_axis_tdata,  // Stream input data
  input s_axis_tlast,  // Stream input last signal
  output s_axis_tready, // Stream input ready signal
  output m_axis_tvalid, // Stream output valid signal
  output m_axis_tdata,  // Stream output data
  output m_axis_tlast,  // Stream output last signal
  input m_axis_tready // Stream output ready signal
);

  // Define parameters
  parameter DATA_WIDTH = 32;     // Data width of stream
  parameter DEPTH = 16;          // Depth of FIFO
  parameter ADDR_WIDTH = $clog2(DEPTH); // Address width
  parameter ID_WIDTH = 1;        // ID width

  // Define local variables
  reg [(DATA_WIDTH-1):0] mem[0:(DEPTH-1)]; // Memory array
  reg [(ADDR_WIDTH-1):0] r_ptr, w_ptr; // Read/write pointers
  reg [ID_WIDTH-1:0] wr_id, rd_id; // Write/read IDs
  wire empty = (r_ptr == w_ptr) && (wr_id == rd_id);
  wire full = (r_ptr == w_ptr) && (wr_id != rd_id);

  // Control logic
  always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      r_ptr <= 0;
      w_ptr <= 0;
      wr_id <= 0;
      rd_id <= 0;
    end else begin
      if (s_axis_tvalid && s_axis_tready) begin
        // Write data to memory
        mem[w_ptr] <= s_axis_tdata;
        wr_id <= ~wr_id;
        w_ptr <= w_ptr + 1;
      end

      if (m_axis_tvalid && m_axis_tready) begin
        // Read data from memory
        m_axis_tdata <= mem[r_ptr];
        rd_id <= ~rd_id;
        r_ptr <= r_ptr + 1;
      end
    end
  end

  // Output logic
  assign s_axis_tready = !full;
  assign m_axis_tvalid = !empty;
  assign m_axis_tlast = s_axis_tlast;
  assign m_axis_tdata = mem[r_ptr];

endmodule
