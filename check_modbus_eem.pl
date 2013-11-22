#!/usr/bin/perl

# Autor: Marcel Fischer
#
# Changelog:
# - 20.11.2013 Version 1
#       - First Release
#
# Todo:
# - option for warning and critical values
# - write pnp template


use strict;
use Getopt::Long;
use MBclient;

my $PLUGIN_VERSION="1.0";

# Variables
my $help;
my $version;
my $hostname = "localhost";
my $unit_id = undef;
my $register = undef;
my $quantity = "2";
my $mode = "";

my $registerL1 = undef;
my $registerL2 = undef;
my $registerL3 = undef;
my $registerN = undef;

my $result_final = undef;
my $perfdata_final = undef;

Getopt::Long::Configure('bundling');
GetOptions
	("H=s" => \$hostname,
	 "U=i" => \$unit_id,
	 "R=i" => \$register,
	 "Q=i" => \$quantity,
	 "M=s" => \$mode,
	 "h" => \$help,
	 "v" => \$version);

if ($help) {
	help();
	exit 0;
}

if ($version) {
	print "Version = ".$PLUGIN_VERSION."\n";
	exit 0;
}


if ($mode eq "Currents") {
	$registerL1 = "50528";
	$registerL2 = "50530";
	$registerL3 = "50532";
	$registerN = "50534";
	my $resultL1 = read_registers("$registerL1")/1000;
	my $resultL2 = read_registers("$registerL2")/1000;
	my $resultL3 = read_registers("$registerL3")/1000;
	my $resultN = read_registers("$registerN")/1000;
	$result_final = $mode." OK - L1 is ".$resultL1."A , L2 is ".$resultL2."A , L3 is ".$resultL3."A , N is ".$resultN."A";
	$perfdata_final = " | currents_L1=".$resultL1.";;;; currents_L2=".$resultL2.";;;; currents_L3=".$resultL3.";;;; currents_N=".$resultN.";;;;";
}

if ($mode eq "Voltages") {
        $registerL1 = "50520";
        $registerL2 = "50522";
        $registerL3 = "50524";
        my $resultL1 = read_registers("$registerL1")/100;
        my $resultL2 = read_registers("$registerL2")/100;
        my $resultL3 = read_registers("$registerL3")/100;
        $result_final = $mode." OK - L1 is ".$resultL1."V , L2 is ".$resultL2."V , L3 is ".$resultL3."V";
        $perfdata_final = " | voltages_L1=".$resultL1.";;;; voltages_L2=".$resultL2.";;;; voltages_L3=".$resultL3.";;;;";
}

if ($mode eq "Voltages2") {
        $registerL1 = "50514";
        $registerL2 = "50516";
        $registerL3 = "50518";
        my $resultL1 = read_registers("$registerL1")/100;
        my $resultL2 = read_registers("$registerL2")/100;
        my $resultL3 = read_registers("$registerL3")/100;
        $result_final = $mode." OK - L12 is ".$resultL1."V , L23 is ".$resultL2."V , L31 is ".$resultL3."V";
        $perfdata_final = " | voltages_L12=".$resultL1.";;;; voltages_L23=".$resultL2.";;;; voltages_L31=".$resultL3.";;;;";
}

if ($mode eq "Power") {
        my $registerCurrentsL1 = "50528";
        my $registerCurrentsL2 = "50530";
        my $registerCurrentsL3 = "50532";
        my $resultCurrentsL1 = read_registers("$registerCurrentsL1")/1000;
        my $resultCurrentsL2 = read_registers("$registerCurrentsL2")/1000;
        my $resultCurrentsL3 = read_registers("$registerCurrentsL3")/1000;

        my $registerVoltagesL1 = "50520";
        my $registerVoltagesL2 = "50522";
        my $registerVoltagesL3 = "50524";
        my $resultVoltagesL1 = read_registers("$registerVoltagesL1")/100;
        my $resultVoltagesL2 = read_registers("$registerVoltagesL2")/100;
        my $resultVoltagesL3 = read_registers("$registerVoltagesL3")/100;
	
	my $resultKWL1 = $resultCurrentsL1*$resultVoltagesL1/1000;
	my $resultKWL2 = $resultCurrentsL2*$resultVoltagesL2/1000;
	my $resultKWL3 = $resultCurrentsL3*$resultVoltagesL3/1000;
	$resultKWL1 = sprintf("%.2f", $resultKWL1);
	$resultKWL2 = sprintf("%.2f", $resultKWL2);
	$resultKWL3 = sprintf("%.2f", $resultKWL3);

        $result_final = $mode." OK - L1 is ".$resultKWL1."kW , L2 is ".$resultKWL2."kW , L3 is ".$resultKWL3."kW";
        $perfdata_final = " | power_L1=".$resultKWL1.";;;; power_L2=".$resultKWL2.";;;; power_L3=".$resultKWL3.";;;;";
	
}


if (($mode eq "") && ($register gt 0)) {
	my $result = read_registers("$register");
	$result_final = "OK - Value is ".$result;
	$perfdata_final = " | value=".$result.";;;;";
}

print $result_final;
print $perfdata_final."\n";

sub read_registers {
	my $register = $_[0];
	my $wordresult = undef;
	my $m = MBclient->new();
	$m->host($hostname);
	$m->unit_id($unit_id);
	my $words = $m->read_holding_registers($register, $quantity);
		foreach my $word (@$words) {
			if ($word > 0) {
				$wordresult=$word;
			}
		}
	$m->close();
	return $wordresult;
}

sub help {
	print "This plugin checks the phoenix contact pmm-ma600 devices over modbus tcp\n";
	print "You need to have an ethernet module and you need to active modbus tcp on your device\n\n";
	print "Version = ".$PLUGIN_VERSION."\n";
	
	print "Usage:\n\n";
	print "-h	print help\n";
	print "-H	Hostname or IP\n";
	print "-U	Unit or Slave ID (Modbus Parameter)\n";
	print "Now you need to choose between\n";
	print "-M	Mode\n";
	print "or\n";
	print "-Q	Quantity (Modbus Parameter)\n";
	print "-R	Register (Modbus Parameter)\n\n";

	print "Modes:\n";
	print "Currents, Voltages, Voltages2, Power\n\n";

}

#Debug stuff
#print $m->last_except()."\n";
#print $m->last_error()."\n";
exit 0;
