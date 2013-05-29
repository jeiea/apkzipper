if {$::tcl_platform(os) ne "Windows NT" ||
    ($::tcl_platform(machine) ne "intel" &&
     $::tcl_platform(machine) ne "amd64")} {
    return
}

namespace eval twapi {}
proc twapi::package_setup {dir pkg version type {file {}} {commands {}}} {
    global auto_index

    if {$file eq ""} {
        set file $pkg
    }
    if {$::tcl_platform(pointerSize) == 8} {
        set fn [file join $dir "${file}64.dll"]
    } else {
        set fn [file join $dir "${file}.dll"]
    }

    if {$fn ne ""} {
        if {![file exists $fn]} {
            set fn "";          # Assume twapi statically linked in
        }
    }

    if {$pkg eq "twapi_base"} {
        # Need the twapi base of the same version
        # In tclkit builds, twapi_base is statically linked in
        foreach pair [info loaded] {
            if {$pkg eq [lindex $pair 1]} {
                set fn [lindex $pair 0]; # Possibly statically loaded
                break
            }
        }
        set loadcmd [list load $fn $pkg]
    } else {
        package require twapi_base $version
        if {$type eq "load"} {
            # Package could be statically linked or to be loaded
            if {[twapi::get_build_config single_module]} {
                # Modules are statically bound. Reset fn
                set fn {}
            }
            set loadcmd [list load $fn $pkg]
        } else {
            # A pure Tcl script package
            set loadcmd [list twapi::Twapi_SourceResource $file 1]
        }
    }

    if {[llength $commands] == 0} {
        # No commands specified, load the package right away
        # TBD - what about the exports table?
        uplevel #0 $loadcmd
    } else {
        # Set up the load for when commands are actually accessed
        # TBD - add a line to export commands here ?
        foreach {ns cmds} $commands {
            foreach cmd $cmds {
                if {[string index $cmd 0] ne "_"} {
                    dict lappend ::twapi::exports $ns $cmd
                }
                set auto_index(${ns}::$cmd) $loadcmd
            }
        }
    }

    # TBD - really necessary? The C modules do this on init anyways.
    # Maybe needed for pure scripts
    package provide $pkg $version
}

