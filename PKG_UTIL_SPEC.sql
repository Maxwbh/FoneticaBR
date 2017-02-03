CREATE OR REPLACE PACKAGE PKG_UTIL IS

    -- Author  : MAXWELL.OLIVEIRA
    -- Created : 09/07/2013 10:20:22
    -- Purpose : Pack contendo funcionalidades gerias de utilização

    FUNCTION normalize(str1 IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION foneticabr(str1 IN VARCHAR2) RETURN VARCHAR2;

END pkg_util;