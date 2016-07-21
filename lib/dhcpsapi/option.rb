module DhcpsApi
=begin
  typedef enum _DHCP_OPTION_TYPE {
    DhcpUnaryElementTypeOption,
    DhcpArrayTypeOption
  } DHCP_OPTION_TYPE, *LPDHCP_OPTION_TYPE;
=end
  class DHCP_OPTION_TYPE
    DhcpUnaryElementTypeOption = 0
    DhcpArrayTypeOption = 1
  end

=begin
  typedef struct _DHCP_OPTION {
    DHCP_OPTION_ID   OptionID;
    LPWSTR           OptionName;
    LPWSTR           OptionComment;
    DHCP_OPTION_DATA DefaultValue;
    DHCP_OPTION_TYPE OptionType;
  } DHCP_OPTION, *LPDHCP_OPTION;
=end
  class DHCP_OPTION < DHCPS_Struct
    layout :option_id, :uint32,
           :option_name, :pointer,
           :option_comment, :pointer,
           :default_value, DHCP_OPTION_DATA,
           :option_type, :uint32 # see DHCP_OPTION_TYPE

    ruby_struct_attr :to_string, :option_name, :option_comment
  end

=begin
typedef struct _DHCP_OPTION_ARRAY {
  DWORD         NumElements;
  LPDHCP_OPTION Options;
} DHCP_OPTION_ARRAY, *LPDHCP_OPTION_ARRAY;
=end
  class DHCP_OPTION_ARRAY < DHCPS_Struct
    layout :num_elements, :uint32,
           :options, :pointer

    def as_ruby_struct
      0.upto(self[:num_elements]-1).inject([]) do |all, offset|
        all << DHCP_OPTION.new(self[:options] + offset*DHCP_OPTION.size).as_ruby_struct
      end
    end
  end

=begin
  DWORD DhcpCreateOptionV5(
    _In_     LPWSTR         ServerIpAddress,
    _In_     DWORD          Flags,
    _In_     DHCP_OPTION_ID OptionId,
    _In_opt_ LPWSTR         ClassName,
    _In_opt_ LPWSTR         VendorName,
    _In_     LPDHCP_OPTION  OptionInfo
  );
=end
  attach_function :DhcpCreateOptionV5, [:pointer, :uint32, :uint32, :pointer, :pointer, :pointer], :uint32

=begin
  DWORD DhcpGetOptionInfoV5(
    _In_  LPWSTR         ServerIpAddress,
    _In_  DWORD          Flags,
    _In_  DHCP_OPTION_ID OptionID,
    _In_  LPWSTR         ClassName,
    _In_  LPWSTR         VendorName,
    _Out_ LPDHCP_OPTION  *OptionInfo
  );
=end
  attach_function :DhcpGetOptionInfoV5, [:pointer, :uint32, :uint32, :pointer, :pointer, :pointer], :uint32

=begin
  DWORD DhcpRemoveOptionV5(
    _In_ LPWSTR         ServerIpAddress,
    _In_ DWORD          Flags,
    _In_ DHCP_OPTION_ID OptionID,
    _In_ LPWSTR         ClassName,
    _In_ LPWSTR         VendorName
  );
=end
  attach_function :DhcpRemoveOptionV5, [:pointer, :uint32, :uint32, :pointer, :pointer], :uint32

=begin
  DWORD DhcpEnumOptionsV5(
    _In_    LPWSTR              ServerIpAddress,
    _In_    DWORD               Flags,
    _In_    LPWSTR              ClassName,
    _In_    LPWSTR              VendorName,
    _Inout_ DHCP_RESUME_HANDLE  *ResumeHandle,
    _In_    DWORD               PreferredMaximum,
    _Out_   LPDHCP_OPTION_ARRAY *Options,
    _Out_   DWORD               *OptionsRead,
    _Out_   DWORD               *OptionsTotal
  );
