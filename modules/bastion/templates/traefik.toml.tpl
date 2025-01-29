[entryPoints]
  [entryPoints.web]
    address = ":80"

[providers]
  [providers.file]
    filename = "/etc/traefik/dynamic_conf.toml"
    watch = true

[log]
  level = "DEBUG"

[api]
  dashboard = true
  insecure = true