CREATE OR REPLACE PACKAGE BODY PKG_UTIL IS


 FUNCTION normalize(str1 IN VARCHAR2) RETURN VARCHAR2 IS
        pos           INT;
        str           VARCHAR2(3000);
        chars_special VARCHAR2(255) := 'ÆÆßÁÂÃÄÅÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝY';
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
        pos     INT;
        chars_s VARCHAR2(255) := 'BL,BR,Ç,CHR,CA,CE,CH,CI,CK,CO,CS,CT,CU,C,GE,GI,GL,GM,GR,LH,LT,L,MD,MG,MJ,N,NG,NH,NJ,PH,PR,Q,RG,RJ,RM,RS,RT,ST,TL,TR,TS,W,X,Y,Z';
        chars_r VARCHAR2(255) := 'B,B,S,KR,K,S,S,S,K,K,S,T,K,K,J,J,G,M,G,L,T,R,M,G,J,M,G,N,J,F,P,K,G,J,SM,S,T,T,T,T,S,U,S,I,S';
        str     VARCHAR2(3000);
        strproc VARCHAR2(3000);
        strsub  VARCHAR2(3000);
    BEGIN
    
        str := normalize(str1);
        pos := 1;
    
        WHILE instr(chars_s, ',', 1, pos) > 0 LOOP
            SELECT substr(chars_s,
                          decode(pos, 1, 1, instr(chars_s, ',', 1, pos - 1) + 1),
                          decode(pos,
                                 1,
                                 instr(chars_s, ',', 1, pos) - 1,
                                 instr(chars_s, ',', 1, pos) - instr(chars_s, ',', 1, pos - 1) - 1))
              INTO strproc
              FROM dual;
            SELECT substr(chars_r,
                          decode(pos, 1, 1, instr(chars_r, ',', 1, pos - 1) + 1),
                          decode(pos,
                                 1,
                                 instr(chars_r, ',', 1, pos) - 1,
                                 instr(chars_r, ',', 1, pos) - instr(chars_r, ',', 1, pos - 1) - 1)
                          
                          )
              INTO strsub
              FROM dual;
            pos := pos + 1;
            str := REPLACE(str, strproc, strsub);
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
	