{
  my.terranix.bird = {
    providers = [ "oracle" ];
    modules = [
      (
        { lib, config, ... }:
        let
          compartment_id = lib.tfRef "data.terraform_remote_state.oracle-network.outputs.compartment_id";
          tenancy_ocid = config.data.external.tenancy_ocid "result.secret";
        in
        {
          data.terraform_remote_state.oracle-network = {
            backend = "local";
            config.path = "../oracle-network/terraform.tfstate";
          };

          data.oci_identity_availability_domains.this = {
            compartment_id = tenancy_ocid;
          };

          resource.random_shuffle.this = {
            input = lib.tfRef "data.oci_identity_availability_domains.this.availability_domains[*].name";
            result_count = 1;
          };

          data.oci_core_images.this = {
            inherit compartment_id;
            shape = "VM.Standard.A1.Flex";
            operating_system = "Canonical Ubuntu";
          };

          resource.oci_core_instance.bird = {
            availability_domain = lib.tfRef "random_shuffle.this.result.0";
            inherit compartment_id;
            shape = "VM.Standard.A1.Flex";

            display_name = "bird";
            preserve_boot_volume = false;

            metadata = {
              ssh_authorized_keys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJgiH4Iu1GUe9Hd40cSnQH94EHj0VmjXdbsaBED2WMHT colmena";
            };

            agent_config = {
              are_all_plugins_disabled = true;
              is_management_disabled = true;
              is_monitoring_disabled = true;
            };

            shape_config = {
              ocpus = 4;
              memory_in_gbs = 24;
            };

            create_vnic_details = {
              assign_public_ip = true;
              display_name = "bird";
              hostname_label = "bird";
              nsg_ids = [
                (lib.tfRef "data.terraform_remote_state.oracle-network.outputs.nsg_id")
              ];
              subnet_id = lib.tfRef "data.terraform_remote_state.oracle-network.outputs.subnet_id";
            };

            source_details = {
              source_id = lib.tfRef ''data.oci_core_images.this.images.0.id'';
              source_type = "image";
            };

            lifecycle = {
              ignore_changes = [ "source_details" ];
            };
          };
        }
      )
    ];
  };
}
