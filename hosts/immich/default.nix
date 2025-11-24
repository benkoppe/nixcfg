{
  self,
  config,
  pkgs,
  ...
}:
let
  inherit (config.mySnippets) hostName;
  inherit (config.mySnippets.hosts.${hostName}) mediaLocation;
in
{
  myNixOS = {
    profiles.proxmox-lxc.enable = true;

    services.caddy =
      let
        inherit (config.services.immich) port;
      in
      {
        enable = true;
        virtualHosts = [
          {
            domain = "thekoppe.com";
            subdomain = "immich";
            inherit port;
          }
        ];
      };
  };

  environment.systemPackages = [
    pkgs.immich-cli
  ];

  users = {
    users.root.openssh.authorizedKeys.keyFiles = [
      "${self.inputs.secrets}/pve/lxc-bootstrap-key.pub"
    ];
    users.immich = {
      uid = 1000;
      extraGroups = [
        "video"
        "render"
      ];
    };
    groups.immich = {
      gid = 1000;
    };
  };

  services.immich = {
    enable = true;
    package = self.inputs.nixpkgs-immich-pr.legacyPackages.${pkgs.stdenv.hostPlatform.system}.immich;

    port = 2283;
    # openFirewall = true;
    inherit mediaLocation;

    accelerationDevices = null;

    settings = {
      backup = {
        database = {
          cronExpression = "0 02 * * *";
          enabled = true;
          keepLastAmount = 14;
        };
      };
      ffmpeg = {
        accel = "disabled";
        accelDecode = false;
        acceptedAudioCodecs = [
          "aac"
          "mp3"
          "libopus"
          "pcm_s16le"
        ];
        acceptedContainers = [
          "mov"
          "ogg"
          "webm"
        ];
        acceptedVideoCodecs = [
          "h264"
        ];
        bframes = -1;
        cqMode = "auto";
        crf = 23;
        gopSize = 0;
        maxBitrate = "0";
        preferredHwDevice = "auto";
        preset = "ultrafast";
        refs = 0;
        targetAudioCodec = "aac";
        targetResolution = "720";
        targetVideoCodec = "h264";
        temporalAQ = false;
        threads = 0;
        tonemap = "hable";
        transcode = "required";
        twoPass = false;
      };
      image = {
        colorspace = "p3";
        extractEmbedded = false;
        fullsize = {
          enabled = false;
          format = "jpeg";
          quality = 80;
        };
        preview = {
          format = "jpeg";
          quality = 80;
          size = 1440;
        };
        thumbnail = {
          format = "webp";
          quality = 80;
          size = 250;
        };
      };
      job = {
        backgroundTask = {
          concurrency = 5;
        };
        faceDetection = {
          concurrency = 2;
        };
        library = {
          concurrency = 5;
        };
        metadataExtraction = {
          concurrency = 5;
        };
        migration = {
          concurrency = 5;
        };
        notifications = {
          concurrency = 5;
        };
        search = {
          concurrency = 5;
        };
        sidecar = {
          concurrency = 5;
        };
        smartSearch = {
          concurrency = 2;
        };
        thumbnailGeneration = {
          concurrency = 3;
        };
        videoConversion = {
          concurrency = 1;
        };
      };
      library = {
        scan = {
          cronExpression = "0 0 * * *";
          enabled = true;
        };
        watch = {
          enabled = false;
        };
      };
      logging = {
        enabled = true;
        level = "log";
      };
      machineLearning = {
        enabled = true;
        clip = {
          enabled = true;
          modelName = "ViT-B-32__openai";
        };
        duplicateDetection = {
          enabled = true;
          maxDistance = {
          };
        };
        facialRecognition = {
          enabled = true;
          maxDistance = {
          };
          minFaces = 3;
          minScore = {
          };
          modelName = "buffalo_l";
        };
        ocr = {
          enabled = true;
          maxResolution = 736;
          minDetectionScore = 0.5;
          minRecognitionScore = 0.8;
          modelName = "PP-OCRv5_mobile";
        };
        urls = [
          "http://127.0.0.1:3003"
        ];
      };
      map = {
        darkStyle = "https://tiles.immich.cloud/v1/style/dark.json";
        enabled = true;
        lightStyle = "https://tiles.immich.cloud/v1/style/light.json";
      };
      metadata = {
        faces = {
          import = false;
        };
      };
      newVersionCheck = {
        enabled = true;
      };
      nightlyTasks = {
        clusterNewFaces = true;
        databaseCleanup = true;
        generateMemories = true;
        missingThumbnails = true;
        startTime = "00:00";
        syncQuotaUsage = true;
      };
      notifications = {
        smtp = {
          enabled = false;
          from = "Koppe Immich";
          replyTo = "koppe.development@gmail.com";
          transport = {
            host = "smtp.gmail.com";
            ignoreCert = false;
            password._secret = config.age.secrets.immich-smtp-pass.path;
            port = 587;
            username = "koppe.development@gmail.com";
          };
        };
      };
      oauth = {
        autoLaunch = true;
        autoRegister = true;
        buttonText = "Login with PocketID";
        clientId._secret = config.age.secrets.immich-oauth-client-id.path;
        clientSecret._secret = config.age.secrets.immich-oauth-secret.path;
        defaultStorageQuota = null;
        enabled = true;
        issuerUrl = "https://pocket.thekoppe.com";
        mobileOverrideEnabled = false;
        mobileRedirectUri = "";
        profileSigningAlgorithm = "none";
        roleClaim = "immich_role";
        scope = "openid email profile groups";
        signingAlgorithm = "RS256";
        storageLabelClaim = "preferred_username";
        storageQuotaClaim = "immich_quota";
        timeout = 30000;
        tokenEndpointAuthMethod = "client_secret_post";
      };
      passwordLogin = {
        enabled = false;
      };
      reverseGeocoding = {
        enabled = true;
      };
      server = {
        externalDomain = "https://immich.thekoppe.com";
        loginPageMessage = "";
        publicUsers = true;
      };
      storageTemplate = {
        enabled = true;
        hashVerificationEnabled = true;
        template = "{{y}}/{{MMMM}}/{{filename}}";
      };
      templates = {
        email = {
          albumInviteTemplate = "";
          albumUpdateTemplate = "";
          welcomeTemplate = "";
        };
      };
      theme = {
        customCss = "";
      };
      trash = {
        days = 30;
        enabled = true;
      };
      user = {
        deleteDelay = 7;
      };
    };
  };

  age.secrets =
    let
      inherit (config.services.immich) user group;
      common = secretFile: {
        file = secretFile;
        owner = user;
        inherit group;
        mode = "440";
      };
      secretsDir = "${self.inputs.secrets}/services/immich";
    in
    {
      immich-oauth-client-id = common "${secretsDir}/oauth-client-id.age";
      immich-oauth-secret = common "${secretsDir}/oauth-secret.age";
      immich-smtp-pass = common "${self.inputs.secrets}/services/smtp/koppe-development-password.age";
    };
}
