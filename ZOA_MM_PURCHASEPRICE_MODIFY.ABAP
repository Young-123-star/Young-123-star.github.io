*&----------------------------------------------------------------------
*&函数名称: ZOA_PURPRICE_MODIFY
*&作者:     DLW
*&完成日期: 2025/07/02
*&描述:     采购信息记录维护接口  tcode:ME11/ME12
*&项目名称: 宝时得
*&----------------------------------------------------------------------
FUNCTION zoa_mm_purchaseprice_modify.
*"----------------------------------------------------------------------
*"*"本地接口：
*"  IMPORTING
*"     VALUE(IV_JSON) TYPE  STRING OPTIONAL
*"  EXPORTING
*"     VALUE(EX_STATUS) TYPE  CHAR1
*"     VALUE(EX_MESSAGE) TYPE  BAPIRET2-MESSAGE
*"     VALUE(EX_JSON) TYPE  STRING
*"----------------------------------------------------------------------

  TYPES:BEGIN OF ty_inputitems ,
          lifnr                    TYPE lifnr,
          matnr                    TYPE matnr,
          i_ekorg                  TYPE ekorg,
          werks                    TYPE werks_d,
          normb                    TYPE normb,
          infnr                    TYPE infnr,
          zflag                    TYPE char1, "C:创建 U:修改
          zstep                    TYPE char1, "传1代表成品采购流程，需要取OA传入的字段，其他场景（促销品，配件）有些数据取配置表ztmm_pur_cof/ztmm_mat_cof3
          i_ekgrp                  TYPE ekgrp,  "采购组
          i_norbm                  TYPE norbm,  "标准数量
          i_aplfz                  TYPE char3,  "计划交货时间
          i_mwskz                  TYPE mwskz,  "税码
          i_bstae                  TYPE eine-bstae,  "确认控制代码
          i_rdprf                  TYPE eine-rdprf,  "取整参数文件
          i_netpr                  TYPE netpr,
          i_peinh                  TYPE peinh,
          i_waers                  TYPE waers,
          i_datab                  TYPE datab,
          i_datbi                  TYPE datbi,
          i_kstbm1                 TYPE menge_d,
          i_netpr1                 TYPE dmbtr,
          i_kstbm2                 TYPE menge_d,
          i_netpr2                 TYPE dmbtr,
          i_kstbm3                 TYPE menge_d,
          i_netpr3                 TYPE dmbtr,
**add by wangyang 20260108 新增OA传入字段存入自建表，供OA其他流程查询
          modelprice               LIKE zpds_eine_text-modelprice,
          pdsremark                LIKE zpds_eine_text-pdsremark,
          chayiprice               LIKE zpds_eine_text-chayiprice,
          chayiprice_remark        LIKE zpds_eine_text-chayiprice_remark,
          trans_material_diffprice LIKE zpds_eine_text-trans_material_diffprice,
          tranmat_diffpr_remark    LIKE zpds_eine_text-tranmat_diffpr_remark,
          taxinclusive_price       LIKE zpds_eine_text-taxinclusive_price,
          bonded_material          LIKE zpds_eine_text-bonded_material,
          purchase_agent           LIKE zpds_eine_text-purchase_agent,
          in_pay                   LIKE zpds_eine_text-in_pay,
          purchase_text            LIKE zpds_eine_text-purchase_text,
          i_beskz                  TYPE string,  "采购类型-特殊采购类 格式:BESKZ-SOBSL 如:F-30
        END OF ty_inputitems .
  DATA:lt_inputitems      TYPE TABLE OF ty_inputitems,
       ls_inputitems      LIKE LINE OF lt_inputitems,
       lt_inputitems_pg4x TYPE TABLE OF ty_inputitems,
       ls_inputitems_pg4x LIKE LINE OF lt_inputitems.

  TYPES:BEGIN OF ty_inputheader,
          items LIKE lt_inputitems,
        END OF ty_inputheader.
  DATA: ls_inputheader TYPE ty_inputheader.
*****************************************
  TYPES:BEGIN OF ty_item ,
          i_ekgrp  TYPE ekgrp,  "采购组
          i_norbm  TYPE norbm,  "标准数量
          i_aplfz  TYPE char3,  "计划交货时间
          i_mwskz  TYPE mwskz,  "税码
          i_bstae  TYPE eine-bstae,  "确认控制代码
          i_rdprf  TYPE eine-rdprf,  "取整参数文件
          i_netpr  TYPE netpr,
          i_peinh  TYPE peinh,
          i_waers  TYPE waers,
          i_datab  TYPE datab,
          i_datbi  TYPE datbi,
          i_kstbm1 TYPE menge_d,
          i_netpr1 TYPE dmbtr,
          i_kstbm2 TYPE menge_d,
          i_netpr2 TYPE dmbtr,
          i_kstbm3 TYPE menge_d,
          i_netpr3 TYPE dmbtr,
          zflag    TYPE char1,
          zstep    TYPE char1,
        END OF ty_item .
  DATA:lt_item TYPE TABLE OF ty_item,
       ls_item LIKE LINE OF lt_item.

  TYPES:BEGIN OF ty_req ,
          lifnr   TYPE lifnr,
          matnr   TYPE matnr,
          i_ekorg TYPE ekorg,
          werks   TYPE werks_d,
          normb   TYPE char1,
          infnr   TYPE infnr,
          zflag   TYPE string,
          zstep   TYPE string,
          feskz   TYPE feskz,
          i_beskz TYPE string,  "采购类型-特殊采购类
          item    LIKE lt_item,
        END OF ty_req .

  DATA:lt_req TYPE TABLE OF ty_req,
       ls_req TYPE ty_req.
  DATA:lt_req_cof3 TYPE TABLE OF ty_req,
       ls_req_cof3 TYPE ty_req.
  DATA:lv_matnr TYPE matnr.
  DATA:lv_beskz TYPE beskz.

********************************************
  TYPES: BEGIN OF ty_res,
           infnr   TYPE eine-infnr,
           lifnr   TYPE lifnr,
           matnr   TYPE matnr,
           i_ekorg TYPE ekorg,
           werks   TYPE werks_d,
           normb   TYPE char1,
           status  TYPE char1,
           recode  TYPE char3,
           message TYPE char100,
         END OF ty_res.

  DATA: lt_item_res TYPE TABLE OF ty_res,
        ls_item_res LIKE LINE OF lt_item_res.

  DATA: lv_message TYPE string.

  DATA  BEGIN  OF  lt_bdc  OCCURS  0.
          INCLUDE  STRUCTURE  bdcdata.
  DATA  END  OF lt_bdc.
  DATA lv_mode TYPE c VALUE 'N'.
  DATA: lt_mess LIKE bdcmsgcoll OCCURS 0 WITH HEADER LINE.
  DATA: lv_price TYPE char10.
  DATA: lv_esokz TYPE char11.

  DATA: gc_ifnum  TYPE zif_ifnum VALUE 'OA-SAP-006',
        ls_header TYPE zif_header.
  TYPES: BEGIN OF itab_pg4x,
           werks_in TYPE werks_d,
           werks    TYPE werks_d,
         END OF itab_pg4x.
  DATA:lt_itab_pg4x TYPE TABLE OF itab_pg4x,
       ls_itab_pg4x TYPE itab_pg4x.
  DATA:lt_ztmm_mat_cof3 LIKE TABLE OF ztmm_mat_cof3,
       ls_ztmm_mat_cof3 LIKE ztmm_mat_cof3.
  DATA:ls_ztmm_pur_cof LIKE ztmm_pur_cof.
  DATA:ls_ztmm_pur_cof_cn LIKE ztmm_pur_cof_cn.

  DATA:ls_zpds_eine_text        LIKE zpds_eine_text,
       lt_zpds_eine_text        LIKE TABLE OF zpds_eine_text,
       lt_zpds_eine_text_single LIKE TABLE OF zpds_eine_text.

  DATA: lv_beskz_val     TYPE marc-beskz,
        lv_sobsl_val     TYPE marc-sobsl,
        ls_headdata_mm   TYPE bapimathead,
        ls_plantdata_mm  TYPE bapi_marc,
        ls_plantdatax_mm TYPE bapi_marcx,
        lt_bapi_ret      TYPE TABLE OF bapiret2,
        ls_bapi_ret      TYPE bapiret2.

*&-----log
  TRY.
      DATA:lv_act TYPE zif_ifact.
      DATA(lo_log) = NEW zcl_if_log_handler( i_ifnum = gc_ifnum  ).
      lo_log->set_guid( ).
      lo_log->modify_header( i_statu = '02' i_ifmsg = text-m01 ).
      lo_log->save_payload( i_logtyp = 'I' i_paylod = iv_json ).
      lo_log->check_active( IMPORTING o_act = lv_act ).
    CATCH cx_ai_system_fault INTO DATA(lo_sys_exception2).
  ENDTRY.

  IF lv_act = ''.
    ls_header-ifmsg = text-e01 .
    lo_log->modify_header( i_statu = '02' i_ifmsg = ls_header-ifmsg ).
    RETURN .
  ENDIF.

