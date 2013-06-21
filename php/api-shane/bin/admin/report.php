<pre>
<?php
$persona = '';
if( isset( $_REQUEST['persona'] ) ){
    $persona = $_REQUEST['persona'];
}
require_once 'vendor/autoload.php';
$r = new BIM_Growth_Reports();
$report = $r->getReportData( $persona );

$tumblrStats = $r->getSocialStatsForTumblr();
?>
</pre>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
	<head>
		<meta http-equiv="Content-type" content="text/html; charset=utf-8">
		<title>Growth Reports</title>
		<style type="text/css" media="screen">
			@import "assets/css/site_jui.ccss";
			@import "assets/css/demo_table_jui.css";
			@import "assets/css/jquery-ui-1.7.2.custom.css";
			
			/*
			 * Override styles needed due to the mix of three different CSS sources! For proper examples
			 * please see the themes example in the 'Examples' section of this site
			 */
			.dataTables_info { padding-top: 0; }
			.dataTables_paginate { padding-top: 0; }
			.css_right { float: right; }
			#example_wrapper .fg-toolbar { font-size: 0.8em }
			#theme_links span { float: left; padding: 2px 10px; }
			#example_wrapper { -webkit-box-shadow: 2px 2px 6px #666; box-shadow: 2px 2px 6px #666; border-radius: 5px; }
			#example tbody {
				border-left: 1px solid #AAA;
				border-right: 1px solid #AAA;
			}
			#example thead th:first-child { border-left: 1px solid #AAA; }
			#example thead th:last-child { border-right: 1px solid #AAA; }
		</style>
		
		<script type="text/javascript" src="assets/js/complete.min.js"></script>
		<script type="text/javascript" src="assets/js/jquery.dataTables.min.js"></script>
		<script type="text/javascript">
			function fnFeaturesInit ()
			{
				/* Not particularly modular this - but does nicely :-) */
				$('ul.limit_length>li').each( function(i) {
					if ( i > 10 ) {
						this.style.display = 'none';
					}
				} );
				
				$('ul.limit_length').append( '<li class="css_link">Show more<\/li>' );
				$('ul.limit_length li.css_link').click( function () {
					$('ul.limit_length li').each( function(i) {
						if ( i > 5 ) {
							this.style.display = 'list-item';
						}
					} );
					$('ul.limit_length li.css_link').css( 'display', 'none' );
				} );
			}
			
			$(document).ready( function() {
				fnFeaturesInit();
				var params =  {
					"bJQueryUI": true,
					"sPaginationType": "full_numbers"
				};
				$('#example').dataTable( params );
				$('#example2').dataTable( params );
				$('#example3').dataTable( params );
				$('#example4').dataTable( params );
				
				SyntaxHighlighter.config.clipboardSwf = 'media/javascript/syntax/clipboard.swf';
				SyntaxHighlighter.all();
			} );
		</script>
		
	</head>
<body id="index" class="grid_2_3">

<div id="fw_container">
<div class="fg-toolbar ui-toolbar ui-widget-header ui-corner-tl ui-corner-tr ui-helper-clearfix">
	<div class="dataTables_length">
		<label>
			&nbsp; &nbsp;Select Persona:  
			<select size="1" id="persona_picker" onChange='location.href = "?persona=" + $("#persona_picker").val();'>
			<?php 
			//print_r( $report->personaTotals ); exit;
			$personas = $r->getPersonaNames();
			sort( $personas );
			foreach( $personas as $personaName ){
			    $selected = "";
			    if( $personaName == $persona ){
			        $selected = "selected='selected'";
			    }
			    echo("<option value='$personaName' $selected >$personaName</option>");
			} 
			?>
			</select> 
		</label>
	</div>
	<div class="dataTables_filter">
		<label>
			Search: <input type="text"">
		</label>
	</div>
