#!/usr/bin/perl
 
#########################################################################
# char.pl
#########################################################################

# Written 10/03/96 by David Harris <David_Harris@hmc.edu>
# Updated 10/09/02 by David Diaz <ddiaz@hmc.edu>
# Updated 4/30/03 by Genevieve Breed <gbreed@hmc.edu>
#
# This script characterizes a CMOS process and obtains a bunch of handy
# data.
#
# Usage:  char.pl VDD LAMBDA processfile -fet

#########################################################################
# Load Libraries
#########################################################################
require "ctime.pl";

#########################################################################
# Start Script
#########################################################################

# Check for proper number of arguments and extract args
if ($#ARGV != 3 && $#ARGV != 4) { # $#ARGV is the number of command line arguments minus 1
    print STDERR "Usage: $0 VDD LAMBDA TEMP processfile [-fet]\n"; # $0 is the script name
    print STDERR " ex: $0 1.8 0.09u 70 ../models/tsmc180/opConditions.lib\n";
    print STDERR " for IBM processes, use -fet to use nfet rather than nmos\n";
    exit;
}
$VDD = $ARGV[0]; $LAMBDA = $ARGV[1]; $temp = $ARGV[2]; $processfile = $ARGV[3];
$fetmode = 0;
if ($#ARGV == 4) {
    if ($ARGV[4] eq "-fet") {
	$fetmode = 1;
	print STDERR "Using FET mode\n";
    }
    else {
	print STDERR "Argument '$ARGV[4]' not recognized\n";
    }
}

# Start timer
$time = time;

#########################################################################
# Run Simulations
#########################################################################

open (OUT1, ">char_temp.out");

# This section runs a bunch of simulations.  While you are testing
# and debugging your additions, you'll probably want to comment
# out  or remove the simulations that you know work.


# Gate leakage
$gateleak_n = &runsim("gateleak", "gateleak_n", "!TEMP!", $temp, 
		     "!CORNER!", "TT", "!VOLT!", $VDD);
$gateleak_n /= 16*$LAMBDA;
$gateleak_p = &runsim("gateleak", "gateleak_p", "!TEMP!", $temp, 
		     "!CORNER!", "TT", "!VOLT!", $VDD);
$gateleak_p /= 16*$LAMBDA;


# Part (1):  Capacitance for delay
# Run the capdelay.hsp deck and extract the measured parameter CperMic
# Substitute $temp for !TEMP!, TT for !CORNER!, and $VDD for !VOLT!
$cap_delay = &runsim("capdelay", "CperMic", "!TEMP!", $temp, 
		     "!CORNER!", "TT", "!VOLT!", $VDD);

# Part (2):  Capacitance for power
# Run the cappower.hsp deck and extract the measured parameter CperMic
# Substitute $temp for !TEMP!, TT for !CORNER!, and $VDD for !VOLT!
$cap_power_integr = &runsim("cappowernew", "invA", "!TEMP!", $temp, 
		     "!CORNER!", "TT", "!VOLT!", $VDD);
$cap_power_f_integr = &runsim("cappowernew", "invF", "!TEMP!", $temp, 
		     "!CORNER!", "TT", "!VOLT!", $VDD);
$cap_power_r_integr = &runsim("cappowernew", "invR", "!TEMP!", $temp, 
		     "!CORNER!", "TT", "!VOLT!", $VDD);
$cap_power = $cap_power_integr/$VDD/48/$LAMBDA;
$cap_power_f = $cap_power_f_integr/$VDD/48/$LAMBDA;
$cap_power_r = -$cap_power_r_integr/$VDD/48/$LAMBDA;

# Part (3):  Diffusion Capacitance for delay
# Run the diffcap.hsp deck and extract the measured parameter CperMic
$cap_ndiff = &runsim("diffcap", "CperMic", "!TEMP!", $temp, "!CORNER!", "TT",
			"!VOLT!", $VDD, "!LOAD!", "ntotcap");

$cap_ndiff_shared = &runsim("diffcap", "CperMic", "!TEMP!", $temp, "!CORNER!", "TT",
			"!VOLT!", $VDD, "!LOAD!", "nsharedcap");

$cap_ndiff_merged = &runsim("diffcap", "CperMic", "!TEMP!", $temp, "!CORNER!", "TT",
			"!VOLT!", $VDD, "!LOAD!", "nmergedcap");

$cap_ndiff_gate = &runsim("diffcap", "CperMic", "!TEMP!", $temp, "!CORNER!", "TT",
			"!VOLT!", $VDD, "!LOAD!", "ngatecap");

$cap_ndiff_area = &runsim("diffcap", "CperMic", "!TEMP!", $temp, "!CORNER!", "TT",
			"!VOLT!", $VDD, "!LOAD!", "nadcap");

$cap_ndiff_area /= 5*$LAMBDA;
$cap_ndiff_perimeter = &runsim("diffcap", "CperMic", "!TEMP!", $temp, 
			       "!CORNER!", "TT", "!VOLT!", $VDD, "!LOAD!", "npdcap");
$cap_ndiff_pgate = &runsim("diffcap", "CperMic", "!TEMP!", $temp, 
			       "!CORNER!", "TT", "!VOLT!", $VDD, "!LOAD!", "npdgcap");


$cap_ndiff_pgate -= $cap_ndiff_gate;
$cap_ndiff_calc = $cap_ndiff_gate + 5*$LAMBDA*$cap_ndiff_area + $cap_ndiff_perimeter + $cap_ndiff_pgate;
$cap_pdiff = &runsim("diffcap", "CperMic", "!TEMP!", $temp, "!CORNER!", "TT",
			"!VOLT!", $VDD, "!LOAD!", "ptotcap");

$cap_pdiff_shared = &runsim("diffcap", "CperMic", "!TEMP!", $temp, "!CORNER!", "TT",
			"!VOLT!", $VDD, "!LOAD!", "psharedcap");

$cap_pdiff_merged = &runsim("diffcap", "CperMic", "!TEMP!", $temp, "!CORNER!", "TT",
			"!VOLT!", $VDD, "!LOAD!", "pmergedcap");
$cap_pdiff_gate = &runsim("diffcap", "CperMic", "!TEMP!", $temp, "!CORNER!", "TT",
			"!VOLT!", $VDD, "!LOAD!", "pgatecap");
$cap_pdiff_area = &runsim("diffcap", "CperMic", "!TEMP!", $temp, "!CORNER!", "TT",
			"!VOLT!", $VDD, "!LOAD!", "padcap");
$cap_pdiff_area /= 5*$LAMBDA;
$cap_pdiff_perimeter = &runsim("diffcap", "CperMic", "!TEMP!", $temp, 
			       "!CORNER!", "TT", "!VOLT!", $VDD, "!LOAD!", "ppdcap");
$cap_pdiff_pgate = &runsim("diffcap", "CperMic", "!TEMP!", $temp, 
			       "!CORNER!", "TT", "!VOLT!", $VDD, "!LOAD!", "ppdgcap");
$cap_pdiff_pgate -= $cap_pdiff_gate;
$cap_pdiff_calc = $cap_pdiff_gate + 5*$LAMBDA*$cap_pdiff_area + $cap_pdiff_perimeter + $cap_pdiff_pgate;