*  iv_json = '[{"zflag":"D","LIFNR":"10180","MATNR":"A123123213","I_EKORG":"1000","WERKS":"1000","NORMB":"0","item":[{"I_EKGRP":"A14","I_NORBM":"1","I_APLFZ":"30","I_MWSKZ":"J0","I_NETPR":"100","I_PEINH":"1","I_WAERS":"RMB",'
*            && '"I_DATAB":"20250507","I_DATBI":"20250520","I_KSTBM1":"2","I_KSTBM2":"5","I_NETPR2":"150","I_KSTBM3":"6","I_NETPR3":"160"}]}]'.

  IF iv_json IS INITIAL.
    ex_status = 'E'.
    ex_message = '请求数据不能为空！'.
    "&-----日志记录
    ls_header-if_statu = '02'.
    ls_header-ifmsg = ex_message.
    TRY.
        lo_log->modify_header( i_statu = ls_header-if_statu i_ifmsg = ls_header-ifmsg i_busno = CONV #( '00006' ) ).
        lo_log->save_payload( i_logtyp = 'O' i_paylod = ex_json )."
      CATCH cx_ai_system_fault INTO lo_sys_exception2.
    ENDTRY.
    RETURN.
  ENDIF.

  "接收入参
  /ui2/cl_json=>deserialize(
    EXPORTING json = iv_json
    CHANGING data = ls_inputheader
    ).
*传入工厂为PG4X时，需要同时创建PG41/PG42/PG43/PG44/PG46/PG47工厂
  lt_itab_pg4x = VALUE #( ( werks_in = 'PG4X' werks = 'PG41' )
                          ( werks_in = 'PG4X' werks = 'PG42' )
                          ( werks_in = 'PG4X' werks = 'PG43' )
                          ( werks_in = 'PG4X' werks = 'PG44' )
                          ( werks_in = 'PG4X' werks = 'PG46' )
                          ( werks_in = 'PG4X' werks = 'PG47' )
                          ).

  CLEAR:ls_inputitems,ls_itab_pg4x,ls_inputitems_pg4x,lt_inputitems_pg4x[].
*将PG4X扩充为对应的几个工厂
  LOOP AT ls_inputheader-items INTO ls_inputitems WHERE werks = 'PG4X'.
    LOOP AT lt_itab_pg4x INTO ls_itab_pg4x WHERE werks_in = ls_inputitems-werks.
      MOVE-CORRESPONDING:ls_inputitems TO ls_inputitems_pg4x.
      ls_inputitems_pg4x-werks = ls_itab_pg4x-werks.
      APPEND ls_inputitems_pg4x TO lt_inputitems_pg4x.
    ENDLOOP.
  ENDLOOP.
*删除原内表中PG4X的数据
  DELETE ls_inputheader-items WHERE werks = 'PG4X'.
*将PG4*的工厂全部附加到原内表
  APPEND LINES OF lt_inputitems_pg4x TO ls_inputheader-items.
**

  CLEAR:ls_inputitems.
  LOOP AT ls_inputheader-items INTO ls_inputitems.
    CLEAR:ls_req.
    ls_req-lifnr = ls_inputitems-lifnr.
    ls_req-matnr = ls_inputitems-matnr.
    ls_req-i_ekorg = ls_inputitems-i_ekorg.
    ls_req-werks = ls_inputitems-werks.
    ls_req-infnr = ls_inputitems-infnr.
    ls_req-zflag = ls_inputitems-zflag.
*add by wangyang 20251121
    ls_req-zstep   = ls_inputitems-zstep.
    ls_req-i_beskz = ls_inputitems-i_beskz.
    IF ls_inputitems-zflag = 'C' AND ls_inputitems-normb IS INITIAL.
      ls_req-normb = '0'.
    ELSE.
      ls_req-normb = ls_inputitems-normb.
    ENDIF.
    APPEND ls_req TO lt_req.
**add by wangyang 20260108 将部分字段存入自建表ZPDS_EINE_TEXT
    CLEAR ls_zpds_eine_text.
    MOVE-CORRESPONDING:ls_inputitems TO ls_zpds_eine_text.
    ls_zpds_eine_text-matnr = |{ ls_zpds_eine_text-matnr ALPHA = IN }|.
    ls_zpds_eine_text-lifnr = |{ ls_zpds_eine_text-lifnr ALPHA = IN }|.
    ls_zpds_eine_text-ekorg = ls_inputitems-i_ekorg.
    SELECT SINGLE model FROM mara INTO ls_zpds_eine_text-zmodel WHERE matnr = ls_zpds_eine_text-matnr.
    APPEND ls_zpds_eine_text TO lt_zpds_eine_text.
  ENDLOOP.
  SORT lt_req BY lifnr matnr i_ekorg werks.
  DELETE ADJACENT DUPLICATES FROM lt_req.

**add by wangyang 20260112
  DATA:lv_count       TYPE i,
       lt_req_grouped TYPE TABLE OF ty_req,
       lt_eord_keys   TYPE TABLE OF eord WITH EMPTY KEY,
       lt_eord_data   TYPE TABLE OF eord WITH KEY matnr werks,
       ls_eord        TYPE eord.

  SORT lt_req BY matnr werks lifnr.

  LOOP AT lt_req ASSIGNING FIELD-SYMBOL(<fs_req>) GROUP BY ( matnr = <fs_req>-matnr
                                               werks = <fs_req>-werks
                                               lv_count  = GROUP SIZE )
                 ASSIGNING FIELD-SYMBOL(<fs_group>).

    DATA(lv_sup_count) = REDUCE i( INIT x = 0
                         FOR GROUPS lifnr_group OF <fs_line> IN GROUP <fs_group>
                         GROUP BY ( lifnr = <fs_line>-lifnr )
                         NEXT x = x + 1 ).

    LOOP AT GROUP <fs_group> ASSIGNING FIELD-SYMBOL(<fs_req_final>).
      IF lv_sup_count > 1.
        <fs_req_final>-feskz = 'N'."物料工厂对应多个供应商不维护固定货源
      ELSE.
        APPEND VALUE #( matnr = <fs_req_final>-matnr
                        werks = <fs_req_final>-werks ) TO lt_eord_keys.
      ENDIF.
    ENDLOOP.
  ENDLOOP.

  DELETE ADJACENT DUPLICATES FROM lt_eord_keys COMPARING matnr werks.
  IF lt_eord_keys IS NOT INITIAL.
    SELECT matnr werks FROM eord
      INTO CORRESPONDING FIELDS OF TABLE lt_eord_data
      FOR ALL ENTRIES IN lt_eord_keys
      WHERE matnr = lt_eord_keys-matnr
        AND werks = lt_eord_keys-werks
        AND flifn = 'X'. " 固定货源标识
  ENDIF.

  LOOP AT lt_req ASSIGNING <fs_req> WHERE feskz <> 'N'."物料工厂对应单一供应商，需根据现有的货源数据来判断是否填入 固定货源参数
    READ TABLE lt_eord_data INTO ls_eord WITH TABLE KEY matnr = <fs_req>-matnr
                                                        werks = <fs_req>-werks.
    IF sy-subrc = 0.
      <fs_req>-feskz = 'N'.
    ELSE.
      <fs_req>-feskz = 'Y'."如果目前物料工厂不存在固定货源，则维护固定货源
    ENDIF.
  ENDLOOP.
**

  CLEAR:ls_inputitems.
  CLEAR:ls_req.
  LOOP AT lt_req INTO ls_req.
    CLEAR ls_item.
    LOOP AT ls_inputheader-items INTO ls_inputitems WHERE lifnr = ls_req-lifnr
                                                     AND  matnr = ls_req-matnr
                                                     AND  i_ekorg = ls_req-i_ekorg
                                                     AND  werks = ls_req-werks.

      ls_item-i_ekgrp = ls_inputitems-i_ekgrp.
      ls_item-i_norbm = ls_inputitems-i_norbm.
      ls_item-i_aplfz = ls_inputitems-i_aplfz.
      ls_item-i_mwskz = ls_inputitems-i_mwskz.
      ls_item-i_bstae = ls_inputitems-i_bstae.
      ls_item-i_rdprf = ls_inputitems-i_rdprf.
      ls_item-i_netpr = ls_inputitems-i_netpr.
      ls_item-i_peinh = ls_inputitems-i_peinh.
      ls_item-i_waers = ls_inputitems-i_waers.
      ls_item-i_datab = ls_inputitems-i_datab.
      ls_item-i_datbi = ls_inputitems-i_datbi.
      ls_item-i_kstbm1 = ls_inputitems-i_kstbm1.
      ls_item-i_netpr1 = ls_inputitems-i_netpr1.
      ls_item-i_kstbm2 = ls_inputitems-i_kstbm2.
      ls_item-i_netpr2 = ls_inputitems-i_netpr2.
      ls_item-i_kstbm3 = ls_inputitems-i_kstbm3.
      ls_item-i_netpr3 = ls_inputitems-i_netpr3.
      ls_item-zflag    = ls_inputitems-zflag.
      ls_item-zstep    = ls_inputitems-zstep.
      ls_item-i_norbm = ls_inputitems-i_norbm."标准数量
      ls_item-i_mwskz = ls_inputitems-i_mwskz."税码
      ls_item-i_ekgrp = ls_inputitems-i_ekgrp."采购组
      APPEND ls_item TO lt_item.
    ENDLOOP.
    ls_req-item[] = lt_item[].
    CLEAR lt_item[].
    MODIFY lt_req FROM ls_req.
  ENDLOOP.

  IF lt_req[] IS NOT INITIAL.
    SELECT *
    FROM ztmm_mat_cof3
    INTO CORRESPONDING FIELDS OF TABLE lt_ztmm_mat_cof3
    FOR ALL ENTRIES IN lt_req
    WHERE werks = lt_req-werks.

    CLEAR:ls_req.
    LOOP AT lt_req INTO ls_req WHERE lifnr = ''.
      LOOP AT lt_ztmm_mat_cof3 INTO ls_ztmm_mat_cof3 WHERE werks = ls_req-werks.
        MOVE-CORRESPONDING:ls_req TO ls_req_cof3.
        ls_req_cof3-lifnr = ls_ztmm_mat_cof3-lifnr.
        APPEND ls_req_cof3 TO lt_req_cof3.
      ENDLOOP.
    ENDLOOP.

    DELETE lt_req WHERE lifnr = ''.
    APPEND LINES OF lt_req_cof3 TO lt_req.

  ENDIF.
