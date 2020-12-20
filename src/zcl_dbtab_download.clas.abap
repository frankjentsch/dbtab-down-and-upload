CLASS zcl_dbtab_download DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_http_service_extension.
    INTERFACES if_oo_adt_classrun.

  PROTECTED SECTION.

  PRIVATE SECTION.
    CONSTANTS BEGIN OF co_url_parameter.
    CONSTANTS   table_name_suggestion TYPE string VALUE `table_name_suggestion` ##no_text.
    CONSTANTS   download_tables       TYPE string VALUE `download_tables` ##no_text.
    CONSTANTS   check_tables          TYPE string VALUE `check_tables` ##no_text.
    CONSTANTS END OF co_url_parameter.

    METHODS get_html RETURNING VALUE(rv_html) TYPE string.
ENDCLASS.


CLASS zcl_dbtab_download IMPLEMENTATION.

  METHOD if_http_service_extension~handle_request.

    CASE request->get_method(  ).

      WHEN CONV string( if_web_http_client=>get ).
        DATA(lv_table_name_suggestion) = to_upper( request->get_form_field( co_url_parameter-table_name_suggestion ) ).
        DATA(lv_download_tables) = to_upper( request->get_form_field( co_url_parameter-download_tables ) ).

        IF lv_table_name_suggestion IS NOT INITIAL.
          "return search-as-you-type results
          response->set_text( NEW zcl_dbtab_helper( )->search_table_name_json_output( lv_table_name_suggestion ) ).

        ELSEIF lv_download_tables IS NOT INITIAL.
          "convert table names string
          NEW zcl_dbtab_helper( )->check_tables_visibility(
            EXPORTING
              iv_table_names    = lv_download_tables
            IMPORTING
              et_table_name     = DATA(lt_table_name)
              ev_error_occurred = DATA(lv_error_occurred)
              ev_error_message  = DATA(lv_error_message)
          ).
          IF lv_error_occurred = abap_true.
            response->set_text( lv_error_message ).
            response->set_status( 404 ).
          ELSE.
            "return file content
            NEW zcl_dbtab_helper( )->download_file_content(
              EXPORTING
                it_table_name     = lt_table_name
              IMPORTING
                ev_xml            = DATA(lv_xml)
                ev_error_occurred = lv_error_occurred
                ev_error_message  = lv_error_message
            ).
            IF lv_error_occurred = abap_false.
              DATA lv_table_name_descr TYPE string.
              READ TABLE lt_table_name INDEX 1 INTO lv_table_name_descr.
              IF lines( lt_table_name ) > 1.
                lv_table_name_descr = lv_table_name_descr && |_and_{ lines( lt_table_name ) - 1 }_more|.
              ENDIF.

              response->set_binary( lv_xml ).
              response->set_header_fields( VALUE #(
                ( name  = `content-type`        value = |application/json| )
                ( name  = `content-disposition` value = |attachment;filename="{ lv_table_name_descr }_{ sy-sysid }_{ cl_abap_context_info=>get_system_date( ) }_{ cl_abap_context_info=>get_system_time( ) }.xml"| )
              ) ) ##no_text.
            ELSE.
              response->set_text( lv_error_message ).
              response->set_status( 404 ).
            ENDIF.
          ENDIF.

        ELSE.
          "return static html for web page
          response->set_text( get_html( ) ).

        ENDIF.

      WHEN CONV string( if_web_http_client=>post ).
        DATA(lv_check_tables) = to_upper( request->get_form_field( co_url_parameter-check_tables ) ).
        IF lv_check_tables IS NOT INITIAL.
          "check visibility of database table
          NEW zcl_dbtab_helper( )->check_tables_visibility(
            EXPORTING
              iv_table_names    = lv_check_tables
            IMPORTING
              ev_error_occurred = lv_error_occurred
              ev_error_message  = lv_error_message
          ).
          IF lv_error_occurred = abap_true.
            response->set_text( lv_error_message ).
            response->set_status( 404 ).
          ENDIF.
        ENDIF.

    ENDCASE.

  ENDMETHOD.

  METHOD get_html.

    "language dependent texts
    DATA(lv_title)        = CONV string( 'Download Table Data'(001) ).
    DATA(lv_l_table_name) = CONV string( 'Table Name(s)'(002) ).
    DATA(lv_l_download)   = CONV string( 'Download'(003) ).

    DATA(lv_m_table_name_missing) = CONV string( 'Enter a table name'(011) ).

    rv_html =
     |<!DOCTYPE html> \n| &&
     |<html lang="en"> \n| &&
     |<head> \n| &&
     |    <meta charset="utf-8"> \n| &&
     |    <meta http-equiv="X-UA-Compatible" content="IE=edge"> \n| &&
     |    <meta name="viewport" content="width=device-width, initial-scale=1"> \n| &&
     |    <title>{ lv_title }</title> \n| &&
     |    <script id="sap-ui-bootstrap" src="https://sapui5.hana.ondemand.com/resources/sap-ui-core.js" \n| &&
     |        data-sap-ui-theme="sap_fiori_3" \n| &&
     |        data-sap-ui-xx-bindingSyntax="complex" \n| &&
     |        data-sap-ui-compatVersion="edge" \n| &&
     |        data-sap-ui-async="true"> \n| &&
     |    </script> \n| &&
     |    <script> \n| &&
     |        sap.ui.require(['sap/ui/core/Core'], (oCore, ) => \{ \n| &&

     |            sap.ui.getCore().loadLibrary("sap.f", \{ \n| &&
     |                async: true \n| &&
     |            \}).then(() => \{ \n| &&

     |                let shell = new sap.f.ShellBar("shell") \n| &&
     |                shell.setTitle("{ lv_title }") \n| &&
     |                shell.placeAt("uiArea") \n| &&

     |                sap.ui.getCore().loadLibrary("sap.ui.layout", \{ \n| &&
     |                    async: true \n| &&
     |                \}).then(() => \{ \n| &&

     |                    let layout = new sap.ui.layout.VerticalLayout("layout") \n| &&
     |                    layout.placeAt("uiArea") \n| &&

     |                    sap.ui.getCore().loadLibrary("sap.m", \{ \n| &&
     |                        async: true \n| &&
     |                    \}).then(() => \{\}) \n| &&

     |                    let input = new sap.m.Input("tablename") \n| &&
     |                    input.placeAt("layout") \n| &&
     |                    input.setRequired(true) \n| &&
     |                    input.setWidth("600px") \n| &&
     |                    input.setPlaceholder("{ lv_l_table_name }") \n| &&
     |                    input.setShowSuggestion(true) \n| &&
     |                    input.attachSuggest(function (oEvent)\{ jQuery.ajax(\{ \n| &&
     |                        method: "GET", \n| &&
     |                        url: "?{ co_url_parameter-table_name_suggestion }=" + encodeURIComponent(oEvent.getParameter("suggestValue")), \n| &&
     |                        timeout: 30000, \n| &&
     |                        dataType: "json", \n| &&
     |                        success: function(myJSON) \{ \n| &&
     |                            let input = oCore.byId("tablename") \n| &&
     |                            input.destroySuggestionItems() \n| &&
     |                            for (var i = 0; i < myJSON.length; i++) \{ \n| &&
     |                                input.addSuggestionItem(new sap.ui.core.Item(\{ text: myJSON[i].TABLE_NAME \})); \n| &&
     |                            \} \n| &&
     |                        \}, \n| &&
     |                        error: function(oErr)\{ \} \n| &&
     |                    \}) \}) \n| &&

     |                    let button = new sap.m.Button("button") \n| &&
     |                    button.setText("{ lv_l_download }") \n| &&
     |                    button.placeAt("layout") \n| &&
     |                    button.attachPress(function (oEvent) \{ \n| &&
     |                        let oInput = oCore.byId("tablename") \n| &&
     |                        if (!oInput.getValue())\{ \n| &&
     |                            sap.m.MessageToast.show("{ lv_m_table_name_missing }") \n| &&
     |                            return \n| &&
     |                        \} \n| &&
     |                        sap.ui.core.BusyIndicator.show(); \n| &&
     |                        jQuery.ajax(\{ \n| &&
     |                            method: "POST", \n| &&
     |                            url: "?{ co_url_parameter-check_tables }=" + encodeURIComponent(oInput.getValue()), \n| &&
     |                            success: function()\{ \n| &&
     |                               sap.m.URLHelper.redirect("?{ co_url_parameter-download_tables }=" + encodeURIComponent(oInput.getValue())); \n| &&
     |                               sap.ui.core.BusyIndicator.hide(); \n| &&
     |                            \}, \n| &&
     |                            error: function(oErr)\{ \n| &&
     |                               sap.ui.core.BusyIndicator.hide(); \n| &&
     |                               sap.m.MessageToast.show(oErr.responseText); \n| &&
     |                            \} \n| &&
     |                        \}) \n| &&
     |                    \}) \n| &&
     |                \}) \n| &&
     |            \}) \n| &&
     |        \}) \n| &&
     |    </script> \n| &&
     |</head> \n| &&
     |<body class="sapUiBody"> \n| &&
     |    <div id="uiArea"></div> \n| &&
     |</body> \n| &&
     |</html>| ##no_text.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.
    out->write( get_html( ) ).
  ENDMETHOD.

ENDCLASS.
