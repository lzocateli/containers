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

### Creating a project

```
docker run -it --rm -w /app -v $(pwd):/app lzocateli/angular-cli ng new my-project-name
```

### Generating a component

```
docker run -it --rm -w /app -v $(pwd)/my-project-name:/app lzocateli/angular-cli ng g component sample-component
```

### Serving

```
docker run -it --rm -w /app -v $(pwd)/my-project-name:/app -p 4200:4200 lzocateli/angular-cli ng serve --host 0.0.0.0
```

## Credits

Credits for the CLI go for [the Angular CLI team](https://github.com/angular/angular-cli) 

Credits to [Alejandro Such ](https://github.com/alejandroSuch/angular-cli) who created the project that motivated me

Maintainer:
 - [Lincoln Zocateli](https://github.com/lzocateli)

## License

MIT