*******************************开始创建或者修改*********************************************************
  CLEAR:lt_item_res.
  LOOP AT lt_req ASSIGNING FIELD-SYMBOL(<ls_item>).
    CLEAR:ls_item_res.
    IF <ls_item>-lifnr IS INITIAL.
      ls_item_res-status = 'E'.
      ls_item_res-recode = '500'.
      ls_item_res-message = '供应商值为空，请检查！'.
      ls_item_res-matnr = |{ <ls_item>-matnr ALPHA = OUT }|.
      ls_item_res-lifnr = |{ <ls_item>-lifnr ALPHA = OUT }|.
      ls_item_res-werks = |{ <ls_item>-werks ALPHA = OUT }|.
      ls_item_res-normb = |{ <ls_item>-normb ALPHA = OUT }|.
      APPEND ls_item_res TO lt_item_res.
      CONTINUE.
    ELSE.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = <ls_item>-lifnr
        IMPORTING
          output = <ls_item>-lifnr.
    ENDIF.

    IF <ls_item>-matnr IS INITIAL.
      ls_item_res-status = 'E'.
      ls_item_res-recode = '500'.
      ls_item_res-message = '物料不能为空！'.
      ls_item_res-matnr = |{ <ls_item>-matnr ALPHA = OUT }|.
      ls_item_res-lifnr = |{ <ls_item>-lifnr ALPHA = OUT }|.
      ls_item_res-werks = |{ <ls_item>-werks ALPHA = OUT }|.
      ls_item_res-normb = |{ <ls_item>-normb ALPHA = OUT }|.
      APPEND ls_item_res TO lt_item_res.
      CONTINUE.
    ELSE.
*      <ls_item>-matnr = |{ <ls_item>-matnr ALPHA = IN WIDTH = 18 }|.
    ENDIF.

    IF <ls_item>-zflag IS INITIAL.
      ls_item_res-status = 'E'.
      ls_item_res-recode = '500'.
      ls_item_res-message = '标识不能为空！'.
      ls_item_res-matnr = |{ <ls_item>-matnr ALPHA = OUT }|.
      ls_item_res-lifnr = |{ <ls_item>-lifnr ALPHA = OUT }|.
      ls_item_res-werks = |{ <ls_item>-werks ALPHA = OUT }|.
      ls_item_res-normb = |{ <ls_item>-normb ALPHA = OUT }|.
      APPEND ls_item_res TO lt_item_res.
      CONTINUE.
    ENDIF.

    IF <ls_item>-i_ekorg IS INITIAL.
      ls_item_res-status = 'E'.
      ls_item_res-recode = '500'.
      ls_item_res-message = '采购组织不能为空！'.
      ls_item_res-matnr = |{ <ls_item>-matnr ALPHA = OUT }|.
      ls_item_res-lifnr = |{ <ls_item>-lifnr ALPHA = OUT }|.
      ls_item_res-werks = |{ <ls_item>-werks ALPHA = OUT }|.
      ls_item_res-normb = |{ <ls_item>-normb ALPHA = OUT }|.
      APPEND ls_item_res TO lt_item_res.
      CONTINUE.
    ELSE.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = <ls_item>-i_ekorg
        IMPORTING
          output = <ls_item>-i_ekorg.
    ENDIF.

    IF <ls_item>-werks IS INITIAL.
      ls_item_res-status = 'E'.
      ls_item_res-recode = '500'.
      ls_item_res-message = '工厂不能为空！'.
      ls_item_res-matnr = |{ <ls_item>-matnr ALPHA = OUT }|.
      ls_item_res-lifnr = |{ <ls_item>-lifnr ALPHA = OUT }|.
      ls_item_res-werks = |{ <ls_item>-werks ALPHA = OUT }|.
      ls_item_res-normb = |{ <ls_item>-normb ALPHA = OUT }|.
      APPEND ls_item_res TO lt_item_res.
      CONTINUE.
    ELSE.
      <ls_item>-werks = |{ <ls_item>-werks ALPHA = IN WIDTH = 4 }|.
    ENDIF.

    IF <ls_item>-normb IS INITIAL.
      ls_item_res-status = 'E'.
      ls_item_res-recode = '500'.
      ls_item_res-message = '信息类别不能为空！'.
      ls_item_res-matnr = |{ <ls_item>-matnr ALPHA = OUT }|.
      ls_item_res-lifnr = |{ <ls_item>-lifnr ALPHA = OUT }|.
      ls_item_res-werks = |{ <ls_item>-werks ALPHA = OUT }|.
      ls_item_res-normb = |{ <ls_item>-normb ALPHA = OUT }|.
      APPEND ls_item_res TO lt_item_res.
      CONTINUE.
    ELSE.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = <ls_item>-normb
        IMPORTING
          output = <ls_item>-normb.
    ENDIF.

    IF <ls_item>-werks = 'A300' OR <ls_item>-werks = 'C100'.
*A300 C100查询配置表时不需要供应商号码
      SELECT SINGLE *
      FROM ztmm_pur_cof
      WHERE ekorg EQ @<ls_item>-i_ekorg
      AND werks EQ @<ls_item>-werks
      INTO @ls_ztmm_pur_cof.
    ELSE.
      SELECT SINGLE *
      FROM ztmm_pur_cof
      WHERE lifnr EQ @<ls_item>-lifnr
      AND ekorg EQ @<ls_item>-i_ekorg
      AND werks EQ @<ls_item>-werks
      INTO @ls_ztmm_pur_cof.
      IF sy-subrc <> 0."根据供应商号码没查到的话，用工厂进行查询
        SELECT SINGLE *
        FROM ztmm_pur_cof
        WHERE werks EQ @<ls_item>-werks
        INTO @ls_ztmm_pur_cof.
      ENDIF.

    ENDIF.

    SELECT SINGLE *
    FROM lfm1
    WHERE lifnr EQ @<ls_item>-lifnr
    AND ekorg EQ @<ls_item>-i_ekorg
    INTO @DATA(ls_lfm1).
*add by wangyang 20251211
    IF <ls_item>-zstep = '3'."采购组取配置表
      CLEAR:ls_ztmm_pur_cof_cn,lv_beskz.

      SELECT SINGLE *
       FROM lfa1
       WHERE lifnr EQ @<ls_item>-lifnr
       INTO @DATA(ls_lfa1).

      IF ls_lfa1-werks IS NOT INITIAL.

        CLEAR:lv_matnr.
        lv_matnr = |{ <ls_item>-matnr ALPHA = IN WIDTH = 18 }|.

        SELECT SINGLE *
         FROM marc
         WHERE matnr EQ @lv_matnr
           AND werks EQ @ls_lfa1-werks"取供应商对应的工厂（制造工厂）
          INTO @DATA(ls_marc).
        IF sy-subrc = 0.
          IF ls_marc-beskz = '' OR ls_marc-beskz = 'E'.
            lv_beskz = 'E'.
          ELSEIF ls_marc-beskz = 'F'.
            lv_beskz = 'F'.
          ENDIF.

          SELECT SINGLE *
          FROM ztmm_pur_cof_cn
          WHERE lifnr EQ @<ls_item>-lifnr
            AND ekorg EQ @<ls_item>-i_ekorg
            AND werks EQ @<ls_item>-werks
            AND beskz EQ @lv_beskz
           INTO @ls_ztmm_pur_cof_cn.
        ENDIF.



      ELSE.
        SELECT SINGLE *
        FROM ztmm_pur_cof_cn
        WHERE lifnr EQ @<ls_item>-lifnr
          AND ekorg EQ @<ls_item>-i_ekorg
          AND werks EQ @<ls_item>-werks
          AND beskz EQ 'E'
         INTO @ls_ztmm_pur_cof_cn.
      ENDIF.

