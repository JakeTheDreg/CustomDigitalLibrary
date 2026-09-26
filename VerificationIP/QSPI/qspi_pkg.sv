package qspi_pkg;
    typedef struct packed {
        logic sclk;
        logic csb;
        logic hd;
        logic wp;
        logic miso;
        logic mosi;
    } qspi_t;
endpackage