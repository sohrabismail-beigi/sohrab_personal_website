#!/usr/bin/perl -w

use strict;
use Tk;
use Tk::Canvas;

#
# print copyleft
#
print <<COPYLEFT;


                            Gravity Wars

              Copyright (C) 2002 Sohrab Ismail-Beigi

             IBM PC Pascal version completed 4/23/1989 (v1.0)
             PERL/Tk version completed 12/15/2002 (v2.0)


    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program as the file "COPYING".  If not, write to
    the Free Software Foundation (FSF), Inc., 59 Temple Place, Suite 330,
    Boston, MA 02111-1307 USA.  The FSF web site http://www.fsf.org
    will have the License and much more.


COPYLEFT

#
# All units of distance in this program are in pixels.
#

# Main battle field width and height (default values)
my $sw = 640;
my $sh = 480;

# If we have command line options, either print help or get new sizes
# for the battle field
if (@ARGV>0) {
    if ($ARGV[0] eq "-h" or $ARGV[0] eq "--help") {
	print "Usage: $0 [-h | --help | <sizex> <sizey>]\n\n";
	print "     -h, --help      : this help menu\n";
	print "     <sizex> <sizey> : integers specifying the size of the\n";
	print "                       main battle field.  Default values\n";
	print "                       are $sw and $sh.\n\n";
	exit(0);
    }
    # Main battle field width and height
    $sw = $ARGV[0];
    $sh = $ARGV[1];
    print "Using screen size of $sw x $sh for main battle field.\n\n";
}

# Initial offset for battle window from upper left corner of screen
my $ioff = 0;

# Constants
my $G = 0.1;
my $pi = atan2(1.0,1.0)*4.0;

# Radius of ships: contains the ship completely
my $ship_radius = 25;

# critical distance beyond which we do escape velocity calc
my $critical_dist = 2*sqrt($sw**2+$sh**2);

# Number of random stars in background
my $nrndstar = 1000;

# Describes current setup
my $np;    # number of planets
my @plx;   # x position of planet
my @ply;   # y position of planet
my @plr;   # radius of plane
my @plGM;  # G * mass of planet
my @plcol; # color of planet
my @shipx; # ship x position
my @shipy; # ship y position
my $totGM; # total sum GM in system

# values to display in control
my $angle_disp = 0.0;
my $speed_disp = 1.0;

# Firing speed and angle for both players
my @angle = ($angle_disp,$angle_disp);
my @speed = ($speed_disp,$speed_disp);

# Min and max values for speed
my ($minspeed,$maxspeed) = (0,10);

# Probablity of getting a black hole
my $black_hole_prob = 0.05;

# First player
my $player = 1;

#############################################################################
#
# Set up main battle field window and canvas
#
#############################################################################
my $main = MainWindow->new(-title=>"Gravity Wars -- battle field" , 
			   -background=>"black");
$main->minsize(($sw, $sh));
$main->maxsize(($sw, $sh));
$main->geometry("+$ioff+$ioff");
my $canvas;
&make_canvas;
&make_random_setup;
&redraw_setup;

#############################################################################
#
# Set up control window with buttons and whatnot
#
#############################################################################
my $control = $main->Toplevel(-title=>"Gravity Wars -- controls",
			      -background=>"black");
my $i = int $ioff+$sw+50;
my $j = int $ioff;
$control->geometry("+$i+$j");
my $fr=$control->Frame(-background=>"black")->pack(-expand=>"yes",
						   -fill=>"both");

#
my $redraw_button = $fr->Button(-text=>"Redraw",
				-background=>"darkgrey",
				-foreground=>"black",
				-command=> \&redraw_setup );
my $new_game_button = $fr->Button(-text=>"New Game",
				  -background=>"darkgrey",
				  -foreground=>"black",
				  -command=> \&new_game );
my $quit_button = $fr->Button(-text=>"Quit",
			      -background=>"darkgrey",
			      -foreground=>"black",
			      -command=> sub { exit(0); });