# Part (4):  Temp Coefficient of capacitance
$cap_delay125 = &runsim("capdelay", "CperMic", "!TEMP!", 125, 
			"!CORNER!", "TT", "!VOLT!", $VDD);
print OUT1 "cap_delay = $cap_delay\n";
print OUT1 "cap_delay125 = $cap_delay125\n";
$captempco = ($cap_delay125-$cap_delay)/$cap_delay;

# Part (5):  Voltage Coefficient of capacitance
$cap_delayVhi = &runsim("capdelay", "CperMic", "!TEMP!", $temp, 
			"!CORNER!", "TT", "!VOLT!", $VDD*1.1);
print OUT1 "cap_delayVhi = $cap_delayVhi\n";
$capvoltco = 100 * ($cap_delayVhi-$cap_delay)/$cap_delay/($VDD * 0.1);

# Part (9, partially complete):  Inverter delays
$inv_delay_1_f = &runsim("invdelay", "invF", "!TEMP!", $temp, "!CORNER!", "TT",
			 "!VOLT!", $VDD, "!FANOUT!", 1);
$inv_delay_1_r = &runsim("invdelay", "invR", "!TEMP!", $temp, "!CORNER!", "TT",
			 "!VOLT!", $VDD, "!FANOUT!", 1);
$inv_delay_1_a = &runsim("invdelay", "invA", "!TEMP!", $temp, "!CORNER!", "TT",
			   "!VOLT!", $VDD, "!FANOUT!", 1);
$inv_delay_2_f = &runsim("invdelay", "invF", "!TEMP!", $temp, "!CORNER!", "TT",
			 "!VOLT!", $VDD, "!FANOUT!", 2);
$inv_delay_2_r = &runsim("invdelay", "invR", "!TEMP!", $temp, "!CORNER!", "TT",
			 "!VOLT!", $VDD, "!FANOUT!", 2);
$inv_delay_2_a = &runsim("invdelay", "invA", "!TEMP!", $temp, "!CORNER!", "TT",
			   "!VOLT!", $VDD, "!FANOUT!", 2);
$inv_delay_3_f = &runsim("invdelay", "invF", "!TEMP!", $temp, "!CORNER!", "TT",
			 "!VOLT!", $VDD, "!FANOUT!", 3);
$inv_delay_3_r = &runsim("invdelay", "invR", "!TEMP!", $temp, "!CORNER!", "TT",
			 "!VOLT!", $VDD, "!FANOUT!", 3);
$inv_delay_3_a = &runsim("invdelay", "invA", "!TEMP!", $temp, "!CORNER!", "TT",
			   "!VOLT!", $VDD, "!FANOUT!", 3);
$inv_delay_4_f = &runsim("invdelay", "invF", "!TEMP!", $temp, "!CORNER!", "TT",
			 "!VOLT!", $VDD, "!FANOUT!", 4);
$inv_delay_4_r = &runsim("invdelay", "invR", "!TEMP!", $temp, "!CORNER!", "TT",
			 "!VOLT!", $VDD, "!FANOUT!", 4);
$inv_delay_4_a = &runsim("invdelay", "invA", "!TEMP!", $temp, "!CORNER!", "TT",
			   "!VOLT!", $VDD, "!FANOUT!", 4);
$inv_delay_6_f = &runsim("invdelay", "invF", "!TEMP!", $temp, "!CORNER!", "TT",
			 "!VOLT!", $VDD, "!FANOUT!", 6);
$inv_delay_6_r = &runsim("invdelay", "invR", "!TEMP!", $temp, "!CORNER!", "TT",
			 "!VOLT!", $VDD, "!FANOUT!", 6);
$inv_delay_6_a = &runsim("invdelay", "invA", "!TEMP!", $temp, "!CORNER!", "TT",
			   "!VOLT!", $VDD, "!FANOUT!", 6);
$inv_delay_8_f = &runsim("invdelay", "invF", "!TEMP!", $temp, "!CORNER!", "TT",
			 "!VOLT!", $VDD, "!FANOUT!", 8);
$inv_delay_8_r = &runsim("invdelay", "invR", "!TEMP!", $temp, "!CORNER!", "TT",
			 "!VOLT!", $VDD, "!FANOUT!", 8);
$inv_delay_8_a = &runsim("invdelay", "invA", "!TEMP!", $temp, "!CORNER!", "TT",
			   "!VOLT!", $VDD, "!FANOUT!", 8);

# Calculating effective resistance from inverter delays

# between fanouts 3-4  
$pmos_resistance_34 = ($inv_delay_4_r-$inv_delay_3_r)*2/3/$cap_delay;
$nmos_resistance_34 = ($inv_delay_4_f-$inv_delay_3_f)/3/$cap_delay;

# tristate delays
$tri_delay_3_f = &runsim("seriesRes", "triF", "!TEMP!", $temp, "!CORNER!", "TT",
			 "!VOLT!", $VDD, "!FANOUT!", 3);
$tri_delay_3_r = &runsim("seriesRes", "triR", "!TEMP!", $temp, "!CORNER!", "TT",
			 "!VOLT!", $VDD, "!FANOUT!", 3);
#$tri_delay_3_a = &runsim("seriesRes", "triA", "!TEMP!", $temp, "!CORNER!", "TT",
#			   "!VOLT!", $VDD, "!FANOUT!", 3);
$tri_delay_4_f = &runsim("seriesRes", "triF", "!TEMP!", $temp, "!CORNER!", "TT",
			 "!VOLT!", $VDD, "!FANOUT!", 4);
$tri_delay_4_r = &runsim("seriesRes", "triR", "!TEMP!", $temp, "!CORNER!", "TT",
			 "!VOLT!", $VDD, "!FANOUT!", 4);
#$tri_delay_4_a = &runsim("seriesRes", "triA", "!TEMP!", $temp, "!CORNER!", "TT",
#			   "!VOLT!", $VDD, "!FANOUT!", 4);

# Calculating effective resistance from tristate delays
# between fanouts 3-4  
$pmos_series_resistance_34 = ($tri_delay_4_r-$tri_delay_3_r)/3/$cap_delay;
$nmos_series_resistance_34 = ($tri_delay_4_f-$tri_delay_3_f)/6/$cap_delay;

# Part (11):  Curve fit of inverter delay
# Do regressions to fit delay data
&linearFit($inv_delay_1_a, 1, 
	   $inv_delay_2_a, 2,
	   $inv_delay_4_a, 4,
	   $inv_delay_6_a, 6,
	   $inv_delay_8_a, 8); # results passed back as $a and $b
$inv_delay_a = $a; $inv_delay_b = $b;

# Part (12): Temp Coefficient of FO4 inverter delay
$inv_delay_4_a125 = &runsim("invdelay", "invA", "!TEMP!", 125, 
			    "!CORNER!", "TT", "!VOLT!", $VDD, "!FANOUT!", 4);
print OUT1 "inv_delay_4_a =  $inv_delay_4_a\n";
print OUT1 "inv_delay_4_a125 =  $inv_delay_4_a125\n";
$invtempco = ($inv_delay_4_a125-$inv_delay_4_a)/$inv_delay_4_a;

# Part (13): Voltage Coefficient of FO4 inverter delay
$inv_delay_4_aVhi = &runsim("invdelay", "invA", "!TEMP!", $temp, 
			    "!CORNER!", "TT", "!VOLT!", $VDD*1.1, 
			    "!FANOUT!", 4);