=end
  attach_function :DhcpEnumOptionsV5, [:pointer, :uint32, :pointer, :pointer, :pointer, :uint32, :pointer, :pointer, :pointer], :uint32

  module Option
    include CommonMethods

    def create_option(option_id, option_name, option_comment, option_type, is_array, vendor_name = nil, *default_values)
      is_vendor = vendor_name.nil? ? 0 : DhcpsApi::DHCP_FLAGS_OPTION_IS_VENDOR
      option_info = DhcpsApi::DHCP_OPTION.new
      option_info[:option_id] = option_id
      option_info[:option_name] = FFI::MemoryPointer.from_string(to_wchar_string(option_name))
      option_info[:option_comment] = FFI::MemoryPointer.from_string(to_wchar_string(option_comment))
      option_info[:option_type] = is_array ? DhcpsApi::DHCP_OPTION_TYPE::DhcpArrayTypeOption : DhcpsApi::DHCP_OPTION_TYPE::DhcpUnaryElementTypeOption
      option_info[:default_value].from_array(option_type, default_values)

      error = DhcpsApi.DhcpCreateOptionV5(to_wchar_string(server_ip_address),
                                              is_vendor,
                                              option_id,
                                              nil,
                                              vendor_name.nil? ? nil : FFI::MemoryPointer.from_string(to_wchar_string(vendor_name)),
                                              option_info.pointer)
      raise DhcpsApi::Error.new("Error creating option.", error) if error != 0

      option_info.as_ruby_struct
    end

    def get_option(option_id, vendor_name = nil)
      is_vendor = vendor_name.nil? ? 0 : DhcpsApi::DHCP_FLAGS_OPTION_IS_VENDOR
      option_info_ptr_ptr = FFI::MemoryPointer.new(:pointer)

      error = DhcpsApi::DhcpGetOptionInfoV5(to_wchar_string(server_ip_address),
                                                is_vendor,
                                                option_id,
                                                nil,
                                                vendor_name.nil? ? nil : FFI::MemoryPointer.from_string(to_wchar_string(vendor_name)),
                                                option_info_ptr_ptr)
      if is_error?(error)
        unless (option_info_ptr_ptr.null? || (to_free = option_info_ptr_ptr.read_pointer).null?)
          free_memory(DhcpsApi::DHCP_OPTION.new(to_free))
        end
        raise DhcpsApi::Error.new("Error retrieving option information.", error)
      end

      option_info = DhcpsApi::DHCP_OPTION.new(option_info_ptr_ptr.read_pointer)
      to_return = option_info.as_ruby_struct
      free_memory(option_info)

      to_return
    end

    def delete_option(option_id, vendor_name = nil)
      error = DhcpsApi::DhcpRemoveOptionV5(to_wchar_string(server_ip_address),
                                               vendor_name.nil? ? 0 : DhcpsApi::DHCP_FLAGS_OPTION_IS_VENDOR,
                                               option_id,
                                               nil,
                                               vendor_name.nil? ? nil : FFI::MemoryPointer.from_string(to_wchar_string(vendor_name)))
      raise DhcpsApi::Error.new("Error deleting option.", error) if error != 0
    end

    def list_options(class_name = nil, vendor_name = nil)
      items, _ = retrieve_items(:dhcp_enum_options_v5, class_name, vendor_name, 1024, 0)
      items
    end

    def dhcp_enum_options_v5(class_name, vendor_name, preferred_maximum, resume_handle)
      resume_handle_ptr = FFI::MemoryPointer.new(:uint32).put_uint32(0, resume_handle)
      options_ptr_ptr = FFI::MemoryPointer.new(:pointer)
      options_read_ptr = FFI::MemoryPointer.new(:uint32).put_uint32(0, 0)
      options_total_ptr = FFI::MemoryPointer.new(:uint32).put_uint32(0, 0)
      is_vendor = vendor_name.nil? ? 0 : DhcpsApi::DHCP_FLAGS_OPTION_IS_VENDOR

      error = DhcpsApi.DhcpEnumOptionsV5(to_wchar_string(server_ip_address),
                                             is_vendor,
                                             class_name.nil? ? nil : FFI::MemoryPointer.from_string(to_wchar_string(class_name)) ,
                                             vendor_name.nil? ? nil : FFI::MemoryPointer.from_string(to_wchar_string(vendor_name)),
                                             resume_handle_ptr,
                                             preferred_maximum,
                                             options_ptr_ptr,
                                             options_read_ptr,
                                             options_total_ptr)
      return empty_response if error == 259
      if is_error?(error)
        unless (options_ptr_ptr.null? || (to_free = options_ptr_ptr.read_pointer).null?)
          free_memory(DhcpsApi::DHCP_OPTION_ARRAY.new(to_free))
        end
        raise DhcpsApi::Error.new("Error retrieving options.", error)
      end

      options_array = DhcpsApi::DHCP_OPTION_ARRAY.new(options_ptr_ptr.read_pointer)
      to_return = options_array.as_ruby_struct

      free_memory(options_array)
      resume_handle = resume_handle_ptr.get_uint32(0) > 0 ? resume_handle_ptr.get_uint32(0) - 1 : 0
      [to_return, resume_handle, options_read_ptr.get_uint32(0), options_total_ptr.get_uint32(0)]
    end
  end
end