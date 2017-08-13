# cyberman

A web-ui for registering domains, written in modern Perl 5 with Dancer.

## Current state

Cyberman was designed to serve .cyb, and the codebase reflects this. Although it is capable of serving any domain, the default config is for .cyb, and the templates/stylesheet are oriented towards cybNIC. We're interested in producing a 'generic' style; if you'd like to contribute to this, do get in touch.

## Features

 * Registering domains
 * Unregistering domains

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

## Questions, fan mail, etc

Feel free to join `#cyb` on `irc.cyberia.is`!