**add by wangyang 20260202
      CLEAR:lv_matnr.
      lv_matnr = |{ <ls_item>-matnr ALPHA = IN WIDTH = 18 }|.
      SELECT SINGLE
        eina~infnr,
        eina~lifnr,
        eine~ekorg,
        eine~werks
      FROM eina
      LEFT JOIN eine ON eina~infnr = eine~infnr
      WHERE eina~lifnr EQ @<ls_item>-lifnr
      AND eine~ekorg EQ @<ls_item>-i_ekorg
      AND eine~werks EQ @<ls_item>-werks
      AND eina~matnr EQ @lv_matnr
      AND eine~esokz EQ '0'"PI01只创建标准类型
      INTO @DATA(ls_eine_pi01).

      IF ls_eine_pi01 IS NOT INITIAL."根据是否存在信息记录，变更操作标识
        <ls_item>-zflag = 'U'.
        <ls_item>-infnr = ls_eine_pi01-infnr.
      ELSE.
        <ls_item>-zflag = 'C'.
      ENDIF.
      LOOP AT <ls_item>-item ASSIGNING FIELD-SYMBOL(<fs_items_pi01>).
        <fs_items_pi01>-zflag = <ls_item>-zflag.
        <fs_items_pi01>-i_ekgrp = ls_ztmm_pur_cof_cn-ekgrp."后添加，防止修改时查不到采购组。下方新建逻辑中，也有赋值采购组的逻辑
      ENDLOOP.
      LOOP AT lt_zpds_eine_text ASSIGNING FIELD-SYMBOL(<fs_zpds_eine_text>) WHERE matnr = lv_matnr
                                                                               AND lifnr = <ls_item>-lifnr
                                                                               AND ekorg = <ls_item>-i_ekorg
                                                                               AND werks = <ls_item>-werks.
        <fs_zpds_eine_text>-infnr = ls_eine_pi01-infnr.
      ENDLOOP.

    ENDIF.
    "------------------------------------------新增 create----------------------------------------------
    IF <ls_item>-zflag EQ 'C'.
      CLEAR:lv_matnr.
      lv_matnr = |{ <ls_item>-matnr ALPHA = IN WIDTH = 18 }|.
      "校验是否存在，存在的话则不去新建
      SELECT SINGLE
        eina~infnr,
        eina~lifnr,
        eine~ekorg,
        eine~werks
      FROM eina
      LEFT JOIN eine ON eina~infnr = eine~infnr
      WHERE eina~lifnr EQ @<ls_item>-lifnr
      AND eine~ekorg EQ @<ls_item>-i_ekorg
      AND eine~werks EQ @<ls_item>-werks
      AND eina~matnr EQ @lv_matnr
      AND eine~esokz EQ '0'
      INTO @DATA(ls_eine).
      IF ls_eine IS NOT INITIAL.
        ls_item_res-status = 'E'.
        ls_item_res-recode = '500'.
        ls_item_res-message = '采购信息记录已存在,请检查'.
      ENDIF.
      CASE <ls_item>-normb. "信息类别
        WHEN '0'.
          lv_esokz = 'RM06I-NORMB'. "标准
        WHEN '3'.
          lv_esokz = 'RM06I-LOHNB'. "外协加工 分包
        WHEN 'P'.
          lv_esokz = 'RM06I-PIPEL'. "管道
        WHEN '2'.
          lv_esokz = 'RM06I-KONSI'. "寄售
      ENDCASE.

      "Enter
      CLEAR:lt_bdc[].
      PERFORM bdc_screen TABLES lt_bdc USING 'SAPMM06I' '0100'.
      PERFORM bdc_field  TABLES lt_bdc:
        USING 'BDC_OKCODE' '/00',
        USING 'EINA-LIFNR' <ls_item>-lifnr,  "供应商
        USING 'EINA-MATNR' <ls_item>-matnr,  "物料
        USING 'EINE-EKORG' <ls_item>-i_ekorg,  "采购组织
        USING 'EINE-WERKS' <ls_item>-werks,  "工厂
        USING 'EINA-INFNR' '',  "采购信息记录
        USING lv_esokz  '',
        USING lv_esokz      'X'.      "信息类别：标准

      LOOP AT <ls_item>-item INTO ls_item.

*        IF ls_item-i_norbm IS INITIAL.
*          ls_item-i_norbm = '1'.
*        ENDIF.
*        IF ls_item-i_mwskz IS INITIAL.
*          ls_item-i_mwskz = 'JB'.
*        ENDIF.
        IF ls_item-i_peinh IS INITIAL.
          ls_item-i_peinh = '1'.
        ENDIF.
*        IF ls_item-i_waers IS INITIAL.
*          ls_item-i_waers = 'RMB'.
*        ENDIF.
        "   ls_item-i_waers = ls_lfm1-waers.
        IF ls_item-i_datab IS INITIAL.
          ls_item-i_datab = sy-datum.
        ENDIF.

        IF ls_item-i_datbi IS INITIAL.
          ls_item-i_datbi = '99991231'.
        ENDIF.

        "zstep = 1:栏位全部取自传入参数；zstep = 3:采购组取配置表，其余取自传入参数；ztep = 2:部分栏位取配置表

        CASE ls_item-zstep.
          WHEN '1'.
          WHEN '3'.
            ls_item-i_ekgrp = ls_ztmm_pur_cof_cn-ekgrp."采购组
          WHEN OTHERS.
            ls_item-i_norbm = ls_ztmm_pur_cof-norbm."标准数量
            ls_item-i_mwskz = ls_ztmm_pur_cof-mwskz."税码
            ls_item-i_ekgrp = ls_ztmm_pur_cof-ekgrp."采购组
            ls_item-i_bstae = ls_ztmm_pur_cof-bstae."确认控制代码
            ls_item-i_rdprf = ls_ztmm_pur_cof-rdprf."舍入参数文件
        ENDCASE.

        PERFORM bdc_screen TABLES lt_bdc      USING 'SAPMM06I' '0101'.
        PERFORM bdc_field  TABLES lt_bdc:      USING 'BDC_OKCODE' '=EINE'.
        PERFORM bdc_screen TABLES lt_bdc      USING 'SAPMM06I' '0102'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_OKCODE'  '=KO'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'EINE-APLFZ' ls_item-i_aplfz.  "计划交货日期
        PERFORM bdc_field  TABLES lt_bdc:       USING 'EINE-EKGRP' ls_item-i_ekgrp.  "采购组
        PERFORM bdc_field  TABLES lt_bdc:       USING 'EINE-NORBM' ls_item-i_norbm. "标准数量
        PERFORM bdc_field  TABLES lt_bdc:       USING 'EINE-MWSKZ' ls_item-i_mwskz.  "税代码
        PERFORM bdc_field  TABLES lt_bdc:       USING 'EINE-NETPR' ls_item-i_netpr.  "净价
        PERFORM bdc_field  TABLES lt_bdc:       USING 'EINE-WAERS' ls_item-i_waers.  "货币码
        PERFORM bdc_field  TABLES lt_bdc:       USING 'EINE-PEINH' ls_item-i_peinh.  "价格单位
        PERFORM bdc_field  TABLES lt_bdc:       USING 'EINE-BSTAE' ls_item-i_bstae.  "确认控制代码
        PERFORM bdc_field  TABLES lt_bdc:       USING 'EINE-RDPRF' ls_item-i_rdprf. "舍入参数文件

        PERFORM bdc_screen TABLES lt_bdc      USING 'SAPMV13A' '0201'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_CURSOR' 'RV13A-DATAB'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_OKCODE' '=PSTF'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'RV13A-DATAB' ls_item-i_datab.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'RV13A-DATBI' ls_item-i_datbi.

        PERFORM bdc_field  TABLES lt_bdc:       USING 'RV130-SELKZ(01)' 'X'.
        PERFORM bdc_screen TABLES lt_bdc      USING 'SAPMV13A' '0303'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_CURSOR' 'KONM-KBETR(03)'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_OKCODE' '=SICH'.
        IF ls_item-i_kstbm1 IS NOT INITIAL.
          PERFORM bdc_field  TABLES lt_bdc:       USING 'KONM-KSTBM(01)' '1'. "等级数量1
          PERFORM bdc_field  TABLES lt_bdc:       USING 'KONM-KBETR(01)' ls_item-i_netpr.  "净价
          PERFORM bdc_field  TABLES lt_bdc:       USING 'KONM-KSTBM(02)' ls_item-i_kstbm1. "等级数量1
          PERFORM bdc_field  TABLES lt_bdc:       USING 'KONM-KBETR(02)' ls_item-i_netpr1.
          PERFORM bdc_field  TABLES lt_bdc:       USING 'KONM-KSTBM(03)' ls_item-i_kstbm2.
          PERFORM bdc_field  TABLES lt_bdc:       USING 'KONM-KBETR(03)' ls_item-i_netpr2.
          PERFORM bdc_field  TABLES lt_bdc:       USING 'KONM-KSTBM(04)' ls_item-i_kstbm3.
          PERFORM bdc_field  TABLES lt_bdc:       USING 'KONM-KBETR(04)' ls_item-i_netpr3.
        ELSE.
          IF ls_item-i_kstbm1 IS NOT INITIAL.
            PERFORM bdc_field  TABLES lt_bdc:       USING 'KONM-KSTBM(01)' ls_item-i_kstbm1. "等级数量1
            PERFORM bdc_field  TABLES lt_bdc:       USING 'KONM-KBETR(01)' ls_item-i_netpr1.
          ENDIF.
          IF ls_item-i_kstbm2 IS NOT INITIAL.
            PERFORM bdc_field  TABLES lt_bdc:       USING 'KONM-KSTBM(02)' ls_item-i_kstbm2.
            PERFORM bdc_field  TABLES lt_bdc:       USING 'KONM-KBETR(02)' ls_item-i_netpr2.
          ENDIF.
          IF ls_item-i_kstbm3 IS NOT INITIAL.
            PERFORM bdc_field  TABLES lt_bdc:       USING 'KONM-KSTBM(03)' ls_item-i_kstbm3.
            PERFORM bdc_field  TABLES lt_bdc:       USING 'KONM-KBETR(03)' ls_item-i_netpr3.
          ENDIF.
        ENDIF.

      ENDLOOP.

      CALL TRANSACTION 'ME11' USING lt_bdc[]
                              MODE  lv_mode
                              UPDATE 'S'
                              MESSAGES INTO lt_mess.

      READ TABLE lt_mess INTO DATA(ls_mess) WITH KEY msgtyp = 'S'
                                  msgid  = '06'
                                  msgnr  = '331'.
      IF sy-subrc = 0.
        ls_item_res-status = 'S'.
        ls_item_res-recode = '200'.
        ls_item_res-infnr = ls_mess-msgv1.
        ls_item_res-message = '创建采购信息记录成功！'.
***创建成功时将备注以及采购信息记录号写入自建表
        IF <ls_item>-zstep <> '2'.
          CLEAR:ls_zpds_eine_text,lt_zpds_eine_text_single[].
          READ TABLE lt_zpds_eine_text INTO ls_zpds_eine_text WITH KEY matnr = lv_matnr
                                                                       lifnr = <ls_item>-lifnr
                                                                       ekorg = <ls_item>-i_ekorg
                                                                       werks = <ls_item>-werks.
          IF sy-subrc = 0.
            ls_zpds_eine_text-infnr = ls_item_res-infnr.
            APPEND ls_zpds_eine_text TO lt_zpds_eine_text_single.
            MODIFY zpds_eine_text FROM TABLE lt_zpds_eine_text_single.
            IF sy-subrc = 0.
              COMMIT WORK.
              ls_item_res-message = ls_item_res-message && '价格及备注写入自建表成功！'.
            ELSE.
              ROLLBACK WORK.
              ls_item_res-message = ls_item_res-message && '价格及备注写入自建表失败！'.
            ENDIF.
          ELSE.
            ls_item_res-message = ls_item_res-message && '价格及备注写入自建表失败！'.
          ENDIF.
        ENDIF.
