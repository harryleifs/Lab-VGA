library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_vga is
end entity tb_vga;

architecture sim of tb_vga is
  signal clk : std_logic := '0';
  signal btn : std_logic_vector(2 downto 0) := "111";
  signal sw  : std_logic_vector(3 downto 0) := "0000";
  signal hs, vs : std_logic;
  signal r, g, b : std_logic_vector(3 downto 0);

  signal hs_fall, vs_fall : time := 0 ns;
  signal r_cnt, r_last    : natural := 0;
  signal vs_d             : std_logic := '1';
begin

  clk <= not clk after 10 ns;   

  dut : entity work.vga_square_top
    generic map (SQ_STEP => 64)   
    port map (CLOCK_50 => clk, BUTTON => btn, SW => sw,
              VGA_HS => hs, VGA_VS => vs, VGA_R => r, VGA_G => g, VGA_B => b);

  
  process (hs) is
  begin
    if falling_edge(hs) then
      if hs_fall /= 0 ns then
        assert (now - hs_fall) = 32 us
          report "Periodo HSync incorrecto: " & time'image(now - hs_fall) severity error;
      end if;
      hs_fall <= now;
    elsif rising_edge(hs) and hs_fall /= 0 ns then
      assert (now - hs_fall) = 3840 ns
        report "Ancho pulso HSync incorrecto: " & time'image(now - hs_fall) severity error;
    end if;
  end process;

  
  process (vs) is
  begin
    if falling_edge(vs) then
      if vs_fall /= 0 ns then
        assert (now - vs_fall) = 16800 us
          report "Periodo VSync incorrecto: " & time'image(now - vs_fall) severity error;
      end if;
      vs_fall <= now;
    elsif rising_edge(vs) and vs_fall /= 0 ns then
      assert (now - vs_fall) = 64 us
        report "Ancho pulso VSync incorrecto: " & time'image(now - vs_fall) severity error;
    end if;
  end process;

  
  process (clk) is
  begin
    if rising_edge(clk) then
      vs_d <= vs;
      if vs_d = '1' and vs = '0' then
        r_last <= r_cnt;
        r_cnt  <= 0;
      elsif r = "1111" then
        r_cnt <= r_cnt + 1;
      end if;
    end if;
  end process;

  stim : process is
    alias sqx is <<signal .tb_vga.dut.sqx : unsigned(9 downto 0)>>;
    alias sqy is <<signal .tb_vga.dut.sqy : unsigned(9 downto 0)>>;

    procedure frames(n : natural) is
    begin
      for i in 1 to n loop
        wait until falling_edge(vs);
      end loop;
    end procedure;
  begin
    frames(3);
    wait for 1 us;
    assert sqx = 300 and sqy = 220 report "Posicion inicial incorrecta" severity error;
    assert r_last = 2 * 40 * 40
      report "Fondo negro: pixeles blancos esperados 1600, ciclos=" & natural'image(r_last) severity error;
    report "[1] Sincronismos y cuadrado inicial OK";

    
    
    btn(0) <= '0';  frames(2);  btn(0) <= '1';  wait for 1 us;
    assert sqx = 428 report "Derecha: sqx=" & integer'image(to_integer(sqx)) severity error;
    report "[2] Movimiento a la derecha OK";

    
    btn(2) <= '0';  frames(3);  btn(2) <= '1';  wait for 1 us;
    assert sqx = 236 report "Izquierda: sqx=" & integer'image(to_integer(sqx)) severity error;
    report "[3] Movimiento a la izquierda OK";

    
    sw(0) <= '1';  wait for 1 us;
    btn(2) <= '0';  frames(2);  btn(2) <= '1';  wait for 1 us;
    assert sqy = 92 report "Arriba: sqy=" & integer'image(to_integer(sqy)) severity error;
    assert sqx = 236 report "El eje X no debia cambiar" severity error;
    report "[4] Movimiento vertical (arriba) OK";

    
    btn(0) <= '0';  frames(6);  btn(0) <= '1';  wait for 1 us;
    assert sqy = 440 report "Limite inferior: sqy=" & integer'image(to_integer(sqy)) severity error;
    report "[5] Limite inferior OK";

    
    btn(2) <= '0';  frames(8);  btn(2) <= '1';  wait for 1 us;
    assert sqy = 0 report "Limite superior: sqy=" & integer'image(to_integer(sqy)) severity error;
    report "[6] Limite superior OK";

    
    sw(0) <= '0';  wait for 1 us;
    btn(0) <= '0';  frames(7);  btn(0) <= '1';  wait for 1 us;
    assert sqx = 600 report "Limite derecho: sqx=" & integer'image(to_integer(sqx)) severity error;
    report "[7] Limite derecho OK";

    
    btn(2) <= '0';  frames(11);  btn(2) <= '1';  wait for 1 us;
    assert sqx = 0 report "Limite izquierdo: sqx=" & integer'image(to_integer(sqx)) severity error;
    report "[8] Limite izquierdo OK";

    
    btn(1) <= '0';  wait for 1 us;  btn(1) <= '1';  wait for 1 us;
    assert sqx = 300 and sqy = 220 report "Reset incorrecto" severity error;
    report "[9] Reset OK";

    
    sw(3 downto 1) <= "100";  frames(2);
    assert r_last = 2 * (640*480 - 40*40)
      report "Fondo rojo: ciclos R=1111 esperados 611200, obtenidos " & natural'image(r_last) severity error;
    report "[10] Color de fondo y cuadrado inverso OK";

    report "=== SIMULACION TERMINADA ===";
    std.env.finish;
  end process;

end architecture sim;
