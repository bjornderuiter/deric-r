# This class file is not called directly
class r::repo::debian(
    $manage_repo    = true,
    $package_source = 'r-project.org',
    $codename       = $::lsbdistcodename
  ) {

  if $caller_module_name != $module_name {
    warning("${name} is deprecated as a public API of the ${module_name} module and should no longer be directly included in the manifest.")
  }

  # 'downcase' is function from stdlib
  $os = downcase($::operatingsystem)

  anchor { 'r::apt_repo' : }

  include '::apt'

  if $manage_repo {
    case $package_source {
      'r-project.org': {
        case $os {
          'ubuntu': {
            apt::source { 'r-project':
              location    => "http://cran.r-project.org/bin/linux/${os}",
              # the '/' must be present, otherwise repo name is required
              release     => "${codename}/",
              repos       => '', # default repo is main (not present at cran)
              include_src => false,
              key         => 'E084DAB9',
              key_server  => 'keyserver.ubuntu.com',
              notify      => Exec['apt_get_update_for_r'],
            }
          }
          'debian': {
            case $codename {
              'wheezy': {
                $rel_name = 'wheezy-cran3'
              }
              'squeeze': {
                $rel_name = 'squeeze-cran3'
              }
            }

            apt::source { 'r-project':
              location    => "http://cran.r-project.org/bin/linux/${os}",
              # the '/' must be present, otherwise repo name is required
              release     => "${rel_name}/",
              repos       => '', # default repo is main (not present at cran)
              include_src => false,
              key         => '381BA480',
              key_server  => 'keys.gnupg.net',
              notify      => Exec['apt_get_update_for_r'],
            }
          }
          default: {
            fail("Module ${module_name} is not supported on ${::osfamily}, os: ${::operatingsystem}")
          }
        }
      }
      default: {}
    }

    exec { 'apt_get_update_for_r':
      command     => '/usr/bin/apt-get update',
      timeout     => 240,
      returns     => [ 0, 100 ],
      refreshonly => true,
      before      => Anchor['r::apt_repo'],
    }
  }
}
