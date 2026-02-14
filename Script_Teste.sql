DECLARE
  vresultado VARCHAR2(200);
  vtotal     INT := 0;
  vok        INT := 0;

  PROCEDURE testar(p_descricao IN VARCHAR2, p_entrada IN VARCHAR2, p_esperado IN VARCHAR2) IS
  BEGIN
    vtotal := vtotal + 1;
    vresultado := pkg_util.foneticabr(str1 => p_entrada);
    IF vresultado = p_esperado THEN
      vok := vok + 1;
      DBMS_OUTPUT.put_line('OK   [' || p_descricao || '] ' || p_entrada || ' => ' || vresultado);
    ELSE
      DBMS_OUTPUT.put_line('FALHA[' || p_descricao || '] ' || p_entrada || ' => ' || vresultado || ' (esperado: ' || p_esperado || ')');
    END IF;
  END;

BEGIN
  DBMS_OUTPUT.put_line('=== TESTES BASICOS ===');
  testar('basico',         'JOAO DA SILVA E OLIVEIRA', 'JO DA SIRVA E ORIVEIRA');
  testar('acento-a',       'JOSE',                     'JOSE');
  testar('duplicata',      'ANNA',                     'ANA');

  DBMS_OUTPUT.put_line('');
  DBMS_OUTPUT.put_line('=== REGRAS ORIGINAIS ===');
  testar('LH->L',          'FILHO',                    'FIRO');
  testar('NH->N (fix)',     'NINHO',                    'NINO');
  testar('NG->G (fix)',     'ANGOLA',                   'AGORA');
  testar('Z->S (fix)',      'FAZENDA',                  'FASEMDA');
  testar('PH->F',          'PHELIPE',                  'FERIPE');
  testar('W->U',           'WILSON',                   'UIRSO');
  testar('Y->I',           'YURI',                     'IURI');
  testar('CH->S',          'CHAVE',                    'SAVE');
  testar('GE->J',          'GENTE',                    'JEMTE');
  testar('CE->S',          'CESAR',                    'SESA');

  DBMS_OUTPUT.put_line('');
  DBMS_OUTPUT.put_line('=== NOVAS REGRAS (fontes: BuscaBR / Metaphone-ptBR) ===');

  -- QUE/QUI: U silencioso antes de E/I apos Q (dígrafo)
  -- Fonte: ortografia portuguesa - QU antes de E/I o U nao e pronunciado
  testar('QUE->KE',        'QUEIJO',                   'KEIO');
  testar('QUI->KI',        'QUILOMBO',                 'KIROMBO');
  testar('QUE->KE (meio)', 'ESQUEMA',                  'ESKEMA');

  -- SCE/SCI: SC antes de E/I tem som de S simples (o C e silencioso)
  -- Fonte: dígrafos do português - "nascer" soa como "naser"
  testar('SCE->SE',        'NASCER',                   'NASE');
  testar('SCI->SI',        'DESCIDA',                  'DESIDA');
  testar('SCE->SE (exc)',  'EXCEPCIONAL',              'ESEOSIONAR');

  -- TH: regra para palavras historicas e estrangeiras
  -- Fonte: BuscaBR / Metaphone-ptBR - TH tem som de T em portugues
  testar('TH->T',          'THEATRO',                  'TEATRO');
  testar('TH->T (nome)',   'THOMAS',                   'TOMA');

  -- RM: corrigido de RM->SM para RM->M (padrao BuscaBR)
  -- Fonte: BuscaBR - RM tem som nasal M em portugues brasileiro
  testar('RM->M (fix)',    'ARMANDO',                  'AMADO');
  testar('RM->M (nome)',   'HERMANO',                  'ERMANO');

  -- SM: novo dígrafo SM->M (padrao BuscaBR)
  -- Fonte: BuscaBR - SM reduz ao som nasal M
  testar('SM->M',          'ESMERALDA',                'EMERARDA');

  DBMS_OUTPUT.put_line('');
  DBMS_OUTPUT.put_line('=== EQUIVALENCIAS FONETICAS (busca fuzzy) ===');
  -- Nomes que devem produzir o mesmo codigo fonetico
  DECLARE
    v1 VARCHAR2(200);
    v2 VARCHAR2(200);
    PROCEDURE comparar(p_nome1 IN VARCHAR2, p_nome2 IN VARCHAR2) IS
    BEGIN
      vtotal := vtotal + 1;
      v1 := pkg_util.foneticabr(p_nome1);
      v2 := pkg_util.foneticabr(p_nome2);
      IF v1 = v2 THEN
        vok := vok + 1;
        DBMS_OUTPUT.put_line('OK   ' || p_nome1 || ' ~ ' || p_nome2 || ' => ' || v1);
      ELSE
        DBMS_OUTPUT.put_line('DIFS ' || p_nome1 || '(' || v1 || ') # ' || p_nome2 || '(' || v2 || ')');
      END IF;
    END;
  BEGIN
    comparar('RAFAEL',    'RAPHAEL');    -- PH=F
    comparar('WALTER',    'VALTER');     -- W=V (BuscaBR) vs U (FoneticaBR)
    comparar('QUEIJO',    'KEIJO');      -- QUE=KE
    comparar('CECILIA',   'SESILIA');    -- CE=S, CI=S
    comparar('GONZAGA',   'GONSAGA');    -- Z=S
    comparar('CHRISTIANO','CRISTIANO'); -- CHR=KR
    comparar('THIAGO',    'TIAGO');      -- TH=T
  END;

  DBMS_OUTPUT.put_line('');
  DBMS_OUTPUT.put_line('=== RESULTADO: ' || vok || '/' || vtotal || ' testes OK ===');
END;
