```
    _                      _                 ____ _     ___
   / \   _ __   __ _ _   _| | __ _ _ __     / ___| |   |_ _|
  / △ \ | '_ \ / _` | | | | |/ _` | '__|   | |   | |    | |
 / ___ \| | | | (_| | |_| | | (_| | |      | |___| |___ | |
/_/   \_\_| |_|\__, |\__,_|_|\__,_|_|       \____|_____|___|
               |___/
```

**package manager:** yarn<br/>
**docker hub:** https://hub.docker.com/r/lzocateli/angular-cli/

[![Docker Pulls](https://img.shields.io/docker/pulls/lzocateli/angular-cli.svg)](https://hub.docker.com/r/lzocateli/angular-cli/)
[![Docker Stars](https://img.shields.io/docker/stars/lzocateli/angular-cli.svg)](https://hub.docker.com/r/lzocateli/angular-cli/)

## Usage examples

This image has the same usage as Angular CLI (https://cli.angular.io/)

 - I use the container as an alias, create the alias below:
```
alias ng='podman run --rm -it -p 4200:4200 -v "$(pwd):/workspace" -w /workspace -v /tmp/ng:/tmp/ng lzocateli/angular-cli:17.3.8 ng "$@"'
```

## Use the `ng` commands normally

```
ng new my-project-name

ng g component sample-component

ng serve --host 0.0.0.0
```

## Credits

Credits for the CLI go for [the Angular CLI team](https://github.com/angular/angular-cli) 

Credits to [Alejandro Such ](https://github.com/alejandroSuch/angular-cli) who created the project that motivated me

Maintainer:
 - [Lincoln Zocateli](https://github.com/lzocateli)

## License

MIT
