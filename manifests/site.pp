require boxen::environment
require homebrew

Exec {
  group       => 'staff',
  logoutput   => on_failure,
  user        => $boxen_user,

  path => [
    "${boxen::config::home}/rbenv/shims",
    "${boxen::config::home}/rbenv/bin",
    "${boxen::config::home}/rbenv/plugins/ruby-build/bin",
    "${boxen::config::home}/homebrew/bin",
    '/usr/bin',
    '/bin',
    '/usr/sbin',
    '/sbin'
  ],

  environment => [
    "HOMEBREW_CACHE=${homebrew::config::cachedir}",
    "HOME=/Users/${::boxen_user}"
  ]
}

File {
  group => 'staff',
  owner => $boxen_user
}

Package {
  provider => homebrew,
  require  => Class['homebrew'],
}

Repository {
  provider => git,
  extra    => [
    '--recurse-submodules'
  ],
  require  => File["${boxen::config::bindir}/boxen-git-credential"],
  config   => {
    'credential.helper' => "${boxen::config::bindir}/boxen-git-credential"
  }
}

Service {
  provider => ghlaunchd
}

Homebrew::Formula <| |> -> Package <| |>

node default {
  # core modules, needed for most things
  include git
  include hub

  # fail if FDE is not enabled
  if $::root_encrypted == 'no' {
    fail('Please enable full disk encryption and try again')
  }

  # node versions
  include nodejs::v0_6
  include nodejs::v0_8
  include nodejs::v0_10

  # default ruby versions
  ruby::version { '1.9.3': }
  ruby::version { '2.0.0': }
  ruby::version { '2.1.0': }
  ruby::version { '2.1.1': }

  file { "${boxen::config::srcdir}/our-boxen":
    ensure => link,
    target => $boxen::config::repodir
  }

  # Creating Orbitz env
  osx::recovery_message { 'If this Mac is found, please call 773-330-5322': }
  include osx::software_update
  include osx::no_network_dsstores
  include osx::disable_app_quarantine
  include osx::universal_access::enable_scrollwheel_zoom
  include osx::universal_access::cursor_size
  include osx::universal_access::ctrl_mod_zoom
  include osx::global::enable_keyboard_control_access
  include osx::global::expand_print_dialog
  include osx::global::expand_save_dialog 
  include osx::finder::empty_trash_securely
  include osx::finder::enable_quicklook_text_selection
  include osx::finder::show_all_on_desktop
  include osx::finder::show_hidden_files
  include osx::finder::unhide_library

  include osx::dock::autohide
  include osx::dock::clear_dock
  include osx::dock::dim_hidden_apps
  include osx::dock::icon_size

  boxen::osx_defaults {
    "Keyboard, Keyboard, Use all F1, F2, etc. keys as standard function keys":
      domain => NSGlobalDomain,
      key => "com.apple.keyboard.fnState",
      type => boolean,
      value => true;

    "Trackpad, Point & Click, Tap to click":
      host => currentHost,
      domain => NSGlobalDomain,
      key => "com.apple.mouse.tapBehavior",
      type => boolean,
      value => true;

   "Mouse, Tracking":
      domain => NSGlobalDomain,
      key => "com.apple.mouse.scaling",
      type => float,
      value => 2.0;
  }

  package { 'tmux':
    install_options => '--fresh'
  }

  include caffeine
  include chrome
  include dropbox
  include adium

  include java
  include eclipse::java

  include intellij

  class { 'ruby::global':
    version => '2.0.0'
  }

  ruby::gem { 
    "RExchange":
      gem     => 'rexchange',
      ruby    => '2.0.0' 
  }

  git::config::global { 
    'user.email':
      value  => 'jacob.tomaw@orbitz.com';

    'user.name': 
      value => 'Jacob Tomaw'
  }

  repository {
    '/Users/jtomaw/Development/sonar-wiki-sync':
      source   => 'git://git.orbitz.net/day/sonar-wiki-sync.git',
      provider => 'git';
  }

  repository {
    '/Users/jtomaw/Development/erma':
      source   => 'git@github.com:erma/erma.git',
      provider => 'git';
  }
}
