CONFIG = YAML::load(File.open("config.dist.yaml"))

begin 
  CONFIG.merge!(YAML::load(File.open("config.yaml")))
rescue Errno::ENOENT
  abort "FATAL: You must copy config.dist.yaml --> config.yaml and edit it appropriately before running `dashing start`."
end