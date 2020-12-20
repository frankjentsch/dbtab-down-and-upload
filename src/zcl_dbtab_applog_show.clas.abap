CLASS zcl_dbtab_applog_show DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_dbtab_applog_show IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    TRY.
        "read all logs of the last 24 hours
        DATA(lt_log) = cl_bali_log_db=>get_instance( )->load_logs_via_filter( cl_bali_log_filter=>create( )->set_descriptor(
                           object = zcl_dbtab_helper=>c_applog_object-name )->set_time_interval(
                                        start_time = utclong_add( val = utclong_current( ) days = '1-' )
                                        end_time   = utclong_current( ) ) ).

        "output all log headers and items
        LOOP AT lt_log INTO DATA(lo_log).
          DATA(lo_header) = lo_log->get_header( ).
          out->write( |{ lo_header->subobject } { lo_header->log_timestamp TIMESTAMP = USER } { lo_header->log_user } { lo_header->external_id }| ).
          LOOP AT lo_log->get_all_items( ) INTO DATA(ls_item).
            out->write( ls_item-item->get_message_text( ) ).
          ENDLOOP.
          out->write( | | ).
        ENDLOOP.

      CATCH cx_bali_runtime INTO DATA(lx_bali_runtime).
        out->write( |Exception occurred: { lx_bali_runtime->get_text( ) }| ) ##no_text.
        RETURN.
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