</div>
<hr>
<?php if( $persona ){?>
<div class="fg-toolbar ui-toolbar ui-widget-header ui-corner-tl ui-corner-tr ui-helper-clearfix">
	<div class="dataTables_length">
		Showing report for <?php echo $persona; ?>
	</div>		
</div>
<?php }?>
<div>
This is where te user details will be going
</div>
<hr>
<div id="fw_content">
    <h3>Totals</h3>
    <div class="full_width">
        <table cellpadding="0" cellspacing="0" border="0" class="display" id="example" style="width:980px">
        	<thead>
        		<tr>
        			<th>Overall</th>
        			<?php $networks = get_object_vars( $report->totals->byNetwork ); ?>
        			<?php foreach( $networks as $network => $data ) {?>
        			<th style="text-align: center;"><?php echo $network;?></th>
        			<?php }?>
        			<th style="text-align: center;">Total</th>
        		</tr>
        	</thead>
        	<tbody>
        		<tr class="gradeA">
        			<td>Overall</td>
        			<?php $networks = get_object_vars( $report->totals->byNetwork ); ?>
        			<?php foreach( $networks as $network => $data ) {?>
        			<td class="center"><?php echo $report->totals->byNetwork->$network->total;?></td>
        			<?php }?>
        			<td><?php echo $report->totals->total; ?></td>
        		</tr>
        	</tbody>
        </table>
    </div>
    
    <br><br>
    <h3>Monthly Totals</h3>
    <div class="full_width">
        <table cellpadding="0" cellspacing="0" border="0" class="display" id="example2" style="width:980px">
        	<thead>
        		<tr>
        			<th>Month</th>
        			<?php $networks = get_object_vars( $report->totals->byNetwork ); ?>
        			<?php foreach( $networks as $network => $data ) {?>
        			<th class="center"><?php echo $network;?></th>
        			<?php }?>
        			<th class="center">Total</th>
        		</tr>
        	</thead>
        	<tbody>
        		<tr class="gradeA">
        			<?php $total = 0; ?>
        			<?php foreach( $report->totals->byMonth as $month => $monthData ) {?>
            			<td><?php echo $month; ?></td>
            			<?php $networks = get_object_vars( $report->totals->byMonth->$month->byNetwork ); ?>
            			<?php foreach( $networks as $network => $data ) {
            			       $total += $report->totals->byMonth->$month->byNetwork->$network;
            			?>
            			<td class="center"><?php echo $report->totals->byMonth->$month->byNetwork->$network;?></td>
            			<?php }?>
	        			<td class="center"><?php echo $total;?></td>
        			<?php }?>
        		</tr>
        	</tbody>
        </table>
    </div>

    <br><br>
    <h3>Daily Totals</h3>
    <div class="full_width">
        <table cellpadding="0" cellspacing="0" border="0" class="display" id="example3" style="width:980px">
        	<thead>
        		<tr>
        			<th>Day</th>
        			<?php $networks = get_object_vars( $report->totals->byNetwork ); ?>
        			<?php foreach( $networks as $network => $data ) {?>
        			<th class="center"><?php echo $network;?></th>
        			<?php }?>
        			<th class="center">Total</th>
        		</tr>
        	</thead>
        	<tbody>
    			<?php foreach( $report->totals->byDay as $day => $dayData ) {?>
	        		<tr class="gradeA">
            			<?php $total = 0; ?>
            			<td><?php echo $day; ?></td>
            			<?php foreach( $networks as $network => $data ) {
            			    $total += $networkTotal = isset( $report->totals->byDay->$day->byNetwork->$network )?$report->totals->byDay->$day->byNetwork->$network:0;
            			?>
            			<td class="center"><?php echo $networkTotal;?></td>
            			<?php }?>
            			<td class="center"><?php echo $total;?></td>
	        		</tr>
    			<?php }?>
        	</tbody>
        </table>
    </div>

    <br><br>
    <h3>Persona Totals</h3>
    <div class="full_width">
        <table cellpadding="0" cellspacing="0" border="0" class="display" id="example4" style="width:980px">
        	<thead>
        		<tr>
        			<th>Persona</th>
        			<?php $networks = get_object_vars( $report->totals->byNetwork ); ?>
        			<?php foreach( $networks as $network => $data ) {?>
        			<th class="center"><?php echo $network;?></th>
        			<?php }?>
        			<th class="center">Total</th>
        		</tr>
        	</thead>
        	<tbody>
    			<?php foreach( $report->personaTotals as $persona => $personaData ) {?>
	        		<tr class="gradeA">
            			<?php $total = 0; ?>
            			<td><?php echo $persona; ?></td>
            			<?php foreach( $networks as $network => $data ) {
            			    $total += $networkTotal = isset( $report->personaTotals->$persona->byNetwork->$network->total )
            			        ?  $report->personaTotals->$persona->byNetwork->$network->total
            			        : 0;
            			?>
            			<td class="center"><?php echo $networkTotal;?></td>
            			<?php }?>
            			<td class="center"><?php echo $total;?></td>
	        		</tr>
    			<?php }?>
        	</tbody>
        </table>
    </div>

</div>
</body>
</html>