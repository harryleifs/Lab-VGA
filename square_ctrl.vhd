library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity square_ctrl is
  generic (
    SIZE : natural := 40;   
    STEP : natural := 4     
  );
  port (
    clk        : in  std_logic;
    rst        : in  std_logic;                
    frame_tick : in  std_logic;
    axis_v     : in  std_logic;
    btn_dec    : in  std_logic;                
    btn_inc    : in  std_logic;                
    sq_x       : out unsigned(9 downto 0);
    sq_y       : out unsigned(9 downto 0)
  );
end entity square_ctrl;

architecture rtl of square_ctrl is
  constant X_MAX : natural := 640 - SIZE;
  constant Y_MAX : natural := 480 - SIZE;
  signal x : unsigned(9 downto 0) := to_unsigned(X_MAX / 2, 10);
  signal y : unsigned(9 downto 0) := to_unsigned(Y_MAX / 2, 10);
begin

  process (clk, rst) is
  begin
    if rst = '1' then
      x <= to_unsigned(X_MAX / 2, 10);
      y <= to_unsigned(Y_MAX / 2, 10);
    elsif rising_edge(clk) then
      if frame_tick = '1' then
        if axis_v = '0' then
         
          if btn_inc = '1' and btn_dec = '0' then
            if x + STEP <= X_MAX then
              x <= x + STEP;
            else
              x <= to_unsigned(X_MAX, 10);
            end if;
          elsif btn_dec = '1' and btn_inc = '0' then
            if x >= STEP then
              x <= x - STEP;
            else
              x <= (others => '0');
            end if;
          end if;
        else
         
          if btn_inc = '1' and btn_dec = '0' then
            if y + STEP <= Y_MAX then
              y <= y + STEP;
            else
              y <= to_unsigned(Y_MAX, 10);
            end if;
          elsif btn_dec = '1' and btn_inc = '0' then
            if y >= STEP then
              y <= y - STEP;
            else
              y <= (others => '0');
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  sq_x <= x;
  sq_y <= y;

end architecture rtl;
