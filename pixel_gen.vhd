-- ============================================================
-- pixel_gen.vhd
-- Genera el color del pixel (pixel_x, pixel_y).
--   Fuera de la zona visible -> negro (obligatorio en VGA).
--   Dentro del cuadrado      -> color inverso del fondo (siempre contrasta).
--   Resto                    -> color de fondo bg (R,G,B), 000 = negro.
-- La DE0 tiene DAC de 4 bits por canal, asi que cada canal vale "0000" o "1111".
-- ============================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pixel_gen is
  generic (
    SIZE : natural := 40
  );
  port (
    pixel_x  : in  unsigned(9 downto 0);
    pixel_y  : in  unsigned(9 downto 0);
    video_on : in  std_logic;
    sq_x     : in  unsigned(9 downto 0);
    sq_y     : in  unsigned(9 downto 0);
    bg       : in  std_logic_vector(2 downto 0);  -- (2)=R (1)=G (0)=B
    r        : out std_logic_vector(3 downto 0);
    g        : out std_logic_vector(3 downto 0);
    b        : out std_logic_vector(3 downto 0)
  );
end entity pixel_gen;

architecture rtl of pixel_gen is
  signal in_sq : std_logic;
  signal rgb   : std_logic_vector(2 downto 0);
begin

  in_sq <= '1' when (pixel_x >= sq_x) and (pixel_x < sq_x + SIZE) and
                    (pixel_y >= sq_y) and (pixel_y < sq_y + SIZE) else '0';

  rgb <= "000"  when video_on = '0' else
         not bg when in_sq = '1'    else
         bg;

  r <= (others => rgb(2));
  g <= (others => rgb(1));
  b <= (others => rgb(0));

end architecture rtl;
