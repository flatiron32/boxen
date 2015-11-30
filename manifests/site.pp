require boxen::environment
require homebrew
include brewcask # taps homebrew-cask / installs brew-cask

Exec {
  group       => 'staff',
  logoutput   => on_failure,
  user        => $boxen_user,

  path => [
    "${boxen::config::home}/rbenv/shims",
    "${boxen::config::home}/rbenv/bin",
    "${boxen::config::home}/rbenv/plugins/ruby-build/bin",
    "${boxen::config::homebrewdir}/bin",
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
homebrew::tap { 'homebrew/binary': }
class lastpass {
  package { 'LastPass':
    provider => 'pkgdmg',
    source   => 'https://download.lastpass.com/lpmacosx.dmg'
  }
}

class securID {
  package { 'SecurID':
    provider => 'pkgdmg',
    source   => 'ftp://ftp.emc.com/pub/agents/rsasecuridmac412.dmg'
  }
}

node default {
  # core modules, needed for most things
  include git
  include hub

  # fail if FDE is not enabled
  if $::root_encrypted == 'no' {
    fail('Please enable full disk encryption and try again')
  }

  # common, useful packages
  package {
    [
      'ack',
      'findutils',
      'gnu-tar',
      'go',
      'bash-completion',
      'python',
      'perforce'
    ]:
  }

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
  include osx::global::tap_to_click
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
  osx::dock::hot_corner { 'Top Left':
    action => 'Put Display to Sleep'
  }

  include osx::keyboard::capslock_to_control

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
      value => 0.875;

   "Trackpad, Tracking":
      domain => NSGlobalDomain,
      key => "com.apple.trackpad.scaling",
      type => float,
      value => 0.875;

   "Datetime format":
      domain => "com.apple.menuextra.clock",
      key => DateFormat,
      type => string,
      value => "EEE MMM d  H:mm:ss";
  }

  exec { 'start located':
    command => 'launchctl load -w /System/Library/LaunchDaemons/com.apple.locate.plist',
    user => root
  }

  package { 'tmux':
    install_options => '--fresh'
  }

  include bash
  include caffeine
  include chrome
  include dropbox

  include java
#  include eclipse::java

  include lastpass
  sudoers { 'installer':
    users    => $::boxen_user,
    hosts    => 'ALL',
    commands => [
      '(ALL) SETENV:NOPASSWD: /usr/sbin/installer',
    ],
    type     => 'user_spec',
  }

  package { 'avira-antivirus':
       provider => 'brewcask',
       require  => [ Homebrew::Tap['caskroom/cask'], Sudoers['installer'] ],
  }

  package { 'Pulse Smart Connect':
    provider => 'pkgdmg',
    source   => '/opt/boxen/repo/pkgs/SmartConnect.pkg'
  }

  git::config::global {
    'user.email':
      value  => 'jacob.tomaw@orbitz.com';

    'user.name':
      value => 'Jacob Tomaw';

    'color.ui':
      value => 'true';

    'push.default':
      value => 'simple';
  }

  repository {
    'my vim configs':
      source   => 'git@github.com:flatiron32/vimfiles.git',
      path     => '/Users/jtomaw/vimfiles',
      provider => 'git',
  }

  file { '/Users/jtomaw/.vimrc':
   ensure => 'link',
   target => '/Users/jtomaw/vimfiles/vimrc',
  }

  repository {
    'my dot files':
      source   => 'git@github.com:flatiron32/dotfiles.git',
      path     => '/Users/jtomaw/dotfiles',
      provider => 'git',
  }

  file { '/Users/jtomaw/.tmux.conf':
   ensure => 'link',
   target => '/Users/jtomaw/dotfiles/tmux.conf',
  }

  file { '/Users/jtomaw/.curlrc':
   ensure => 'link',
   target => '/Users/jtomaw/dotfiles/curlrc',
  }

  file { "/Users/jtomaw/Development":
    ensure => "directory",
  }
}
