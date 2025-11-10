# Turbo Snek

This is an open-source game that utilizes the [PolkaGodot](https://github.com/pinksters/polkagodot-plugin) add-on and its [backend with smart contracts](https://github.com/pinksters/polkagodot-backend) for equippable cosmetics, on-chain score submission, and reward distribution.

The game consists of a Godot project and a minimal NodeJS backend for game-specific logic, and can be used as a starting point for more advanced games - whether single- or multiplayer.


## Getting Started

IMPORTANT: Before setting up the game itself, you must first set up the [PolkaGodot backend](https://github.com/pinksters/polkagodot-backend) by deploying smart contracts, creating metadata for your cosmetics, and configuring the server.

### Setting up the game

1. Clone this repository (with `git clone --recursive` to also pull the PolkaGodot submodule).

2. Import the project in Godot Engine by navigating to `project.godot` at the root of this repo.

3. Configure the PolkaGodot extension: either create a new PolkaConfig resource at the root of the project, or copy a pre-filled configuration from `res://addons/polkagodot/config_examples` to `res://`.

  Don't forget to adjust the PolkaConfig resource with your deployed contract addresses and chain info.
  
  For more details on setting up the PolkaGodot extension, [see its own README](https://github.com/pinksters/polkagodot-plugin)


### Configuring leaderboards and reward distribution

1. Create a `.env` file in the `backend` directory and set it up according to `.env.example`.

2. Run `backend/snake-server.js`.

3. In `res://online/score_server.gd`, specify the URL of your `snake-server` instance.


## Important notes

This game serves as a live demo for the PolkaGodot extension and a starting point for new projects.
After completing the setup, the game will be playable out-of-the-box and will distribute rewards based on a cron schedule.

**However**, it's not recommended to use this demo as-is for real tournaments with prizes.

In real-world applications, you will have to implement additional validation and cheat detection in your fork, and/or have a way to review score submissions.
