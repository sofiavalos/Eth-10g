`timescale 1ns / 1ps

module eth_phy_10g_tx_if_tb;

    // Par�metros de simulaci�n
    parameter SIM_TIME = 2000; // Tiempo total de simulaci�n

    // Se�ales
    reg clk = 0;
    reg rst = 1;
    reg cfg_tx_prbs31_enable = 0;
    wire [63:0] encoded_tx_data;
    wire [1:0] encoded_tx_hdr;
    wire [63:0] serdes_tx_data;
    wire [1:0] serdes_tx_hdr;

    // Instancia del m�dulo bajo prueba
    eth_phy_10g_tx_if #(
        .DATA_WIDTH(64),
        .HDR_WIDTH(2),
        .BIT_REVERSE(0),
        .SCRAMBLER_DISABLE(0),
        .PRBS31_ENABLE(1), // Habilita la generaci�n de PRBS31
        .SERDES_PIPELINE(0)
    ) dut (
        .clk(clk),
        .rst(rst),
        .encoded_tx_data(encoded_tx_data),
        .encoded_tx_hdr(encoded_tx_hdr),
        .serdes_tx_data(serdes_tx_data),
        .serdes_tx_hdr(serdes_tx_hdr),
        .cfg_tx_prbs31_enable(cfg_tx_prbs31_enable)
    );

    // Generador de clock
    always #5 clk = ~clk;

    // Est�mulo
    initial begin
        // Reset inicial
        rst = 1;
        #10 rst = 0;

        // Espera un ciclo de clock antes de habilitar PRBS31
        #20;

        // Habilita la generaci�n de PRBS31
        cfg_tx_prbs31_enable = 1;

        // Espera un tiempo suficiente para generar datos PRBS31
        #500;

        // Deshabilita la generaci�n de PRBS31
        cfg_tx_prbs31_enable = 0;

        // Espera un tiempo adicional para ver los datos generados
        #500;

        // Finaliza la simulaci�n
        $finish;
    end

endmodule
