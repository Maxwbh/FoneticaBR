CREATE OR REPLACE PACKAGE PKG_UTIL IS

    -- Author  : MAXWELL.OLIVEIRA
    -- Created : 11/04/2019
    -- Purpose : Package contendo funcionalidades gerais de utilizacao - Fonetica Brasileira

    --FUNCTION normalize(str1 IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION foneticabr(str1 IN VARCHAR2) RETURN VARCHAR2;

END pkg_util;
