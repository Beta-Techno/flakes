# Netbox service module
{ config, pkgs, lib, ... }:

{
  # Netbox OCI container
  virtualisation.oci-containers.containers.netbox = {
    image = "netboxcommunity/netbox:v4.0.0";
    ports = [ "8080:8080" ];
    
    volumes = [
      "/var/lib/netbox/config:/etc/netbox/config:ro"
      "/var/lib/netbox/media:/opt/netbox/netbox/media:rw"
      "/var/lib/netbox/static:/opt/netbox/netbox/static:rw"
    ];
    
    environment = {
      TZ = "UTC";
      DB_HOST = "localhost";
      DB_PORT = "5432";
      DB_NAME = "netbox";
      DB_USER = "netbox";
      DB_PASSWORD = "$__file{/var/lib/netbox/db-password}";
      REDIS_HOST = "localhost";
      REDIS_PORT = "6379";
      REDIS_PASSWORD = "$__file{/var/lib/netbox/redis-password}";
      SECRET_KEY = "$__file{/var/lib/netbox/secret-key}";
    };
    
    extraOptions = [
      "--restart=unless-stopped"
      "--network=host"
    ];
  };

  # Netbox configuration
  environment.etc."netbox/config.py".text = ''
    import os
    import sys
    
    # Database configuration
    DATABASE = {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME', 'netbox'),
        'USER': os.environ.get('DB_USER', 'netbox'),
        'PASSWORD': os.environ.get('DB_PASSWORD', ''),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', '5432'),
        'CONN_MAX_AGE': 300,
    }
    
    # Redis configuration
    REDIS = {
        'tasks': {
            'HOST': os.environ.get('REDIS_HOST', 'localhost'),
            'PORT': int(os.environ.get('REDIS_PORT', 6379)),
            'PASSWORD': os.environ.get('REDIS_PASSWORD', ''),
            'DATABASE': 0,
            'SSL': False,
        },
        'caching': {
            'HOST': os.environ.get('REDIS_HOST', 'localhost'),
            'PORT': int(os.environ.get('REDIS_PORT', 6379)),
            'PASSWORD': os.environ.get('REDIS_PASSWORD', ''),
            'DATABASE': 1,
            'SSL': False,
        }
    }
    
    # Secret key
    SECRET_KEY = os.environ.get('SECRET_KEY', '')
    
    # Allowed hosts
    ALLOWED_HOSTS = ['*']
    
    # Debug mode
    DEBUG = False
    
    # Time zone
    TIME_ZONE = 'UTC'
    
    # Language
    LANGUAGE_CODE = 'en-us'
    USE_I18N = True
    USE_TZ = True
    
    # Static files
    STATIC_ROOT = '/opt/netbox/netbox/static'
    MEDIA_ROOT = '/opt/netbox/netbox/media'
    
    # Logging
    LOGGING = {
        'version': 1,
        'disable_existing_loggers': False,
        'handlers': {
            'file': {
                'level': 'INFO',
                'class': 'logging.FileHandler',
                'filename': '/var/log/netbox/netbox.log',
            },
        },
        'loggers': {
            'netbox': {
                'handlers': ['file'],
                'level': 'INFO',
                'propagate': True,
            },
        },
    }
  '';

  # Create Netbox directories
  systemd.tmpfiles.rules = [
    "d /var/lib/netbox 0755 netbox netbox"
    "d /var/lib/netbox/config 0755 netbox netbox"
    "d /var/lib/netbox/media 0755 netbox netbox"
    "d /var/lib/netbox/static 0755 netbox netbox"
    "d /var/log/netbox 0755 netbox netbox"
  ];

  # System packages
  environment.systemPackages = with pkgs; [
    netbox
  ];
}
