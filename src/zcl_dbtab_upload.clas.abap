CLASS zcl_dbtab_upload DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_http_service_extension.
    INTERFACES if_oo_adt_classrun.

  PROTECTED SECTION.

  PRIVATE SECTION.
    METHODS get_html RETURNING VALUE(rv_html) TYPE string.

ENDCLASS.



CLASS ZCL_DBTAB_UPLOAD IMPLEMENTATION.


  METHOD get_html.

    "language dependent texts
    DATA(lv_title)        = CONV string( 'Upload Table Data'(001) ).
    DATA(lv_l_upload)     = CONV string( 'Upload'(003) ).

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
     |                    let line2 = new sap.ui.layout.HorizontalLayout("line2") \n| &&
     |                    let line3 = new sap.ui.layout.HorizontalLayout("line3") \n| &&
     |                    let line4 = new sap.ui.layout.HorizontalLayout("line4") \n| &&
     |                    let line5 = new sap.ui.layout.HorizontalLayout("line5") \n| &&
     |                    line2.placeAt("layout") \n| &&
     |                    line3.placeAt("layout") \n| &&
     |                    line4.placeAt("layout") \n| &&
     |                    line5.placeAt("layout") \n| &&

     |                    sap.ui.getCore().loadLibrary("sap.m", \{ \n| &&
     |                        async: true \n| &&
     |                    \}).then(() => \{\}) \n| &&

     |                    let button = new sap.m.Button("button") \n| &&
     |                    button.setText("Upload File") \n| &&
     |                    button.placeAt("line5") \n| &&
     |                    button.attachPress(function () \{ \n| &&
     |                        let oFileUploader = oCore.byId("fileToUpload") \n| &&
     |                        if (!oFileUploader.getValue()) \{ \n| &&
     |                            sap.m.MessageToast.show("Choose a file first") \n| &&
     |                            return \n| &&
     |                        \} \n| &&
     |                        sap.ui.core.BusyIndicator.show(); \n| &&
     |                        let oGroup = oCore.byId("grpDataOptions") \n| &&
     |                        oFileUploader.setAdditionalData(oGroup.getSelectedIndex()) \n| &&
     |                        oFileUploader.upload() \n| &&
     |                    \}) \n| &&
     |                    let groupDataOptions = new sap.m.RadioButtonGroup("grpDataOptions") \n| &&
     |                    let lblGroupDataOptions = new sap.m.Label("lblDataOptions") \n| &&
     |                    lblGroupDataOptions.setLabelFor(groupDataOptions) \n| &&
     |                    lblGroupDataOptions.setText("Data Upload Options") \n| &&
     |                    lblGroupDataOptions.placeAt("line3") \n| &&
     |                    groupDataOptions.placeAt("line4") \n| &&
     |                    rbAppend = new sap.m.RadioButton("rbAppend") \n| &&
     |                    rbReplace = new sap.m.RadioButton("rbReplace") \n| &&
     |                    rbAppend.setText("Append") \n| &&
     |                    rbReplace.setText("Replace") \n| &&
     |                    groupDataOptions.addButton(rbAppend) \n| &&
     |                    groupDataOptions.addButton(rbReplace) \n| &&
     |                    rbAppend.setGroupName("grpDataOptions") \n| &&
     |                    rbReplace.setGroupName("grpDataOptions") \n| &&
     |                    sap.ui.getCore().loadLibrary("sap.ui.unified", \{ \n| &&
     |                        async: true \n| &&
     |                    \}).then(() => \{ \n| &&
     |                        var fileUploader = new sap.ui.unified.FileUploader( \n| &&
     |                            "fileToUpload") \n| &&
     |                        fileUploader.setFileType("xml") \n| &&
     |                        fileUploader.setWidth("400px") \n| &&
     |                        fileUploader.placeAt("line2") \n| &&
     |                        fileUploader.setPlaceholder( \n| &&
     |                            "Choose File for Upload...") \n| &&
     |                        fileUploader.attachUploadComplete(function (oEvent) \{ \n| &&
     |                           sap.ui.core.BusyIndicator.hide(); \n| &&
     |                           sap.m.MessageToast.show(oEvent.getParameters().response); \n| &&
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
     | \n| &&
     |</html>| ##no_text.

  ENDMETHOD.


  METHOD if_http_service_extension~handle_request.

    CASE request->get_method(  ).

      WHEN CONV string( if_web_http_client=>get ).
        "return static html for web page
        response->set_text( get_html( ) ).

      WHEN CONV string( if_web_http_client=>post ).
        DATA lv_override TYPE abap_bool.
        CASE request->get_form_field( `filetoupload-data` ).
          WHEN '0'.
            lv_override = abap_false.
          WHEN '1'.
            lv_override = abap_true.
          WHEN OTHERS.
            response->set_text( CONV #( 'Invalid upload operation'(006) ) ).
            response->set_status( 404 ).
            RETURN.
        ENDCASE.

        DO request->num_multiparts( ) TIMES.
          DATA(lo_part_request) = request->get_multipart( index = sy-index ).
          IF lo_part_request IS BOUND.
            DATA(lv_xml) = lo_part_request->get_binary( ).
            IF lv_xml IS NOT INITIAL.
              NEW zcl_dbtab_helper( )->upload_file_content(
                EXPORTING
                  iv_xml            = lv_xml
                  iv_overwrite      = lv_override
                IMPORTING
                  ev_error_occurred = DATA(lv_error_occurred)
                  ev_error_message  = DATA(lv_error_message)
              ).
              IF lv_error_occurred = abap_false.
                response->set_text( CONV #( 'Data has been successfully inserted'(007) ) ).
              ELSE.
                response->set_text( lv_error_message ).
                response->set_status( 404 ).
              ENDIF.
              EXIT.
            ENDIF.
          ENDIF.
        ENDDO.

    ENDCASE.

  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.
    out->write( get_html( ) ).
  ENDMETHOD.
ENDCLASS.