***创建采购信息记录的时候，创建货源
        CLEAR:lt_bdc[],ls_item,lt_mess[].
        READ TABLE <ls_item>-item INTO ls_item INDEX 1.

        PERFORM bdc_screen TABLES lt_bdc      USING 'SAPLMEOR' '0200'.
        PERFORM bdc_field  TABLES lt_bdc:      USING 'BDC_CURSOR' 'EORD-MATNR'.
        PERFORM bdc_field  TABLES lt_bdc:      USING 'BDC_OKCODE'  '/00'.
        PERFORM bdc_field  TABLES lt_bdc:      USING 'EORD-MATNR' <ls_item>-matnr.
        PERFORM bdc_field  TABLES lt_bdc:      USING 'EORD-WERKS' <ls_item>-werks.
        PERFORM bdc_screen TABLES lt_bdc      USING 'SAPLMEOR' '0205'.
        PERFORM bdc_field  TABLES lt_bdc:      USING 'EORD-VDATU(01)'  ls_item-i_datab."有效从
        PERFORM bdc_field  TABLES lt_bdc:      USING 'EORD-BDATU(01)'  ls_item-i_datbi."有效至
        PERFORM bdc_field  TABLES lt_bdc:      USING 'EORD-LIFNR(01)'  <ls_item>-lifnr.
        PERFORM bdc_field  TABLES lt_bdc:      USING 'EORD-EKORG(01)'  <ls_item>-i_ekorg.
        IF <ls_item>-feskz = 'Y'.
          PERFORM bdc_field  TABLES lt_bdc:      USING 'RM06W-FESKZ(01)'  'X'."固定货源
        ENDIF.
        PERFORM bdc_field  TABLES lt_bdc:      USING 'BDC_OKCODE'  '=BU'.
        CALL TRANSACTION 'ME01' USING lt_bdc[]
                              MODE  lv_mode
                              UPDATE 'S'
                              MESSAGES INTO lt_mess.
        READ TABLE lt_mess INTO ls_mess WITH KEY msgtyp = 'S'
                                    msgid  = '06'
                                    msgnr  = '790'.
        IF sy-subrc = 0.
          ls_item_res-message = ls_item_res-message && '，创建货源清单成功！'.
        ELSE.
          CLEAR:lv_message.
          READ TABLE lt_mess WITH KEY msgtyp = 'E'.
          CALL FUNCTION 'FORMAT_MESSAGE'
            EXPORTING
              id        = lt_mess-msgid
              no        = lt_mess-msgnr
              v1        = lt_mess-msgv1
              v2        = lt_mess-msgv2
              v3        = lt_mess-msgv3
              v4        = lt_mess-msgv4
            IMPORTING
              msg       = lv_message
            EXCEPTIONS
              not_found = 1
              OTHERS    = 2.

          ls_item_res-message = ls_item_res-message && '，创建货源清单失败：' && lv_message.

        ENDIF.
***根据I_BESKZ更新物料主数据采购类型/特殊采购类
        IF <ls_item>-i_beskz IS NOT INITIAL.
          CLEAR: lv_beskz_val, lv_sobsl_val, ls_headdata_mm, ls_plantdata_mm, ls_plantdatax_mm, lt_bapi_ret[].
          SPLIT <ls_item>-i_beskz AT '-' INTO lv_beskz_val lv_sobsl_val.
          ls_headdata_mm-material    = lv_matnr.
          ls_plantdata_mm-plant      = <ls_item>-werks.
          ls_plantdata_mm-proc_type  = lv_beskz_val.
          ls_plantdatax_mm-plant     = <ls_item>-werks.
          ls_plantdatax_mm-proc_type = 'X'.
          IF lv_sobsl_val IS NOT INITIAL.
            ls_plantdata_mm-spproctype  = lv_sobsl_val.
            ls_plantdatax_mm-spproctype = 'X'.
          ENDIF.
          CALL FUNCTION 'BAPI_MATERIAL_SAVEDATA'
            EXPORTING
              headdata       = ls_headdata_mm
              plantdata      = ls_plantdata_mm
              plantdatax     = ls_plantdatax_mm
            TABLES
              returnmessages = lt_bapi_ret.
          READ TABLE lt_bapi_ret INTO ls_bapi_ret WITH KEY type = 'E'.
          IF sy-subrc <> 0.
            CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
              EXPORTING
                wait = 'X'.
            ls_item_res-message = ls_item_res-message && '，更新物料采购类型成功！'.
          ELSE.
            CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
            ls_item_res-message = ls_item_res-message && '，更新物料采购类型失败：' && ls_bapi_ret-message.
          ENDIF.
        ENDIF.
***end
      ELSE.
        ls_item_res-status = 'E'.
        ls_item_res-recode = '500'.
        READ TABLE lt_mess WITH KEY msgtyp = 'E'.
        CALL FUNCTION 'FORMAT_MESSAGE'
          EXPORTING
            id        = lt_mess-msgid
            no        = lt_mess-msgnr
            v1        = lt_mess-msgv1
            v2        = lt_mess-msgv2
            v3        = lt_mess-msgv3
            v4        = lt_mess-msgv4
          IMPORTING
            msg       = lv_message
          EXCEPTIONS
            not_found = 1
            OTHERS    = 2.
        IF ls_item_res-message IS INITIAL.
          ls_item_res-message = '创建采购信息记录失败:' && lv_message.
        ENDIF.
      ENDIF.
    ENDIF.

    "-----------------------------------------------------------------修改 update---------------------------------------------------------------------
    IF <ls_item>-zflag EQ 'U'.

      "校验是否存在，存在的话则不去新建
      SELECT SINGLE
        eina~infnr,
        eina~lifnr,
        eine~ekorg,
        eine~werks
      FROM eina
      LEFT JOIN eine ON eina~infnr = eine~infnr
      WHERE eina~infnr EQ @<ls_item>-infnr
*      AND eina~lifnr EQ @<ls_item>-lifnr
*      AND eine~ekorg EQ @<ls_item>-i_ekorg
*      AND eine~werks EQ @<ls_item>-werks
*      AND eina~matnr EQ @<ls_item>-matnr
*      AND eine~esokz EQ @<ls_item>-normb
      INTO @ls_eine.
      IF ls_eine IS INITIAL.
        ls_item_res-status = 'E'.
        ls_item_res-recode = '500'.
        ls_item_res-message = '采购信息记录不存在,请检查'.
        APPEND ls_item_res TO lt_item_res.
        CONTINUE.
      ENDIF.

*      SELECT SINGLE  *
*      FROM a017
*      WHERE kschl EQ 'PB00'
*      AND kappl EQ 'M'
*      AND lifnr EQ @<ls_item>-lifnr
*      AND matnr EQ @<ls_item>-matnr
*      AND ekorg EQ @<ls_item>-i_ekorg
*      AND werks EQ @<ls_item>-werks
**      AND datab EQ @ls_item-i_datab
**      AND datab EQ @ls_item-i_datbi
*      INTO  @DATA(ls_a017).

      DATA: lt_add    TYPE TABLE OF ty_item,
            lt_update TYPE TABLE OF ty_item.
      CLEAR:lt_add,lt_update.
      LOOP AT <ls_item>-item INTO ls_item.
        IF ls_item-zflag EQ 'C'.
          APPEND ls_item TO lt_add.
        ENDIF.
        IF ls_item-zflag EQ 'U'.
          APPEND ls_item TO lt_update.
        ENDIF.
      ENDLOOP.

