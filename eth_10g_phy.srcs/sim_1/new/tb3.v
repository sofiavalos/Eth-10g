`timescale 1ns/1ps


module eth_phy_10g_tb3;

    // Par�metros del m�dulo
    parameter DATA_WIDTH = 64;
    parameter CTRL_WIDTH = (DATA_WIDTH/8);
    parameter HDR_WIDTH = 2;
    parameter BIT_REVERSE = 0;
    parameter SCRAMBLER_DISABLE = 0;
    parameter PRBS31_ENABLE = 1; // Habilitar PRBS31 para generar datos
    parameter TX_SERDES_PIPELINE = 0;
    parameter RX_SERDES_PIPELINE = 0;
    parameter BITSLIP_HIGH_CYCLES = 1;
    parameter BITSLIP_LOW_CYCLES = 8;
    parameter COUNT_125US = 125000/6.4;

    // Definici�n de se�ales
    reg rx_clk, rx_rst, tx_clk, tx_rst;
    reg [DATA_WIDTH-1:0] xgmii_txd;
    reg [CTRL_WIDTH-1:0] xgmii_txc;
    wire [DATA_WIDTH-1:0] xgmii_rxd;
    wire [CTRL_WIDTH-1:0] xgmii_rxc;
    wire [DATA_WIDTH-1:0] serdes_tx_data;
    wire [HDR_WIDTH-1:0]  serdes_tx_hdr;
    // Cambio de wire a reg para poder asignar valores
    reg [DATA_WIDTH-1:0] serdes_rx_data;
    reg [HDR_WIDTH-1:0]  serdes_rx_hdr;
   
    wire serdes_rx_bitslip;
    wire serdes_rx_reset_req;
    wire tx_bad_block;
    wire [6:0] rx_error_count;
    wire rx_bad_block;
    wire rx_sequence_error;
    wire rx_block_lock;
    wire rx_high_ber;
    wire rx_status;
    reg cfg_tx_prbs31_enable, cfg_rx_prbs31_enable;

    // Instancia del DUT (Design Under Test)
    eth_phy_10g #(
        .DATA_WIDTH(DATA_WIDTH),
        .CTRL_WIDTH(CTRL_WIDTH),
        .HDR_WIDTH(HDR_WIDTH),
        .BIT_REVERSE(BIT_REVERSE),
        .SCRAMBLER_DISABLE(SCRAMBLER_DISABLE),
        .PRBS31_ENABLE(PRBS31_ENABLE),
        .TX_SERDES_PIPELINE(TX_SERDES_PIPELINE),
        .RX_SERDES_PIPELINE(RX_SERDES_PIPELINE),
        .BITSLIP_HIGH_CYCLES(BITSLIP_HIGH_CYCLES),
        .BITSLIP_LOW_CYCLES(BITSLIP_LOW_CYCLES),
        .COUNT_125US(COUNT_125US)
    ) dut (
        .rx_clk(rx_clk),
        .rx_rst(rx_rst),
        .tx_clk(tx_clk),
        .tx_rst(tx_rst),
        .xgmii_txd(xgmii_txd),
        .xgmii_txc(xgmii_txc),
        .xgmii_rxd(xgmii_rxd),
        .xgmii_rxc(xgmii_rxc),
        .serdes_tx_data(serdes_tx_data),
        .serdes_tx_hdr(serdes_tx_hdr),
        .serdes_rx_data(serdes_rx_data),
        .serdes_rx_hdr(serdes_rx_hdr),
        .serdes_rx_bitslip(serdes_rx_bitslip),
        .serdes_rx_reset_req(serdes_rx_reset_req),
        .tx_bad_block(tx_bad_block),
        .rx_error_count(rx_error_count),
        .rx_bad_block(rx_bad_block),
        .rx_sequence_error(rx_sequence_error),
        .rx_block_lock(rx_block_lock),
        .rx_high_ber(rx_high_ber),
        .rx_status(rx_status),
        .cfg_tx_prbs31_enable(cfg_tx_prbs31_enable),
        .cfg_rx_prbs31_enable(cfg_rx_prbs31_enable)
    );

    always
    // CAMBIOS
    // Cambio de begin a fork para que sea paralelo y no secuencial
        fork
            #5 rx_clk = ~rx_clk;
            #5 tx_clk = ~tx_clk;
        join


    // Generador de datos PRBS31 para xgmii_txd
    initial begin
       
        
        // Configurar generaci�n de PRBS31
        cfg_tx_prbs31_enable = 1'b1;
        cfg_rx_prbs31_enable = 1'b1;
        
        // Ciclo de clock y reset
        rx_clk = 1'b0;
        tx_clk = 1'b0;
        rx_rst = 1'b1;
        tx_rst = 1'b1;
        #10;
        rx_rst = 1'b0;
        tx_rst = 1'b0;
        
        #100
        // Verificar resultados

        if (rx_bad_block)
            $display("Error en bloque recibido");
        
        else if(rx_sequence_error)
            $display("Error en secuencia recibida");

        else if(rx_high_ber)
            $display("Error en BER recibido");
        
        else if(tx_bad_block)
            $display("Error en bloque transmitido");
        
        else if(rx_block_lock)
            $display("Error en bloque recibido");
        
        else if(rx_error_count)
            $display("Error en conteo de errores recibidos");
        
        // Finalizar simulaci�n
        else $display("Transmision y recepcion exitosas");

        $finish;
    end

    always @(posedge tx_clk) begin
    if (!tx_rst) begin
    
        // CAMBIOS
        // a�ade el txc tambien porque quedaba todo en xxxx
        xgmii_txc <= serdes_tx_hdr;
        xgmii_txd <= serdes_tx_data;
        // Mostrar valores de datos despu�s de la asignaci�n a xgmii_txd
        $display("----ASIGNACION----");
        $display("serdes_tx_data = %h --> xgmii_txd = %h", serdes_tx_data, xgmii_txd);
        end
    end

    always @(posedge rx_clk) begin
        if (!rx_rst) begin
            // Mostrar valores de datos recibidos
            $display("----RECEPCION----");
            $display("serdes_rx_data = %h, serdes_rx_hdr = %h", serdes_rx_data, serdes_rx_hdr);
        end
        
        // CAMBIOS
        // Conecta los datos de la salida del transmisor con la entrada del receptor
        serdes_rx_data <= serdes_tx_data;
        serdes_rx_hdr <= serdes_tx_hdr;
    end

    // Validaci�n: Compara los datos recibidos con los datos transmitidos
    always @(posedge rx_clk) begin
        if (!rx_rst) begin
            // Compara solo si no est� en estado de reinicio
            if (xgmii_rxd !== xgmii_txd) begin
                $display("ERROR: ", "xgmii_rxd = %h, xgmii_txd = %h", xgmii_rxd, xgmii_txd);
            end
            else begin
                $display("OK: ", "xgmii_rxd = %h, xgmii_txd = %h", xgmii_rxd, xgmii_txd);
            end
        end
    end
    
    

endmodule
