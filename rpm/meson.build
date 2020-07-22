# Meson configuration file
#

r = run_command('date', '+%a %b %d %Y')
if r.returncode() == 0
  today = r.stdout().strip()
else
  today = 'Unknown'
endif

r = run_command('date', '+%Y%m%d')
if r.returncode() == 0
  short_today = r.stdout().strip()
else
  short_today = 'Unknown'
endif

r = run_command('git', 'rev-parse', '--verify', 'HEAD')
if r.returncode() == 0
  git_hash = r.stdout().strip()
else
  git_hash = 'Unknown'
endif

git_build = 0
if profile == 'development'
  git_build = 1
endif

conf_data = configuration_data()
conf_data.set('version', meson.project_version())
conf_data.set('project_url', PROJECT_URL)
conf_data.set('source_root', meson.source_root())
conf_data.set('build_root', meson.build_root())
conf_data.set('project_name', meson.project_name())
conf_data.set('spec_name', 'akira')
conf_data.set('today', today)
conf_data.set('git_hash', git_hash)
conf_data.set('short_today', short_today)
conf_data.set('git_build', git_build)

configure_file(input : 'akira.spec.in',
               output : 'akira.spec',
               configuration : conf_data)

configure_file(input : 'build.py.in',
               output : 'build.py',
               configuration : conf_data)
