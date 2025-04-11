## Demo Project Description

This project is a Swift implementation of [cowsay](https://en.wikipedia.org/wiki/Cowsay).

It demonstrates how to use [Sake](https://github.com/kattouf/Sake) to manage common workflows for such projects: code style checks, running tests, and building release artifacts.

To view the full list of available commands, run:

```sh
sake list
```

Each public command is fully self-contained and does not rely on any prior setup. It handles installing required tools and performs any necessary preparations automatically. This makes the project highly portable across different machines.

The project also showcases how Sake can be used in CI environments. In this case, it uses a GitHub Action to enforce code quality by running lint checks and tests through the [setup-sake](https://github.com/kattouf/setup-sake) action.

To manage required dependencies, it uses [mise](https://mise.jdx.dev), which is installed in a fixed version into a private directory within the project.
