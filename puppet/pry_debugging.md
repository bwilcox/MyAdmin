```
Install-Module RubyInstaller
Install-Ruby
```

Note, I had problems with the chocolatey version of ruby.  As a backup, download the ruby installer from rubyinstall.org and install it. Get the devkit version. Either way will need to update the environment path to include the ruby directory.

Download the modules you want to use for testing. Direct the modulepath somewhere you'll be able to find it again.

```
puppet module install dsc-securitypolicydsc --version 2.10.0-0-1 --modulepath ./modules
```

If there isn't a Gemfile in the module already, use:

```
source ENV['GEM_SOURCE'] || 'https://rubygems.org'
def location_for(place_or_version, fake_version = nil)
  git_url_regex = %r{\A(?<url>(https?|git)[:@][^#]*)(#(?<branch>.*))?}
  file_url_regex = %r{\Afile:\/\/(?<path>.*)}
  if place_or_version && (git_url = place_or_version.match(git_url_regex))
    [fake_version, { git: git_url[:url], branch: git_url[:branch], require: false }].compact
  elsif place_or_version && (file_url = place_or_version.match(file_url_regex))
    ['>= 0', { path: File.expand_path(file_url[:path]), require: false }]
  else
    [place_or_version, { require: false }]
  end
end
ruby_version_segments = Gem::Version.new(RUBY_VERSION.dup).segments
minor_version = ruby_version_segments[0..1].join('.')
group :development do
  gem "fast_gettext", '1.1.0',                                   require: false if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('2.1.0')
  gem "fast_gettext",                                            require: false if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.1.0')
  gem "json_pure", '<= 2.0.1',                                   require: false if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('2.0.0')
  gem "json", '= 1.8.1',                                         require: false if Gem::Version.new(RUBY_VERSION.dup) == Gem::Version.new('2.1.9')
  gem "json", '= 2.0.4',                                         require: false if Gem::Requirement.create('~> 2.4.2').satisfied_by?(Gem::Version.new(RUBY_VERSION.dup))
  gem "json", '= 2.1.0',                                         require: false if Gem::Requirement.create(['>= 2.5.0', '< 2.7.0']).satisfied_by?(Gem::Version.new(RUBY_VERSION.dup))
  gem "rb-readline", '= 0.5.5',                                  require: false, platforms: [:mswin, :mingw, :x64_mingw]
  gem "puppet-module-posix-default-r#{minor_version}", '~> 0.4', require: false, platforms: [:ruby]
  gem "puppet-module-posix-dev-r#{minor_version}", '~> 0.4',     require: false, platforms: [:ruby]
  gem "puppet-module-win-default-r#{minor_version}", '~> 0.4',   require: false, platforms: [:mswin, :mingw, :x64_mingw]
  gem "puppet-module-win-dev-r#{minor_version}", '~> 0.4',       require: false, platforms: [:mswin, :mingw, :x64_mingw]
end
puppet_version = ENV['PUPPET_GEM_VERSION']
facter_version = ENV['FACTER_GEM_VERSION']
hiera_version = ENV['HIERA_GEM_VERSION']
gems = {}
gems['puppet'] = location_for(puppet_version)
# If facter or hiera versions have been specified via the environment
# variables
gems['facter'] = location_for(facter_version) if facter_version
gems['hiera'] = location_for(hiera_version) if hiera_version
if Gem.win_platform? && puppet_version =~ %r{^(file:///|git://)}
  # If we're using a Puppet gem on Windows which handles its own win32-xxx gem
  # dependencies (>= 3.5.0), set the maximum versions (see PUP-6445).
  gems['win32-dir'] =      ['<= 0.4.9', require: false]
  gems['win32-eventlog'] = ['<= 0.6.5', require: false]
  gems['win32-process'] =  ['<= 0.7.5', require: false]
  gems['win32-security'] = ['<= 0.2.5', require: false]
  gems['win32-service'] =  ['0.8.8', require: false]
end
gems.each do |gem_name, gem_params|
  gem gem_name, *gem_params
end
# Evaluate Gemfile.local and ~/.gemfile if they exist
extra_gemfiles = [
  "#{__FILE__}.local",
  File.join(Dir.home, '.gemfile'),
]
extra_gemfiles.each do |gemfile|
  if File.file?(gemfile) && File.readable?(gemfile)
    eval(File.read(gemfile), binding)
  end
end
# vim: syntax=ruby
```


In the root folder, Gemfile.local

```
gem 'fuubar'
gem 'pry-byebug'
gem 'pry-stack_explorer'
gem 'pdk'
gem 'github_changelog_generator'
```

Set Gemfile line endings to LF if using VSCode.

Add the ruby bin directory to the environment path.

then

```
gem install bundler
bundle install
```

You may need to remove a Gemfile.lock file if it exists.

If the module does not have a Rakefile, add the standard Rakefile generated with pdk 
for new modules.

NOTE:  If the module has a rake file, you may need to add additional gems to 
the Gemfile.

```
bundle exec rake spec_prep
bundle exec puppet apply ./examples/test.pp --modulepath ./spec/fixtures/modules
```

Note:  Yay security, running the powershell scripts in the module may error.  Have to allow them to run.
Note:  I experienced problem getting things to work using bundle exec with puppet apply.  If I run puppet apply outside of bundler, it works as expected.

If the puppet agent is running, you will need to disable it to keep it from caching different module code then you want to test.

Then remove the cached module data in `C:\ProgramData\PuppetLabs\puppet`

to drop a pry on a line, you'll want to add:

```
require 'pry' ; binding.pry
```