CLASS zcl_dbtab_helper DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    TYPES ty_table_name   TYPE c LENGTH 30.
    TYPES ty_t_table_name TYPE STANDARD TABLE OF ty_table_name WITH EMPTY KEY.

    CONSTANTS BEGIN OF c_applog_object.
    CONSTANTS   name TYPE if_bali_object_handler=>ty_object VALUE 'ZDBTAB_DOWN_AND_UPLO'.
    CONSTANTS   BEGIN OF subobject.
    CONSTANTS     download TYPE if_bali_object_handler=>ty_subobject VALUE 'DOWNLOAD'.
    CONSTANTS     upload   TYPE if_bali_object_handler=>ty_subobject VALUE 'UPLOAD'.
    CONSTANTS   END OF subobject.
    CONSTANTS END OF c_applog_object.

    METHODS check_tables_visibility
      IMPORTING iv_table_names    TYPE string
      EXPORTING et_table_name     TYPE ty_t_table_name
                ev_error_occurred TYPE abap_bool
                ev_error_message  TYPE string.

    METHODS download_file_content
      IMPORTING it_table_name     TYPE ty_t_table_name
      EXPORTING ev_xml            TYPE xstring
                ev_error_occurred TYPE abap_bool
                ev_error_message  TYPE string.

    METHODS upload_file_content
      IMPORTING iv_xml            TYPE xstring
                iv_overwrite      TYPE abap_bool OPTIONAL
      EXPORTING ev_error_occurred TYPE abap_bool
                ev_error_message  TYPE string.

    METHODS search_table_name_json_output
      IMPORTING iv_search_text        TYPE string
      RETURNING VALUE(rv_json_output) TYPE string.

  PROTECTED SECTION.

  PRIVATE SECTION.
    TYPES BEGIN OF ty_s_download_file_content.
    TYPES   table_name      TYPE ty_table_name.
    TYPES   row_count       TYPE i.
    TYPES   content_version TYPE i.
    TYPES   content         TYPE xstring.
    TYPES END OF ty_s_download_file_content.

    TYPES ty_t_download_file_content TYPE STANDARD TABLE OF ty_s_download_file_content WITH EMPTY KEY.

    TYPES BEGIN OF ty_s_log_entry.
    TYPES   table_name      TYPE ty_table_name.
    TYPES   row_count       TYPE i.
    TYPES END OF ty_s_log_entry.

    TYPES ty_t_log_entry TYPE STANDARD TABLE OF ty_s_log_entry WITH EMPTY KEY.

    CONSTANTS c_table_name_max_length     TYPE i VALUE 30.
    CONSTANTS c_table_name_separators     TYPE c LENGTH 3 VALUE ' ,;'.
    CONSTANTS c_table_name_main_separator TYPE c LENGTH 1 VALUE ' '.
    CONSTANTS c_table_name_regex          TYPE string VALUE `[\w/]{1,30}`.

    METHODS check_table_visibility
      IMPORTING iv_table_name     TYPE ty_table_name
      EXPORTING ev_error_occurred TYPE abap_bool
                ev_error_message  TYPE string.

    METHODS serialize_table_data
      IMPORTING iv_table_name            TYPE ty_table_name
      EXPORTING es_download_file_content TYPE ty_s_download_file_content
                ev_error_occurred        TYPE abap_bool
                ev_error_message         TYPE string.

    METHODS deserialize_table_data
      IMPORTING is_download_file_content TYPE ty_s_download_file_content
                iv_overwrite             TYPE abap_bool OPTIONAL
      EXPORTING ev_error_occurred        TYPE abap_bool
                ev_error_message         TYPE string.

    METHODS search_table_name
      IMPORTING iv_search_text       TYPE string
      RETURNING VALUE(rt_table_name) TYPE ty_t_table_name.

    METHODS check_log_object
      EXPORTING ev_error_occurred TYPE abap_bool
                ev_error_message  TYPE string.

    METHODS write_log_entries
      IMPORTING it_log_entry      TYPE ty_t_log_entry
                iv_for_download   TYPE abap_bool
                iv_overwrite      TYPE abap_bool OPTIONAL
      EXPORTING ev_error_occurred TYPE abap_bool
                ev_error_message  TYPE string.

