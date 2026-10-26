-- ============================================================
-- vga_sync.vhd
-- Generador de sincronismos VGA 640x480 @ 60 Hz
-- Reloj de entrada: 50 MHz (DE0). Internamente se habilita un
-- "tick" cada 2 ciclos => pixel clock = 25 MHz.
-- HSync y VSync son activos en BAJO.
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_sync is
  port (
    clk        : in  std_logic;            -- 50 MHz
    hsync      : out std_logic;            -- activo en bajo
    vsync      : out std_logic;            -- activo en bajo
    video_on   : out std_logic;            -- '1' dentro de los 640x480 visibles
    pixel_x    : out unsigned(9 downto 0); -- columna actual (0..799)
    pixel_y    : out unsigned(9 downto 0); -- fila actual    (0..524)
    frame_tick : out std_logic             -- pulso de 1 ciclo de clk por cuadro (60 Hz)
  );
end entity vga_sync;

architecture rtl of vga_sync is

  -- Horizontal (en pixeles)
  constant H_DISP  : natural := 640;
  constant H_FP    : natural := 16;   -- front porch
  constant H_SYNC  : natural := 96;   -- ancho del pulso de sync
  constant H_BP    : natural := 48;   -- back porch
  constant H_TOTAL : natural := H_DISP + H_FP + H_SYNC + H_BP;  -- 800

  -- Vertical (en lineas)
  constant V_DISP  : natural := 480;
  constant V_FP    : natural := 10;
  constant V_SYNC  : natural := 2;
  constant V_BP    : natural := 33;
  constant V_TOTAL : natural := V_DISP + V_FP + V_SYNC + V_BP;  -- 525

  signal tick : std_logic := '0';
  signal hc   : unsigned(9 downto 0) := (others => '0');
  signal vc   : unsigned(9 downto 0) := (others => '0');

begin

  -- Contadores horizontal y vertical (avanzan a 25 MHz)
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

  -- Un pulso por cuadro, justo al terminar la zona visible (inicia el blanking vertical)
  frame_tick <= '1' when (tick = '1') and (hc = 0) and (vc = V_DISP) else '0';

end architecture rtl;
