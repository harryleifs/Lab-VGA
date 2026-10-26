library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity tb_vga is
end entity tb_vga;
 
architecture sim of tb_vga is
  signal clk     : std_logic := '0';
  signal done    : boolean   := false;
  signal rst     : std_logic := '0';
  signal axis_v  : std_logic := '0';
  signal btn_dec : std_logic := '0';
  signal btn_inc : std_logic := '0';
  signal bg      : std_logic_vector(2 downto 0) := "000";
 
  signal hs, vs, von, ftick : std_logic;
  signal px, py, sqx, sqy   : unsigned(9 downto 0);
  signal r, g, b            : std_logic_vector(3 downto 0);
 
  signal hs_fall, vs_fall : time := 0 ns;
  signal r_cnt, r_last    : natural := 0;
  signal vs_d             : std_logic := '1';
begin
 
  -- Reloj de 50 MHz
  process is
  begin
    while not done loop
      clk <= '0';  wait for 10 ns;
      clk <= '1';  wait for 10 ns;
    end loop;
    wait;
  end process;
 
  u_sync : entity work.vga_sync
    port map (clk => clk, hsync => hs, vsync => vs, video_on => von,
              pixel_x => px, pixel_y => py, frame_tick => ftick);
 
  u_ctrl : entity work.square_ctrl
    generic map (SIZE => 40, STEP => 64)
    port map (clk => clk, rst => rst, frame_tick => ftick, axis_v => axis_v,
              btn_dec => btn_dec, btn_inc => btn_inc, sq_x => sqx, sq_y => sqy);
 
  u_pix : entity work.pixel_gen
    generic map (SIZE => 40)
    port map (pixel_x => px, pixel_y => py, video_on => von,
              sq_x => sqx, sq_y => sqy, bg => bg, r => r, g => g, b => b);
 
  -- HSync: periodo 32 us, pulso en bajo 3.84 us
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
 
  -- VSync: periodo 525 lineas = 16.8 ms, pulso en bajo 2 lineas = 64 us
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
 
  -- Cuenta ciclos de reloj con R="1111" en cada cuadro (2 ciclos por pixel)
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
      report "Fondo negro: ciclos esperados 3200, obtenidos " & natural'image(r_last) severity error;
    report "[1] Sincronismos y cuadrado inicial OK";
 
    -- Con STEP = 64: X_MAX = 600, Y_MAX = 440, inicio (300, 220)
    btn_inc <= '1';  frames(2);  btn_inc <= '0';  wait for 1 us;
    assert sqx = 428 report "Derecha: sqx=" & integer'image(to_integer(sqx)) severity error;
    report "[2] Movimiento a la derecha OK";
 
    btn_dec <= '1';  frames(3);  btn_dec <= '0';  wait for 1 us;
    assert sqx = 236 report "Izquierda: sqx=" & integer'image(to_integer(sqx)) severity error;
    report "[3] Movimiento a la izquierda OK";
 
    axis_v <= '1';  wait for 1 us;
    btn_dec <= '1';  frames(2);  btn_dec <= '0';  wait for 1 us;
    assert sqy = 92 report "Arriba: sqy=" & integer'image(to_integer(sqy)) severity error;
    assert sqx = 236 report "El eje X no debia cambiar" severity error;
    report "[4] Movimiento vertical (arriba) OK";
 
    btn_inc <= '1';  frames(6);  btn_inc <= '0';  wait for 1 us;
    assert sqy = 440 report "Limite inferior: sqy=" & integer'image(to_integer(sqy)) severity error;
    report "[5] Limite inferior OK";
 
    btn_dec <= '1';  frames(8);  btn_dec <= '0';  wait for 1 us;
    assert sqy = 0 report "Limite superior: sqy=" & integer'image(to_integer(sqy)) severity error;
    report "[6] Limite superior OK";
 
    axis_v <= '0';  wait for 1 us;
    btn_inc <= '1';  frames(7);  btn_inc <= '0';  wait for 1 us;
    assert sqx = 600 report "Limite derecho: sqx=" & integer'image(to_integer(sqx)) severity error;
    report "[7] Limite derecho OK";
 
    btn_dec <= '1';  frames(11);  btn_dec <= '0';  wait for 1 us;
    assert sqx = 0 report "Limite izquierdo: sqx=" & integer'image(to_integer(sqx)) severity error;
    report "[8] Limite izquierdo OK";
 
    rst <= '1';  wait for 1 us;  rst <= '0';  wait for 1 us;
    assert sqx = 300 and sqy = 220 report "Reset incorrecto" severity error;
    report "[9] Reset OK";
 
    -- Fondo rojo: R=1111 en todo el area visible menos el cuadrado (que sale cian)
    bg <= "100";  frames(2);
    assert r_last = 2 * (640*480 - 40*40)
      report "Fondo rojo: esperados 611200, obtenidos " & natural'image(r_last) severity error;
    report "[10] Color de fondo y cuadrado inverso OK";
 
    report "=== SIMULACION TERMINADA ===";
    done <= true;
    wait;
  end process;
 
end architecture sim;
 