ENDCLASS.


CLASS zcl_dbtab_helper IMPLEMENTATION.

  METHOD check_tables_visibility.

    CLEAR et_table_name.
    CLEAR ev_error_occurred.
    CLEAR ev_error_message.

    CHECK iv_table_names IS NOT INITIAL.

    "check availability of log object
    check_log_object(
      IMPORTING
        ev_error_occurred = ev_error_occurred
        ev_error_message  = ev_error_message
    ).
    IF ev_error_occurred = abap_true.
      RETURN.
    ENDIF.

    "replace the supported separators
    DATA(lv_table_names) = iv_table_names.

    IF lv_table_names CA c_table_name_separators.
      DATA lv_table_name_separator TYPE c LENGTH 1.
      DATA(lv_table_name_separator_index) = 0.
      DO strlen( c_table_name_separators ) TIMES.
        lv_table_name_separator = c_table_name_separators+lv_table_name_separator_index(1).
        lv_table_name_separator_index += 1.
        IF lv_table_name_separator <> c_table_name_main_separator.
          lv_table_names = replace( val = lv_table_names sub = lv_table_name_separator with = c_table_name_main_separator occ = 0 ).
        ENDIF.
      ENDDO.
    ENDIF.

    "convert the query string into a table name list
    lv_table_names = condense( lv_table_names ).
    SPLIT lv_table_names AT c_table_name_main_separator INTO TABLE DATA(lt_table_name_string).

    "check each single table
    DATA lt_table_name_dupl_check TYPE SORTED TABLE OF string WITH NON-UNIQUE KEY table_line.
    LOOP AT lt_table_name_string INTO DATA(lv_table_name_string).
      IF ( strlen( lv_table_name_string ) > c_table_name_max_length ) OR
         ( match( val = lv_table_name_string regex = c_table_name_regex ) = abap_false ).
        ev_error_occurred = abap_true.
        ev_error_message  = replace( val = 'Table &1 does not exist'(001) sub = '&1' with = lv_table_name_string ).
        RETURN.
      ELSE.
        READ TABLE lt_table_name_dupl_check TRANSPORTING NO FIELDS
                   WITH TABLE KEY table_line = lv_table_name_string.
        IF sy-subrc = 0.
          ev_error_occurred = abap_true.
          ev_error_message  = replace( val = 'Table &1 entered twice'(003) sub = '&1' with = lv_table_name_string ).
          RETURN.
        ELSE.
          check_table_visibility(
            EXPORTING
              iv_table_name     = CONV #( lv_table_name_string )
            IMPORTING
              ev_error_occurred = ev_error_occurred
              ev_error_message  = ev_error_message
          ).
          IF ev_error_occurred = abap_true.
            RETURN.
          ENDIF.

          INSERT lv_table_name_string INTO TABLE lt_table_name_dupl_check.
        ENDIF.
      ENDIF.
    ENDLOOP.

    et_table_name = lt_table_name_string.

  ENDMETHOD.

  METHOD check_table_visibility.

    CLEAR ev_error_occurred.
    CLEAR ev_error_message.

    CHECK iv_table_name IS NOT INITIAL.

    "check design-time information
    TRY.
        IF xco_cp_abap_repository=>object->tabl->database_table->for( iv_name = CONV #( iv_table_name ) )->exists( ) = abap_true.
          "check runtime information
          TRY.
              DATA lo_test_ref TYPE REF TO data ##needed.
              CREATE DATA lo_test_ref TYPE (iv_table_name).

              "everything ok
              RETURN.

            CATCH cx_root ##no_handler ##catch_all.
              "table is not visible
          ENDTRY.
        ENDIF.

      CATCH cx_xco_runtime_exception ##no_handler.
        "XCO runtime error
    ENDTRY.

    ev_error_occurred = abap_true.
    ev_error_message  = replace( val = 'Table &1 does not exist'(001) sub = '&1' with = iv_table_name ).

  ENDMETHOD.

  METHOD download_file_content.

    CLEAR ev_xml.
    CLEAR ev_error_occurred.
    CLEAR ev_error_message.

    "check all prerequisites first
    LOOP AT it_table_name INTO DATA(lv_table_name).
      check_table_visibility(
        EXPORTING
          iv_table_name     = lv_table_name
        IMPORTING
          ev_error_occurred = ev_error_occurred
          ev_error_message  = ev_error_message
      ).
      IF ev_error_occurred = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.

    "read table data
    DATA lt_download_file_content TYPE ty_t_download_file_content.
    DATA ls_download_file_content LIKE LINE OF lt_download_file_content.

    LOOP AT it_table_name INTO lv_table_name.
      serialize_table_data(
        EXPORTING
          iv_table_name            = lv_table_name
        IMPORTING
          es_download_file_content = ls_download_file_content
          ev_error_occurred        = ev_error_occurred
          ev_error_message         = ev_error_message
      ).
      IF ev_error_occurred = abap_true.
        RETURN.
      ENDIF.

      APPEND ls_download_file_content TO lt_download_file_content.
    ENDLOOP.

    "serialize data for all tables as xml file
    TRY.
        CALL TRANSFORMATION id
          SOURCE root = lt_download_file_content
          RESULT XML ev_xml.

        "alternative option for JSON
        "DATA(lo_xml_writer) = cl_sxml_string_writer=>create( type = if_sxml=>co_xt_json ).
        "CALL TRANSFORMATION id SOURCE root = lt_download_file_content RESULT XML lo_xml_writer.
        "ev_xml = lo_xml_writer->get_output( ).

      CATCH cx_root ##catch_all.
        ev_error_occurred = abap_true.
        ev_error_message  = 'Error during creation of file content occurred'(002).
        RETURN.
    ENDTRY.

    "write log entries
    write_log_entries(
      EXPORTING
        it_log_entry      = CORRESPONDING #( lt_download_file_content )
        iv_for_download   = abap_true
      IMPORTING
        ev_error_occurred = ev_error_occurred
        ev_error_message  = ev_error_message
    ).
    IF ev_error_occurred = abap_true.
      RETURN.
    ENDIF.

    COMMIT WORK.

  ENDMETHOD.

  METHOD serialize_table_data.

    CLEAR es_download_file_content.
    CLEAR ev_error_occurred.
    CLEAR ev_error_message.

    TRY.
        DATA lr_dbtab_data TYPE REF TO data.
        CREATE DATA lr_dbtab_data TYPE STANDARD TABLE OF (iv_table_name).

      CATCH cx_root ##catch_all.
        ev_error_occurred = abap_true.
        ev_error_message  = replace( val = 'Table &1 does not exist'(001) sub = '&1' with = iv_table_name ).
        RETURN.
    ENDTRY.

    TRY.
        FIELD-SYMBOLS <lt_dbtab_data> TYPE STANDARD TABLE.
        ASSIGN lr_dbtab_data->* TO <lt_dbtab_data>.

        DATA(lv_table_name_checked) = cl_abap_dyn_prg=>check_table_name_str(
            val      = iv_table_name
            packages = space
        ).

        SELECT FROM (lv_table_name_checked) FIELDS * INTO TABLE @<lt_dbtab_data>.

      CATCH cx_root ##catch_all.
        ev_error_occurred = abap_true.
        ev_error_message  = replace( val = 'Table &1 does not exist'(001) sub = '&1' with = iv_table_name ).
        RETURN.
    ENDTRY.

    TRY.
        DATA lv_dbtab_xml TYPE xstring.

        "serialize table data to xml of json
        IF 1 = 2.
          "xml
          CALL TRANSFORMATION id
            SOURCE root = <lt_dbtab_data>
            RESULT XML lv_dbtab_xml.
        ELSE.
          "json
          DATA(lo_xml_writer) = cl_sxml_string_writer=>create( type = if_sxml=>co_xt_json ).
          CALL TRANSFORMATION id
            SOURCE root = <lt_dbtab_data>
            RESULT XML lo_xml_writer.

          lv_dbtab_xml = lo_xml_writer->get_output( ).
          FREE lo_xml_writer.
        ENDIF.

        es_download_file_content-table_name      = iv_table_name.
        es_download_file_content-row_count       = lines( <lt_dbtab_data> ).
        es_download_file_content-content_version = 1.

        "free memory
        FREE <lt_dbtab_data>.

        "compress the serialized xml
        cl_abap_gzip=>compress_binary( EXPORTING raw_in = lv_dbtab_xml IMPORTING gzip_out = es_download_file_content-content ).

        FREE lv_dbtab_xml.

      CATCH cx_root ##catch_all.
        ev_error_occurred = abap_true.
        ev_error_message  = 'Error during creation of file content occurred'(002).
    ENDTRY.

  ENDMETHOD.

  METHOD search_table_name.

    IF ( strlen( iv_search_text ) > c_table_name_max_length ) OR
       ( match( val = iv_search_text regex = c_table_name_regex ) = abap_false ).
      RETURN.
    ENDIF.

    DATA(lo_name_filter) = xco_cp_abap_repository=>object_name->get_filter(
                             xco_cp_abap_sql=>constraint->contains_pattern( to_upper( iv_search_text ) && '%' )  ).
    DATA(lo_objects) = xco_cp_abap_repository=>objects->tabl->database_tables->where( VALUE #(
                         ( lo_name_filter ) ) )->in( xco_cp_abap=>repository )->get( ).

    LOOP AT lo_objects INTO DATA(lo_object).
      APPEND lo_object->name TO rt_table_name.
    ENDLOOP.

    SORT rt_table_name BY table_line.

  ENDMETHOD.

  METHOD search_table_name_json_output.

    TYPES BEGIN OF ty_s_table_name_json_output.
    TYPES   table_name TYPE ty_table_name.
    TYPES END OF ty_s_table_name_json_output.

    DATA(lt_table_name) = search_table_name( iv_search_text ).

    DATA lt_table_name_json_output TYPE STANDARD TABLE OF ty_s_table_name_json_output WITH EMPTY KEY.
    LOOP AT lt_table_name INTO DATA(lv_table_name).
      APPEND VALUE #( table_name = lv_table_name ) TO lt_table_name_json_output.
    ENDLOOP.

    rv_json_output = /ui2/cl_json=>serialize( lt_table_name_json_output ).
    "rv_json_output = xco_cp_json=>data->from_abap( lt_table_name_json_output )->to_string( ). "alternative option

  ENDMETHOD.

  METHOD upload_file_content.

    CLEAR ev_error_occurred.
    CLEAR ev_error_message.

    DATA lt_download_file_content TYPE ty_t_download_file_content.

    "deserialize xml data for all tables
    TRY.
        CALL TRANSFORMATION id
          SOURCE XML iv_xml
          RESULT root = lt_download_file_content.

      CATCH cx_root ##catch_all.
        ev_error_occurred = abap_true.
        ev_error_message  = 'Error during file upload occurred'(004).
    ENDTRY.

    IF lt_download_file_content IS NOT INITIAL.
      "check all prerequisites first
      LOOP AT lt_download_file_content ASSIGNING FIELD-SYMBOL(<ls_download_file_content>).
        check_table_visibility(
          EXPORTING
            iv_table_name     = <ls_download_file_content>-table_name
          IMPORTING
            ev_error_occurred = ev_error_occurred
            ev_error_message  = ev_error_message
        ).
        IF ev_error_occurred = abap_true.
          RETURN.
        ENDIF.
      ENDLOOP.

      "write table data
      DATA lt_log_entry TYPE ty_t_log_entry.
      LOOP AT lt_download_file_content ASSIGNING <ls_download_file_content>.
        deserialize_table_data(
          EXPORTING
            is_download_file_content = <ls_download_file_content>
            iv_overwrite             = iv_overwrite
          IMPORTING
            ev_error_occurred        = ev_error_occurred
            ev_error_message         = ev_error_message
        ).
        IF ev_error_occurred = abap_false.
          APPEND VALUE #( table_name = <ls_download_file_content>-table_name
                          row_count  = <ls_download_file_content>-row_count  ) TO lt_log_entry.
          "free memory after completed processing of a table
          CLEAR <ls_download_file_content>-content.
        ELSE.
          EXIT.
        ENDIF.
      ENDLOOP.

      "write log entries for actually changed tables
      IF lt_log_entry IS NOT INITIAL.
        write_log_entries(
            it_log_entry    = lt_log_entry
            iv_for_download = abap_false
            iv_overwrite    = iv_overwrite
        ).
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD deserialize_table_data.

    CLEAR ev_error_occurred.
    CLEAR ev_error_message.

    TRY.
        DATA lr_dbtab_data TYPE REF TO data.
        CREATE DATA lr_dbtab_data TYPE STANDARD TABLE OF (is_download_file_content-table_name).

        FIELD-SYMBOLS <lt_dbtab_data> TYPE STANDARD TABLE.
        ASSIGN lr_dbtab_data->* TO <lt_dbtab_data>.

        DATA(lv_table_name_checked) = cl_abap_dyn_prg=>check_table_name_str(
            val      = is_download_file_content-table_name
            packages = space
        ).

      CATCH cx_root ##catch_all.
        ev_error_occurred = abap_true.
        ev_error_message  = replace( val = 'Table &1 does not exist'(001) sub = '&1' with = is_download_file_content-table_name ).
        RETURN.
    ENDTRY.

    TRY.
        DATA lv_dbtab_xml TYPE xstring.

        "decompress the deserialized xml
        cl_abap_gzip=>decompress_binary( EXPORTING gzip_in = is_download_file_content-content IMPORTING raw_out = lv_dbtab_xml ).

        "deserialize table data
        CALL TRANSFORMATION id
          SOURCE XML lv_dbtab_xml
          RESULT root = <lt_dbtab_data>.

        "free memory
        FREE lv_dbtab_xml.

      CATCH cx_root ##catch_all.
        ev_error_occurred = abap_true.
        ev_error_message  = 'Error during reading the data from file'(005).
    ENDTRY.

    TRY.
        IF iv_overwrite = abap_true.
          DELETE FROM (lv_table_name_checked).
        ENDIF.
        INSERT (lv_table_name_checked) FROM TABLE @<lt_dbtab_data>.
        COMMIT WORK.

      CATCH cx_root INTO DATA(lx_root) ##catch_all.
        ev_error_occurred = abap_true.
        ev_error_message  = replace( val = 'Error during inserting data into table &1'(006) sub = '&1' with = is_download_file_content-table_name ) && `: ` && lx_root->get_text( ).
        RETURN.
    ENDTRY.

  ENDMETHOD.

  METHOD check_log_object.

    CLEAR ev_error_occurred.
    CLEAR ev_error_message.

    TRY.
        cl_bali_object_handler=>get_instance( )->read_object(
          EXPORTING
            iv_object     = c_applog_object-name
          IMPORTING
            et_subobjects = DATA(lt_subobject)
        ).

        READ TABLE lt_subobject TRANSPORTING NO FIELDS
                   WITH KEY subobject = c_applog_object-subobject-download.
        IF sy-subrc <> 0.
          ev_error_occurred = abap_true.
          ev_error_message  = 'Applog object definition is incomplete - please refer to documentation'(011).
          RETURN.
        ENDIF.

        READ TABLE lt_subobject TRANSPORTING NO FIELDS
                   WITH KEY subobject = c_applog_object-subobject-upload.
        IF sy-subrc <> 0.
          ev_error_occurred = abap_true.
          ev_error_message  = 'Applog object definition is incomplete - please refer to documentation'(011).
          RETURN.
        ENDIF.

      CATCH cx_bali_objects.
        ev_error_occurred = abap_true.
        ev_error_message  = 'Applog object definition is missing - please refer to documentation'(010).
        RETURN.
    ENDTRY.

  ENDMETHOD.

  METHOD write_log_entries.

    CLEAR ev_error_occurred.
    CLEAR ev_error_message.

    CHECK it_log_entry IS NOT INITIAL.

    "determine external id for new log
    DATA lv_external_id TYPE if_bali_header_setter=>ty_external_id.
    READ TABLE it_log_entry INDEX 1 INTO DATA(ls_log_entry).
    lv_external_id = ls_log_entry-table_name.

    IF lines( it_log_entry ) > 1.
      lv_external_id = lv_external_id && | and { lines( it_log_entry ) - 1 } more| ##no_text.
    ENDIF.

    "create the log and add entries
    TRY.
        IF iv_for_download = abap_true.
          DATA(lo_log) = cl_bali_log=>create_with_header(
                            header = cl_bali_header_setter=>create(
                                         object      = c_applog_object-name
                                         subobject   = c_applog_object-subobject-download
                                         external_id = lv_external_id ) ).

          LOOP AT it_log_entry INTO ls_log_entry.
            lo_log->add_item( item = cl_bali_free_text_setter=>create( severity = if_bali_constants=>c_severity_information
                                                                       text     = |Table { ls_log_entry-table_name }: { ls_log_entry-row_count } rows downloaded| ) ) ##no_text.
          ENDLOOP.
        ELSE.
          lo_log = cl_bali_log=>create_with_header(
                            header = cl_bali_header_setter=>create(
                                         object      = c_applog_object-name
                                         subobject   = c_applog_object-subobject-upload
                                         external_id = lv_external_id ) ).

          LOOP AT it_log_entry INTO ls_log_entry.
            IF iv_overwrite = abap_false.
              lo_log->add_item( item = cl_bali_free_text_setter=>create( severity = if_bali_constants=>c_severity_information
                                                                         text     = |Table { ls_log_entry-table_name }: { ls_log_entry-row_count } rows appended| ) ) ##no_text.
            ELSE.
              lo_log->add_item( item = cl_bali_free_text_setter=>create( severity = if_bali_constants=>c_severity_information
                                                                         text     = |Table { ls_log_entry-table_name }: { ls_log_entry-row_count } rows replacing the previous content| ) ) ##no_text.
            ENDIF.
          ENDLOOP.
        ENDIF.

        "save the log
        cl_bali_log_db=>get_instance( )->save_log( log = lo_log ).

      CATCH cx_bali_runtime INTO DATA(lx_bali_runtime).
        ev_error_occurred = abap_true.
        ev_error_message  = lx_bali_runtime->get_text( ).
        RETURN.
    ENDTRY.

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    DATA(lo_objects) = xco_cp_abap_repository=>objects->tabl->database_tables->all->in( xco_cp_abap=>repository )->get( ).

    DATA lt_table_name TYPE ty_t_table_name.
    LOOP AT lo_objects INTO DATA(lo_object).
      APPEND lo_object->name TO lt_table_name.
    ENDLOOP.

    SORT lt_table_name BY table_line.

    DATA lv_output TYPE string.
    LOOP AT lt_table_name INTO DATA(lv_table_name).
      check_table_visibility(
        EXPORTING
          iv_table_name     = lv_table_name
        IMPORTING
          ev_error_occurred = DATA(lv_error_occurred)
      ).
      IF lv_error_occurred = abap_false.
        lv_output = lv_output && lv_table_name && ` `.
      ELSE.
        DELETE lt_table_name.
      ENDIF.
    ENDLOOP.

    out->write( lv_output ).
    out->write( |{ lines( lt_table_name ) } table(s) found| ) ##no_text.

  ENDMETHOD.

ENDCLASS.
