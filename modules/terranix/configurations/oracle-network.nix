let
  networkModule =
    { lib, config, ... }:
    let
      tenancy_ocid = config.data.external.tenancy_ocid "result.secret";
      name = "terranix";
    in
    {
      resource = {
        oci_identity_compartment.this = {
          compartment_id = tenancy_ocid;
          description = name;
          name = builtins.replaceStrings [ " " ] [ "-" ] name;

          enable_delete = true;
        };

        oci_core_vcn.this = {
          compartment_id = lib.tfRef "oci_identity_compartment.this.id";

          cidr_blocks = [ "10.1.0.0/16" ];
          display_name = name;
          dns_label = "vcn";
        };

        oci_core_internet_gateway.this = {
          compartment_id = lib.tfRef "oci_identity_compartment.this.id";
          vcn_id = lib.tfRef "oci_core_vcn.this.id";

          display_name = lib.tfRef "oci_core_vcn.this.display_name";
        };

        oci_core_default_route_table.this = {
          manage_default_resource_id = lib.tfRef "oci_core_vcn.this.default_route_table_id";

          display_name = lib.tfRef "oci_core_vcn.this.display_name";

          route_rules = {
            network_entity_id = lib.tfRef "oci_core_internet_gateway.this.id";

            description = "Default route";
            destination = "0.0.0.0/0";
          };
        };

        oci_core_default_security_list.this = {
          manage_default_resource_id = lib.tfRef "oci_core_vcn.this.default_security_list_id";

          ingress_security_rules =
            let
              mkRule =
                { port, description }:
                {
                  protocol = "6"; # TCP
                  source = "0.0.0.0/0";
                  inherit description;
                  tcp_options = {
                    max = toString port;
                    min = toString port;
                  };
                };
            in
            [
              (mkRule {
                port = 22;
                description = "SSH traffic";
              })

              (mkRule {
                port = 80;
                description = "HTTP traffic";
              })

              (mkRule {
                port = 443;
                description = "HTTPS traffic";
              })
            ];

          egress_security_rules = {
            destination = "0.0.0.0/0";
            protocol = "all";
            description = "All traffic to any destination";
          };
        };

        oci_core_subnet.this = {
          cidr_block = lib.tfRef "oci_core_vcn.this.cidr_blocks.0";
          compartment_id = lib.tfRef "oci_identity_compartment.this.id";
          vcn_id = lib.tfRef "oci_core_vcn.this.id";

          display_name = lib.tfRef "oci_core_vcn.this.display_name";
          dns_label = "subnet";
        };

        oci_core_network_security_group.this = {
          compartment_id = lib.tfRef "oci_identity_compartment.this.id";
          vcn_id = lib.tfRef "oci_core_vcn.this.id";

          display_name = lib.tfRef "oci_core_vcn.this.display_name";
        };

        oci_core_network_security_group_security_rule.this = {
          direction = "INGRESS";
          network_security_group_id = lib.tfRef "oci_core_network_security_group.this.id";
          protocol = "1"; # ICMP
          source = "0.0.0.0/0";
        };
      };

      output.subnet_id = {
        value = lib.tfRef "oci_core_subnet.this.id";
        sensitive = true;
      };

      output.compartment_id = {
        value = lib.tfRef "oci_identity_compartment.this.id";
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