print OUT1 "inv_delay_4_aVhi = $inv_delay_4_aVhi\n";
$invvoltco = 100*($inv_delay_4_aVhi-$inv_delay_4_a)/$inv_delay_4_a/($VDD*0.1);

# Part (14): gate delay with outer input switching
$nand_delay_r = &runsim("gatedelay", "delayR", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb",
			"!INNER!", "Vdd", "!VOLT!", $VDD, "!TEMP!", $temp);
$nand_delay_f = &runsim("gatedelay", "delayF", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb",
			"!INNER!", "Vdd", "!VOLT!", $VDD, "!TEMP!", $temp);
$nand_delay_a = &runsim("gatedelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb",
			"!INNER!", "Vdd", "!VOLT!", $VDD, "!TEMP!", $temp);
$nor_delay_r = &runsim("gatedelay", "delayR", "!CORNER!", "TT",
		       "!GATE!", "nor2", "!OUTER!", "Inb",
		       "!INNER!", "Gnd", "!VOLT!", $VDD, "!TEMP!", $temp);
$nor_delay_f = &runsim("gatedelay", "delayF", "!CORNER!", "TT",
		       "!GATE!", "nor2", "!OUTER!", "Inb",
		       "!INNER!", "Gnd", "!VOLT!", $VDD, "!TEMP!", $temp);
$nor_delay_a = &runsim("gatedelay", "delayA", "!CORNER!", "TT",
		       "!GATE!", "nor2", "!OUTER!", "Inb",
		       "!INNER!", "Gnd", "!VOLT!", $VDD, "!TEMP!", $temp);


# Part (16):  Curve fit of NAND2 delay
# with outer input switching
$nand_outdelay_1_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Vdd", "!FANIN!", 1, "!FANOUT!", 1, "!VOLT!", $VDD);
$nand_outdelay_2_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Vdd", "!FANIN!", 1, "!FANOUT!", 2, "!VOLT!", $VDD);
$nand_outdelay_4_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Vdd", "!FANIN!", 1, "!FANOUT!", 4, "!VOLT!", $VDD);
$nand_outdelay_6_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Vdd", "!FANIN!", 1, "!FANOUT!", 6, "!VOLT!", $VDD);
$nand_outdelay_8_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Vdd", "!FANIN!", 1, "!FANOUT!", 8, "!VOLT!", $VDD);

# with inner input switching
$nand_indelay_1_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Vdd", "!TEMP!", $temp,
			"!INNER!", "Inb", "!FANIN!", 1, "!FANOUT!", 1, "!VOLT!", $VDD);
$nand_indelay_2_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Vdd", "!TEMP!", $temp,
			"!INNER!", "Inb", "!FANIN!", 1, "!FANOUT!", 2, "!VOLT!", $VDD);
$nand_indelay_4_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Vdd", "!TEMP!", $temp,
			"!INNER!", "Inb", "!FANIN!", 1, "!FANOUT!", 4, "!VOLT!", $VDD);
$nand_indelay_6_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Vdd", "!TEMP!", $temp,
			"!INNER!", "Inb", "!FANIN!", 1, "!FANOUT!", 6, "!VOLT!", $VDD);
$nand_indelay_8_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Vdd", "!TEMP!", $temp,
			"!INNER!", "Inb", "!FANIN!", 1, "!FANOUT!", 8, "!VOLT!", $VDD);

# with outer input switching (constant fanin)
$nand_outdelay_1_ac = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Vdd", "!FANIN!", 0.25, "!FANOUT!", 1, "!VOLT!", $VDD);
$nand_outdelay_2_ac = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Vdd", "!FANIN!", 0.5, "!FANOUT!", 2, "!VOLT!", $VDD);
$nand_outdelay_4_ac = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Vdd", "!FANIN!", 1, "!FANOUT!", 4, "!VOLT!", $VDD);
$nand_outdelay_6_ac = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Vdd", "!FANIN!", 1.5, "!FANOUT!", 6, "!VOLT!", $VDD);
$nand_outdelay_8_ac = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Vdd", "!FANIN!", 2, "!FANOUT!", 8, "!VOLT!", $VDD);

# with inner input switching (constant fanin)
$nand_indelay_1_ac = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Vdd", "!TEMP!", $temp,
			"!INNER!", "Inb", "!FANIN!", 0.25, "!FANOUT!", 1, "!VOLT!", $VDD);
$nand_indelay_2_ac = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Vdd", "!TEMP!", $temp,
			"!INNER!", "Inb", "!FANIN!", 0.5, "!FANOUT!", 2, "!VOLT!", $VDD);
$nand_indelay_4_ac = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Vdd", "!TEMP!", $temp,
			"!INNER!", "Inb", "!FANIN!", 1, "!FANOUT!", 4, "!VOLT!", $VDD);
$nand_indelay_6_ac = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Vdd", "!TEMP!", $temp,
			"!INNER!", "Inb", "!FANIN!", 1.5, "!FANOUT!", 6, "!VOLT!", $VDD);
$nand_indelay_8_ac = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Vdd", "!TEMP!", $temp,
			"!INNER!", "Inb", "!FANIN!", 2, "!FANOUT!", 8, "!VOLT!", $VDD);

# with both inputs simultaneously switching
$nand_bdelay_1_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 1, "!VOLT!", $VDD);
$nand_bdelay_2_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 2, "!VOLT!", $VDD);
$nand_bdelay_4_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 4, "!VOLT!", $VDD);
$nand_bdelay_6_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 6, "!VOLT!", $VDD);
$nand_bdelay_8_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 8, "!VOLT!", $VDD);

$nand_bdelay_1_r = &runsim("gatefodelay", "delayR", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 1, "!VOLT!", $VDD);
$nand_bdelay_2_r = &runsim("gatefodelay", "delayR", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 2, "!VOLT!", $VDD);
$nand_bdelay_4_r = &runsim("gatefodelay", "delayR", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 4, "!VOLT!", $VDD);
$nand_bdelay_6_r = &runsim("gatefodelay", "delayR", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 6, "!VOLT!", $VDD);
$nand_bdelay_8_r = &runsim("gatefodelay", "delayR", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 8, "!VOLT!", $VDD);

