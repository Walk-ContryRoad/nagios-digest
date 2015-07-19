#!/usr/bin/perl
################################################################################
#
#	Program:	Nagios Digest
#
#	Author:		Tim Schaefer, tim@asystemarchitect.com
#
#	Description:	Prints Report of all "not-OK" information from
#			Nagios'  /var/log/nagios/status.dat
#
#	Args:		dbg		allows you to see debug statements
#			stats		location of Nagios' status.dat
#			recipient	the recipient of the report
#			level		0,1,2,3 
#					( OK,WARNING,CRITICAL,UNKNOWN )
#			only		[Y|N] - defaults to N.
#
#			"only" means "only this level or any level >= to it.
#
#			enabled		[E|D|A]
#			E - Show only services with notification enabled
#			D - Show only services with notification disabled
#			A - Show services with notification enabled or disabled
#			( default = A )
#
#	Usage:		Level can be set as "only this level, yes or no" or
#			all levels greater than this level.  If you say 
#			only=Y, then only that level will be reported otherwise
#			only=N will produce that level or greater than that
#			level.
#
#	Notes:		Using level 0 will produce huge output if you're on a
#			large Nagios system.  You -can- use level 0 but it's
#			not recommended if you have a lot of host-objects and
#			services.
#			
#			Please see the wrapper shell script for examples of how
#			to use this program.
#
################################################################################

	use CGI ;
	use POSIX ;

	$co               =  new CGI ;

        my $dbg           = $co->param("dbg");
           $dbg           = ($dbg)?"$dbg" : 'N' ;

	my $stats         = $co->param("stats") ;
           $stats         = ($stats)?"$stats" : 'NULL' ;

        my $recipient     = $co->param("recipient");
           $recipient     = ($recipient)?"$recipient" : "NULL" ;

	my $level         = $co->param("level") ;
           $level         = ($level)?"$level" : 0 ;

	my $only         = $co->param("only") ;
           $only         = ($only)?"$only" : 'N' ;

	my $mime          = $co->param("mime");
	   $mime          = ($mime)?"$mime" : 'H' ;

	my $enabled       = $co->param("enabled");
	   $enabled       = ($enabled)?"$enabled" : 'A' ;

	$p_level          = "" ;
	$p_level_bkg      = "" ;
	$p_level_suffix   = "" ; 
	$p_level_color    = "" ; 

	if( $level == 0 ) { $p_level = 'OK';       $p_level_bkg = 'LIME';    $p_level_color = 'BLACK' ;}
	if( $level == 1 ) { $p_level = 'WARNING';  $p_level_bkg = 'YELLOW';  $p_level_color = 'BLACK' ;}
	if( $level == 2 ) { $p_level = 'CRITICAL'; $p_level_bkg = 'RED';     $p_level_color = 'WHITE' ;}
	if( $level == 3 ) { $p_level = 'UNKNOWN';  $p_level_bkg = 'ORANGE';  $p_level_color = 'WHITE' ;}

	if( $level > 0 ) 
		{ 
		$p_level_suffix =  $p_level . ' Alerts' ; 
		}
	else	{
		$p_level_suffix =  $p_level . ' Status' ; 
		}

        my $subject       = "Nagios Email Reports: " . $p_level_suffix ;

	if( $enabled eq 'E' ) { $sub_title = " Services that have notifications enabled. " ; }
	if( $enabled eq 'D' ) { $sub_title = " Services that have notifications disabled. " ; }
	if( $enabled eq 'A' ) { $sub_title = " Services that have notifications enabled or disabled. " ; }

	if( $recipient eq 'NULL' )
		{
		print STDERR "Recipient cannot be NULL.  Please add an email recipient=recipient\@email_server to the command-line when running this program\n" ;
		}

	$email_program = "/usr/sbin/sendmail" ;

        my $smtp_hostname    = `hostname` ;
           chomp $smtp_hostname ;

	my $new_line         = "" ;
	my $current_state    = "" ;
	my $plugin_output    = "" ;

	my $to               = "" ;
	my $from             = "" ;

	$from                = "Nagios Central Command < nagios\@${smtp_hostname} > " ;
	$to                  = $recipient ;

	my $contact_url      = "<a href=mailto:$recipient?subject=$subject_url >$recipient</a>" ;

	$background_color    = "#cfcfcf" ;
	$td_title_cell_color = "#dfdfdf" ;
	$td_font_color       = "black"   ;

	my $message ;
	my %report_data ;

	if( $stats )
		{
		open( STATS, "<$stats" ) ;
		@statsdata = <STATS> ;
		close ( STATS ) ;
		}

	$hash_idx  = 0 ;
	$idx       = 0 ;
	$rows      = 0 ;

	$print_flag = 0 ;

	foreach $line ( @statsdata )
		{
		chomp $line ;

		if( $line =~ /	host_name/ ) 
			{ 
			@hostname      = split( '=', $line ) ;
			$host_name     = $hostname[1] ;
			$hash_idx      = sprintf( "%4.4d", $idx ) ;
			$h_key         = $host_name . "_" . $hash_idx ;
			$new_line      = "" ;
			$current_state = "" ;
			$plugin_output = "" ;
			}

		if( $line =~ /	service_description/ ) 
			{ 
			@service_description  = split( '=', $line ) ;
			$service_description = $service_description[1]  ; 
			}

		if( $line =~ /	current_state/ ) 
			{ 
			@currentstate  = split( '=', $line ) ;
			$current_state = $currentstate[1] ;
			}

		if( $line =~ /	plugin_output/ ) 
			{ 
			@pluginoutput  = split( '=', $line ) ;
			$plugin_output = $pluginoutput[1]  ; 
			}

		if( $line =~ /	notifications_enabled/ ) 
			{ 
			@notificationsenabled  = split( '=', $line ) ;
			$notifications_enabled = $notificationsenabled[1]  ; 
			}

		if( $line =~ /	last_check/ ) 
			{ 
			@lastcheck     = split( '=', $line ) ;
			$last_check    = $lastcheck[1]  ; 
			$l_check       = cnvt_epoch_to_timestring( $last_check ) ;
			}

		if( $line =~ /	next_check/ ) 
			{ 
			@nextcheck  = split( '=', $line ) ;
			$next_check = $nextcheck[1]  ; 
			if( $next_check > 0 )
				{
				$n_check = cnvt_epoch_to_timestring( $next_check ) ;
				}
			else	{
				$n_check = "PASV" ;
				}
			}

		if( $line =~ /	last_update/ ) 
			{ 
			@lastupdate  = split( '=', $line ) ;
			$last_update = $lastupdate[1]  ; 
			$l_update    = cnvt_epoch_to_timestring( $last_update ) ;

			$print_flag = 0 ;

			if( $enabled eq 'A' )
				{
				$print_flag = 1 ;
				}

			if( $enabled eq 'D' )
				{
				if ( $notifications_enabled == 0 )
					{
					$print_flag = 1;
					}
				}

			if( $enabled eq 'E' )
				{
				if ( $notifications_enabled == 1 )
					{
					$print_flag = 1;
					}
				}

			if( $print_flag == 1 )
				{
				if( $plugin_output )
					{

					if( $only eq 'N' ) 
						{ 
						if( $current_state >= $level )
							{
							$new_line              = sprintf "$current_state|$host_name|$service_description|$l_check|$n_check|$l_update|$notifications_enabled|$plugin_output"  ; 
							$combo_key             = $current_state . "_" .  $h_key ;
							$data_hash{$combo_key} = "$new_line" ;
							++$rows ;
							}
						}

					if( $only eq 'Y' ) 
						{ 
						if( $current_state == $level )
							{
							$new_line              = sprintf "$current_state|$host_name|$service_description|$l_check|$n_check|$l_update|$notifications_enabled|$plugin_output"  ; 
							$combo_key             = $current_state . "_" .  $h_key ;
							$data_hash{$combo_key} = "$new_line" ;
							++$rows ;
							}
						}
					}
				}
			}

		++$idx ;
		}

	build_report();

        open( OUT, "|$email_program -i -t" ) ;