$redraw_button->grid($new_game_button,$quit_button,-padx=>"10",-pady=>"10");

#
my $l1 = $fr->Label(-text=>"Current player: ",
		    -background=>"black",
		    -foreground=>"white");
my $player_label = $fr->Label(-textvariable=> \$player,
			      -background=>"black",
			      -foreground=>"white",
			      -justify=>"left");
$l1->grid($player_label);

#
my $l2 = $fr->Label(-text=>"Angle (0-360): ",
		    -background=>"black",
		    -foreground=>"white");
my $angle_entry = $fr->Entry(-width=>"5", -textvariable=> \$angle_disp);
$l2->grid($angle_entry,-padx=>"10",-pady=>"10");

#
my $l3 = $fr->Label(-text=>"Speed ($minspeed-$maxspeed): ",
		    -background=>"black",
		    -foreground=>"white");
my $speed_entry = $fr->Entry(-width=>"5", -textvariable=> \$speed_disp);
$l3->grid($speed_entry,-padx=>"10",-pady=>"10");

#
my $help_button = $fr->Button(-text=>"Help",
			      -background=>"darkgrey",
			      -foreground=>"black",
			      -command=> \&help);
my $fire_button = $fr->Button(-text=>"Fire",
			      -background=>"darkgrey",
			      -foreground=>"black",
			      -command=> \&fire);
$help_button->grid($fire_button);
$fire_button->grid(-column=>"2");

#
MainLoop;

#############################################################################
#
#                            Subroutines follow
#
#############################################################################

#
# Given three arguments (x,y,r) see if the circle with that center
# and radius is completely on the screen.
#
sub in_bounds($$$) {
    my ($x,$y,$r) = @_;
    if ($x-$r<0 or $x+$r>$sw or $y-$r<0 or $y+$r>$sh) { return 0 }
    else { return 1 }
}

#
# Creates a new random setup.  Picks somewhere between 1 and 9 planets,
# some of which may be blackholes, picks densities and colors, and
# places the ships.  Every item must be in the screen bounds and not
# collide with each other.
#
sub make_random_setup {

    # Random number of planets between 1 and 9
    $np = int(rand 9) + 1;
    $#plx = $np-1;
    $#ply = $np-1;
    $#plr = $np-1;
    $#plGM = $np-1;
    $#plcol = $np-1;
    $totGM = 0;

    # Loop over the planets and find places for them and pick their
    # radii and densities and calculate G*M.  density is 1, 2, or 3.
    # And the colors are RGB for those densities.
    for (my $i=0; $i<$np; $i++) {
	my $ok = 0;
	while(!$ok) {
	    # pick a random place and radius for the planet
	    my ($x,$y) = (int(rand $sw),int(rand $sh));
	    my $d = int(rand 3)+1;
	    my $r = 0;
	    my $GM;
	    # 5% change of being a blackhole ($r==0)
	    if (rand>$black_hole_prob) {
		$r = int (rand 70)+20;
		$GM = $G * $pi* $r**2 * $d;
	    }
	    else {
		$GM = $G * $pi * 30.0**2;
	    } 
	    # now see if the choice is in bounds and not colliding
	    # with any other planets
	    $ok = 1;
	    if (! &in_bounds($x,$y,$r)) { $ok=0; next; }
	    if ($i>0) { 
		for (my $j=0; $j<$i; $j++) {
		    my $dist =	sqrt(($x-$plx[$j])**2 + ($y-$ply[$j])**2);
		    if ($dist <= $r+$plr[$j]) {
			$ok = 0;
			last;
		    }
		}
	    }
	    # good choice: store it
	    if ($ok) {
		$plx[$i] = $x;
		$ply[$i] = $y;
		$plr[$i] = $r;
		$plGM[$i] = $GM;
		$totGM += $GM;
		$plcol[$i] = ("red", "green", "blue")[$d-1];
	    }
	} # while our choice is !$ok
    } # $i loop on planets

    # Place ships: random positions not colliding with a planet or other ship
    for (my $i=0; $i<2; $i++) {
	my ($x,$y);
	my $ok=0;
	while (!$ok) {

	    # pick a random position
	    if ($i==0) { ($x,$y) = (int(rand $sw),int(rand $sh)); }
	    # put second ship in quadrant directly opposite the first one
	    else { ($x,$y) = (int(rand $sw/2)+$sw/2*($shipx[0]<$sw/2),
			      int(rand $sh/2)+$sh/2*($shipy[0]<$sh/2)); }

	    # try again if out of bounds
	    next if (!in_bounds($x,$y,$ship_radius));

	    # does it collide with a planet or other ship?
	    $ok = 1;
	    for (my $j=0; $j<$np; $j++) {
		my $dist = sqrt(($x-$plx[$j])**2 + ($y-$ply[$j])**2);
		if ($dist <= $ship_radius+$plr[$j]+10) {
		    $ok = 0;
		    last;
		}
	    }
	    for (my $j=0; $j<$i; $j++) {
		my $dist = sqrt(($x-$shipx[$j])**2 + ($y-$shipy[$j])**2);
		if ($dist <= 2*$ship_radius) {
		    $ok = 0;
		    last;
		}
	    }
	} # while not ok ship position

	# the choice was fine, store it
	$shipx[$i] = $x;
	$shipy[$i] = $y;
    }
}

