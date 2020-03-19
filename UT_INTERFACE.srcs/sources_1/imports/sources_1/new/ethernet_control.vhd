----------------------------------------------------------------------------------
-- @FILE : ethernet_control.vhd 
-- @AUTHOR: BLANCO CAAMANO, RAMON. <ramonblancocaamano@gmail.com> 
-- 
-- @ABOUT: .
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY ethernet_control IS
    GENERIC( 
        DATA : INTEGER;
        PACKETS : INTEGER
    );
    PORT(
        rst : IN STD_LOGIC;
        clk: IN STD_LOGIC;   
        rd_trigger : IN STD_LOGIC;
        rd_trigger_ok : OUT STD_LOGIC;              
        rd_continue : OUT STD_LOGIC;              
        rd_continue_ok : IN STD_LOGIC;
        i_buff_rd_en : OUT STD_LOGIC;   
        start : OUT STD_LOGIC;
        counter : IN STD_LOGIC_VECTOR(11 DOWNTO 0)  
    );
END ethernet_control;

ARCHITECTURE behavioral OF ethernet_control IS

    TYPE ST_ETH IS (IDLE, SEND);
    SIGNAL state : ST_ETH := IDLE;
    SIGNAL eth_fsm : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    
    SIGNAL eth_rd_trigger_ok : STD_LOGIC := '0';              
    SIGNAL eth_rd_continue : STD_LOGIC := '0'; 
    SIGNAL eth_i_buff_rd_en : STD_LOGIC := '0';  
    SIGNAL eth_start : STD_LOGIC := '0';
   
BEGIN
    
    rd_trigger_ok <=  eth_rd_trigger_ok;              
    rd_continue <= eth_rd_continue; 
    i_buff_rd_en <= eth_i_buff_rd_en;  
    start <= eth_start;
    
    
    PROCESS(rst, clk, rd_trigger, rd_continue_ok, counter,
        state, eth_rd_trigger_ok, eth_rd_continue, eth_i_buff_rd_en, eth_start)
    
        VARIABLE counter_data : INTEGER := 0;
        VARIABLE counter_packets : INTEGER := 0;
    
    BEGIN
        IF rst = '1' THEN
            state <= IDLE;
            counter_data := 0;
            counter_packets := 0;
            eth_rd_trigger_ok <= '0';
            eth_rd_continue <= '0';
            eth_i_buff_rd_en <= '0';
            eth_start <= '0';                    
        ELSIF RISING_EDGE(clk) THEN           
            CASE (state) IS
            
                WHEN IDLE =>
                
                    counter_data := 0; 
                    eth_i_buff_rd_en <= '0';
                    eth_start <= '0';                                           
                    IF counter_packets = PACKETS THEN
                        counter_packets := 0;
                    END IF;                        
                    IF rd_continue_ok = '1' THEN
                        eth_rd_continue <= '0';
                    END IF;                        
                    IF rd_trigger = '1' THEN                            
                        eth_rd_trigger_ok <= '1';
                        state <= SEND;
                    END IF;
                
                WHEN SEND =>
                
                    IF rd_trigger = '0' THEN
                        eth_rd_trigger_ok <= '0';
                    END IF;                            
                    IF counter_data < DATA THEN
                        IF counter = x"000" THEN
                            IF eth_start = '0' THEN
                                counter_data := counter_data + 1; 
                                eth_i_buff_rd_en <= '1';
                                eth_start <= '1';  
                            ELSE 
                                eth_i_buff_rd_en <= '0';
                            END IF;
                        ELSE
                            eth_start <= '0';
                        END IF;                       
                    ELSE
                        eth_i_buff_rd_en <= '0';
                        IF counter /= x"000" THEN
                            state <= IDLE;
                            counter_packets := counter_packets + 1; 
                            eth_start <= '0';                        
                            IF counter_packets < PACKETS - 1 THEN
                                eth_rd_continue <= '1';
                            END IF; 
                        END IF;
                    END IF;
                        
                END CASE;
            END IF;
        END PROCESS;
        
        STATE_ETH: BLOCK
        BEGIN
            WITH state SELECT eth_fsm <=
                x"00" WHEN IDLE,
                x"01" WHEN SEND,	
                x"FF" WHEN OTHERS
             ;
        END BLOCK STATE_ETH;

END behavioral;