let
  networkModule =
    { lib, config, ... }:
    let
      compartment_id = config.data.external.compartment_ocid "result.secret";
    in
    {
      resource = {
        oci_core_virtual_network.main_vcn = {
          cidr_block = "10.1.0.0/16";
          inherit compartment_id;
          display_name = "mainVCN";
          dns_label = "mainvcn";
        };

        oci_core_subnet.prod_subnet = {
          cidr_block = "10.1.1.0/24";
          display_name = "prodSubnet";
          dns_label = "prodsubnet";
          security_list_ids = [ (lib.tfRef "oci_core_security_list.prod_security_list.id") ];
          inherit compartment_id;
          vcn_id = lib.tfRef "oci_core_virtual_network.main_vcn.id";
          route_table_id = lib.tfRef "oci_core_route_table.main_route_table.id";
          dhcp_options_id = lib.tfRef "oci_core_virtual_network.main_vcn.default_dhcp_options_id";
        };

        oci_core_internet_gateway.main_internet_gateway = {
          inherit compartment_id;
          display_name = "mainIG";
          vcn_id = lib.tfRef "oci_core_virtual_network.main_vcn.id";
        };

        oci_core_route_table.main_route_table = {
          inherit compartment_id;
          vcn_id = lib.tfRef "oci_core_virtual_network.main_vcn.id";
          display_name = "mainRouteTable";

          route_rules = {
            destination = "0.0.0.0/0";
            destination_type = "CIDR_BLOCK";
            network_entity_id = lib.tfRef "oci_core_internet_gateway.main_internet_gateway.id";
          };
        };

        oci_core_security_list.prod_security_list = {
          inherit compartment_id;
          vcn_id = lib.tfRef "oci_core_virtual_network.main_vcn.id";
          display_name = "mainSecurityList";

          egress_security_rules = {
            protocol = "6";
            destination = "0.0.0.0/0";
          };

          ingress_security_rules =
            let
              mkRule = tcp_options: {
                protocol = "6";
                source = "0.0.0.0/0";
                inherit tcp_options;
              };
            in
            [
              (mkRule {
                max = "22";
                min = "22";
              })

              (mkRule {
                max = "3000";
                min = "3000";
              })

              (mkRule {
                max = "3005";
                min = "3005";
              })

              (mkRule {
                max = "80";
                min = "80";
              })
            ];
        };
      };

      output.prod_subnet_id = {
        value = lib.tfRef "oci_core_subnet.prod_subnet.id";
        sensitive = true;
      };
    };
in
{
  my.terranix.oracle-network = {
    modules = [
      networkModule
    ];
    providers = [ "oracle" ];
  };
}