#
# Draw the enterprise given its center x and y coords as arguments
#
sub draw_enterprise ($$) {
    my ($x,$y) = @_;

    # This circle surrounds the enterprise just right...
    # $canvas->createOval($x-25,$y-25,$x+25,$y+25,-outline=>"white");

    $x += 14;
    $canvas->createOval($x-9,$y-9,$x+9,$y+9,
			-outline=>"grey",
			-fill=>"grey",
			-tags=>"spock");
    $canvas->createRectangle($x-23,$y-2,$x,$y+2,
			     -outline=>"grey",
			     -fill=>"grey",
			     -tags=>"spock");
    $canvas->createPolygon($x-18,$y-2,$x-21,$y-10,$x-34,$y-10,
			   $x-34,$y-13,$x-10,$y-13,$x-10,$y-10,
			   $x-17,$y-10,$x-14,$y-2,
			   -outline=>"grey",
			   -fill=>"grey",
			   -tags=>"spock");
    $canvas->createPolygon($x-18,$y+2,$x-21,$y+10,$x-34,$y+10,
			   $x-34,$y+13,$x-10,$y+13,$x-10,$y+10,
			   $x-17,$y+10,$x-14,$y+2,
			   -outline=>"grey",
			   -fill=>"grey",
			   -tags=>"spock");
    $canvas->createOval($x-2,$y-2,$x+2,$y+2,
			-outline=>"red",
			-fill=>"red",
			-tags=>"spock");
    $canvas->createRectangle($x-10,$y-13,$x-9,$y-10,
			     -outline=>"red",
			     -fill=>"red",
			     -tags=>"spock");
    $canvas->createRectangle($x-10,$y+13,$x-9,$y+10,
			     -outline=>"red",
			     -fill=>"red",
			     -tags=>"spock");
}

#
# Draw the klingon ship given its center x and y coords as arguments
#
sub draw_klingon ($$) {
    my ($x,$y) = @_;

    # This circle surrounds the klingon just right...
    # $canvas->createOval($x-25,$y-25,$x+25,$y+25,-outline=>"white");

    $x -= 23;
    $canvas->createPolygon($x,$y,$x+5,$y-6,$x+10,$y-2,$x+20,$y-2,
			   $x+25,$y-15,$x+40,$y-15,$x+34,$y,
			   $x+40,$y+15,$x+25,$y+15,$x+20,$y+2,
			   $x+10,$y+2,$x+5,$y+6,
			   -outline=>"grey",
			   -fill=>"grey",
			   -tags=>"warf");
    $canvas->createPolygon($x+26,$y,$x+30,$y-11,$x+33,$y-11,
			   $x+30,$y,$x+33,$y+11,$x+30,$y+11,
			   -outline=>"red",
			   -fill=>"red",
			   -tags=>"warf");
    $x += 5;
    $canvas->createOval($x-1,$y-1,$x+1,$y+1,
			-outline=>"red",
			-fill=>"red",
			-tags=>"warf");
}