*      SELECT SINGLE * FROM konp WHERE knumh = @ls_a017-knumh INTO @DATA(ls_konp).
**      "ls_konp-LOEVM_KO
**      ls_item_res-message = '修改采购信息记录失败'.

      LOOP AT lt_update INTO ls_item.
        CLEAR:lt_bdc[],lt_mess.

        CASE <ls_item>-normb. "信息类别
          WHEN '0'.
            lv_esokz = 'RM06I-NORMB'. "标准
          WHEN '3'.
            lv_esokz = 'RM06I-LOHNB'. "外协加工 分包
          WHEN 'P'.
            lv_esokz = 'RM06I-PIPEL'. "管道
          WHEN '2'.
            lv_esokz = 'RM06I-KONSI'. "寄售
        ENDCASE.

        CLEAR:lv_matnr.
        lv_matnr = |{ <ls_item>-matnr ALPHA = OUT }|.
        "Enter
        PERFORM bdc_screen TABLES lt_bdc
          USING 'SAPMM06I' '0100'.
        PERFORM bdc_field  TABLES lt_bdc:
          USING 'BDC_OKCODE' '/00',
          USING 'EINA-LIFNR' <ls_item>-lifnr,  "供应商
          USING 'EINA-MATNR' lv_matnr,  "物料
          USING 'EINE-EKORG' <ls_item>-i_ekorg,  "采购组织
          USING 'EINE-WERKS' <ls_item>-werks,  "工厂
          USING 'EINA-INFNR' <ls_item>-infnr,  "采购信息记录
          USING lv_esokz      'X'.      "信息类别：标准

        SELECT SINGLE * FROM eine
        WHERE infnr = @ls_eine-infnr
        AND ekorg = @<ls_item>-i_ekorg
        AND werks = @<ls_item>-werks
        INTO @DATA(ls_eineget).
        IF ls_item-i_aplfz IS NOT INITIAL.
          ls_eineget-aplfz = ls_item-i_aplfz.
        ENDIF.
        IF ls_item-i_ekgrp IS NOT INITIAL.
          ls_eineget-ekgrp  = ls_item-i_ekgrp.
        ENDIF.
        IF ls_item-i_norbm IS NOT INITIAL.
          ls_eineget-norbm  = ls_item-i_norbm.
        ENDIF.
        IF ls_item-i_mwskz IS NOT INITIAL.
          ls_eineget-mwskz  = ls_item-i_mwskz.
        ENDIF.
        IF ls_item-i_netpr IS NOT INITIAL.
          ls_eineget-netpr  = ls_item-i_netpr.
        ENDIF.
        IF ls_item-i_waers IS NOT INITIAL.
          ls_eineget-waers  = ls_item-i_waers.
        ENDIF.
        IF ls_item-i_peinh IS NOT INITIAL.
          ls_eineget-peinh  = ls_item-i_peinh.
        ENDIF.
        IF ls_item-i_bstae IS NOT INITIAL.
          ls_eineget-bstae  = ls_item-i_bstae.
        ENDIF.
        IF ls_item-i_datab IS INITIAL.
          ls_item-i_datab = sy-datum."取当前日期
        ENDIF.
        PERFORM bdc_screen TABLES lt_bdc      USING 'SAPMM06I' '0101'.
        PERFORM bdc_field  TABLES lt_bdc:      USING 'BDC_OKCODE' '=EINE'.
        PERFORM bdc_screen TABLES lt_bdc      USING 'SAPMM06I' '0102'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_OKCODE'  '=KO'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'EINE-APLFZ' ls_eineget-aplfz.  "计划交货日期
        PERFORM bdc_field  TABLES lt_bdc:       USING 'EINE-EKGRP' ls_eineget-ekgrp.  "采购组
        PERFORM bdc_field  TABLES lt_bdc:       USING 'EINE-NORBM' ls_eineget-norbm. "标准数量
        PERFORM bdc_field  TABLES lt_bdc:       USING 'EINE-MWSKZ' ls_eineget-mwskz.  "税代码
        PERFORM bdc_field  TABLES lt_bdc:       USING 'EINE-BSTAE' ls_eineget-bstae.  "确认控制代码
        PERFORM bdc_field  TABLES lt_bdc:       USING 'EINE-BSTAE' ls_item-i_bstae.  "确认控制代码
        PERFORM bdc_field  TABLES lt_bdc:       USING 'EINE-RDPRF' ls_item-i_rdprf. "舍入参数文件

        PERFORM bdc_screen TABLES lt_bdc      USING 'SAPLV14A' '0102'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_CURSOR' 'VAKE-DATAB(01)'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_OKCODE' '=NEWD'.

        PERFORM bdc_screen TABLES lt_bdc      USING 'SAPMV13A' '0201'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_CURSOR' 'KONP-KBETR(01)'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_OKCODE'  '/00'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'RV13A-DATAB'  ls_item-i_datab.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'RV13A-DATBI'  ls_item-i_datbi.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'KONP-KBETR(01)' ls_item-i_netpr.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'KONP-KONWA(01)' ls_item-i_waers.
        IF ls_item-i_peinh IS NOT INITIAL.
          PERFORM bdc_field  TABLES lt_bdc:       USING 'KONP-KPEIN(01)' ls_item-i_peinh."条件定价单位
        ENDIF.
*        PERFORM bdc_field  TABLES lt_bdc:       USING 'KONP-KMEIN(01)' ls_item-i_kmein."条件单位

        PERFORM bdc_screen TABLES lt_bdc      USING 'SAPMV13A' '0201'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_CURSOR' 'KONP-KBETR(01)'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_OKCODE' '=SICH'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'RV13A-DATAB' ls_item-i_datab.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'RV13A-DATBI' ls_item-i_datbi.
        PERFORM bdc_screen TABLES lt_bdc      USING 'SAPMV13A' '0303'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_CURSOR' 'KONM-KBETR(03)'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_OKCODE' '=SICH'.
        IF ls_item-i_kstbm1 IS NOT INITIAL.
          PERFORM bdc_field  TABLES lt_bdc:     USING 'KONM-KSTBM(01)' ls_item-i_kstbm1. "等级数量1
        ENDIF.
        IF ls_item-i_kstbm2 IS NOT INITIAL.
          PERFORM bdc_field  TABLES lt_bdc:     USING 'KONM-KSTBM(02)' ls_item-i_kstbm2.
          PERFORM bdc_field  TABLES lt_bdc:     USING 'KONM-KBETR(02)' ls_item-i_netpr2.
        ENDIF.
        IF ls_item-i_kstbm3 IS NOT INITIAL.
          PERFORM bdc_field  TABLES lt_bdc:     USING 'KONM-KSTBM(03)' ls_item-i_kstbm3.
          PERFORM bdc_field  TABLES lt_bdc:     USING 'KONM-KBETR(03)' ls_item-i_netpr3.
        ENDIF.

        CALL TRANSACTION 'ME12' USING lt_bdc[]
                                MODE  lv_mode
                                UPDATE 'S'
                                MESSAGES INTO lt_mess.

        READ TABLE lt_mess INTO ls_mess WITH KEY msgtyp = 'S'
                                    msgid  = '06'
                                    msgnr  = '335'.
        IF sy-subrc = 0.
          ls_item_res-status = 'S'.
          ls_item_res-recode = '200'.
*        fs-i_infnr = ls_mess-msgv1.
          ls_item_res-message = '修改采购信息记录成功！'.
***修改成功时将备注以及采购信息记录号写入自建表
          IF <ls_item>-zstep <> '2'.
            CLEAR:ls_zpds_eine_text,lt_zpds_eine_text_single[].

            <ls_item>-matnr = |{ <ls_item>-matnr ALPHA = IN }|.
            <ls_item>-lifnr = |{ <ls_item>-lifnr ALPHA = IN }|.
            READ TABLE lt_zpds_eine_text INTO ls_zpds_eine_text WITH KEY matnr = <ls_item>-matnr
                                                                         lifnr = <ls_item>-lifnr
                                                                         ekorg = <ls_item>-i_ekorg
                                                                         werks = <ls_item>-werks
                                                                         infnr = <ls_item>-infnr.
            IF sy-subrc = 0.
              APPEND ls_zpds_eine_text TO lt_zpds_eine_text_single.
              MODIFY zpds_eine_text FROM TABLE lt_zpds_eine_text_single.
              IF sy-subrc = 0.
                COMMIT WORK.
                ls_item_res-message = ls_item_res-message && '价格及备注写入自建表成功！'.
              ELSE.
                ROLLBACK WORK.
                ls_item_res-message = ls_item_res-message && '价格及备注写入自建表失败！'.
              ENDIF.
            ELSE.
              ls_item_res-message = ls_item_res-message && '价格及备注写入自建表失败！'.
            ENDIF.
          ENDIF.
***修改采购信息记录的时候，根据价格有效期修改货源有效期
          CLEAR:lt_bdc[],ls_item,lt_mess[].
          READ TABLE <ls_item>-item INTO ls_item INDEX 1.

          PERFORM bdc_screen TABLES lt_bdc      USING 'SAPLMEOR' '0200'.
          PERFORM bdc_field  TABLES lt_bdc:      USING 'BDC_CURSOR' 'EORD-MATNR'.
          PERFORM bdc_field  TABLES lt_bdc:      USING 'BDC_OKCODE'  '/00'.
          PERFORM bdc_field  TABLES lt_bdc:      USING 'EORD-MATNR' lv_matnr.
          PERFORM bdc_field  TABLES lt_bdc:      USING 'EORD-WERKS' <ls_item>-werks.
          PERFORM bdc_screen TABLES lt_bdc      USING 'SAPLMEOR' '0205'.
          PERFORM bdc_field  TABLES lt_bdc:      USING 'EORD-VDATU(01)'  ls_item-i_datab."有效从
          PERFORM bdc_field  TABLES lt_bdc:      USING 'EORD-BDATU(01)'  ls_item-i_datbi."有效至
          PERFORM bdc_field  TABLES lt_bdc:      USING 'EORD-LIFNR(01)'  <ls_item>-lifnr.
          PERFORM bdc_field  TABLES lt_bdc:      USING 'EORD-EKORG(01)'  <ls_item>-i_ekorg.
          IF <ls_item>-feskz = 'Y'.
            PERFORM bdc_field  TABLES lt_bdc:    USING 'RM06W-FESKZ(01)'  'X'."固定货源
          ENDIF.
          PERFORM bdc_field  TABLES lt_bdc:      USING 'BDC_OKCODE'  '=BU'.
          CALL TRANSACTION 'ME01' USING lt_bdc[]
                                MODE  lv_mode
                                UPDATE 'S'
                                MESSAGES INTO lt_mess.
          READ TABLE lt_mess INTO ls_mess WITH KEY msgtyp = 'S'
                                      msgid  = '06'
                                      msgnr  = '790'.
          IF sy-subrc = 0.
            ls_item_res-message = ls_item_res-message && '，修改货源清单成功！'.
          ELSE.
            CLEAR:lv_message.
            READ TABLE lt_mess WITH KEY msgtyp = 'E'.
            CALL FUNCTION 'FORMAT_MESSAGE'
              EXPORTING
                id        = lt_mess-msgid
                no        = lt_mess-msgnr
                v1        = lt_mess-msgv1
                v2        = lt_mess-msgv2
                v3        = lt_mess-msgv3
                v4        = lt_mess-msgv4
              IMPORTING
                msg       = lv_message
              EXCEPTIONS
                not_found = 1
                OTHERS    = 2.

            ls_item_res-message = ls_item_res-message && '，创建货源清单失败：' && lv_message.

          ENDIF.