$nand_bdelay_1_f = &runsim("gatefodelay", "delayF", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 1, "!VOLT!", $VDD);
$nand_bdelay_2_f = &runsim("gatefodelay", "delayF", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 2, "!VOLT!", $VDD);
$nand_bdelay_4_f = &runsim("gatefodelay", "delayF", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 4, "!VOLT!", $VDD);
$nand_bdelay_6_f = &runsim("gatefodelay", "delayF", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 6, "!VOLT!", $VDD);
$nand_bdelay_8_f = &runsim("gatefodelay", "delayF", "!CORNER!", "TT",
			"!GATE!", "nand2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 8, "!VOLT!", $VDD);

&linearFit($nand_outdelay_1_a, 1, 
	   $nand_outdelay_2_a, 2,
	   $nand_outdelay_4_a, 4,
	   $nand_outdelay_6_a, 6,
	   $nand_outdelay_8_a, 8); # results passed back as $a and $b
$nand_delay_a_out = $a; $nand_delay_b_out = $b;


&linearFit($nand_indelay_1_a, 1, 
	   $nand_indelay_2_a, 2,
	   $nand_indelay_4_a, 4,
	   $nand_indelay_6_a, 6,
	   $nand_indelay_8_a, 8); # results passed back as $a and $b
$nand_delay_a_in = $a; $nand_delay_b_in = $b;

&linearFit($nand_outdelay_1_ac, 1, 
	   $nand_outdelay_2_ac, 2,
	   $nand_outdelay_4_ac, 4,
	   $nand_outdelay_6_ac, 6,
	   $nand_outdelay_8_ac, 8); # results passed back as $a and $b
$nand_delay_a_outc = $a; $nand_delay_b_outc = $b;

&linearFit($nand_indelay_1_ac, 1, 
	   $nand_indelay_2_ac, 2,
	   $nand_indelay_4_ac, 4,
	   $nand_indelay_6_ac, 6,
	   $nand_indelay_8_ac, 8); # results passed back as $a and $b
$nand_delay_a_inc = $a; $nand_delay_b_inc = $b;

&linearFit($nand_bdelay_1_a, 1, 
	   $nand_bdelay_2_a, 2,
	   $nand_bdelay_4_a, 4,
	   $nand_bdelay_6_a, 6,
	   $nand_bdelay_8_a, 8); # results passed back as $a and $b
$nand_delay_a_both = $a; $nand_delay_b_both = $b;

&linearFit($nand_bdelay_1_r, 1, 
	   $nand_bdelay_2_r, 2,
	   $nand_bdelay_4_r, 4,
	   $nand_bdelay_6_r, 6,
	   $nand_bdelay_8_r, 8); # results passed back as $a and $b
$nand_delay_a_both_r = $a; $nand_delay_b_both_r = $b;

&linearFit($nand_bdelay_1_f, 1, 
	   $nand_bdelay_2_f, 2,
	   $nand_bdelay_4_f, 4,
	   $nand_bdelay_6_f, 6,
	   $nand_bdelay_8_f, 8); # results passed back as $a and $b
$nand_delay_a_both_f = $a; $nand_delay_b_both_f = $b;




# Part (17):  Curve fit of NOR delay
# with outer input switching
$nor_outdelay_1_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Gnd", "!FANIN!", 1, "!FANOUT!", 1, "!VOLT!", $VDD);
$nor_outdelay_2_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Gnd", "!FANIN!", 1, "!FANOUT!", 2, "!VOLT!", $VDD);
$nor_outdelay_4_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Gnd", "!FANIN!", 1, "!FANOUT!", 4, "!VOLT!", $VDD);
$nor_outdelay_6_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Gnd", "!FANIN!", 1, "!FANOUT!", 6, "!VOLT!", $VDD);
$nor_outdelay_8_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Gnd", "!FANIN!", 1, "!FANOUT!", 8, "!VOLT!", $VDD);

# with inner input switching
$nor_indelay_1_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Gnd", "!TEMP!", $temp,
			"!INNER!", "Inb", "!FANIN!", 1, "!FANOUT!", 1, "!VOLT!", $VDD);
$nor_indelay_2_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Gnd", "!TEMP!", $temp,
			"!INNER!", "Inb", "!FANIN!", 1, "!FANOUT!", 2, "!VOLT!", $VDD);
$nor_indelay_4_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Gnd", "!TEMP!", $temp,
			"!INNER!", "Inb", "!FANIN!", 1, "!FANOUT!", 4, "!VOLT!", $VDD);
$nor_indelay_6_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Gnd", "!TEMP!", $temp,
			"!INNER!", "Inb", "!FANIN!", 1, "!FANOUT!", 6, "!VOLT!", $VDD);
$nor_indelay_8_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Gnd", "!TEMP!", $temp,
			"!INNER!", "Inb", "!FANIN!", 1, "!FANOUT!", 8, "!VOLT!", $VDD);

# with outer input switching (constant fanin)
$nor_outdelay_1_ac = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Gnd", "!FANIN!", 0.25, "!FANOUT!", 1, "!VOLT!", $VDD);
$nor_outdelay_2_ac = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Gnd", "!FANIN!", 0.5, "!FANOUT!", 2, "!VOLT!", $VDD);
$nor_outdelay_4_ac = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Gnd", "!FANIN!", 1, "!FANOUT!", 4, "!VOLT!", $VDD);
$nor_outdelay_6_ac = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Gnd", "!FANIN!", 1.5, "!FANOUT!", 6, "!VOLT!", $VDD);
$nor_outdelay_8_ac = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Gnd", "!FANIN!", 2, "!FANOUT!", 8, "!VOLT!", $VDD);

# with inner input switching (constant fanin)
$nor_indelay_1_ac = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Gnd", "!TEMP!", $temp,
			"!INNER!", "Inb", "!FANIN!", 0.25, "!FANOUT!", 1, "!VOLT!", $VDD);
$nor_indelay_2_ac = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Gnd", "!TEMP!", $temp,
			"!INNER!", "Inb", "!FANIN!", 0.5, "!FANOUT!", 2, "!VOLT!", $VDD);
$nor_indelay_4_ac = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Gnd", "!TEMP!", $temp,
			"!INNER!", "Inb", "!FANIN!", 1, "!FANOUT!", 4, "!VOLT!", $VDD);
$nor_indelay_6_ac = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Gnd", "!TEMP!", $temp,
			"!INNER!", "Inb", "!FANIN!", 1.5, "!FANOUT!", 6, "!VOLT!", $VDD);
$nor_indelay_8_ac = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Gnd", "!TEMP!", $temp,
			"!INNER!", "Inb", "!FANIN!", 2, "!FANOUT!", 8, "!VOLT!", $VDD);

# with both inputs simultaneously switching
$nor_bdelay_1_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 1, "!VOLT!", $VDD);
$nor_bdelay_2_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 2, "!VOLT!", $VDD);
$nor_bdelay_4_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 4, "!VOLT!", $VDD);
$nor_bdelay_6_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 6, "!VOLT!", $VDD);
$nor_bdelay_8_a = &runsim("gatefodelay", "delayA", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 8, "!VOLT!", $VDD);

$nor_bdelay_1_r = &runsim("gatefodelay", "delayR", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 1, "!VOLT!", $VDD);
$nor_bdelay_2_r = &runsim("gatefodelay", "delayR", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 2, "!VOLT!", $VDD);
$nor_bdelay_4_r = &runsim("gatefodelay", "delayR", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 4, "!VOLT!", $VDD);
$nor_bdelay_6_r = &runsim("gatefodelay", "delayR", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 6, "!VOLT!", $VDD);
$nor_bdelay_8_r = &runsim("gatefodelay", "delayR", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 8, "!VOLT!", $VDD);

$nor_bdelay_1_f = &runsim("gatefodelay", "delayF", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 1, "!VOLT!", $VDD);
$nor_bdelay_2_f = &runsim("gatefodelay", "delayF", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 2, "!VOLT!", $VDD);
$nor_bdelay_4_f = &runsim("gatefodelay", "delayF", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 4, "!VOLT!", $VDD);
$nor_bdelay_6_f = &runsim("gatefodelay", "delayF", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 6, "!VOLT!", $VDD);
$nor_bdelay_8_f = &runsim("gatefodelay", "delayF", "!CORNER!", "TT",
			"!GATE!", "nor2", "!OUTER!", "Inb", "!TEMP!", $temp,
			"!INNER!", "Inb1", "!FANIN!", 2, "!FANOUT!", 8, "!VOLT!", $VDD);

