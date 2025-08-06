module t05_sd_tx_controller (

);

  typedef enum logic [3:0] {
    CMD0, CMD8, CMD55, CMD41, 
    CMD_55_2, CMD_41_2, CMD58,
    CMD25, WRITE_STOP
  } state_t;

endmodule