***end
        ELSE.
          ls_item_res-status = 'E'.
          ls_item_res-recode = '500'.
          ls_item_res-message = '修改采购信息记录失败：'.
          READ TABLE lt_mess WITH KEY msgtyp = 'E'.
          CALL FUNCTION 'FORMAT_MESSAGE'
            EXPORTING
              id        = lt_mess-msgid
              no        = lt_mess-msgnr
              v1        = lt_mess-msgv1
              v2        = lt_mess-msgv2
              v3        = lt_mess-msgv3
              v4        = lt_mess-msgv4
            IMPORTING
              msg       = lv_message
            EXCEPTIONS
              not_found = 1
              OTHERS    = 2.

          ls_item_res-message = ls_item_res-message && lv_message.

        ENDIF.
      ENDLOOP.

*这段逻辑不一定执行
      LOOP AT lt_add INTO ls_item.
        CLEAR:lt_bdc[],lt_mess.
        CASE <ls_item>-normb. "信息类别
          WHEN '0'.
            lv_esokz = 'RM06I-NORMB'. "标准
          WHEN '1'.
            lv_esokz = 'RM06I-LOHNB'. "外协加工 分包
          WHEN '2'.
            lv_esokz = 'RM06I-PIPEL'. "管道
          WHEN '3'.
            lv_esokz = 'RM06I-KONSI'. "寄售
        ENDCASE.

        "Enter
        PERFORM bdc_screen TABLES lt_bdc
          USING 'SAPMM06I' '0100'.
        PERFORM bdc_field  TABLES lt_bdc:
          USING 'BDC_OKCODE' '/00',
          USING 'EINA-LIFNR' <ls_item>-lifnr,  "供应商
          USING 'EINA-MATNR' <ls_item>-matnr,  "物料
          USING 'EINE-EKORG' <ls_item>-i_ekorg,  "采购组织
          USING 'EINE-WERKS' <ls_item>-werks,  "工厂
          USING 'EINA-INFNR' ls_eine-infnr,  "采购信息记录
          USING lv_esokz      'X'.      "信息类别：标准

        PERFORM bdc_screen TABLES lt_bdc      USING 'SAPMM06I' '0101'.
        PERFORM bdc_field  TABLES lt_bdc:      USING 'BDC_OKCODE' '=EINE'.
        PERFORM bdc_screen TABLES lt_bdc      USING 'SAPMM06I' '0102'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_OKCODE'  '=KO'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'EINE-APLFZ' ls_item-i_aplfz.  "计划交货日期
        PERFORM bdc_field  TABLES lt_bdc:       USING 'EINE-EKGRP' ls_item-i_ekgrp.  "采购组
        PERFORM bdc_field  TABLES lt_bdc:       USING 'EINE-NORBM' ls_item-i_norbm. "标准数量
        PERFORM bdc_field  TABLES lt_bdc:       USING 'EINE-MWSKZ' ls_item-i_mwskz.  "税代码
        PERFORM bdc_field  TABLES lt_bdc:       USING 'EINE-BSTAE' ls_item-i_bstae.  "确认控制代码
        PERFORM bdc_field  TABLES lt_bdc:       USING 'EINE-BSTAE' ls_item-i_bstae.  "确认控制代码
        PERFORM bdc_field  TABLES lt_bdc:       USING 'EINE-RDPRF' ls_item-i_rdprf. "舍入参数文件

        PERFORM bdc_screen TABLES lt_bdc      USING 'SAPLV14A' '0102'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_CURSOR' 'VAKE-DATAB(01)'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_OKCODE' '=NEWD'.


        PERFORM bdc_screen TABLES lt_bdc      USING 'SAPMV13A' '0201'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_CURSOR' 'KONP-KSCHL(01)'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_OKCODE'  '=PSTF'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'RV13A-DATAB' ls_item-i_datab.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'RV13A-DATBI' ls_item-i_datbi.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'RV130-SELKZ(01)' 'X'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'KONP-KBETR(01)' ls_item-i_netpr.
        PERFORM bdc_screen TABLES lt_bdc      USING 'SAPMV13A' '0303'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_CURSOR' 'KONM-KBETR(03)'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_OKCODE' '=SICH'.
*perform bdc_field  tables lt_bdc:       using 'RV13A-DATAB' '2025-04-01'.
*perform bdc_field  tables lt_bdc:       using 'RV13A-DATBI' '2025-04-02'.

        IF ls_item-i_kstbm1 IS NOT INITIAL.
          PERFORM bdc_field  TABLES lt_bdc:       USING 'KONM-KSTBM(01)' ls_item-i_kstbm1. "等级数量1
        ENDIF.
        IF ls_item-i_kstbm2 IS NOT INITIAL.
          PERFORM bdc_field  TABLES lt_bdc:       USING 'KONM-KSTBM(02)' ls_item-i_kstbm2.
          PERFORM bdc_field  TABLES lt_bdc:       USING 'KONM-KBETR(02)' ls_item-i_netpr2.
        ENDIF.
        IF ls_item-i_kstbm3 IS NOT INITIAL.
          PERFORM bdc_field  TABLES lt_bdc:       USING 'KONM-KSTBM(03)' ls_item-i_kstbm3.
          PERFORM bdc_field  TABLES lt_bdc:       USING 'KONM-KBETR(03)' ls_item-i_netpr3.
        ENDIF.

*      lv_mode = 'A'.
        CALL TRANSACTION 'ME12' USING lt_bdc[]
                                MODE  lv_mode
                                UPDATE 'S'
                                MESSAGES INTO lt_mess.

        READ TABLE lt_mess INTO ls_mess WITH KEY msgtyp = 'S'
                                    msgid  = '06'
                                    msgnr  = '335'.
        IF sy-subrc = 0.
          ls_item_res-status = 'S'.
          ls_item_res-recode = '200'.
*        fs-i_infnr = ls_mess-msgv1.
          ls_item_res-message = '修改采购信息记录成功！'.

**add by wangyang 20260109
***修改成功时将备注以及采购信息记录号写入自建表
          IF <ls_item>-zstep <> '2'.
            CLEAR:ls_zpds_eine_text,lt_zpds_eine_text_single[].

            <ls_item>-matnr = |{ <ls_item>-matnr ALPHA = IN }|.
            <ls_item>-lifnr = |{ <ls_item>-lifnr ALPHA = IN }|.
            READ TABLE lt_zpds_eine_text INTO ls_zpds_eine_text WITH KEY matnr = <ls_item>-matnr
                                                                         lifnr = <ls_item>-lifnr
                                                                         ekorg = <ls_item>-i_ekorg
                                                                         werks = <ls_item>-werks
                                                                         infnr = <ls_item>-infnr.
            IF sy-subrc = 0.
              APPEND ls_zpds_eine_text TO lt_zpds_eine_text_single.
              MODIFY zpds_eine_text FROM TABLE lt_zpds_eine_text_single.
              IF sy-subrc = 0.
                COMMIT WORK.
                ls_item_res-message = ls_item_res-message && '价格及备注写入自建表成功！'.
              ELSE.
                ROLLBACK WORK.
                ls_item_res-message = ls_item_res-message && '价格及备注写入自建表失败！'.
              ENDIF.
            ELSE.
              ls_item_res-message = ls_item_res-message && '价格及备注写入自建表失败！'.
            ENDIF.
          ENDIF.
***修改采购信息记录的时候，根据价格有效期修改货源有效期
          CLEAR:lt_bdc[],ls_item,lt_mess[].
          READ TABLE <ls_item>-item INTO ls_item INDEX 1.

          PERFORM bdc_screen TABLES lt_bdc      USING 'SAPLMEOR' '0200'.
          PERFORM bdc_field  TABLES lt_bdc:      USING 'BDC_CURSOR' 'EORD-MATNR'.
          PERFORM bdc_field  TABLES lt_bdc:      USING 'BDC_OKCODE'  '/00'.
          PERFORM bdc_field  TABLES lt_bdc:      USING 'EORD-MATNR' <ls_item>-matnr.
          PERFORM bdc_field  TABLES lt_bdc:      USING 'EORD-WERKS' <ls_item>-werks.
          PERFORM bdc_screen TABLES lt_bdc      USING 'SAPLMEOR' '0205'.
          PERFORM bdc_field  TABLES lt_bdc:      USING 'EORD-VDATU(01)'  ls_item-i_datab."有效从
          PERFORM bdc_field  TABLES lt_bdc:      USING 'EORD-BDATU(01)'  ls_item-i_datbi."有效至
          PERFORM bdc_field  TABLES lt_bdc:      USING 'EORD-LIFNR(01)'  <ls_item>-lifnr.
          PERFORM bdc_field  TABLES lt_bdc:      USING 'EORD-EKORG(01)'  <ls_item>-i_ekorg.
          IF <ls_item>-feskz = 'Y'.
            PERFORM bdc_field  TABLES lt_bdc:      USING 'RM06W-FESKZ(01)'  'X'."固定货源
          ENDIF.
          PERFORM bdc_field  TABLES lt_bdc:      USING 'BDC_OKCODE'  '=BU'.
          CALL TRANSACTION 'ME01' USING lt_bdc[]
                                MODE  lv_mode
                                UPDATE 'S'
                                MESSAGES INTO lt_mess.
          READ TABLE lt_mess INTO ls_mess WITH KEY msgtyp = 'S'
                                      msgid  = '06'
                                      msgnr  = '790'.
          IF sy-subrc = 0.
            ls_item_res-message = ls_item_res-message && '，修改货源清单成功！'.
          ELSE.
            CLEAR:lv_message.
            READ TABLE lt_mess WITH KEY msgtyp = 'E'.
            CALL FUNCTION 'FORMAT_MESSAGE'
              EXPORTING
                id        = lt_mess-msgid
                no        = lt_mess-msgnr
                v1        = lt_mess-msgv1
                v2        = lt_mess-msgv2
                v3        = lt_mess-msgv3
                v4        = lt_mess-msgv4
              IMPORTING
                msg       = lv_message
              EXCEPTIONS
                not_found = 1
                OTHERS    = 2.

            ls_item_res-message = ls_item_res-message && '，创建货源清单失败：' && lv_message.

          ENDIF.