&linearFit($nor_outdelay_1_a, 1, 
	   $nor_outdelay_2_a, 2,
	   $nor_outdelay_4_a, 4,
	   $nor_outdelay_6_a, 6,
	   $nor_outdelay_8_a, 8); # results passed back as $a and $b
$nor_delay_a_out = $a; $nor_delay_b_out = $b;

&linearFit($nor_indelay_1_a, 1, 
	   $nor_indelay_2_a, 2,
	   $nor_indelay_4_a, 4,
	   $nor_indelay_6_a, 6,
	   $nor_indelay_8_a, 8); # results passed back as $a and $b
$nor_delay_a_in = $a; $nor_delay_b_in = $b;

&linearFit($nor_outdelay_1_ac, 1, 
	   $nor_outdelay_2_ac, 2,
	   $nor_outdelay_4_ac, 4,
	   $nor_outdelay_6_ac, 6,
	   $nor_outdelay_8_ac, 8); # results passed back as $a and $b
$nor_delay_a_outc = $a; $nor_delay_b_outc = $b;

&linearFit($nor_indelay_1_ac, 1, 
	   $nor_indelay_2_ac, 2,
	   $nor_indelay_4_ac, 4,
	   $nor_indelay_6_ac, 6,
	   $nor_indelay_8_ac, 8); # results passed back as $a and $b
$nor_delay_a_inc = $a; $nor_delay_b_inc = $b;

&linearFit($nor_bdelay_1_a, 1, 
	   $nor_bdelay_2_a, 2,
	   $nor_bdelay_4_a, 4,
	   $nor_bdelay_6_a, 6,
	   $nor_bdelay_8_a, 8); # results passed back as $a and $b
$nor_delay_a_both = $a; $nor_delay_b_both = $b;

&linearFit($nor_bdelay_1_r, 1, 
	   $nor_bdelay_2_r, 2,
	   $nor_bdelay_4_r, 4,
	   $nor_bdelay_6_r, 6,
	   $nor_bdelay_8_r, 8); # results passed back as $a and $b
$nor_delay_a_both_r = $a; $nor_delay_b_both_r = $b;

&linearFit($nor_bdelay_1_f, 1, 
	   $nor_bdelay_2_f, 2,
	   $nor_bdelay_4_f, 4,
	   $nor_bdelay_6_f, 6,
	   $nor_bdelay_8_f, 8); # results passed back as $a and $b
$nor_delay_a_both_f = $a; $nor_delay_b_both_f = $b;



printf OUT1 "    NAND Delay (both inputs rise) = %5.2f +", 
    $nand_delay_a_both_r*1e12;
printf OUT1 " %5.2f * fanout ps\n", $nand_delay_b_both_r*1e12;
printf OUT1 "    NAND Delay (both inputs fall) = %5.2f +", 
    $nand_delay_a_both_f*1e12;
printf OUT1 " %5.2f * fanout ps\n", $nand_delay_b_both_f*1e12;


printf OUT1 "    NOR Delay (both inputs rise) = %5.2f +", 
    $nor_delay_a_both_r*1e12;
printf OUT1 " %5.2f * fanout ps\n", $nor_delay_b_both_r*1e12;
printf OUT1 "    NOR Delay (both inputs fall) = %5.2f +", 
    $nor_delay_a_both_f*1e12;
printf OUT1 " %5.2f * fanout ps\n", $nor_delay_b_both_f*1e12;

printf OUT1 "    NAND Delay (outer input, constant fanin) = %5.2f +", 
    $nand_delay_a_outc*1e12;
printf OUT1 " %5.2f * fanout ps\n", $nand_delay_b_outc*1e12;
printf OUT1 "    NAND Delay (inner input, constant fanin) = %5.2f +", 
    $nand_delay_a_inc*1e12;
printf OUT1 " %5.2f * fanout ps\n", $nand_delay_b_inc*1e12;


printf OUT1 "    NOR Delay (outer input, constant fanin) = %5.2f +", 
    $nor_delay_a_outc*1e12;
printf OUT1 " %5.2f * fanout ps\n", $nor_delay_b_outc*1e12;
printf OUT1 "    NOR Delay (inner input, constant fanin) = %5.2f +", 
    $nor_delay_a_inc*1e12;
printf OUT1 " %5.2f * fanout ps\n", $nor_delay_b_inc*1e12;



# 18) Threshold Voltage with constant current
$vt_n_0c = &runsim("vt", "vt_n", "!CORNER!", "TT", "!VOLT!", $VDD, "!TEMP!", 0);
$vt_n_70c = &runsim("vt", "vt_n", "!CORNER!", "TT", "!VOLT!", $VDD, "!TEMP!", 70);
$vt_n_120c = &runsim("vt", "vt_n", "!CORNER!", "TT", "!VOLT!", $VDD, "!TEMP!", 125);

$vt_p_0c = &runsim("vt", "vt_p", "!CORNER!", "TT", "!VOLT!", $VDD, "!TEMP!", 0);
$vt_p_70c = &runsim("vt", "vt_p", "!CORNER!", "TT", "!VOLT!", $VDD, "!TEMP!", 70);
$vt_p_120c = &runsim("vt", "vt_p", "!CORNER!", "TT", "!VOLT!", $VDD, "!TEMP!", 125);

# 19) Saturation Current
$idsat_n_0c = &runsim("idsat", "idsat_n", "!CORNER!", "TT", "!VOLT!", $VDD, "!TEMP!", 0);
$idsat_n_0c /= 16*$LAMBDA;
$idsat_n_70c = &runsim("idsat", "idsat_n", "!CORNER!", "TT", "!VOLT!", $VDD, "!TEMP!", 70);
$idsat_n_70c /= 16*$LAMBDA;
$idsat_n_120c = &runsim("idsat", "idsat_n", "!CORNER!", "TT", "!VOLT!", $VDD, "!TEMP!", 125);
$idsat_n_120c /= 16*$LAMBDA;

$idsat_p_0c = &runsim("idsat", "idsat_p", "!CORNER!", "TT", "!VOLT!", $VDD, "!TEMP!", 0);
$idsat_p_0c /= 16*$LAMBDA;
$idsat_p_70c = &runsim("idsat", "idsat_p", "!CORNER!", "TT", "!VOLT!", $VDD, "!TEMP!", 70);
$idsat_p_70c /= 16*$LAMBDA;
$idsat_p_120c = &runsim("idsat", "idsat_p", "!CORNER!", "TT", "!VOLT!", $VDD, "!TEMP!", 125);
$idsat_p_120c /= 16*$LAMBDA;

# 20) Off Current
$ioff_n_0c = &runsim("ioff", "ioff_n", "!CORNER!", "TT", "!VOLT!", $VDD, "!TEMP!", 0);
$ioff_n_0c /= 16*$LAMBDA;
$ioff_n_70c = &runsim("ioff", "ioff_n", "!CORNER!", "TT", "!VOLT!", $VDD, "!TEMP!", 70);
$ioff_n_70c /= 16*$LAMBDA;
$ioff_n_120c = &runsim("ioff", "ioff_n", "!CORNER!", "TT", "!VOLT!", $VDD, "!TEMP!", 125);
$ioff_n_120c /= 16*$LAMBDA;

