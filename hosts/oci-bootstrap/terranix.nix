{ config, lib, ... }:
let
  namespace = lib.tfRef "var.namespace";
  compartment_id = lib.tfRef "var.compartment_ocid";
in
{
  myTerranix.providers.oracle.enable = true;

  module.system-build = {
    source = "github.com/nix-community/nixos-anywhere//terraform/nix-build";
    attribute = "../../.#packages.aarch64-linux.oci-bootstrap-image";
  };

  data.oci_core_compute_global_image_capability_schemas.global_schemas = { };

  resource = {
    oci_objectstorage_bucket.nixos_bucket = {
      inherit namespace compartment_id;
      name = "nixos-images";
    };

    oci_objectstorage_object.nixos_image = {
      bucket = lib.tfRef "oci_objectstorage_bucket.nixos_bucket.name";
      inherit namespace;
      object = "nixos-aarch64.qcow2";
      source = lib.tfRef "module.system-build.result.out";

      depends_on = [
        "oci_objectstorage_bucket.nixos_bucket"
      ];
    };

    oci_core_image.nixos = {
      inherit compartment_id;
      display_name = "NixOS ARM64";

      image_source_details = {
        source_type = "objectStorageTuple";
        namespace_name = namespace;
        bucket_name = lib.tfRef "oci_objectstorage_bucket.nixos_bucket.name";
        object_name = config.resource.oci_objectstorage_object.nixos_image.object;
      };

      launch_mode = "PARAVIRTUALIZED";

      timeouts = {
        create = "60m";
      };

      depends_on = [
        "oci_objectstorage_object.nixos_image"
        "oci_objectstorage_bucket.nixos_bucket"
      ];
    };

    oci_core_shape_management.nixos_a1_compat = {
      inherit compartment_id;
      image_id = lib.tfRef "oci_core_image.nixos.id";
      shape_name = "VM.Standard.A1.Flex";

      depends_on = [ "oci_core_image.nixos" ];
    };

    oci_core_compute_image_capability_schema.nixos_caps = {
      inherit compartment_id;
      image_id = lib.tfRef "oci_core_image.nixos.id";

      compute_global_image_capability_schema_version_name = lib.tfRef "data.oci_core_compute_global_image_capability_schemas.global_schemas.compute_global_image_capability_schemas[0].current_version_name";

      schema_data =
        let
          encode =
            attrs:
            builtins.toJSON (
              {
                descriptorType = "enumstring";
                source = "IMAGE";
              }
              // attrs
            );
        in
        {
          "Compute.Firmware" = encode {
            defaultValue = "UEFI_64";
            values = [ "UEFI_64" ];
          };

          "Compute.LaunchMode" = encode {
            defaultValue = "PARAVIRTUALIZED";
            values = [
              "PARAVIRTUALIZED"
              "EMULATED"
              "CUSTOM"
              "NATIVE"
            ];
          };

          "Storage.BootVolumeType" = encode {
            defaultValue = "PARAVIRTUALIZED";
            values = [
              "PARAVIRTUALIZED"
              "ISCSI"
              "SCSI"
              "IDE"
              "NVME"
            ];
          };

          "Network.AttachmentType" = encode {
            defaultValue = "PARAVIRTUALIZED";
            values = [
              "PARAVIRTUALIZED"
              "E1000"
              "VFIO"
              "VDPA"
            ];
          };
        };
    };
  };
}
