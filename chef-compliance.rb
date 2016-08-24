# THIS FILE WILL BE OVERWRITTEN ON CONTAINER START.  Please create a
# new file named `chef-compliance-local.rb` for custom settings.

_local = File.join(File.dirname(__FILE__), 'chef-compliance-local.rb')
instance_eval(File.read(_local), _local) if File.exist?(_local)
