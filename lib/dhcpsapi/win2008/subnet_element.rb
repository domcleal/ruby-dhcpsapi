module DhcpsApi::Win2008
  module SubnetElement
    extend FFI::Library
    ffi_lib 'dhcpsapi'
    ffi_convention :stdcall

=begin
  DWORD DhcpAddSubnetElementV4(
    _In_ DHCP_CONST WCHAR                       *ServerIpAddress,
    _In_ DHCP_IP_ADDRESS                        SubnetAddress,
    _In_ DHCP_CONST DHCP_SUBNET_ELEMENT_DATA_V4 *AddElementInfo
  );
=end
    attach_function :DhcpAddSubnetElementV4, [:pointer, :uint32, :pointer], :uint32

=begin
  DWORD DHCP_API_FUNCTION DhcpRemoveSubnetElementV4(
    _In_ DHCP_CONST WCHAR                       *ServerIpAddress,
    _In_ DHCP_IP_ADDRESS                        SubnetAddress,
    _In_ DHCP_CONST DHCP_SUBNET_ELEMENT_DATA_V4 *RemoveElementInfo,
    _In_ DHCP_FORCE_FLAG                        ForceFlag
  );
=end
    attach_function :DhcpRemoveSubnetElementV4, [:pointer, :uint32, :pointer, :uint32], :uint32

=begin
DWORD DHCP_API_FUNCTION DhcpEnumSubnetElementsV4(
  _In_    DHCP_CONST WCHAR                    *ServerIpAddress,
  _In_    DHCP_IP_ADDRESS                     SubnetAddress,
  _In_    DHCP_SUBNET_ELEMENT_TYPE            EnumElementType,
  _Inout_ DHCP_RESUME_HANDLE                  *ResumeHandle,
  _In_    DWORD                               PreferredMaximum,
  _Out_   LPDHCP_SUBNET_ELEMENT_INFO_ARRAY_V4 *EnumElementInfo,
  _Out_   DWORD                               *ElementsRead,
  _Out_   DWORD                               *ElementsTotal
);
=end
    attach_function :DhcpEnumSubnetElementsV4, [:pointer, :uint32, :uint32, :pointer, :uint32, :pointer, :pointer, :pointer], :uint32
  end
end