print OUT <<ENDOFMESSAGE;
$message
ENDOFMESSAGE

	close( OUT ) ;

	exit 0 ;

################################################################################

sub build_report {

$header_row = <<ENDOFROW;

<tr>
<td class=titlecell ><b>State</b></td>
<td class=titlecell ><b>Host Name</b></td>
<td class=titlecell ><b>Notifications</b></td>
<td class=titlecell ><b>Service</b></td>
<td class=titlecell ><b>Plugin Output</b></td>
</tr>

ENDOFROW

$message = <<ENDOFMESSAGE;
From: $from
To: $to
Subject: $subject
Mime-Version: 1.0
Content-type: text/html; charset="iso-8859-1"


<style type=text/css>
a           	{ text-decoration: none; color: #63309C ; border:0px; font-size:9px; font-weight:bold; font-family:arial,helvetica,sans-serif;  }
a:link      	{ text-decoration: none; color: #63309C ; border:0px; font-size:9px; font-weight:bold; font-family:arial,helvetica,sans-serif;  }
a:visited   	{ text-decoration: none; color: #63309C ; border:0px; font-size:9px; font-weight:bold; font-family:arial,helvetica,sans-serif;  }
a:hover     	{ text-decoration: none; color: #63309C ; border:0px; font-size:9px; font-weight:bold; font-family:arial,helvetica,sans-serif;  }
a:active    	{ text-decoration: none; color: blue    ; border:0px; font-size:9px; font-weight:bold; font-family:arial,helvetica,sans-serif;  }

body	{
	border-radius:5px;
	font-family:arial,helvetica ;
	}

td	{
	empty-cells: show ;
	border:1px solid #cfcfcf;
	border-radius:5px;
	padding:2px;
	margin:2px;
	font-size: 8px;
	color: black ;
	font-family:arial,helvetica ;
	vertical-align:middle;
	}

.titlecell	{
	padding:2px;
	margin:2px;
	border-radius:5px;
	border:1px solid #cfcfcf ;
	text-align:center;
	width:* ;
	max-width:* ;
	font-size: 14px;
	background-color: $td_title_cell_color ;
	color: $td_font_color ;
	font-family:arial,helvetica ;
}

</style>

<body>
<center>
<font style='font-family: arial,helvetica; font-size: 10px;' >

<table width=100% >
<tr>
<td style='text-align:left; background-color: white; border:1px solid #dfdfdf; font-size:12px; ' colspan=10 >
	<table width=100% border=0 >
	<tr>
	<td align=left style='font-size:18px; border:0px; ' ><b>
	Nagios Digest 
	</td>
	<td align=right style='font-size:12px; border:0px; ' ><b>
	<a href=http://www.nagios.com ><img src="http://assets.nagios.com/images/header/Nagios.png" style='width:75px; border:0px;' ></a>
	</td>
	</tr>
	</table>
</td>

</tr>

<tr>
<td style='text-align:center; background-color: white; border:1px solid #dfdfdf; font-size:16px; ' colspan=10 ><b>
<i>Nagios Server <a style='font-size:16px;' href=http://$smtp_hostname/nagios >$smtp_hostname</a>
</td>
</tr>

<tr>
<td style='text-align:center; background-color: white; border:1px solid #dfdfdf; font-size:12px; ' colspan=10 >
<i>$sub_title
</td>
</tr>

<tr>
<td style='text-align:center; background-color: $p_level_bkg ; border:1px solid #dfdfdf; font-size:11px; color:$p_level_color; ' colspan=10 >
$rows $p_level_suffix 
</td>
</tr>

<tr>
<td style='text-align:center; background-color: white ; border:1px solid #dfdfdf; font-size:11px; color:black; ' colspan=10 >
<a href=http://$smtp_hostname/nagios/cgi-bin/status.cgi?host=all&servicestatustypes=28 >All Problems</a>
</td>
</tr>

ENDOFMESSAGE

$message .= $header_row ;

	if( $rows > 0 )
		{

		$p_current_state = "" ;
		$p_host_name     = " " ;
		$p_l_check       = "" ;
		$p_n_check       = "" ;
		$p_l_update      = "" ;
		$p_plugin_output = "" ;
		$last_host_name  = "" ;
        	$count           = 0 ;

		$p_notifications_enabled_text = "" ;

		$print_flag = 0 ;

        	foreach $k ( sort keys %data_hash )
                	{

                	@fields = split( '\|', $data_hash{$k} ) ;
                	$cols = scalar @fields ;

			$p_current_state         = "" ;
			$p_host_name             = "" ;
			$p_l_check               = "" ;
			$p_n_check               = "" ;
			$p_l_update              = "" ;
			$p_notifications_enabled = "" ;
			$p_plugin_output         = "" ;

			$p_current_state         = $fields[0] ;
			$p_host_name             = $fields[1] ;
			$p_service_description   = $fields[2] ;
			$p_l_check               = $fields[3] ;
			$p_n_check               = $fields[4] ;
			$p_l_update              = $fields[5] ;
			$p_notifications_enabled = $fields[6] ;
			$p_plugin_output         = $fields[7] ;

			$nagios_url  = "<a href=http://" . $smtp_hostname . "/nagios/cgi-bin/extinfo.cgi?type=2&host=" ;
			$nagios_url .= $p_host_name . "&service=" . $p_service_description . " >" ;
			$nagios_url .= $p_service_description   ;
			$nagios_url .= "</a>"   ;

			if( $p_notifications_enabled == 1 )
				{
				$p_notifications_enabled_text = "<b>ENABLED</b>" ;
				$p_notify_bkg                 = "#d3eda7" ;
				}

			if( $p_notifications_enabled == 0 )
				{
				$p_notifications_enabled_text = "<i>DISABLED</i>" ;
				$p_notify_bkg                 = "#dfdfdf" ;
				}

			if( $p_current_state eq '0' )
				{
				$p_current_state_text = "OK" ;
				$p_background_color   = "LIME" ;
				}

			if( $p_current_state eq '1' )
				{
				$p_current_state_text = "WARNING" ;
				$p_background_color   = "YELLOW" ;
				}

			if( $p_current_state eq '2' )
				{
				$p_current_state_text = "CRITICAL" ;
				$p_background_color   = "RED" ;
				}

			if( $p_current_state eq '3' )
				{
				$p_current_state_text = "UNKNOWN" ;
				$p_background_color   = "ORANGE" ;
				}

			#
			# creates break for each host-object
			#
			# if( $p_host_name ne $last_host_name )
				# {
				# $message .= "<tr>\n" ;
				# $message .= "<td style='text-align:left; background-color: white; border:1px solid #cfcfcf; font-size:18px; ' colspan=10 ><b>" ;
				# $message .= $p_host_name ;
				# $message .= "</b></td>" ;
				# $message .= $header_row ;
				# }

			$message .= "<tr>\n" ;
			$message .= "<td style='text-align:center; background-color:$p_background_color; min-width:50px; ' >" ;
			$message .= $p_current_state_text ;
			$message .= "</td>" ;

			$message .= "<td " ;
			$message .= " title=\" " ;
			$message .= " $p_host_name - Last Update: $p_l_update " ;
			$message .= " \" " ;
			$message .= " style='text-align:center; min-width:200px; ' >" ;
			$message .= "<a href=http://" . $smtp_hostname . "/nagios/cgi-bin/status.cgi?host=" . $p_host_name . ">" ;
			$message .= $p_host_name     ;
			$message .= "</a>" ;
			$message .= "</td>" ;

			$message .= "<td style='text-align:center; min-width:50px; background-color:$p_notify_bkg; ' >" ;
			$message .= $p_notifications_enabled_text ;
			$message .= "</td>" ;

			$message .= "<td style='text-align:center; min-width:120px; ' >" ;
			$message .= $nagios_url ;
			$message .= "</td>" ;

			$message .= "<td style='text-align:left; min-width:100px; ' >" ;
			$message .= $p_plugin_output ;
			$message .= "</td>" ;

			$message .= "</tr>\n" ;

			$last_host_name = $p_host_name ;
			}
		}
	else	{
$message .= <<ENDOFHTML;

<tr>
<td colspan=7><i>No Alerts</td>
</tr>

ENDOFHTML
		}

$message .= <<ENDOFHTML;

<tr>
<td style='text-align:center; background-color: white ; border:1px solid #dfdfdf; font-size:11px; color:black; ' colspan=10 >
<a href=http://$smtp_hostname/nagios/cgi-bin/status.cgi?host=all&servicestatustypes=28 >All Problems</a>
</td>
</tr>


</table>
</body>
</html>

ENDOFHTML

}

################################################################################

sub cnvt_epoch_to_timestring {

        my $epoch          = $_[0] ;
        my $formatted_time = strftime("%Y-%m-%d %H:%M:%S", localtime($epoch) ) ;

        return $formatted_time ;
}

################################################################################
