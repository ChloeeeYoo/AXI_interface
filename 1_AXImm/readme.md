# High-level overview

![image](https://user-images.githubusercontent.com/51250746/222420293-fcbdc097-64be-48c0-98eb-904bc23a4fd2.png)


##AXI memory-mapped 
### Read
![image](https://user-images.githubusercontent.com/51250746/222420962-50287bfc-f3c1-4248-a149-1823fe741e91.png)

* Burst를 수행할 때는 255는 ‘wburst_resume_value’로 나머지는 ‘core_wr_req_fire’을 통해 “RUN”으로 넘어감
* ‘wburst_resume_ce’는 burst의 data 255개를 다 보낼 때 1이 됨. 
* 그 후에 ‘wburst_resume_value’가 0이 되고 ‘core_rd_req_ready’가 1이 됨 (①->③)
* 255 data를 모두 다 보내고서 나머지 address를 보냄 (after 2 clocks)
* Input ‘rlast’가 1이 될 때까지 data 받음
* A의 data 전송이 끝나는 동시에 B의 address 보낼 수 있음
```python
{signal: [
  {name: 'clk', wave: 'P..............................'},
  {name: 'araddr', wave:  'x2.x.........9x.2.x............', data: ['A', 'A<<', 'B', 'D']},
  {name: 'arlen', wave:   'x2.x.........9x.2.x............', data: ['255', '100', '150']},
  {name: 'arvalid', wave: '01.0.........10.10.............'},  //ar_run -> arvalid
  {name: 'arready', wave: '01.0.........1.010.............'},	 //input
  {name: 'ar_fire', wave: '0.10.........10.10.............'},  //arvalid & arready  (ar_fire -> dr_run)
  {},
  {name: 'core_rd_req_valid', wave:    '1..0.......1.0.10..............'},
  {name: 'core_rd_req_ready', wave:    '10..........10.10..............'},  //output //dr_idle & (~rburst_resume_value)
  {name: 'core_rd_req_fire', wave:     '10..........10.10..............'},
  {name: 'full_rburst', wave:  		   '1.0............................'},    //rlen_value > AXI_MAX_BURST_LEN - 1 (over 2 times)
  {name: 'rburst_resume_next', wave:   '1.0............................'},    //full_rburst
  {name: 'rburst_resume_ce', wave:     '0..........10..........10......'},  //dr_fire & rlast
  {name: 'rburst_resume_value', wave:  '1...........0..................'},  
  {name: 'raddr_ce', wave: 			'10.........1.0.........10......'},  //dr_fire & rlast
  {name: 'rlen_ce', wave:  			'10.........1.0.........10......'},  //dr_fire & rlast
  {name: 'ADDR_STATE', wave: '35.43........543540............', data:['IDLE', 'RUN', 'DONE', 'IDLE', 'RUN', 'DONE', 'IDLE', 'RUN', 'DONE']},
  {},
  // core_read_size -> rsize_next, core_read_burst -> rburst_next, core_read_addr -> raddr_next, core_read_len -> rlen_next
  // core send signals 1 clock after with enable signal(n clock), next -> value
  // rsize_value -> arsize, rburst_value -> arburst, raddr_value -> araddr, rlen_value -> arlen, ar_run -> arvalid
  
  {name: 'rdata', wave:   'x..2x..2x|.2x|.9x2x.|.2x.......', data: ['D(A0)', 'D(A1)', 'D(A255)', 'D(A100)', 'D(B0)', 'D(B150)']},
  {name: 'rvalid', wave:  '0.1.0.11.0.1.1.101..01.0.......'},	 //input
  {name: 'rready', wave:  '0..10..10..10..1010...10.......'},  //dr_run & core_read_data_ready  (dr_run <- ar_fire)
  {name: 'dr_fire', wave: '0..10..10..10..1010...10.......'},  //rvalid & rready
  {name: 'rlast', wave:   '0..........10..10.....10.......'},
  {name: 'A_DATA_STATE', wave:   '3..5........40.................', data:['IDLE', 'RUN', 'DONE', 'IDLE', 'RUN', 'DONE']},
  {name: 'A<<_DATA_STATE', wave: '3.............5.40.............', data:['IDLE', 'RUN', 'DONE', 'IDLE', 'RUN', 'DONE']},
  {name: 'B_DATA_STATE', wave:   '3................5.....40......', data:['IDLE', 'RUN', 'DONE', 'IDLE', 'RUN', 'DONE']},
  {},
  {name: 'core_rd_data_valid', wave: '0.1.0.11.0.1.1.101..01.0.......'}, //output //dr_run & rvalid
  {name: 'core_rd_data_ready', wave: '0..10..10..10..1010...10.......'},	 //input 
  {name: 'core_rd_data', wave:       '0..10..10..10..1010...10.......'},  //output //rdata
  
]}
```

### Write
![image](https://user-images.githubusercontent.com/51250746/222421036-b1097815-84a9-456b-aa97-fcd2ca1ca8a1.png)

* Burst를 수행할 때는 255는 ‘wburst_resume_value’로 나머지는 ‘core_wr_req_fire’을 통해 “RUN”으로 넘어감
* ‘wburst_resume_ce’는 burst의 data 255개를 다 보낼 때 1이 됨
* 그 후에 ‘wburst_resume_value’가 0이 되고 ‘core_wr_req_ready’가 1이 됨 (①->③)
* 255 data를 모두 다 보내고서 나머지 address를 보냄 (after 2 clocks)
* Data도 Address와 동일한 “IDLE” -> “RUN” 조건을 가짐
* Data의 “RUN”을 끝내는 건 ‘wlast’
(wbeat_cnt_value를 통해 count함)
* A의 data 전송이 끝나야 B의 address 보낼 수 있음
(address와 data의 IDLE->RUN sync가 같기 때문)

```python
{signal: [
  {name: 'clk', wave: 'P..............................'},
  {name: 'awaddr', wave:  'x2.x..........9x2.x............', data: ['A', 'A<<', 'B', 'D']},
  {name: 'awlen', wave:   'x2.x..........9x2.x............', data: ['255', '100', '150']},
  {name: 'awvalid', wave: '01.0..........10.10............'},  //aw_run -> awvalid
  {name: 'awready', wave: '0.10.1......1..01.0............'},	 //input
  {name: 'aw_fire', wave: '0.10..........10.10............'},  //awvalid & awready  (ar_fire -> dr_run)

  {},
  {name: 'core_wr_req_valid', wave:    '1..0........1.0.10.............'},
  {name: 'core_wr_req_ready', wave:    '0............10.10.............'},  //aw_idle & (~wburst_resume_value) & awready
  {name: 'core_wr_req_fire', wave:     '0............10.10.............'},
  {},
  {name: 'full_wburst', wave:  		   '1.0............................'},  //wlen_value > AXI_MAX_BURST_LEN - 1 (over 2 times)
  {name: 'wburst_resume_next', wave:   '1.0............................'},  //full_wburst
  {name: 'wburst_resume_ce', wave:     '0...........10..10......10.....'},  //dw_fire & wlast
  {name: 'wburst_resume_value', wave:  '1............0.................'},  
  {name: 'waddr_ce', wave: 			'0...........10..1.0.....10.....'},  //core_write_request_fire | (dw_fire & wlast)
  {name: 'wlen_ce', wave:  			'0...........10..1.0.....10.....'},  //core_write_request_fire | (dw_fire & wlast)
  {name: 'A_ADDR_STATE', wave:   '35.4..........30...............', data:['IDLE', 'RUN', 'DONE', 'IDLE']},
  {name: 'A<<_ADDR_STATE', wave: '3.............54..30...........', data:['IDLE', 'RUN', 'DONE', 'IDLE']},
  {name: 'B_ADDR_STATE', wave:   '3................54......30....', data:['IDLE', 'RUN', 'DONE', 'IDLE']},
  {},
  // core_read_size -> rsize_next, core_read_burst -> rburst_next, core_read_addr -> raddr_next, core_read_len -> rlen_next
  // core send signals 1 clock after with enable signal(n clock), next -> value
  // rsize_value -> arsize, rburst_value -> arburst, raddr_value -> araddr, rlen_value -> arlen, ar_run -> arvalid
  
  {name: 'wdata', wave:   'x...2x..2x|.2x|.9x2x.|.2x......', data: ['D(A0)', 'D(A1)', 'D(A255)', 'D(A100)', 'D(B0)', 'D(B150)']},
  {name: 'wvalid', wave:  '0.1..0.1..01.01.11...0.1.0.....'},	 //dw_run & core_write_data_valid  (dw_run <- aw_fire)
  {name: 'wready', wave:  '0..1.0.1.0.1.0.1.1.0..1.0......'},  //input 
  {name: 'dw_fire', wave: '0..1.0.1.0.1.0.1...0..1.0......'},  //wvalid & wready
  {name: 'wbeat_cnt_next', wave:   '2...2...2|..x|2.x2x|.2.x.......', data: ['0', '1', '... 255', '100', '0', '250']},
  {name: 'wbeat_cnt_value', wave:  'x...2x..2x|.2x|.2x2x.|.2x......', data: ['0', '1', '255', '100', '0', '250']},   //wbeat_cnt_ce = dw_fire
  {name: 'wlast', wave:   '0...........10..10.....10......'}, //dw_run & ((wbeat_cnt_value == wlen_value & ~full_wburst)|(wbeat_cnt_value == AXI_MAX_BURST_LEN - 1))
  {name: 'bvalid', wave:     '0...........1.0.1.0....1.0.....'},   //input
  {name: 'bready', wave:     '0............10..10.....10.....'},   //aw_done & dw_done
  {name: 'bresp_fire', wave: '0............10..10.....10.....'},   //bvalid & bready
  {name: 'A_DATA_STATE', wave:   '35...........430...............', data:['IDLE', 'RUN', 'DONE', 'IDLE', 'RUN', 'DONE']},
  {name: 'A<<_DATA_STATE', wave: '3.............5..430...........', data:['IDLE', 'RUN', 'DONE', 'IDLE', 'RUN', 'DONE']},
  {name: 'B_DATA_STATE', wave:   '3................5......430....', data:['IDLE', 'RUN', 'DONE', 'IDLE', 'RUN', 'DONE']},
  {},
  {name: 'core_wr_data_valid', wave: '0.1..0.1..01.01.11...0.1.0.....'}, //input
  {name: 'core_wr_data_ready', wave: '0.1..0.1..01.01.101..0.1.0.....'}, //dw_run & wready
  {name: 'core_wr_data', wave:       '0...10..10..10..1010...10......'}, //wdata
  
]}
```