***end
        ELSE.
          ls_item_res-status = 'E'.
          ls_item_res-recode = '500'.
          ls_item_res-message = '修改采购信息记录失败：'.
          READ TABLE lt_mess WITH KEY msgtyp = 'E'.
          CALL FUNCTION 'FORMAT_MESSAGE'
            EXPORTING
              id        = lt_mess-msgid
              no        = lt_mess-msgnr
              v1        = lt_mess-msgv1
              v2        = lt_mess-msgv2
              v3        = lt_mess-msgv3
              v4        = lt_mess-msgv4
            IMPORTING
              msg       = lv_message
            EXCEPTIONS
              not_found = 1
              OTHERS    = 2.

          ls_item_res-message = ls_item_res-message && lv_message.

        ENDIF.
      ENDLOOP.
***根据I_BESKZ更新物料主数据采购类型/特殊采购类
      IF <ls_item>-i_beskz IS NOT INITIAL.
        CLEAR: lv_beskz_val, lv_sobsl_val, ls_headdata_mm, ls_plantdata_mm, ls_plantdatax_mm, lt_bapi_ret[].
        SPLIT <ls_item>-i_beskz AT '-' INTO lv_beskz_val lv_sobsl_val.
        lv_matnr = |{ <ls_item>-matnr ALPHA = IN WIDTH = 18 }|.
        ls_headdata_mm-material    = lv_matnr.
        ls_plantdata_mm-plant      = <ls_item>-werks.
        ls_plantdata_mm-proc_type  = lv_beskz_val.
        ls_plantdatax_mm-plant     = <ls_item>-werks.
        ls_plantdatax_mm-proc_type = 'X'.
        IF lv_sobsl_val IS NOT INITIAL.
          ls_plantdata_mm-spproctype  = lv_sobsl_val.
          ls_plantdatax_mm-spproctype = 'X'.
        ENDIF.
        CALL FUNCTION 'BAPI_MATERIAL_SAVEDATA'
          EXPORTING
            headdata       = ls_headdata_mm
            plantdata      = ls_plantdata_mm
            plantdatax     = ls_plantdatax_mm
          TABLES
            returnmessages = lt_bapi_ret.
        READ TABLE lt_bapi_ret INTO ls_bapi_ret WITH KEY type = 'E'.
        IF sy-subrc <> 0.
          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
            EXPORTING
              wait = 'X'.
          ls_item_res-message = ls_item_res-message && '，更新物料采购类型成功！'.
        ELSE.
          CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
          ls_item_res-message = ls_item_res-message && '，更新物料采购类型失败：' && ls_bapi_ret-message.
        ENDIF.
      ENDIF.
    ENDIF.

    IF <ls_item>-zflag EQ 'D'.

      "校验是否存在，存在的话则不去新建
      SELECT SINGLE
        eina~infnr,
        eina~lifnr,
        eine~ekorg,
        eine~werks
      FROM eina
      LEFT JOIN eine ON eina~infnr = eine~infnr
      WHERE eina~lifnr EQ @<ls_item>-lifnr
      AND eine~ekorg EQ @<ls_item>-i_ekorg
      AND eine~werks EQ @<ls_item>-werks
      AND eina~matnr EQ @<ls_item>-matnr
      AND eine~esokz EQ '0'
      INTO @ls_eine.
      IF ls_eine IS INITIAL.
        ls_item_res-status = 'E'.
        ls_item_res-recode = '500'.
        ls_item_res-message = '采购信息记录不存在,请检查'.
      ENDIF.

      SELECT  *
      FROM a017
      WHERE kschl EQ 'PB00'
      AND kappl EQ 'M'
      AND lifnr EQ @<ls_item>-lifnr
      AND matnr EQ @<ls_item>-matnr
      AND ekorg EQ @<ls_item>-i_ekorg
      AND werks EQ @<ls_item>-werks
      INTO TABLE  @DATA(lt_a017).
      SORT lt_a017 BY datab ASCENDING.


      CASE <ls_item>-normb. "信息类别
        WHEN '0'.
          lv_esokz = 'RM06I-NORMB'. "标准
        WHEN '1'.
          lv_esokz = 'RM06I-LOHNB'. "外协加工 分包
        WHEN '2'.
          lv_esokz = 'RM06I-PIPEL'. "管道
        WHEN '3'.
          lv_esokz = 'RM06I-KONSI'. "寄售
      ENDCASE.

      "Enter
      PERFORM bdc_screen TABLES lt_bdc
        USING 'SAPMM06I' '0100'.
      PERFORM bdc_field  TABLES lt_bdc:
        USING 'BDC_OKCODE' '/00',
        USING 'EINA-LIFNR' <ls_item>-lifnr,  "供应商
        USING 'EINA-MATNR' <ls_item>-matnr,  "物料
        USING 'EINE-EKORG' <ls_item>-i_ekorg,  "采购组织
        USING 'EINE-WERKS' <ls_item>-werks,  "工厂
        USING 'EINA-INFNR' ls_eine-infnr,  "采购信息记录
        USING lv_esokz      'X'.      "信息类别：标准

      DATA: lv_index TYPE i,
            lv_code  TYPE string.
      LOOP AT <ls_item>-item INTO ls_item.
        CLEAR:lv_index,lv_code.
        LOOP AT lt_a017 INTO DATA(ls_017).
          lv_index = lv_index + 1.
          IF ls_017-datab = ls_item-i_datab AND ls_017-datbi = ls_item-i_datbi.
            lv_code = lv_index.
            lv_code = 'VAKE-DATAB(' && |{ lv_code ALPHA = IN WIDTH = 2 }| && ')'.
            EXIT.
          ENDIF.
        ENDLOOP.

        PERFORM bdc_screen TABLES lt_bdc      USING 'SAPMM06I' '0101'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_CURSOR'  'EINA-MAHN1'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_OKCODE'  '=KO'.

        PERFORM bdc_screen TABLES lt_bdc      USING 'SAPLV14A' '0102'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_CURSOR'  lv_code.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_OKCODE'  '=PICK'.

        PERFORM bdc_screen TABLES lt_bdc      USING 'SAPMV13A' '0201'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_CURSOR' 'KONP-KSCHL(01)'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_OKCODE' '=DLIN'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'RV130-SELKZ(01)'  'X'.
        PERFORM bdc_screen TABLES lt_bdc      USING 'SAPMV13A' '0201'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_CURSOR' 'KONP-KSCHL(01)'.
        PERFORM bdc_field  TABLES lt_bdc:       USING 'BDC_OKCODE' '=SICH'.
      ENDLOOP.
      CALL TRANSACTION 'ME12' USING lt_bdc[]
                              MODE  lv_mode
                              UPDATE 'S'
                              MESSAGES INTO lt_mess.

      READ TABLE lt_mess INTO ls_mess WITH KEY msgtyp = 'S'
                                  msgid  = '06'
                                  msgnr  = '335'.
      IF sy-subrc = 0.
        ls_item_res-status = 'S'.
        ls_item_res-recode = '200'.
*        fs-i_infnr = ls_mess-msgv1.
        ls_item_res-message = '删除采购信息记录成功！'.
      ELSE.
        ls_item_res-status = 'E'.
        ls_item_res-recode = '500'.
        READ TABLE lt_mess WITH KEY msgtyp = 'E'.
        CALL FUNCTION 'FORMAT_MESSAGE'
          EXPORTING
            id        = lt_mess-msgid
            no        = lt_mess-msgnr
            v1        = lt_mess-msgv1
            v2        = lt_mess-msgv2
            v3        = lt_mess-msgv3
            v4        = lt_mess-msgv4
          IMPORTING
            msg       = lv_message
          EXCEPTIONS
            not_found = 1
            OTHERS    = 2.
        IF ls_item_res-message IS INITIAL.
          ls_item_res-message = '删除采购信息记录失败:' && lv_message.
        ENDIF.
      ENDIF.
    ENDIF.

    ls_item_res-matnr = |{ <ls_item>-matnr ALPHA = OUT }|.
    ls_item_res-lifnr = |{ <ls_item>-lifnr ALPHA = OUT }|.
    ls_item_res-werks = |{ <ls_item>-werks ALPHA = OUT }|.
    ls_item_res-normb = |{ <ls_item>-normb ALPHA = OUT }|.
    APPEND ls_item_res TO lt_item_res.
  ENDLOOP.

  ex_status = 'S'.
  ex_message = '操作成功！'.

  CALL METHOD /ui2/cl_json=>serialize
    EXPORTING
      compress = abap_true
      data     = lt_item_res
    RECEIVING
      r_json   = ex_json.
  "&-----日志记录
  ls_header-if_statu = '01'.
  TRY.
      lo_log->modify_header( i_statu = ls_header-if_statu i_ifmsg = ls_header-ifmsg i_busno = CONV #( '00006' ) ).
      lo_log->save_payload( i_logtyp = 'O' i_paylod = ex_json )."
    CATCH cx_ai_system_fault INTO lo_sys_exception2.
  ENDTRY.

ENDFUNCTION.