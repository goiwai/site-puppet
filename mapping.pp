# A top-level variable to give a parametrised class storm::mapping as well as an internal class extraworks.
$pools = [
  # change this:
  {
    # parameters pre-defined in storm::puppet for pool-accounts:
    #   name: prefix of account name
    #   size: How many pool-accounts are created
    #   base_uid: UID starts number
    #   group: A primary group for these pool-accounts
    #   gid: GID for the group above
    #   vo: used in the field of comment in the /etc/passwd
    #       as well as grid-mapfile and groupmapfile
    'name'      => 'belleuser',
    'size'      => 40,
    'base_uid'  => 8100,
    'group'     => 'belleusers',
    'gid'       => 8100,
    'vo'        => 'belle',
    # extended parameters
    # groups: allows pool-accounts belonging multiple groups 
    # role_voms: allows supporting individual roles in the VOMS, like lcgadmin, production
    'groups'    => ['belleusers'],
  },
  {
    'name'      => 'belleprd',
    'size'      => 20,
    'base_uid'  => 8200,
    'group'     => 'belleprd',
    'gid'       => 8200,
    'vo'        => 'belle',
    'groups'    => ['belleprd', 'belleusers'],
    'role_voms' => 'production',
  },
  {
    'name'      => 'bellesgm',
    'size'      => 20,
    'base_uid'  => 8300,
    'group'     => 'bellesgm',
    'gid'       => 8300,
    'vo'        => 'belle',
    'groups'    => ['bellesgm', 'belleusers'],
    'role_voms' => 'lcgadmin',
  }
]

# A class inherited from storm::mapping for giving supplemental works, which enables pool-accounts belonging multiple groups as well as supporting individual roles in the VOMS, like lcgadmin, production.
class extraworks inherits storm::mapping {
  $::pools.each | $p | {
    if defined(Group[$p['group']]) {
      Group[$p['group']] {
        gid => $p['gid'],
      }
    } else {
      group { $p['group']:
        ensure => present,
        gid    => $p['gid'],
      }
    }

    range('1', $p['size']).each | $i | {
      $id_str = sprintf('%03d', $i)
      $name = "${p['name']}${id_str}"
      if is_hash($p) and has_key($p, 'role_voms') {
        $comment = "Mapped user for VO=${p['vo']}/Role=${p['role_voms']}"
      } else {
        $comment = "Mapped user for VO=${p['vo']}"
      }
      if defined(User[$name]) {
        User[$name] {
          comment => $comment,
          gid     => $p['gid'],
          groups  => $p['groups'],
          require +> Group[unique($p['groups'])],
        }
      } else {
        user { $name:
          ensure     => present,
          uid        => $p['base_uid'] + $i,
          gid        => $p['gid'],
          groups     => $p['groups'],
          comment    => $comment,
          managehome => true,
          require    => Group[unique($p['groups'])],
        }
      }
    }
  }

  $gridmapfile = '/etc/grid-security/grid-mapfile'
  # change this:
  $template_dir = '/change/this/directory/to/erb'
  # $gridmapfile_template='storm/etc/grid-security/grid-mapfile.erb'
  $gridmapfile_template = join([$template_dir, 'grid-mapfile.erb'], '/')

  if defined(File[$gridmapfile]) {
    File[$gridmapfile] {
      content => template($gridmapfile_template),
    }
  } else {
    file { $gridmapfile:
      ensure  => present,
      content => template($gridmapfile_template),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }
  }

  $groupmapfile = '/etc/grid-security/groupmapfile'
  # $groupmapfile_template='storm/etc/grid-security/groupmapfile.erb'
  $groupmapfile_template = join([$template_dir, 'groupmapfile.erb'], '/')

  if defined(File[$groupmapfile]) {
    File[$groupmapfile] {
      content => template($groupmapfile_template),
    }
  } else {
    file { $groupmapfile:
      ensure  => present,
      content => template($groupmapfile_template),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }
  }
}

# A class for calling a class storm::mapping with $pools, followed by a class extraworks.
class caller {
  include storm::users
  class { 'storm::mapping':
    pools => $::pools
  }
  include extraworks
}

include caller