$ioff_p_0c = &runsim("ioff", "ioff_p", "!CORNER!", "TT", "!VOLT!", $VDD, "!TEMP!", 0);
$ioff_p_0c /= 16*$LAMBDA;
$ioff_p_70c = &runsim("ioff", "ioff_p", "!CORNER!", "TT", "!VOLT!", $VDD, "!TEMP!", 70);
$ioff_p_70c /= 16*$LAMBDA;
$ioff_p_120c = &runsim("ioff", "ioff_p", "!CORNER!", "TT", "!VOLT!", $VDD, "!TEMP!", 125);
$ioff_p_120c /= 16*$LAMBDA;

#Threshold voltage by finding the max slope of I(vds) vs Vgs and interpolating back to the x axis
$maxSlopeVoltP= &runsim("thresvoltp", "at", "!TEMP!", $temp, 
            "!CORNER!", "TT", "!VOLT!", $VDD);
$maxSlopeCurrentP= &runsim("thresvoltpointp", "current", "!TEMP!", $temp, 
            "!CORNER!", "TT", "!VOLT!", $VDD, "!VGS!", $maxSlopeVoltP);

$maxSlopeVoltpPlus=$maxSlopeVoltP+.01;

$maxSlopeCurrentpPlus= &runsim("thresvoltpointp", "current", "!TEMP!", $temp, 
            "!CORNER!", "TT", "!VOLT!", $VDD, "!VGS!", $maxSlopeVoltpPlus);

$slopeP = ($maxSlopeCurrentpPlus-$maxSlopeCurrentP)/($maxSlopeVoltpPlus-$maxSlopeVoltP);

$thresvoltageP = $maxSlopeVoltP-($maxSlopeCurrentP/$slopeP);

$threscurrentP = &runsim("thresvoltpointp", "current", "!TEMP!", $temp, 
            "!CORNER!", "TT", "!VOLT!", $VDD, "!VGS!", $thresvoltageP);
$threscurrentP/=(16*$LAMBDA);

$thresvoltagePminusVDS =$thresvoltageP-.05;
$threscurrentPminusVDS = &runsim("thresvoltpointp", "current", "!TEMP!", $temp, 
            "!CORNER!", "TT", "!VOLT!", $VDD, "!VGS!", $thresvoltagePminusVDS);
$threscurrentPminusVDS/=(16*$LAMBDA);

$maxSlopeVoltN= &runsim("thresvoltn", "at", "!TEMP!", $temp, 
            "!CORNER!", "TT", "!VOLT!", $VDD);
$maxSlopeCurrentN= &runsim("thresvoltpointn", "current", "!TEMP!", $temp, 
            "!CORNER!", "TT", "!VOLT!", $VDD, "!VGS!", $maxSlopeVoltN);

$maxSlopeVoltnPlus=$maxSlopeVoltN+.01;

$maxSlopeCurrentnPlus= &runsim("thresvoltpointn", "current", "!TEMP!", $temp, 
            "!CORNER!", "TT", "!VOLT!", $VDD, "!VGS!", $maxSlopeVoltnPlus);

$slopeN = ($maxSlopeCurrentnPlus-$maxSlopeCurrentN)/($maxSlopeVoltnPlus-$maxSlopeVoltN);

$thresvoltageN = $maxSlopeVoltN-($maxSlopeCurrentN/$slopeN);

$threscurrentN = &runsim("thresvoltpointn", "current", "!TEMP!", $temp, 
            "!CORNER!", "TT", "!VOLT!", $VDD, "!VGS!", $thresvoltageN);

$threscurrentN/=(16*$LAMBDA);
$thresvoltageNminusVDS = $thresvoltageN-.05;
$threscurrentNminusVDS = &runsim("thresvoltpointn", "current", "!TEMP!", $temp, 
            "!CORNER!", "TT", "!VOLT!", $VDD, "!VGS!", $thresvoltageN-.05);

$threscurrentNminusVDS/=(16*$LAMBDA);

close (OUT1);


# Finish timer
$date = &ctime(time); chomp($date); # get current date and strip off newline
$time = time-$time;
#########################################################################
# Print Results
#########################################################################

# This section prints out all the results required by PS2 question 1.
# You should not have to modify it.  However, you will have to add
# simulations to the previous section to compute all of the values
# that are printed in this section.

open (PRINTOUT, ">char_results.out");

print PRINTOUT "\n*** Process Characterization Results ***\n\n";
print PRINTOUT "Process File: $processfile\n";
print PRINTOUT "VDD: $VDD\n";
print PRINTOUT "LAMBDA: $LAMBDA \n";
print PRINTOUT "Run completed $date in $time seconds\n\n";
printf PRINTOUT "    NMOS Gate Overlap Cap fF/um: %5.3f\n", $cap_ndiff_gate*1e15;
printf PRINTOUT "         Area Cap fF/um^2: %5.3f\n", $cap_ndiff_area*1e15;
printf PRINTOUT "         Outer Perimeter Cap fF/um: %5.3f\n", $cap_ndiff_perimeter*1e15;
printf PRINTOUT "         Inner Perimeter Cap fF/um: %5.3f\n", $cap_ndiff_pgate*1e15;
printf PRINTOUT "    NMOS Total Diff Cap fF/um (delay): %5.3f\n", $cap_ndiff*1e15;
printf PRINTOUT "         Shared Contact Diff Cap fF/um (delay): %5.3f\n", $cap_ndiff_shared*1e15;
printf PRINTOUT "         Merged Contact Diff Cap fF/um (delay): %5.3f\n", $cap_ndiff_merged*1e15;
printf PRINTOUT "         Total Diff Cap (calc.) fF/um: %5.3f\n", $cap_ndiff_calc*1e15;
printf PRINTOUT "    Single NMOS Effective Resistance (fanouts 3-4) = %5.2f KOhms*um \n", $nmos_resistance_34/1e3;
printf PRINTOUT "    Series NMOS Effective Resistance (fanouts 3-4) = %5.2f KOhms*um \n", $nmos_series_resistance_34/1e3; 
printf PRINTOUT "    NMOS Threshold Voltage (constant current method)\n";
printf PRINTOUT "      0 C: %5.2f V\n", $vt_n_0c;
printf PRINTOUT "      70 C: %5.2f V\n", $vt_n_70c;
printf PRINTOUT "      125 C: %5.2f V\n", $vt_n_120c;
printf PRINTOUT "    NMOS Threshold Voltage (linear extrapolation method)\n";
printf PRINTOUT "      Vgs=Vto     NMOS = %5.3f V\n", $thresvoltageN; 
printf PRINTOUT "      Ids @ Vgs=Vto NMOS = %5.3f uA/um\n", $threscurrentN*-1e6; 
printf PRINTOUT "      Vgs=Vt      NMOS = %5.3f V\n", $thresvoltageNminusVDS; 
printf PRINTOUT "      Ids @ Vgs=Vt  NMOS = %5.3f uA/um\n", $threscurrentNminusVDS*-1e6; 

