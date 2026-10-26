-- ============================================================
-- vga_square_top.vhd   (Top-level para la DE0)
--   BUTTON(2) : izquierda / arriba
--   BUTTON(0) : derecha  / abajo
--   BUTTON(1) : reset (el cuadrado vuelve al centro)
--   SW(0)     : eje   -> '0' horizontal, '1' vertical
--   SW(3 downto 1) : color de fondo (R,G,B); "000" = negro
-- Los botones de la DE0 son activos en BAJO (presionado = '0').
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_square_top is
  generic (
    SQ_STEP : natural := 4    -- pixeles por cuadro (velocidad); el testbench usa otro valor
  );
  port (
    CLOCK_50 : in  std_logic;
    BUTTON   : in  std_logic_vector(2 downto 0);
    SW       : in  std_logic_vector(3 downto 0);
    VGA_HS   : out std_logic;
    VGA_VS   : out std_logic;
    VGA_R    : out std_logic_vector(3 downto 0);
    VGA_G    : out std_logic_vector(3 downto 0);
    VGA_B    : out std_logic_vector(3 downto 0)
  );
end entity vga_square_top;

architecture rtl of vga_square_top is

  constant SQ_SIZE : natural := 40;

  -- sincronizadores de entradas (2 flip-flops)
  signal btn_s1, btn_s2 : std_logic_vector(2 downto 0) := (others => '1');
  signal sw_s1,  sw_s2  : std_logic_vector(3 downto 0) := (others => '0');

  signal rst, btn_dec, btn_inc : std_logic;

  signal hs, vs, von, ftick : std_logic;
  signal px, py, sqx, sqy   : unsigned(9 downto 0);
  signal r_i, g_i, b_i      : std_logic_vector(3 downto 0);

begin

  process (CLOCK_50) is
  begin
    if rising_edge(CLOCK_50) then
      btn_s1 <= BUTTON;  btn_s2 <= btn_s1;
      sw_s1  <= SW;      sw_s2  <= sw_s1;
    end if;
  end process;

  rst     <= not btn_s2(1);
  btn_dec <= not btn_s2(2);
  btn_inc <= not btn_s2(0);

  u_sync : entity work.vga_sync
    port map (
      clk        => CLOCK_50,
      hsync      => hs,
      vsync      => vs,
      video_on   => von,
      pixel_x    => px,
      pixel_y    => py,
      frame_tick => ftick
    );

  u_ctrl : entity work.square_ctrl
    generic map (SIZE => SQ_SIZE, STEP => SQ_STEP)
    port map (
      clk        => CLOCK_50,
      rst        => rst,
      frame_tick => ftick,
      axis_v     => sw_s2(0),
      btn_dec    => btn_dec,
      btn_inc    => btn_inc,
      sq_x       => sqx,
      sq_y       => sqy
    );

  u_pix : entity work.pixel_gen
    generic map (SIZE => SQ_SIZE)
    port map (
      pixel_x  => px,
      pixel_y  => py,
      video_on => von,
      sq_x     => sqx,
      sq_y     => sqy,
      bg       => sw_s2(3 downto 1),
      r        => r_i,
      g        => g_i,
      b        => b_i
    );

  -- Salidas registradas: RGB y sincronismos cambian juntos
  process (CLOCK_50) is
  begin
    if rising_edge(CLOCK_50) then
      VGA_HS <= hs;
      VGA_VS <= vs;
      VGA_R  <= r_i;
      VGA_G  <= g_i;
      VGA_B  <= b_i;
    end if;
  end process;

end architecture rtl;
