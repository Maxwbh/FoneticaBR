DECLARE 
   vresultado VARCHAR2(200);
begin
  -- Call the function
  vresultado  := pkg_util.foneticabr(str1 => 'JOÃO DA SILVA E OLIVEIRA');
  DBMS_OUTPUT.put_line(vresultado);
  -- JO DA SIRVA E ORIVEIRA  
end;