printf PRINTOUT "    Saturation Current\n";
printf PRINTOUT "    NMOS:\n";
printf PRINTOUT "      0 C: %5.2f uA/um\n", -$idsat_n_0c*1e6;
printf PRINTOUT "      70 C: %5.2f uA/um\n", -$idsat_n_70c*1e6;
printf PRINTOUT "      125 C: %5.2f uA/um\n", -$idsat_n_120c*1e6;
printf PRINTOUT "    Off Current\n";
printf PRINTOUT "    NMOS:\n";
printf PRINTOUT "      0 C: %5.2f pA/um\n", -$ioff_n_0c*1e12;
printf PRINTOUT "      70 C: %5.2f pA/um\n", -$ioff_n_70c*1e12;
printf PRINTOUT "      125 C: %5.2f pA/um\n", -$ioff_n_120c*1e12;
printf PRINTOUT "    Gate leakage: %5.2f pA/um\n", -$gateleak_n*1e12;

printf PRINTOUT "    PMOS Gate Overlap Cap fF/um: %5.3f\n", $cap_pdiff_gate*1e15;
printf PRINTOUT "         Area Cap fF/um^2: %5.3f\n", $cap_pdiff_area*1e15;
printf PRINTOUT "         Outer Perimeter Cap fF/um: %5.3f\n", $cap_pdiff_perimeter*1e15;
printf PRINTOUT "         Inner Perimeter Cap fF/um: %5.3f\n", $cap_pdiff_pgate*1e15;
printf PRINTOUT "    PMOS Diff Cap fF/um (delay): %5.3f\n", $cap_pdiff*1e15;
printf PRINTOUT "         Shared Contact Diff Cap fF/um (delay): %5.3f\n", $cap_pdiff_shared*1e15;
printf PRINTOUT "         Merged Contact Diff Cap fF/um (delay): %5.3f\n", $cap_pdiff_merged*1e15;
printf PRINTOUT "         Total Diff Cap (calc.) fF/um: %5.3f\n", $cap_pdiff_calc*1e15;
printf PRINTOUT "    Single PMOS Effective Resistance (fanouts 3-4) = %5.2f KOhms*um \n", $pmos_resistance_34/1e3; 
printf PRINTOUT "    Series PMOS Effective Resistance (fanouts 3-4) = %5.2f KOhms*um \n", $pmos_series_resistance_34/1e3; 
printf PRINTOUT "    PMOS Threshold Voltage (constant current method)\n";
printf PRINTOUT "      0 C: %5.2f V\n", $VDD - $vt_p_0c;
printf PRINTOUT "      70 C: %5.2f V\n", $VDD - $vt_p_70c;
printf PRINTOUT "      125 C: %5.2f V\n", $VDD - $vt_p_120c;
printf PRINTOUT "    PMOS Threshold Voltage (linear extrapolation method)\n";
printf PRINTOUT "      Vgs=Vto     PMOS = %5.3f V\n", $thresvoltageP; 
printf PRINTOUT "      Ids @ Vgs=Vto PMOS = %5.3f uA/um\n", $threscurrentP*-1e6; 
printf PRINTOUT "      Vgs=Vt      PMOS = %5.3f V\n", $thresvoltagePminusVDS; 
printf PRINTOUT "      Ids @ Vgs=Vt  PMOS = %5.3f uA/um\n", $threscurrentPminusVDS*-1e6; 
print PRINTOUT "    Saturation Current\n";
print PRINTOUT "    PMOS:\n";
printf PRINTOUT "      0 C: %5.2f uA/um\n", $idsat_p_0c*1e6;
printf PRINTOUT "      70 C: %5.2f uA/um\n", $idsat_p_70c*1e6;
printf PRINTOUT "      125 C: %5.2f uA/um\n", $idsat_p_120c*1e6;
print PRINTOUT "    Off Current\n";
print PRINTOUT "    PMOS:\n";
printf PRINTOUT "      0 C: %5.2f pA/um\n", $ioff_p_0c*1e12;
printf PRINTOUT "      70 C: %5.2f pA/um\n", $ioff_p_70c*1e12;
printf PRINTOUT "      125 C: %5.2f pA/um\n", $ioff_p_120c*1e12;
printf PRINTOUT "    Gate leakage: %5.2f pA/um\n", $gateleak_p*1e12;
printf PRINTOUT "\n";
printf PRINTOUT "    Capacitance fF/um (delay): %5.2f\n", $cap_delay*1e15;
printf PRINTOUT "    Capacitance fF/um (power) - average: %5.2f\n", $cap_power*1e15;
printf PRINTOUT "    Capacitance fF/um (power) - falling: %5.2f\n", $cap_power_f*1e15;
printf PRINTOUT "    Capacitance fF/um (power) - rising: %5.2f\n", $cap_power_r*1e15;
print  PRINTOUT "    Gate Cap \%change / degree C (delay):";
printf PRINTOUT " %5.2f\n", $captempco;
print  PRINTOUT "    Gate Cap \%change / volt (delay):";
printf PRINTOUT " %5.2f\n", $capvoltco;
printf PRINTOUT "    Inverter Delay (FO1): Rise %5.1f ps", $inv_delay_1_r*1e12;
printf PRINTOUT " Fall %5.1f ps", $inv_delay_1_f*1e12;
printf PRINTOUT " Average %5.1f ps\n", $inv_delay_1_a*1e12;
printf PRINTOUT "    Inverter Delay (FO2): Rise %5.1f ps", $inv_delay_2_r*1e12;
printf PRINTOUT " Fall %5.1f ps", $inv_delay_2_f*1e12;
printf PRINTOUT " Average %5.1f ps\n", $inv_delay_2_a*1e12;
printf PRINTOUT "    Inverter Delay (FO3): Rise %5.1f ps", $inv_delay_3_r*1e12;
printf PRINTOUT " Fall %5.1f ps", $inv_delay_3_f*1e12;
printf PRINTOUT " Average %5.1f ps\n", $inv_delay_3_a*1e12;
printf PRINTOUT "    Inverter Delay (FO4): Rise %5.1f ps", $inv_delay_4_r*1e12;
printf PRINTOUT " Fall %5.1f ps", $inv_delay_4_f*1e12;
printf PRINTOUT " Average %5.1f ps\n", $inv_delay_4_a*1e12;
printf PRINTOUT "    Inverter Delay (FO6): Rise %5.1f ps", $inv_delay_6_r*1e12;
printf PRINTOUT " Fall %5.1f ps", $inv_delay_6_f*1e12;
printf PRINTOUT " Average %5.1f ps\n", $inv_delay_6_a*1e12;
printf PRINTOUT "    Inverter Delay (FO8): Rise %5.1f ps", $inv_delay_8_r*1e12;
printf PRINTOUT " Fall %5.1f ps", $inv_delay_8_f*1e12;
printf PRINTOUT " Average %5.1f ps\n", $inv_delay_8_a*1e12;
printf PRINTOUT "    Inverter Delay =";
printf PRINTOUT " %5.1f + %5.1f * fanout ps\n", $inv_delay_a*1e12, 
    $inv_delay_b*1e12;
print  PRINTOUT "    Inverter Delay \%change / degree C:";
printf PRINTOUT " %5.2f\n", $invtempco;
print PRINTOUT  "    Inverter Delay \%change / volt:";
printf PRINTOUT " %5.2f\n", $invvoltco;