#
# Creates the canvas to draw on in battle window
#
sub make_canvas {
    $canvas = $main->Canvas(-width=>$sw,
			    -height=>$sh,
			    -background=>"black");
    $canvas->pack(-expand =>"yes",
		  -fill=>"both");
}

#
# Clears the canvas and redraws the current setup.
# The background stars are random, however
#
sub redraw_setup {

    # destroy old canvas and make new (i.e. clear screen)
    $canvas->destroy;
    &make_canvas;

    # draw random stars in the background as grey dots
    for (my $i=0; $i<$nrndstar; $i++) {
	my $x = int(rand $sw);
	my $y = int(rand $sh);
	$canvas->createLine($x,$y,$x+1,$y+1,
			    -fill=>"darkgrey",
			    -tags=>"dots");
    }

    # draw the planets
    for (my $i=0; $i<$np; $i++) {
	my $r = $plr[$i];
	$canvas->createOval($plx[$i]-$r,$ply[$i]-$r,
			    $plx[$i]+$r,$ply[$i]+$r,
			    -fill=>$plcol[$i],
			    -tags=>"planet");
    }

    # draw the ships
    &draw_enterprise($shipx[0],$shipy[0]);
    &draw_klingon($shipx[1],$shipy[1]);
}

#
# Reset everything and start a new game
#
sub new_game {
    $player = 1;
    $speed_disp = 1.0;
    $angle_disp = 0.0;
    @speed = ($speed_disp,$speed_disp);
    @angle = ($angle_disp,$angle_disp);
    &make_random_setup;
    &redraw_setup;
}