# The build process will append package ifneeded commands below
# to create an appropriate pkgIndex.tcl file for included modules
package ifneeded twapi_base 4.0a16 [list twapi::package_setup $dir twapi_base 4.0a16 load twapi_base {::twapi {atomize _parse_integer_pair _access_mask_to_rights close_lsa_policy_handle support_report _array_set_all _validate_guid _create_disposition_to_code format_message get_system_time map_account_to_sid large_system_time_to_secs get_tcl_channel_handle eventlog_open lookup_account_sid adsi_translate_name kl_equal _binary_to_guid is_valid_sid_syntax getenv import_commands get_window_long nil_uuid kl_flatten kl_unset debuglog_clear _share_mode_to_mask _access_rights_to_mask expand_environment_strings _guid_to_binary trap _array_non_zero_entry _net_enum_helper _init_security_defs min_os_version large_system_time_to_secs_since_1970 free_library twine cancel_wait_on_handle _decode_mem_registry_value get_lsa_policy_handle _seconds_to_timelist kl_vget resetbits get_current_user parseargs _wait_handler debuglog tcltype set_window_long canonicalize_guid pointer? _attach_hwin_and_eval free kl_create kl_set kl_create2 _parse_symbolic_bitmask _get_public_commands _timelist_to_seconds get_build_config random_bytes export_public_commands timelist_to_large_system_time pointer_type kl_get_default _drivemask_to_drivelist _lookup_account pointer_to_address map_windows_error create_file kl_print _ucs16_binary_to_string tclcast _array_non_zero_switches close_handle set_window_userdata _get_array_as_options eventlog_write _log_timestamp new_uuid pointer_from_address kl_get mem_binary_scan _timestring_to_timelist pointer_registered? wait _get_script_wm setbits win32_error pointer_equal? kl_fields _make_secattr load_library eventlog_close _timelist_to_timestring _unregister_script_wm_handler close_handles _normalize_path _decode_mem_guid _script_wm_handler duplicate_handle map_account_to_name recordarray get_os_version _validate_uuid _register_script_wm_handler true large_system_time_to_timelist pointer_null? _eventlog_valid_handle cast_handle list_raw_api _make_symbolic_bitmask wait_on_handle _bitmask_to_switches lookup_account_name malloc revert_to_self eventlog_log get_version _switches_to_bitmask secs_since_1970_to_large_system_time _unsafe_format_message}}]
package ifneeded metoo 4.0a16 [list twapi::package_setup $dir metoo 4.0a16 source {} {::metoo {_class_cmd demo _trace_class_renames _new ancestors class _trace_object_renames introspect _locate_method} ::metoo::object {my self next} ::metoo::define {superclass method export constructor destructor}}]
package ifneeded twapi_com 4.0a16 [list twapi::package_setup $dir twapi_com 4.0a16 load {} {::twapi {name_to_iid _dispatch_print_helper clsid_to_progid dispatch_prototype_set _adsi iid_to_name comobj? _paramflags_to_tokens dispatch_print _variant_values_from_safearray comobj_idispatch _dispatch_prototype_get _resolve_iid progid_to_clsid dispatch_prototype_get variant_type comobj_object comobj_instances _invkind_to_string comobj_null com_create_instance variant_value _resolve_com_params_text _vtcode_to_string timelist_to_variant_time _convert_to_clsid _flatten_com_type _parse_dispatch_paramdef define_dispatch_prototypes _iid_iunknown comobj _string_to_invkind _string_to_base_vt typelib_print _resolve_comtype _interface_proxy_tracer _iid_idispatch make_interface_proxy _comobj_cleanup unregister_typelib generate_code_from_typelib _interface_text _format_prototype _vttype_to_string _dispatch_prototype_load _resolve_params_for_prototype variant_time_to_timelist _eventsink_callback _resolve_com_type_text get_typelib_path_from_guid class _dispatch_prototype_set} ::metoo::define twapi_exportall}]
package ifneeded twapi_msi 4.0a16 [list twapi::package_setup $dir twapi_msi 4.0a16 source {} {::twapi {load_msi_prototypes cast_msi_object new_msi delete_msi init_msi}}]
package ifneeded twapi_power 4.0a16 [list twapi::package_setup $dir twapi_power 4.0a16 source {} {::twapi {get_device_power_state start_power_monitor stop_power_monitor _power_handler get_power_status}}]
package ifneeded twapi_printer 4.0a16 [list twapi::package_setup $dir twapi_printer 4.0a16 source {} {::twapi {get_default_printer enumerate_printers _symbolize_printer_attributes printer_properties_dialog}}]
package ifneeded twapi_synch 4.0a16 [list twapi::package_setup $dir twapi_synch 4.0a16 source {} {::twapi {reset_event create_event unlock_mutex open_mutex lock_mutex set_event create_mutex}}]
package ifneeded twapi_security 4.0a16 [list twapi::package_setup $dir twapi_security 4.0a16 load {} {::twapi {_ace_type_code_to_symbol set_security_descriptor_dacl lock_workstation get_resource_integrity security_descriptor_to_sddl _is_valid_security_descriptor new_luid get_token_privileges _map_impersonation_level set_ace_type close_token get_acl_aces get_token_privileges_and_attrs new_ace _is_valid_luid_syntax get_token_restricted_groups_and_attrs _integrity_to_sid set_resource_security_descriptor new_acl map_privilege_to_luid get_token_virtualization set_ace_inheritance get_token_impersonation_level set_acl_aces set_token_integrity new_restricted_dacl get_token_groups_and_attrs sort_acl_aces impersonate_user get_token_elevation _null_secd reset_thread_token append_acl_aces set_security_descriptor_owner impersonate_self get_token_statistics new_security_descriptor get_security_descriptor_text get_security_descriptor_group get_ace_inheritance _init_ace_type_symbol_to_code_map get_token_integrity_policy get_token_source set_thread_token set_ace_sid get_security_descriptor_control get_token_user get_token_integrity get_token_primary_group _ace_type_symbol_to_code get_resource_security_descriptor logoff disable_token_privileges map_luid_to_privilege get_security_descriptor_sacl prepend_acl_aces get_security_descriptor_integrity set_ace_rights _sid_to_integrity set_security_descriptor_integrity get_ace_rights get_ace_sid enable_token_privileges get_acl_rev get_token_linked_token open_user_token get_privilege_description set_security_descriptor_sacl map_token_group_attr eval_with_privileges get_token_info sddl_to_security_descriptor _map_luids_and_attrs_to_privileges enable_privileges _is_valid_acl _get_token_sid_field open_thread_token get_token_groups _map_resource_symbol_to_type impersonate_token get_security_descriptor_owner get_security_descriptor_dacl _delete_rights sort_aces set_token_virtualization open_process_token get_ace_type get_token_type set_token_integrity_policy get_token_owner get_ace_text check_enabled_privileges disable_privileges is_valid_luid_syntax set_resource_integrity disable_all_token_privileges map_token_privilege_attr set_security_descriptor_group}}]
package ifneeded twapi_account 4.0a16 [list twapi::package_setup $dir twapi_account 4.0a16 load {} {::twapi {_set_user_priv_level set_user_expiration set_user_name _logon_session_type_symbol set_user_account_info set_user_profile new_local_group _modify_account_rights get_global_group_members set_user_script_path get_logon_session_info add_account_rights enable_user remove_account_rights add_user_to_global_group get_users find_accounts_with_right get_global_group_info set_user_password remove_member_from_local_group set_user_comment get_account_rights remove_user_from_global_group add_member_to_local_group get_user_account_info add_members_to_local_group set_user_full_name get_user_local_groups_recursive disable_user get_local_group_info unlock_user set_user_country_code delete_local_group new_global_group find_logon_sessions get_global_groups get_local_groups delete_user delete_global_group remove_members_from_local_group get_local_group_members _change_user_info_flags set_user_home_dir new_user set_user_home_dir_drive _logon_session_type_code}}]
package ifneeded twapi_apputil 4.0a16 [list twapi::package_setup $dir twapi_apputil 4.0a16 load {} {::twapi {delete_inifile_section delete_inifile_key get_command_line_args get_command_line read_inifile_section read_inifile_section_names write_inifile_key read_inifile_key}}]
package ifneeded twapi_clipboard 4.0a16 [list twapi::package_setup $dir twapi_clipboard 4.0a16 load {} {::twapi {stop_clipboard_monitor register_clipboard_format clipboard_format_available close_clipboard read_clipboard_text get_clipboard_formats write_clipboard open_clipboard read_clipboard _clipboard_handler empty_clipboard start_clipboard_monitor get_registered_clipboard_format_name write_clipboard_text}}]
package ifneeded twapi_console 4.0a16 [list twapi::package_setup $dir twapi_console 4.0a16 load {} {::twapi {num_console_mouse_buttons _set_console_input_mode fill_console _modify_console_output_mode set_console_cursor_position console_read set_console_input_mode _get_console_input_mode set_console_screen_buffer_size get_console_window_location console_write get_console_input_mode get_console_output_codepage get_console_input_codepage _clear_console _set_console_output_mode _modify_console_input_mode get_console_cursor_position write_console _do_console_proc _get_console_screen_buffer_info set_standard_handle allocate_console get_console_window_maxsize free_console get_console_title set_console_title create_console_screen_buffer set_console_active_screen_buffer _set_console_default_attr get_console_output_mode _fill_console get_standard_handle _flags_to_console_output_attr _console_read get_console_handle generate_console_control_event set_console_input_codepage _console_write get_console_pending_input_count get_console_screen_buffer_info modify_console_input_mode _get_console_window_maxsize get_console_window _console_ctrl_handler _set_console_window_location modify_console_output_mode clear_console read_console flush_console_input _get_console_pending_input_count _set_console_screen_buffer_size _flush_console_input set_console_output_mode _set_console_cursor_position _set_console_active_screen_buffer set_console_default_attr set_console_window_location _get_console_output_mode _console_output_attr_to_flags set_console_output_codepage set_console_control_handler}}]
package ifneeded twapi_crypto 4.0a16 [list twapi::package_setup $dir twapi_crypto 4.0a16 load {} {::twapi {sspi_encrypt sspi_decrypt sspi_security_context_next sspi_server_new_context sspi_enumerate_packages _sspi_sample sspi_free_credentials sspi_get_security_context_sizes sspi_generate_signature sspi_client_new_context sspi_get_security_context_username sspi_verify_signature sspi_close_security_context _construct_sspi_security_context sspi_new_credentials sspi_get_security_context_features}}]
package ifneeded twapi_device 4.0a16 [list twapi::package_setup $dir twapi_device 4.0a16 load {} {::twapi {close_devinfoset _device_registry_sym_to_code get_device_element_instance_id device_ioctl _init_device_registry_code_maps _device_registry_code_to_sym _decode_PARTITION_INFORMATION_EX_binary get_devinfoset_registry_properties get_physical_disk_info device_setup_class_name_to_guids _partition_style_sym _device_notification_handler find_physical_disks _decode_PARTITION_INFORMATION_binary get_devinfoset_interface_details update_devinfoset stop_device_notifier start_device_notifier get_devinfoset_elements device_setup_class_guid_to_name}}]
package ifneeded twapi_etw 4.0a16 [list twapi::package_setup $dir twapi_etw 4.0a16 load {} {::twapi {etw_provider_enabled etw_stop_trace etw_dump_files etw_update_trace _etw_decipher_mof_event_field_type etw_close_trace etw_uninstall_mof etw_provider_enable_flags etw_start_kernel_trace etw_query_trace etw_install_mof etw_provider_enable_level etw_find_mof_event_classes etw_variable_tracker etw_open_file _etw_make_limited_unicode etw_control_trace etw_open_session etw_load_mof_event_class_obj etw_command_tracker etw_log_message etw_start_trace _etw_get_types etw_get_all_mof_event_classes etw_flush_trace etw_parse_mof_event_class etw_unregister_provider etw_process_events etw_register_provider etw_enable_trace etw_execution_tracker etw_format_events etw_load_mof_event_classes}}]
package ifneeded twapi_eventlog 4.0a16 [list twapi::package_setup $dir twapi_eventlog 4.0a16 load {} {::twapi {evt_log_info eventlog_backup evt_clear_log eventlog_count evt_open_channel_config evt_create_bookmark evt_object_array_property evt_export_log evt_close _evt_normalize_path eventlog_monitor_stop evt_archive_exported_log evt_open_session eventlog_format_message evt_cancel evt_update_bookmark eventlog_read evt_next evt_open_publisher_metadata _evt_map_channel_config_property evt_query_info evt_free_EVT_VARIANT_ARRAY evt_render_context_xpaths evt_channels evt_set_channel_config eventlog_oldest evt_format_publisher_message evt_free winlog_event_count evt_render_context_system eventlog_format_category _winlog_dump evt_close_session evt_query winlog_subscribe winlog_open eventlog_clear _eventlog_dump evt_open_log_info _evt_init winlog_backup evt_decode_event_system_fields _evt_dump _eventlog_notification_handler evt_object_array_size evt_seek evt_publishers evt_local_session? evt_publisher_metadata_property eventlog_monitor_start evt_get_channel_config winlog_read evt_event_metadata_property evt_local_session _find_eventlog_regkey winlog_close evt_publisher_events_metadata eventlog_is_full winlog_clear evt_subscribe evt_free_EVT_RENDER_VALUES evt_render_context_user evt_decode_event eventlog_subscribe evt_decode_event_userdata evt_event_info}}]
package ifneeded twapi_mstask 4.0a16 [list twapi::package_setup $dir twapi_mstask 4.0a16 load {} {::twapi {itask_release mstask_delete itasktrigger_release itaskscheduler_get_itask itask_save itasktrigger_configure itaskscheduler_new itask_edit_dialog itaskscheduler_get_target_system itaskscheduler_release itaskscheduler_task_exists itaskscheduler_delete_task mstask_create itask_end itaskscheduler_get_tasks itasktrigger_get_info itask_get_itasktrigger itask_run itask_delete_itasktrigger itaskscheduler_set_target_system itask_new_itasktrigger itask_configure itaskscheduler_new_itask itask_get_itasktrigger_count itask_get_itasktrigger_string itask_get_info itask_get_runtimes_within_interval}}]
package ifneeded twapi_multimedia 4.0a16 [list twapi::package_setup $dir twapi_multimedia 4.0a16 load {} {::twapi {stop_sound play_sound beep}}]
package ifneeded twapi_namedpipe 4.0a16 [list twapi::package_setup $dir twapi_namedpipe 4.0a16 load {} {::twapi {namedpipe_client namedpipe_server impersonate_namedpipe_client}}]
package ifneeded twapi_network 4.0a16 [list twapi::package_setup $dir twapi_network 4.0a16 load {} {::twapi {get_netif_info get_netif_count _format_route get_routing_table flush_arp_tables flush_arp_table address_to_hostname get_network_info flush_network_name_cache get_netif_indices get_netif6_info hostname_to_address get_udp_connections _ipversion_to_af get_netif6_count get_ipaddr_version get_outgoing_interface get_netif6_indices get_arp_table get_ip_addresses resolve_address _get_all_tcp _hostname_resolve_handler ipaddr_to_hwaddr port_to_service get_tcp_connections _get_all_udp get_system_ipaddrs get_route getaddrinfo getnameinfo _address_resolve_handler hwaddr_to_ipaddr _hosts_to_ip_addrs _hwaddr_binary_to_string terminate_tcp_connections service_to_port _valid_ipaddr_format resolve_hostname}}]
package ifneeded twapi_nls 4.0a16 [list twapi::package_setup $dir twapi_nls 4.0a16 load {} {::twapi {extract_sublanguage_langid get_locale_info format_number _map_default_lcid_token get_system_default_lcid get_user_default_langid get_user_ui_langid extract_primary_langid get_system_langid map_code_page_to_name get_system_default_langid get_lcid get_user_langid map_langid_to_name format_currency get_user_default_lcid get_system_ui_langid _verify_number_format}}]
package ifneeded twapi_os 4.0a16 [list twapi::package_setup $dir twapi_os 4.0a16 load {} {::twapi {get_processor_count get_os_info get_os_description get_computer_netbios_name get_system_parameters_info abort_system_shutdown get_memory_info shutdown_system get_system_info get_active_processor_mask set_system_parameters_info get_primary_domain_info get_primary_domain_controller get_computer_name find_domain_controller get_system_uptime get_processor_info suspend_system}}]
package ifneeded twapi_pdh 4.0a16 [list twapi::package_setup $dir twapi_pdh 4.0a16 load {} {::twapi {get_perf_thread_counter_paths get_perf_process_id_path collect_perf_query_data connect_perf _pdh_fmt_sym_to_val get_perf_process_counter_paths close_perf_query get_perf_object_items add_perf_counter get_counter_path_value get_hcounter_value get_perf_instance_counter_paths _localize_perf_counter _refresh_perf_objects get_perf_thread_id_path _perf_detail_sym_to_val remove_perf_counter validate_perf_counter_path get_perf_counter_paths make_perf_counter_path get_unique_counter_path get_perf_values_from_metacounter_info parse_perf_counter_path open_perf_query get_perf_objects _make_counter_path_list get_perf_processor_counter_paths}}]
package ifneeded twapi_process 4.0a16 [list twapi::package_setup $dir twapi_process 4.0a16 load {} {::twapi {is_idle_pid wow64_process set_priority_class set_process_virtualization get_current_process_id process_in_administrators get_process_handle is_system_pid end_process process_waiting_for_input resume_thread get_process_exit_code get_thread_info get_process_ids get_process_name get_process_integrity get_module_handle_from_address get_device_drivers set_thread_relative_priority _map_console_color _token_info_helper get_process_parent virtualized_process get_priority_class get_process_thread_ids get_thread_handle get_thread_relative_priority _token_set_helper get_module_handle get_pid_from_handle set_process_integrity create_process get_process_info get_process_elevation get_process_modules get_process_path suspend_thread get_multiple_process_info _get_wts_pids get_thread_parent_process_id get_process_commandline get_current_thread_id _get_process_name_path_helper process_exists}}]
package ifneeded twapi_rds 4.0a16 [list twapi::package_setup $dir twapi_rds 4.0a16 load {} {::twapi {rds_get_session_oemid rds_get_session_appname rds_get_session_protocol rds_get_session_clientdir rds_get_session_productid rds_get_session_clientname rds_get_session_clientbuild rds_disconnect_session rds_get_session_intialdir rds_get_session_state rds_enumerate_sessions rds_query_session_information rds_open_server rds_send_message rds_logoff_session rds_get_session_winsta rds_get_session_userdomain rds_get_session_user rds_get_session_initialprogram rds_get_session_clienthwid rds_get_session_id rds_close_server}}]
package ifneeded twapi_resource 4.0a16 [list twapi::package_setup $dir twapi_resource 4.0a16 load {} {::twapi {strings_to_resource_stringblock load_bitmap_from_file _load_image_from_system begin_resource_update free_bitmap enumerate_resource_languages load_icon_from_file load_bitmap_from_system load_icon_from_module resource_stringblock_to_strings load_cursor_from_file load_cursor_from_module delete_resource end_resource_update enumerate_resource_types read_resource_string resource_stringid_to_stringblockid load_bitmap_from_module _load_image enumerate_resource_names write_bmp_file get_file_version_resource extract_resources update_resource free_cursor read_resource load_icon_from_system load_cursor_from_system free_icon}}]
package ifneeded twapi_service 4.0a16 [list twapi::package_setup $dir twapi_service 4.0a16 load {} {::twapi {_service_handler_unsafe pause_service _service_handler set_service_configuration get_service_internal_name service_exists _parse_service_accept_controls _service_fn_wrapper _map_starttype_sym start_service update_service_status control_service _map_errorcontrol_code get_service_display_name get_multiple_service_status interrogate_service _map_servicetype_code _service_background_error _map_errorcontrol_sym get_service_status continue_service get_dependent_service_status stop_service get_service_state delete_service _map_starttype_code _report_service_status _call_scm_within_waithint create_service get_service_configuration run_as_service _map_servicetype_sym}}]
package ifneeded twapi_share 4.0a16 [list twapi::package_setup $dir twapi_share 4.0a16 load {} {::twapi {_share_type_symbols_to_code find_lm_connections get_lm_session_info _format_lm_open_file connect_share _make_unc_computername new_share _map_USE_INFO end_lm_sessions get_client_shares get_client_share_info get_lm_open_file_info disconnect_share _share_type_code_to_symbols delete_share get_connected_shares get_shares set_share_info _calc_minimum_session_info_level get_share_info find_lm_open_files _format_lm_session find_lm_sessions close_lm_open_file}}]
package ifneeded twapi_shell 4.0a16 [list twapi::package_setup $dir twapi_shell 4.0a16 load {} {::twapi {file_properties_dialog invoke_url_shortcut shell_execute write_shortcut read_url_shortcut recycle_file write_url_shortcut get_shell_folder read_shortcut shell_object_properties_dialog systemtray} ::twapi::systemtray {_taskbar_restart_handler _icon_handler modifyicon _make_NOTIFYICONW addicon removeicon}}]
package ifneeded twapi_storage 4.0a16 [list twapi::package_setup $dir twapi_storage 4.0a16 load {} {::twapi {get_drive_info _drive_rootpath normalize_device_rooted_path _is_unc find_volumes find_logical_drives get_mounted_volume_name set_file_times set_drive_label unmount_volume get_logical_drives begin_filesystem_monitor volume_properties_dialog find_volume_mount_points _filesystem_monitor_handler get_file_times get_volume_mount_point_for_path get_volume_info get_drive_type map_drive_local mount_volume user_drive_space_available cancel_filesystem_monitor unmap_drive_local}}]
package ifneeded twapi_ui 4.0a16 [list twapi::package_setup $dir twapi_ui 4.0a16 load {} {::twapi {get_toplevel_windows minimize_window get_desktop_window window_is_child show_owned_popups get_descendent_windows get_first_sibling_window get_active_window_for_thread window_exists get_first_child set_desktop_wallpaper get_caret_location set_window_zorder _same_window get_parent_window _get_message_only_windows set_focus get_display_monitor_info flash_window_caption find_windows set_foreground_window hide_window _format_monitor_info get_window_client_area_size redraw_window move_window get_display_monitors get_window_id get_window_at_location set_window_text show_window _format_display_monitor maximize_window get_display_monitor_from_window get_window_process _show_theme_syscolors get_display_size get_active_window_for_current_thread close_window get_display_devices _return_window get_window_userdata get_window_coordinates get_window_class redraw_window_frame get_window_style resize_window _show_theme_colors get_owner_window _style_mask_to_symbols configure_window_titlebar get_desktop_workarea get_child_windows get_display_monitor_from_point arrange_icons flash_window window_visible set_window_style _show_window _format_display_device hide_caret show_caret _get_gui_thread_info restore_window get_multiple_display_monitor_info set_caret_location get_desktop_wallpaper get_window_text tkpath_to_hwnd get_last_sibling_window invalidate_screen_region get_window_real_class window_maximized get_window_thread set_active_window_for_thread get_next_sibling_window get_shell_window get_foreground_window _show_theme_fonts get_caret_blink_time window_minimized window_unicode_enabled get_focus_window_for_thread set_caret_blink_time get_display_monitor_from_rect hide_owned_popups get_color_depth get_prev_sibling_window get_window_application}}]
package ifneeded twapi_input 4.0a16 [list twapi::package_setup $dir twapi_input 4.0a16 load {} {::twapi {block_input send_input_text enable_window_input send_keys move_mouse _init_vk_map turn_mouse_wheel send_input unblock_input get_input_idle_time _hotkeysyms_to_vk click_mouse_button window_input_enabled get_mouse_location disable_window_input register_hotkey _parse_send_keys _hotkey_handler unregister_hotkey}}]
package ifneeded twapi_winsta 4.0a16 [list twapi::package_setup $dir twapi_winsta 4.0a16 load {} {::twapi {set_process_window_station close_desktop_handle find_desktops get_current_window_station_handle close_window_station_handle get_desktop_handle get_window_station_handle find_window_stations}}]
package ifneeded twapi_wmi 4.0a16 [list twapi::package_setup $dir twapi_wmi 4.0a16 load {} {::twapi {_wmi wmi_collect_classes wmi_root wmi_extract_systemproperty wmi_extract_class wmi_extract_method wmi_extract_property wmi_extract_qualifier}}]
package ifneeded twapi 4.0a16 {
  package require twapi_base 4.0a16
  package require metoo 4.0a16
  package require twapi_com 4.0a16
  package require twapi_msi 4.0a16
  package require twapi_power 4.0a16
  package require twapi_printer 4.0a16
  package require twapi_synch 4.0a16
  package require twapi_security 4.0a16
  package require twapi_account 4.0a16
  package require twapi_apputil 4.0a16
  package require twapi_clipboard 4.0a16
  package require twapi_console 4.0a16
  package require twapi_crypto 4.0a16
  package require twapi_device 4.0a16
  package require twapi_etw 4.0a16
  package require twapi_eventlog 4.0a16
  package require twapi_mstask 4.0a16
  package require twapi_multimedia 4.0a16
  package require twapi_namedpipe 4.0a16
  package require twapi_network 4.0a16
  package require twapi_nls 4.0a16
  package require twapi_os 4.0a16
  package require twapi_pdh 4.0a16
  package require twapi_process 4.0a16
  package require twapi_rds 4.0a16
  package require twapi_resource 4.0a16
  package require twapi_service 4.0a16
  package require twapi_share 4.0a16
  package require twapi_shell 4.0a16
  package require twapi_storage 4.0a16
  package require twapi_ui 4.0a16
  package require twapi_input 4.0a16
  package require twapi_winsta 4.0a16
  package require twapi_wmi 4.0a16

  package provide twapi 4.0a16
}
