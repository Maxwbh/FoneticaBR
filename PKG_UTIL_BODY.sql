CREATE OR REPLACE PACKAGE BODY PKG_UTIL IS


   FUNCTION normalize(str1 IN VARCHAR2) RETURN VARCHAR2 IS
    pos           INT;
    str           VARCHAR2(3000);
    chars_special VARCHAR2(255) := chr( 198 ) ||chr( 198 ) ||chr( 223 ) ||chr( 193 ) ||chr( 194 ) ||chr( 195 ) ||chr( 196 ) ||chr( 197 ) ||
                                   chr( 199 ) ||chr( 200 ) ||chr( 201 ) ||chr( 202 ) ||chr( 203 ) ||chr( 204 ) ||chr( 205 ) ||chr( 206 ) ||
				   chr( 207 ) ||chr( 208 ) ||chr( 209 ) ||chr( 210 ) ||chr( 211 ) ||chr( 212 ) ||chr( 213 ) ||chr( 214 ) ||
				   chr( 216 ) ||chr( 217 ) ||chr( 218 ) ||chr( 219 ) ||chr( 220 ) ||chr( 221 ) ||chr( 89 ) ;
    -- chars_special VARCHAR2(255) := 'ÆÆßÁÂÃÄÅÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝY';
    chars_normal  VARCHAR2(255) := 'AABAAAAACEEEEIIIIDNOOOOOOUUUUYY';
  
  BEGIN
  
    str := upper(str1);
    FOR pos IN 1 .. length(chars_normal) LOOP
      str := REPLACE(str, substr(chars_special, pos, 1), substr(chars_normal, pos, 1));
    END LOOP;
  
    str := TRIM(str);
  
    WHILE instr(str, '  ') > 0 LOOP
      str := REPLACE(str, '  ', ' ');
    END LOOP;
    str := regexp_replace(str, '[^A-Z0-9Ç&@_ +-]+');
    RETURN str;
  END;

  FUNCTION foneticabr(str1 IN VARCHAR2) RETURN VARCHAR2 IS   
    chars_s VARCHAR2(255) := 'BL,BR,Ç,CHR,CA,CE,CH,CI,CK,CO,CS,CT,CU,C,GE,GI,GL,GM,GR,LH,LT,L,MD,MG,MJ,N,NG,NH,NJ,PH,PR,Q,RG,RJ,RM,RS,RT,ST,TL,TR,TS,W,X,Y,Z';
    chars_r VARCHAR2(255) := 'B,B,S,KR,K,S,S,S,K,K,S,T,K,K,J,J,G,M,G,L,T,R,M,G,J,M,G,N,J,F,P,K,G,J,SM,S,T,T,T,T,S,U,S,I,S';
    str     VARCHAR2(3000);
    strproc VARCHAR2(3000);
    strsub  VARCHAR2(3000);
  BEGIN
  
    str := normalize(str1);

    FOR pos IN 1 .. regexp_count(chars_s, ',') LOOP
      strproc := regexp_substr(chars_s, '[^,]+', 1, pos);
      strsub  := regexp_substr(chars_r, '[^,]+', 1, pos);
      str     := REPLACE(str, strproc, strsub);
    END LOOP;
  
    -- 18. Eliminamos as terminações S, Z, R, R, M, N, AO e L;
    str := str || ' ';
    str := REPLACE(str, 'S ', ' ');
    str := REPLACE(str, 'Z ', ' ');
    str := REPLACE(str, 'R ', ' ');
    str := REPLACE(str, 'M ', ' ');
    str := REPLACE(str, 'N ', ' ');
    str := REPLACE(str, 'AO ', ' ');
    str := REPLACE(str, 'L ', ' ');
    str := REPLACE(str, 'H', '');
    str := TRIM(str);
  
    FOR a IN 65 .. 90 LOOP
      str := REPLACE(str, chr(a) || chr(a), chr(a));
    END LOOP;
  
    RETURN str;
  END;
						
END pkg_util;
	
