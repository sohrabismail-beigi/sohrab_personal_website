**************************************************************************
                            Gravity Wars
              Copyright (C) 2002 Sohrab Ismail-Beigi

This is free software, and you are welcome to redistribute it
under certain conditions.  Please read the file "COPYING" for
more details.


**************************************************************************
How to play the game:

This is a two player game: each player has a spaceship and tries to
shoot the other player's ship first with photon torpedoes in order to
win.  Players take turns shooting until one of them wins.

Player one's ship is the Enterprise, and player two controls the
Klingon ship.  (The Enterprise is the ship with the round circular disk
with the red dot in the middle.)

When the game starts, two windows pop up.  The main window is the
"battle field" where the ships are located and where the action takes
place.  The other window is the control window used to play the game.

The battle field contains the two ships and various planets (colored
circles) of various sizes and masses.  Plants create gravitational
fields that affect the motion of the torpedo, and the gravitational
field of the planets add up following the usual Newtonian inverse
square law.  Planet colors indicate density: red is low, green is
medium, and blue is high.

The control window shows which player's turn it is.  The current
player chooses the angle and speed at which a torpedo will be fired.
Angles are in degrees (between 0 and 360, 0 degrees being 3 o'clock),
and speeds are in arbitrary units (0 to 10), and these values are
entered in the boxes in the control window.  When the player presses
the "Fire" button, a torpedo is launched at that angle and speed,
assuming the angle and speed are valid.  If invalid, the program beeps
and prints an error message on the console when "Fire" is pressed; the
player must choose valid values in order to fire.  The program
remembers the values used by each player and will automatically put
the player's last used values in the boxes when players change turns.

Once fired, the torpedo leaves a white track showing its trajectory.
Each fired torpedo can do one of three things:

   (1) it can hit a planet: in this case the player's turn is over
       and the next player gets to shoot.

   (2) it can leave the planetary system: when the torpedo leaves the
       battle field, it continues moving under gravitational effects,
       and if it has sufficient speed, it can escape the planetary
       system.  In this case, the program will print a message on the
       console, and the player's turn is over.

   (3) it can hit a ship: the person whose ship got hit loses.  Hence,
       one can lose by shooting one's own ship.  A window appears
       announcing the news, and pressing "OK" starts a new game.

The white torpedo tracks are meant to help the players see the paths
of their previous shots.  However, if the battle field gets too
cluttered for your liking, press the "Redraw" button to redraw the
same battle field minus the old torpedo tracks.

Pressing the "New Game" button resets the game and generates a new,
random battle field.  Press "New Game" until you get a scenario to
your liking.

If you would like to play on a battle field with a screen size
different from the default (640 by 480 pixels), read the section "How
to run" below.

Final words of wisdom: once in a while, there will be black holes
present in the planetary system.  Black holes are invisible and have
no size so that you will not see them and your torpedo can not hit
them.  From far away, black holes act like a normal, medium-sized
planet.  However, if a torpedo gets close to a black hole, the
gravitational effects get very strong.


**************************************************************************
Files in the distribution:

      COPYING          :  GNU copyleft, included as per the copyleft
      gravity_wars.pl  :  PERL code for the game
      gwarorig.zip     :  zip file containing original public domain
                          Pascal code from 1989
      README           :  this file


**************************************************************************
How to run :

The program is in PERL and is the file "gravity_wars.pl".  You will
need to have the perl program to run it.  You can get perl for free at
http://www.perl.com.  You will also need the Tk toolkit for perl.  You
can obtain it in the same place as perl itself (you'll have to hunt a
little; Tk is technically a "module" and will be found under that
listing).

To run the code, you should just do "perl gravity_wars.pl" or if you
make the program executable then just type the name "gravity_wars.pl".

I have tested this program and it works on a Linux/X windows box with
perl v5.6.1 and Tk 800.021.

You can look a the command line options by running the program with
"-h" or "--help" (i.e. "perl gravity_wars.pl --help").

If you want to run with a bigger screen for the battle field, you can
provide two positive integers as command line arguments that will
define the new screen size.  The default is 640 by 480 pixels, a
holdover from the old IBM PC EGA/VGA days.


**************************************************************************
To do and wish list:

Unfortunately, at the moment the program will calculate the trajectory
of the torpedo until one of the three conditions above are met and
only AFTERWARDS will show the torpedo track.  This seems to be a
deficiency of the Tk graphics system; I don't know how to solve this
at the moment, but perhaps there is some sort of solution.


**************************************************************************
Brief history:

I based my game on one called Gravity Wars (or something similar) that
used to play on the Amiga in the late 1980s.  The basic layout was
identical, I just had to implement it and pick parameters (gravity,
how to draw the lines, etc.)  I programmed the first version using
Turbo Pascal on an IBM PC system.  That was April 1989.

I put it on my dialup bulletin board system (BBS), which for modern
folks is something from the old days:  people would use their modems
and dial into a server in text mode.  Folks then could download the
game for their own use.

The 1989 game was released as Public Domain code.  Had I known about
the GNU copyleft, I would have instead chosen that because I have
found very similar games on the net which are copyrighted and so the
source code is not free.

In 2002, I decided to do a rewrite for the following reasons: (1) to
have fun and kill some time, (2) to make sure the code is now
copylefted and free software, and (3) to have a version that runs on a
modern type of system.  My choice was to user the PERL programming
language (both to learn it and because it is a great language).  For
graphics I used the Tk library for perl.  Both the perl program and Tk
are available free at http://www.perl.com.
