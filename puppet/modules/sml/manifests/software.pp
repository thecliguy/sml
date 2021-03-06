class sml::software {
	include sml::sw_repositories

	$prerequisites = [
		'perl',
		'ubuntu-desktop',
		'inkscape',
		'kolourpaint4',
		'scribus',
		'gcompris',
		'krusader',
		'dolphin',
		'bkchem',
		'chemtool',
		'kalzium',
		'kstars',
		'openuniverse',
		'pymol',
		'gimp',
		'qalculate-gtk',
		'stellarium',
		'blinken',
		'celestia-gnome',
		'kalgebra',
		'kanagram',
		'kbruch',
		'khangman',
		'kig',
		'klavaro',
		'kmplot',
		'ktouch',
		'kturtle',
		'kwordquiz',
		'marble',
		'parley',
		'step',
		'tuxmath',
		'tuxpaint',
		#'nautilus-dropbox', # installation hangs during downloading from dropbox.com
		'tuxtype',
		'vym',
		'wine',
		'audacity',
		'openshot',
		'pitivi',
		'gperiodic',
		'vlc',
		'openssh-server',
		#'google-chrome-stable', # no longer available for ubuntu 12.04
		'opera',

		# language packs
		'myspell-en-gb',
		'myspell-en-au',
		'myspell-en-za',
		'myspell-cs',
		'mythes-en-us',
		'mythes-en-au',
		'mythes-cs',
		'hunspell-en-ca',
		'hyphen-en-us',
		'firefox-locale-en',
		'firefox-locale-cs',
		'gimp-help-en',
		'libreoffice-l10n-en-gb',
		'libreoffice-l10n-en-za',
		'libreoffice-l10n-cs',
		'libreoffice-help-en-gb',
		'libreoffice-help-cs',
		'openoffice.org-hyphenation',
		'poppler-data',
		'thunderbird-locale-en',
		'thunderbird-locale-en-us',
		'thunderbird-locale-en-gb',
		'thunderbird-locale-cs',
		'kde-l10n-engb',
		'kde-l10n-cs',
		'language-pack-kde-en',
		'language-pack-kde-cs',
		'language-pack-gnome-en',
		'language-pack-gnome-cs',
		'wamerican',
		'wbritish',
	]
	$params = {
		ensure => installed,
	}

	# Use the ensure_resources function to prevent conflicts
	ensure_resources(Package[$prerequisites], $params)

	Package[$prerequisites] <- Class['sml::sw_repositories']

	include sml::utils
}
