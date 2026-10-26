library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_sync is
  port (
    clk        : in  std_logic;            
    hsync      : out std_logic;            
    vsync      : out std_logic;            
    video_on   : out std_logic;            
    pixel_x    : out unsigned(9 downto 0); 
    pixel_y    : out unsigned(9 downto 0); 
    frame_tick : out std_logic             
  );
end entity vga_sync;

architecture rtl of vga_sync is

 
  constant H_DISP  : natural := 640;
  constant H_FP    : natural := 16;   
  constant H_SYNC  : natural := 96;   
  constant H_BP    : natural := 48;   
  constant H_TOTAL : natural := H_DISP + H_FP + H_SYNC + H_BP;  


  constant V_DISP  : natural := 480;
  constant V_FP    : natural := 10;
  constant V_SYNC  : natural := 2;
  constant V_BP    : natural := 33;
  constant V_TOTAL : natural := V_DISP + V_FP + V_SYNC + V_BP;  

  signal tick : std_logic := '0';
  signal hc   : unsigned(9 downto 0) := (others => '0');
  signal vc   : unsigned(9 downto 0) := (others => '0');

begin

 
  process (clk) is
  begin
    if rising_edge(clk) then
      tick <= not tick;
      if tick = '1' then
        if hc = H_TOTAL - 1 then
          hc <= (others => '0');
          if vc = V_TOTAL - 1 then
            vc <= (others => '0');
          else
            vc <= vc + 1;
          end if;
        else
          hc <= hc + 1;
        end if;
      end if;
    end if;
  end process;

  hsync <= '0' when (hc >= H_DISP + H_FP) and (hc < H_DISP + H_FP + H_SYNC) else '1';
  vsync <= '0' when (vc >= V_DISP + V_FP) and (vc < V_DISP + V_FP + V_SYNC) else '1';

  video_on <= '1' when (hc < H_DISP) and (vc < V_DISP) else '0';

  pixel_x <= hc;
  pixel_y <= vc;

 
  frame_tick <= '1' when (tick = '1') and (hc = 0) and (vc = V_DISP) else '0';

end architecture rtl;
