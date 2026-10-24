---
title: Gravity Wars
description: A two-player space game, first written in Turbo Pascal in 1989 and rewritten in Perl/Tk in 2002.
---

# Gravity Wars

Two spaceships, a handful of planets, and Newtonian gravity: players take turns firing photon torpedoes at each other's ship, and the planets bend every shot.

## Brief history

Back in the late 1980s when I was in high school, I wrote a game for IBM DOS machines, using Turbo Pascal, called "gravwars" which was based on an Amiga game that someone else had written and that I liked a lot. That version was distributed, much more widely than I thought or knew about, through BBSs (bulletin board systems) and then through the Internet ftp servers and whatnot. A certain number of people liked the game and would email me about the latest version in the intervening years.

Alas with the demise of DOS and my graduation from high school, I did not have the time to rewrite the game for a more modern system. Recently, I had a bit of time free so I did a rewrite but in the most rapid and least difficult manner: thus some of the features are missing and it uses PERL, which makes my life as programmer much easier, but requires the user to have PERL and some libraries.

I took the old Turbo Pascal code and converted the essential parts into PERL. The graphics engine is the PERL Tk library. Thus in some sense the new version is much more universal since PERL exists on many different kinds of systems and is a universal language (unlike Turbo Pascal and graphics command unique to the DOS system with VGA/EGA of the 1980s).

Furthermore, the code is no longer freeware but is under the GNU General Public License (copyleft). See the file "COPYING" below for what that means in detail. What it means, briefly, is that it is "free" software, by which I mean "free" in the sense of freedom and not money. When you acquire this software, you can read the code, modify it, change it, do whatever you want, and give it others at no charge. However, you must also propagate it under the GNU copyleft so others can do the same thing. If you make changes, the changes are covered under the copyleft so you have to include those "free" for next user. You *may* charge for the costs of distributing the package if you had to do something to this end (of course, in these days of Internet and web pages, if you charge, most folks will get it elsewhere at no cost since no one can restrict use or distribution of this software). The philosophy is that software should be free so as to allow everyone to have access to the software and its source code to play with it, improve it, or simply learn. And no one can turn it into private software with hidden code (usually to make money).

## Files

The program itself is the PERL program "gravity_wars.pl" and the file "README" explains the game and other useful details. If you have PERL with the Tk library, just download that and run. Otherwise, you have to get PERL yourself (free to download as "free" software at the PERL website [www.perl.com](https://www.perl.com)). As a convenience, I've included the Tk library version 800.021 below (although you can get this or the latest version at the PERL website too): I've checked and it works with this library for sure on a standard Linux box.

Files you can download:

- [gravity_wars.pl](gravity_wars.pl): the actual program. Current version is 2.0
- [README](README.txt) file explaining the game and other useful information
- [COPYING](COPYING.txt): GNU General Public License (copyleft) and what it means; i.e. the legal terms and obligations involved with this software
- [Tk800.021.tar.gz](Tk800.021.tar.gz): Tk PERL library for the graphics used in the program (latest version of Tk can be found at the PERL website under Downloads [www.perl.com](https://www.perl.com))
- [gwarorig.zip](gwarorig.zip): this is the original IBM DOS Turbo Pascal distribution as found on the web (on ftp game download servers) courtesy of the Internet community as I had lost the original sources myself. Thanks to all those folks out there keeping backups and mirrors! It is mostly of historical value but it might work for someone out there. Or you can read it and write your own version and/or incorporate more features in the old one into the PERL version.

## Gravity Wars elsewhere

- [Grav Wars](https://www.gravwars.com/): a really great new implementation by others that you can play right in your browser, on a computer or a phone.
- [MobyGames](https://www.mobygames.com/game/62124/gravity-wars/): a brief description of the game, with old images of what it looked like.
- [LaunchBox Games Database](https://gamesdb.launchbox-app.com/games/details/91624-gravity-wars): another brief description, with screenshots of the original DOS version.

## Get in touch

Feel free to email me at [sohrab.ismail-beigi@yale.edu](mailto:sohrab.ismail-beigi@yale.edu) with comments, historical corrections, or stories you have about the game.
