# Juice Ownable

A Juicebox variation on OpenZeppelin [`Ownable`](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol) to enable owner-based access control incorporating Juicebox project ownership and `JBPermissions`.

This implementation adds:

- The ability to transfer contract ownership to a Juicebox Project instead of a specific address.
- The ability to grant other addresses `OnlyOwner` access using `JBPermissions`.
- Includes the `JBPermissioned` modifiers with support for OpenZeppelin [`Context`](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol). This enables optional meta-transaction support.

All features are backwards compatible with OpenZeppelin `Ownable`. This should be a drop-in replacement.

This repo contains 2 contracts:

1. If your contract does not already use `Ownable` or access controls, use `JBOwnable`.
2. If your contract extends a contract you cannot easily modify (e.g. a core dependency), and that contract inherits from OpenZeppelin `Ownable`, use `JBOwnableOverride`.

**NOTICE:** Only use `JBOwnableOverride` if you are overriding OpenZeppelin `Ownable` v4.7.0 or higher. Otherwise, `JBPermissions` functionality for `onlyOwner` will not work.

_If you're having trouble understanding this contract, take a look at the [core Juicebox contracts](https://github.com/bananapus/juice-contracts-v4) and the [documentation](https://docs.juicebox.money/) first. If you have questions, reach out on [Discord](https://discord.com/invite/ErQYmth4dS)._

## Develop

`juice-ownable` uses [npm](https://www.npmjs.com/) for package management and the [Foundry](https://github.com/foundry-rs/foundry) development toolchain for builds, tests, and deployments. To get set up, [install Node.js](https://nodejs.org/en/download) and install [Foundry](https://github.com/foundry-rs/foundry):

```bash
curl -L https://foundry.paradigm.xyz | sh
```

You can download and install dependencies with:

```bash
npm install && forge install
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
