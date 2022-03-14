# Lucid Craft
**Lucid Craft** is the first **one-time-dynamic** ERC-721 token, where people can merge their one of the best NFTs to their **Lucid Craft** wearables. In that way, **Lucid Craft** brings more utilities to NFTs in different Metaverses, thus people can display their valuables on their **Lucid Craft** wearables.

# Backend, Contracts and Chainlink Oracles
**Lucid Craft** allows you to pick 2 NFTs, one of them is **Lucid Craft** wearable and the other is your another non-fungible which is in your wallet. Then, two NFTs' contract addresses and token ids are transferred to the **Lucid Craft** backend via **Chainlink Oracles**. **Lucid Craft** backend get metadata of NFTs, and print your valuable to your **Lucid Craft** wearable. Finally, thanks to **Chainlink External Adapters** and **Lucid Craft Contracts** we get and set the final token uri on blockchain. 

There is no admin allowances or manual intervences in order to print the valuable's image onto the **Lucid Craft** wearable. All processes are automatated (see [`LucidCraft.sol`](https://github.com/thelucidcraft/lucidcraft/blob/main/contracts/LucidCraft.sol) and [`Lucid Craft Backend`](https://github.com/thelucidcraft/lucidcraft/tree/main/backend)).

<img src="https://github.com/thelucidcraft/lucidcraft/blob/main/image0.jpeg" width=36% height=36%><img src="https://github.com/thelucidcraft/lucidcraft/blob/main/fidenza.png" width=25% height=25%>

## Special Case I: Cryptopunks
Since **Cryptopunks** are created prior to ERC721 standards, there is no  ```ownerOf()``` or another ownership method. So, we created another function for **Cryptopunks** owners to verify that if the user has really own the **Cryptopunks** Nft. You can check that in the contract (see [`LucidCraft.sol`](https://github.com/thelucidcraft/lucidcraft/blob/main/contracts/LucidCraft.sol)

# Installation 

## Backend
```python3 manage.py runserver```

## Oracle
```deploy Operator.sol [`smartcontractkit`](https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.7/Operator.sol))```

## External Adapter
```run chainlink node```

```set bridge name, url = http://host.docker.internal:8080/```

```create job [`Job Definition`](https://github.com/thelucidcraft/lucidcraft/blob/main/cl-ea/index.js))```

## Contracts

```deploy [`LucidCraft.sol`](https://github.com/thelucidcraft/lucidcraft/blob/main/contracts/LucidCraft.sol)```

```send test LINK```