printf PRINTOUT "    FO4 NAND Delay:  Rise %5.1f ps", $nand_delay_r*1e12;
printf PRINTOUT " Fall %5.1f ps", $nand_delay_f*1e12;
printf PRINTOUT " Average %5.1f ps\n", $nand_delay_a*1e12;
printf PRINTOUT "    FO4 NOR Delay:  Rise %5.1f ps", $nor_delay_r*1e12;
printf PRINTOUT " Fall %5.1f ps", $nor_delay_f*1e12;
printf PRINTOUT " Average %5.1f ps\n",  $nor_delay_a*1e12;
printf PRINTOUT "    NAND Delay (inner input) = %5.1f +", 
    $nand_delay_a_in*1e12;
printf PRINTOUT " %5.2f * fanout ps\n", $nand_delay_b_in*1e12;
printf PRINTOUT "    NAND Delay (outer input) = %5.2f +", 
    $nand_delay_a_out*1e12;
printf PRINTOUT " %5.2f * fanout ps\n", $nand_delay_b_out*1e12;
printf PRINTOUT "    NAND Delay (both inputs) = %5.2f +", 
    $nand_delay_a_both*1e12;
printf PRINTOUT " %5.2f * fanout ps\n", $nand_delay_b_both*1e12;

printf PRINTOUT "    NOR Delay (inner input) = %5.2f +", $nor_delay_a_in*1e12;
printf PRINTOUT " %5.2f * fanout ps\n", $nor_delay_b_in*1e12;
printf PRINTOUT "    NOR Delay (outer input) = %5.2f +", $nor_delay_a_out*1e12;
printf PRINTOUT " %5.2f * fanout ps\n", $nor_delay_b_out*1e12;
printf PRINTOUT "    NOR Delay (both inputs) = %5.2f +", 
    $nor_delay_a_both*1e12;
printf PRINTOUT " %5.2f * fanout ps\n", $nor_delay_b_both*1e12;




close (PRINTOUT);

#########################################################################
# Subroutines
#########################################################################

# The subroutines provide a quick way to kick off simulations
# and extract the results computed by SPICE.  
#
# The spice deck should follow a format similar to that shown
# in the example.

# sub runsim
#
# This subroutine takes the name of the HSPICE deck and a measured
# parameter value to extract as inputs.
# It substitutes the values of VDD and processfile you provide
# for the variables !VDD! and !LIB! in the HSPICE deck and
# also handles any other substitutions you passed.  It then
# runs HSPICE and extracts the value of the parameter you specified found
# by a .measure statement in the deck.

sub runsim {
    $olddeckname = $deckname;
    @old = @subs; # save old arguments
    @subs = @_; # Grab list of arguments to substitute

    $deckname = shift(@subs); # Grab deckname passed to runsim
    $measure = shift(@subs); # Grab parameter to measure

    print "Extracting $measure from $deckname with:\n  ";
    for ($i=0; $i<=$#subs; $i+=2) {
	print "$subs[$i] = $subs[$i+1]  ";
    }
    print "\n";

    # If old arguments are the same as new ones, recycle old results
    $recycle = 1;
    for ($i=0; $i<=$#subs; $i++) {
	if (($old[$i] ne $subs[$i])||($olddeckname ne $deckname)) {
	    $recycle = 0;
	}
    }
    if ($recycle != 1) {
	# Open the spice deck and a temporary output file
	open(DECK, $deckname.".hsp") 
	    || die("Can't open $deckname.hsp: $!\n");
	open(OUT, "> temp_deck.hsp") || die("Can't open temp_deck.hsp: $!\n");

	# Read each line of the deck, substitute VDD & procfile, write out
	while (<DECK>) {
	    s/!SUP!/$VDD/g;
	    s/!LAMBDA!/$LAMBDA/g;
	    s/!LIB!/$processfile/g;
	    for ($i=0; $i<=$#subs; $i+=2) { 
		s/$subs[$i]/$subs[$i+1]/g; # replace all occurrences
	    }
	    if ($fetmode == 1) {
		s/nmos/nfet/gi;
		s/pmos/pfet/gi;
	    }
	    print OUT $_;
	}
	print "Not recycling\n";
	# Close files
	close(OUT);
	close(DECK);

	# Run HSPICE simulation
	# Close STDERR while running to avoid messages printed by SPICE
	open(SAVEERR, ">&STDERR");
	close(STDERR);
	system("hspice temp_deck.hsp > temp_deck.lis"); # for Unix
#	system("hspice temp_deck.lis temp_deck.hsp"); # for Windows
#	system("hspice temp_deck.hsp temp_deck.lis"); # for Windows with 2007 HSPICE
	open(STDERR, ">&SAVEERR");
	close(SAVEERR);
    }

    # Extract result from output file
    open(RESULT, "temp_deck.lis") || die("Can't open temp_deck.lis: $!\n");
    $result = "";
    while (<RESULT>) {
	if (/\*\*error/) { # HSPICE produced an error
	    print STDERR "$_";
	    $next = <RESULT>;
	    die("$next");
	}
	if (/\s*$measure\s*=\s*(\S+)/i) { # Search for $measure = xxx
	    $result = $1; last; # and record xxx
	}
    }
    if ($result eq "") {
	die ("Couldn't find $measure\n");
    }
	close(RESULT);
    return $result;
}

# sub linearFit
#
# This subroutine takes a list of (y, x) pairs and does a least squares
# curve fit to the equation y = a + b*x.  It leaves a and b in
# global variables $a and $b.
#
# Least squares finds the best solution to Ap=q:
# 
# p' = [a b]^T = (A^T * A)^-1 * A^T * q
#
# where ^T indicates transpose and ^-1 indicates inverse.
# A is the matrix: [ 1 x1 ]
#                  [ 1 x2 ]
#                  [ 1 x3 ]
#                    ...
#                  [ 1 xm ]
# p' is [a b]^T, the best solution,  and q is [y1 y2 y3 ... ym]^T.
#
# This math isn't very important; as long as you call the subroutine
# as given in the inverter example, you should get the right answer.

sub linearFit {
    @input = @_; # in format (y1, x1, y2, x2, y3, x3, ..., ym, xm)

    # compute A^T * A
    $prod[0] = $prod[1] = $prod[2] = $prod[3] = 0;
    for ($i = 0; $i <= $#input; $i += 2) {
	$prod[0]++;
	$prod[1] += $input[$i+1];
	$prod[2] += $input[$i+1];
	$prod[3] += $input[$i+1]*$input[$i+1];
    }
    
    # invert A^T * A
    $det = $prod[0] * $prod[3] - $prod[1] * $prod[2]; 
    if ($det == 0) { # trap error
	print " Error: division by zero during least squares\n";
	$a = 0; $b = 0;
	return;
    }

    $inv[0] = $prod[3]/$det;
    $inv[1] = -$prod[1]/$det;
    $inv[2] = -$prod[2]/$det;
    $inv[3] = $prod[0]/$det;

    # compute A^T * q
    $atq[0] = $atq[1] = 0;
    for ($i=0; $i <= $#input; $i += 2) {
	$atq[0] += $input[$i];
	$atq[1] += $input[$i] * $input[$i+1];
    }

    # compute p' = INV * ATQ
    $a = $inv[0] * $atq[0] + $inv[1] * $atq[1];
    $b = $inv[2] * $atq[0] + $inv[3] * $atq[1];

    
}
