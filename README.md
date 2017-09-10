# cyberman

A web-ui for registering domains, written in modern Perl 5 with Dancer.

[issue tracker](https://git.fuwafuwa.moe/.cyb/cyberman/issues) | [detailed documentation](https://http.cat/404)

## Current state

Cyberman was designed to serve .cyb, however it can easily be configured to work with other TLDs. In addition to the default 'cyberpunk' stylesheet, there is a more generic 'light' stylesheet available.

## Features

 * Lightweight (~50M) server-side application, no database server required
 * Lightweight, intuitive web UI
 * Produces zone files which can be used by most DNS daemons

## Prerequisites

You need a recent Perl 5 version (5.14 or later should do) and some Perl modules. The best way to get these is to install cpanminus (`cpan App::cpanminus`, `curl https://cpanmin.us | perl - app::cpanminus`, or better still, use your package manager) and then run `cpanm --installdeps .` in the repo directory.

You also need SQLite3. To set up the database:

```
cd /path/to/cyberman
sqlite3 db.sqlite
(sqlite prompt) .read schema.sql
(sqlite prompt) .q
```

## Getting started

Once you've got all that, just run `plackup` to start a development server. You should probably inspect and alter `config.yml` first.

## Production!

You can deploy cyberman however you want, using Plack. Just make sure you pass `-E production` - this disables detailed error pages which could be a security risk, and tones down the logging.

## WHOIS server

The WHOIS server is written in Perl 6 (what do you think I am, a luddite?!) so you need to install that first, along with Panda, a package manager. Then, install the dependencies for the WHOIS server: `cat whoissrv/DEPENDENCIES | xargs -n 1 panda install`. Edit the values in the `whoissrv` section of `config.yml` and then start the server as root.

The WHOIS server is not supported on Windows at this time.

## Questions, fan mail, etc

Feel free to join `#cyb` on `irc.cyberia.is`!

### License

```
Cyberman: Web UI for domain registration
Copyright (C) 2017 "Al Beano" <albino@autistici.org>

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (see LICENSE file); if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
```
