"!<h1>Class runner to create Application Log Object and Subobjects</h1>
"!<p>This class runner must be executed only in the development system and only once!
"! As there is currently no ADT editor available to create the required Application Log Object and Subobjects,
"! the corresponding design-time API must be used. This is a one-time activity as the objects will be assigned to a package and to a transport request.</p>
"!<p><strong>Please adjust the code below and enter an open transport request number as constant value for lc_package</strong>.</p>
"!<p>Please adjust also the package name if required.</p>
"!<p>This class runner supports only the creation of the required objects, but no update and no delete. It creates the Application Log Object <strong>ZDBTAB_DOWN_AND_UPLO</strong>
"! with the subobjects <strong>DOWNLOAD</strong> and <strong>UPLOAD</strong>.</p>
CLASS zcl_dbtab_applog_create_obj DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_dbtab_applog_create_obj IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    CONSTANTS lc_transport_request TYPE if_bali_object_handler=>ty_transport VALUE '...'.
    CONSTANTS lc_package           TYPE if_bali_object_handler=>ty_package   VALUE 'ZDBTAB_DOWN_AND_UPLOAD'.

    TYPES BEGIN OF ty_ls_obj.
    TYPES   object            TYPE if_bali_object_handler=>ty_object.
    TYPES   object_text       TYPE if_bali_object_handler=>ty_object_text.
    TYPES   subobjects        TYPE if_bali_object_handler=>ty_tab_subobject.
    TYPES END OF ty_ls_obj.

    DATA lt_obj TYPE STANDARD TABLE OF ty_ls_obj WITH EMPTY KEY.

    lt_obj = VALUE #(
      ( object = zcl_dbtab_helper=>c_applog_object-name object_text = 'Download and Upload of Table Data' subobjects = VALUE #(
          ( subobject = zcl_dbtab_helper=>c_applog_object-subobject-download subobject_text = 'Download of Table Data' )
          ( subobject = zcl_dbtab_helper=>c_applog_object-subobject-upload   subobject_text = 'Upload of Table Data' )
      ) )
    ) ##no_text.

    DATA(lo_log_object) = cl_bali_object_handler=>get_instance( ).

    LOOP AT lt_obj INTO DATA(ls_obj).
      TRY.
          lo_log_object->create_object(
              iv_object            = ls_obj-object
              iv_object_text       = ls_obj-object_text
              it_subobjects        = ls_obj-subobjects
              iv_package           = lc_package
              iv_transport_request = lc_transport_request ).

          out->write( |Successfully created: { ls_obj-object }| ) ##no_text.

        CATCH cx_bali_objects INTO DATA(lx_exception).
          out->write( |Error occurred for { ls_obj-object }: { lx_exception->get_text( ) }| ) ##no_text.
      ENDTRY.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
