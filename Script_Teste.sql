DECLARE
  vresultado VARCHAR2(200);

  PROCEDURE testar(p_entrada IN VARCHAR2, p_esperado IN VARCHAR2) IS
  BEGIN
    vresultado := pkg_util.foneticabr(str1 => p_entrada);
    IF vresultado = p_esperado THEN
      DBMS_OUTPUT.put_line('OK   : ' || p_entrada || ' => ' || vresultado);
    ELSE
      DBMS_OUTPUT.put_line('FALHA: ' || p_entrada || ' => ' || vresultado || ' (esperado: ' || p_esperado || ')');
    END IF;
  END;

BEGIN
  -- Teste basico
  testar('JOAO DA SILVA E OLIVEIRA', 'JO DA SIRVA E ORIVEIRA');

  -- Teste Ç -> S (bug fix: Ç era convertido para C no normalize)
  testar('ACUCAR', 'ASUKA');

  -- Teste NH -> N (bug fix: N->M era aplicado antes de NH->N)
  testar('NINHO', 'NINO');

  -- Teste NG -> G (bug fix: N->M era aplicado antes de NG->G)
  testar('ANGOLA', 'AGORA');

  -- Teste Z -> S no meio da palavra (bug fix: off-by-one no loop)
  testar('FAZENDA', 'FASEMDA');

  -- Teste com acentos
  testar('JOSE', 'JOSE');

  -- Teste W -> U, Y -> I
  testar('WILSON', 'UIRSO');
  testar('YURI', 'IURI');

  -- Teste PH -> F
  testar('PHELIPE', 'FERIPE');

  -- Teste duplicatas
  testar('ANNA', 'ANA');

END;
