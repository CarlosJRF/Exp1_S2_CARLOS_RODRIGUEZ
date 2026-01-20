VARIABLE b_fecha VARCHAR2(20);

EXEC :b_fecha := TO_DATE('19/01/2026','DD/MM/YYYY');

DECLARE
    v_fecha_de_proceso  DATE;
    v_annios_trabajados VARCHAR2(10);
    v_usuario           VARCHAR2(50);
    v_clave             VARCHAR2(50);
    
    -- Variables referenciadas a la tabla EMPLEADO
    v_id_emp            EMPLEADO.ID_EMP%TYPE;
    v_nombre_emp        EMPLEADO.PNOMBRE_EMP%TYPE;
    v_run_emp           EMPLEADO.NUMRUN_EMP%TYPE;
    v_dvrun_emp         EMPLEADO.DVRUN_EMP%TYPE;
    v_fecha_nac_emp     EMPLEADO.FECHA_NAC%TYPE;
    v_sueldob_emp       EMPLEADO.SUELDO_BASE%TYPE;
    v_appaterno_emp     EMPLEADO.APPATERNO_EMP%TYPE;
    v_id_estadocv_emp   EMPLEADO.ID_ESTADO_CIVIL%TYPE;
    v_fecha_contrato    EMPLEADO.FECHA_CONTRATO%TYPE;
    
    --  Referencia a la tabla correcta (ESTADO_CIVIL)
    v_nombre_estadocv_emp ESTADO_CIVIL.NOMBRE_ESTADO_CIVIL%TYPE; 

