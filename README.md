# Bananapus Ownable

A Bananapus variation on OpenZeppelin [`Ownable`](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol) to enable owner-based access control incorporating Juicebox project ownership and `JBPermissions`.

<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#repository-layout">Repository Layout</a></li>
    <li><a href="#usage">Usage</a></li>
  <ul>
    <li><a href="#install">Install</a></li>
    <li><a href="#develop">Develop</a></li>
    <li><a href="#scripts">Scripts</a></li>
    <li><a href="#tips">Tips</a></li>
    </ul>
  </ul>
  </ol>
</details>

This implementation adds:

- The ability to transfer contract ownership to a Juicebox Project instead of a specific address.
- The ability to grant other addresses `OnlyOwner` access using `JBPermissions`.
- Includes the `JBPermissioned` modifiers with support for OpenZeppelin [`Context`](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol). This enables optional meta-transaction support.

All features are backwards compatible with OpenZeppelin `Ownable`. This should be a drop-in replacement.

This repo contains 2 contracts:

1. If your contract does not already use `Ownable` or access controls, use `JBOwnable`.
2. If your contract extends a contract you cannot easily modify (e.g. a core dependency), and that contract inherits from OpenZeppelin `Ownable`, use `JBOwnableOverride`.

**NOTICE:** Only use `JBOwnableOverride` if you are overriding OpenZeppelin `Ownable` v4.7.0 or higher. Otherwise, `JBPermissions` functionality for `onlyOwner` will not work.

This repo was forked from [`jbx-protocol/juice-ownable`](https://github.com/jbx-protocol/juice-ownable).

_If you're having trouble understanding this contract, take a look at the [core protocol contracts](https://github.com/Bananapus/nana-core) and the [documentation](https://docs.juicebox.money/) first. If you have questions, reach out on [Discord](https://discord.com/invite/ErQYmth4dS)._

## Repository Layout

The root directory contains this README, an MIT license, and config files.

```
nana-ownable/
├── src/ - The Solidity source code for the contracts.
│   ├── JBOwnable.sol - Implements ownable access control for Juicebox projects/permissions.
│   ├── JBOwnableOverrides.sol - Abstract base contract used by JBOwnable.
│   ├── interfaces/ - Contract interfaces.
│   │   └── IJBOwnable.sol - Interface used by JBOwnableOverrides.
│   └── structs/ - Structs.
│       └── JBOwner.sol - Owner information for a given instance of JBOwnableOverrides.
├── test/ - Forge tests and testing utilities. Top level contains the main test files.
│   ├── handlers/ - Custom handlers for tests.
│   ├── mock/ - Mocking utilities.
│   ├── Ownable.t.sol - Main tests.
│   └── OwnableInvariantTests.t.sol - Invariant test.
└── .github/
    └── workflows/ - CI/CD workflows.
```

## Usage

### Install

How to install `nana-ownable` in another project.

For projects using `npm` to manage dependencies (recommended):

```bash
npm install @bananapus/ownable
```

For projects using `forge` to manage dependencies (not recommended):

```bash
forge install Bananapus/nana-ownable
```

If you're using `forge` to manage dependencies, add `@bananapus/ownable/=lib/nana-ownable/` to `remappings.txt`. You'll also need to install `nana-ownable`'s dependencies and add similar remappings for them.

### Develop

`nana-ownable` uses [npm](https://www.npmjs.com/) (version >=20.0.0) for package management and the [Foundry](https://github.com/foundry-rs/foundry) development toolchain for builds, tests, and deployments. To get set up, [install Node.js](https://nodejs.org/en/download) and install [Foundry](https://github.com/foundry-rs/foundry):

```bash
curl -L https://foundry.paradigm.xyz | sh
```

You can download and install dependencies with:

```bash
npm ci && forge install
```

If you run into trouble with `forge install`, try using `git submodule update --init --recursive` to ensure that nested submodules have been properly initialized.

Some useful commands:

| Command               | Description                                         |
| --------------------- | --------------------------------------------------- |
| `forge build`         | Compile the contracts and write artifacts to `out`. |
| `forge fmt`           | Lint.                                               |
| `forge test`          | Run the tests.                                      |
| `forge build --sizes` | Get contract sizes.                                 |
| `forge coverage`      | Generate a test coverage report.                    |
| `foundryup`           | Update foundry. Run this periodically.              |
| `forge clean`         | Remove the build artifacts and cache directories.   |

To learn more, visit the [Foundry Book](https://book.getfoundry.sh/) docs.

### Scripts

For convenience, several utility commands are available in `package.json`.

| Command                           | Description                            |
| --------------------------------- | -------------------------------------- |
| `npm test`                        | Run local tests.                       |
| `npm run test:fork`               | Run fork tests (for use in CI).        |
| `npm run coverage`           | Generate an LCOV test coverage report. |

### Tips

To view test coverage, run `npm run coverage` to generate an LCOV test report. You can use an extension like [Coverage Gutters](https://marketplace.visualstudio.com/items?itemName=ryanluker.vscode-coverage-gutters) to view coverage in your editor.

If you're using Nomic Foundation's [Solidity](https://marketplace.visualstudio.com/items?itemName=NomicFoundation.hardhat-solidity) extension in VSCode, you may run into LSP errors because the extension cannot find dependencies outside of `lib`. You can often fix this by running:

```bash
forge remappings >> remappings.txt
```

This makes the extension aware of default remappings.