#
# The fire button was pressed: fire the torpedo, see where it goes,
# figure out what happens, and then go to the next player
#
sub fire {

    # Get the speed and angle the player wants to fire with
    # and make sure they are allowed
    $player--;
    $angle[$player] = $angle_disp;
    $speed[$player] = $speed_disp;
    my ($a,$s) = ($angle[$player],$speed[$player]);
    if ($a<0 or $a>360) {
	print "\aError: angle must be between 0 and 360.  Try again.\n\n";
	$player++;
	return;
    }
    if ($s<$minspeed or $s>$maxspeed) {
	print "\aError: speed must be between $minspeed and $maxspeed.  ";
	print "Try again.\n\n";
	$player++;
	return;
    }

    # Initial conditions
    $a = $a*$pi/180.0;
    my ($x,$y) = ($shipx[$player]+$ship_radius*cos($a),
		  $shipy[$player]-$ship_radius*sin($a));
    my ($vx,$vy) = ($s*cos($a),-$s*sin($a));

    # Calculate torpedo trajetory
    my $dt=0.10;
    my $keep_going = 1;
    my $winner = 0;
    while ($keep_going) {

	# save last position
	my ($lastx,$lasty) = ($x,$y);

	# update position
	$x += $vx*$dt;
	$y += $vy*$dt;

	# calculate acceleration due to planets and update velocity
	my ($ax,$ay) = (0.0,0.0);
	for (my $i=0; $i<$np; $i++) {
	    my ($dx,$dy) = ($x-$plx[$i],$y-$ply[$i]);
	    my $dr = sqrt($dx**2+$dy**2);
	    # normal planet
	    if ($plr[$i]>0) {
		$ax -= $plGM[$i]*$dx/($dr**3);
		$ay -= $plGM[$i]*$dy/($dr**3);
	    }
	    # black hole
	    else {
		$ax -= $plGM[$i]*$dx/($dr**3+1/$dr**4);
		$ay -= $plGM[$i]*$dy/($dr**3+1/$dr**4);
	    }
	}
	$vx += $ax*$dt;
	$vy += $ay*$dt;

	# Adjust dt so that torpedo moves two pixel per time step
	$dt = 2.0/sqrt($vx**2+$vy**2);

	# If (x,y) is on the screen, then draw the last segment of trajectory
	#  see if it collides with any of the planets or ships.
	if (&in_bounds($x,$y,0)) {

	    # Draw segement of torpedo path
	    $canvas->createLine($lastx,$lasty,$x,$y,
				-fill=>"white",-tags=>"torpedo");

	    # See if this segment overlaps with any of the planets or ships
	    my @overlaps = $canvas->find("overlapping",$lastx,$lasty,$x,$y);
	    for (my $i=0; $i<=$#overlaps; $i++) {
		my @tagarr = $canvas->gettags($overlaps[$i]);
                my $tag = $tagarr[0];
		# if overlap is planet or ship, we can stop the calculation
		if ($tag eq "planet" or $tag eq "spock" or $tag eq "warf") {
		    $keep_going = 0;
		    # if a ship, find the winner
		    if ($tag ne "planet") { 
			$tag eq "spock" ? $winner = 2 : $winner = 1; 
		    }
		    last;
		}
	    }
	}
	# if (x,y) is off screen, see if the torpedo has reached escape
	# velocity.
	else {

	    # if the torpedo is far enough away, check for escape velocity
	    my ($dx,$dy) = ($x-$sw/2,$y-$sh/2);
	    my $dr = sqrt($dx**2+$dy**2);
	    if ($dr >= $critical_dist) {
		my $vc = ($vx*$dx+$vy*$dy)/$dr;
		if (0.5*($vc**2) >= $totGM/$dr) {
		    $keep_going = 0;
		    print "\nPlayer ", $player+1, 
  		       ": your photon torpedo left planetary system.\n\n";
		}
	    }
	}
    } # trajectory calculation loop

    # did we stop because someone won?
    if ($winner) {

	# put some "explosion" dots around the loser's ship centered
	# on where the torpedo struck
	for (my $i=0; $i<800; $i++) {
	    my $a = rand 2*$pi;
	    my $r = rand 30;
	    my ($px,$py) = ($x+$r*cos($a),$y+$r*sin($a));
	    $canvas->createLine($px,$py,$px+1,$py+1,
				-fill=>"yellow",-tags=>"explosion");
	}

	# pop up a little window annoucing who won; when closed, a new
	# game is started
	$player++;
	my $box = $main->Toplevel(-title=>"Gamer over!",-background=>"black");
	$box->Label(-text=>"Gamer over: player $winner wins!",
		    -background=>"black", 
		    -foreground=>"white")->pack;
	$box->Button(-text=>"OK",
		     -background=>"darkgrey",
		     -foreground=>"black",
		     -command=> sub { $box->destroy; &new_game; })->pack;
	return;
    }

    # No winner, so switch players for the next player's turn
    $player++;
    $player%=2;
    $angle_disp = $angle[$player];
    $speed_disp = $speed[$player];
    $player++;
}

#
# Print help (from README file) into a window
#
sub help {

    # see if we can read the README file
    if (!open(R,"<README")) {
	print "\n\aCan not read README file for help.\n\n";
	return;
    }

    my $help_win = $main->Toplevel(-title=>"Gravity Wars help",
				-background=>"black",
				-foreground=>"white");
    
    # use text widget to put the README file into it
    my $text_widget = $help_win->Text(-insertbackground=>"red",
				      -background=>"black",
				      -foreground=>"white")->pack;
    while (<R>) {
	$text_widget->insert("end", $_);
    }
    close R;

    # button to get rid of the help window
    $help_win->Button(-text=>"Ok",
		      -background=>"darkgrey",
		      -foreground=>"black",
		      -command=> sub { $help_win->destroy })->pack;
}