BEGIN
    -- 1. Limpieza
    EXECUTE IMMEDIATE 'TRUNCATE TABLE USUARIO_CLAVE REUSE STORAGE';

    v_fecha_de_proceso := :b_fecha;

    -- 2. Bucle
    FOR v_id_iterador IN 100..320 LOOP
        BEGIN
            --  Usamos JOIN para traer datos de tablas EMPLEADO y ESTADO_CIVIL
            SELECT e.ID_EMP, e.NUMRUN_EMP, e.DVRUN_EMP, e.PNOMBRE_EMP, e.APPATERNO_EMP, 
                   e.FECHA_NAC, e.SUELDO_BASE, e.ID_ESTADO_CIVIL, ec.NOMBRE_ESTADO_CIVIL, e.FECHA_CONTRATO
            INTO   v_id_emp, v_run_emp, v_dvrun_emp, v_nombre_emp, v_appaterno_emp, 
                   v_fecha_nac_emp, v_sueldob_emp, v_id_estadocv_emp, v_nombre_estadocv_emp, v_fecha_contrato
            FROM   EMPLEADO e
            JOIN   ESTADO_CIVIL ec ON e.ID_ESTADO_CIVIL = ec.ID_ESTADO_CIVIL
            WHERE  e.ID_EMP = v_id_iterador;
            
            -- B. Años trabajados
            v_annios_trabajados := TO_CHAR(TRUNC(MONTHS_BETWEEN(v_fecha_de_proceso, v_fecha_contrato) / 12));
            
            -- C. Usuario 
            v_usuario := SUBSTR(LOWER(v_nombre_estadocv_emp), 1, 1) || 
                         SUBSTR(v_nombre_emp, 1, 3) || 
                         TO_CHAR(LENGTH(v_nombre_emp)) || 
                         '*' || 
                         SUBSTR(v_sueldob_emp, -1, 1) || 
                         TO_CHAR(v_dvrun_emp) || 
                         v_annios_trabajados;
            
            IF TO_NUMBER(v_annios_trabajados) < 10 THEN
                v_usuario := v_usuario || 'X';
            END IF;

            -- D. Clave
            CASE v_id_estadocv_emp
                WHEN 10 THEN -- Casado
                    v_clave := SUBSTR(v_run_emp, 3, 1) ||
                               TO_CHAR(ADD_MONTHS(v_fecha_nac_emp, 24), 'YYYY') ||
                               (TO_NUMBER(SUBSTR(v_sueldob_emp, -3)) - 1) ||
                               SUBSTR(LOWER(v_appaterno_emp), 1, 2) ||
                               v_id_emp ||
                               TO_NUMBER(TO_CHAR(v_fecha_de_proceso, 'DDMMYY')); 
                
                WHEN 20 THEN -- Divorciado
                    v_clave := SUBSTR(v_run_emp, 3, 1) ||
                               TO_CHAR(ADD_MONTHS(v_fecha_nac_emp, 24), 'YYYY') ||
                               (TO_NUMBER(SUBSTR(v_sueldob_emp, -3)) - 1) ||
                               SUBSTR(LOWER(v_appaterno_emp), 1, 1) ||
                               SUBSTR(LOWER(v_appaterno_emp), -1, 1) ||
                               v_id_emp ||
                               TO_NUMBER(TO_CHAR(v_fecha_de_proceso, 'DDMMYY'));

                WHEN 30 THEN -- Soltero
                    v_clave := SUBSTR(v_run_emp, 3, 1) ||
                               TO_CHAR(ADD_MONTHS(v_fecha_nac_emp, 24), 'YYYY') ||
                               (TO_NUMBER(SUBSTR(v_sueldob_emp, -3)) - 1) ||
                               SUBSTR(LOWER(v_appaterno_emp), 1, 1) ||
                               SUBSTR(LOWER(v_appaterno_emp), -1, 1) ||
                               v_id_emp ||
                               TO_NUMBER(TO_CHAR(v_fecha_de_proceso, 'DDMMYY'));

                WHEN 40 THEN -- Viudo
                    v_clave := SUBSTR(v_run_emp, 3, 1) ||
                               TO_CHAR(ADD_MONTHS(v_fecha_nac_emp, 24), 'YYYY') ||
                               (TO_NUMBER(SUBSTR(v_sueldob_emp, -3)) - 1) ||
                               SUBSTR(LOWER(v_appaterno_emp), -3, 1) ||
                               SUBSTR(LOWER(v_appaterno_emp), -2, 1) ||
                               v_id_emp ||
                               TO_NUMBER(TO_CHAR(v_fecha_de_proceso, 'DDMMYY'));

                WHEN 50 THEN -- Separado
                    v_clave := SUBSTR(v_run_emp, 3, 1) ||
                               TO_CHAR(ADD_MONTHS(v_fecha_nac_emp, 24), 'YYYY') ||
                               (TO_NUMBER(SUBSTR(v_sueldob_emp, -3)) - 1) ||
                               SUBSTR(LOWER(v_appaterno_emp), -2) ||
                               v_id_emp ||
                               TO_NUMBER(TO_CHAR(v_fecha_de_proceso, 'DDMMYY'));

                WHEN 60 THEN -- Union Civil
                    v_clave := SUBSTR(v_run_emp, 3, 1) ||
                               TO_CHAR(ADD_MONTHS(v_fecha_nac_emp, 24), 'YYYY') ||
                               (TO_NUMBER(SUBSTR(v_sueldob_emp, -3)) - 1) ||
                               SUBSTR(LOWER(v_appaterno_emp), 1, 2) ||
                               v_id_emp ||
                               TO_NUMBER(TO_CHAR(v_fecha_de_proceso, 'DDMMYY'));
            END CASE;

            -- E. Insertar
            INSERT INTO USUARIO_CLAVE (ID_EMP, NUMRUN_EMP, DVRUN_EMP, NOMBRE_EMPLEADO, NOMBRE_USUARIO, CLAVE_USUARIO)
            VALUES (v_id_emp, v_run_emp, v_dvrun_emp, v_nombre_emp || ' ' || v_appaterno_emp, v_usuario, v_clave);

        EXCEPTION 
            WHEN NO_DATA_FOUND THEN 
                NULL; 
        END;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Proceso finalizado exitosamente.');
END;






